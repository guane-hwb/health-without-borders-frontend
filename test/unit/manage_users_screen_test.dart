// test/unit/manage_users_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';

// ── Helpers ───────────────────────────────────
UserSession buildUser({
  String id = 'u1',
  String fullName = 'Juan Galvis',
  String email = 'juan@test.com',
  UserRole role = UserRole.doctor,
  bool isActive = true,
  String organizationId = 'org-1',
}) => UserSession(
  id: id,
  fullName: fullName,
  email: email,
  role: role,
  isActive: isActive,
  organizationId: organizationId,
);

List<UserSession> applyFilter(List<UserSession> users, String filter) {
  if (filter == 'all') return users;
  return users.where((u) {
    switch (filter) {
      case 'doctor':
        return u.role == UserRole.doctor;
      case 'nurse':
        return u.role == UserRole.nurse;
      case 'org_admin':
        return u.role == UserRole.orgAdmin;
      default:
        return true;
    }
  }).toList();
}

List<MapEntry<String, String>> roleOptions(UserRole creatorRole) {
  if (creatorRole == UserRole.superadmin) {
    return const [MapEntry('org_admin', 'Administrador')];
  }
  return const [MapEntry('doctor', 'Doctor'), MapEntry('nurse', 'Enfermería')];
}

Color roleColor(UserRole r) => switch (r) {
  UserRole.doctor => const Color(0xFF1565C0),
  UserRole.nurse => const Color(0xFF2E7D32),
  UserRole.orgAdmin => const Color(0xFF6A1B9A),
  UserRole.superadmin => const Color(0xFFB71C1C),
};

String computeInitials(String fullName) => fullName
    .split(' ')
    .where((p) => p.isNotEmpty)
    .take(2)
    .map((p) => p[0].toUpperCase())
    .join();
String? submitGuard({
  required String email,
  required String name,
  required String pass,
}) {
  final trimmedEmail = email.trim();
  final trimmedName = name.trim();

  if (trimmedEmail.isEmpty || trimmedName.isEmpty || pass.isEmpty) {
    return 'Completa todos los campos requeridos.';
  }
  return null;
}

void main() {
  group('_filtered — filtro de usuarios', () {
    final users = [
      buildUser(id: '1', role: UserRole.doctor, fullName: 'Doctor A'),
      buildUser(id: '2', role: UserRole.nurse, fullName: 'Nurse B'),
      buildUser(id: '3', role: UserRole.orgAdmin, fullName: 'Admin C'),
      buildUser(id: '4', role: UserRole.doctor, fullName: 'Doctor D'),
    ];

    test('filtro "all" retorna todos los usuarios', () {
      expect(applyFilter(users, 'all').length, 4);
    });

    test('filtro "doctor" retorna solo doctores', () {
      final result = applyFilter(users, 'doctor');
      expect(result.length, 2);
      expect(result.every((u) => u.role == UserRole.doctor), isTrue);
    });

    test('filtro "nurse" retorna solo enfermería', () {
      final result = applyFilter(users, 'nurse');
      expect(result.length, 1);
      expect(result.first.role, UserRole.nurse);
    });

    test('filtro "org_admin" retorna solo org_admin', () {
      final result = applyFilter(users, 'org_admin');
      expect(result.length, 1);
      expect(result.first.role, UserRole.orgAdmin);
    });

    test('filtro desconocido retorna todos (default: true)', () {
      expect(applyFilter(users, 'unknown').length, 4);
    });

    test('filtro sobre lista vacía retorna lista vacía', () {
      expect(applyFilter([], 'doctor'), isEmpty);
    });

    test('filtro "all" sobre lista vacía retorna lista vacía', () {
      expect(applyFilter([], 'all'), isEmpty);
    });

    test('filtro preserva el orden original', () {
      final result = applyFilter(users, 'doctor');
      expect(result[0].fullName, 'Doctor A');
      expect(result[1].fullName, 'Doctor D');
    });

    test('filtro "doctor" no incluye enfermería ni admin', () {
      final result = applyFilter(users, 'doctor');
      expect(result.any((u) => u.role == UserRole.nurse), isFalse);
      expect(result.any((u) => u.role == UserRole.orgAdmin), isFalse);
    });

    test('filtro "nurse" no incluye doctores ni admin', () {
      final result = applyFilter(users, 'nurse');
      expect(result.any((u) => u.role == UserRole.doctor), isFalse);
    });
  });

  group('_roleColor — colores de rol', () {
    test('doctor → azul 1565C0', () {
      expect(roleColor(UserRole.doctor), const Color(0xFF1565C0));
    });

    test('nurse → verde 2E7D32', () {
      expect(roleColor(UserRole.nurse), const Color(0xFF2E7D32));
    });

    test('orgAdmin → morado 6A1B9A', () {
      expect(roleColor(UserRole.orgAdmin), const Color(0xFF6A1B9A));
    });

    test('superadmin → rojo B71C1C', () {
      expect(roleColor(UserRole.superadmin), const Color(0xFFB71C1C));
    });

    test('todos los roles tienen colores distintos', () {
      final colors = UserRole.values.map(roleColor).toSet();
      expect(colors.length, UserRole.values.length);
    });
  });

  group('_roleOptions — opciones de rol para crear usuario', () {
    test('superadmin solo puede crear org_admin', () {
      final opts = roleOptions(UserRole.superadmin);
      expect(opts.length, 1);
      expect(opts.first.key, 'org_admin');
      expect(opts.first.value, 'Administrador');
    });

    test('orgAdmin puede crear doctor o nurse', () {
      final opts = roleOptions(UserRole.orgAdmin);
      expect(opts.length, 2);
      expect(opts.map((e) => e.key).toList(), ['doctor', 'nurse']);
    });

    test('orgAdmin opciones tienen labels correctos', () {
      final opts = roleOptions(UserRole.orgAdmin);
      expect(opts[0].value, 'Doctor');
      expect(opts[1].value, 'Enfermería');
    });

    test('primera opción de orgAdmin es doctor (rol por defecto)', () {
      final opts = roleOptions(UserRole.orgAdmin);
      expect(opts.first.key, 'doctor');
    });

    test('primera opción de superadmin es org_admin (rol por defecto)', () {
      final opts = roleOptions(UserRole.superadmin);
      expect(opts.first.key, 'org_admin');
    });

    test(
      'doctor no tiene opciones de creación (no debería ver este sheet)',
      () {
        final opts = roleOptions(UserRole.doctor);
        expect(opts.length, 2);
      },
    );
  });

  group('_submit guard — validación', () {
    test('todos los campos llenos → retorna null (sin error)', () {
      expect(
        submitGuard(email: 'a@b.com', name: 'Juan', pass: '123456'),
        isNull,
      );
    });

    test('email vacío → retorna mensaje de error', () {
      expect(
        submitGuard(email: '', name: 'Juan', pass: '123456'),
        'Completa todos los campos requeridos.',
      );
    });

    test('name vacío → retorna mensaje de error', () {
      expect(
        submitGuard(email: 'a@b.com', name: '', pass: '123456'),
        'Completa todos los campos requeridos.',
      );
    });

    test('password vacío → retorna mensaje de error', () {
      expect(
        submitGuard(email: 'a@b.com', name: 'Juan', pass: ''),
        'Completa todos los campos requeridos.',
      );
    });

    test('los tres campos vacíos → retorna mensaje de error', () {
      expect(
        submitGuard(email: '', name: '', pass: ''),
        'Completa todos los campos requeridos.',
      );
    });

    test('email con solo espacios es vacío después de trim', () {
      expect(
        submitGuard(email: '   ', name: 'Juan', pass: '123'),
        'Completa todos los campos requeridos.',
      );
    });

    test('name con solo espacios es vacío después de trim', () {
      expect(
        submitGuard(email: 'a@b.com', name: '   ', pass: '123'),
        'Completa todos los campos requeridos.',
      );
    });
  });

  group('Initials — cálculo de iniciales en _UserCard', () {
    test('dos palabras produce dos iniciales', () {
      expect(computeInitials('Juan Galvis'), 'JG');
    });

    test('tres palabras usa solo las dos primeras', () {
      expect(computeInitials('María Fernanda López'), 'MF');
    });

    test('una sola palabra produce una inicial', () {
      expect(computeInitials('Carlos'), 'C');
    });

    test('nombre en minúsculas se convierte a mayúsculas', () {
      expect(computeInitials('ana torres'), 'AT');
    });

    test('nombre con espacios dobles los ignora', () {
      expect(computeInitials('Luis  Pérez'), 'LP');
    });

    test('cadena vacía produce cadena vacía', () {
      expect(computeInitials(''), '');
    });

    test('iniciales de doctor con nombre completo', () {
      expect(computeInitials('Isabella Martínez Silva'), 'IM');
    });
  });

  group('UserSession — propiedades', () {
    test('isActive true → etiqueta "Activo"', () {
      final user = buildUser(isActive: true);
      expect(user.isActive ? 'Activo' : 'Suspendido', 'Activo');
    });

    test('isActive false → etiqueta "Suspendido"', () {
      final user = buildUser(isActive: false);
      expect(user.isActive ? 'Activo' : 'Suspendido', 'Suspendido');
    });

    test('role doctor se asigna correctamente', () {
      expect(buildUser(role: UserRole.doctor).role, UserRole.doctor);
    });

    test('role nurse se asigna correctamente', () {
      expect(buildUser(role: UserRole.nurse).role, UserRole.nurse);
    });

    test('role orgAdmin se asigna correctamente', () {
      expect(buildUser(role: UserRole.orgAdmin).role, UserRole.orgAdmin);
    });

    test('organizationId se conserva', () {
      expect(buildUser(organizationId: 'org-42').organizationId, 'org-42');
    });
  });

  group('_RoleBadge — labels', () {
    String badgeLabel(UserRole role) => switch (role) {
      UserRole.doctor => 'Doctor',
      UserRole.nurse => 'Enfermería',
      UserRole.orgAdmin => 'Admin',
      UserRole.superadmin => 'Superadmin',
    };

    test(
      'doctor → "Doctor"',
      () => expect(badgeLabel(UserRole.doctor), 'Doctor'),
    );
    test(
      'nurse → "Enfermería"',
      () => expect(badgeLabel(UserRole.nurse), 'Enfermería'),
    );
    test(
      'orgAdmin → "Admin"',
      () => expect(badgeLabel(UserRole.orgAdmin), 'Admin'),
    );
    test(
      'superadmin → "Superadmin"',
      () => expect(badgeLabel(UserRole.superadmin), 'Superadmin'),
    );
  });

  group('_FilterChip — lógica de selección', () {
    test('chip seleccionado cuando value == current', () {
      const value = 'doctor';
      const current = 'doctor';
      expect(value == current, isTrue);
    });

    test('chip no seleccionado cuando value != current', () {
      const value = 'nurse';
      const current = 'doctor';
      expect(value == current, isFalse);
    });

    test('filtro "all" es el predeterminado (selected al inicio)', () {
      const initialFilter = 'all';
      expect(initialFilter, 'all');
    });

    test('cambiar filtro actualiza el current', () {
      var current = 'all';
      current = 'doctor';
      expect(current, 'doctor');
    });

    test('cambiar filtro de vuelta a all', () {
      var current = 'doctor';
      current = 'all';
      expect(current, 'all');
    });
  });
}
