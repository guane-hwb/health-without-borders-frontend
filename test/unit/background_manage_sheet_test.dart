// test/unit/background_manage_sheet_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

void main() {
  String relLabel(AppStrings s, String r) {
    switch (r) {
      case '01':
        return s.relParents;
      case '02':
        return s.relSiblings;
      case '03':
        return s.relUncles;
      case '04':
        return s.relGrandparents;
      default:
        return r;
    }
  }

  String medStatusLabel(AppStrings s, String c) {
    switch (c) {
      case 'active':
        return s.medStatusActive;
      case 'completed':
        return s.medStatusCompleted;
      case 'stopped':
        return s.medStatusStopped;
      case 'unknown':
        return s.medStatusUnknown;
      default:
        return c;
    }
  }

  group('BackgroundManageSheet – Mappings & Localizations (es)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('es'));

    test('Relationship mapping (es)', () {
      expect(relLabel(s, '01'), equals('Padres'));
      expect(relLabel(s, '02'), equals('Hermanos'));
      expect(relLabel(s, '03'), equals('Tíos'));
      expect(relLabel(s, '04'), equals('Abuelos'));
      expect(relLabel(s, '99'), equals('99'));
    });

    test('Medication status mapping (es)', () {
      expect(medStatusLabel(s, 'active'), equals('Activo'));
      expect(medStatusLabel(s, 'completed'), equals('Completado'));
      expect(medStatusLabel(s, 'stopped'), equals('Suspendido'));
      expect(medStatusLabel(s, 'unknown'), equals('Desconocido'));
      expect(medStatusLabel(s, 'paused'), equals('paused'));
    });
  });

  group('BackgroundManageSheet – Mappings & Localizations (en)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('en'));

    test('Relationship mapping (en)', () {
      expect(relLabel(s, '01'), equals('Parents'));
      expect(relLabel(s, '02'), equals('Siblings'));
      expect(relLabel(s, '03'), equals('Uncles'));
      expect(relLabel(s, '04'), equals('Grandparents'));
      expect(relLabel(s, 'CUSTOM'), equals('CUSTOM'));
    });

    test('Medication status mapping (en)', () {
      expect(medStatusLabel(s, 'active'), equals('Active'));
      expect(medStatusLabel(s, 'completed'), equals('Completed'));
      expect(medStatusLabel(s, 'stopped'), equals('Stopped'));
      expect(medStatusLabel(s, 'unknown'), equals('Unknown'));
      expect(medStatusLabel(s, 'draft'), equals('draft'));
    });
  });
}
