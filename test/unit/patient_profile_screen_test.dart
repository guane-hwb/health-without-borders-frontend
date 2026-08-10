// test/unit/patient_profile_screen_test.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/patient_profile_helpers.dart';

PatientFullRecord _buildRecord({
  String patientId = 'p1',
  double? weight,
  double? height,
}) {
  return PatientFullRecord(
    patientId: patientId,
    deviceUid: 'uid-1',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'RC',
        documentNumber: '123',
      ),
      firstLastName: 'Pérez',
      firstName: 'Juan',
      dob: '2000-01-01',
      biologicalSex: 'M',
      address: Address(city: 'Bogotá', state: 'Cundinamarca'),
      weight: weight,
      height: height,
    ),
    guardianInfo: GuardianInfo(
      name: 'María Pérez',
      relationship: '01',
      phone: '3000000000',
    ),
  );
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

    test('5. devuelve null para formato no soportado (puntos)', () {
      expect(computeAge('1990.06.15', DateTime(2025, 1, 1)), isNull);
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
    final es = AppStrings.forTesting('es');
    test('18. 01 → Padres', () => expect(relLabel(es, '01'), 'Padres'));
    test('19. 02 → Hermanos', () => expect(relLabel(es, '02'), 'Hermanos'));
    test('20. 03 → Tíos', () => expect(relLabel(es, '03'), 'Tíos'));
    test('21. 04 → Abuelos', () => expect(relLabel(es, '04'), 'Abuelos'));
    test('22. código desconocido → mismo valor', () {
      expect(relLabel(es, '99'), '99');
    });
    test('23. cadena vacía → cadena vacía', () {
      expect(relLabel(es, ''), '');
    });
  });

  group('medStatusLabel (6 tests)', () {
    final es = AppStrings.forTesting('es');
    test(
      '24. active → Activo',
      () => expect(medStatusLabel(es, 'active'), 'Activo'),
    );
    test(
      '25. completed → Completado',
      () => expect(medStatusLabel(es, 'completed'), 'Completado'),
    );
    test(
      '26. stopped → Suspendido',
      () => expect(medStatusLabel(es, 'stopped'), 'Suspendido'),
    );
    test(
      '27. unknown → Desconocido',
      () => expect(medStatusLabel(es, 'unknown'), 'Desconocido'),
    );
    test('28. estado arbitrario → mismo valor', () {
      expect(medStatusLabel(es, 'on-hold'), 'on-hold');
    });
    test('29. cadena vacía → cadena vacía', () {
      expect(medStatusLabel(es, ''), '');
    });
  });

  group('hasUnsyncedChanges vía PatientFullRecord real (5 tests)', () {
    final base = _buildRecord(weight: 70.0, height: 170.0);

    test('30. false cuando draft y original son idénticos (misma data)', () {
      final draft = _buildRecord(weight: 70.0, height: 170.0);
      expect(draft != base, false);
    });

    test('31. true cuando un campo del draft difiere (peso)', () {
      final draft = base.copyWith(
        patientInfo: base.patientInfo.copyWith(weight: 71.0),
      );
      expect(draft != base, true);
    });

    test('32. true cuando cambia un campo anidado (dirección)', () {
      final draft = base.copyWith(
        patientInfo: base.patientInfo.copyWith(
          address: Address(city: 'Medellín', state: 'Antioquia'),
        ),
      );
      expect(draft != base, true);
    });

    test(
      '33. false con dos instancias construidas por separado pero iguales',
      () {
        final a = _buildRecord(weight: 70.0, height: 170.0);
        final b = _buildRecord(weight: 70.0, height: 170.0);
        expect(a != b, false);
      },
    );

    test('34. true cuando cambia la lista de alergias', () {
      final draft = base.copyWith(
        allergies: [
          AllergyInfo(category: '02', allergen: 'Maní', reaction: 'Urticaria'),
        ],
      );
      expect(draft != base, true);
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
        expect(idx, lessThan(avatarColorPaletteLength));
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
    final es = AppStrings.forTesting('es');
    test('39. M → Masculino', () => expect(sexLabel(es, 'M'), 'Masculino'));
    test('40. F → Femenino', () => expect(sexLabel(es, 'F'), 'Femenino'));
    test('41. valor desconocido → Indeterminado', () {
      expect(sexLabel(es, 'X'), 'Indeterminado');
    });
    test('42. cadena vacía → Indeterminado', () {
      expect(sexLabel(es, ''), 'Indeterminado');
    });
  });

  group('docTypeLabel (14 tests)', () {
    final es = AppStrings.forTesting('es');
    final en = AppStrings.forTesting('en');
    test(
      '43. RC → Reg. civil',
      () => expect(docTypeLabel(es, 'RC'), 'Reg. civil'),
    );
    test(
      '44. TI → Tarjeta identidad',
      () => expect(docTypeLabel(es, 'TI'), 'Tarjeta identidad'),
    );
    test('45. CC → Cédula', () => expect(docTypeLabel(es, 'CC'), 'Cédula'));
    test(
      '46. CE → Céd. extranjería',
      () => expect(docTypeLabel(es, 'CE'), 'Céd. extranjería'),
    );
    test(
      '47. PA → Pasaporte',
      () => expect(docTypeLabel(es, 'PA'), 'Pasaporte'),
    );
    test(
      '48. PE → Permiso esp.',
      () => expect(docTypeLabel(es, 'PE'), 'Permiso esp.'),
    );
    test('49. PT → PPT', () => expect(docTypeLabel(es, 'PT'), 'PPT'));
    test(
      '50. MS → Menor s/ID',
      () => expect(docTypeLabel(es, 'MS'), 'Menor s/ID'),
    );
    test(
      '51. AS → Adulto s/ID',
      () => expect(docTypeLabel(es, 'AS'), 'Adulto s/ID'),
    );
    test(
      '52. código desconocido → mismo valor',
      () => expect(docTypeLabel(es, 'XX'), 'XX'),
    );
    test('53. cadena vacía → "—"', () => expect(docTypeLabel(es, ''), '—'));
    test(
      '53b. SC en es → Salvoconducto',
      () => expect(docTypeLabel(es, 'SC'), 'Salvoconducto'),
    );
    test(
      '53c. SC en en → Safe-conduct',
      () => expect(docTypeLabel(en, 'SC'), 'Safe-conduct'),
    );
    test(
      '53d. CN en es → Cert. Nacido Vivo',
      () => expect(docTypeLabel(es, 'CN'), 'Cert. Nacido Vivo'),
    );
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
