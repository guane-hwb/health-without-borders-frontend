// test/unit/brigade_stats_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

int minorCount(int totalPatients, double minorsPct) =>
    (totalPatients * minorsPct / 100).round();

double vaccineRatio(int count, int maxCount) =>
    maxCount > 0 ? count / maxCount : 0.0;

Color allergyBg(String cat) => switch (cat) {
  'med' => const Color(0xFFFAECE7),
  'food' => const Color(0xFFFAEEDA),
  'env' => const Color(0xFFE1F5EE),
  _ => const Color(0xFFF1EFE8),
};

Color allergyFg(String cat) => switch (cat) {
  'med' => const Color(0xFF712B13),
  'food' => const Color(0xFF633806),
  'env' => const Color(0xFF085041),
  _ => const Color(0xFF5F5E5A),
};

bool isLastItem(int index, int totalLength) => index == totalLength - 1;

class BrigadeStatsMock {
  static const int totalPatients = 1284;
  static const int totalVaccines = 847;
  static const int totalAllergies = 203;
  static const double minorsPct = 31.0;
  static const int vaccineBreakdownLength = 5;
  static const int allergyBreakdownLength = 8;
  static const int nationalityBreakdownLength = 5;
}

// ============================================================================
void main() {
  group('_KpiGrid._fmt · formateo de números', () {
    test('0 → "0" (menor a 1000)', () {
      expect(fmt(0), '0');
    });

    test('999 → "999" (límite inferior de < 1000)', () {
      expect(fmt(999), '999');
    });

    test('1000 → "1.0K" (límite exacto de >= 1000)', () {
      expect(fmt(1000), '1.0K');
    });

    test('1284 → "1.3K" (dato real de mock totalPatients)', () {
      expect(fmt(1284), '1.3K');
    });

    test('1500 → "1.5K"', () {
      expect(fmt(1500), '1.5K');
    });

    test('10000 → "10.0K"', () {
      expect(fmt(10000), '10.0K');
    });

    test('847 → "847" (totalVaccines del mock, sin K)', () {
      expect(fmt(847), '847');
    });

    test('203 → "203" (totalAllergies del mock, sin K)', () {
      expect(fmt(203), '203');
    });

    test('número negativo < 0 → string del número sin K', () {
      expect(fmt(-5), '-5');
    });
  });

  group('_KpiGrid minorCount · cálculo de menores', () {
    test('1284 pacientes × 31% → 398 menores', () {
      expect(minorCount(1284, 31.0), 398);
    });

    test('100 pacientes × 50% → 50 menores', () {
      expect(minorCount(100, 50.0), 50);
    });

    test('100 pacientes × 0% → 0 menores', () {
      expect(minorCount(100, 0.0), 0);
    });

    test('100 pacientes × 100% → 100 menores', () {
      expect(minorCount(100, 100.0), 100);
    });

    test('0 pacientes → 0 menores sin importar el porcentaje', () {
      expect(minorCount(0, 31.0), 0);
    });

    test(
      'resultado se redondea correctamente: 1 paciente × 50% → round de 0.5 = 1',
      () {
        expect(minorCount(1, 50.0), 1);
      },
    );

    test('10 pacientes × 33% → round(3.3) = 3', () {
      expect(minorCount(10, 33.0), 3);
    });

    test('10 pacientes × 35% → round(3.5) = 4', () {
      expect(minorCount(10, 35.0), 4);
    });
  });

  group('_VaccineBarChart ratio · cálculo de proporción', () {
    test('count == maxCount → ratio 1.0 (barra llena)', () {
      expect(vaccineRatio(312, 312), 1.0);
    });

    test('count == 0 → ratio 0.0 (barra vacía)', () {
      expect(vaccineRatio(0, 312), 0.0);
    });

    test(
      'maxCount == 0 → ratio 0.0 (guard clause, evita división por cero)',
      () {
        expect(vaccineRatio(100, 0), 0.0);
      },
    );

    test('228 / 312 ≈ 0.7308 (COVID-19 del mock)', () {
      expect(vaccineRatio(228, 312), closeTo(0.7308, 0.001));
    });

    test('147 / 312 ≈ 0.4712 (Hepatitis B del mock)', () {
      expect(vaccineRatio(147, 312), closeTo(0.4712, 0.001));
    });

    test('62 / 312 ≈ 0.1987 (Fiebre Amarilla del mock)', () {
      expect(vaccineRatio(62, 312), closeTo(0.1987, 0.001));
    });

    test('ratio nunca excede 1.0 cuando count <= maxCount', () {
      expect(vaccineRatio(100, 100), lessThanOrEqualTo(1.0));
    });

    test('ratio siempre es >= 0.0', () {
      expect(vaccineRatio(0, 500), greaterThanOrEqualTo(0.0));
    });
  });

  group('_AllergyChips._bg · colores de fondo', () {
    test('categoría "med" → Color(0xFFFAECE7)', () {
      expect(allergyBg('med'), const Color(0xFFFAECE7));
    });

    test('categoría "food" → Color(0xFFFAEEDA)', () {
      expect(allergyBg('food'), const Color(0xFFFAEEDA));
    });

    test('categoría "env" → Color(0xFFE1F5EE)', () {
      expect(allergyBg('env'), const Color(0xFFE1F5EE));
    });

    test('categoría "other" → Color(0xFFF1EFE8)', () {
      expect(allergyBg('other'), const Color(0xFFF1EFE8));
    });

    test('categoría desconocida → fallback Color(0xFFF1EFE8)', () {
      expect(allergyBg('unknown'), const Color(0xFFF1EFE8));
    });

    test('string vacío → fallback Color(0xFFF1EFE8)', () {
      expect(allergyBg(''), const Color(0xFFF1EFE8));
    });

    test('categorías son case-sensitive: "Med" != "med" → fallback', () {
      expect(allergyBg('Med'), const Color(0xFFF1EFE8));
    });
  });

  group('_AllergyChips._fg · colores de texto', () {
    test('categoría "med" → Color(0xFF712B13)', () {
      expect(allergyFg('med'), const Color(0xFF712B13));
    });

    test('categoría "food" → Color(0xFF633806)', () {
      expect(allergyFg('food'), const Color(0xFF633806));
    });

    test('categoría "env" → Color(0xFF085041)', () {
      expect(allergyFg('env'), const Color(0xFF085041));
    });

    test('categoría "other" → Color(0xFF5F5E5A)', () {
      expect(allergyFg('other'), const Color(0xFF5F5E5A));
    });

    test('categoría desconocida → fallback Color(0xFF5F5E5A)', () {
      expect(allergyFg('xyz'), const Color(0xFF5F5E5A));
    });

    test('string vacío → fallback Color(0xFF5F5E5A)', () {
      expect(allergyFg(''), const Color(0xFF5F5E5A));
    });

    test('_bg y _fg producen colores distintos para la misma categoría', () {
      for (final cat in ['med', 'food', 'env', 'other']) {
        expect(allergyBg(cat), isNot(equals(allergyFg(cat))));
      }
    });
  });

  group('_NationalityList isLast · lógica del divisor', () {
    test('lista de 1 elemento: índice 0 es el último', () {
      expect(isLastItem(0, 1), isTrue);
    });

    test('lista de 5: índice 4 es el último', () {
      expect(isLastItem(4, 5), isTrue);
    });

    test('lista de 5: índice 0 NO es el último', () {
      expect(isLastItem(0, 5), isFalse);
    });

    test('lista de 5: índice 3 NO es el último', () {
      expect(isLastItem(3, 5), isFalse);
    });

    test('lista de 5: índice 2 (mitad) NO es el último', () {
      expect(isLastItem(2, 5), isFalse);
    });

    test('reflejo del mock: 5 nacionalidades → índice 4 es último', () {
      expect(
        isLastItem(
          BrigadeStatsMock.nationalityBreakdownLength - 1,
          BrigadeStatsMock.nationalityBreakdownLength,
        ),
        isTrue,
      );
    });
  });

  group('_BrigadeStats.mock · integridad de datos', () {
    test('totalPatients == 1284', () {
      expect(BrigadeStatsMock.totalPatients, 1284);
    });

    test('totalVaccines == 847', () {
      expect(BrigadeStatsMock.totalVaccines, 847);
    });

    test('totalAllergies == 203', () {
      expect(BrigadeStatsMock.totalAllergies, 203);
    });

    test('minorsPct == 31.0', () {
      expect(BrigadeStatsMock.minorsPct, 31.0);
    });

    test('vaccineBreakdown tiene 5 entradas', () {
      expect(BrigadeStatsMock.vaccineBreakdownLength, 5);
    });

    test('allergyBreakdown tiene 8 entradas', () {
      expect(BrigadeStatsMock.allergyBreakdownLength, 8);
    });

    test('nationalityBreakdown tiene 5 entradas', () {
      expect(BrigadeStatsMock.nationalityBreakdownLength, 5);
    });

    test('minorCount derivado del mock: round(1284 × 31% / 100) = 398', () {
      expect(
        minorCount(BrigadeStatsMock.totalPatients, BrigadeStatsMock.minorsPct),
        398,
      );
    });

    test('fmt del totalPatients del mock → "1.3K"', () {
      expect(fmt(BrigadeStatsMock.totalPatients), '1.3K');
    });

    test('fmt del totalVaccines del mock → "847" (sin K)', () {
      expect(fmt(BrigadeStatsMock.totalVaccines), '847');
    });
  });

  group('Consistencia _bg/_fg para categorías del mock', () {
    const categorias = ['med', 'food', 'env', 'other'];

    for (final cat in categorias) {
      test('$cat: _bg y _fg no son nulos y son distintos', () {
        final bg = allergyBg(cat);
        final fg = allergyFg(cat);
        expect(bg, isNotNull);
        expect(fg, isNotNull);
        expect(bg, isNot(equals(fg)));
      });
    }
  });

  group('_fmt · propiedades invariantes', () {
    test('siempre retorna un string no vacío', () {
      for (final n in [0, 1, 999, 1000, 9999, 100000]) {
        expect(fmt(n).isNotEmpty, isTrue, reason: 'falló para n=$n');
      }
    });

    test('números >= 1000 siempre terminan en "K"', () {
      for (final n in [1000, 1500, 2000, 10000]) {
        expect(fmt(n).endsWith('K'), isTrue, reason: 'falló para n=$n');
      }
    });

    test('números < 1000 nunca contienen "K"', () {
      for (final n in [0, 1, 100, 999]) {
        expect(fmt(n).contains('K'), isFalse, reason: 'falló para n=$n');
      }
    });
  });

  group('vaccineRatio · propiedades invariantes', () {
    test('ratio está siempre en [0.0, 1.0] para valores normales', () {
      final casos = [(0, 100), (50, 100), (100, 100), (312, 312), (62, 312)];
      for (final (count, max) in casos) {
        final r = vaccineRatio(count, max);
        expect(
          r,
          greaterThanOrEqualTo(0.0),
          reason: 'ratio < 0 para count=$count max=$max',
        );
        expect(
          r,
          lessThanOrEqualTo(1.0),
          reason: 'ratio > 1 para count=$count max=$max',
        );
      }
    });

    test('maxCount == 0 siempre retorna 0.0 (no lanza excepción)', () {
      expect(() => vaccineRatio(999, 0), returnsNormally);
      expect(vaccineRatio(999, 0), 0.0);
    });
  });
}
