// test/unit/step5_review_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/register_nfc_screen.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

String buildFullName(RegisterDraft d) => [
  d.firstName,
  d.secondName,
  d.firstLastName,
  d.secondLastName,
].where((s) => s != null && s.isNotEmpty).join(' ');

/// sexLabel
String sexLabel(String sex, {bool isEs = true}) => isEs
    ? const {'M': 'Masculino', 'F': 'Femenino', 'I': 'Indeterminado'}[sex] ??
          sex
    : const {'M': 'Male', 'F': 'Female', 'I': 'Indeterminate'}[sex] ?? sex;

/// zoneLabel
String zoneLabel(String? zone, {bool isEs = true}) =>
    zone == '02' ? (isEs ? 'Rural' : 'Rural') : (isEs ? 'Urbana' : 'Urban');

/// guardianRelationshipLabel
String guardianRelLabel(String? rel, {bool isEs = true}) => isEs
    ? const {
            '01': 'Padres',
            '02': 'Hermanos',
            '03': 'Tíos',
            '04': 'Abuelos',
          }[rel ?? '01'] ??
          ''
    : const {
            '01': 'Parents',
            '02': 'Siblings',
            '03': 'Uncles',
            '04': 'Grandparents',
          }[rel ?? '01'] ??
          '';

/// Replica itemsCount
String itemsCount(int count, {bool isEs = true}) {
  if (count == 0) return '—';
  return isEs ? '$count ítems' : '$count items';
}

/// _kv
MapEntry<String, String> kv(String k, String v) =>
    MapEntry(k, v.isEmpty ? '—' : v);

String formatDob(DateTime? dob) {
  if (dob == null) return '—';
  return '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
}

void main() {
  group('Nombre completo', () {
    test('nombre con los cuatro campos', () {
      final d = RegisterDraft()
        ..firstName = 'Isabella'
        ..secondName = 'María'
        ..firstLastName = 'Martínez'
        ..secondLastName = 'Silva';
      expect(buildFullName(d), 'Isabella María Martínez Silva');
    });

    test('nombre sin segundo nombre', () {
      final d = RegisterDraft()
        ..firstName = 'Juan'
        ..firstLastName = 'Galvis';
      expect(buildFullName(d), 'Juan Galvis');
    });

    test('nombre sin segundo apellido', () {
      final d = RegisterDraft()
        ..firstName = 'Ana'
        ..secondName = 'Lucía'
        ..firstLastName = 'Rodríguez';
      expect(buildFullName(d), 'Ana Lucía Rodríguez');
    });

    test('nombre solo con firstName y firstLastName', () {
      final d = RegisterDraft()
        ..firstName = 'Carlos'
        ..firstLastName = 'Pérez';
      expect(buildFullName(d), 'Carlos Pérez');
    });

    test('ignora campos vacíos o nulos', () {
      final d = RegisterDraft()
        ..firstName = 'Luisa'
        ..secondName = ''
        ..firstLastName = 'Torres'
        ..secondLastName = null;
      expect(buildFullName(d), 'Luisa Torres');
    });

    test('draft vacío produce cadena vacía', () {
      final d = RegisterDraft()
        ..firstName = ''
        ..firstLastName = '';
      expect(buildFullName(d), '');
    });
  });

  group('sexLabel — ES', () {
    test('M → Masculino', () => expect(sexLabel('M'), 'Masculino'));
    test('F → Femenino', () => expect(sexLabel('F'), 'Femenino'));
    test('I → Indeterminado', () => expect(sexLabel('I'), 'Indeterminado'));
    test(
      'código desconocido retorna el código mismo',
      () => expect(sexLabel('X'), 'X'),
    );
  });

  group('sexLabel — EN', () {
    test('M → Male', () => expect(sexLabel('M', isEs: false), 'Male'));
    test('F → Female', () => expect(sexLabel('F', isEs: false), 'Female'));
    test(
      'I → Indeterminate',
      () => expect(sexLabel('I', isEs: false), 'Indeterminate'),
    );
    test(
      'código desconocido retorna el código mismo en EN',
      () => expect(sexLabel('X', isEs: false), 'X'),
    );
  });

  group('zoneLabel — ES', () {
    test('zona "02" → Rural', () => expect(zoneLabel('02'), 'Rural'));
    test('zona "01" → Urbana', () => expect(zoneLabel('01'), 'Urbana'));
    test(
      'zona null → Urbana (valor por defecto)',
      () => expect(zoneLabel(null), 'Urbana'),
    );
    test('zona vacía → Urbana', () => expect(zoneLabel(''), 'Urbana'));
  });

  group('zoneLabel — EN', () {
    test(
      'zona "02" → Rural en EN',
      () => expect(zoneLabel('02', isEs: false), 'Rural'),
    );
    test(
      'zona "01" → Urban en EN',
      () => expect(zoneLabel('01', isEs: false), 'Urban'),
    );
    test(
      'zona null → Urban en EN',
      () => expect(zoneLabel(null, isEs: false), 'Urban'),
    );
  });

  group('guardianRelLabel — ES', () {
    test('"01" → Padres', () => expect(guardianRelLabel('01'), 'Padres'));
    test('"02" → Hermanos', () => expect(guardianRelLabel('02'), 'Hermanos'));
    test('"03" → Tíos', () => expect(guardianRelLabel('03'), 'Tíos'));
    test('"04" → Abuelos', () => expect(guardianRelLabel('04'), 'Abuelos'));
    test(
      'null usa "01" como fallback → Padres',
      () => expect(guardianRelLabel(null), 'Padres'),
    );
    test(
      'código desconocido retorna cadena vacía',
      () => expect(guardianRelLabel('99'), ''),
    );
  });

  group('guardianRelLabel — EN', () {
    test(
      '"01" → Parents',
      () => expect(guardianRelLabel('01', isEs: false), 'Parents'),
    );
    test(
      '"02" → Siblings',
      () => expect(guardianRelLabel('02', isEs: false), 'Siblings'),
    );
    test(
      '"03" → Uncles',
      () => expect(guardianRelLabel('03', isEs: false), 'Uncles'),
    );
    test(
      '"04" → Grandparents',
      () => expect(guardianRelLabel('04', isEs: false), 'Grandparents'),
    );
  });

  group('itemsCount — ES', () {
    test('0 → "—"', () => expect(itemsCount(0), '—'));
    test('1 → "1 ítems"', () => expect(itemsCount(1), '1 ítems'));
    test('3 → "3 ítems"', () => expect(itemsCount(3), '3 ítems'));
    test('10 → "10 ítems"', () => expect(itemsCount(10), '10 ítems'));
  });

  group('itemsCount — EN', () {
    test('0 → "—"', () => expect(itemsCount(0, isEs: false), '—'));
    test('1 → "1 items"', () => expect(itemsCount(1, isEs: false), '1 items'));
    test('5 → "5 items"', () => expect(itemsCount(5, isEs: false), '5 items'));
  });

  group('_kv helper', () {
    test('valor no vacío se preserva', () {
      final entry = kv('Nombre', 'Isabella');
      expect(entry.key, 'Nombre');
      expect(entry.value, 'Isabella');
    });

    test('valor vacío se reemplaza por "—"', () {
      final entry = kv('Campo', '');
      expect(entry.value, '—');
    });

    test('valor "—" se preserva tal cual', () {
      final entry = kv('Campo', '—');
      expect(entry.value, '—');
    });

    test('valor con espacios no se reemplaza', () {
      final entry = kv('Dirección', 'Cra 18 #27-43');
      expect(entry.value, 'Cra 18 #27-43');
    });

    test('clave se preserva sin modificar', () {
      final entry = kv('UID', 'AA:BB:CC:DD');
      expect(entry.key, 'UID');
    });
  });

  group('formatDob', () {
    test('dob null retorna "—"', () => expect(formatDob(null), '—'));

    test('fecha con mes y día de un dígito incluye cero inicial', () {
      expect(formatDob(DateTime(2015, 8, 5)), '2015-08-05');
    });

    test('fecha con mes y día de dos dígitos', () {
      expect(formatDob(DateTime(1990, 12, 25)), '1990-12-25');
    });

    test('formato es YYYY-MM-DD', () {
      final result = formatDob(DateTime(2000, 1, 1));
      expect(result, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });

  group('RegisterDraft — valores iniciales', () {
    test('biologicalSex por defecto es "F"', () {
      expect(RegisterDraft().biologicalSex, 'F');
    });

    test('documentType por defecto es "TI"', () {
      expect(RegisterDraft().documentType, 'TI');
    });

    test('nationalityCode por defecto es "COL"', () {
      expect(RegisterDraft().nationalityCode, 'COL');
    });

    test('listas empiezan vacías', () {
      final d = RegisterDraft();
      expect(d.chronicConditions, isEmpty);
      expect(d.familyHistory, isEmpty);
      expect(d.medications, isEmpty);
      expect(d.allergies, isEmpty);
    });

    test('guardianName es null por defecto', () {
      expect(RegisterDraft().guardianName, isNull);
    });

    test('deviceUid es null por defecto', () {
      expect(RegisterDraft().deviceUid, isNull);
    });

    test('dob es null por defecto', () {
      expect(RegisterDraft().dob, isNull);
    });
  });

  group('RegisterDraft — itemsCount con listas reales', () {
    test('0 alergias → "—"', () {
      final d = RegisterDraft();
      expect(itemsCount(d.allergies.length), '—');
    });

    test('1 alergia → "1 ítems"', () {
      final d = RegisterDraft()
        ..allergies = [AllergyInfo(category: '01', allergen: 'Penicilina')];
      expect(itemsCount(d.allergies.length), '1 ítems');
    });

    test('2 condiciones crónicas → "2 ítems"', () {
      final d = RegisterDraft()
        ..chronicConditions = [
          ChronicConditionItem(chronicDescription: 'Diabetes'),
          ChronicConditionItem(chronicDescription: 'HTA'),
        ];
      expect(itemsCount(d.chronicConditions.length), '2 ítems');
    });

    test('1 antecedente familiar → "1 ítems"', () {
      final d = RegisterDraft()
        ..familyHistory = [
          FamilyHistoryItem(conditionDescription: 'Cáncer', relationship: '01'),
        ];
      expect(itemsCount(d.familyHistory.length), '1 ítems');
    });

    test('3 medicamentos → "3 ítems"', () {
      final d = RegisterDraft()
        ..medications = [
          MedicationStatementItem(medicationName: 'A'),
          MedicationStatementItem(medicationName: 'B'),
          MedicationStatementItem(medicationName: 'C'),
        ];
      expect(itemsCount(d.medications.length), '3 ítems');
    });
  });

  group('Condición sin guardián', () {
    test('guardianName null se evalúa como sin guardián', () {
      final d = RegisterDraft();
      final noGuardian = d.guardianName == null || d.guardianName!.isEmpty;
      expect(noGuardian, isTrue);
    });

    test('guardianName vacío se evalúa como sin guardián', () {
      final d = RegisterDraft()..guardianName = '';
      final noGuardian = d.guardianName == null || d.guardianName!.isEmpty;
      expect(noGuardian, isTrue);
    });

    test('guardianName con valor no se evalúa como sin guardián', () {
      final d = RegisterDraft()..guardianName = 'Roberto';
      final noGuardian = d.guardianName == null || d.guardianName!.isEmpty;
      expect(noGuardian, isFalse);
    });

    test('guardianDeviceUid null usa texto de fallback en ES', () {
      final d = RegisterDraft();
      final label = d.guardianDeviceUid ?? 'No registrada';
      expect(label, 'No registrada');
    });

    test('guardianDeviceUid null usa texto de fallback en EN', () {
      final d = RegisterDraft();
      final label = d.guardianDeviceUid ?? 'Not registered';
      expect(label, 'Not registered');
    });

    test('guardianDeviceUid con valor no usa fallback', () {
      final d = RegisterDraft()..guardianDeviceUid = 'GG:HH:II:JJ';
      final label = d.guardianDeviceUid ?? 'No registrada';
      expect(label, 'GG:HH:II:JJ');
    });
  });

  group('AppStrings — ES', () {
    final s = AppStrings.forTesting('es');

    test('welcome es "Bienvenido" (detecta locale ES)', () {
      expect(s.welcome, 'Bienvenido');
    });

    test('reviewData retorna texto correcto', () {
      expect(s.reviewData, 'Revisar datos');
    });

    test('saving retorna texto correcto', () {
      expect(s.saving, 'Guardando...');
    });

    test('back retorna texto correcto', () {
      expect(s.back, 'Atrás');
    });

    test('patient retorna texto correcto', () {
      expect(s.patient, 'Paciente');
    });

    test('guardian retorna texto correcto', () {
      expect(s.guardian, 'Guardián');
    });

    test('backgroundHistory retorna texto correcto', () {
      expect(s.backgroundHistory, 'Antecedentes');
    });

    test('allergiesSheetTitle retorna texto correcto', () {
      expect(s.allergiesSheetTitle, 'Alergias');
    });

    test('sexMale retorna "Masculino"', () {
      expect(s.sexMale, 'Masculino');
    });

    test('sexFemale retorna "Femenino"', () {
      expect(s.sexFemale, 'Femenino');
    });

    test('sexIndeterminate retorna "Indeterminado"', () {
      expect(s.sexIndeterminate, 'Indeterminado');
    });

    test('zoneUrban retorna "Urbana"', () {
      expect(s.zoneUrban, 'Urbana');
    });

    test('zoneRural retorna "Rural"', () {
      expect(s.zoneRural, 'Rural');
    });

    test('identification retorna texto correcto', () {
      expect(s.identification, 'Identificación');
    });

    test('nationality retorna texto correcto', () {
      expect(s.nationality, contains('Nacionalidad'));
    });

    test('bloodType retorna texto correcto', () {
      expect(s.bloodType, 'Tipo de sangre');
    });

    test('address retorna "Dirección"', () {
      expect(s.address, 'Dirección');
    });
  });

  group('AppStrings — EN', () {
    final s = AppStrings.forTesting('en');

    test('welcome es "Welcome" (detecta locale EN)', () {
      expect(s.welcome, 'Welcome');
    });

    test('reviewData retorna texto en inglés', () {
      expect(s.reviewData, 'Review data');
    });

    test('saving retorna texto en inglés', () {
      expect(s.saving, 'Saving...');
    });

    test('back retorna "Back"', () {
      expect(s.back, 'Back');
    });

    test('patient retorna "Patient"', () {
      expect(s.patient, 'Patient');
    });

    test('guardian retorna "Guardian"', () {
      expect(s.guardian, 'Guardian');
    });

    test('sexMale retorna "Male"', () {
      expect(s.sexMale, 'Male');
    });

    test('sexFemale retorna "Female"', () {
      expect(s.sexFemale, 'Female');
    });

    test('sexIndeterminate retorna "Indeterminate"', () {
      expect(s.sexIndeterminate, 'Indeterminate');
    });

    test('zoneUrban retorna "Urban"', () {
      expect(s.zoneUrban, 'Urban');
    });
  });
}
