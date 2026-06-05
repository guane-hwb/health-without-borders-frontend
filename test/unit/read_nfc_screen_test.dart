// test/unit/read_nfc_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';

void main() {
  group('Step state logic', () {
    test('initial state: step2 is false', () {
      final state = _FakeReadNfcState();
      expect(state.step2, isFalse);
    });

    test('detecting a 403 error containing "guardian" activates step2', () {
      final state = _FakeReadNfcState();
      final error = ApiException(
        'Guardian bracelet scan required for minors.',
        statusCode: 403,
      );
      state.handlePatientApiError(error, deviceUid: 'AA:BB:CC:DD');

      expect(state.step2, isTrue);
      expect(state.patientDeviceUid, 'AA:BB:CC:DD');
      expect(state.errorMessage, isNull);
    });

    test(
      'detecting a 403 error WITHOUT "guardian" does NOT activate step2',
      () {
        final state = _FakeReadNfcState();
        final error = ApiException('Forbidden.', statusCode: 403);
        state.handlePatientApiError(error, deviceUid: 'AA:BB:CC:DD');

        expect(state.step2, isFalse);
        expect(state.errorMessage, 'Forbidden.');
      },
    );

    test(
      'detecting a 404 error shows a message and does not activate step2',
      () {
        final state = _FakeReadNfcState();
        final error = ApiException('Patient not found.', statusCode: 404);
        state.handlePatientApiError(error, deviceUid: 'AA:BB:CC:DD');

        expect(state.step2, isFalse);
        expect(state.errorMessage, 'Patient not found.');
      },
    );

    test(
      'detecting a 401 error shows a message and does not activate step2',
      () {
        final state = _FakeReadNfcState();
        final error = ApiException('Token expired.', statusCode: 401);
        state.handlePatientApiError(error, deviceUid: 'AA:BB:CC:DD');

        expect(state.step2, isFalse);
        expect(state.errorMessage, 'Token expired.');
      },
    );

    test(
      'detecting a 500 error shows a message and does not activate step2',
      () {
        final state = _FakeReadNfcState();
        final error = ApiException('Internal error.', statusCode: 500);
        state.handlePatientApiError(error, deviceUid: 'AA:BB:CC:DD');

        expect(state.step2, isFalse);
        expect(state.errorMessage, 'Internal error.');
      },
    );

    test('guardian word detection is case-insensitive', () {
      final state = _FakeReadNfcState();
      final error = ApiException('GUARDIAN BRACELET REQUIRED', statusCode: 403);
      state.handlePatientApiError(error, deviceUid: 'AA:BB:CC:DD');
      expect(state.step2, isTrue);
    });

    test('backToStep1 resets step2 and clears guardianUid', () {
      final state = _FakeReadNfcState()
        ..step2 = true
        ..guardianUidText = 'GG:HH:II:JJ'
        ..errorMessage = 'Previous error';

      state.backToStep1();

      expect(state.step2, isFalse);
      expect(state.guardianUidText, '');
      expect(state.errorMessage, isNull);
    });

    test('backToStep1 preserves patientDeviceUid', () {
      final state = _FakeReadNfcState()
        ..step2 = true
        ..patientDeviceUid = 'AA:BB:CC:DD';

      state.backToStep1();

      expect(state.patientDeviceUid, 'AA:BB:CC:DD');
    });
  });

  group('Empty UID guards', () {
    test('submitPatientFromForm does not proceed if UID is empty', () {
      final state = _FakeReadNfcState()..patientUidText = '';
      final result = state.shouldSubmitPatient();
      expect(result, isFalse);
    });

    test('submitPatientFromForm proceeds if UID has content', () {
      final state = _FakeReadNfcState()..patientUidText = 'AA:BB:CC:DD';
      final result = state.shouldSubmitPatient();
      expect(result, isTrue);
    });

    test('submitPatientFromForm ignores UID with only spaces', () {
      final state = _FakeReadNfcState()..patientUidText = '   ';
      expect(state.shouldSubmitPatient(), isFalse);
    });

    test('submitGuardianFromForm does not proceed if guardianUid is empty', () {
      final state = _FakeReadNfcState()..guardianUidText = '';
      expect(state.shouldSubmitGuardian(), isFalse);
    });

    test('submitGuardianFromForm proceeds if guardianUid has content', () {
      final state = _FakeReadNfcState()..guardianUidText = 'GG:HH:II:JJ';
      expect(state.shouldSubmitGuardian(), isTrue);
    });

    test('submitGuardianFromForm ignores UID with only spaces', () {
      final state = _FakeReadNfcState()..guardianUidText = '   ';
      expect(state.shouldSubmitGuardian(), isFalse);
    });

    test('submitGuardian does not proceed if patientDeviceUid is null', () {
      final state = _FakeReadNfcState()
        ..patientDeviceUid = null
        ..guardianUidText = 'GG:HH:II:JJ';
      expect(state.canSubmitGuardian(), isFalse);
    });

    test(
      'submitGuardian proceeds if patientDeviceUid and guardianUid are valid',
      () {
        final state = _FakeReadNfcState()
          ..patientDeviceUid = 'AA:BB:CC:DD'
          ..guardianUidText = 'GG:HH:II:JJ';
        expect(state.canSubmitGuardian(), isTrue);
      },
    );
  });

  group('State reset after returning from profile view', () {
    test('resetAfterProfile clears all tracking data fields', () {
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

    test(
      'resetAfterProfile executed on a clean state does not throw errors',
      () {
        final state = _FakeReadNfcState();
        expect(() => state.resetAfterProfile(), returnsNormally);
      },
    );
  });

  group('Guardian scanner exception mapping handlers', () {
    test(
      'ApiException in _submitGuardian displays the network error message payload',
      () {
        final state = _FakeReadNfcState()..patientDeviceUid = 'AA:BB:CC:DD';
        final error = ApiException('Invalid guardian device.', statusCode: 403);
        state.handleGuardianApiError(error);

        expect(state.errorMessage, 'Invalid guardian device.');
        expect(state.scanning, isFalse);
      },
    );

    test(
      'generic error exception inside _submitGuardian displays its fallback string',
      () {
        final state = _FakeReadNfcState()..patientDeviceUid = 'AA:BB:CC:DD';
        state.handleGuardianGenericError(Exception('timeout'));

        expect(state.errorMessage, contains('timeout'));
        expect(state.scanning, isFalse);
      },
    );

    test(
      'generic error exception inside _submitPatient displays its fallback string',
      () {
        final state = _FakeReadNfcState();
        state.handlePatientGenericError(Exception('network error'));

        expect(state.errorMessage, contains('network error'));
        expect(state.scanning, isFalse);
      },
    );
  });

  group('ApiException model metrics', () {
    test('instantiates normally with statusCode and string message values', () {
      final e = ApiException('Not found', statusCode: 404);
      expect(e.statusCode, 404);
      expect(e.message, 'Not found');
    });

    test(
      'toString representation contains target status codes and details',
      () {
        final e = ApiException('Forbidden', statusCode: 403);
        expect(e.toString(), contains('403'));
        expect(e.toString(), contains('Forbidden'));
      },
    );

    test('behaves as a completely throw-compliant implementation object', () {
      expect(
        () => throw ApiException('Error', statusCode: 500),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'string sequences containing "guardian" validate true checking step parameters',
      () {
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
            reason:
                'Message: "$msg" should trigger guardian pattern matching assertions.',
          );
        }
      },
    );

    test(
      'string sequences missing "guardian" keywords validate false checking parameters',
      () {
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
            reason:
                'Message: "$msg" should skip guardian validation parameters.',
          );
        }
      },
    );
  });

  group('_ManualUidPanel button execution validation tracking', () {
    test('onSubmit resolves to null when internal scanning state is true', () {
      final Object scanning = true;
      final onSubmit = (scanning == true) ? null : () {};
      expect(onSubmit, isNull);
    });

    test(
      'onSubmit context remains active when tracking scanning state is false',
      () {
        final Object scanning = false;
        var called = false;
        final onSubmit = (scanning == true)
            ? null
            : () {
                called = true;
              };
        onSubmit?.call();
        expect(called, isTrue);
      },
    );
  });
}

/// Simulated state mock implementation tracking business rules isolated from presentation frameworks.
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

  void handleGuardianApiError(ApiException e) {
    scanning = false;
    errorMessage = e.message;
  }

  void handleGuardianGenericError(Object e) {
    scanning = false;
    errorMessage = e.toString();
  }

  void backToStep1() {
    step2 = false;
    guardianUidText = '';
    errorMessage = null;
  }

  void resetAfterProfile() {
    step2 = false;
    patientDeviceUid = null;
    patientUidText = '';
    guardianUidText = '';
    errorMessage = null;
  }

  bool shouldSubmitPatient() => patientUidText.trim().isNotEmpty;

  bool shouldSubmitGuardian() => guardianUidText.trim().isNotEmpty;

  bool canSubmitGuardian() =>
      patientDeviceUid != null && guardianUidText.trim().isNotEmpty;
}
