// test/unit/password_policy_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/network/api_error_codes.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/password_policy.dart';

void main() {
  group('PasswordPolicy.problem', () {
    String? problem(String p, {String? current}) =>
        PasswordPolicy.problem(p, current: current, isEs: true);

    test('acepta una contraseña de 12 caracteres que no es común', () {
      expect(problem('una-clave-12'), isNull);
    });

    test('rechaza menos de 12 caracteres', () {
      expect(problem('corta-11chr'), 'Debe tener al menos 12 caracteres.');
    });

    test('cuenta caracteres, no unidades UTF-16: un emoji cuenta uno', () {
      // 11 letters + 1 emoji = 12 characters (13 UTF-16 units).
      expect(problem('abcdefghijk😀'), isNull);
      // 10 letters + 1 emoji = 11 characters, though 12 UTF-16 units.
      expect(problem('abcdefghij😀'), isNotNull);
    });

    test('rechaza más de 72 bytes UTF-8', () {
      expect(problem('a' * 72), isNull);
      expect(problem('a' * 73), contains('72 bytes'));
      // 37 "ñ" are 37 characters but 74 bytes.
      expect(problem('ñ' * 37), contains('72 bytes'));
    });

    test('rechaza las comunes sin distinguir mayúsculas ni espacios', () {
      expect(problem('Password1234'), contains('común'));
      expect(problem(' CONTRASEÑA123 '), contains('común'));
    });

    test('rechaza la misma que la actual', () {
      expect(
        problem('una-clave-12', current: 'una-clave-12'),
        'Debe ser distinta de la contraseña actual.',
      );
    });

    test('mensajes en inglés', () {
      expect(
        PasswordPolicy.problem('short', isEs: false),
        'It must have at least 12 characters.',
      );
    });
  });

  group('ApiErrorCode.tooManyAttempts', () {
    String wait(int? seconds, {bool isEs = true}) =>
        ApiErrorCode.tooManyAttempts(
          seconds == null ? null : Duration(seconds: seconds),
          isEs: isEs,
        );

    test('sin Retry-After da un mensaje genérico', () {
      expect(
        wait(null),
        'Demasiados intentos. Espere unos minutos e intente de nuevo.',
      );
      expect(wait(0), startsWith('Demasiados intentos. Espere'));
    });

    test('segundos y minutos, en singular y plural', () {
      expect(wait(1), 'Demasiados intentos. Intente de nuevo en 1 segundo.');
      expect(wait(45), 'Demasiados intentos. Intente de nuevo en 45 segundos.');
      expect(wait(60), 'Demasiados intentos. Intente de nuevo en 1 minuto.');
      expect(wait(61), 'Demasiados intentos. Intente de nuevo en 2 minutos.');
      expect(wait(900), 'Demasiados intentos. Intente de nuevo en 15 minutos.');
      expect(
        wait(120, isEs: false),
        'Too many attempts. Try again in 2 minutes.',
      );
      expect(wait(1, isEs: false), 'Too many attempts. Try again in 1 second.');
    });

    test('login_paused tiene mensaje propio', () {
      expect(
        ApiErrorCode.describe(ApiErrorCode.loginPaused, isEs: true),
        wait(null),
      );
    });
  });
}
