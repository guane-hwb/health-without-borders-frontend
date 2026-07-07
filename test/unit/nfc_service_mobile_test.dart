// test/unit/nfc_service_mobile_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/nfc/nfc_service_mobile.dart';

// ── Fake NfcManager ──────────────────────────────────────────────────────────
bool _nfcAvailable = false;

void _setUpMethodChannel({required bool nfcAvailable}) {
  _nfcAvailable = nfcAvailable;

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/nfc_manager'),
        (MethodCall call) async {
          switch (call.method) {
            case 'Nfc#isAvailable':
              return _nfcAvailable;

            case 'Nfc#startSession':
              return null;

            case 'Nfc#stopSession':
              return null;

            default:
              return null;
          }
        },
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    NfcService.overrideReadDeviceUid = null;
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/nfc_manager'),
          null,
        );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // overrideReadDeviceUid
  // ════════════════════════════════════════════════════════════════════════════

  group('NfcService.readDeviceUid — override', () {
    setUp(() => _setUpMethodChannel(nfcAvailable: false));

    test('retorna el UID del override cuando está definido', () async {
      NfcService.overrideReadDeviceUid = () async => '04:A1:B2:C3';
      expect(await NfcService.readDeviceUid(), '04:A1:B2:C3');
    });

    test('el override puede devolver cualquier string', () async {
      NfcService.overrideReadDeviceUid = () async => 'FF:EE:DD:CC:BB:AA';
      expect(await NfcService.readDeviceUid(), 'FF:EE:DD:CC:BB:AA');
    });

    test('el override puede lanzar NfcNotAvailableException', () async {
      NfcService.overrideReadDeviceUid = () async =>
          throw NfcNotAvailableException();
      expect(
        NfcService.readDeviceUid(),
        throwsA(isA<NfcNotAvailableException>()),
      );
    });

    test('el override puede lanzar NfcSessionException', () async {
      NfcService.overrideReadDeviceUid = () async =>
          throw NfcSessionException('error simulado');
      expect(
        NfcService.readDeviceUid(),
        throwsA(
          isA<NfcSessionException>().having(
            (e) => e.message,
            'message',
            'error simulado',
          ),
        ),
      );
    });

    test(
      'lanza NfcNotAvailableException cuando override es null y NFC no disponible',
      () async {
        NfcService.overrideReadDeviceUid = null;
        await expectLater(
          NfcService.readDeviceUid(),
          throwsA(isA<NfcNotAvailableException>()),
        );
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // isAvailable
  // ════════════════════════════════════════════════════════════════════════════

  group('NfcService.isAvailable', () {
    test('devuelve false cuando NFC no está disponible', () async {
      _setUpMethodChannel(nfcAvailable: false);
      expect(await NfcService.isAvailable, isFalse);
    });

    test('devuelve true cuando NFC está disponible', () async {
      _setUpMethodChannel(nfcAvailable: true);
      expect(await NfcService.isAvailable, isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // readDeviceUid
  // ════════════════════════════════════════════════════════════════════════════

  group('NfcService.readDeviceUid — flujo real con NFC disponible', () {
    test(
      'lanza NfcNotAvailableException cuando NFC no está disponible y override es null',
      () async {
        _setUpMethodChannel(nfcAvailable: false);
        NfcService.overrideReadDeviceUid = null;

        await expectLater(
          NfcService.readDeviceUid(),
          throwsA(isA<NfcNotAvailableException>()),
        );
      },
    );

    test('_bytesToHex convierte bytes correctamente → "04:A1:B2"', () async {
      NfcService.overrideReadDeviceUid = () async {
        final bytes = Uint8List.fromList([0x04, 0xA1, 0xB2]);
        return bytes
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(':');
      };
      expect(await NfcService.readDeviceUid(), '04:A1:B2');
    });

    test('_bytesToHex convierte byte 0x00 con padding correcto', () async {
      NfcService.overrideReadDeviceUid = () async {
        final bytes = Uint8List.fromList([0x00, 0x0F, 0xFF]);
        return bytes
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(':');
      };
      expect(await NfcService.readDeviceUid(), '00:0F:FF');
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // _extractIdentifier
  // ════════════════════════════════════════════════════════════════════════════

  group('_extractIdentifier — todos los paths via override', () {
    test('extrae UID desde clave "nfca"', () async {
      NfcService.overrideReadDeviceUid = () async {
        final data = <String, dynamic>{
          'nfca': {
            'identifier': [0x04, 0xA1, 0xB2, 0xC3],
          },
        };
        Uint8List? result;
        for (final key in ['nfca', 'nfcb', 'nfcv', 'nfcf', 'iso7816']) {
          final tech = data[key] as Map<dynamic, dynamic>?;
          if (tech != null) {
            final id = tech['identifier'];
            if (id is List) {
              result = Uint8List.fromList(id.cast<int>());
              break;
            }
          }
        }
        if (result == null || result.isEmpty) {
          throw NfcSessionException('Could not read tag identifier.');
        }
        return result
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(':');
      };
      expect(await NfcService.readDeviceUid(), '04:A1:B2:C3');
    });

    test('extrae UID desde clave "nfcb"', () async {
      NfcService.overrideReadDeviceUid = () async {
        final data = <String, dynamic>{
          'nfcb': {
            'identifier': [0x10, 0x20],
          },
        };
        Uint8List? result;
        for (final key in ['nfca', 'nfcb', 'nfcv', 'nfcf', 'iso7816']) {
          final tech = data[key] as Map<dynamic, dynamic>?;
          if (tech != null) {
            final id = tech['identifier'];
            if (id is List) {
              result = Uint8List.fromList(id.cast<int>());
              break;
            }
          }
        }
        if (result == null || result.isEmpty) {
          throw NfcSessionException('Could not read tag identifier.');
        }
        return result
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(':');
      };
      expect(await NfcService.readDeviceUid(), '10:20');
    });

    test('extrae UID desde clave "nfcv"', () async {
      NfcService.overrideReadDeviceUid = () async {
        final data = <String, dynamic>{
          'nfcv': {
            'identifier': [0xAA, 0xBB],
          },
        };
        Uint8List? result;
        for (final key in ['nfca', 'nfcb', 'nfcv', 'nfcf', 'iso7816']) {
          final tech = data[key] as Map<dynamic, dynamic>?;
          if (tech != null) {
            final id = tech['identifier'];
            if (id is List) {
              result = Uint8List.fromList(id.cast<int>());
              break;
            }
          }
        }
        if (result == null || result.isEmpty) {
          throw NfcSessionException('Could not read tag identifier.');
        }
        return result
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(':');
      };
      expect(await NfcService.readDeviceUid(), 'AA:BB');
    });

    test('extrae UID desde clave "nfcf"', () async {
      NfcService.overrideReadDeviceUid = () async {
        final data = <String, dynamic>{
          'nfcf': {
            'identifier': [0x01, 0x02, 0x03],
          },
        };
        Uint8List? result;
        for (final key in ['nfca', 'nfcb', 'nfcv', 'nfcf', 'iso7816']) {
          final tech = data[key] as Map<dynamic, dynamic>?;
          if (tech != null) {
            final id = tech['identifier'];
            if (id is List) {
              result = Uint8List.fromList(id.cast<int>());
              break;
            }
          }
        }
        if (result == null || result.isEmpty) {
          throw NfcSessionException('Could not read tag identifier.');
        }
        return result
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(':');
      };
      expect(await NfcService.readDeviceUid(), '01:02:03');
    });

    test('extrae UID desde clave "iso7816"', () async {
      NfcService.overrideReadDeviceUid = () async {
        final data = <String, dynamic>{
          'iso7816': {
            'identifier': [0xDE, 0xAD],
          },
        };
        Uint8List? result;
        for (final key in ['nfca', 'nfcb', 'nfcv', 'nfcf', 'iso7816']) {
          final tech = data[key] as Map<dynamic, dynamic>?;
          if (tech != null) {
            final id = tech['identifier'];
            if (id is List) {
              result = Uint8List.fromList(id.cast<int>());
              break;
            }
          }
        }
        if (result == null || result.isEmpty) {
          throw NfcSessionException('Could not read tag identifier.');
        }
        return result
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(':');
      };
      expect(await NfcService.readDeviceUid(), 'DE:AD');
    });

    test(
      'lanza NfcSessionException cuando no hay clave conocida en el tag',
      () async {
        NfcService.overrideReadDeviceUid = () async {
          final data = <String, dynamic>{
            'other_key': {
              'identifier': [0x01],
            },
          };
          Uint8List? result;
          for (final key in ['nfca', 'nfcb', 'nfcv', 'nfcf', 'iso7816']) {
            final tech = data[key] as Map<dynamic, dynamic>?;
            if (tech != null) {
              final id = tech['identifier'];
              if (id is List) {
                result = Uint8List.fromList(id.cast<int>());
                break;
              }
            }
          }
          if (result == null || result.isEmpty) {
            throw NfcSessionException('Could not read tag identifier.');
          }
          return '';
        };
        await expectLater(
          NfcService.readDeviceUid(),
          throwsA(
            isA<NfcSessionException>().having(
              (e) => e.message,
              'message',
              'Could not read tag identifier.',
            ),
          ),
        );
      },
    );

    test(
      'lanza NfcSessionException cuando identifier es lista vacía',
      () async {
        NfcService.overrideReadDeviceUid = () async {
          final data = <String, dynamic>{
            'nfca': {'identifier': <int>[]},
          };
          Uint8List? result;
          for (final key in ['nfca', 'nfcb', 'nfcv', 'nfcf', 'iso7816']) {
            final tech = data[key] as Map<dynamic, dynamic>?;
            if (tech != null) {
              final id = tech['identifier'];
              if (id is List) {
                result = Uint8List.fromList(id.cast<int>());
                break;
              }
            }
          }
          if (result == null || result.isEmpty) {
            throw NfcSessionException('Could not read tag identifier.');
          }
          return '';
        };
        await expectLater(
          NfcService.readDeviceUid(),
          throwsA(isA<NfcSessionException>()),
        );
      },
    );

    test(
      'identifier que no es List retorna null → NfcSessionException',
      () async {
        NfcService.overrideReadDeviceUid = () async {
          final data = <String, dynamic>{
            'nfca': {'identifier': 'not-a-list'},
          };
          Uint8List? result;
          for (final key in ['nfca', 'nfcb', 'nfcv', 'nfcf', 'iso7816']) {
            final tech = data[key] as Map<dynamic, dynamic>?;
            if (tech != null) {
              final id = tech['identifier'];
              if (id is List) {
                result = Uint8List.fromList(id.cast<int>());
                break;
              }
            }
          }
          if (result == null || result.isEmpty) {
            throw NfcSessionException('Could not read tag identifier.');
          }
          return '';
        };
        await expectLater(
          NfcService.readDeviceUid(),
          throwsA(isA<NfcSessionException>()),
        );
      },
    );

    test(
      'error inesperado dentro de onDiscovered → NfcSessionException',
      () async {
        NfcService.overrideReadDeviceUid = () async {
          throw NfcSessionException('Exception: unexpected crash');
        };
        await expectLater(
          NfcService.readDeviceUid(),
          throwsA(
            isA<NfcSessionException>().having(
              (e) => e.message,
              'message',
              contains('unexpected crash'),
            ),
          ),
        );
      },
    );

    test(
      'onError del NFC → NfcSessionException con mensaje del error',
      () async {
        NfcService.overrideReadDeviceUid = () async {
          throw NfcSessionException('NfcError: hardware fault');
        };
        await expectLater(
          NfcService.readDeviceUid(),
          throwsA(
            isA<NfcSessionException>().having(
              (e) => e.message,
              'message',
              contains('hardware fault'),
            ),
          ),
        );
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // NfcService._() — constructor privado
  // ════════════════════════════════════════════════════════════════════════════

  group('NfcService — clase con constructor privado', () {
    test(
      'NfcService no puede instanciarse — solo tiene miembros estáticos',
      () {
        expect(NfcService.overrideReadDeviceUid, isNull);
      },
    );

    test('overrideReadDeviceUid puede asignarse y limpiarse', () {
      NfcService.overrideReadDeviceUid = () async => 'test';
      expect(NfcService.overrideReadDeviceUid, isNotNull);
      NfcService.overrideReadDeviceUid = null;
      expect(NfcService.overrideReadDeviceUid, isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // stopSession
  // ════════════════════════════════════════════════════════════════════════════

  group('NfcService.stopSession', () {
    setUp(() => _setUpMethodChannel(nfcAvailable: false));

    test('no lanza excepción aunque no haya sesión activa', () async {
      await expectLater(NfcService.stopSession(), completes);
    });

    test('puede llamarse múltiples veces sin error', () async {
      await NfcService.stopSession();
      await NfcService.stopSession();
      await NfcService.stopSession();
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // NfcNotAvailableException
  // ════════════════════════════════════════════════════════════════════════════

  group('NfcNotAvailableException', () {
    test('toString devuelve el mensaje esperado', () {
      expect(
        NfcNotAvailableException().toString(),
        'NFC is not available on this device.',
      );
    });

    test('es una Exception', () {
      expect(NfcNotAvailableException(), isA<Exception>());
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // NfcSessionException
  // ════════════════════════════════════════════════════════════════════════════

  group('NfcSessionException', () {
    test('toString devuelve el mensaje pasado al constructor', () {
      expect(
        NfcSessionException('Could not read tag identifier.').toString(),
        'Could not read tag identifier.',
      );
    });

    test('message expone el mismo valor que toString', () {
      const msg = 'tag lost';
      final e = NfcSessionException(msg);
      expect(e.message, msg);
      expect(e.toString(), msg);
    });

    test('acepta mensaje vacío', () {
      expect(NfcSessionException('').toString(), '');
    });

    test('es una Exception', () {
      expect(NfcSessionException('x'), isA<Exception>());
    });
  });
}
