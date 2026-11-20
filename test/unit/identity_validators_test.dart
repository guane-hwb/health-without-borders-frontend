// test/unit/identity_validators_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/validation/identity_validators.dart';

void main() {
  group('validateDocumentNumber', () {
    test('acepta cédula colombiana', () {
      expect(validateDocumentNumber('1098765432'), isNull);
    });

    test('acepta PPT venezolano con puntos', () {
      expect(validateDocumentNumber('PPT-1.234.567'), isNull);
    });

    test('rechaza menos de 5 caracteres', () {
      expect(validateDocumentNumber('1234'), ValidationErrorKey.documentFormat);
    });

    test('rechaza símbolos no admitidos', () {
      expect(
        validateDocumentNumber('CC#12345'),
        ValidationErrorKey.documentFormat,
      );
    });

    test('un valor vacío no es un error de formato', () {
      expect(validateDocumentNumber('   '), isNull);
    });
  });

  group('validatePhone', () {
    test('acepta móvil colombiano', () {
      expect(validatePhone('3001234567'), isNull);
    });

    test('acepta prefijo internacional', () {
      expect(validatePhone('+573001234567'), isNull);
    });

    test('rechaza letras', () {
      expect(validatePhone('300ABC4567'), ValidationErrorKey.phoneFormat);
    });

    test('un valor vacío no es un error de formato', () {
      expect(validatePhone(''), isNull);
    });

    test('acepta el número escrito con espacios, como el ejemplo', () {
      expect(validatePhone('+57 310 482 9914'), isNull);
    });

    test('el ejemplo que muestra el campo pasa la validación (es y en)', () {
      for (final locale in ['es', 'en']) {
        final hint = AppStrings.forTesting(locale).guardianPhoneHint;
        final example = hint.substring(hint.indexOf('+'));
        expect(validatePhone(example), isNull, reason: '$locale: $hint');
      }
    });

    test('acepta guiones, puntos y paréntesis', () {
      expect(validatePhone('(310) 482-9914'), isNull);
      expect(validatePhone('310.482.9914'), isNull);
    });

    test('rechaza un número hecho sólo de separadores', () {
      expect(validatePhone(' - ( ) '), ValidationErrorKey.phoneFormat);
    });

    test('rechaza un «+» que no va al principio', () {
      expect(validatePhone('57+3104829914'), ValidationErrorKey.phoneFormat);
    });

    test('sin los separadores sigue exigiendo de 7 a 15 dígitos', () {
      expect(validatePhone('+57 310'), ValidationErrorKey.phoneFormat);
      expect(
        validatePhone('+57 310 482 9914 0000'),
        ValidationErrorKey.phoneFormat,
      );
    });
  });

  group('normalizePhone', () {
    test('deja sólo los dígitos y el «+» inicial', () {
      expect(normalizePhone('+57 310 482 9914'), '+573104829914');
      expect(normalizePhone(' (310) 482-99.14 '), '3104829914');
    });

    test('un número ya normalizado no cambia', () {
      expect(normalizePhone('+573104829914'), '+573104829914');
    });
  });

  group('validateEmail', () {
    test('acepta correo normal', () {
      expect(validateEmail('a@b.co'), isNull);
    });

    test('rechaza sin dominio', () {
      expect(validateEmail('a@b'), ValidationErrorKey.emailFormat);
    });

    for (final String email in <String>[
      'enfermera@salud.gov.co',
      'juan.perez@cruzroja.org.co',
      'user@guane.com.co',
      'ana+brigada@unicef.org',
      'medico@unicef.org',
    ]) {
      test('acepta $email (dominio de dos niveles o con «+»)', () {
        expect(validateEmail(email), isNull);
      });
    }

    for (final String email in <String>[
      'sin-arroba',
      '@unicef.org',
      'ana@',
      'ana@@unicef.org',
      'ana @unicef.org',
      'ana@unicef.o',
    ]) {
      test('rechaza «$email»', () {
        expect(validateEmail(email), ValidationErrorKey.emailFormat);
      });
    }

    test('un valor vacío no es un error de formato', () {
      expect(validateEmail(''), isNull);
    });
  });
}
