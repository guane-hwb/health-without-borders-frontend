// test/unit/nfc_service_mobile_test.dart

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_manager/nfc_manager.dart' show NfcAvailability;

import 'package:health_without_borders_frontend/src/core/nfc/nfc_service_mobile.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_session_manager.dart';

// ── Fakes ───────────────────────────────────────────────────────────────────
//
// Nothing here touches nfc_manager. v4 seals its tag types (`final class
// NfcTag`, `@protected Object data`, an unexported TagPigeon), so the old
// approach — building fake NfcTags and mocking the plugin's method channel —
// is not expressible any more. The seam is NfcTagSource instead, which is
// where it should have been all along: these tests now describe HWB's
// behaviour rather than the plugin's wire format.

/// An [NfcTagSource] that hands [action] whatever tag it is told to.
class _FakeTagSource implements NfcTagSource {
  _FakeTagSource.tag(this._tag);
  _FakeTagSource.throws(this._error);

  HwbTag? _tag;
  Object? _error;

  int calls = 0;
  Duration? lastTimeout;
  NfcCancelToken? lastCancel;

  @override
  Future<T> withTag<T>(
    Future<T> Function(HwbTag tag) action, {
    Duration timeout = const Duration(seconds: 20),
    NfcCancelToken? cancel,
  }) async {
    calls++;
    lastTimeout = timeout;
    lastCancel = cancel;
    if (_error != null) throw _error!;
    return action(_tag!);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(NfcService.resetForTest);

  // ══════════════════════════════════════════════════════════════════════════
  // overrideReadDeviceUid
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcService.readDeviceUid — override', () {
    test('retorna el UID del override cuando está definido', () async {
      NfcService.overrideReadDeviceUid = () async => '04:A1:B2:C3';
      expect(await NfcService.readDeviceUid(), '04:A1:B2:C3');
    });

    test('el override puede devolver cualquier string', () async {
      NfcService.overrideReadDeviceUid = () async => 'FF:EE:DD:CC:BB:AA';
      expect(await NfcService.readDeviceUid(), 'FF:EE:DD:CC:BB:AA');
    });

    test('el override cortocircuita la radio por completo', () async {
      final source = _FakeTagSource.tag(const HwbTag(uid: '04:AA'));
      NfcService.tagSource = source;
      NfcService.overrideReadDeviceUid = () async => '99:99';
      expect(await NfcService.readDeviceUid(), '99:99');
      expect(source.calls, 0);
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
  });

  // ══════════════════════════════════════════════════════════════════════════
  // readDeviceUid — vía la radio
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcService.readDeviceUid — radio', () {
    test('retorna el UID del chip acercado', () async {
      NfcService.tagSource = _FakeTagSource.tag(
        const HwbTag(uid: '04:03:46:71:8F:61:80'),
      );
      expect(await NfcService.readDeviceUid(), '04:03:46:71:8F:61:80');
    });

    test('no necesita que el chip esté formateado como NDEF', () async {
      NfcService.tagSource = _FakeTagSource.tag(const HwbTag(uid: '04:AA'));
      expect(await NfcService.readDeviceUid(), '04:AA');
    });

    test(
      'lanza NfcSessionException si el chip no tiene identificador legible',
      () async {
        NfcService.tagSource = _FakeTagSource.tag(const HwbTag(uid: ''));
        await expectLater(
          NfcService.readDeviceUid(),
          throwsA(isA<NfcSessionException>()),
        );
      },
    );

    test('pasa el timeout recibido a la radio', () async {
      final source = _FakeTagSource.tag(const HwbTag(uid: '04:AA'));
      NfcService.tagSource = source;
      await NfcService.readDeviceUid(timeout: const Duration(seconds: 5));
      expect(source.lastTimeout, const Duration(seconds: 5));
    });

    test('usa 20 s por defecto', () async {
      final source = _FakeTagSource.tag(const HwbTag(uid: '04:AA'));
      NfcService.tagSource = source;
      await NfcService.readDeviceUid();
      expect(source.lastTimeout, NfcSessionManager.defaultTimeout);
    });

    test('propaga el token de cancelación', () async {
      final source = _FakeTagSource.tag(const HwbTag(uid: '04:AA'));
      final token = NfcCancelToken();
      NfcService.tagSource = source;
      await NfcService.readDeviceUid(cancel: token);
      expect(source.lastCancel, same(token));
    });

    // Antes de la migración estos tres casos eran indistinguibles: en Android
    // el plugin nunca invocaba onError, así que cualquiera de ellos dejaba el
    // botón girando para siempre en vez de fallar.
    test('propaga NfcTimeoutException', () async {
      NfcService.tagSource = _FakeTagSource.throws(
        NfcTimeoutException(const Duration(seconds: 20)),
      );
      await expectLater(
        NfcService.readDeviceUid(),
        throwsA(isA<NfcTimeoutException>()),
      );
    });

    test(
      'propaga NfcBusyException cuando ya hay otra lectura en curso',
      () async {
        NfcService.tagSource = _FakeTagSource.throws(NfcBusyException());
        await expectLater(
          NfcService.readDeviceUid(),
          throwsA(isA<NfcBusyException>()),
        );
      },
    );

    test('propaga NfcTagAlreadyPresentException', () async {
      NfcService.tagSource = _FakeTagSource.throws(
        NfcTagAlreadyPresentException(),
      );
      await expectLater(
        NfcService.readDeviceUid(),
        throwsA(isA<NfcTagAlreadyPresentException>()),
      );
    });

    test('propaga NfcDisabledException', () async {
      NfcService.tagSource = _FakeTagSource.throws(NfcDisabledException());
      await expectLater(
        NfcService.readDeviceUid(),
        throwsA(isA<NfcDisabledException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // isAvailable
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcService.isAvailable', () {
    test('devuelve true cuando el NFC está encendido', () async {
      NfcService.availabilityProbe = () async => NfcAvailability.enabled;
      expect(await NfcService.isAvailable, isTrue);
    });

    test('devuelve false cuando el NFC está apagado', () async {
      NfcService.availabilityProbe = () async => NfcAvailability.disabled;
      expect(await NfcService.isAvailable, isFalse);
    });

    test('devuelve false cuando el dispositivo no tiene NFC', () async {
      NfcService.availabilityProbe = () async => NfcAvailability.unsupported;
      expect(await NfcService.isAvailable, isFalse);
    });

    test('devuelve false —sin propagar— si el canal nativo falla', () async {
      NfcService.availabilityProbe = () async => throw Exception('boom');
      expect(await NfcService.isAvailable, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // stopSession
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcService.stopSession', () {
    test('completa sin error cuando no hay nada pendiente', () async {
      await expectLater(NfcService.stopSession(), completes);
    });

    test('puede llamarse múltiples veces sin error', () async {
      await NfcService.stopSession();
      await NfcService.stopSession();
      await NfcService.stopSession();
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // formatNfcUid  (antes NfcService.bytesToHex)
  // ══════════════════════════════════════════════════════════════════════════

  group('formatNfcUid', () {
    test('formatea bytes correctamente', () {
      expect(
        formatNfcUid(Uint8List.fromList([0x04, 0xA1, 0xB2, 0xC3])),
        '04:A1:B2:C3',
      );
    });

    test('aplica padding en bytes menores a 0x10', () {
      expect(formatNfcUid(Uint8List.fromList([0x00, 0x0F, 0x01])), '00:0F:01');
    });

    test('usa mayúsculas', () {
      expect(formatNfcUid(Uint8List.fromList([0xab, 0xcd, 0xef])), 'AB:CD:EF');
    });

    test('un solo byte no lleva separador', () {
      expect(formatNfcUid(Uint8List.fromList([0x7F])), '7F');
    });

    test('lista vacía produce string vacío', () {
      expect(formatNfcUid(Uint8List(0)), '');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // normalizeNfcUid
  // ══════════════════════════════════════════════════════════════════════════

  group('normalizeNfcUid', () {
    test('quita separadores', () {
      expect(normalizeNfcUid('04:A1:B2:C3'), '04A1B2C3');
    });

    test('es insensible a mayúsculas', () {
      expect(normalizeNfcUid('04:a1:b2:c3'), normalizeNfcUid('04:A1:B2:C3'));
    });

    test('tolera formatos distintos del mismo UID', () {
      expect(normalizeNfcUid('04-a1-b2-c3'), normalizeNfcUid('04A1B2C3'));
      expect(normalizeNfcUid('04 A1 B2 C3'), normalizeNfcUid('04:a1:b2:c3'));
    });

    test('descarta cualquier caracter no hexadecimal', () {
      expect(normalizeNfcUid('04:A1!?*'), '04A1');
    });

    test('absorbe las letras hex de un prefijo — filtra, no valida', () {
      // Deliberado, y peligroso: normalizeNfcUid quita lo no-hexadecimal, y
      // las letras A-F de un prefijo SON hexadecimal. Nunca le pases un UID
      // con prefijo; pasale sólo el UID.
      expect(normalizeNfcUid('HWB-04:A1'), 'B04A1');
      expect(normalizeNfcUid('uid=04:A1'), 'D04A1');
    });

    test('string vacío queda vacío', () {
      expect(normalizeNfcUid(''), '');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // NfcCancelToken
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcCancelToken', () {
    test('arranca sin cancelar', () {
      expect(NfcCancelToken().isCancelled, isFalse);
    });

    test('cancel() lo marca y completa whenCancelled', () async {
      final token = NfcCancelToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
      await expectLater(token.whenCancelled, completes);
    });

    test('cancel() es idempotente', () {
      final token = NfcCancelToken()..cancel();
      expect(token.cancel, returnsNormally);
    });
  });
}
