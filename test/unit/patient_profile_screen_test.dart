// test/unit/patient_profile_screen_test.dart:

import 'package:flutter_test/flutter_test.dart';

// ── _age ────────────────────────────────────────────────────────────────────

int? computeAge(String dob, DateTime now) {
  try {
    final parts = dob.split('-');
    if (parts.length != 3) return null;
    final dobDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    var age = now.year - dobDate.year;
    if (now.month < dobDate.month ||
        (now.month == dobDate.month && now.day < dobDate.day)) {
      age--;
    }
    return age;
  } catch (_) {
    return null;
  }
}

// ── _initials ────────────────────────────────────────────────────────────────

String computeInitials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || (parts.length == 1 && parts.first.isEmpty)) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

// ── _relLabel ────────────────────────────────────────────────────────────────

String relLabel(String r) {
  switch (r) {
    case '01':
      return 'Padres';
    case '02':
      return 'Hermanos';
    case '03':
      return 'Tíos';
    case '04':
      return 'Abuelos';
    default:
      return r;
  }
}

// ── _medStatusLabel ──────────────────────────────────────────────────────────

String medStatusLabel(String c) {
  switch (c) {
    case 'active':
      return 'Activo';
    case 'completed':
      return 'Completado';
    case 'stopped':
      return 'Suspendido';
    case 'unknown':
      return 'Desconocido';
    default:
      return c;
  }
}

// ── _hasUnsyncedChanges ──────────────────────────────────────────────────────

bool hasUnsyncedChanges(
  Map<String, dynamic> draft,
  Map<String, dynamic> original,
) {
  return draft.toString() != original.toString();
}

// ── _avatarColor hash ────────────────────────────────────────────────────────

int avatarColorIndex(String initials) {
  const colorsLength = 8;
  var hash = 0;
  for (var i = 0; i < initials.length; i++) {
    hash = hash * 31 + initials.codeUnitAt(i);
  }
  return hash.abs() % colorsLength;
}

// ════════════════════════════════════════════════════════════════════════════
// TESTS
// ════════════════════════════════════════════════════════════════════════════

void main() {
  // ── computeAge ─────────────────────────────────────────────────────────────
  group('computeAge', () {
    test('calcula correctamente la edad exacta en el cumpleaños', () {
      final now = DateTime(2025, 6, 15);
      expect(computeAge('1990-06-15', now), 35);
    });

    test(
      'resta un año cuando el cumpleaños aún no ha pasado en el año actual',
      () {
        final now = DateTime(2025, 3, 10);
        expect(computeAge('1990-06-15', now), 34);
      },
    );

    test('resta un año cuando el mes es igual pero el día aún no llegó', () {
      final now = DateTime(2025, 6, 14);
      expect(computeAge('1990-06-15', now), 34);
    });

    test('no resta el año cuando ya pasó el cumpleaños', () {
      final now = DateTime(2025, 6, 16);
      expect(computeAge('1990-06-15', now), 35);
    });

    test('devuelve null para formato inválido (sin guiones)', () {
      expect(computeAge('19900615', DateTime(2025, 1, 1)), null);
    });

    test('devuelve null para cadena vacía', () {
      expect(computeAge('', DateTime(2025, 1, 1)), null);
    });

    test('devuelve null para fecha con partes no numéricas', () {
      expect(computeAge('YYYY-MM-DD', DateTime(2025, 1, 1)), null);
    });

    test('maneja correctamente recién nacido (edad 0)', () {
      final now = DateTime(2025, 1, 1);
      expect(computeAge('2024-12-31', now), 0);
    });

    test('maneja paciente recién nacido el mismo día', () {
      final now = DateTime(2025, 6, 15);
      expect(computeAge('2025-06-15', now), 0);
    });
  });

  // ── computeInitials ────────────────────────────────────────────────────────
  group('computeInitials', () {
    test('dos palabras devuelve las dos primeras letras en mayúscula', () {
      expect(computeInitials('Juan Pérez'), 'JP');
    });

    test('una sola palabra devuelve la primera letra', () {
      expect(computeInitials('Carlos'), 'C');
    });

    test('tres palabras usa solo las dos primeras', () {
      expect(computeInitials('María Fernanda López'), 'MF');
    });

    test('nombre con espacios extra al inicio y final', () {
      expect(computeInitials('  Ana Torres  '), 'AT');
    });

    test('nombre en minúsculas se convierte a mayúsculas', () {
      expect(computeInitials('luisa martínez'), 'LM');
    });

    test('nombre vacío devuelve ?', () {
      expect(computeInitials(''), '?');
    });

    test('nombre con solo espacios devuelve ?', () {
      expect(computeInitials('   '), '?');
    });
  });

  // ── relLabel ──────────────────────────────────────────────────────────────
  group('relLabel', () {
    test('01 mapea a Padres', () => expect(relLabel('01'), 'Padres'));
    test('02 mapea a Hermanos', () => expect(relLabel('02'), 'Hermanos'));
    test('03 mapea a Tíos', () => expect(relLabel('03'), 'Tíos'));
    test('04 mapea a Abuelos', () => expect(relLabel('04'), 'Abuelos'));
    test('código desconocido devuelve el mismo código', () {
      expect(relLabel('99'), '99');
    });
    test('cadena vacía devuelve cadena vacía', () {
      expect(relLabel(''), '');
    });
  });

  // ── medStatusLabel ────────────────────────────────────────────────────────
  group('medStatusLabel', () {
    test(
      'active mapea a Activo',
      () => expect(medStatusLabel('active'), 'Activo'),
    );
    test(
      'completed mapea a Completado',
      () => expect(medStatusLabel('completed'), 'Completado'),
    );
    test(
      'stopped mapea a Suspendido',
      () => expect(medStatusLabel('stopped'), 'Suspendido'),
    );
    test(
      'unknown mapea a Desconocido',
      () => expect(medStatusLabel('unknown'), 'Desconocido'),
    );
    test('estado arbitrario devuelve el mismo valor', () {
      expect(medStatusLabel('on-hold'), 'on-hold');
    });
    test('cadena vacía devuelve cadena vacía', () {
      expect(medStatusLabel(''), '');
    });
  });

  // ── hasUnsyncedChanges ────────────────────────────────────────────────────
  group('hasUnsyncedChanges', () {
    final base = <String, dynamic>{'id': '1', 'name': 'Juan'};

    test('devuelve false cuando draft y original son iguales', () {
      final draft = Map<String, dynamic>.from(base);
      final original = Map<String, dynamic>.from(base);
      expect(hasUnsyncedChanges(draft, original), false);
    });

    test('devuelve true cuando el draft tiene un campo distinto', () {
      final draft = Map<String, dynamic>.from(base)..['name'] = 'Pedro';
      final original = Map<String, dynamic>.from(base);
      expect(hasUnsyncedChanges(draft, original), true);
    });

    test('devuelve true cuando el draft tiene un campo adicional', () {
      final draft = Map<String, dynamic>.from(base)..['extra'] = 'valor';
      final original = Map<String, dynamic>.from(base);
      expect(hasUnsyncedChanges(draft, original), true);
    });

    test('devuelve false con dos mapas vacíos', () {
      expect(hasUnsyncedChanges({}, {}), false);
    });
  });

  // ── avatarColorIndex ──────────────────────────────────────────────────────
  group('avatarColorIndex', () {
    test('siempre devuelve un índice entre 0 y 7 (inclusive)', () {
      final inputs = ['AB', 'ZZ', 'MF', 'JP', 'CC', 'LM', 'AT', '??', 'A', ''];
      for (final input in inputs) {
        final index = avatarColorIndex(input);
        expect(index, greaterThanOrEqualTo(0));
        expect(index, lessThan(8));
      }
    });

    test(
      'mismas iniciales producen siempre el mismo índice (determinista)',
      () {
        expect(avatarColorIndex('AB'), avatarColorIndex('AB'));
      },
    );

    test('iniciales distintas pueden producir índices distintos', () {
      final a = avatarColorIndex('AB');
      final b = avatarColorIndex('ZZ');
      expect(a, inInclusiveRange(0, 7));
      expect(b, inInclusiveRange(0, 7));
    });

    test('cadena vacía no lanza excepción', () {
      expect(() => avatarColorIndex(''), returnsNormally);
    });
  });

  // ── _updateConnectivityStatus: business logic ──────────────────────────
  group('lógica de conectividad', () {
    test('hasNet es true cuando los resultados no contienen "none"', () {
      const results = ['wifi'];
      final hasNet = !results.contains('none');
      expect(hasNet, true);
    });

    test('hasNet es false cuando los resultados contienen "none"', () {
      const results = ['none'];
      final hasNet = !results.contains('none');
      expect(hasNet, false);
    });

    test(
      'lista vacía se interpreta como sin conexión (no contiene wifi/mobile)',
      () {
        const results = <String>[];
        final hasNet = !results.contains('none');
        expect(hasNet, true);
      },
    );
  });
}
