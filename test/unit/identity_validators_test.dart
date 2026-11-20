// test/unit/identity_validators_test.dart

import 'package:flutter_test/flutter_test.dart';
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
