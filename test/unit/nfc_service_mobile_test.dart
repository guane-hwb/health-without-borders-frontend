// test/unit/nfc_service_mobile_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/nfc/nfc_service_mobile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/nfc_manager'),
          (MethodCall call) async {
            if (call.method == 'Nfc#isAvailable') return false;
            return null;
          },
        );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/nfc_manager'),
          null,
        );
  });

  tearDown(() {
    NfcService.overrideReadDeviceUid = null;
  });

  // ── overrideReadDeviceUid ────────────────────────────────────────────────

  group('NfcService.readDeviceUid — override', () {
    test('retorna el UID del override cuando está definido', () async {
      NfcService.overrideReadDeviceUid = () async => '04:A1:B2:C3';

      final uid = await NfcService.readDeviceUid();

      expect(uid, equals('04:A1:B2:C3'));
    });

    test('el override puede devolver cualquier string', () async {
      NfcService.overrideReadDeviceUid = () async => 'FF:EE:DD:CC:BB:AA';

      final uid = await NfcService.readDeviceUid();

      expect(uid, equals('FF:EE:DD:CC:BB:AA'));
    });

    test('el override puede lanzar NfcNotAvailableException', () async {
      NfcService.overrideReadDeviceUid = () async =>
          throw NfcNotAvailableException();

      expect(
        () => NfcService.readDeviceUid(),
        throwsA(isA<NfcNotAvailableException>()),
      );
    });

    test('el override puede lanzar NfcSessionException', () async {
      NfcService.overrideReadDeviceUid = () async =>
          throw NfcSessionException('error simulado');

      expect(
        () => NfcService.readDeviceUid(),
        throwsA(
          isA<NfcSessionException>().having(
            (e) => e.message,
            'message',
            equals('error simulado'),
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

  // ── stopSession ──────────────────────────────────────────────────────────

  group('NfcService.stopSession', () {
    test('no lanza excepción aunque no haya sesión activa', () async {
      await expectLater(NfcService.stopSession(), completes);
    });

    test('puede llamarse múltiples veces sin error', () async {
      await NfcService.stopSession();
      await NfcService.stopSession();
      await NfcService.stopSession();
    });
  });

  // ── NfcNotAvailableException ─────────────────────────────────────────────

  group('NfcNotAvailableException', () {
    test('toString devuelve el mensaje esperado', () {
      final exception = NfcNotAvailableException();
      expect(
        exception.toString(),
        equals('NFC is not available on this device.'),
      );
    });

    test('es una Exception', () {
      expect(NfcNotAvailableException(), isA<Exception>());
    });
  });

  // ── NfcSessionException ──────────────────────────────────────────────────

  group('NfcSessionException', () {
    test('toString devuelve el mensaje pasado al constructor', () {
      final exception = NfcSessionException('Could not read tag identifier.');
      expect(exception.toString(), equals('Could not read tag identifier.'));
    });

    test('message expone el mismo valor que toString', () {
      const msg = 'tag lost';
      final exception = NfcSessionException(msg);
      expect(exception.message, equals(msg));
      expect(exception.toString(), equals(msg));
    });

    test('acepta mensaje vacío', () {
      final exception = NfcSessionException('');
      expect(exception.toString(), equals(''));
    });

    test('es una Exception', () {
      expect(NfcSessionException('x'), isA<Exception>());
    });
  });
}
