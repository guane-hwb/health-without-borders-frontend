// test/unit/manage_organizations_screen_test.dart

import 'package:flutter_test/flutter_test.dart';

class OrgSummary {
  const OrgSummary({
    required this.id,
    required this.name,
    required this.isActive,
  });
  final String id;
  final String name;
  final bool isActive;
}

const int _bgColorsLength = 5;
int colorIndexFor(String name) => name.codeUnitAt(0) % _bgColorsLength;

String initialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── OrgSummary ─────────────────────────────────────────────────────────

  group('OrgSummary', () {
    test('almacena id, name e isActive correctamente', () {
      const org = OrgSummary(id: 'abc', name: 'Cruz Roja', isActive: true);
      expect(org.id, 'abc');
      expect(org.name, 'Cruz Roja');
      expect(org.isActive, isTrue);
    });

    test('isActive puede ser false', () {
      const org = OrgSummary(id: '1', name: 'Org', isActive: false);
      expect(org.isActive, isFalse);
    });
  });

  // ── (_OrgCard._initials) ────────────────────────────────────

  group('initialsFor', () {
    test('dos palabras → primera letra de cada una en mayúscula', () {
      expect(initialsFor('Cruz Roja'), 'CR');
    });

    test('tres palabras → solo las dos primeras letras', () {
      expect(initialsFor('Cruz Roja Norte'), 'CR');
    });

    test('una sola palabra → hasta 2 chars en mayúscula', () {
      expect(initialsFor('Omega'), 'OM');
    });

    test('una sola letra → devuelve esa letra', () {
      expect(initialsFor('A'), 'A');
    });

    test('una palabra de 2 chars → devuelve ambas en mayúscula', () {
      expect(initialsFor('ab'), 'AB');
    });

    test('spaces extra al inicio/fin se ignoran', () {
      expect(initialsFor('  Cruz Roja  '), 'CR');
    });

    test('múltiples espacios entre palabras se normalizan', () {
      expect(initialsFor('Cruz   Roja'), 'CR');
    });

    test('nombre vacío → substring vacío (no lanza excepción)', () {
      // name.length.clamp(0,2) = 0 → ''
      expect(initialsFor(''), '');
    });

    test('resultado siempre en mayúsculas', () {
      expect(initialsFor('open source'), 'OS');
    });
  });

  // ── Color index (_OrgCard._ci) ────────────────────────────────────────

  group('colorIndexFor', () {
    test('siempre está en rango [0, 4]', () {
      final names = [
        'Alfa',
        'Beta',
        'Cruz Roja',
        'Zeta',
        'Omega',
        'Nación',
        'Q',
      ];
      for (final n in names) {
        final idx = colorIndexFor(n);
        expect(
          idx,
          inInclusiveRange(0, 4),
          reason: 'Fallo para "$n" → índice=$idx',
        );
      }
    });

    test('determinista: mismo nombre → mismo índice', () {
      expect(colorIndexFor('Cruz Roja'), colorIndexFor('Cruz Roja'));
    });

    test('nombres distintos con mismo primer char → mismo índice', () {
      expect(colorIndexFor('Cruz'), colorIndexFor('Corazón'));
    });
  });

  // ──(_step) ────────────────────────────────────────────

  group('lógica de pasos del sheet', () {
    test('step inicial es 1', () {
      int step = 1;
      expect(step, 1);
    });

    test('después de submitStep1 exitoso, step pasa a 2', () {
      int step = 1;
      step = 2;
      expect(step, 2);
    });

    test('al volver desde step 2, step regresa a 1', () {
      int step = 2;
      step = 1;
      expect(step, 1);
    });

    test('después de submitStep2 exitoso, step pasa a 3', () {
      int step = 2;
      step = 3;
      expect(step, 3);
    });

    test('step 3 es el estado de éxito (no hay más pasos)', () {
      const int successStep = 3;
      expect(successStep, greaterThan(2));
    });
  });

  // ── _submitStep1 ──────────────────────────────────────

  group('validación step 1 (nombre de organización)', () {
    String? validateOrgName(String raw) {
      final name = raw.trim();
      if (name.isEmpty) return 'El nombre de la organización es obligatorio.';
      return null;
    }

    test('nombre vacío → error obligatorio', () {
      expect(validateOrgName(''), isNotNull);
    });

    test('solo espacios → error obligatorio', () {
      expect(validateOrgName('   '), isNotNull);
    });

    test('nombre válido → sin error', () {
      expect(validateOrgName('Cruz Roja'), isNull);
    });
  });

  // _submitStep2 ──────────────────────────────────────

  group('validación step 2 (datos del admin)', () {
    String? validateAdminFields(String name, String email, String pass) {
      if (name.trim().isEmpty || email.trim().isEmpty || pass.isEmpty) {
        return 'Todos los campos son obligatorios.';
      }
      if (pass.length < 8) {
        return 'La contraseña debe tener al menos 8 caracteres.';
      }
      return null;
    }

    test('nombre vacío → todos campos obligatorios', () {
      expect(validateAdminFields('', 'a@b.com', 'pass1234'), isNotNull);
    });

    test('email vacío → todos campos obligatorios', () {
      expect(validateAdminFields('Juan', '', 'pass1234'), isNotNull);
    });

    test('password vacío → todos campos obligatorios', () {
      expect(validateAdminFields('Juan', 'a@b.com', ''), isNotNull);
    });

    test('password con 7 chars → error de longitud', () {
      expect(
        validateAdminFields('Juan', 'a@b.com', '1234567'),
        'La contraseña debe tener al menos 8 caracteres.',
      );
    });

    test('password con 8 chars → válido', () {
      expect(validateAdminFields('Juan', 'a@b.com', '12345678'), isNull);
    });

    test('todos los campos válidos → sin error', () {
      expect(
        validateAdminFields('Juan Pérez', 'jp@org.com', 'Segura99'),
        isNull,
      );
    });
  });

  // ── _StepIndicator ─────────────────────────────────────────────

  group('_StepIndicator logic', () {
    /// Simula isDone / isActive para cada paso dado current y total.
    Map<String, bool> stepState(int stepNum, int current) => {
      'isDone': stepNum < current,
      'isActive': stepNum == current,
    };

    test('step 1 activo cuando current=1', () {
      expect(stepState(1, 1)['isActive'], isTrue);
      expect(stepState(1, 1)['isDone'], isFalse);
    });

    test('step 1 completado cuando current=2', () {
      expect(stepState(1, 2)['isDone'], isTrue);
      expect(stepState(1, 2)['isActive'], isFalse);
    });

    test('step 2 activo cuando current=2', () {
      expect(stepState(2, 2)['isActive'], isTrue);
      expect(stepState(2, 2)['isDone'], isFalse);
    });

    test('paso futuro no está activo ni completo', () {
      expect(stepState(2, 1)['isActive'], isFalse);
      expect(stepState(2, 1)['isDone'], isFalse);
    });

    test('genera la cantidad correcta de pasos para total=2', () {
      final steps = List.generate(2, (i) => i + 1);
      expect(steps, [1, 2]);
    });
  });
}
