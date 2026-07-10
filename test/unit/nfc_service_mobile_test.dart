// test/unit/nfc_service_mobile_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'package:health_without_borders_frontend/src/core/nfc/nfc_service_mobile.dart';

// ── Canal y mock ──────────────────────────────────────────────────────────────

const _channel = MethodChannel('plugins.flutter.io/nfc_manager');

void _mockChannel({
  required bool nfcAvailable,
  bool throwOnStopSession = false,
}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (MethodCall call) async {
        switch (call.method) {
          case 'Nfc#isAvailable':
            return nfcAvailable;
          case 'Nfc#startSession':
            return null;
          case 'Nfc#stopSession':
            if (throwOnStopSession) {
              throw PlatformException(code: 'stop_session_error');
            }
            return null;
          case 'Nfc#disposeTag':
            return null;
          default:
            return null;
        }
      });
}

// ── Helpers  ────────────────────────────────────────────────────────────────

NfcTag _makeTag(Map<String, dynamic> data) {
  return NfcTag(handle: 'test-handle', data: data);
}

// ── main ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final defaultStartSessionImpl = NfcService.startSessionImpl;

  tearDown(() {
    NfcService.overrideReadDeviceUid = null;
    NfcService.startSessionImpl = defaultStartSessionImpl;
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  // ══════════════════════════════════════════════════════════════════════════
  // overrideReadDeviceUid
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcService.readDeviceUid — override', () {
    setUp(() => _mockChannel(nfcAvailable: false));

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
      await expectLater(
        NfcService.readDeviceUid(),
        throwsA(isA<NfcNotAvailableException>()),
      );
    });

    test('el override puede lanzar NfcSessionException', () async {
      NfcService.overrideReadDeviceUid = () async =>
          throw NfcSessionException('error simulado');
      await expectLater(
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

    test('lanza NfcNotAvailableException cuando override es null '
        'y NFC no disponible', () async {
      NfcService.overrideReadDeviceUid = null;
      await expectLater(
        NfcService.readDeviceUid(),
        throwsA(isA<NfcNotAvailableException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // isAvailable
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcService.isAvailable', () {
    test('devuelve false cuando NFC no está disponible', () async {
      _mockChannel(nfcAvailable: false);
      expect(await NfcService.isAvailable, isFalse);
    });

    test('devuelve true cuando NFC está disponible', () async {
      _mockChannel(nfcAvailable: true);
      expect(await NfcService.isAvailable, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // stopSession
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcService.stopSession', () {
    setUp(() => _mockChannel(nfcAvailable: false));

    test('completa sin error cuando no hay sesión activa', () async {
      await expectLater(NfcService.stopSession(), completes);
    });

    test('puede llamarse múltiples veces sin error', () async {
      await NfcService.stopSession();
      await NfcService.stopSession();
      await NfcService.stopSession();
    });

    test('captura silenciosamente errores del canal nativo', () async {
      _mockChannel(nfcAvailable: false, throwOnStopSession: true);
      await expectLater(NfcService.stopSession(), completes);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // extractIdentifier
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcService.extractIdentifier', () {
    test('extrae identifier desde clave "nfca"', () {
      final tag = _makeTag({
        'nfca': {
          'identifier': [0x04, 0xA1, 0xB2, 0xC3],
        },
      });
      expect(
        NfcService.extractIdentifier(tag),
        equals(Uint8List.fromList([0x04, 0xA1, 0xB2, 0xC3])),
      );
    });

    test('extrae identifier desde clave "nfcb"', () {
      final tag = _makeTag({
        'nfcb': {
          'identifier': [0x10, 0x20],
        },
      });
      expect(
        NfcService.extractIdentifier(tag),
        equals(Uint8List.fromList([0x10, 0x20])),
      );
    });

    test('extrae identifier desde clave "nfcv"', () {
      final tag = _makeTag({
        'nfcv': {
          'identifier': [0xAA, 0xBB],
        },
      });
      expect(
        NfcService.extractIdentifier(tag),
        equals(Uint8List.fromList([0xAA, 0xBB])),
      );
    });

    test('extrae identifier desde clave "nfcf"', () {
      final tag = _makeTag({
        'nfcf': {
          'identifier': [0xDE, 0xAD],
        },
      });
      expect(
        NfcService.extractIdentifier(tag),
        equals(Uint8List.fromList([0xDE, 0xAD])),
      );
    });

    test('extrae identifier desde clave "iso7816"', () {
      final tag = _makeTag({
        'iso7816': {
          'identifier': [0xCA, 0xFE],
        },
      });
      expect(
        NfcService.extractIdentifier(tag),
        equals(Uint8List.fromList([0xCA, 0xFE])),
      );
    });

    test('retorna null si ninguna clave conocida está presente', () {
      final tag = _makeTag({
        'unknown': {
          'identifier': [0x01],
        },
      });
      expect(NfcService.extractIdentifier(tag), isNull);
    });

    test('retorna null si identifier no es List', () {
      final tag = _makeTag({
        'nfca': {'identifier': 'not-a-list'},
      });
      expect(NfcService.extractIdentifier(tag), isNull);
    });

    test('retorna Uint8List vacío si identifier es lista vacía', () {
      final tag = _makeTag({
        'nfca': {'identifier': <int>[]},
      });
      expect(NfcService.extractIdentifier(tag), isEmpty);
    });

    test('usa la primera clave encontrada si hay varias', () {
      final tag = _makeTag({
        'nfca': {
          'identifier': [0x01],
        },
        'nfcb': {
          'identifier': [0x02],
        },
      });
      expect(
        NfcService.extractIdentifier(tag),
        equals(Uint8List.fromList([0x01])),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // bytesToHex
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcService.bytesToHex', () {
    test('formatea bytes correctamente', () {
      expect(
        NfcService.bytesToHex(Uint8List.fromList([0x04, 0xA1, 0xB2, 0xC3])),
        '04:A1:B2:C3',
      );
    });

    test('aplica padding en bytes menores a 0x10', () {
      expect(
        NfcService.bytesToHex(Uint8List.fromList([0x00, 0x0F, 0xFF])),
        '00:0F:FF',
      );
    });

    test('un solo byte no añade separador', () {
      expect(NfcService.bytesToHex(Uint8List.fromList([0xAB])), 'AB');
    });

    test('resultado en mayúsculas', () {
      expect(
        NfcService.bytesToHex(Uint8List.fromList([0xde, 0xad, 0xbe, 0xef])),
        'DE:AD:BE:EF',
      );
    });
  });

  group('NfcService.readDeviceUid — flujo completo con NFC disponible', () {
    test('retorna UID cuando el override simula lectura exitosa', () async {
      _mockChannel(nfcAvailable: true);
      NfcService.overrideReadDeviceUid = () async => '04:A1:B2:C3';
      expect(await NfcService.readDeviceUid(), '04:A1:B2:C3');
    });

    test(
      'lanza NfcSessionException cuando el override simula fallo de sesión',
      () async {
        _mockChannel(nfcAvailable: true);
        NfcService.overrideReadDeviceUid = () async =>
            throw NfcSessionException('tag lost');
        await expectLater(
          NfcService.readDeviceUid(),
          throwsA(
            isA<NfcSessionException>().having(
              (e) => e.message,
              'message',
              'tag lost',
            ),
          ),
        );
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // NfcNotAvailableException
  // ══════════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════════
  // NfcSessionException
  // ══════════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════════
  // startSessionImpl — implementación real por defecto
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcService.startSessionImpl — implementación real', () {
    setUp(() => _mockChannel(nfcAvailable: true));

    test(
      'invoca NfcManager.instance.startSession real cuando no fue sobrescrito',
      () {
        expect(
          () => NfcService.startSessionImpl(
            pollingOptions: {NfcPollingOption.iso14443},
            onDiscovered: (_) async {},
            onError: (_) async {},
          ),
          returnsNormally,
        );
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // readDeviceUid
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcService.readDeviceUid — flujo real (onDiscovered)', () {
    setUp(() {
      _mockChannel(nfcAvailable: true);
      NfcService.overrideReadDeviceUid = null;
    });

    test(
      'retorna el UID cuando se descubre un tag con identifier válido',
      () async {
        final tag = _makeTag({
          'nfca': {
            'identifier': [0x04, 0xA1],
          },
        });
        NfcService.startSessionImpl =
            ({
              required pollingOptions,
              required onDiscovered,
              required onError,
            }) {
              onDiscovered(tag);
            };

        expect(await NfcService.readDeviceUid(), '04:A1');
      },
    );

    test(
      'lanza NfcSessionException cuando el tag no tiene identifier (id null)',
      () async {
        final tag = _makeTag({'unknown': {}});
        NfcService.startSessionImpl =
            ({
              required pollingOptions,
              required onDiscovered,
              required onError,
            }) {
              onDiscovered(tag);
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
      'lanza NfcSessionException cuando el identifier es una lista vacía',
      () async {
        final tag = _makeTag({
          'nfca': {'identifier': <int>[]},
        });
        NfcService.startSessionImpl =
            ({
              required pollingOptions,
              required onDiscovered,
              required onError,
            }) {
              onDiscovered(tag);
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

    test('envuelve en NfcSessionException cualquier excepción lanzada '
        'al procesar el tag', () async {
      final tag = _makeTag({
        'nfca': {
          'identifier': ['no-es-un-entero'],
        },
      });
      NfcService.startSessionImpl =
          ({required pollingOptions, required onDiscovered, required onError}) {
            onDiscovered(tag);
          };

      await expectLater(
        NfcService.readDeviceUid(),
        throwsA(isA<NfcSessionException>()),
      );
    });

    test('ignora invocaciones adicionales de onDiscovered tras completar '
        'el completer', () async {
      final tag = _makeTag({
        'nfca': {
          'identifier': [0x01],
        },
      });
      NfcService.startSessionImpl =
          ({required pollingOptions, required onDiscovered, required onError}) {
            onDiscovered(tag);
            onDiscovered(tag);
          };

      expect(await NfcService.readDeviceUid(), '01');
    });
  });

  group('NfcService.readDeviceUid — flujo real (onError)', () {
    setUp(() {
      _mockChannel(nfcAvailable: true);
      NfcService.overrideReadDeviceUid = null;
    });

    test(
      'lanza NfcSessionException con el mensaje del error de la plataforma',
      () async {
        NfcService.startSessionImpl =
            ({
              required pollingOptions,
              required onDiscovered,
              required onError,
            }) {
              onError('tag lost');
            };

        await expectLater(
          NfcService.readDeviceUid(),
          throwsA(
            isA<NfcSessionException>().having(
              (e) => e.message,
              'message',
              'tag lost',
            ),
          ),
        );
      },
    );

    test('ignora invocaciones adicionales de onError tras completar '
        'el completer', () async {
      NfcService.startSessionImpl =
          ({required pollingOptions, required onDiscovered, required onError}) {
            onError('primer error');
            onError('segundo error');
          };

      await expectLater(
        NfcService.readDeviceUid(),
        throwsA(
          isA<NfcSessionException>().having(
            (e) => e.message,
            'message',
            'primer error',
          ),
        ),
      );
    });
  });
}
