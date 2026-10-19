import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/retired_device_hash.dart';

// Same vectors as the backend:
// tests/contract/fixtures/retired_device_hashes.json (health-without-borders).
const String _hashA =
    '8e1e4ddbca4b0de60ef17c3d47d3b98abdadf688147d26760451bd41e26976de';
const String _hashB =
    '55d2ccd1cb9bb77c9d1c134328bdef18038084479a22fdb052fff3a067ca42b2';

void main() {
  test('el prefijo es el del backend', () {
    expect(retiredDeviceHashPrefix, 'hwb-retired-device:v1:');
  });

  test('coincide con los vectores compartidos con el backend', () {
    const Map<String, String> vectors = <String, String>{
      '04:a1:b2:c3:d4:e5:f6': _hashA,
      '04A1B2C3D4E5F6': _hashA,
      '04 a1-b2.c3:d4 e5 f6': _hashA,
      '53:8C:2E:91': _hashB,
    };
    vectors.forEach((String uid, String hash) {
      expect(retiredDeviceHash(uid), hash, reason: uid);
    });
  });

  test('un UID sin dígitos hex no tiene hash', () {
    for (final String uid in <String>['', '  ', '::-', 'XYZ']) {
      expect(retiredDeviceHash(uid), isNull, reason: uid);
    }
  });

  test('reconoce un hash del servidor', () {
    expect(isRetiredDeviceHash(_hashA), isTrue);
    expect(isRetiredDeviceHash(_hashA.toUpperCase()), isFalse);
    expect(isRetiredDeviceHash(_hashA.substring(1)), isFalse);
    expect(isRetiredDeviceHash('04:A1:B2'), isFalse);
  });
}
