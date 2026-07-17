// test/unit/brigade_stats_screen_test.dart
//
// Unit tests for the brigade statistics domain models and the country catalog.
//
// The previous version of this file re-implemented the screen's formatting
// helpers locally and asserted against hard-coded mock constants. Those copies
// could — and did — drift from the widgets they claimed to cover. The models
// are public now, so these tests exercise the real code.

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/admin/domain/brigade_stats.dart';
import 'package:health_without_borders_frontend/src/shared/country_display.dart';

// ============================================================================
// FIXTURES
// ============================================================================

Map<String, dynamic> _payload({
  Object? deltaPct = 11.8,
  String period = 'month',
  int patients = 1284,
  List<Map<String, dynamic>>? vaccines,
  List<Map<String, dynamic>>? allergies,
  List<Map<String, dynamic>>? nationalities,
}) => <String, dynamic>{
  'scope': {'organization_id': null, 'organization_name': null},
  'generated_at': '2026-07-09T14:22:01-05:00',
  'window': {'date_from': null, 'date_to': null},
  'totals': {
    'patients': patients,
    'patients_with_birth_date': 1240,
    'minors': 384,
    'minors_pct': 30.97,
    'vaccine_doses': 847,
    'allergies': 203,
    'encounters': 512,
  },
  'trend': {
    'period': period,
    'patients': {'current': 142, 'previous': 127, 'delta_pct': deltaPct},
    'vaccine_doses': {'current': 98, 'previous': 0, 'delta_pct': null},
    'encounters': {'current': 61, 'previous': 55, 'delta_pct': 10.9},
  },
  'vaccines':
      vaccines ??
      [
        {'code': '141', 'name': 'Influenza Trivalente', 'count': 312},
        {'code': '208', 'name': 'COVID-19 (ARNm)', 'count': 228},
      ],
  'allergies':
      allergies ??
      [
        {'allergen': 'Ibuprofeno', 'category': '01', 'count': 41},
        {'allergen': 'Mariscos', 'category': '02', 'count': 29},
        {'allergen': 'Polen', 'category': '03', 'count': 18},
      ],
  'allergies_others': 7,
  'nationalities':
      nationalities ??
      [
        {'code': 'COL', 'count': 542},
        {'code': 'VEN', 'count': 489},
      ],
  'nationalities_others': 12,
};

// ============================================================================
// BrigadeStats.fromJson
// ============================================================================

void main() {
  group('BrigadeStats.fromJson', () {
    test('parses the full payload', () {
      final stats = BrigadeStats.fromJson(_payload());

      expect(stats.totals.patients, 1284);
      expect(stats.totals.patientsWithBirthDate, 1240);
      expect(stats.totals.minors, 384);
      expect(stats.totals.minorsPct, closeTo(30.97, 0.001));
      expect(stats.totals.vaccineDoses, 847);
      expect(stats.totals.encounters, 512);
      expect(stats.trend.period, 'month');
      expect(stats.trend.isMonthly, isTrue);
      expect(stats.vaccines, hasLength(2));
      expect(stats.allergiesOthers, 7);
      expect(stats.nationalitiesOthers, 12);
      expect(stats.generatedAt, isNotNull);
    });

    test('a null delta_pct stays null and is not coerced to zero', () {
      final stats = BrigadeStats.fromJson(_payload(deltaPct: null));

      expect(stats.trend.patients.deltaPct, isNull);
      expect(stats.trend.patients.hasNoBaseline, isTrue);
      // The vaccine metric has previous = 0 in the fixture.
      expect(stats.trend.vaccineDoses.deltaPct, isNull);
      // A real delta is preserved.
      expect(stats.trend.encounters.deltaPct, closeTo(10.9, 0.001));
      expect(stats.trend.encounters.hasNoBaseline, isFalse);
    });

    test('a negative delta survives parsing', () {
      final json = _payload(deltaPct: -50.0);
      expect(
        BrigadeStats.fromJson(json).trend.patients.deltaPct,
        closeTo(-50.0, 0.001),
      );
    });

    test('period "custom" is reported as non-monthly', () {
      final stats = BrigadeStats.fromJson(_payload(period: 'custom'));
      expect(stats.trend.isMonthly, isFalse);
    });

    test('integers arriving as doubles are truncated, not dropped', () {
      final json = _payload();
      (json['totals'] as Map<String, dynamic>)['patients'] = 1284.0;
      expect(BrigadeStats.fromJson(json).totals.patients, 1284);
    });

    test('a missing or malformed payload degrades to zeros, not a crash', () {
      final stats = BrigadeStats.fromJson(<String, dynamic>{});

      expect(stats.totals.patients, 0);
      expect(stats.totals.minorsPct, 0.0);
      expect(stats.vaccines, isEmpty);
      expect(stats.allergies, isEmpty);
      expect(stats.nationalities, isEmpty);
      expect(stats.trend.period, 'month');
      expect(stats.trend.patients.deltaPct, isNull);
      expect(stats.generatedAt, isNull);
      expect(stats.isEmpty, isTrue);
    });

    test('non-list breakdowns are ignored rather than throwing', () {
      final json = _payload();
      json['vaccines'] = 'not-a-list';
      json['nationalities'] = <Object>[42, 'nope'];

      final stats = BrigadeStats.fromJson(json);
      expect(stats.vaccines, isEmpty);
      expect(stats.nationalities, isEmpty);
    });
  });

  // ==========================================================================
  // Derived values
  // ==========================================================================

  group('BrigadeStats derived values', () {
    test('isEmpty is true only when every headline count is zero', () {
      final json = _payload(patients: 0);
      final totals = json['totals'] as Map<String, dynamic>;
      totals['patients'] = 0;
      totals['vaccine_doses'] = 0;
      totals['encounters'] = 0;
      totals['allergies'] = 0;

      expect(BrigadeStats.fromJson(json).isEmpty, isTrue);

      totals['encounters'] = 1;
      expect(BrigadeStats.fromJson(json).isEmpty, isFalse);
    });

    test('maxVaccineCount does not assume the backend sorted the list', () {
      final stats = BrigadeStats.fromJson(
        _payload(
          vaccines: [
            {'code': 'A', 'name': 'A', 'count': 5},
            {'code': 'B', 'name': 'B', 'count': 90},
            {'code': 'C', 'name': 'C', 'count': 12},
          ],
        ),
      );
      expect(stats.maxVaccineCount, 90);
    });

    test(
      'maxVaccineCount is zero for an empty list, so bars never divide by 0',
      () {
        final stats = BrigadeStats.fromJson(
          _payload(vaccines: <Map<String, dynamic>>[]),
        );
        expect(stats.maxVaccineCount, 0);
      },
    );

    test('allergyCategoryCount counts distinct categories, not entries', () {
      final stats = BrigadeStats.fromJson(
        _payload(
          allergies: [
            {'allergen': 'Ibuprofeno', 'category': '01', 'count': 41},
            {'allergen': 'Penicilina', 'category': '01', 'count': 38},
            {'allergen': 'Mariscos', 'category': '02', 'count': 29},
          ],
        ),
      );
      expect(stats.allergies, hasLength(3));
      expect(stats.allergyCategoryCount, 2);
    });
  });

  // ==========================================================================
  // Sentinels
  // ==========================================================================

  group('backend sentinels', () {
    test('a vaccine with no CVX code is flagged as uncoded', () {
      final stats = BrigadeStats.fromJson(
        _payload(
          vaccines: [
            {'code': 'UNCODED', 'name': '', 'count': 4},
            {'code': '141', 'name': 'Influenza', 'count': 9},
          ],
        ),
      );
      expect(stats.vaccines.first.isUncoded, isTrue);
      expect(stats.vaccines.last.isUncoded, isFalse);
    });

    test('a patient with no nationality is flagged as unknown', () {
      final stats = BrigadeStats.fromJson(
        _payload(
          nationalities: [
            {'code': 'UNK', 'count': 3},
            {'code': 'COL', 'count': 7},
          ],
        ),
      );
      expect(stats.nationalities.first.isUnknown, isTrue);
      expect(stats.nationalities.last.isUnknown, isFalse);
    });

    test('an allergy with no category defaults to "otra"', () {
      final stat = AllergyStat.fromJson(<String, dynamic>{
        'allergen': 'Látex',
        'count': 2,
      });
      expect(stat.category, '06');
    });
  });

  // ==========================================================================
  // Country catalog
  // ==========================================================================

  group('countryDisplay', () {
    test('resolves the nationalities the registration form offers', () {
      for (final code in ['COL', 'VEN', 'ECU', 'PER', 'HTI', 'CUB']) {
        expect(isKnownCountry(code), isTrue, reason: code);
        expect(countryDisplay(code).flag, isNot('🌍'), reason: code);
      }
    });

    test('is case and whitespace insensitive', () {
      expect(countryDisplay(' col ').nameEs, 'Colombia');
      expect(countryDisplay('ven').nameEn, 'Venezuela');
    });

    test('localizes the name', () {
      expect(countryDisplay('PER').name(isEs: true), 'Perú');
      expect(countryDisplay('PER').name(isEs: false), 'Peru');
    });

    test('"UNK" reads as not recorded, which is not the same as "other"', () {
      final unknown = countryDisplay('UNK');
      expect(unknown.nameEs, 'Sin registrar');
      expect(unknown.nameEn, 'Not recorded');
      expect(unknown.nameEs, isNot(othersDisplay.nameEs));
    });

    test('an empty code reads as not recorded', () {
      expect(countryDisplay('').nameEs, 'Sin registrar');
    });

    test(
      'an unrecognised code falls back to the globe rather than vanishing',
      () {
        expect(isKnownCountry('ZZZ'), isFalse);
        expect(countryDisplay('ZZZ').flag, '🌍');
        expect(countryDisplay('ZZZ').nameEs, 'Otros');
      },
    );

    test('the others bucket is the globe', () {
      expect(othersDisplay.flag, '🌍');
      expect(othersDisplay.name(isEs: true), 'Otros');
      expect(othersDisplay.name(isEs: false), 'Other');
    });
  });
}
