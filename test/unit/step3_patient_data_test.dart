// test/unit/step3_patient_data_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step3_patient_data.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/register_draft.dart';
import 'package:health_without_borders_frontend/src/shared/country_display.dart';

String _formatDate(DateTime? value) {
  if (value == null) return '';
  return '${value.year}'
      '-${value.month.toString().padLeft(2, '0')}'
      '-${value.day.toString().padLeft(2, '0')}';
}

String? _optionalField(String raw) {
  final v = raw.trim();
  return v.isEmpty ? null : v;
}

void main() {
  group('_formatDate – _StyledDateField._display', () {
    test('devuelve cadena vacía cuando value es null', () {
      expect(_formatDate(null), '');
    });

    test('formatea fecha con mes y día de dos dígitos', () {
      expect(_formatDate(DateTime(1990, 11, 25)), '1990-11-25');
    });

    test('padLeft: mes de un dígito queda con cero a la izquierda', () {
      expect(_formatDate(DateTime(2000, 5, 1)), '2000-05-01');
    });

    test('padLeft: día de un dígito queda con cero a la izquierda', () {
      expect(_formatDate(DateTime(1985, 12, 3)), '1985-12-03');
    });

    test('padLeft: mes y día ambos de un dígito', () {
      expect(_formatDate(DateTime(2010, 1, 9)), '2010-01-09');
    });

    test('año de 4 dígitos se conserva tal cual', () {
      expect(_formatDate(DateTime(2024, 12, 31)), '2024-12-31');
    });

    test('fecha mínima representable: 1900-01-01', () {
      expect(_formatDate(DateTime(1900, 1, 1)), '1900-01-01');
    });

    test('fecha con mes=10 (dos dígitos) no agrega cero extra', () {
      expect(_formatDate(DateTime(2005, 10, 20)), '2005-10-20');
    });
  });

  group('patientHasEthnicity (símbolo real de producción)', () {
    test('null → false', () => expect(patientHasEthnicity(null), isFalse));
    test("'6' → false ('Ninguno')", () {
      expect(patientHasEthnicity('6'), isFalse);
    });
    test("'99' → false (código heredado del backend para 'Ninguna')", () {
      expect(patientHasEthnicity('99'), isFalse);
    });
    test("'1' → true (Indígena)", () {
      expect(patientHasEthnicity('1'), isTrue);
    });
    test("'2' → true (ROM/Gitano)", () {
      expect(patientHasEthnicity('2'), isTrue);
    });
    test("'3' → true (Raizal)", () {
      expect(patientHasEthnicity('3'), isTrue);
    });
    test("'4' → true (Palenquero)", () {
      expect(patientHasEthnicity('4'), isTrue);
    });
    test("'5' → true (Afrocolombiano)", () {
      expect(patientHasEthnicity('5'), isTrue);
    });
    test("'01' (formato viejo, incompatible con el backend) → true: "
        'patientHasEthnicity no valida el FORMATO del código, solo si '
        'representa "ninguna etnia". Un valor así nunca debería llegar a '
        'draft.ethnicity porque el selector solo emite códigos de '
        'kEthnicityCodes — este caso documenta el riesgo, no lo avala.', () {
      expect(patientHasEthnicity('01'), isTrue);
    });
  });

  group('kEthnicityCodes / kDisabilityCodes (contrato real exportado)', () {
    test('kEthnicityCodes contiene exactamente los 6 códigos esperados', () {
      expect(kEthnicityCodes, equals(<String>['6', '1', '2', '3', '4', '5']));
    });

    test('kNoEthnicityCodes son los únicos códigos de "sin etnia"', () {
      expect(kNoEthnicityCodes, equals(<String>['6', '99']));
      for (final code in kEthnicityCodes) {
        expect(
          patientHasEthnicity(code),
          equals(!kNoEthnicityCodes.contains(code)),
        );
      }
    });

    test('kDisabilityCodes contiene exactamente los 8 códigos esperados', () {
      expect(
        kDisabilityCodes,
        equals(<String>['00', '01', '02', '03', '04', '05', '06', '07']),
      );
    });

    test(
      'ningún código de etnia coincide con el formato viejo de 2 dígitos '
      '(protege contra la regresión original de v2-copia-etnia-divergida)',
      () {
        for (final code in kEthnicityCodes) {
          expect(
            code.length == 2 && code != '99',
            isFalse,
            reason:
                'Código "$code" parece del formato viejo incompatible '
                '(01-06). Si esto fallara, alguien reintrodujo el bug '
                'original.',
          );
        }
      },
    );
  });

  group('_optionalField – trim y null', () {
    test('cadena vacía → null', () => expect(_optionalField(''), isNull));
    test('solo espacios → null', () => expect(_optionalField('   '), isNull));
    test(
      'valor con espacios → trimado',
      () => expect(_optionalField(' Ana '), 'Ana'),
    );
    test(
      'valor sin espacios → igual',
      () => expect(_optionalField('ABC'), 'ABC'),
    );
    test('tabulaciones → null', () => expect(_optionalField('\t\n'), isNull));
  });

  group('RegisterDraft – valores y asignación', () {
    test('documentNumber se asigna y recupera', () {
      final d = RegisterDraft()..documentNumber = '123';
      expect(d.documentNumber, '123');
    });

    test('secondName null por defecto', () {
      expect(RegisterDraft().secondName, isNull);
    });

    test('secondLastName null por defecto', () {
      expect(RegisterDraft().secondLastName, isNull);
    });

    test('street null por defecto', () {
      expect(RegisterDraft().street, isNull);
    });

    test('ethnicCommunity null por defecto', () {
      expect(RegisterDraft().ethnicCommunity, isNull);
    });

    test('ethnicity null por defecto', () {
      expect(RegisterDraft().ethnicity, isNull);
    });

    test('genderIdentity null por defecto', () {
      expect(RegisterDraft().genderIdentity, isNull);
    });

    test('disabilityCategory null por defecto', () {
      expect(RegisterDraft().disabilityCategory, isNull);
    });

    test('bloodType null por defecto', () {
      expect(RegisterDraft().bloodType, isNull);
    });

    test('dob null por defecto', () {
      expect(RegisterDraft().dob, isNull);
    });

    test('nationalityName se asigna al cambiar nationalityCode', () {
      final d = RegisterDraft()
        ..nationalityCode = 'VEN'
        ..nationalityName = 'Venezolana';
      expect(d.nationalityCode, 'VEN');
      expect(d.nationalityName, 'Venezolana');
    });

    test('zone null por defecto', () {
      expect(RegisterDraft().zone, isNull);
    });

    test('múltiples asignaciones en cascada no se pisan', () {
      final d = RegisterDraft()
        ..documentNumber = 'D1'
        ..firstName = 'Pedro'
        ..firstLastName = 'Ramírez'
        ..secondName = 'Luis'
        ..secondLastName = 'Gómez'
        ..street = 'Cra 5'
        ..addressCity = 'Medellín'
        ..addressState = 'Antioquia';

      expect(d.documentNumber, 'D1');
      expect(d.firstName, 'Pedro');
      expect(d.firstLastName, 'Ramírez');
      expect(d.secondName, 'Luis');
      expect(d.secondLastName, 'Gómez');
      expect(d.street, 'Cra 5');
      expect(d.addressCity, 'Medellín');
      expect(d.addressState, 'Antioquia');
    });
  });

  group('Mapas locales – ramas isEs', () {
    String sc(bool isEs) => isEs ? 'Salvoconducto' : 'Safe-conduct';
    String cn(bool isEs) => isEs ? 'Cert. nacido vivo' : 'Live birth cert.';
    String de(bool isEs) => isEs ? 'Doc. extranjero' : 'Foreign ID';
    String tr(bool isEs) => isEs ? 'Transgénero' : 'Transgender';
    String nb(bool isEs) => isEs ? 'No binario' : 'Non-binary';
    String nr(bool isEs) => isEs ? 'No reporta' : 'Not reported';
    String col(bool isEs) => isEs ? 'Colombiana' : 'Colombian';
    String ven(bool isEs) => isEs ? 'Venezolana' : 'Venezuelan';
    String ecu(bool isEs) => isEs ? 'Ecuatoriana' : 'Ecuadorian';
    String per(bool isEs) => isEs ? 'Peruana' : 'Peruvian';
    String hti(bool isEs) => isEs ? 'Haitiana' : 'Haitian';
    String cub(bool isEs) => isEs ? 'Cubana' : 'Cuban';
    String nin(bool isEs) => isEs ? 'Ninguno' : 'None';
    String ind(bool isEs) => isEs ? 'Indígena' : 'Indigenous';
    String rom(bool isEs) => isEs ? 'ROM/Gitano' : 'Romani';
    String rai(bool isEs) => isEs ? 'Raizal' : 'Raizal';
    String pal(bool isEs) => isEs ? 'Palenquero' : 'Palenquero';
    String afr(bool isEs) => isEs ? 'Afrocolombiano' : 'Afro-Colombian';
    String dnin(bool isEs) => isEs ? 'Ninguna' : 'None';
    String fis(bool isEs) => isEs ? 'Física' : 'Physical';
    String intel(bool isEs) => isEs ? 'Intelectual' : 'Intellectual';
    String aud(bool isEs) => isEs ? 'Auditiva' : 'Hearing';
    String vis(bool isEs) => isEs ? 'Visual' : 'Visual';
    String sor(bool isEs) => isEs ? 'Sordoceguera' : 'Deaf-blindness';
    String psi(bool isEs) => isEs ? 'Psicosocial' : 'Psychosocial';
    String mul(bool isEs) => isEs ? 'Múltiple' : 'Multiple';
    String asM(bool isEs) => isEs ? 'Adulto s/ID' : 'Adult w/o ID';

    test('SC en español', () => expect(sc(true), 'Salvoconducto'));
    test('SC en inglés', () => expect(sc(false), 'Safe-conduct'));
    test('CN en español', () => expect(cn(true), 'Cert. nacido vivo'));
    test('CN en inglés', () => expect(cn(false), 'Live birth cert.'));
    test('DE en español', () => expect(de(true), 'Doc. extranjero'));
    test('DE en inglés', () => expect(de(false), 'Foreign ID'));
    test('Transgénero es', () => expect(tr(true), 'Transgénero'));
    test('Transgender en', () => expect(tr(false), 'Transgender'));
    test('No binario es', () => expect(nb(true), 'No binario'));
    test('Non-binary en', () => expect(nb(false), 'Non-binary'));
    test('No reporta es', () => expect(nr(true), 'No reporta'));
    test('Not reported en', () => expect(nr(false), 'Not reported'));
    test('Colombiana es', () => expect(col(true), 'Colombiana'));
    test('Colombian en', () => expect(col(false), 'Colombian'));
    test('Venezolana es', () => expect(ven(true), 'Venezolana'));
    test('Venezuelan en', () => expect(ven(false), 'Venezuelan'));
    test('Ecuatoriana es', () => expect(ecu(true), 'Ecuatoriana'));
    test('Ecuadorian en', () => expect(ecu(false), 'Ecuadorian'));
    test('Peruana es', () => expect(per(true), 'Peruana'));
    test('Peruvian en', () => expect(per(false), 'Peruvian'));
    test('Haitiana es', () => expect(hti(true), 'Haitiana'));
    test('Haitian en', () => expect(hti(false), 'Haitian'));
    test('Cubana es', () => expect(cub(true), 'Cubana'));
    test('Cuban en', () => expect(cub(false), 'Cuban'));
    test('Ninguno (etnia) es', () => expect(nin(true), 'Ninguno'));
    test('None (etnia) en', () => expect(nin(false), 'None'));
    test('Indígena es', () => expect(ind(true), 'Indígena'));
    test('Indigenous en', () => expect(ind(false), 'Indigenous'));
    test('ROM/Gitano es', () => expect(rom(true), 'ROM/Gitano'));
    test('Romani en', () => expect(rom(false), 'Romani'));
    test('Raizal es', () => expect(rai(true), 'Raizal'));
    test('Raizal en', () => expect(rai(false), 'Raizal'));
    test('Palenquero es', () => expect(pal(true), 'Palenquero'));
    test('Palenquero en', () => expect(pal(false), 'Palenquero'));
    test('Afrocolombiano es', () => expect(afr(true), 'Afrocolombiano'));
    test('Afro-Colombian en', () => expect(afr(false), 'Afro-Colombian'));
    test('Ninguna (discap) es', () => expect(dnin(true), 'Ninguna'));
    test('None (discap) en', () => expect(dnin(false), 'None'));
    test('Física es', () => expect(fis(true), 'Física'));
    test('Physical en', () => expect(fis(false), 'Physical'));
    test('Intelectual es', () => expect(intel(true), 'Intelectual'));
    test('Intellectual en', () => expect(intel(false), 'Intellectual'));
    test('Auditiva es', () => expect(aud(true), 'Auditiva'));
    test('Hearing en', () => expect(aud(false), 'Hearing'));
    test('Visual es', () => expect(vis(true), 'Visual'));
    test('Visual en', () => expect(vis(false), 'Visual'));
    test('Sordoceguera es', () => expect(sor(true), 'Sordoceguera'));
    test('Deaf-blindness en', () => expect(sor(false), 'Deaf-blindness'));
    test('Psicosocial es', () => expect(psi(true), 'Psicosocial'));
    test('Psychosocial en', () => expect(psi(false), 'Psychosocial'));
    test('Múltiple es', () => expect(mul(true), 'Múltiple'));
    test('Multiple en', () => expect(mul(false), 'Multiple'));
    test('AS con sexo M es', () => expect(asM(true), 'Adulto s/ID'));
    test('AS con sexo M en', () => expect(asM(false), 'Adult w/o ID'));
  });

  group('Vocabulario de nacionalidad', () {
    test('todos los códigos ofrecidos son alfa-3 de tres letras', () {
      for (final String code in kSupportedNationalityCodes) {
        if (code == 'OTHER') continue;
        expect(
          RegExp(r'^[A-Z]{3}$').hasMatch(code),
          isTrue,
          reason: '"$code" no es un ISO 3166-1 alfa-3 válido',
        );
      }
    });

    test('no se ofrece el centinela UNK', () {
      expect(kSupportedNationalityCodes, isNot(contains('UNK')));
    });

    test('todo código ofrecido tiene presentación en el catálogo', () {
      for (final String code in kSupportedNationalityCodes) {
        if (code == 'OTHER') continue;
        expect(
          countryDisplay(code).flag,
          isNot('🌍'),
          reason: '"$code" cae al globo: falta en countryDisplay',
        );
      }
    });
  });
}
