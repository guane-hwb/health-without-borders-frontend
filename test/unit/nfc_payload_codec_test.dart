// test/unit/nfc_payload_codec_test.dart

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';

const String _validHexKey =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const String _otherHexKey =
    'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';

void main() {
  group('NfcPayloadCodec — constructor', () {
    test('crea instancia válida con clave hexadecimal de 64 chars', () {
      final codec = NfcPayloadCodec(hexKey: _validHexKey);
      expect(codec, isA<NfcPayloadCodec>());
    });

    test('acepta separadores (espacios, ":" y "-") en la clave hex', () {
      final buffer = StringBuffer();
      const separators = [':', '-', ' '];
      for (var i = 0; i < _validHexKey.length; i++) {
        buffer.write(_validHexKey[i]);
        if (i % 2 == 1 && i != _validHexKey.length - 1) {
          buffer.write(separators[i % separators.length]);
        }
      }
      final withSeparators = buffer.toString();

      expect(() => NfcPayloadCodec(hexKey: withSeparators), returnsNormally);
    });

    test('lanza ArgumentError si la clave no tiene 32 bytes (muy corta)', () {
      expect(
        () => NfcPayloadCodec(hexKey: 'abcd'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lanza ArgumentError si la clave no tiene 32 bytes (muy larga)', () {
      // CORRECCIÓN: Se utiliza interpolación de strings para eliminar el linter warning
      final tooLong = '${_validHexKey}ff';
      expect(
        () => NfcPayloadCodec(hexKey: tooLong),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lanza ArgumentError si el hex tiene longitud impar', () {
      // El constructor ahora reporta de forma uniforme «no queda ninguna llave
      // usable», sin importar por qué la llave era inválida: antes el hex
      // impar se distinguía con FormatException.
      expect(
        () => NfcPayloadCodec(hexKey: 'abc'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('NfcPayloadCodec — encode/decode roundtrip', () {
    late NfcPayloadCodec codec;

    setUp(() {
      codec = NfcPayloadCodec(hexKey: _validHexKey);
    });

    test('roundtrip con mapa simple de tipos mixtos', () async {
      final original = <String, dynamic>{
        'patientId': 'abc-123',
        'age': 34,
        'isCritical': true,
        'temperature': 38.5,
      };

      final encrypted = await codec.encode(original);
      expect(encrypted, isA<Uint8List>());

      final decoded = await codec.decode(encrypted);
      expect(decoded, equals(original));
    });

    test('roundtrip con mapa anidado y listas', () async {
      final original = <String, dynamic>{
        'patient': {
          'name': 'María José',
          'vitals': {'hr': 88, 'spo2': 97},
        },
        'allergies': ['penicilina', 'maní'],
        'history': [
          {'date': '2025-01-01', 'note': 'control'},
          {'date': '2025-06-01', 'note': 'seguimiento'},
        ],
      };

      final encrypted = await codec.encode(original);
      final decoded = await codec.decode(encrypted);
      expect(decoded, equals(original));
    });

    test('roundtrip con mapa vacío', () async {
      final original = <String, dynamic>{};

      final encrypted = await codec.encode(original);
      final decoded = await codec.decode(encrypted);
      expect(decoded, equals(original));
    });

    test('roundtrip con valores null y unicode/emoji', () async {
      final original = <String, dynamic>{
        'note': null,
        'text': 'Tëst ünïcödé 🚑🩺',
      };

      final encrypted = await codec.encode(original);
      final decoded = await codec.decode(encrypted);
      expect(decoded, equals(original));
    });

    test(
      'dos encriptaciones del mismo mapa producen bytes distintos (nonce aleatorio)',
      () async {
        final original = <String, dynamic>{'a': 1};

        final encrypted1 = await codec.encode(original);
        final encrypted2 = await codec.encode(original);

        expect(encrypted1, isNot(equals(encrypted2)));

        expect(await codec.decode(encrypted1), equals(original));
        expect(await codec.decode(encrypted2), equals(original));
      },
    );
  });

  group('NfcPayloadCodec — decode: casos de falla', () {
    late NfcPayloadCodec codec;

    setUp(() {
      codec = NfcPayloadCodec(hexKey: _validHexKey);
    });

    test('decode retorna null si el payload está vacío (muy corto)', () async {
      final result = await codec.decode(Uint8List(0));
      expect(result, isNull);
    });

    test(
      'decode retorna null si el payload es más corto que el overhead mínimo',
      () async {
        final shortPayload = Uint8List.fromList(List<int>.filled(10, 0xAA));
        final result = await codec.decode(shortPayload);
        expect(result, isNull);
      },
    );

    test(
      'decode retorna null si el tag de autenticación fue alterado',
      () async {
        final encrypted = await codec.encode(<String, dynamic>{'x': 1});

        final tampered = Uint8List.fromList(encrypted);
        tampered[tampered.length - 1] ^= 0xFF;

        final result = await codec.decode(tampered);
        expect(result, isNull);
      },
    );

    test('decode retorna null si el ciphertext fue alterado', () async {
      final encrypted = await codec.encode(<String, dynamic>{'x': 1, 'y': 2});

      final tampered = Uint8List.fromList(encrypted);
      final middleIndex = 12 + 1;
      tampered[middleIndex] ^= 0xFF;

      final result = await codec.decode(tampered);
      expect(result, isNull);
    });

    test('decode retorna null si se usa una clave AES distinta', () async {
      final encrypted = await codec.encode(<String, dynamic>{'x': 1});

      final otherCodec = NfcPayloadCodec(hexKey: _otherHexKey);
      final result = await otherCodec.decode(encrypted);
      expect(result, isNull);
    });

    test(
      'decode retorna null ante datos binarios completamente aleatorios',
      () async {
        final garbage = Uint8List.fromList(
          List<int>.generate(40, (i) => (i * 37) % 256),
        );
        final result = await codec.decode(garbage);
        expect(result, isNull);
      },
    );
  });

  group('NfcPayloadCodec — estimateSize', () {
    late NfcPayloadCodec codec;

    setUp(() {
      codec = NfcPayloadCodec(hexKey: _validHexKey);
    });

    test('retorna un tamaño positivo y consistente con encode()', () async {
      final data = <String, dynamic>{
        'patientId': 'abc-123',
        'age': 34,
        'notes': 'Paciente estable, monitoreo continuo.',
      };

      final estimated = codec.estimateSize(data);
      final encrypted = await codec.encode(data);

      expect(estimated, greaterThan(0));
      expect(estimated, equals(encrypted.length));
    });

    test('mapa vacío produce un tamaño estimado mínimo pero positivo', () {
      final estimated = codec.estimateSize(<String, dynamic>{});
      expect(estimated, greaterThan(28)); // al menos el overhead AES-GCM
    });
  });

  group('NfcPayloadCodec — manejo de errores en decode (catch genérico)', () {
    test(
      'decode captura excepciones inesperadas y retorna null en vez de propagar',
      () async {
        final codec = NfcPayloadCodec(hexKey: _validHexKey);

        final invalid = Uint8List.fromList(List<int>.filled(50, 0x00));
        final result = await codec.decode(invalid);
        expect(result, isNull);
      },
    );
  });
}
