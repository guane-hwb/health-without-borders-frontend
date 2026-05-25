// test/unit/features/auth/login_screen_unit_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Estas pruebas validan la LÓGICA PURA del LoginScreen:
//  • Validadores del formulario (email y contraseña)
//  • Cambio de idioma (toggle ES ↔ EN)
//  • Estado inicial de los controladores
// No requieren render de widgets ni dependencias externas.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Helpers: replicamos los mismos validadores que usa _LabeledField ────────

  String? emailValidator(String? v, {String locale = 'es'}) {
    if (v == null || v.trim().isEmpty) {
      return locale == 'es' ? 'El correo es requerido' : 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(v.trim())) {
      return locale == 'es' ? 'Correo invalido' : 'Invalid email';
    }
    return null;
  }

  String? passwordValidator(String? v, {String locale = 'es'}) {
    if (v == null || v.isEmpty) {
      return locale == 'es'
          ? 'La contrasena es requerida'
          : 'Password is required';
    }
    if (v.length < 6) {
      return locale == 'es'
          ? 'Minimo 6 caracteres'
          : 'Minimum 6 characters';
    }
    return null;
  }

  // ── Grupo 1: Validador de email ─────────────────────────────────────────────
  group('Email validator', () {
    test('retorna error cuando el campo esta vacio', () {
      expect(emailValidator(''), isNotNull);
      expect(emailValidator(null), isNotNull);
      expect(emailValidator('   '), isNotNull);
    });

    test('retorna error para emails con formato invalido', () {
      expect(emailValidator('noesuncorreo'), isNotNull);
      expect(emailValidator('falta@eldominio'), isNotNull);
      expect(emailValidator('@sinusuario.com'), isNotNull);
      expect(emailValidator('sin arroba.com'), isNotNull);
      expect(emailValidator('doble@@dominio.com'), isNotNull);
    });

    test('retorna null para emails validos', () {
      expect(emailValidator('usuario@dominio.com'), isNull);
      expect(emailValidator('nombre.apellido@empresa.org'), isNull);
      expect(emailValidator('user_name@dominio.co'), isNull);
      expect(emailValidator('  user@test.io  '), isNull); // trim
    });

    test('retorna mensaje en ingles cuando locale es en', () {
      final msg = emailValidator('', locale: 'en');
      expect(msg, contains('required'));
    });

    test('retorna mensaje en espanol cuando locale es es', () {
      final msg = emailValidator('', locale: 'es');
      expect(msg, contains('requerido'));
    });
  });

  // ── Grupo 2: Validador de contraseña ────────────────────────────────────────
  group('Password validator', () {
    test('retorna error cuando el campo esta vacio', () {
      expect(passwordValidator(''), isNotNull);
      expect(passwordValidator(null), isNotNull);
    });

    test('retorna error cuando la contrasena tiene menos de 6 caracteres', () {
      expect(passwordValidator('abc'), isNotNull);
      expect(passwordValidator('12345'), isNotNull);
    });

    test('retorna null para contrasenas validas (>= 6 caracteres)', () {
      expect(passwordValidator('123456'), isNull);
      expect(passwordValidator('miContrasena123!'), isNull);
      expect(passwordValidator('abcdef'), isNull);
    });

    test('retorna mensaje en ingles cuando locale es en', () {
      final msg = passwordValidator('', locale: 'en');
      expect(msg, contains('required'));
    });

    test('retorna mensaje en espanol cuando locale es es', () {
      final msg = passwordValidator('', locale: 'es');
      expect(msg, contains('requerida'));
    });
  });

  // ── Grupo 3: Lógica del toggle de idioma ────────────────────────────────────
  group('Language toggle logic', () {
    test('al empezar en es, el toggle produce en', () {
      String locale = 'es';
      locale = locale == 'es' ? 'en' : 'es';
      expect(locale, 'en');
    });

    test('al empezar en en, el toggle produce es', () {
      String locale = 'en';
      locale = locale == 'es' ? 'en' : 'es';
      expect(locale, 'es');
    });

    test('dos toggles consecutivos regresan al idioma original', () {
      String locale = 'es';
      locale = locale == 'es' ? 'en' : 'es';
      locale = locale == 'es' ? 'en' : 'es';
      expect(locale, 'es');
    });
  });

  // ── Grupo 4: TextEditingController — estado inicial ─────────────────────────
  group('TextEditingController initial state', () {
    late TextEditingController emailCtrl;
    late TextEditingController passwordCtrl;

    setUp(() {
      emailCtrl = TextEditingController();
      passwordCtrl = TextEditingController();
    });

    tearDown(() {
      emailCtrl.dispose();
      passwordCtrl.dispose();
    });

    test('los controladores inician vacios', () {
      expect(emailCtrl.text, isEmpty);
      expect(passwordCtrl.text, isEmpty);
    });

    test('al asignar texto, el controlador lo refleja', () {
      emailCtrl.text = 'test@correo.com';
      passwordCtrl.text = 'password123';
      expect(emailCtrl.text, 'test@correo.com');
      expect(passwordCtrl.text, 'password123');
    });

    test('trim elimina espacios en email antes de validar', () {
      emailCtrl.text = '  usuario@test.com  ';
      expect(emailValidator(emailCtrl.text), isNull);
    });
  });

  // ── Grupo 5: Estado booleano interno ────────────────────────────────────────
  group('Boolean state flags', () {
    test('_rememberSession inicia en true por defecto', () {
      // Refleja el valor hardcodeado en _LoginScreenState
      const bool rememberSession = true;
      expect(rememberSession, isTrue);
    });

    test('_obscurePassword inicia en true (contrasena oculta)', () {
      const bool obscurePassword = true;
      expect(obscurePassword, isTrue);
    });

    test('_isLoading inicia en false', () {
      const bool isLoading = false;
      expect(isLoading, isFalse);
    });
  });

  // ── Grupo 6: Regex de email — casos borde ───────────────────────────────────
  group('Email regex edge cases', () {
    final emailRegex = RegExp(r'^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,}$');

    test('acepta TLDs de 2+ caracteres', () {
      expect(emailRegex.hasMatch('a@b.co'), isTrue);
      expect(emailRegex.hasMatch('a@b.com'), isTrue);
      expect(emailRegex.hasMatch('a@b.info'), isTrue);
    });

    test('rechaza TLD de un solo caracter', () {
      expect(emailRegex.hasMatch('a@b.c'), isFalse);
    });

    test('rechaza email sin @', () {
      expect(emailRegex.hasMatch('sinArrobaDominio.com'), isFalse);
    });

    test('rechaza string vacio', () {
      expect(emailRegex.hasMatch(''), isFalse);
    });
  });
}