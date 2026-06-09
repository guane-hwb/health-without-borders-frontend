// test/unit/add_chronic_condition_sheet_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

void main() {
  group('ChronicConditionItem – Model', () {
    test('creates correctly with a valid description', () {
      final item = ChronicConditionItem(chronicDescription: 'Diabetes tipo 2');
      expect(item.chronicDescription, 'Diabetes tipo 2');
    });

    test('accepts empty description without throwing an exception', () {
      final item = ChronicConditionItem(chronicDescription: '');
      expect(item.chronicDescription, '');
    });

    test(
      'preserves internal spacing but trims external whitespace as expected by the widget',
      () {
        const raw = '  Hipertensión  ';
        final trimmed = raw.trim();
        final item = ChronicConditionItem(chronicDescription: trimmed);
        expect(item.chronicDescription, 'Hipertensión');
      },
    );

    test('description containing special characters is stored unaltered', () {
      final item = ChronicConditionItem(
        chronicDescription: 'Enfermedad de Crohn (crónica) – severa',
      );
      expect(item.chronicDescription, 'Enfermedad de Crohn (crónica) – severa');
    });
  });

  group('TextEditingController – canConfirm Logic', () {
    late TextEditingController ctrl;

    setUp(() {
      ctrl = TextEditingController();
    });

    tearDown(() {
      ctrl.dispose();
    });

    bool canConfirm() => ctrl.text.trim().isNotEmpty;

    test('canConfirm is false when the controller is empty', () {
      expect(canConfirm(), isFalse);
    });

    test('canConfirm is false when the text contains only spaces', () {
      ctrl.text = '   ';
      expect(canConfirm(), isFalse);
    });

    test('canConfirm is false when the text contains only linebreaks', () {
      ctrl.text = '\n\n';
      expect(canConfirm(), isFalse);
    });

    test('canConfirm is true when the text has valid content', () {
      ctrl.text = 'Asma';
      expect(canConfirm(), isTrue);
    });

    test(
      'canConfirm is true when the text has surrounding whitespace but contains valid content',
      () {
        ctrl.text = '  Lupus  ';
        expect(canConfirm(), isTrue);
      },
    );

    test(
      'trimming applied when creating ChronicConditionItem drops external whitespace parameters',
      () {
        ctrl.text = '  Artritis reumatoide  ';
        final item = ChronicConditionItem(chronicDescription: ctrl.text.trim());
        expect(item.chronicDescription, 'Artritis reumatoide');
      },
    );

    test('mutating text from empty to valid toggles canConfirm to true', () {
      expect(canConfirm(), isFalse);
      ctrl.text = 'Fibromialgia';
      expect(canConfirm(), isTrue);
    });

    test('clearing the controller value resets canConfirm back to false', () {
      ctrl.text = 'Psoriasis';
      expect(canConfirm(), isTrue);
      ctrl.clear();
      expect(canConfirm(), isFalse);
    });
  });
}
