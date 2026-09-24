// test/unit/add_family_history_sheet_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

void main() {
  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Replicates the private _label() widget method for isolated pure logic tests.
  String label(AppStrings s, String code) => switch (code) {
    '01' => s.relParents,
    '02' => s.relSiblings,
    '03' => s.relUncles,
    '04' => s.relGrandparents,
    _ => code,
  };

  group('AppStrings.forTesting — Spanish locale validations (es)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('es'));

    test('addFamilyHistory returns the correct value', () {
      expect(s.addFamilyHistory, equals('Agregar antecedente familiar'));
    });

    test('relationship returns the correct value', () {
      expect(s.relationship, equals('Parentesco'));
    });

    test('condition returns the correct value', () {
      expect(s.condition, equals('Condición'));
    });

    test('confirm returns the correct value', () {
      expect(s.confirm, equals('Confirmar'));
    });

    test('chronicConditionHint returns the correct value', () {
      expect(
        s.chronicConditionHint,
        equals('ej: Diabetes mellitus tipo 2, Hipertensión arterial...'),
      );
    });

    test('relParents returns the correct value', () {
      expect(s.relParents, equals('Padres'));
    });

    test('relSiblings returns the correct value', () {
      expect(s.relSiblings, equals('Hermanos'));
    });

    test('relUncles returns the correct value', () {
      expect(s.relUncles, equals('Tíos'));
    });

    test('relGrandparents returns the correct value', () {
      expect(s.relGrandparents, equals('Abuelos'));
    });
  });

  group('AppStrings.forTesting — English locale validations (en)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('en'));

    test('addFamilyHistory returns the correct value', () {
      expect(s.addFamilyHistory, equals('Add family history'));
    });

    test('relationship returns the correct value', () {
      expect(s.relationship, equals('Relationship'));
    });

    test('condition returns the correct value', () {
      expect(s.condition, equals('Condition'));
    });

    test('confirm returns the correct value', () {
      expect(s.confirm, equals('Confirm'));
    });

    test('relParents returns the correct value', () {
      expect(s.relParents, equals('Parents'));
    });

    test('relSiblings returns the correct value', () {
      expect(s.relSiblings, equals('Siblings'));
    });

    test('relUncles returns the correct value', () {
      expect(s.relUncles, equals('Uncles'));
    });

    test('relGrandparents returns the correct value', () {
      expect(s.relGrandparents, equals('Grandparents'));
    });
  });

  group('_label() — mapping codes to labels (es)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('es'));

    test('code 01 maps to Padres', () {
      expect(label(s, '01'), equals('Padres'));
    });

    test('code 02 maps to Hermanos', () {
      expect(label(s, '02'), equals('Hermanos'));
    });

    test('code 03 maps to Tíos', () {
      expect(label(s, '03'), equals('Tíos'));
    });

    test('code 04 maps to Abuelos', () {
      expect(label(s, '04'), equals('Abuelos'));
    });

    test('unknown codes return the input code as a fallback strategy', () {
      expect(label(s, '99'), equals('99'));
      expect(label(s, 'XYZ'), equals('XYZ'));
      expect(label(s, ''), equals(''));
    });
  });

  group('_label() — mapping codes to labels (en)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('en'));

    test('code 01 maps to Parents', () {
      expect(label(s, '01'), equals('Parents'));
    });

    test('code 02 maps to Siblings', () {
      expect(label(s, '02'), equals('Siblings'));
    });

    test('code 03 maps to Uncles', () {
      expect(label(s, '03'), equals('Uncles'));
    });

    test('code 04 maps to Grandparents', () {
      expect(label(s, '04'), equals('Grandparents'));
    });

    test('unknown codes return the input code as a fallback strategy', () {
      expect(label(s, '05'), equals('05'));
    });
  });

  group('AddFamilyHistorySheet — Unsaved Changes Evaluation', () {
    bool hasUnsavedChanges(String conditionText, String relationship) {
      return conditionText.trim().isNotEmpty || relationship != '01';
    }

    test('returns false when text is blank and relationship is default 01', () {
      expect(hasUnsavedChanges('', '01'), isFalse);
      expect(hasUnsavedChanges('   ', '01'), isFalse);
    });

    test('returns true when text is entered', () {
      expect(hasUnsavedChanges('Diabetes', '01'), isTrue);
    });

    test('returns true when relationship changes from default 01', () {
      expect(hasUnsavedChanges('', '02'), isTrue);
      expect(hasUnsavedChanges('', '03'), isTrue);
      expect(hasUnsavedChanges('', '04'), isTrue);
    });
  });
}
