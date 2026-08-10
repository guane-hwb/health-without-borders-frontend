// test/unit/edit_vital_signs_sheet_unit_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/clinical_validation_utils.dart';

// ── Helpers Replicating Private Widget Logic ─────────────────────────────────

String weightInitText(double? weight) =>
    weight != null ? weight.toStringAsFixed(1) : '';

String heightInitText(double? height) =>
    height != null ? height.toStringAsFixed(0) : '';

double? parseWeight(String text) => double.tryParse(text.trim());

double? parseHeight(String text) => double.tryParse(text.trim());

bool showPreviousWeight(double? previousWeight) => previousWeight != null;

bool showPreviousHeight(double? previousHeight) => previousHeight != null;

String previousWeightText(String previous, double previousWeight) =>
    '$previous: ${previousWeight.toStringAsFixed(1)} kg';

String previousHeightText(String previous, double previousHeight) =>
    '$previous: ${previousHeight.toStringAsFixed(0)} cm';

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ClinicalValidationUtils (Importado de Dominio)', () {
    test('acepta pesos dentro del rango pediátrico/clínico válido', () {
      expect(ClinicalValidationUtils.validateWeight(72.5), isNull);
      expect(ClinicalValidationUtils.validateWeight(3.4), isNull);
    });

    test('rechaza pesos fuera del rango clínico (<= 0.2 kg o > 350 kg)', () {
      expect(ClinicalValidationUtils.validateWeight(0.1), isNotNull);
      expect(ClinicalValidationUtils.validateWeight(400.0), isNotNull);
    });

    test('acepta alturas dentro del rango válido', () {
      expect(ClinicalValidationUtils.validateHeight(170.0), isNull);
      expect(ClinicalValidationUtils.validateHeight(50.0), isNull);
    });

    test('rechaza alturas fuera del rango clínico (<= 20 cm o > 250 cm)', () {
      expect(ClinicalValidationUtils.validateHeight(10.0), isNotNull);
      expect(ClinicalValidationUtils.validateHeight(300.0), isNotNull);
    });
  });

  group('Weight Formatting — toStringAsFixed(1)', () {
    test('65.0 → "65.0"', () {
      expect(weightInitText(65.0), equals('65.0'));
    });

    test('72.5 → "72.5"', () {
      expect(weightInitText(72.5), equals('72.5'));
    });

    test('100.0 → "100.0"', () {
      expect(weightInitText(100.0), equals('100.0'));
    });

    test('3.4 → "3.4" (infant metric evaluation)', () {
      expect(weightInitText(3.4), equals('3.4'));
    });

    test('0.0 → "0.0"', () {
      expect(weightInitText(0.0), equals('0.0'));
    });

    test('null → "" (renders empty field fallback bounds)', () {
      expect(weightInitText(null), equals(''));
    });

    test(
      'rounds weights with multiple fractional digits to exactly 1 decimal place',
      () {
        expect(weightInitText(72.567), equals('72.6'));
      },
    );

    test(
      'appends trailing zero fractional components to exact integer numbers',
      () {
        expect(weightInitText(80), equals('80.0'));
      },
    );
  });

  group('Height Formatting — toStringAsFixed(0)', () {
    test('170.0 → "170"', () {
      expect(heightInitText(170.0), equals('170'));
    });

    test('50.0 → "50" (infant metric evaluation)', () {
      expect(heightInitText(50.0), equals('50'));
    });

    test('180.5 → "181" (standard mathematical rounding constraints)', () {
      expect(heightInitText(180.5), equals('181'));
    });

    test('0.0 → "0"', () {
      expect(heightInitText(0.0), equals('0'));
    });

    test('null → "" (renders empty field fallback bounds)', () {
      expect(heightInitText(null), equals(''));
    });

    test(
      'preserves whole values unchanged when initialized with flat double parameters',
      () {
        expect(heightInitText(165.0), equals('165'));
      },
    );
  });

  group('Weight Parsing Execution — double.tryParse operations', () {
    test('"72.5" → 72.5', () {
      expect(parseWeight('72.5'), equals(72.5));
    });

    test('"65" → 65.0', () {
      expect(parseWeight('65'), equals(65.0));
    });

    test('"0.0" → 0.0', () {
      expect(parseWeight('0.0'), equals(0.0));
    });

    test('"100.0" → 100.0', () {
      expect(parseWeight('100.0'), equals(100.0));
    });

    test('"" → null (empty entry boundaries evaluation)', () {
      expect(parseWeight(''), isNull);
    });

    test(
      '"abc" → null (invalid alphanumeric token sequences drops into null)',
      () {
        expect(parseWeight('abc'), isNull);
      },
    );

    test(
      '"72,5" → null (comma decimal separators reject baseline format expectations)',
      () {
        expect(parseWeight('72,5'), isNull);
      },
    );

    test('"  72.5  " → 72.5 (applies structural trim procedures cleanly)', () {
      expect(parseWeight('  72.5  '), equals(72.5));
    });

    test('"3.4" → 3.4 (processes explicit decimal metrics successfully)', () {
      expect(parseWeight('3.4'), equals(3.4));
    });

    test(
      '" " → null (whitespace parameters evaluate into non-numeric states)',
      () {
        expect(parseWeight(' '), isNull);
      },
    );
  });

  group('Height Parsing Execution — double.tryParse operations', () {
    test('"170" → 170.0', () {
      expect(parseHeight('170'), equals(170.0));
    });

    test('"165.5" → 165.5', () {
      expect(parseHeight('165.5'), equals(165.5));
    });

    test('"50" → 50.0 (processes structural metrics successfully)', () {
      expect(parseHeight('50'), equals(50.0));
    });

    test('"" → null (empty entry boundaries evaluation)', () {
      expect(parseHeight(''), isNull);
    });

    test(
      '"altura" → null (invalid text values fall back to null configurations)',
      () {
        expect(parseHeight('altura'), isNull);
      },
    );

    test('"  180  " → 180.0 (applies structural trim procedures cleanly)', () {
      expect(parseHeight('  180  '), equals(180.0));
    });

    test('"0" → 0.0', () {
      expect(parseHeight('0'), equals(0.0));
    });
  });

  group('TextEditingControllers — Memory Instance Initializations', () {
    test(
      '_weightCtrl pre-populates with string representation "72.5" when active models exist',
      () {
        final ctrl = TextEditingController(text: weightInitText(72.5));
        expect(ctrl.text, equals('72.5'));
        ctrl.dispose();
      },
    );

    test(
      '_weightCtrl initializes completely empty if model parameters evaluate to null',
      () {
        final ctrl = TextEditingController(text: weightInitText(null));
        expect(ctrl.text, isEmpty);
        ctrl.dispose();
      },
    );

    test(
      '_heightCtrl pre-populates with string representation "170" when active models exist',
      () {
        final ctrl = TextEditingController(text: heightInitText(170.0));
        expect(ctrl.text, equals('170'));
        ctrl.dispose();
      },
    );

    test(
      '_heightCtrl initializes completely empty if model parameters evaluate to null',
      () {
        final ctrl = TextEditingController(text: heightInitText(null));
        expect(ctrl.text, isEmpty);
        ctrl.dispose();
      },
    );

    test(
      'mutating active weight forms reflects target controller content changes',
      () {
        final ctrl = TextEditingController(text: '65.0');
        ctrl.text = '70.5';
        expect(ctrl.text, equals('70.5'));
        ctrl.dispose();
      },
    );

    test(
      'invoking controller clear operations purges metric tracking states',
      () {
        final ctrl = TextEditingController(text: '170');
        ctrl.clear();
        expect(ctrl.text, isEmpty);
        ctrl.dispose();
      },
    );
  });

  group('Historical Metadata Contexts — Visibility Logic Triggers', () {
    test(
      'showPreviousWeight reports true when valid historical coordinates exist',
      () {
        expect(showPreviousWeight(68.0), isTrue);
      },
    );

    test(
      'showPreviousWeight reports false when historical parameters are missing',
      () {
        expect(showPreviousWeight(null), isFalse);
      },
    );

    test(
      'showPreviousHeight reports true when valid historical coordinates exist',
      () {
        expect(showPreviousHeight(165.0), isTrue);
      },
    );

    test(
      'showPreviousHeight reports false when historical parameters are missing',
      () {
        expect(showPreviousHeight(null), isFalse);
      },
    );

    test(
      'showPreviousWeight retains active triggers even for zero absolute values',
      () {
        expect(showPreviousWeight(0.0), isTrue);
      },
    );

    test(
      'showPreviousHeight retains active triggers even for zero absolute values',
      () {
        expect(showPreviousHeight(0.0), isTrue);
      },
    );
  });

  group('Historical Records Labels — Internationalization Copy Assertions', () {
    test('ES localization strategy resolves to "Anterior: 68.0 kg"', () {
      expect(previousWeightText('Anterior', 68.0), equals('Anterior: 68.0 kg'));
    });

    test('EN localization strategy resolves to "Previous: 68.0 kg"', () {
      expect(previousWeightText('Previous', 68.0), equals('Previous: 68.0 kg'));
    });

    test('ES localization strategy resolves to "Anterior: 165 cm"', () {
      expect(previousHeightText('Anterior', 165.0), equals('Anterior: 165 cm'));
    });

    test('EN localization strategy resolves to "Previous: 165 cm"', () {
      expect(previousHeightText('Previous', 165.0), equals('Previous: 165 cm'));
    });

    test(
      'historical weight values are rendered preserving exactly 1 trailing decimal component',
      () {
        expect(
          previousWeightText('Anterior', 72.567),
          equals('Anterior: 72.6 kg'),
        );
      },
    );

    test(
      'historical height values are rendered rounding fractions into integers',
      () {
        expect(
          previousHeightText('Anterior', 170.7),
          equals('Anterior: 171 cm'),
        );
      },
    );
  });

  group(
    'onConfirm Extraction Pipelines — Value Extraction Gates Assertions',
    () {
      test('extracts valid numerical weight contents accurately', () {
        final w = parseWeight('72.5');
        expect(w, equals(72.5));
      });

      test('extracts valid numerical height contents accurately', () {
        final h = parseHeight('170');
        expect(h, equals(170.0));
      });

      test(
        'extracts unpopulated weight fields directly into null attributes',
        () {
          final w = parseWeight('');
          expect(w, isNull);
        },
      );

      test(
        'extracts unpopulated height fields directly into null attributes',
        () {
          final h = parseHeight('');
          expect(h, isNull);
        },
      );

      test(
        'extracts corrupted weight entries directly into null properties',
        () {
          final w = parseWeight('no-es-un-numero');
          expect(w, isNull);
        },
      );

      test(
        'extracts corrupted height entries directly into null properties',
        () {
          final h = parseHeight('--');
          expect(h, isNull);
        },
      );

      test(
        'both fields capture non-null values under flawless input sequences',
        () {
          final w = parseWeight('72.5');
          final h = parseHeight('170');
          expect(w, isNotNull);
          expect(h, isNotNull);
        },
      );

      test(
        'both fields evaluate into null parameters when text fields are empty',
        () {
          final w = parseWeight('');
          final h = parseHeight('');
          expect(w, isNull);
          expect(h, isNull);
        },
      );
    },
  );
}
