// test/unit/muac_test.dart
//
// Mid-upper arm circumference (circunferencia media de brazo): the Ministry's
// table, the 6-59 month window and the field in PatientInfo.

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/muac.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/register_draft.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/state/patient_draft_controller.dart';

PatientInfo _info({double? muac, double? weight}) => PatientInfo(
  identification: PatientIdentification(
    documentType: 'RC',
    documentNumber: '1100000001',
  ),
  firstLastName: 'Pérez',
  firstName: 'Lucía',
  dob: '2024-03-10',
  biologicalSex: 'F',
  address: Address(city: 'Riohacha', state: 'La Guajira'),
  weight: weight,
  muac: muac,
);

PatientFullRecord _record({double? muac}) => PatientFullRecord(
  patientId: 'p-1',
  deviceUid: 'UID-1',
  patientInfo: _info(muac: muac),
  guardianInfo: GuardianInfo(name: 'Ana', relationship: '01', phone: '300'),
);

void main() {
  group('classifyMuac — tabla del Ministerio', () {
    for (final (cm, risk) in <(double, MuacRisk)>[
      (8.0, MuacRisk.red),
      (11.5, MuacRisk.red),
      (11.6, MuacRisk.yellow),
      (12.5, MuacRisk.yellow),
      (13.5, MuacRisk.yellow),
      (13.6, MuacRisk.green),
      (16.0, MuacRisk.green),
    ]) {
      test('$cm cm → ${risk.name}', () => expect(classifyMuac(cm), risk));
    }

    test('nothing falls between the bounds: rounded to one decimal first', () {
      expect(classifyMuac(11.54), MuacRisk.red);
      expect(classifyMuac(11.55), MuacRisk.yellow);
      expect(classifyMuac(13.54), MuacRisk.yellow);
      expect(classifyMuac(13.55), MuacRisk.green);
    });
  });

  group('parseMuac / isMuacInRange', () {
    test('accepts a comma and rounds to millimetres', () {
      expect(parseMuac('12,3'), 12.3);
      expect(parseMuac(' 12.34 '), 12.3);
      expect(parseMuac('doce'), isNull);
      expect(parseMuac(''), isNull);
    });

    test('5 to 30 cm', () {
      expect(isMuacInRange(4.9), isFalse);
      expect(isMuacInRange(5.0), isTrue);
      expect(isMuacInRange(30.0), isTrue);
      expect(isMuacInRange(30.1), isFalse);
    });
  });

  group('muacApplies — de 6 a 59 meses cumplidos', () {
    final now = DateTime(2026, 11, 25);

    test('completed months count the day of the month', () {
      expect(ageInCompletedMonths(DateTime(2026, 5, 25), now), 6);
      expect(ageInCompletedMonths(DateTime(2026, 5, 26), now), 5);
      expect(ageInCompletedMonths(DateTime(2026, 12, 1), now), isNull);
    });

    test('the window', () {
      expect(muacApplies(DateTime(2026, 5, 26), now), isFalse); // 5 m 29 d
      expect(muacApplies(DateTime(2026, 5, 25), now), isTrue); // 6 m
      expect(muacApplies(DateTime(2021, 11, 26), now), isTrue); // 59 m
      expect(muacApplies(DateTime(2021, 11, 25), now), isFalse); // 60 m
      expect(muacApplies(null, now), isFalse);
    });
  });

  group('PatientInfo.muac', () {
    test('round-trips through JSON', () {
      final json = _info(muac: 12.3).toJson();
      expect(json['muac'], 12.3);
      expect(PatientInfo.fromJson(json).muac, 12.3);
    });

    test('is left out of the JSON when missing, so the backend keeps its '
        'stored value', () {
      expect(_info().toJson().containsKey('muac'), isFalse);
      expect(PatientInfo.fromJson(_info().toJson()).muac, isNull);
    });

    test('takes part in == and hashCode', () {
      expect(_info(muac: 12.3), isNot(_info(muac: 12.4)));
      expect(_info(muac: 12.3), _info(muac: 12.3));
      expect(_info(muac: 12.3).hashCode, _info(muac: 12.3).hashCode);
    });

    test('copyWith keeps it and can change it', () {
      expect(_info(muac: 12.3).copyWith(weight: 10).muac, 12.3);
      expect(_info(muac: 12.3).copyWith(muac: 14).muac, 14);
    });

    test('a registration draft carries it into the record', () {
      final draft = RegisterDraft()..muac = 12.3;
      expect(draft.toRecord().patientInfo.muac, 12.3);
    });
  });

  group('PatientDraftController.updateVitalSigns', () {
    test('sets the arm circumference', () {
      final controller = PatientDraftController(_record());
      controller.updateVitalSigns(muac: 13.8);
      expect(controller.draft.patientInfo.muac, 13.8);
    });

    test('keeps it when the sheet sends none, like weight and height', () {
      final controller = PatientDraftController(_record(muac: 11.2));
      controller.updateVitalSigns(weight: 10.5);
      expect(controller.draft.patientInfo.muac, 11.2);
      expect(controller.draft.patientInfo.weight, 10.5);
    });
  });
}
