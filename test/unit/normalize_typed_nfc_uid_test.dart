// test/unit/normalize_typed_nfc_uid_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_session_types.dart';

void main() {
  group('normalizeTypedNfcUid', () {
    test('espacios y minúsculas -> formato del lector', () {
      expect(normalizeTypedNfcUid('04 1a 2c de'), '04:1A:2C:DE');
    });

    test('ya normalizado queda igual (idempotente)', () {
      expect(normalizeTypedNfcUid('04:1A:2C:DE'), '04:1A:2C:DE');
      expect(
        normalizeTypedNfcUid(normalizeTypedNfcUid('04-1a-2c-de')),
        '04:1A:2C:DE',
      );
    });

    test('recorta espacios alrededor', () {
      expect(normalizeTypedNfcUid('  04:1a:2c:de \n'), '04:1A:2C:DE');
    });

    test('vacío o solo espacios -> vacío', () {
      expect(normalizeTypedNfcUid(''), '');
      expect(normalizeTypedNfcUid('   '), '');
    });

    test('etiquetas no hexadecimales no se deforman', () {
      expect(normalizeTypedNfcUid('HWB-ADULTO-88'), 'HWB-ADULTO-88');
      expect(normalizeTypedNfcUid(' HWB-GUARDIAN-01 '), 'HWB-GUARDIAN-01');
    });
  });
}
