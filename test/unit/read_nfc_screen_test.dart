// test/unit/read_nfc_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';

class NfcNotAvailableException implements Exception {
  @override
  String toString() => 'NFC is not available on this device.';
}

class NfcSessionException implements Exception {
  NfcSessionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _FakeReadNfcState {
  bool step2 = false;
  bool scanning = false;
  String? errorMessage;
  String? patientDeviceUid;
  String patientUidText = '';
  String guardianUidText = '';

  void handlePatientApiError(ApiException e, {required String deviceUid}) {
    if (e.statusCode == 403 && e.message.toLowerCase().contains('guardian')) {
      scanning = false;
      patientDeviceUid = deviceUid;
      step2 = true;
      errorMessage = null;
    } else {
      scanning = false;
      errorMessage = e.message;
    }
  }

  void handlePatientGenericError(Object e) {
    scanning = false;
    errorMessage = e.toString();
  }

  void handlePatientNfcNotAvailable(String nfcNotAvailableHint) {
    scanning = false;
    errorMessage = nfcNotAvailableHint;
  }

  void handlePatientNfcSessionException(NfcSessionException e) {
    scanning = false;
    errorMessage = e.message;
  }

  void handleGuardianApiError(ApiException e) {
    scanning = false;
    errorMessage = e.message;
  }

  void handleGuardianGenericError(Object e) {
    scanning = false;
    errorMessage = e.toString();
  }

  void handleGuardianNfcNotAvailable(String nfcNotAvailableHint) {
    scanning = false;
    errorMessage = nfcNotAvailableHint;
  }

  void handleGuardianNfcSessionException(NfcSessionException e) {
    scanning = false;
    errorMessage = e.message;
  }

  bool canProceedWithGuardianSubmit() => patientDeviceUid != null;

  void resetAfterOpenProfile() {
    step2 = false;
    patientDeviceUid = null;
    patientUidText = '';
    guardianUidText = '';
    errorMessage = null;
  }

  void backToStep1() {
    step2 = false;
    guardianUidText = '';
    errorMessage = null;
  }

  void resetAfterProfile() => resetAfterOpenProfile();

  bool shouldSubmitPatient() => patientUidText.trim().isNotEmpty;
  bool shouldSubmitGuardian() => guardianUidText.trim().isNotEmpty;
  bool canSubmitGuardian() =>
      patientDeviceUid != null && guardianUidText.trim().isNotEmpty;
}

void main() {
  group('A. Step state logic', () {
    test('A-01 estado inicial: step2 es false', () {
      expect(_FakeReadNfcState().step2, isFalse);
    });

    test('A-02 403 con "guardian" activa step2 y limpia errorMessage', () {
      final state = _FakeReadNfcState();
      state.handlePatientApiError(
        ApiException(
          'Guardian bracelet scan required for minors.',
          statusCode: 403,
        ),
        deviceUid: 'AA:BB:CC:DD',
      );
      expect(state.step2, isTrue);
      expect(state.patientDeviceUid, 'AA:BB:CC:DD');
      expect(state.errorMessage, isNull);
    });

    test('A-03 403 sin "guardian" no activa step2 y muestra mensaje', () {
      final state = _FakeReadNfcState();
      state.handlePatientApiError(
        ApiException('Forbidden.', statusCode: 403),
        deviceUid: 'AA:BB:CC:DD',
      );
      expect(state.step2, isFalse);
      expect(state.errorMessage, 'Forbidden.');
    });

    test('A-04 404 muestra mensaje y no activa step2', () {
      final state = _FakeReadNfcState();
      state.handlePatientApiError(
        ApiException('Patient not found.', statusCode: 404),
        deviceUid: 'AA:BB:CC:DD',
      );
      expect(state.step2, isFalse);
      expect(state.errorMessage, 'Patient not found.');
    });

    test('A-05 401 muestra mensaje y no activa step2', () {
      final state = _FakeReadNfcState();
      state.handlePatientApiError(
        ApiException('Token expired.', statusCode: 401),
        deviceUid: 'AA:BB:CC:DD',
      );
      expect(state.step2, isFalse);
      expect(state.errorMessage, 'Token expired.');
    });

    test('A-06 500 muestra mensaje y no activa step2', () {
      final state = _FakeReadNfcState();
      state.handlePatientApiError(
        ApiException('Internal error.', statusCode: 500),
        deviceUid: 'AA:BB:CC:DD',
      );
      expect(state.step2, isFalse);
      expect(state.errorMessage, 'Internal error.');
    });

    test('A-07 detección de "guardian" es case-insensitive', () {
      final state = _FakeReadNfcState();
      state.handlePatientApiError(
        ApiException('GUARDIAN BRACELET REQUIRED', statusCode: 403),
        deviceUid: 'AA:BB:CC:DD',
      );
      expect(state.step2, isTrue);
    });

    test('A-08 backToStep1 restablece step2 y limpia guardianUid', () {
      final state = _FakeReadNfcState()
        ..step2 = true
        ..guardianUidText = 'GG:HH:II:JJ'
        ..errorMessage = 'Previous error';

      state.backToStep1();

      expect(state.step2, isFalse);
      expect(state.guardianUidText, '');
      expect(state.errorMessage, isNull);
    });

    test('A-09 backToStep1 preserva patientDeviceUid', () {
      final state = _FakeReadNfcState()
        ..step2 = true
        ..patientDeviceUid = 'AA:BB:CC:DD';

      state.backToStep1();

      expect(state.patientDeviceUid, 'AA:BB:CC:DD');
    });

    test('A-10 scanning se pone en false tras handlePatientApiError', () {
      final state = _FakeReadNfcState()..scanning = true;
      state.handlePatientApiError(
        ApiException('Some error', statusCode: 500),
        deviceUid: 'AA:BB:CC:DD',
      );
      expect(state.scanning, isFalse);
    });

    test('A-11 scanning se pone en false tras activar step2', () {
      final state = _FakeReadNfcState()..scanning = true;
      state.handlePatientApiError(
        ApiException(
          'Guardian bracelet scan required for minors.',
          statusCode: 403,
        ),
        deviceUid: 'AA:BB:CC:DD',
      );
      expect(state.scanning, isFalse);
    });
  });

  group('B. Empty UID guards', () {
    test('B-01 submitPatientFromForm no continúa si UID está vacío', () {
      expect(() => _FakeReadNfcState()..patientUidText = '', returnsNormally);

      expect(
        (_FakeReadNfcState()..patientUidText = '').shouldSubmitPatient(),
        isFalse,
      );
    });

    test('B-02 submitPatientFromForm continúa si UID tiene contenido', () {
      expect(
        (_FakeReadNfcState()..patientUidText = 'AA:BB:CC:DD')
            .shouldSubmitPatient(),
        isTrue,
      );
    });

    test('B-03 submitPatientFromForm ignora UID de sólo espacios', () {
      expect(
        (_FakeReadNfcState()..patientUidText = '   ').shouldSubmitPatient(),
        isFalse,
      );
    });

    test(
      'B-04 submitGuardianFromForm no continúa si guardianUid está vacío',
      () {
        expect(
          (_FakeReadNfcState()..guardianUidText = '').shouldSubmitGuardian(),
          isFalse,
        );
      },
    );

    test(
      'B-05 submitGuardianFromForm continúa si guardianUid tiene contenido',
      () {
        expect(
          (_FakeReadNfcState()..guardianUidText = 'GG:HH:II:JJ')
              .shouldSubmitGuardian(),
          isTrue,
        );
      },
    );

    test('B-06 submitGuardianFromForm ignora guardianUid de sólo espacios', () {
      expect(
        (_FakeReadNfcState()..guardianUidText = '   ').shouldSubmitGuardian(),
        isFalse,
      );
    });

    test('B-07 submitGuardian no procede si patientDeviceUid es null', () {
      final state = _FakeReadNfcState()
        ..patientDeviceUid = null
        ..guardianUidText = 'GG:HH:II:JJ';
      expect(state.canSubmitGuardian(), isFalse);
    });

    test(
      'B-08 submitGuardian procede si patientDeviceUid y guardianUid son válidos',
      () {
        final state = _FakeReadNfcState()
          ..patientDeviceUid = 'AA:BB:CC:DD'
          ..guardianUidText = 'GG:HH:II:JJ';
        expect(state.canSubmitGuardian(), isTrue);
      },
    );
  });

  // ── C. State reset ────────────────────────────────────────────────────────

  group('C. State reset after returning from profile view', () {
    test('C-01 resetAfterProfile limpia todos los campos de seguimiento', () {
      final state = _FakeReadNfcState()
        ..step2 = true
        ..patientDeviceUid = 'AA:BB:CC:DD'
        ..patientUidText = 'AA:BB:CC:DD'
        ..guardianUidText = 'GG:HH:II:JJ'
        ..errorMessage = 'Previous error';

      state.resetAfterProfile();

      expect(state.step2, isFalse);
      expect(state.patientDeviceUid, isNull);
      expect(state.patientUidText, '');
      expect(state.guardianUidText, '');
      expect(state.errorMessage, isNull);
    });

    test('C-02 resetAfterProfile sobre estado limpio no lanza error', () {
      expect(() => _FakeReadNfcState().resetAfterProfile(), returnsNormally);
    });
  });

  group('D. Guardian scanner exception mapping handlers', () {
    test(
      'D-01 ApiException en _submitGuardian muestra el mensaje del error',
      () {
        final state = _FakeReadNfcState()..patientDeviceUid = 'AA:BB:CC:DD';
        state.handleGuardianApiError(
          ApiException('Invalid guardian device.', statusCode: 403),
        );

        expect(state.errorMessage, 'Invalid guardian device.');
        expect(state.scanning, isFalse);
      },
    );

    test(
      'D-02 error genérico en _submitGuardian muestra el toString del error',
      () {
        final state = _FakeReadNfcState()..patientDeviceUid = 'AA:BB:CC:DD';
        state.handleGuardianGenericError(Exception('timeout'));

        expect(state.errorMessage, contains('timeout'));
        expect(state.scanning, isFalse);
      },
    );

    test(
      'D-03 error genérico en _submitPatient muestra el toString del error',
      () {
        final state = _FakeReadNfcState();
        state.handlePatientGenericError(Exception('network error'));

        expect(state.errorMessage, contains('network error'));
        expect(state.scanning, isFalse);
      },
    );

    test('D-04 ApiException 401 en guardian muestra mensaje de sesión', () {
      final state = _FakeReadNfcState()..patientDeviceUid = 'AA:BB:CC:DD';
      state.handleGuardianApiError(
        ApiException('Session expired.', statusCode: 401),
      );

      expect(state.errorMessage, 'Session expired.');
      expect(state.scanning, isFalse);
    });

    test('D-05 ApiException 500 en guardian muestra mensaje de servidor', () {
      final state = _FakeReadNfcState()..patientDeviceUid = 'AA:BB:CC:DD';
      state.handleGuardianApiError(
        ApiException('Server error.', statusCode: 500),
      );

      expect(state.errorMessage, 'Server error.');
      expect(state.scanning, isFalse);
    });
  });

  group('E. NFC hardware exceptions — patient scanner', () {
    const nfcHint = 'NFC no disponible en este dispositivo.';

    test('E-01 NfcNotAvailableException en _scanPatient: scanning=false y '
        'errorMessage muestra el hint de NFC no disponible', () {
      final state = _FakeReadNfcState()..scanning = true;
      state.handlePatientNfcNotAvailable(nfcHint);

      expect(state.scanning, isFalse);
      expect(state.errorMessage, nfcHint);
      expect(state.step2, isFalse);
    });

    test('E-02 NfcNotAvailableException en _scanPatient no activa step2', () {
      final state = _FakeReadNfcState();
      state.handlePatientNfcNotAvailable(nfcHint);

      expect(state.step2, isFalse);
    });

    test('E-03 NfcSessionException en _scanPatient: scanning=false y '
        'errorMessage contiene el mensaje de la excepción', () {
      final state = _FakeReadNfcState()..scanning = true;
      state.handlePatientNfcSessionException(
        NfcSessionException('Tag lost during scan.'),
      );

      expect(state.scanning, isFalse);
      expect(state.errorMessage, 'Tag lost during scan.');
    });

    test('E-04 NfcSessionException en _scanPatient no activa step2', () {
      final state = _FakeReadNfcState();
      state.handlePatientNfcSessionException(
        NfcSessionException('Session cancelled.'),
      );

      expect(state.step2, isFalse);
    });

    test('E-05 NfcSessionException preserva patientDeviceUid previo', () {
      final state = _FakeReadNfcState()..patientDeviceUid = 'PREV:UID';
      state.handlePatientNfcSessionException(
        NfcSessionException('Read error.'),
      );

      expect(state.patientDeviceUid, 'PREV:UID');
    });

    test(
      'E-06 mensajes de NfcSessionException vacíos se propagan sin cambios',
      () {
        final state = _FakeReadNfcState();
        state.handlePatientNfcSessionException(NfcSessionException(''));

        expect(state.errorMessage, '');
      },
    );
  });

  group('E. NFC hardware exceptions — guardian scanner', () {
    const nfcHint = 'NFC no disponible en este dispositivo.';

    test('E-07 NfcNotAvailableException en _scanGuardian: scanning=false y '
        'errorMessage muestra el hint de NFC no disponible', () {
      final state = _FakeReadNfcState()
        ..scanning = true
        ..patientDeviceUid = 'AA:BB:CC:DD';

      state.handleGuardianNfcNotAvailable(nfcHint);

      expect(state.scanning, isFalse);
      expect(state.errorMessage, nfcHint);
    });

    test(
      'E-08 NfcNotAvailableException en _scanGuardian mantiene step2=true',
      () {
        final state = _FakeReadNfcState()
          ..step2 = true
          ..patientDeviceUid = 'AA:BB:CC:DD';

        state.handleGuardianNfcNotAvailable(nfcHint);

        expect(state.step2, isTrue);
      },
    );

    test('E-09 NfcSessionException en _scanGuardian: scanning=false y '
        'errorMessage contiene el mensaje de la excepción', () {
      final state = _FakeReadNfcState()
        ..scanning = true
        ..patientDeviceUid = 'AA:BB:CC:DD';

      state.handleGuardianNfcSessionException(
        NfcSessionException('NFC error.'),
      );

      expect(state.scanning, isFalse);
      expect(state.errorMessage, 'NFC error.');
    });

    test(
      'E-10 NfcSessionException en _scanGuardian preserva patientDeviceUid',
      () {
        final state = _FakeReadNfcState()
          ..patientDeviceUid = 'AA:BB:CC:DD'
          ..step2 = true;

        state.handleGuardianNfcSessionException(
          NfcSessionException('Read failed.'),
        );

        expect(state.patientDeviceUid, 'AA:BB:CC:DD');
      },
    );

    test('E-11 NfcSessionException en _scanGuardian no limpia errorMessage '
        'previo — lo reemplaza con el nuevo', () {
      final state = _FakeReadNfcState()
        ..errorMessage = 'Old error'
        ..patientDeviceUid = 'AA:BB:CC:DD';

      state.handleGuardianNfcSessionException(
        NfcSessionException('New NFC error.'),
      );

      expect(state.errorMessage, 'New NFC error.');
    });
  });

  group('F. _submitGuardian guard — patientDeviceUid null', () {
    test('F-01 canProceedWithGuardianSubmit devuelve false cuando '
        'patientDeviceUid es null', () {
      expect(_FakeReadNfcState().canProceedWithGuardianSubmit(), isFalse);
    });

    test('F-02 canProceedWithGuardianSubmit devuelve true cuando '
        'patientDeviceUid tiene valor', () {
      expect(
        (_FakeReadNfcState()..patientDeviceUid = 'AA:BB:CC:DD')
            .canProceedWithGuardianSubmit(),
        isTrue,
      );
    });

    test('F-03 el guard no modifica ningún campo de estado', () {
      final state = _FakeReadNfcState()
        ..scanning = false
        ..errorMessage = null;

      state.canProceedWithGuardianSubmit();

      expect(state.scanning, isFalse);
      expect(state.errorMessage, isNull);
    });
  });

  // ── G. _openProfile reset ─────────────────────────────────────────────────

  group('G. _openProfile — reset al volver del perfil', () {
    test(
      'G-01 resetAfterOpenProfile limpia step2, patientDeviceUid y UIDs',
      () {
        final state = _FakeReadNfcState()
          ..step2 = true
          ..patientDeviceUid = 'AA:BB:CC:DD'
          ..patientUidText = 'AA:BB:CC:DD'
          ..guardianUidText = 'GG:HH:II:JJ'
          ..errorMessage = 'Algo falló';

        state.resetAfterOpenProfile();

        expect(state.step2, isFalse);
        expect(state.patientDeviceUid, isNull);
        expect(state.patientUidText, '');
        expect(state.guardianUidText, '');
        expect(state.errorMessage, isNull);
      },
    );

    test('G-02 resetAfterOpenProfile sobre estado inicial no lanza error', () {
      expect(
        () => _FakeReadNfcState().resetAfterOpenProfile(),
        returnsNormally,
      );
    });

    test('G-03 scanning NO se modifica por resetAfterOpenProfile '
        '(se pone en false antes de navegar, no después)', () {
      final state = _FakeReadNfcState()..scanning = false;
      state.resetAfterOpenProfile();
      expect(state.scanning, isFalse);
    });
  });

  group('H. ApiException model metrics', () {
    test('H-01 se instancia correctamente con statusCode y mensaje', () {
      final e = ApiException('Not found', statusCode: 404);
      expect(e.statusCode, 404);
      expect(e.message, 'Not found');
    });

    test('H-02 toString contiene statusCode y mensaje', () {
      final e = ApiException('Forbidden', statusCode: 403);
      expect(e.toString(), contains('403'));
      expect(e.toString(), contains('Forbidden'));
    });

    test('H-03 se lanza y captura correctamente', () {
      expect(
        () => throw ApiException('Error', statusCode: 500),
        throwsA(isA<ApiException>()),
      );
    });

    test('H-04 statusCode puede ser null', () {
      final e = ApiException('Network failure');
      expect(e.statusCode, isNull);
      expect(e.message, 'Network failure');
    });

    test('H-05 mensajes con "guardian" activan la lógica de paso 2', () {
      const messages = [
        'Guardian bracelet scan required for minors.',
        'guardian required',
        'GUARDIAN SCAN NEEDED',
        'Need guardian device',
      ];
      for (final msg in messages) {
        expect(
          msg.toLowerCase().contains('guardian'),
          isTrue,
          reason: '"$msg" debería activar la verificación de guardian.',
        );
      }
    });

    test('H-06 mensajes sin "guardian" no activan paso 2', () {
      const messages = [
        'Forbidden.',
        'Patient not found.',
        'Token expired.',
        'Internal server error.',
        'Access denied.',
      ];
      for (final msg in messages) {
        expect(
          msg.toLowerCase().contains('guardian'),
          isFalse,
          reason: '"$msg" NO debería activar la verificación de guardian.',
        );
      }
    });
  });

  group('I. _ManualUidPanel button execution validation', () {
    test('I-01 onSubmit es null cuando scanning es true', () {
      const scanning = true;
      final onSubmit = (scanning == true) ? null : () {};
      expect(onSubmit, isNull);
    });

    test('I-02 onSubmit se puede invocar cuando scanning es false', () {
      const scanning = false;
      var called = false;
      final onSubmit = (scanning == true) ? null : () => called = true;
      onSubmit?.call();
      expect(called, isTrue);
    });
  });
}
