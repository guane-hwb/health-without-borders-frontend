// test/unit/edit_vital_signs_sheet_unit_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_vital_signs_helpers.dart';

void main() {
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

  group('Weight Parsing — parseWeight (matches _handleConfirm exactly)', () {
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
      '"72,5" → 72.5 (producción SÍ acepta coma decimal via replaceAll)',
      () {
        expect(parseWeight('72,5'), equals(72.5));
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

  group('Height Parsing — parseHeight (matches _handleConfirm exactly)', () {
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

    test('"180,5" → 180.5 (coma decimal aceptada, igual que en peso)', () {
      expect(parseHeight('180,5'), equals(180.5));
    });
  });

  group('Range validation — isWeightInRange / isHeightInRange', () {
    test('0.2 kg es el límite inferior EXCLUSIVO → false', () {
      expect(isWeightInRange(0.2), isFalse);
    });
    test('0.3 kg está dentro de rango → true', () {
      expect(isWeightInRange(0.3), isTrue);
    });
    test('350.0 kg es el límite superior INCLUSIVO → true', () {
      expect(isWeightInRange(350.0), isTrue);
    });
    test('350.1 kg excede el límite superior → false', () {
      expect(isWeightInRange(350.1), isFalse);
    });
    test('20.0 cm es el límite inferior EXCLUSIVO → false', () {
      expect(isHeightInRange(20.0), isFalse);
    });
    test('20.1 cm está dentro de rango → true', () {
      expect(isHeightInRange(20.1), isTrue);
    });
    test('250.0 cm es el límite superior INCLUSIVO → true', () {
      expect(isHeightInRange(250.0), isTrue);
    });
    test('250.1 cm excede el límite superior → false', () {
      expect(isHeightInRange(250.1), isFalse);
    });
  });

  group(
    'Mensajes de error bilingües — weightErrorMessage / heightErrorMessage',
    () {
      test('es: peso', () {
        expect(
          weightErrorMessage(isEs: true),
          'El peso debe estar entre 0.2 kg y 350 kg',
        );
      });
      test('en: peso', () {
        expect(
          weightErrorMessage(isEs: false),
          'Weight must be between 0.2 kg and 350 kg',
        );
      });
      test('es: altura', () {
        expect(
          heightErrorMessage(isEs: true),
          'La altura debe estar entre 20 cm y 250 cm',
        );
      });
      test('en: altura', () {
        expect(
          heightErrorMessage(isEs: false),
          'Height must be between 20 cm and 250 cm',
        );
      });
    },
  );

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
}
