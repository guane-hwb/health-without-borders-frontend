// test/unit/nfc_payload_codec_versioning_test.dart
//
// Key versioning behaviour of NfcPayloadCodec: the version header, resolving
// the right key out of a keyring, rotation, and reading pre-versioning tags.

import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;
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

      // Importante para el ajuste de capacidad de la tarjeta del guardián.
      // La v0 no lleva encabezado, así que no lo suma.
      expect(estimated, encrypted.length);
      expect(estimated, greaterThan(28));
    });

    test('estimateSize suma el encabezado desde la v1', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(_keyV1, version: 1),
      );

      final estimated = codec.estimateSize(_record);
      final encrypted = await codec.encode(_record);

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
        // Desde el arreglo de flota mixta, la v0 ya escribe exactamente el
        // formato previo al versionado: [nonce][ciphertext][tag].
        final legacyWriter = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV0),
        );
        final legacyTag = await legacyWriter.encode(_record);

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

    test(
      'una llave inválida junto a otra válida ya no lanza: se descarta',
      () {
        // Antes esto lanzaba y dejaba sin NFC a todo dispositivo al que el
        // backend le entregara un secreto mal montado. Ver el grupo
        // «anillo parcialmente inválido» para el comportamiento completo.
        final codec = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring(
            keys: <int, String>{0: _keyV0, 1: 'abcd'},
            currentVersion: 0,
          ),
        );

        expect(codec.knownKeyVersions, <int>[0]);
      },
    );

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

  group('formato de flota mixta (v0 sin encabezado)', () {
    test('la v0 no escribe el encabezado', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(_keyV0),
      );

      final bytes = await codec.encode(_record);

      // Si escribiera 'HW' aquí, una build anterior no podría leer nada de lo
      // que escribe esta: sus primeros bytes son el nonce.
      expect(bytes[0] == 0x48 && bytes[1] == 0x57, isFalse);
      expect(codec.writeKeyVersion, kLegacyNfcKeyVersion);
    });

    test(
      'un lector solo-legado (sin versionado) descifra lo que escribe la v0',
      () async {
        final writer = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV0),
        );
        final tag = await writer.encode(_record);

        // Se emula el lector previo al versionado: mismo AES-256-GCM sobre
        // [nonce][ciphertext][tag], sin encabezado ni datos asociados.
        final decoded = await _legacyDecrypt(tag, _keyV0);

        expect(decoded, isNotNull);
      },
    );

    test('la v1 sí escribe el encabezado', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(_keyV1, version: 1),
      );

      final bytes = await codec.encode(_record);

      expect(bytes[0], 0x48);
      expect(bytes[1], 0x57);
      expect(bytes[2], 1);
    });
  });

  group('encabezado autenticado (AAD)', () {
    test(
      'quitar el encabezado de un payload v1 lo vuelve ilegible',
      () async {
        final writer = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV1, version: 1),
        );
        final tag = await writer.encode(_record);
        final stripped = Uint8List.sublistView(tag, 3);

        final reader = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring(
            keys: <int, String>{0: _keyV0, 1: _keyV1},
            currentVersion: 1,
          ),
        );

        // Sin AAD esto era legible por el camino legado: el encabezado no
        // significaba nada verificable.
        expect(await reader.decode(stripped), isNull);
      },
    );

    test('un payload v0 sigue descifrando sin datos asociados', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(_keyV0),
      );

      expect(await codec.decode(await codec.encode(_record)), isNotNull);
    });
  });

  group('anillo parcialmente inválido', () {
    test('descarta la versión inválida y sigue leyendo con la válida', () async {
      final writer = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(_keyV0),
      );
      final tag = await writer.encode(_record);

      // Un secreto mal montado en el backend no debe apagar el NFC entero.
      final reader = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring(
          keys: <int, String>{0: _keyV0, 1: 'no-es-hex'},
          currentVersion: 0,
        ),
      );

      expect(reader.knownKeyVersions, <int>[0]);
      expect(reader.writeKeyVersion, 0);
      expect(await reader.decode(tag), isNotNull);
    });

    test(
      'si la versión actual es inválida queda en solo lectura, no lanza',
      () async {
        final writer = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring.single(_keyV0),
        );
        final tag = await writer.encode(_record);

        final reader = NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring(
            keys: <int, String>{0: _keyV0, 1: 'abcd'},
            currentVersion: 1,
          ),
        );

        expect(reader.writeKeyVersion, isNull);
        expect(await reader.decode(tag), isNotNull);
        await expectLater(reader.encode(_record), throwsStateError);
      },
    );

    test('una versión fuera de rango se descarta, no lanza', () {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring(
          keys: <int, String>{0: _keyV0, 999: _keyV1},
          currentVersion: 0,
        ),
      );

      expect(codec.knownKeyVersions, <int>[0]);
    });

    test('si ninguna llave es usable lanza ArgumentError', () {
      expect(
        () => NfcPayloadCodec.fromKeyring(
          keyring: NfcKeyring(
            keys: <int, String>{0: 'abcd', 1: 'no-es-hex'},
            currentVersion: 0,
          ),
        ),
        throwsArgumentError,
      );
    });
  });

}

/// Emulates the pre-versioning reader: AES-256-GCM over [nonce][ct][tag], with
/// no header and no associated data. Used to prove a build without key
/// versioning can still read what version 0 writes.
Future<List<int>?> _legacyDecrypt(Uint8List packed, String hexKey) async {
  final algorithm = crypto.AesGcm.with256bits();
  final key = <int>[
    for (int i = 0; i < hexKey.length; i += 2)
      int.parse(hexKey.substring(i, i + 2), radix: 16),
  ];
  try {
    final secretBox = crypto.SecretBox(
      Uint8List.sublistView(packed, 12, packed.length - 16),
      nonce: Uint8List.sublistView(packed, 0, 12),
      mac: crypto.Mac(Uint8List.sublistView(packed, packed.length - 16)),
    );
    return await algorithm.decrypt(
      secretBox,
      secretKey: crypto.SecretKey(key),
    );
  } catch (_) {
    return null;
  }
}
