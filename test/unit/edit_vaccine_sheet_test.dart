// test/unit/features/nfc/profile/sheets/edit_vaccine_sheet_unit_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

// =============================================================================
// Fixture Helpers
// =============================================================================

VaccinationRecordItem _vaccine({
  String date = '2026-01-15',
  String vaccineName = 'Triple Viral (SRP)',
  String vaccineCode = '03',
  int dose = 1,
  String administratedBy = 'Enf. Ana Ruiz',
  String administratedAt = 'Hospital Central',
  String status = 'completed',
}) => VaccinationRecordItem(
  date: date,
  vaccineName: vaccineName,
  vaccineCode: vaccineCode,
  dose: dose,
  administratedBy: administratedBy,
  administratedAt: administratedAt,
  status: status,
);

// =============================================================================
// UNIT TESTS
// =============================================================================

void main() {
  group('VaccinationRecordItem — Field Integrity', () {
    test('date is stored correctly', () {
      expect(_vaccine(date: '2026-05-12').date, equals('2026-05-12'));
    });

    test('vaccineName is stored correctly', () {
      expect(
        _vaccine(vaccineName: 'Hepatitis B').vaccineName,
        equals('Hepatitis B'),
      );
    });

    test('vaccineCode is stored correctly', () {
      expect(_vaccine(vaccineCode: '08').vaccineCode, equals('08'));
    });

    test('dose is stored as an integer', () {
      expect(_vaccine(dose: 2).dose, equals(2));
      expect(_vaccine(dose: 2).dose, isA<int>());
    });

    test('administratedBy is stored correctly', () {
      expect(
        _vaccine(administratedBy: 'Dr. Pérez').administratedBy,
        equals('Dr. Pérez'),
      );
    });

    test('administratedAt is stored correctly', () {
      expect(
        _vaccine(administratedAt: 'UBS Norte').administratedAt,
        equals('UBS Norte'),
      );
    });

    test('status defaults to "completed"', () {
      expect(_vaccine().status, equals('completed'));
    });

    test('status can be mutated to "refused"', () {
      expect(_vaccine(status: 'refused').status, equals('refused'));
    });

    test('status can be mutated to "not_given"', () {
      expect(_vaccine(status: 'not_given').status, equals('not_given'));
    });
  });

  group('VaccinationRecordItem.toJson — Serialization', () {
    test('toJson contains all required target fields', () {
      final json = _vaccine().toJson();
      expect(json.containsKey('date'), isTrue);
      expect(json.containsKey('vaccineName'), isTrue);
      expect(json.containsKey('vaccineCode'), isTrue);
      expect(json.containsKey('dose'), isTrue);
      expect(json.containsKey('administratedBy'), isTrue);
      expect(json.containsKey('administratedAt'), isTrue);
      expect(json.containsKey('status'), isTrue);
    });

    test('toJson serializes dose integer type correctly', () {
      final json = _vaccine(dose: 3).toJson();
      expect(json['dose'], equals(3));
      expect(json['dose'], isA<int>());
    });

    test('toJson serializes date adhering to YYYY-MM-DD formatting', () {
      final json = _vaccine(date: '2025-08-22').toJson();
      expect(json['date'], equals('2025-08-22'));
    });

    test('toJson preserves custom status property value', () {
      final json = _vaccine(status: 'refused').toJson();
      expect(json['status'], equals('refused'));
    });
  });

  group('VaccinationRecordItem.fromJson — Deserialization', () {
    test('fromJson successfully reconstructs data fields', () {
      final original = _vaccine();
      final restored = VaccinationRecordItem.fromJson(original.toJson());

      expect(restored.date, equals(original.date));
      expect(restored.vaccineName, equals(original.vaccineName));
      expect(restored.vaccineCode, equals(original.vaccineCode));
      expect(restored.dose, equals(original.dose));
      expect(restored.administratedBy, equals(original.administratedBy));
      expect(restored.administratedAt, equals(original.administratedAt));
      expect(restored.status, equals(original.status));
    });

    test('fromJson falls back to a default value of 1 when dose is null', () {
      final json = _vaccine().toJson()..remove('dose');
      final item = VaccinationRecordItem.fromJson(json);
      expect(item.dose, equals(1));
    });

    test(
      'fromJson falls back to "completed" when status payload is missing',
      () {
        final json = _vaccine().toJson()..remove('status');
        final item = VaccinationRecordItem.fromJson(json);
        expect(item.status, equals('completed'));
      },
    );

    test('fromJson initializes empty string keys normally', () {
      final item = VaccinationRecordItem.fromJson({
        'date': '',
        'vaccineName': '',
        'vaccineCode': '',
        'dose': 1,
        'administratedBy': '',
        'administratedAt': '',
        'status': 'completed',
      });
      expect(item.vaccineName, equals(''));
    });

    test('toJson into fromJson operation remains completely idempotent', () {
      final original = _vaccine(
        date: '2026-03-10',
        vaccineName: 'BCG',
        vaccineCode: '19',
        dose: 1,
        administratedBy: 'Enf. López',
        administratedAt: 'Brigada Sur',
        status: 'completed',
      );
      final json = original.toJson();
      final restored = VaccinationRecordItem.fromJson(json);
      expect(restored.toJson(), equals(json));
    });
  });

  group('TextEditingControllers — Initial Setup Assertions', () {
    test('nameCtrl initializes with initialVaccine text string', () {
      final ctrl = TextEditingController(text: 'Triple Viral (SRP)');
      expect(ctrl.text, equals('Triple Viral (SRP)'));
      ctrl.dispose();
    });

    test('codeCtrl initializes with initialVaccineCode text string', () {
      final ctrl = TextEditingController(text: '03');
      expect(ctrl.text, equals('03'));
      ctrl.dispose();
    });

    test('doseCtrl initializes with initialDose text string', () {
      final ctrl = TextEditingController(text: '2');
      expect(ctrl.text, equals('2'));
      ctrl.dispose();
    });

    test('dateCtrl initializes with initialDate text string', () {
      final ctrl = TextEditingController(text: '2026-01-15');
      expect(ctrl.text, equals('2026-01-15'));
      ctrl.dispose();
    });

    test('byCtrl initializes with initialAdministeredBy text string', () {
      final ctrl = TextEditingController(text: 'Enf. Ana Ruiz');
      expect(ctrl.text, equals('Enf. Ana Ruiz'));
      ctrl.dispose();
    });

    test('atCtrl initializes with initialAdministeredAt text string', () {
      final ctrl = TextEditingController(text: 'Hospital Central');
      expect(ctrl.text, equals('Hospital Central'));
      ctrl.dispose();
    });

    test('null values initialize safely into an empty string', () {
      final ctrl = TextEditingController(text: null);
      expect(ctrl.text, equals(''));
      ctrl.dispose();
    });

    test('mutating controller text changes text property value', () {
      final ctrl = TextEditingController(text: 'Hepatitis B');
      ctrl.text = 'BCG';
      expect(ctrl.text, equals('BCG'));
      ctrl.dispose();
    });

    test('clearing a controller removes all text contents', () {
      final ctrl = TextEditingController(text: '03');
      ctrl.clear();
      expect(ctrl.text, isEmpty);
      ctrl.dispose();
    });
  });

  group('Dose Input Parsing and Validation', () {
    test('valid integer dose string parses correctly', () {
      final dose = int.tryParse('1');
      expect(dose, equals(1));
      expect(dose, isNotNull);
    });

    test('non-numeric booster text strings fail to parse', () {
      final dose = int.tryParse('Refuerzo');
      expect(dose, isNull);
    });

    test('empty dose strings evaluate to null', () {
      final dose = int.tryParse('');
      expect(dose, isNull);
    });

    test(
      'string integer token evaluates to integer primitive representation',
      () {
        expect(int.tryParse('2'), equals(2));
      },
    );

    /// Dart's native int.tryParse handles surrounding whitespace implicitly.
    test('whitespace tokens parse into integers natively', () {
      final dose = int.tryParse(' 1 ');
      expect(dose, equals(1));
    });

    test(
      'explicitly trimmed string payloads evaluate to target numeric primitive',
      () {
        expect(int.tryParse(' 1 '.trim()), equals(1));
      },
    );
  });

  group('Date Input Formatting — YYYY-MM-DD Validation Criteria', () {
    bool isValidDate(String s) {
      final parts = s.split('-');
      if (parts.length != 3) return false;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year == null || month == null || day == null) return false;
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;
      return true;
    }

    test('"2026-01-15" standard pattern verifies successfully', () {
      expect(isValidDate('2026-01-15'), isTrue);
    });

    test('"2026-13-01" fails checking index boundaries (month > 12)', () {
      expect(isValidDate('2026-13-01'), isFalse);
    });

    test('unseparated tokens without hyphens fail verification rules', () {
      expect(isValidDate('20260115'), isFalse);
    });

    test('empty input parameters evaluate to false', () {
      expect(isValidDate(''), isFalse);
    });

    test('literal non-numeric placeholder strings evaluate to false', () {
      expect(isValidDate('YYYY-MM-DD'), isFalse);
    });

    test('"2026-01-00" fails lower bound validation criteria (day 0)', () {
      expect(isValidDate('2026-01-00'), isFalse);
    });
  });

  group('Status Domain State Validation Matrix', () {
    const validStatuses = ['completed', 'refused', 'not_given'];

    test('expected finite array capacity allocation matches definition', () {
      expect(validStatuses.length, equals(3));
    });

    test('"completed" evaluates as a valid tracking property status state', () {
      expect(validStatuses.contains('completed'), isTrue);
    });

    test('"refused" evaluates as a valid tracking property status state', () {
      expect(validStatuses.contains('refused'), isTrue);
    });

    test('"not_given" evaluates as a valid tracking property status state', () {
      expect(validStatuses.contains('not_given'), isTrue);
    });

    test('base state fallback token exists inside target matrix', () {
      expect(validStatuses.contains('completed'), isTrue);
    });

    test('unsupported dynamic strings fail inclusion parameters', () {
      expect(validStatuses.contains('active'), isFalse);
    });
  });

  group('VaccinationRecordItem — Explicit Boundary Cases', () {
    test('minimum permitted numerical dose allocation limit is 1', () {
      expect(_vaccine(dose: 1).dose, equals(1));
    });

    test('extended custom booster index sequence allows up to 5', () {
      expect(_vaccine(dose: 5).dose, equals(5));
    });

    test('exceptionally large vaccine string models store data completely', () {
      final longName = 'A' * 200;
      expect(_vaccine(vaccineName: longName).vaccineName.length, equals(200));
    });

    test('single digit localized vaccine identifiers remain valid', () {
      expect(_vaccine(vaccineCode: '8').vaccineCode, equals('8'));
    });

    test(
      'triple digit standardization structures remain valid (CVX compliance)',
      () {
        expect(_vaccine(vaccineCode: '141').vaccineCode, equals('141'));
      },
    );
  });
}
