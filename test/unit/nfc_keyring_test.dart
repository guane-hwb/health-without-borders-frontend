// test/unit/nfc_keyring_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';

const String _keyV0 =
    '0000000000000000000000000000000000000000000000000000000000000000';
const String _keyV1 =
    '1111111111111111111111111111111111111111111111111111111111111111';
const String _keyV2 =
    '2222222222222222222222222222222222222222222222222222222222222222';

void main() {
  group('NfcKeyring.single', () {
    test('crea un anillo de una sola llave en la versión legacy', () {
      final ring = NfcKeyring.single(_keyV0);

      expect(ring.currentVersion, kLegacyNfcKeyVersion);
      expect(ring.currentKey, _keyV0);
      expect(ring.keyFor(0), _keyV0);
      expect(ring.canWrite, isTrue);
      expect(ring.versions, <int>[0]);
    });

    test('acepta una versión explícita', () {
      final ring = NfcKeyring.single(_keyV2, version: 2);

      expect(ring.currentVersion, 2);
      expect(ring.currentKey, _keyV2);
      expect(ring.keyFor(0), isNull);
    });

    test('el mapa de llaves es inmutable', () {
      final ring = NfcKeyring.single(_keyV0);
      expect(() => ring.keys[1] = _keyV1, throwsUnsupportedError);
    });
  });

  group('NfcKeyring.fromResponse', () {
    test('retorna null cuando no hay material de llave', () {
      expect(NfcKeyring.fromResponse(<String, dynamic>{}), isNull);
      expect(
        NfcKeyring.fromResponse(<String, dynamic>{'nfc_encryption_key': null}),
        isNull,
      );
    });

    test('backend sin versionado: la llave única se toma como versión 0', () {
      final ring = NfcKeyring.fromResponse(<String, dynamic>{
        'nfc_encryption_key': _keyV0,
      });

      expect(ring, isNotNull);
      expect(ring!.versions, <int>[0]);
      expect(ring.currentVersion, 0);
      expect(ring.currentKey, _keyV0);
    });

    test('parsea el anillo completo y la versión actual', () {
      final ring = NfcKeyring.fromResponse(<String, dynamic>{
        'nfc_encryption_key': _keyV1,
        'nfc_key_version': 1,
        'nfc_keyring': <String, dynamic>{'0': _keyV0, '1': _keyV1},
      });

      expect(ring, isNotNull);
      expect(ring!.versions, <int>[0, 1]);
      expect(ring.currentVersion, 1);
      expect(ring.currentKey, _keyV1);
      // La versión vieja sigue disponible para leer pulseras sin migrar.
      expect(ring.keyFor(0), _keyV0);
    });

    test('las claves string del JSON se parsean a int', () {
      final ring = NfcKeyring.fromResponse(<String, dynamic>{
        'nfc_key_version': '2',
        'nfc_keyring': <String, dynamic>{'2': _keyV2},
      });

      expect(ring!.keyFor(2), _keyV2);
      expect(ring.currentVersion, 2);
    });

    test('ignora entradas con versión no numérica o llave vacía', () {
      final ring = NfcKeyring.fromResponse(<String, dynamic>{
        'nfc_key_version': 0,
        'nfc_keyring': <String, dynamic>{'0': _keyV0, 'abc': _keyV1, '3': ''},
      });

      expect(ring!.versions, <int>[0]);
    });

    test(
      'currentVersion es null si la versión declarada no está en el anillo',
      () {
        final ring = NfcKeyring.fromResponse(<String, dynamic>{
          'nfc_key_version': 5,
          'nfc_keyring': <String, dynamic>{'1': _keyV1},
        });

        expect(ring, isNotNull);
        expect(ring!.isNotEmpty, isTrue);
        // Se puede leer, pero no escribir: mejor rechazar que cifrar con una
        // llave arbitraria.
        expect(ring.canWrite, isFalse);
        expect(ring.currentKey, isNull);
        expect(ring.keyFor(1), _keyV1);
      },
    );

    test(
      'la llave legacy rellena la versión declarada que el anillo omitió',
      () {
        final ring = NfcKeyring.fromResponse(<String, dynamic>{
          'nfc_encryption_key': _keyV2,
          'nfc_key_version': 2,
          'nfc_keyring': <String, dynamic>{'0': _keyV0},
        });

        expect(ring!.keyFor(2), _keyV2);
        expect(ring.currentVersion, 2);
        expect(ring.keyFor(0), _keyV0);
      },
    );

    test('sin nfc_key_version no se puede escribir pero sí leer', () {
      final ring = NfcKeyring.fromResponse(<String, dynamic>{
        'nfc_keyring': <String, dynamic>{'0': _keyV0, '1': _keyV1},
      });

      expect(ring!.canWrite, isFalse);
      expect(ring.keyFor(1), _keyV1);
    });
  });

  group('NfcKeyring — round trip por almacenamiento', () {
    test('toJson/fromJson preserva llaves y versión actual', () {
      final original = NfcKeyring(
        keys: <int, String>{0: _keyV0, 1: _keyV1},
        currentVersion: 1,
      );

      final restored = NfcKeyring.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.versions, <int>[0, 1]);
      expect(restored.currentVersion, 1);
      expect(restored.keyFor(0), _keyV0);
      expect(restored.keyFor(1), _keyV1);
    });

    test('toJson omite la versión actual cuando no hay', () {
      final ring = NfcKeyring(keys: <int, String>{0: _keyV0});
      expect(ring.toJson().containsKey('nfc_key_version'), isFalse);
    });
  });

  group('NfcKeyring.toString', () {
    test('incluye las versiones y la versión actual', () {
      final ring = NfcKeyring(
        keys: <int, String>{1: _keyV1, 0: _keyV0},
        currentVersion: 1,
      );

      expect(ring.toString(), 'NfcKeyring(versions: [0, 1], current: 1)');
    });

    test('muestra current: null cuando no hay versión actual', () {
      final ring = NfcKeyring(keys: <int, String>{1: _keyV1});

      expect(ring.toString(), 'NfcKeyring(versions: [1], current: null)');
    });

    test('nunca expone el material de las llaves', () {
      final ring = NfcKeyring.single(_keyV2, version: 2);
      final text = ring.toString();

      expect(text, 'NfcKeyring(versions: [2], current: 2)');
      expect(text.contains(_keyV2), isFalse);
    });
  });

  group('NfcKeyring — anillo vacío y entradas inválidas', () {
    test('un anillo sin llaves es vacío y no puede escribir', () {
      final ring = NfcKeyring(keys: <int, String>{});

      expect(ring.isEmpty, isTrue);
      expect(ring.isNotEmpty, isFalse);
      expect(ring.canWrite, isFalse);
      expect(ring.currentKey, isNull);
      expect(ring.versions, isEmpty);
      expect(ring.toString(), 'NfcKeyring(versions: [], current: null)');
    });

    test('un anillo con llaves no es vacío', () {
      expect(NfcKeyring.single(_keyV0).isEmpty, isFalse);
    });

    test('ignora entradas del anillo con llave null', () {
      final ring = NfcKeyring.fromResponse(<String, dynamic>{
        'nfc_key_version': 1,
        'nfc_keyring': <String, dynamic>{'0': null, '1': _keyV1},
      });

      expect(ring!.versions, <int>[1]);
      expect(ring.currentVersion, 1);
    });

    test('un nfc_keyring que no es un mapa cae a la llave legacy', () {
      final ring = NfcKeyring.fromResponse(<String, dynamic>{
        'nfc_keyring': 'no-es-un-mapa',
        'nfc_encryption_key': _keyV0,
      });

      expect(ring, isNotNull);
      expect(ring!.versions, <int>[0]);
      expect(ring.currentKey, _keyV0);
    });

    test('fromJson retorna null sin material de llave', () {
      expect(NfcKeyring.fromJson(<String, dynamic>{}), isNull);
    });
  });
}
