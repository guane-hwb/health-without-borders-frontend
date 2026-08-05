// test/unit/step4_background_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/register_draft.dart';

String relLabel(AppStrings s, String c) =>
    {
      '01': s.relParents,
      '02': s.relSiblings,
      '03': s.relUncles,
      '04': s.relGrandparents,
    }[c] ??
    c;

String catLabel(AppStrings s, String c) =>
    {
      '01': s.allergenMedication,
      '02': s.allergenFood,
      '03': s.allergenEnvironment,
      '04': s.allergenSkin,
      '05': s.allergenInsect,
      '06': s.allergenOther,
    }[c] ??
    c;

String medStatusLabel(AppStrings s, String c) =>
    {
      'active': s.medStatusActive,
      'completed': s.medStatusCompleted,
      'stopped': s.medStatusStopped,
      'unknown': s.medStatusUnknown,
    }[c] ??
    c;

String? computePersonalHistory(String rawText) {
  final trimmed = rawText.trim();
  return trimmed.isEmpty ? null : trimmed;
}

void applySave(RegisterDraft draft, String personalText) {
  draft.personalHistory = computePersonalHistory(personalText);
}

String medSubtitle(String statusLabel, String? dosage) {
  final dosagePart = (dosage != null && dosage.isNotEmpty) ? ' · $dosage' : '';
  return '$statusLabel$dosagePart';
}

String allergySubtitle(String catLabel, String? reaction) {
  final reactionPart = (reaction != null && reaction.isNotEmpty)
      ? ' · $reaction'
      : '';
  return '$catLabel$reactionPart';
}

MedicationStatementItem buildMedication({
  required String name,
  required String status,
  String dosage = '',
  String notes = '',
}) {
  return MedicationStatementItem(
    medicationName: name.trim(),
    status: status,
    dosage: dosage.trim().isEmpty ? null : dosage.trim(),
    notes: notes.trim().isEmpty ? null : notes.trim(),
  );
}

// _AddAllergySheet
AllergyInfo buildAllergy({
  required String allergen,
  required String category,
  String reaction = '',
}) {
  return AllergyInfo(
    category: category,
    allergen: allergen.trim(),
    reaction: reaction.trim().isEmpty ? null : reaction.trim(),
  );
}

// _AddFamilyHistorySheet
FamilyHistoryItem buildFamilyHistory({
  required String conditionDescription,
  required String relationship,
}) {
  return FamilyHistoryItem(
    conditionDescription: conditionDescription.trim(),
    relationship: relationship,
  );
}

//  _AddChronicConditionSheet
ChronicConditionItem buildChronicCondition(String description) {
  return ChronicConditionItem(chronicDescription: description.trim());
}

bool ccCanConfirm(String text) => text.trim().isNotEmpty;
bool medCanConfirm(String name) => name.trim().isNotEmpty;
bool fhCanConfirm(String text) => text.trim().isNotEmpty;
bool allergyCanConfirm(String allergen) => allergen.trim().isNotEmpty;

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('_save() — personalHistory en el draft', () {
    test('texto vacío → personalHistory null', () {
      final draft = RegisterDraft();
      applySave(draft, '');
      expect(draft.personalHistory, isNull);
    });

    test('texto solo espacios → personalHistory null', () {
      final draft = RegisterDraft();
      applySave(draft, '   ');
      expect(draft.personalHistory, isNull);
    });

    test('texto con contenido → personalHistory con trim', () {
      final draft = RegisterDraft();
      applySave(draft, '  Cirugía de apéndice 2020  ');
      expect(draft.personalHistory, 'Cirugía de apéndice 2020');
    });

    test('texto sin espacios extra → se conserva tal cual', () {
      final draft = RegisterDraft();
      applySave(draft, 'Sin antecedentes');
      expect(draft.personalHistory, 'Sin antecedentes');
    });

    test(
      '_save llama onContinue: draft.personalHistory actualizado antes de continuar',
      () {
        final draft = RegisterDraft()..personalHistory = 'Viejo valor';
        applySave(draft, '');
        expect(draft.personalHistory, isNull);
      },
    );

    test('personalHistory preexistente es sobreescrito', () {
      final draft = RegisterDraft()..personalHistory = 'Previo';
      applySave(draft, 'Nuevo texto');
      expect(draft.personalHistory, 'Nuevo texto');
    });
  });

  group('computePersonalHistory', () {
    test(
      'string vacío → null',
      () => expect(computePersonalHistory(''), isNull),
    );
    test(
      'solo tabs → null',
      () => expect(computePersonalHistory('\t\t'), isNull),
    );
    test(
      'solo saltos de línea → null',
      () => expect(computePersonalHistory('\n\n'), isNull),
    );
    test('string no vacío → devuelve trimmed', () {
      expect(computePersonalHistory('  Hola  '), 'Hola');
    });
    test('string sin espacios → idéntico', () {
      expect(computePersonalHistory('Texto'), 'Texto');
    });
  });

  group('_relLabel — locale ES', () {
    late AppStrings s;
    setUp(() => s = AppStrings.forTesting('es'));

    test("'01' → relParents", () => expect(relLabel(s, '01'), s.relParents));
    test("'02' → relSiblings", () => expect(relLabel(s, '02'), s.relSiblings));
    test("'03' → relUncles", () => expect(relLabel(s, '03'), s.relUncles));
    test(
      "'04' → relGrandparents",
      () => expect(relLabel(s, '04'), s.relGrandparents),
    );
    test("código desconocido → devuelve el código (fallback)", () {
      expect(relLabel(s, '99'), '99');
      expect(relLabel(s, ''), '');
      expect(relLabel(s, 'XYZ'), 'XYZ');
    });
  });

  group('_relLabel — locale EN', () {
    late AppStrings s;
    setUp(() => s = AppStrings.forTesting('en'));

    test(
      "'01' EN → relParents EN",
      () => expect(relLabel(s, '01'), s.relParents),
    );
    test(
      "'02' EN → relSiblings EN",
      () => expect(relLabel(s, '02'), s.relSiblings),
    );
    test(
      "'03' EN → relUncles EN",
      () => expect(relLabel(s, '03'), s.relUncles),
    );
    test(
      "'04' EN → relGrandparents EN",
      () => expect(relLabel(s, '04'), s.relGrandparents),
    );

    test('ES y EN de relParents son diferentes', () {
      final es = AppStrings.forTesting('es');
      final en = AppStrings.forTesting('en');
      expect(relLabel(es, '01'), isNot(equals(relLabel(en, '01'))));
    });
  });

  group('_catLabel — locale ES', () {
    late AppStrings s;
    setUp(() => s = AppStrings.forTesting('es'));

    test(
      "'01' → allergenMedication",
      () => expect(catLabel(s, '01'), s.allergenMedication),
    );
    test(
      "'02' → allergenFood",
      () => expect(catLabel(s, '02'), s.allergenFood),
    );
    test(
      "'03' → allergenEnvironment",
      () => expect(catLabel(s, '03'), s.allergenEnvironment),
    );
    test(
      "'04' → allergenSkin",
      () => expect(catLabel(s, '04'), s.allergenSkin),
    );
    test(
      "'05' → allergenInsect",
      () => expect(catLabel(s, '05'), s.allergenInsect),
    );
    test(
      "'06' → allergenOther",
      () => expect(catLabel(s, '06'), s.allergenOther),
    );
    test("código desconocido → fallback al código", () {
      expect(catLabel(s, '07'), '07');
      expect(catLabel(s, ''), '');
    });
  });

  group('_catLabel — locale EN', () {
    late AppStrings s;
    setUp(() => s = AppStrings.forTesting('en'));

    test(
      "'01' EN → allergenMedication EN",
      () => expect(catLabel(s, '01'), s.allergenMedication),
    );
    test(
      "'06' EN → allergenOther EN",
      () => expect(catLabel(s, '06'), s.allergenOther),
    );

    test('ES y EN de allergenFood son diferentes', () {
      final es = AppStrings.forTesting('es');
      final en = AppStrings.forTesting('en');
      expect(catLabel(es, '02'), isNot(equals(catLabel(en, '02'))));
    });
  });

  group('_medStatusLabel — locale ES', () {
    late AppStrings s;
    setUp(() => s = AppStrings.forTesting('es'));

    test(
      "'active' → medStatusActive",
      () => expect(medStatusLabel(s, 'active'), s.medStatusActive),
    );
    test(
      "'completed' → medStatusCompleted",
      () => expect(medStatusLabel(s, 'completed'), s.medStatusCompleted),
    );
    test(
      "'stopped' → medStatusStopped",
      () => expect(medStatusLabel(s, 'stopped'), s.medStatusStopped),
    );
    test(
      "'unknown' → medStatusUnknown",
      () => expect(medStatusLabel(s, 'unknown'), s.medStatusUnknown),
    );
    test("código desconocido → fallback al código", () {
      expect(medStatusLabel(s, 'other'), 'other');
      expect(medStatusLabel(s, ''), '');
    });
  });

  group('_medStatusLabel — locale EN', () {
    late AppStrings s;
    setUp(() => s = AppStrings.forTesting('en'));

    test(
      "'active' EN → medStatusActive EN",
      () => expect(medStatusLabel(s, 'active'), s.medStatusActive),
    );
    test(
      "'stopped' EN → medStatusStopped EN",
      () => expect(medStatusLabel(s, 'stopped'), s.medStatusStopped),
    );

    test('ES y EN de medStatusActive son diferentes', () {
      final es = AppStrings.forTesting('es');
      final en = AppStrings.forTesting('en');
      expect(
        medStatusLabel(es, 'active'),
        isNot(equals(medStatusLabel(en, 'active'))),
      );
    });
  });

  group('_ItemCard subtitle — medicación', () {
    test('sin dosage → solo el statusLabel', () {
      expect(medSubtitle('Activo', null), 'Activo');
    });

    test('dosage vacío → solo el statusLabel', () {
      expect(medSubtitle('Activo', ''), 'Activo');
    });

    test('con dosage → statusLabel · dosage', () {
      expect(medSubtitle('Activo', '500mg'), 'Activo · 500mg');
    });

    test('statusLabel vacío con dosage → " · dosage"', () {
      expect(medSubtitle('', '10ml'), ' · 10ml');
    });
  });

  group('_ItemCard subtitle — alergias', () {
    test('sin reaction → solo la catLabel', () {
      expect(allergySubtitle('Medicamento', null), 'Medicamento');
    });

    test('reaction vacío → solo la catLabel', () {
      expect(allergySubtitle('Medicamento', ''), 'Medicamento');
    });

    test('con reaction → catLabel · reaction', () {
      expect(
        allergySubtitle('Medicamento', 'Urticaria'),
        'Medicamento · Urticaria',
      );
    });
  });

  group('_AddChronicConditionSheet — buildChronicCondition', () {
    test('descripción con espacios → trim aplicado', () {
      final item = buildChronicCondition('  Diabetes tipo 2  ');
      expect(item.chronicDescription, 'Diabetes tipo 2');
    });

    test('descripción sin espacios → idéntica', () {
      expect(buildChronicCondition('Asma').chronicDescription, 'Asma');
    });
  });

  group('_AddChronicConditionSheet — ccCanConfirm', () {
    test(
      'texto vacío → canConfirm false',
      () => expect(ccCanConfirm(''), isFalse),
    );
    test(
      'solo espacios → canConfirm false',
      () => expect(ccCanConfirm('   '), isFalse),
    );
    test(
      'texto con contenido → canConfirm true',
      () => expect(ccCanConfirm('Diabetes'), isTrue),
    );
    test(
      'texto con espacios y contenido → canConfirm true',
      () => expect(ccCanConfirm(' x '), isTrue),
    );
  });

  group('_AddMedicationSheet — buildMedication', () {
    test('nombre con trim', () {
      expect(
        buildMedication(
          name: '  Ibuprofeno  ',
          status: 'active',
        ).medicationName,
        'Ibuprofeno',
      );
    });

    test('status se conserva', () {
      expect(buildMedication(name: 'Med', status: 'stopped').status, 'stopped');
    });

    test('dosage vacío → null', () {
      expect(
        buildMedication(name: 'Med', status: 'active', dosage: '').dosage,
        isNull,
      );
    });

    test('dosage solo espacios → null', () {
      expect(
        buildMedication(name: 'Med', status: 'active', dosage: '   ').dosage,
        isNull,
      );
    });

    test('dosage con valor → trimmed y no null', () {
      expect(
        buildMedication(
          name: 'Med',
          status: 'active',
          dosage: ' 500mg ',
        ).dosage,
        '500mg',
      );
    });

    test('notes vacío → null', () {
      expect(
        buildMedication(name: 'Med', status: 'active', notes: '').notes,
        isNull,
      );
    });

    test('notes solo espacios → null', () {
      expect(
        buildMedication(name: 'Med', status: 'active', notes: '   ').notes,
        isNull,
      );
    });

    test('notes con valor → trimmed', () {
      expect(
        buildMedication(
          name: 'Med',
          status: 'active',
          notes: '  2 veces al día  ',
        ).notes,
        '2 veces al día',
      );
    });

    test('status default es active si no se cambia', () {
      const defaultStatus = 'active';
      expect(
        buildMedication(name: 'Med', status: defaultStatus).status,
        'active',
      );
    });
  });

  group('_AddMedicationSheet — medCanConfirm', () {
    test(
      'nombre vacío → canConfirm false',
      () => expect(medCanConfirm(''), isFalse),
    );
    test(
      'solo espacios → canConfirm false',
      () => expect(medCanConfirm('  '), isFalse),
    );
    test(
      'con nombre → canConfirm true',
      () => expect(medCanConfirm('Aspirina'), isTrue),
    );
  });

  group('_AddFamilyHistorySheet — buildFamilyHistory', () {
    test('conditionDescription con trim', () {
      final item = buildFamilyHistory(
        conditionDescription: '  Hipertensión  ',
        relationship: '01',
      );
      expect(item.conditionDescription, 'Hipertensión');
    });

    test('relationship se conserva', () {
      final item = buildFamilyHistory(
        conditionDescription: 'Cáncer',
        relationship: '03',
      );
      expect(item.relationship, '03');
    });

    test('relationship default del State es "01"', () {
      final item = buildFamilyHistory(
        conditionDescription: 'Diabetes',
        relationship: '01',
      );
      expect(item.relationship, '01');
    });

    test('todos los relationships válidos', () {
      for (final rel in ['01', '02', '03', '04']) {
        final item = buildFamilyHistory(
          conditionDescription: 'Cond',
          relationship: rel,
        );
        expect(item.relationship, rel);
      }
    });
  });

  group('_AddFamilyHistorySheet — fhCanConfirm', () {
    test('vacío → false', () => expect(fhCanConfirm(''), isFalse));
    test('solo espacios → false', () => expect(fhCanConfirm('   '), isFalse));
    test('con texto → true', () => expect(fhCanConfirm('Diabetes'), isTrue));
  });

  group('_AddAllergySheet — buildAllergy', () {
    test('allergen con trim', () {
      final item = buildAllergy(allergen: '  Penicilina  ', category: '01');
      expect(item.allergen, 'Penicilina');
    });

    test('category se conserva', () {
      final item = buildAllergy(allergen: 'Polen', category: '03');
      expect(item.category, '03');
    });

    test('reaction vacío → null', () {
      final item = buildAllergy(
        allergen: 'Polen',
        category: '03',
        reaction: '',
      );
      expect(item.reaction, isNull);
    });

    test('reaction solo espacios → null', () {
      final item = buildAllergy(
        allergen: 'Polen',
        category: '03',
        reaction: '   ',
      );
      expect(item.reaction, isNull);
    });

    test('reaction con valor → trimmed', () {
      final item = buildAllergy(
        allergen: 'Polen',
        category: '03',
        reaction: '  Urticaria  ',
      );
      expect(item.reaction, 'Urticaria');
    });

    test('category default del State es "01"', () {
      final item = buildAllergy(allergen: 'Med', category: '01');
      expect(item.category, '01');
    });

    test('todos los categories válidos (01-06)', () {
      for (var i = 1; i <= 6; i++) {
        final cat = i.toString().padLeft(2, '0');
        final item = buildAllergy(allergen: 'X', category: cat);
        expect(item.category, cat);
      }
    });
  });

  group('_AddAllergySheet — allergyCanConfirm', () {
    test(
      'allergen vacío → false',
      () => expect(allergyCanConfirm(''), isFalse),
    );
    test(
      'solo espacios → false',
      () => expect(allergyCanConfirm('   '), isFalse),
    );
    test(
      'con allergen → true',
      () => expect(allergyCanConfirm('Penicilina'), isTrue),
    );
  });

  group('isEs — detección de locale (s.welcome == Bienvenido)', () {
    test('locale es → isEs true', () {
      final s = AppStrings.forTesting('es');
      expect(s.welcome == 'Bienvenido', isTrue);
    });

    test('locale en → isEs false', () {
      final s = AppStrings.forTesting('en');
      expect(s.welcome == 'Bienvenido', isFalse);
    });
  });

  group('Subtítulos inline hardcodeados — Step4Background.build()', () {
    test('ES — FormSectionHeader chronicConditions subtitle', () {
      const subtitle = 'Agregue cada condición.';
      expect(subtitle, isNotEmpty);
    });

    test('EN — FormSectionHeader chronicConditions subtitle', () {
      const subtitle = 'Add each condition.';
      expect(subtitle, isNotEmpty);
    });

    test('ES — _EmptyCard chronicConditions', () {
      const msg = 'Sin condiciones crónicas. Toque "Agregar".';
      expect(msg, contains('Agregar'));
    });

    test('EN — _EmptyCard chronicConditions', () {
      const msg = 'No chronic conditions. Tap "Add".';
      expect(msg, contains('Add'));
    });

    test('ES — _EmptyCard medications', () {
      const msg = 'Sin medicamentos registrados. Toque "Agregar".';
      expect(msg, contains('medicamentos'));
    });

    test('EN — _EmptyCard medications', () {
      const msg = 'No medications registered. Tap "Add".';
      expect(msg, contains('medications'));
    });

    test('ES — _EmptyCard familyHistory', () {
      const msg = 'Sin antecedentes familiares. Toque "Agregar".';
      expect(msg, contains('familiares'));
    });

    test('EN — _EmptyCard familyHistory', () {
      const msg = 'No family history entries yet. Tap "Add".';
      expect(msg, contains('family history'));
    });

    test('ES — _EmptyCard allergies', () {
      const msg = 'Sin alergias registradas. Toque "Agregar".';
      expect(msg, contains('alergias'));
    });

    test('EN — _EmptyCard allergies', () {
      const msg = 'No allergies registered. Tap "Add".';
      expect(msg, contains('allergies'));
    });

    test('ES — personalHistory section subtitle', () {
      const subtitle = 'Antecedentes quirúrgicos, hospitalizaciones, etc.';
      expect(subtitle, contains('quirúrgicos'));
    });

    test('EN — personalHistory section subtitle', () {
      const subtitle = 'Surgical history, hospitalizations, etc.';
      expect(subtitle, contains('Surgical'));
    });

    test('ES — VoiceTextArea personalHistory hint', () {
      const hint = 'Ej. Cirugía de adenoides 2021...';
      expect(hint, contains('Cirugía'));
    });

    test('EN — VoiceTextArea personalHistory hint', () {
      const hint = 'e.g. Adenoid surgery 2021...';
      expect(hint, contains('Adenoid'));
    });

    test('ES — medications subtitle', () {
      const subtitle = 'Medicamentos actuales del paciente.';
      expect(subtitle, contains('Medicamentos'));
    });

    test('EN — medications subtitle', () {
      const subtitle = "Patient's current medications.";
      expect(subtitle, contains('medications'));
    });
  });
}
