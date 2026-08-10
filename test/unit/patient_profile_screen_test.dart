// test/unit/patient_profile_screen_test.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/patient_profile_helpers.dart';

// ── _age ────────────────────────────────────────────────────────────────────
int? computeAge(String dob, DateTime now) {
  final parts = dob.split('-');
  if (parts.length != 3 || dob.length != 10) return null;

  final dobDateTime = tryParsePatientDate(dob);
  if (dobDateTime == null) return null;

  var age = now.year - dobDateTime.year;
  if (now.month < dobDateTime.month ||
      (now.month == dobDateTime.month && now.day < dobDateTime.day)) {
    age--;
  }
  return age >= 0 ? age : null;
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

void main() {
  group('computeAge (10 tests)', () {
    test('1. edad exacta en el día del cumpleaños', () {
      expect(computeAge('1990-06-15', DateTime(2025, 6, 15)), 35);
    });

    test(
      '2. resta 1 cuando el cumpleaños aún no ha llegado (mes anterior)',
      () {
        expect(computeAge('1990-06-15', DateTime(2025, 3, 10)), 34);
      },
    );

    test('3. resta 1 cuando mismo mes pero día anterior al cumpleaños', () {
      expect(computeAge('1990-06-15', DateTime(2025, 6, 14)), 34);
    });

    test('4. no resta 1 cuando el cumpleaños ya pasó', () {
      expect(computeAge('1990-06-15', DateTime(2025, 6, 16)), 35);
    });

    test('5. devuelve null para formato sin guiones', () {
      expect(computeAge('19900615', DateTime(2025, 1, 1)), isNull);
    });

    test('6. devuelve null para cadena vacía', () {
      expect(computeAge('', DateTime(2025, 1, 1)), isNull);
    });

    test('7. devuelve null para partes no numéricas', () {
      expect(computeAge('YYYY-MM-DD', DateTime(2025, 1, 1)), isNull);
    });

    test('8. edad 0 para recién nacido (día anterior)', () {
      expect(computeAge('2024-12-31', DateTime(2025, 1, 1)), 0);
    });

    test('9. edad 0 para nacido el mismo día', () {
      expect(computeAge('2025-06-15', DateTime(2025, 6, 15)), 0);
    });

    test('10. devuelve null si sólo hay dos partes separadas por guión', () {
      expect(computeAge('1990-06', DateTime(2025, 1, 1)), isNull);
    });
  });

  group('computeInitials (7 tests)', () {
    test('11. dos palabras → dos primeras letras en mayúscula', () {
      expect(computeInitials('Juan Pérez'), 'JP');
    });

    test('12. una sola palabra → primera letra en mayúscula', () {
      expect(computeInitials('Carlos'), 'C');
    });

    test('13. tres palabras → usa sólo las dos primeras', () {
      expect(computeInitials('María Fernanda López'), 'MF');
    });

    test('14. espacios extra al inicio y al final se recortan', () {
      expect(computeInitials('  Ana Torres  '), 'AT');
    });

    test('15. nombre en minúsculas se convierte a mayúsculas', () {
      expect(computeInitials('luisa martínez'), 'LM');
    });

    test('16. nombre vacío → ?', () {
      expect(computeInitials(''), '?');
    });

    test('17. sólo espacios → ?', () {
      expect(computeInitials('   '), '?');
    });
  });

  group('relLabel (6 tests)', () {
    test('18. 01 → Padres', () => expect(relLabel('01'), 'Padres'));
    test('19. 02 → Hermanos', () => expect(relLabel('02'), 'Hermanos'));
    test('20. 03 → Tíos', () => expect(relLabel('03'), 'Tíos'));
    test('21. 04 → Abuelos', () => expect(relLabel('04'), 'Abuelos'));
    test('22. código desconocido → mismo valor', () {
      expect(relLabel('99'), '99');
    });
    test('23. cadena vacía → cadena vacía', () {
      expect(relLabel(''), '');
    });
  });

  group('medStatusLabel (6 tests)', () {
    test(
      '24. active → Activo',
      () => expect(medStatusLabel('active'), 'Activo'),
    );
    test(
      '25. completed → Completado',
      () => expect(medStatusLabel('completed'), 'Completado'),
    );
    test(
      '26. stopped → Suspendido',
      () => expect(medStatusLabel('stopped'), 'Suspendido'),
    );
    test(
      '27. unknown → Desconocido',
      () => expect(medStatusLabel('unknown'), 'Desconocido'),
    );
    test('28. estado arbitrario → mismo valor', () {
      expect(medStatusLabel('on-hold'), 'on-hold');
    });
    test('29. cadena vacía → cadena vacía', () {
      expect(medStatusLabel(''), '');
    });
  });

  group('hasUnsyncedChanges (5 tests)', () {
    final base = <String, dynamic>{'id': '1', 'name': 'Juan'};

    test('30. false cuando draft y original son idénticos', () {
      expect(
        hasUnsyncedChanges(
          Map<String, dynamic>.from(base),
          Map<String, dynamic>.from(base),
        ),
        false,
      );
    });

    test('31. true cuando un campo del draft difiere', () {
      final draft = Map<String, dynamic>.from(base)..['name'] = 'Pedro';
      expect(hasUnsyncedChanges(draft, Map<String, dynamic>.from(base)), true);
    });

    test('32. true cuando el draft tiene un campo extra', () {
      final draft = Map<String, dynamic>.from(base)..['extra'] = 'valor';
      expect(hasUnsyncedChanges(draft, Map<String, dynamic>.from(base)), true);
    });

    test('33. false con dos mapas vacíos', () {
      expect(hasUnsyncedChanges({}, {}), false);
    });

    test('34. true cuando original tiene un campo que draft no tiene', () {
      final original = Map<String, dynamic>.from(base)..['extra'] = 'valor';
      expect(
        hasUnsyncedChanges(Map<String, dynamic>.from(base), original),
        true,
      );
    });
  });

  group('avatarColorIndex (4 tests)', () {
    test('35. siempre devuelve índice entre 0 y 7', () {
      for (final input in [
        'AB',
        'ZZ',
        'MF',
        'JP',
        'CC',
        'LM',
        'AT',
        '??',
        'A',
        '',
      ]) {
        final idx = avatarColorIndex(input);
        expect(idx, greaterThanOrEqualTo(0));
        expect(idx, lessThan(8));
      }
    });

    test('36. determinista: mismas iniciales → mismo índice', () {
      expect(avatarColorIndex('MF'), avatarColorIndex('MF'));
    });

    test('37. cadena vacía no lanza excepción', () {
      expect(() => avatarColorIndex(''), returnsNormally);
    });

    test('38. índices para iniciales distintas están en rango válido', () {
      expect(avatarColorIndex('AB'), inInclusiveRange(0, 7));
      expect(avatarColorIndex('ZZ'), inInclusiveRange(0, 7));
    });
  });

  group('sexLabel (4 tests)', () {
    test('39. M → Masculino', () => expect(sexLabel('M'), 'Masculino'));
    test('40. F → Femenino', () => expect(sexLabel('F'), 'Femenino'));
    test('41. valor desconocido → Indeterminado', () {
      expect(sexLabel('X'), 'Indeterminado');
    });
    test('42. cadena vacía → Indeterminado', () {
      expect(sexLabel(''), 'Indeterminado');
    });
  });

  group('docTypeLabel (11 tests)', () {
    test(
      '43. RC → Registro Civil',
      () => expect(docTypeLabel('RC'), 'Registro Civil'),
    );
    test(
      '44. TI → Tarjeta de Identidad',
      () => expect(docTypeLabel('TI'), 'Tarjeta de Identidad'),
    );
    test(
      '45. CC → Cédula de Ciudadanía',
      () => expect(docTypeLabel('CC'), 'Cédula de Ciudadanía'),
    );
    test(
      '46. CE → Cédula de Extranjería',
      () => expect(docTypeLabel('CE'), 'Cédula de Extranjería'),
    );
    test('47. PA → Pasaporte', () => expect(docTypeLabel('PA'), 'Pasaporte'));
    test(
      '48. PE → Permiso Especial',
      () => expect(docTypeLabel('PE'), 'Permiso Especial'),
    );
    test(
      '49. PT → Permiso Temporal',
      () => expect(docTypeLabel('PT'), 'Permiso Temporal'),
    );
    test(
      '50. MS → Menor sin Identificación',
      () => expect(docTypeLabel('MS'), 'Menor sin Identificación'),
    );
    test(
      '51. AS → Adulto sin Identificación',
      () => expect(docTypeLabel('AS'), 'Adulto sin Identificación'),
    );
    test(
      '52. código desconocido → mismo valor',
      () => expect(docTypeLabel('XX'), 'XX'),
    );
    test('53. cadena vacía → cadena vacía', () => expect(docTypeLabel(''), ''));
  });

  group('hasInternetConnection (6 tests)', () {
    test(
      '54. true cuando hay wifi',
      () => expect(hasInternetConnection([ConnectivityResult.wifi]), true),
    );
    test(
      '55. true cuando hay mobile',
      () => expect(hasInternetConnection([ConnectivityResult.mobile]), true),
    );
    test(
      '56. false cuando contiene none',
      () => expect(hasInternetConnection([ConnectivityResult.none]), false),
    );
    test(
      '57. false cuando hay varios resultados y uno es none',
      () => expect(
        hasInternetConnection([
          ConnectivityResult.wifi,
          ConnectivityResult.none,
        ]),
        false,
      ),
    );
    test(
      '58. lista vacía → true',
      () => expect(hasInternetConnection(const []), true),
    );
    test(
      '59. múltiples tipos sin none → true',
      () => expect(
        hasInternetConnection([
          ConnectivityResult.wifi,
          ConnectivityResult.ethernet,
        ]),
        true,
      ),
    );
  });
}
