// test/unit/nfc_chip_binding_test.dart
//
// ADR 003: a versioned (v1+) NFC payload is bound to the chip UID and record
// type through the AAD; a payload moved to another chip must not decrypt.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';

const String _hexKey =
    '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';

void main() {
  const Map<String, dynamic> payload = <String, dynamic>{
    'fn': 'Ana',
    'alg': <Map<String, String>>[
      <String, String>{'a': 'Penicilina'},
    ],
  };

  group('chipBindingAad', () {
    test('cambia con la UID y con el tipo MIME', () {
      final Uint8List a = chipBindingAad(
        '04:A1:B2:C3:D4:E5:F6',
        kHwbNdefMimeType,
      );
      final Uint8List b = chipBindingAad(
        '04:A1:B2:C3:D4:E5:F7',
        kHwbNdefMimeType,
      );
      final Uint8List c = chipBindingAad(
        '04:A1:B2:C3:D4:E5:F6',
        kHwbGuardianMimeType,
      );
      expect(a, isNot(equals(b)));
      expect(a, isNot(equals(c)));
    });

    test('es determinista para la misma UID y tipo', () {
      expect(
        chipBindingAad('04:A1:B2:C3:D4:E5:F6', kHwbNdefMimeType),
        equals(chipBindingAad('04:A1:B2:C3:D4:E5:F6', kHwbNdefMimeType)),
      );
    });
  });

  group('payload versionado (v1+) ligado al chip', () {
    final NfcPayloadCodec codec = NfcPayloadCodec(
      hexKey: _hexKey,
      keyVersion: 1,
    );
    final Uint8List aad = chipBindingAad(
      '04:A1:B2:C3:D4:E5:F6',
      kHwbNdefMimeType,
    );

    test('se descifra en el chip y tipo originales', () async {
      final Uint8List sealed = await codec.encode(payload, extraAad: aad);
      final NfcDecodeResult? result = await codec.decodeDetailed(
        sealed,
        extraAad: aad,
      );
      expect(result, isNotNull);
      expect(result!.hadHeader, isTrue);
      expect(result.data['fn'], 'Ana');
    });

    test('copiado a otra UID no se descifra', () async {
      final Uint8List sealed = await codec.encode(payload, extraAad: aad);
      final Uint8List otherChip = chipBindingAad(
        '04:FF:EE:DD:CC:BB:AA',
        kHwbNdefMimeType,
      );
      expect(await codec.decodeDetailed(sealed, extraAad: otherChip), isNull);
    });

    test('con otro tipo MIME no se descifra', () async {
      final Uint8List sealed = await codec.encode(payload, extraAad: aad);
      final Uint8List otherType = chipBindingAad(
        '04:A1:B2:C3:D4:E5:F6',
        kHwbGuardianMimeType,
      );
      expect(await codec.decodeDetailed(sealed, extraAad: otherType), isNull);
    });

    test(
      'sin AAD (el segundo intento del servicio) tampoco se descifra',
      () async {
        final Uint8List sealed = await codec.encode(payload, extraAad: aad);
        expect(await codec.decodeDetailed(sealed), isNull);
      },
    );
  });

  group('payload versión 0 (flota actual)', () {
    final NfcPayloadCodec codec = NfcPayloadCodec(hexKey: _hexKey);

    test('se escribe sin cabecera ni AAD y se lee sin AAD', () async {
      final Uint8List sealed = await codec.encode(payload);
      final NfcDecodeResult? result = await codec.decodeDetailed(sealed);
      expect(result, isNotNull);
      expect(result!.hadHeader, isFalse);
    });

    test(
      'no se descifra con AAD de chip: por eso el servicio reintenta sin él',
      () async {
        final Uint8List sealed = await codec.encode(payload);
        final Uint8List aad = chipBindingAad(
          '04:A1:B2:C3:D4:E5:F6',
          kHwbNdefMimeType,
        );
        expect(await codec.decodeDetailed(sealed, extraAad: aad), isNull);
      },
    );
  });
}
