// test/unit/allergies_manage_sheet_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

void main() {
  String catLabel(AppStrings s, String c) {
    switch (c) {
      case '01':
        return s.allergenMedication;
      case '02':
        return s.allergenFood;
      case '03':
        return s.allergenEnvironment;
      case '04':
        return s.allergenSkin;
      case '05':
        return s.allergenInsect;
      case '06':
        return s.allergenOther;
      default:
        return c;
    }
  }

  group('AllergiesManageSheet – Category mapping & AppStrings (es)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('es'));

    test('01 maps to allergenMedication', () {
      expect(catLabel(s, '01'), equals('Medicamento'));
    });

    test('02 maps to allergenFood', () {
      expect(catLabel(s, '02'), equals('Alimento'));
    });

    test('03 maps to allergenEnvironment', () {
      expect(catLabel(s, '03'), equals('Sustancia ambiental'));
    });

    test('04 maps to allergenSkin', () {
      expect(catLabel(s, '04'), equals('Sustancia en piel'));
    });

    test('05 maps to allergenInsect', () {
      expect(catLabel(s, '05'), equals('Picadura insectos'));
    });

    test('06 maps to allergenOther', () {
      expect(catLabel(s, '06'), equals('Otra'));
    });

    test('default fallback returns raw category code', () {
      expect(catLabel(s, '99'), equals('99'));
      expect(catLabel(s, 'UNKNOWN'), equals('UNKNOWN'));
    });

    test('Header & label AppStrings return non-empty localized strings', () {
      expect(s.allergiesSheetTitle, equals('Alergias'));
      expect(s.noAllergiesRegistered, equals('Sin alergias registradas.'));
      expect(s.reactionLabel, equals('Reacción: '));
      expect(s.addAllergyBtn, equals('Agregar alergia'));
    });
  });

  group('AllergiesManageSheet – Category mapping & AppStrings (en)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('en'));

    test('01 maps to Medication', () {
      expect(catLabel(s, '01'), equals('Medication'));
    });

    test('02 maps to Food', () {
      expect(catLabel(s, '02'), equals('Food'));
    });

    test('03 maps to Environmental substance', () {
      expect(catLabel(s, '03'), equals('Environmental substance'));
    });

    test('04 maps to Skin substance', () {
      expect(catLabel(s, '04'), equals('Skin substance'));
    });

    test('05 maps to Insect sting', () {
      expect(catLabel(s, '05'), equals('Insect sting'));
    });

    test('06 maps to Other', () {
      expect(catLabel(s, '06'), equals('Other'));
    });

    test('default fallback returns raw category code', () {
      expect(catLabel(s, '99'), equals('99'));
    });
  });
}
