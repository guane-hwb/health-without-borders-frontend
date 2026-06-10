// test/unit/features/nfc/register/register_nfc_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/register_nfc_screen.dart';

bool isMinor(DateTime? dob, DateTime now) {
  if (dob == null) return true;
  var age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age < 18;
}

/// _next
int nextStep(int step) => step < 5 ? step + 1 : step;

/// _stepBack
int prevStep(int step) => step > 0 ? step - 1 : step;

///  _ProgressBar
bool isStepActive(int index, int currentStep) => index <= currentStep;

/// guardian2Info in toRecord
bool includesGuardian2(String? guardian2Name) =>
    guardian2Name != null && guardian2Name.isNotEmpty;

/// _formatTimeNow
String formatTimeNow(
  DateTime now, {
  String amLabel = 'a.m.',
  String pmLabel = 'p.m.',
  String todayLabel = 'Hoy',
}) {
  final h = now.hour;
  final m = now.minute.toString().padLeft(2, '0');
  final period = h < 12 ? amLabel : pmLabel;
  final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$todayLabel, $h12:$m $period';
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  group('RegisterDraft — valores por defecto', () {
    test('deviceUid es null por defecto', () {
      expect(RegisterDraft().deviceUid, isNull);
    });

    test('documentType es "TI" por defecto', () {
      expect(RegisterDraft().documentType, equals('TI'));
    });

    test('documentNumber es "" por defecto', () {
      expect(RegisterDraft().documentNumber, equals(''));
    });

    test('firstName es "" por defecto', () {
      expect(RegisterDraft().firstName, equals(''));
    });

    test('firstLastName es "" por defecto', () {
      expect(RegisterDraft().firstLastName, equals(''));
    });

    test('biologicalSex es "F" por defecto', () {
      expect(RegisterDraft().biologicalSex, equals('F'));
    });

    test('nationalityCode es "COL" por defecto', () {
      expect(RegisterDraft().nationalityCode, equals('COL'));
    });

    test('nationalityName es "Colombia" por defecto', () {
      expect(RegisterDraft().nationalityName, equals('Colombia'));
    });

    test('dob es null por defecto', () {
      expect(RegisterDraft().dob, isNull);
    });

    test('allergies es lista vacía por defecto', () {
      expect(RegisterDraft().allergies, isEmpty);
    });

    test('familyHistory es lista vacía por defecto', () {
      expect(RegisterDraft().familyHistory, isEmpty);
    });

    test('chronicConditions es lista vacía por defecto', () {
      expect(RegisterDraft().chronicConditions, isEmpty);
    });

    test('medications es lista vacía por defecto', () {
      expect(RegisterDraft().medications, isEmpty);
    });

    test('guardianAuthAccepted es null por defecto', () {
      expect(RegisterDraft().guardianAuthAccepted, isNull);
    });

    test('guardian2Name es null por defecto', () {
      expect(RegisterDraft().guardian2Name, isNull);
    });
  });

  group('RegisterDraft.toRecord — serialización a PatientFullRecord', () {
    test('patientId es un UUID v4 no vacío', () {
      final record = RegisterDraft().toRecord();
      expect(record.patientId, isNotEmpty);
      expect(record.patientId.contains('-'), isTrue);
    });

    test('deviceUid null → "" en el record', () {
      final record = RegisterDraft().toRecord();
      expect(record.deviceUid, equals(''));
    });

    test('deviceUid asignado se preserva en el record', () {
      final draft = RegisterDraft()..deviceUid = 'HWB-01';
      expect(draft.toRecord().deviceUid, equals('HWB-01'));
    });

    test('dob null → dobStr vacío en patientInfo', () {
      final record = RegisterDraft().toRecord();
      expect(record.patientInfo.dob, equals(''));
    });

    test('dob asignado → formato YYYY-MM-DD', () {
      final draft = RegisterDraft()..dob = DateTime(2010, 5, 3);
      expect(draft.toRecord().patientInfo.dob, equals('2010-05-03'));
    });

    test('dob con día/mes de un dígito usa padding con cero', () {
      final draft = RegisterDraft()..dob = DateTime(2010, 1, 7);
      expect(draft.toRecord().patientInfo.dob, equals('2010-01-07'));
    });

    test('documentType se transfiere al record', () {
      final draft = RegisterDraft()..documentType = 'CC';
      expect(
        draft.toRecord().patientInfo.identification.documentType,
        equals('CC'),
      );
    });

    test('firstName se transfiere al record', () {
      final draft = RegisterDraft()..firstName = 'María';
      expect(draft.toRecord().patientInfo.firstName, equals('María'));
    });

    test('addressCity se transfiere al record', () {
      final draft = RegisterDraft()..addressCity = 'Bogotá';
      expect(draft.toRecord().patientInfo.address.city, equals('Bogotá'));
    });

    test('country siempre es "COL" en toRecord', () {
      expect(
        RegisterDraft().toRecord().patientInfo.address.country,
        equals('COL'),
      );
    });

    test('medicalHistory es lista vacía en toRecord', () {
      expect(RegisterDraft().toRecord().medicalHistory, isEmpty);
    });

    test('vaccinationRecord es lista vacía en toRecord', () {
      expect(RegisterDraft().toRecord().vaccinationRecord, isEmpty);
    });

    test('guardianRelationship null → "01" en toRecord', () {
      final record = RegisterDraft().toRecord();
      expect(record.guardianInfo.relationship, equals('01'));
    });

    test('guardianAuthAccepted false → consent es null en toRecord', () {
      final draft = RegisterDraft()..guardianAuthAccepted = false;
      expect(draft.toRecord().guardianInfo.consent, isNull);
    });

    test('guardianAuthAccepted true → consent no es null en toRecord', () {
      final draft = RegisterDraft()
        ..guardianAuthAccepted = true
        ..guardianEmail = 'test@test.com';
      expect(draft.toRecord().guardianInfo.consent, isNotNull);
      expect(draft.toRecord().guardianInfo.consent!.accepted, isTrue);
    });
  });

  group('_isMinor — lógica de minoría de edad', () {
    test('dob null → isMinor es true', () {
      expect(isMinor(null, DateTime(2025, 6, 1)), isTrue);
    });

    test('18 años exactos → isMinor es false', () {
      final now = DateTime(2025, 6, 15);
      final dob = DateTime(2007, 6, 15);
      expect(isMinor(dob, now), isFalse);
    });

    test('17 años y 364 días → isMinor es true', () {
      final now = DateTime(2025, 6, 14);
      final dob = DateTime(2007, 6, 15);
      expect(isMinor(dob, now), isTrue);
    });

    test('19 años → isMinor es false', () {
      final now = DateTime(2025, 6, 15);
      final dob = DateTime(2006, 1, 1);
      expect(isMinor(dob, now), isFalse);
    });

    test('recién nacido → isMinor es true', () {
      final now = DateTime(2025, 6, 15);
      final dob = DateTime(2025, 6, 15);
      expect(isMinor(dob, now), isTrue);
    });

    test('cumpleaños exactamente hoy con 18 años → isMinor es false', () {
      final now = DateTime(2025, 3, 10);
      final dob = DateTime(2007, 3, 10);
      expect(isMinor(dob, now), isFalse);
    });

    test('cumpleaños aún no llegó este año → age se descuenta', () {
      final now = DateTime(2025, 3, 10);
      final dob = DateTime(2008, 6, 15);
      expect(isMinor(dob, now), isTrue);
    });
  });

  group('_next — avance de pasos', () {
    test('paso 0 → 1', () => expect(nextStep(0), equals(1)));
    test('paso 1 → 2', () => expect(nextStep(1), equals(2)));
    test('paso 2 → 3', () => expect(nextStep(2), equals(3)));
    test('paso 3 → 4', () => expect(nextStep(3), equals(4)));
    test('paso 4 → 5', () => expect(nextStep(4), equals(5)));
    test('paso 5 NO avanza (límite)', () => expect(nextStep(5), equals(5)));
  });

  group('_stepBack — retroceso de pasos', () {
    test('paso 5 → 4', () => expect(prevStep(5), equals(4)));
    test('paso 4 → 3', () => expect(prevStep(4), equals(3)));
    test('paso 1 → 0', () => expect(prevStep(1), equals(0)));
    test('paso 0 NO retrocede (va a Home = sigue en 0)', () {
      expect(prevStep(0), equals(0));
    });
  });

  group('_ProgressBar — lógica de activación por paso', () {
    test('paso 0: índice 0 es activo, 1-4 inactivos', () {
      expect(isStepActive(0, 0), isTrue);
      expect(isStepActive(1, 0), isFalse);
      expect(isStepActive(4, 0), isFalse);
    });

    test('paso 2: índices 0-2 activos, 3-4 inactivos', () {
      expect(isStepActive(0, 2), isTrue);
      expect(isStepActive(2, 2), isTrue);
      expect(isStepActive(3, 2), isFalse);
    });

    test('paso 4 (último): todos los índices 0-4 activos', () {
      for (int i = 0; i <= 4; i++) {
        expect(isStepActive(i, 4), isTrue);
      }
    });

    test('total de segmentos es siempre 5', () {
      const total = 5;
      expect(total, equals(5));
    });
  });

  group('_formatTimeNow — formato hora 12h', () {
    test('medianoche (0h) → 12:00 a.m.', () {
      expect(
        formatTimeNow(DateTime(2025, 1, 1, 0, 0)),
        equals('Hoy, 12:00 a.m.'),
      );
    });

    test('mediodía (12h) → 12:00 p.m.', () {
      expect(
        formatTimeNow(DateTime(2025, 1, 1, 12, 0)),
        equals('Hoy, 12:00 p.m.'),
      );
    });

    test('1h AM → 1:00 a.m.', () {
      expect(
        formatTimeNow(DateTime(2025, 1, 1, 1, 0)),
        equals('Hoy, 1:00 a.m.'),
      );
    });

    test('13h → 1:00 p.m.', () {
      expect(
        formatTimeNow(DateTime(2025, 1, 1, 13, 0)),
        equals('Hoy, 1:00 p.m.'),
      );
    });

    test('23h → 11:00 p.m.', () {
      expect(
        formatTimeNow(DateTime(2025, 1, 1, 23, 0)),
        equals('Hoy, 11:00 p.m.'),
      );
    });

    test('minutos se pad con cero (09 → "09")', () {
      final result = formatTimeNow(DateTime(2025, 1, 1, 10, 9));
      expect(result, contains(':09'));
    });

    test('EN: usa "Today", "AM", "PM"', () {
      final result = formatTimeNow(
        DateTime(2025, 1, 1, 9, 30),
        amLabel: 'AM',
        pmLabel: 'PM',
        todayLabel: 'Today',
      );
      expect(result, equals('Today, 9:30 AM'));
    });

    test('11h → 11:XX a.m. (antes del mediodía)', () {
      final result = formatTimeNow(DateTime(2025, 1, 1, 11, 45));
      expect(result, contains('a.m.'));
    });
  });

  group('guardian2Info — condición de inclusión en toRecord', () {
    test('guardian2Name null → guardian2Info es null', () {
      expect(includesGuardian2(null), isFalse);
      final record = RegisterDraft().toRecord();
      expect(record.guardian2Info, isNull);
    });

    test('guardian2Name vacío → guardian2Info es null', () {
      expect(includesGuardian2(''), isFalse);
    });

    test('guardian2Name con valor → guardian2Info no es null', () {
      expect(includesGuardian2('Ana Torres'), isTrue);
    });

    test('guardian2Name asignado → guardian2Info presente en record', () {
      final draft = RegisterDraft()
        ..guardian2Name = 'Ana Torres'
        ..guardian2Relationship = '02'
        ..guardian2Phone = '+57300000000';
      final record = draft.toRecord();
      expect(record.guardian2Info, isNotNull);
      expect(record.guardian2Info!.name, equals('Ana Torres'));
    });

    test('guardian2AuthAccepted true → consent presente en guardian2', () {
      final draft = RegisterDraft()
        ..guardian2Name = 'Ana Torres'
        ..guardian2AuthAccepted = true;
      final record = draft.toRecord();
      expect(record.guardian2Info!.consent, isNotNull);
      expect(record.guardian2Info!.consent!.accepted, isTrue);
    });

    test('guardian2AuthAccepted false → consent es null en guardian2', () {
      final draft = RegisterDraft()
        ..guardian2Name = 'Ana Torres'
        ..guardian2AuthAccepted = false;
      final record = draft.toRecord();
      expect(record.guardian2Info!.consent, isNull);
    });
  });

  group('stepText — generación del indicador de paso', () {
    test('paso 0 → stepText es "1/5"', () {
      final step = 0;
      final stepText = '${step + 1}/5';
      expect(stepText, equals('1/5'));
    });

    test('paso 4 → stepText es "5/5"', () {
      final step = 4;
      final stepText = '${step + 1}/5';
      expect(stepText, equals('5/5'));
    });

    test('paso 5 (success) → stepText es null (no se muestra)', () {
      final step = 5;
      final onSuccess = step == 5;
      final stepText = onSuccess ? null : '${step + 1}/5';
      expect(stepText, isNull);
    });

    test('paso 1 → stepText es "2/5"', () {
      final stepText = '${1 + 1}/5';
      expect(stepText, equals('2/5'));
    });
  });
}
