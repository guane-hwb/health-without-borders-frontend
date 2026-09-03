// test/unit/nfc_payload_codec_versioning_test.dart
//
// Key versioning behaviour of NfcPayloadCodec: the version header, resolving
// the right key out of a keyring, rotation, and reading pre-versioning tags.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';

const String _keyV0 =
    '0000000000000000000000000000000000000000000000000000000000000000';
const String _keyV1 =
    '1111111111111111111111111111111111111111111111111111111111111111';
const String _keyV2 =
    '2222222222222222222222222222222222222222222222222222222222222222';

final Map<String, dynamic> _record = <String, dynamic>{
  'patientId': 'p-123',
  'age': 7,
  'notes': 'Control de crecimiento.',
};

void main() {
  group('encabezado de versión', () {
    test('encode escribe la magia HW y la versión actual', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(_keyV1, version: 1),
      );

      final bytes = await codec.encode(_record);

      expect(bytes[0], 0x48); // 'H'
      expect(bytes[1], 0x57); // 'W'
      expect(bytes[2], 1); // versión de llave
    });

    test('la versión escrita sigue a la versión actual del anillo', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring(
          keys: <int, String>{0: _keyV0, 7: _keyV1},
          currentVersion: 7,
        ),
      );

      final bytes = await codec.encode(_record);

      expect(bytes[2], 7);
      expect(codec.writeKeyVersion, 7);
    });

    test('estimateSize incluye el encabezado y coincide con encode', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(_keyV0),
      );

      final estimated = codec.estimateSize(_record);
      final encrypted = await codec.encode(_record);

      // Importante para el ajuste de capacidad de la tarjeta del guardián: el
      // encabezado también consume espacio del chip.
      expect(estimated, encrypted.length);
      expect(estimated, greaterThan(28 + 3));
    });

    test('knownKeyVersions lista las versiones en orden', () {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring(
          keys: <int, String>{2: _keyV2, 0: _keyV0, 1: _keyV1},
          currentVersion: 2,
        ),
      );

      expect(codec.knownKeyVersions, <int>[0, 1, 2]);
    });
  });

  group('roundtrip y resolución de llave', () {
    test('el mismo códec descifra lo que cifró', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(_keyV1, version: 1),
      );

      final decoded = await codec.decode(await codec.encode(_record));

      expect(decoded, isNotNull);
      expect(decoded!['patientId'], 'p-123');
      expect(decoded['age'], 7);
    });

    test(
      'un lector con el anillo completo descifra una pulsera de versión vieja',
      () async {
        // Pulsera escrita antes de la rotación, con la v0.
        final oldWriter = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV0),
        );
        final tag = await oldWriter.encode(_record);

        // Dispositivo ya rotado: escribe con v1, pero conserva la v0 para leer.
        final rotatedReader = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring(
            keys: <int, String>{0: _keyV0, 1: _keyV1},
            currentVersion: 1,
          ),
        );

        final decoded = await rotatedReader.decode(tag);

        expect(decoded, isNotNull);
        expect(decoded!['patientId'], 'p-123');
      },
    );

    test(
      'un lector sin la versión de la pulsera retorna null (fail-safe)',
      () async {
        final writer = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV2, version: 2),
        );
        final tag = await writer.encode(_record);

        // La v2 ya salió del anillo (ventana de coexistencia cerrada).
        final reader = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV0),
        );

        expect(await reader.decode(tag), isNull);
      },
    );

    test(
      'una versión presente pero con llave distinta no descifra',
      () async {
        final writer = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV1, version: 1),
        );
        final tag = await writer.encode(_record);

        // Misma versión declarada, material distinto.
        final reader = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV2, version: 1),
        );

        expect(await reader.decode(tag), isNull);
      },
    );
  });

  group('compatibilidad con pulseras previas al versionado', () {
    test(
      'decode lee un payload sin encabezado usando una llave del anillo',
      () async {
        // Formato legacy construido a mano: [nonce][ciphertext][tag], que es
        // exactamente lo que produce encode() menos los 3 bytes del header.
        final legacyWriter = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV0),
        );
        final versioned = await legacyWriter.encode(_record);
        final legacyTag = Uint8List.sublistView(versioned, 3);

        final reader = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring(
            keys: <int, String>{0: _keyV0, 1: _keyV1},
            currentVersion: 1,
          ),
        );

        final decoded = await reader.decode(legacyTag);

        expect(decoded, isNotNull);
        expect(decoded!['patientId'], 'p-123');
      },
    );

    test('el constructor hexKey sigue funcionando y escribe la v0', () async {
      final codec = NfcPayloadCodec(hexKey: _keyV0);

      final bytes = await codec.encode(_record);

      expect(codec.writeKeyVersion, kLegacyNfcKeyVersion);
      expect(bytes[2], 0);
      expect(await codec.decode(bytes), isNotNull);
    });
  });

  group('configuración inválida', () {
    test('anillo vacío lanza ArgumentError', () {
      expect(
        () => NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring(keys: <int, String>{}),
        ),
        throwsArgumentError,
      );
    });

    test('una llave del anillo con largo inválido lanza ArgumentError', () {
      expect(
        () => NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring(
            keys: <int, String>{0: _keyV0, 1: 'abcd'},
            currentVersion: 0,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('una versión fuera del rango del byte lanza ArgumentError', () {
      expect(
        () => NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV0, version: 256),
        ),
        throwsArgumentError,
      );
    });

    test(
      'sin versión actual: decode funciona pero encode lanza StateError',
      () async {
        final writer = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV0),
        );
        final tag = await writer.encode(_record);

        final readOnly = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring(keys: <int, String>{0: _keyV0}),
        );

        expect(readOnly.writeKeyVersion, isNull);
        expect(await readOnly.decode(tag), isNotNull);
        await expectLater(readOnly.encode(_record), throwsStateError);
      },
    );
  });

  group('integridad', () {
    test('alterar el ciphertext retorna null', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(_keyV1, version: 1),
      );
      final bytes = await codec.encode(_record);

      final tampered = Uint8List.fromList(bytes);
      // Primer byte de ciphertext: 3 de header + 12 de nonce.
      tampered[3 + 12] ^= 0xFF;

      expect(await codec.decode(tampered), isNull);
    });

    test('alterar el byte de versión retorna null', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring(
          keys: <int, String>{0: _keyV0, 1: _keyV1},
          currentVersion: 1,
        ),
      );
      final bytes = await codec.encode(_record);

      final tampered = Uint8List.fromList(bytes);
      tampered[2] = 0; // apunta a la v0, que no cifró estos datos

      expect(await codec.decode(tampered), isNull);
    });
  });
}
