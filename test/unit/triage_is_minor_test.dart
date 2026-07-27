// test/unit/triage_is_minor_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_triage_payload.dart';

TriageSummary _triage(String dob) => TriageSummary(
  firstName: 'Ana',
  lastName: 'Pérez',
  dob: dob,
  biologicalSex: 'F',
  bloodType: 'O+',
  documentType: 'TI',
  documentNumber: '123',
  guardianPhone: '300',
  guardianDeviceUid: '04:AA',
  chronicConditions: '',
  allergies: const <TriageAllergy>[],
);

String _isoYearsAgo(int years, {int dayOffset = 0}) {
  final now = DateTime.now();
  final d = DateTime(now.year - years, now.month, now.day + dayOffset);
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

void main() {
  // This getter decides whether the guardian card is required offline. Getting
  // it wrong either blocks legitimate care or hands a minor's record over
  // without authorisation, so the edges matter.
  group('TriageSummary.isMinor', () {
    test('un recién nacido es menor', () {
      expect(_triage(_isoYearsAgo(0)).isMinor, isTrue);
    });

    test('alguien de 10 años es menor', () {
      expect(_triage(_isoYearsAgo(10)).isMinor, isTrue);
    });

    test('el día del cumpleaños número 18 ya NO es menor', () {
      expect(_triage(_isoYearsAgo(18)).isMinor, isFalse);
    });

    test('un día antes de cumplir 18 todavía es menor', () {
      // Nació hace 18 años pero mañana: aún no los cumplió.
      expect(_triage(_isoYearsAgo(18, dayOffset: 1)).isMinor, isTrue);
    });

    test('un día después de cumplir 18 no es menor', () {
      expect(_triage(_isoYearsAgo(18, dayOffset: -1)).isMinor, isFalse);
    });

    test('alguien de 40 no es menor', () {
      expect(_triage(_isoYearsAgo(40)).isMinor, isFalse);
    });
  });

  group('falla cerrado', () {
    // Si no podemos probar que es adulto, exigimos el guardián. Cualquier otro
    // default entregaría datos de un menor ante un dato corrupto.
    test('fecha vacía se trata como menor', () {
      expect(_triage('').isMinor, isTrue);
    });

    test('fecha ilegible se trata como menor', () {
      expect(_triage('no-es-una-fecha').isMinor, isTrue);
    });

    test('fecha con espacios se parsea igual', () {
      expect(_triage('  ${_isoYearsAgo(40)}  ').isMinor, isFalse);
    });

    test('una fecha futura se trata como menor', () {
      expect(_triage(_isoYearsAgo(-5)).isMinor, isTrue);
    });
  });
}
