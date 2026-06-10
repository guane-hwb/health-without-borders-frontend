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

String sexLabel(String biologicalSex) {
  switch (biologicalSex) {
    case 'M':
      return 'Masculino';
    case 'F':
      return 'Femenino';
    default:
      return 'Indeterminado';
  }
}

String docTypeLabel(String documentType) {
  switch (documentType) {
    case 'RC':
      return 'Registro Civil';
    case 'TI':
      return 'Tarjeta de Identidad';
    case 'CC':
      return 'Cédula de Ciudadanía';
    case 'CE':
      return 'Cédula de Extranjería';
    case 'PA':
      return 'Pasaporte';
    case 'PE':
      return 'Permiso Especial';
    case 'PT':
      return 'Permiso Temporal';
    case 'MS':
      return 'Menor sin Identificación';
    case 'AS':
      return 'Adulto sin Identificación';
    default:
      return documentType;
  }
}

bool resolveHasInternet(List<String> results) {
  return !results.contains('none');
}

// ─────────────────────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── computeAge ─────────────────────────────────────────────────────────────
  group('computeAge', () {
    test('edad exacta en el día del cumpleaños', () {
      expect(computeAge('1990-06-15', DateTime(2025, 6, 15)), 35);
    });

    test('resta 1 cuando el cumpleaños aún no ha llegado (mes anterior)', () {
      expect(computeAge('1990-06-15', DateTime(2025, 3, 10)), 34);
    });

    test('resta 1 cuando mismo mes pero día anterior al cumpleaños', () {
      expect(computeAge('1990-06-15', DateTime(2025, 6, 14)), 34);
    });

    test('no resta 1 cuando el cumpleaños ya pasó', () {
      expect(computeAge('1990-06-15', DateTime(2025, 6, 16)), 35);
    });

    test('devuelve null para formato sin guiones', () {
      expect(computeAge('19900615', DateTime(2025, 1, 1)), isNull);
    });

    test('devuelve null para cadena vacía', () {
      expect(computeAge('', DateTime(2025, 1, 1)), isNull);
    });

    test('devuelve null para partes no numéricas', () {
      expect(computeAge('YYYY-MM-DD', DateTime(2025, 1, 1)), isNull);
    });

    test('edad 0 para recién nacido (día anterior)', () {
      expect(computeAge('2024-12-31', DateTime(2025, 1, 1)), 0);
    });

    test('edad 0 para nacido el mismo día', () {
      expect(computeAge('2025-06-15', DateTime(2025, 6, 15)), 0);
    });

    test('devuelve null si sólo hay dos partes separadas por guión', () {
      expect(computeAge('1990-06', DateTime(2025, 1, 1)), isNull);
    });
  });

  // ── computeInitials ────────────────────────────────────────────────────────
  group('computeInitials', () {
    test('dos palabras → dos primeras letras en mayúscula', () {
      expect(computeInitials('Juan Pérez'), 'JP');
    });

    test('una sola palabra → primera letra en mayúscula', () {
      expect(computeInitials('Carlos'), 'C');
    });

    test('tres palabras → usa sólo las dos primeras', () {
      expect(computeInitials('María Fernanda López'), 'MF');
    });

    test('espacios extra al inicio y al final se recortan', () {
      expect(computeInitials('  Ana Torres  '), 'AT');
    });

    test('nombre en minúsculas se convierte a mayúsculas', () {
      expect(computeInitials('luisa martínez'), 'LM');
    });

    test('nombre vacío → ?', () {
      expect(computeInitials(''), '?');
    });

    test('sólo espacios → ?', () {
      expect(computeInitials('   '), '?');
    });
  });

  // ── relLabel ──────────────────────────────────────────────────────────────
  group('relLabel', () {
    test('01 → Padres', () => expect(relLabel('01'), 'Padres'));
    test('02 → Hermanos', () => expect(relLabel('02'), 'Hermanos'));
    test('03 → Tíos', () => expect(relLabel('03'), 'Tíos'));
    test('04 → Abuelos', () => expect(relLabel('04'), 'Abuelos'));
    test('código desconocido → mismo valor', () {
      expect(relLabel('99'), '99');
    });
    test('cadena vacía → cadena vacía', () {
      expect(relLabel(''), '');
    });
  });

  // ── medStatusLabel ────────────────────────────────────────────────────────
  group('medStatusLabel', () {
    test('active → Activo', () => expect(medStatusLabel('active'), 'Activo'));
    test(
      'completed → Completado',
      () => expect(medStatusLabel('completed'), 'Completado'),
    );
    test(
      'stopped → Suspendido',
      () => expect(medStatusLabel('stopped'), 'Suspendido'),
    );
    test(
      'unknown → Desconocido',
      () => expect(medStatusLabel('unknown'), 'Desconocido'),
    );
    test('estado arbitrario → mismo valor', () {
      expect(medStatusLabel('on-hold'), 'on-hold');
    });
    test('cadena vacía → cadena vacía', () {
      expect(medStatusLabel(''), '');
    });
  });

  // ── hasUnsyncedChanges ────────────────────────────────────────────────────
  group('hasUnsyncedChanges', () {
    final base = <String, dynamic>{'id': '1', 'name': 'Juan'};

    test('false cuando draft y original son idénticos', () {
      expect(
        hasUnsyncedChanges(
          Map<String, dynamic>.from(base),
          Map<String, dynamic>.from(base),
        ),
        false,
      );
    });

    test('true cuando un campo del draft difiere', () {
      final draft = Map<String, dynamic>.from(base)..['name'] = 'Pedro';
      expect(hasUnsyncedChanges(draft, Map<String, dynamic>.from(base)), true);
    });

    test('true cuando el draft tiene un campo extra', () {
      final draft = Map<String, dynamic>.from(base)..['extra'] = 'valor';
      expect(hasUnsyncedChanges(draft, Map<String, dynamic>.from(base)), true);
    });

    test('false con dos mapas vacíos', () {
      expect(hasUnsyncedChanges({}, {}), false);
    });

    test('true cuando original tiene un campo que draft no tiene', () {
      final original = Map<String, dynamic>.from(base)..['extra'] = 'valor';
      expect(
        hasUnsyncedChanges(Map<String, dynamic>.from(base), original),
        true,
      );
    });
  });

  // ── avatarColorIndex ──────────────────────────────────────────────────────
  group('avatarColorIndex', () {
    test('siempre devuelve índice entre 0 y 7 (inclusive)', () {
      const inputs = ['AB', 'ZZ', 'MF', 'JP', 'CC', 'LM', 'AT', '??', 'A', ''];
      for (final input in inputs) {
        final idx = avatarColorIndex(input);
        expect(
          idx,
          greaterThanOrEqualTo(0),
          reason: 'falla con input "$input"',
        );
        expect(idx, lessThan(8), reason: 'falla con input "$input"');
      }
    });

    test('determinista: mismas iniciales → mismo índice', () {
      expect(avatarColorIndex('MF'), avatarColorIndex('MF'));
    });

    test('cadena vacía no lanza excepción', () {
      expect(() => avatarColorIndex(''), returnsNormally);
    });

    test('índices para iniciales distintas están en rango válido', () {
      expect(avatarColorIndex('AB'), inInclusiveRange(0, 7));
      expect(avatarColorIndex('ZZ'), inInclusiveRange(0, 7));
    });
  });

  // ── sexLabel ──────────────────────────────────────────────────────────────
  group('sexLabel', () {
    test('M → Masculino', () => expect(sexLabel('M'), 'Masculino'));
    test('F → Femenino', () => expect(sexLabel('F'), 'Femenino'));
    test('valor desconocido → Indeterminado', () {
      expect(sexLabel('X'), 'Indeterminado');
    });
    test('cadena vacía → Indeterminado', () {
      expect(sexLabel(''), 'Indeterminado');
    });
  });

  // ── docTypeLabel ──────────────────────────────────────────────────────────
  group('docTypeLabel', () {
    test('RC → Registro Civil', () {
      expect(docTypeLabel('RC'), 'Registro Civil');
    });
    test('TI → Tarjeta de Identidad', () {
      expect(docTypeLabel('TI'), 'Tarjeta de Identidad');
    });
    test('CC → Cédula de Ciudadanía', () {
      expect(docTypeLabel('CC'), 'Cédula de Ciudadanía');
    });
    test('CE → Cédula de Extranjería', () {
      expect(docTypeLabel('CE'), 'Cédula de Extranjería');
    });
    test('PA → Pasaporte', () => expect(docTypeLabel('PA'), 'Pasaporte'));
    test('PE → Permiso Especial', () {
      expect(docTypeLabel('PE'), 'Permiso Especial');
    });
    test('PT → Permiso Temporal', () {
      expect(docTypeLabel('PT'), 'Permiso Temporal');
    });
    test('MS → Menor sin Identificación', () {
      expect(docTypeLabel('MS'), 'Menor sin Identificación');
    });
    test('AS → Adulto sin Identificación', () {
      expect(docTypeLabel('AS'), 'Adulto sin Identificación');
    });
    test('código desconocido → mismo valor', () {
      expect(docTypeLabel('XX'), 'XX');
    });
    test('cadena vacía → cadena vacía', () {
      expect(docTypeLabel(''), '');
    });
  });

  // ── resolveHasInternet ────────────────────────────────────────────────────
  group('resolveHasInternet (lógica de _updateConnectivityStatus)', () {
    test('true cuando hay wifi', () {
      expect(resolveHasInternet(['wifi']), true);
    });

    test('true cuando hay mobile', () {
      expect(resolveHasInternet(['mobile']), true);
    });

    test('false cuando contiene none', () {
      expect(resolveHasInternet(['none']), false);
    });

    test('false cuando hay varios resultados y uno es none', () {
      expect(resolveHasInternet(['wifi', 'none']), false);
    });

    test(
      'lista vacía se interpreta como con internet (sin none explícito)',
      () {
        expect(resolveHasInternet([]), true);
      },
    );

    test('múltiples tipos sin none → true', () {
      expect(resolveHasInternet(['wifi', 'ethernet']), true);
    });
  });
}
