// test/unit/nfc_session_types_test.dart

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_manager/ndef_record.dart';

import 'package:health_without_borders_frontend/src/core/nfc/nfc_session_types.dart';

// ── Fakes ───────────────────────────────────────────────────────────────────

class _FakeNdef implements HwbNdef {
  NdefMessage? written;

  @override
  bool get isWritable => true;

  @override
  int get maxSize => 492;

  @override
  NdefMessage? get cachedMessage => null;

  @override
  Future<void> write(NdefMessage message) async {
    written = message;
  }
}

class _FakeTagSource implements NfcTagSource {
  @override
  Future<T> withTag<T>(
    Future<T> Function(HwbTag tag) action, {
    Duration timeout = const Duration(seconds: 20),
    NfcCancelToken? cancel,
    String? alertMessage,
  }) {
    return action(const HwbTag(uid: '04:A1:B2'));
  }
}

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // HwbTag / HwbNdef / NfcTagSource
  // ══════════════════════════════════════════════════════════════════════════

  group('HwbTag', () {
    test('ndef es null por defecto (chip sin formato NDEF)', () {
      const tag = HwbTag(uid: '04:A1:B2');

      expect(tag.uid, '04:A1:B2');
      expect(tag.ndef, isNull);
    });

    test('conserva el ndef recibido', () {
      final ndef = _FakeNdef();
      final tag = HwbTag(uid: '04:A1:B2', ndef: ndef);

      expect(tag.ndef, same(ndef));
    });

    test('uid vacío significa que no se pudo leer el identificador', () {
      const tag = HwbTag(uid: '');

      expect(tag.uid, isEmpty);
    });
  });

  group('HwbNdef', () {
    test(
      'una implementación puede escribir y exponer sus propiedades',
      () async {
        final ndef = _FakeNdef();
        const message = NdefMessage(records: []);

        await ndef.write(message);

        expect(ndef.written, same(message));
        expect(ndef.isWritable, isTrue);
        expect(ndef.maxSize, 492);
        expect(ndef.cachedMessage, isNull);
      },
    );
  });

  group('NfcTagSource', () {
    test(
      'withTag ejecuta la acción contra el chip y devuelve su resultado',
      () async {
        final NfcTagSource source = _FakeTagSource();

        final uid = await source.withTag<String>((tag) async => tag.uid);

        expect(uid, '04:A1:B2');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // NfcRadioState
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcRadioState', () {
    test('expone los seis estados en el orden esperado', () {
      expect(NfcRadioState.values, [
        NfcRadioState.unsupported,
        NfcRadioState.disabled,
        NfcRadioState.off,
        NfcRadioState.idle,
        NfcRadioState.waiting,
        NfcRadioState.working,
      ]);
    });

    test('cada estado tiene un nombre distinto', () {
      final names = NfcRadioState.values.map((s) => s.name).toSet();

      expect(names, hasLength(NfcRadioState.values.length));
      expect(NfcRadioState.waiting.name, 'waiting');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // NfcCancelToken
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcCancelToken', () {
    test('nace sin cancelar', () {
      final token = NfcCancelToken();

      expect(token.isCancelled, isFalse);
    });

    test('cancel() marca el token como cancelado', () {
      final token = NfcCancelToken();

      token.cancel();

      expect(token.isCancelled, isTrue);
    });

    test('whenCancelled se completa cuando se llama cancel()', () async {
      final token = NfcCancelToken();
      var completed = false;
      final waiting = token.whenCancelled.then((_) => completed = true);

      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse, reason: 'no debe completarse antes de cancel');

      token.cancel();
      await waiting;

      expect(completed, isTrue);
    });

    test('whenCancelled ya completo si se cancela antes de escuchar', () async {
      final token = NfcCancelToken()..cancel();

      await expectLater(token.whenCancelled, completes);
    });

    test('cancel() es idempotente: una segunda llamada no lanza', () {
      final token = NfcCancelToken();

      token.cancel();

      expect(token.cancel, returnsNormally);
      expect(token.isCancelled, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // formatNfcUid
  // ══════════════════════════════════════════════════════════════════════════

  group('formatNfcUid', () {
    test('formatea bytes como hex mayúscula separado por dos puntos', () {
      expect(formatNfcUid(Uint8List.fromList([0x04, 0xA1, 0xB2])), '04:A1:B2');
    });

    test('rellena con cero los bytes menores a 0x10', () {
      expect(formatNfcUid(Uint8List.fromList([0x00, 0x0F, 0x01])), '00:0F:01');
    });

    test('un solo byte no lleva separador', () {
      expect(formatNfcUid(Uint8List.fromList([0xFF])), 'FF');
    });

    test('lista vacía devuelve cadena vacía', () {
      expect(formatNfcUid(Uint8List(0)), '');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // normalizeNfcUid
  // ══════════════════════════════════════════════════════════════════════════

  group('normalizeNfcUid', () {
    test('quita separadores y pasa a mayúsculas', () {
      expect(normalizeNfcUid('ab:cd:ef'), 'ABCDEF');
    });

    test('trata igual distintos formatos del mismo UID', () {
      final expected = normalizeNfcUid('AB:CD:EF');

      expect(normalizeNfcUid('ab-cd-ef'), expected);
      expect(normalizeNfcUid('ab cd ef'), expected);
      expect(normalizeNfcUid('AB.CD.EF'), expected);
      expect(normalizeNfcUid('abcdef'), expected);
    });

    test('descarta caracteres que no son hexadecimales', () {
      expect(normalizeNfcUid('0x04:zz:A1'), '004A1');
    });

    test('cadena vacía devuelve cadena vacía', () {
      expect(normalizeNfcUid(''), '');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // normalizeTypedNfcUid
  // ══════════════════════════════════════════════════════════════════════════

  group('normalizeTypedNfcUid', () {
    test('cadena vacía devuelve cadena vacía', () {
      expect(normalizeTypedNfcUid(''), '');
    });

    test('solo espacios devuelve cadena vacía', () {
      expect(normalizeTypedNfcUid('   \t '), '');
    });

    test('solo separadores (sin dígitos hex) devuelve cadena vacía', () {
      expect(normalizeTypedNfcUid(':'), '');
      expect(normalizeTypedNfcUid(' . - : '), '');
    });

    test('inserta dos puntos cada dos caracteres', () {
      expect(normalizeTypedNfcUid('04A1B2C3'), '04:A1:B2:C3');
    });

    test('conserva mayúsculas y minúsculas originales', () {
      expect(normalizeTypedNfcUid('04a1B2c3'), '04:a1:B2:c3');
    });

    test('acepta espacios, guiones, puntos y dos puntos como separadores', () {
      expect(normalizeTypedNfcUid('04 a1-b2.c3:d4'), '04:a1:b2:c3:d4');
    });

    test('recorta espacios al inicio y al final', () {
      expect(normalizeTypedNfcUid('  04A1  '), '04:A1');
    });

    test('longitud impar deja el último bloque con un solo carácter', () {
      expect(normalizeTypedNfcUid('abc'), 'ab:c');
      expect(normalizeTypedNfcUid('04A1B'), '04:A1:B');
    });

    test('un solo carácter hex se devuelve sin separador', () {
      expect(normalizeTypedNfcUid('A'), 'A');
    });

    test('un UID ya formateado queda igual', () {
      expect(normalizeTypedNfcUid('04:A1:B2'), '04:A1:B2');
    });

    test('texto que no es hexadecimal se devuelve recortado, sin tocar', () {
      expect(normalizeTypedNfcUid('  hola mundo  '), 'hola mundo');
    });

    test('mezcla de hex y caracteres inválidos se devuelve tal cual', () {
      expect(normalizeTypedNfcUid('04:GG:B2'), '04:GG:B2');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Excepciones
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcSessionException', () {
    test('toString devuelve el mensaje tal cual', () {
      final e = NfcSessionException('algo falló');

      expect(e.message, 'algo falló');
      expect(e.toString(), 'algo falló');
      expect(e, isA<Exception>());
    });
  });

  group('NfcNotAvailableException', () {
    test('toString describe que no hay NFC en el dispositivo', () {
      expect(
        NfcNotAvailableException().toString(),
        'NFC is not available on this device.',
      );
    });

    test('no es un NfcSessionException (se captura por separado)', () {
      final Object e = NfcNotAvailableException();

      expect(e, isA<Exception>());
      expect(e, isNot(isA<NfcSessionException>()));
    });
  });

  group('NfcDisabledException', () {
    test('indica que hay que activar NFC en ajustes', () {
      final e = NfcDisabledException();

      expect(e, isA<NfcSessionException>());
      expect(e.message, 'NFC is turned off. Enable it in system settings.');
      expect(e.toString(), e.message);
    });
  });

  group('NfcBusyException', () {
    test('indica que ya hay otra operación en curso', () {
      final e = NfcBusyException();

      expect(e, isA<NfcSessionException>());
      expect(e.message, 'Another NFC operation is already in progress.');
      expect(e.toString(), e.message);
    });
  });

  group('NfcTimeoutException', () {
    test('conserva el timeout y muestra el mensaje para el usuario', () {
      const timeout = Duration(seconds: 20);
      final e = NfcTimeoutException(timeout);

      expect(e, isA<NfcSessionException>());
      expect(e.timeout, timeout);
      expect(
        e.message,
        'No device detected. Hold it against the reader and try again.',
      );
      expect(e.toString(), e.message);
    });
  });

  group('NfcCancelledException', () {
    test('indica que la operación fue cancelada', () {
      final e = NfcCancelledException();

      expect(e, isA<NfcSessionException>());
      expect(e.message, 'NFC operation cancelled.');
      expect(e.toString(), e.message);
    });
  });

  group('NfcInterruptedException', () {
    test('indica que la operación fue interrumpida', () {
      final e = NfcInterruptedException();

      expect(e, isA<NfcSessionException>());
      expect(e.message, 'NFC operation interrupted.');
      expect(e.toString(), e.message);
    });
  });

  group('NfcTagAlreadyPresentException', () {
    test('pide retirar el dispositivo y volver a acercarlo', () {
      final e = NfcTagAlreadyPresentException();

      expect(e, isA<NfcSessionException>());
      expect(e.message, 'Lift the device away and tap it again.');
      expect(e.toString(), e.message);
    });
  });

  group('jerarquía de excepciones', () {
    test('cada excepción de sesión se puede lanzar y capturar como base', () {
      final thrown = <NfcSessionException>[
        NfcDisabledException(),
        NfcBusyException(),
        NfcTimeoutException(const Duration(seconds: 1)),
        NfcCancelledException(),
        NfcInterruptedException(),
        NfcTagAlreadyPresentException(),
      ];

      for (final e in thrown) {
        expect(() => throw e, throwsA(isA<NfcSessionException>()));
      }
    });
  });
}
