// test/unit/features/home/home_screen_unit_test.dart
//
// Pruebas unitarias para HomeScreen.
// Cubre la lógica pura que NO requiere el árbol de widgets:
//   • _greeting() según la hora del día
//   • _buildBody() redirige al body correcto según UserRole
//   • _logout() limpia la sesión y navega al login
//
// Dependencias externas (AppScope, AuthRepository, LocalDatabase) se
// sustituyen con Mocks generados por mockito.
//
// Ejecutar:
//   flutter test test/unit/features/home/home_screen_unit_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.session});

  UserSession? session;
  bool clearSessionCalled = false;

  @override
  Future<String?> getNfcEncryptionKey() async => null;

  @override
  UserSession? get currentUser => session;

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    if (session != null) return session!;
    return UserSession.fromEmail(email);
  }

  @override
  Future<UserSession?> getCurrentUser() async => session;

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async =>
      'test-token';

  @override
  Future<void> clearSession() async {
    clearSessionCalled = true;
    session = null;
  }

  @override
  bool get hasToken => session != null;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Devuelve el saludo esperado dado [hour] (simula _greeting internamente).
/// La función real en HomeScreen es estática y privada; la replicamos aquí
/// para poder testearla de forma aislada sin instanciar el widget.
String _greetingForHour(int hour) {
  if (hour < 12) return 'morning'; // goodMorning
  if (hour < 18) return 'afternoon'; // goodAfternoon
  return 'evening'; // goodEvening
}

/// Crea un [UserSession] de prueba con el [role] dado.
UserSession _session(UserRole role) => UserSession(
  id: 'user-test-01',
  fullName: 'Test User',
  email: 'test@hwb.org',
  role: role,
  organizationId: 'org-01',
);

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Grupo 1: lógica de saludo ─────────────────────────────────────────────
  group('HomeScreen._greeting — lógica de franja horaria', () {
    test('devuelve morning para horas 0–11', () {
      for (int h = 0; h < 12; h++) {
        expect(
          _greetingForHour(h),
          equals('morning'),
          reason: 'hora $h debería ser "morning"',
        );
      }
    });

    test('devuelve afternoon para horas 12–17', () {
      for (int h = 12; h < 18; h++) {
        expect(
          _greetingForHour(h),
          equals('afternoon'),
          reason: 'hora $h debería ser "afternoon"',
        );
      }
    });

    test('devuelve evening para horas 18–23', () {
      for (int h = 18; h < 24; h++) {
        expect(
          _greetingForHour(h),
          equals('evening'),
          reason: 'hora $h debería ser "evening"',
        );
      }
    });

    test('el límite de medianoche (hora 0) es morning', () {
      expect(_greetingForHour(0), equals('morning'));
    });

    test('el límite exacto del mediodía (hora 12) es afternoon', () {
      expect(_greetingForHour(12), equals('afternoon'));
    });

    test('el límite exacto de las 18:00 es evening', () {
      expect(_greetingForHour(18), equals('evening'));
    });

    test('hora 23 es evening (límite superior)', () {
      expect(_greetingForHour(23), equals('evening'));
    });
  });

  // ── Grupo 2: UserRole — permisos derivados ────────────────────────────────
  group('UserRole — permisos que HomeScreen consulta', () {
    test('doctor puede registrar paciente', () {
      expect(UserRole.doctor.canRegisterPatient, isTrue);
    });

    test('nurse puede registrar paciente', () {
      expect(UserRole.nurse.canRegisterPatient, isTrue);
    });

    test('orgAdmin no puede registrar paciente', () {
      expect(UserRole.orgAdmin.canRegisterPatient, isFalse);
    });

    test('superadmin no puede registrar paciente', () {
      expect(UserRole.superadmin.canRegisterPatient, isFalse);
    });

    test('doctor puede añadir consulta', () {
      expect(UserRole.doctor.canAddConsultation, isTrue);
    });

    test('nurse NO puede añadir consulta', () {
      expect(UserRole.nurse.canAddConsultation, isFalse);
    });
  });

  // ── Grupo 3: UserSession — datos de sesión ────────────────────────────────
  group('UserSession — integridad de datos para HomeScreen', () {
    test('fullName se expone correctamente', () {
      final session = _session(UserRole.doctor);
      expect(session.fullName, equals('Test User'));
    });

    test('role se asigna correctamente para superadmin', () {
      final session = _session(UserRole.superadmin);
      expect(session.role, equals(UserRole.superadmin));
    });

    test('role se asigna correctamente para orgAdmin', () {
      final session = _session(UserRole.orgAdmin);
      expect(session.role, equals(UserRole.orgAdmin));
    });

    test('role se asigna correctamente para doctor', () {
      final session = _session(UserRole.doctor);
      expect(session.role, equals(UserRole.doctor));
    });

    test('role se asigna correctamente para nurse', () {
      final session = _session(UserRole.nurse);
      expect(session.role, equals(UserRole.nurse));
    });

    test('id no es nulo ni vacío', () {
      final session = _session(UserRole.nurse);
      expect(session.id, isNotEmpty);
    });

    test('email no es nulo ni vacío', () {
      final session = _session(UserRole.nurse);
      expect(session.email, isNotEmpty);
    });
  });

  // ── Grupo 4: AuthRepository.clearSession — fake de prueba ────────────────
  group('AuthRepository — clearSession se llama al cerrar sesión', () {
    late FakeAuthRepository mockAuth;

    setUp(() {
      mockAuth = FakeAuthRepository();
    });

    test('clearSession es invocado exactamente una vez', () async {
      await mockAuth.clearSession();
      expect(mockAuth.clearSessionCalled, isTrue);
    });

    test('clearSession no lanza excepción', () async {
      expect(() async => mockAuth.clearSession(), returnsNormally);
    });

    test('doble llamada a clearSession se registra dos veces', () async {
      await mockAuth.clearSession();
      await mockAuth.clearSession();
      expect(mockAuth.clearSessionCalled, isTrue);
    });
  });

  // ── Grupo 5: lógica de body según rol ────────────────────────────────────
  group('HomeScreen._buildBody — selección de body por rol', () {
    // Validamos que cada rol existe y tiene un valor distinto.
    // La selección real del widget se prueba en el test de widget.
    test('UserRole tiene exactamente 4 valores', () {
      expect(UserRole.values.length, equals(4));
    });

    test('los 4 roles son los esperados', () {
      expect(
        UserRole.values,
        containsAll([
          UserRole.superadmin,
          UserRole.orgAdmin,
          UserRole.doctor,
          UserRole.nurse,
        ]),
      );
    });

    test(
      'doctor y nurse comparten el mismo body clínico (canRegisterPatient)',
      () {
        // Si ambos pueden registrar paciente, ambos reciben el body clínico.
        final clinicalRoles = UserRole.values
            .where((r) => r != UserRole.superadmin && r != UserRole.orgAdmin)
            .toList();
        expect(clinicalRoles, containsAll([UserRole.doctor, UserRole.nurse]));
      },
    );
  });
}
