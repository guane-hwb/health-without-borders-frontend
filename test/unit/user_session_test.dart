// test/unit/features/auth/domain/user_session_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';

void main() {
  // ─────────────────────────────────────────────
  // UserSession.fromJson
  // ─────────────────────────────────────────────
  group('UserSession.fromJson', () {
    test('maps all fields when full_name is present', () {
      final json = {
        'id': '42',
        'email': 'juan@org.com',
        'full_name': 'Juan Carlos Pérez',
        'role': 'doctor',
        'organization_id': 'org-1',
        'organization_name': 'Clínica Norte',
        'is_active': true,
      };

      final session = UserSession.fromJson(json);

      expect(session.id, '42');
      expect(session.email, 'juan@org.com');
      expect(session.fullName, 'Juan Carlos Pérez');
      expect(session.role, UserRole.doctor);
      expect(session.organizationId, 'org-1');
      expect(session.organizationName, 'Clínica Norte');
      expect(session.isActive, isTrue);
    });

    test('humanizes email when full_name is null', () {
      final json = {
        'id': '1',
        'email': 'doctor.juan@org.com',
        'full_name': null,
        'role': 'doctor',
        'organization_id': 'org-1',
        'is_active': true,
      };

      final session = UserSession.fromJson(json);
      expect(session.fullName, 'Doctor Juan');
    });

    test('humanizes email when full_name is empty string', () {
      final json = {
        'id': '1',
        'email': 'nurse_maria@org.com',
        'full_name': '   ',
        'role': 'nurse',
        'organization_id': 'org-1',
      };

      final session = UserSession.fromJson(json);
      expect(session.fullName, 'Nurse Maria');
    });

    test('defaults is_active to true when absent', () {
      final json = {
        'id': '1',
        'email': 'a@b.com',
        'role': 'doctor',
        'organization_id': 'o1',
      };

      final session = UserSession.fromJson(json);
      expect(session.isActive, isTrue);
    });

    test('respects is_active = false', () {
      final json = {
        'id': '1',
        'email': 'a@b.com',
        'role': 'doctor',
        'organization_id': 'o1',
        'is_active': false,
      };

      final session = UserSession.fromJson(json);
      expect(session.isActive, isFalse);
    });

    test('defaults id / organizationId to empty string when null', () {
      final json = <String, dynamic>{'email': 'a@b.com', 'role': 'doctor'};

      final session = UserSession.fromJson(json);
      expect(session.id, '');
      expect(session.organizationId, '');
    });

    test('organizationName is null when absent', () {
      final json = {
        'id': '1',
        'email': 'a@b.com',
        'role': 'doctor',
        'organization_id': 'o1',
      };

      final session = UserSession.fromJson(json);
      expect(session.organizationName, isNull);
    });

    test('parses superadmin role', () {
      final session = UserSession.fromJson(_baseJson(role: 'superadmin'));
      expect(session.role, UserRole.superadmin);
    });

    test('parses org_admin role', () {
      final session = UserSession.fromJson(_baseJson(role: 'org_admin'));
      expect(session.role, UserRole.orgAdmin);
    });

    test('parses nurse role', () {
      final session = UserSession.fromJson(_baseJson(role: 'nurse'));
      expect(session.role, UserRole.nurse);
    });

    test('parses doctor role', () {
      final session = UserSession.fromJson(_baseJson(role: 'doctor'));
      expect(session.role, UserRole.doctor);
    });

    test('defaults unknown role to doctor', () {
      final session = UserSession.fromJson(_baseJson(role: 'unknown_role'));
      expect(session.role, UserRole.doctor);
    });

    test('defaults null role to doctor', () {
      final session = UserSession.fromJson(_baseJson(role: null));
      expect(session.role, UserRole.doctor);
    });
  });

  // ─────────────────────────────────────────────
  // UserSession.fromEmail
  // ─────────────────────────────────────────────
  group('UserSession.fromEmail', () {
    test('sets email and humanized fullName', () {
      final session = UserSession.fromEmail('doctor.juan@org.com');
      expect(session.email, 'doctor.juan@org.com');
      expect(session.fullName, 'Doctor Juan');
    });

    test('defaults id and organizationId to empty string', () {
      final session = UserSession.fromEmail('x@y.com');
      expect(session.id, '');
      expect(session.organizationId, '');
    });

    test('safe-defaults role to doctor', () {
      final session = UserSession.fromEmail('x@y.com');
      expect(session.role, UserRole.doctor);
    });

    test('isActive defaults to true', () {
      final session = UserSession.fromEmail('x@y.com');
      expect(session.isActive, isTrue);
    });
  });

  // ─────────────────────────────────────────────
  // shortName getter
  // ─────────────────────────────────────────────
  group('UserSession.shortName', () {
    test('returns first two words for three-word name', () {
      final session = _sessionWithName('Juan Carlos Pérez');
      expect(session.shortName, 'Juan Carlos');
    });

    test('returns first two words for two-word name', () {
      final session = _sessionWithName('Ana López');
      expect(session.shortName, 'Ana López');
    });

    test('returns full name when single word', () {
      final session = _sessionWithName('Madonna');
      expect(session.shortName, 'Madonna');
    });
  });

  // ─────────────────────────────────────────────
  // _humanizeEmail
  // ─────────────────────────────────────────────
  group('_humanizeEmail (via fromEmail / fromJson)', () {
    test('handles dot separator', () {
      expect(UserSession.fromEmail('john.doe@x.com').fullName, 'John Doe');
    });

    test('handles underscore separator', () {
      expect(UserSession.fromEmail('john_doe@x.com').fullName, 'John Doe');
    });

    test('handles hyphen separator', () {
      expect(UserSession.fromEmail('john-doe@x.com').fullName, 'John Doe');
    });

    test('handles mixed separators', () {
      expect(
        UserSession.fromEmail('dr.john_doe-jr@x.com').fullName,
        'Dr John Doe Jr',
      );
    });

    test('capitalizes single-word local part', () {
      expect(UserSession.fromEmail('admin@x.com').fullName, 'Admin');
    });

    test('collapses consecutive separators', () {
      expect(UserSession.fromEmail('a..b@x.com').fullName, 'A B');
    });
  });

  // ─────────────────────────────────────────────
  // UserRole permission getters
  // ─────────────────────────────────────────────
  group('UserRole.isAdmin', () {
    test('orgAdmin is admin', () => expect(UserRole.orgAdmin.isAdmin, isTrue));
    test(
      'superadmin is admin',
      () => expect(UserRole.superadmin.isAdmin, isTrue),
    );
    test('doctor is not admin', () => expect(UserRole.doctor.isAdmin, isFalse));
    test('nurse is not admin', () => expect(UserRole.nurse.isAdmin, isFalse));
  });

  group('UserRole.isSuperadmin', () {
    test('superadmin', () => expect(UserRole.superadmin.isSuperadmin, isTrue));
    test('orgAdmin', () => expect(UserRole.orgAdmin.isSuperadmin, isFalse));
    test('doctor', () => expect(UserRole.doctor.isSuperadmin, isFalse));
    test('nurse', () => expect(UserRole.nurse.isSuperadmin, isFalse));
  });

  group('UserRole.canReadPatients', () {
    test(
      'doctor → true',
      () => expect(UserRole.doctor.canReadPatients, isTrue),
    );
    test('nurse → true', () => expect(UserRole.nurse.canReadPatients, isTrue));
    test(
      'orgAdmin → true',
      () => expect(UserRole.orgAdmin.canReadPatients, isTrue),
    );
    test(
      'superadmin → false',
      () => expect(UserRole.superadmin.canReadPatients, isFalse),
    );
  });

  group('UserRole.canRegisterPatient', () {
    test(
      'doctor → true',
      () => expect(UserRole.doctor.canRegisterPatient, isTrue),
    );
    test(
      'nurse → true',
      () => expect(UserRole.nurse.canRegisterPatient, isTrue),
    );
    test(
      'orgAdmin → false',
      () => expect(UserRole.orgAdmin.canRegisterPatient, isFalse),
    );
    test(
      'superadmin → false',
      () => expect(UserRole.superadmin.canRegisterPatient, isFalse),
    );
  });

  group('UserRole.canAddConsultation', () {
    test(
      'doctor → true',
      () => expect(UserRole.doctor.canAddConsultation, isTrue),
    );
    test(
      'nurse → false',
      () => expect(UserRole.nurse.canAddConsultation, isFalse),
    );
    test(
      'orgAdmin → false',
      () => expect(UserRole.orgAdmin.canAddConsultation, isFalse),
    );
    test(
      'superadmin → false',
      () => expect(UserRole.superadmin.canAddConsultation, isFalse),
    );
  });

  group('UserRole.canAddVaccine', () {
    test('doctor → true', () => expect(UserRole.doctor.canAddVaccine, isTrue));
    test('nurse → true', () => expect(UserRole.nurse.canAddVaccine, isTrue));
    test(
      'orgAdmin → false',
      () => expect(UserRole.orgAdmin.canAddVaccine, isFalse),
    );
    test(
      'superadmin → false',
      () => expect(UserRole.superadmin.canAddVaccine, isFalse),
    );
  });

  group('UserRole.canSyncPatient', () {
    test('doctor → true', () => expect(UserRole.doctor.canSyncPatient, isTrue));
    test('nurse → true', () => expect(UserRole.nurse.canSyncPatient, isTrue));
    test(
      'orgAdmin → false',
      () => expect(UserRole.orgAdmin.canSyncPatient, isFalse),
    );
    test(
      'superadmin → false',
      () => expect(UserRole.superadmin.canSyncPatient, isFalse),
    );
  });

  group('UserRole.canManageUsers', () {
    test(
      'orgAdmin → true',
      () => expect(UserRole.orgAdmin.canManageUsers, isTrue),
    );
    test(
      'superadmin → true',
      () => expect(UserRole.superadmin.canManageUsers, isTrue),
    );
    test(
      'doctor → false',
      () => expect(UserRole.doctor.canManageUsers, isFalse),
    );
    test('nurse → false', () => expect(UserRole.nurse.canManageUsers, isFalse));
  });

  group('UserRole.canViewAnalytics', () {
    test(
      'orgAdmin → true',
      () => expect(UserRole.orgAdmin.canViewAnalytics, isTrue),
    );
    test(
      'superadmin → true',
      () => expect(UserRole.superadmin.canViewAnalytics, isTrue),
    );
    test(
      'doctor → false',
      () => expect(UserRole.doctor.canViewAnalytics, isFalse),
    );
    test(
      'nurse → false',
      () => expect(UserRole.nurse.canViewAnalytics, isFalse),
    );
  });

  group('UserRole.canScanNfc', () {
    test('doctor → true', () => expect(UserRole.doctor.canScanNfc, isTrue));
    test('nurse → true', () => expect(UserRole.nurse.canScanNfc, isTrue));
    test(
      'orgAdmin → false',
      () => expect(UserRole.orgAdmin.canScanNfc, isFalse),
    );
    test(
      'superadmin → false',
      () => expect(UserRole.superadmin.canScanNfc, isFalse),
    );
  });

  group('UserRole.canSearchPatient', () {
    test(
      'doctor → true',
      () => expect(UserRole.doctor.canSearchPatient, isTrue),
    );
    test('nurse → true', () => expect(UserRole.nurse.canSearchPatient, isTrue));
    test(
      'orgAdmin → true',
      () => expect(UserRole.orgAdmin.canSearchPatient, isTrue),
    );
    test(
      'superadmin → false',
      () => expect(UserRole.superadmin.canSearchPatient, isFalse),
    );
  });

  group('UserSession.toJson', () {
    test('round-trips a través de fromJson preservando campos', () {
      final original = UserSession(
        id: '9',
        email: 'nurse@hwb.org',
        fullName: 'Nurse Real',
        role: UserRole.nurse,
        organizationId: 'org-2',
        organizationName: 'Clinic 2',
        isActive: true,
      );

      final restored = UserSession.fromJson(original.toJson());

      expect(restored.id, '9');
      expect(restored.email, 'nurse@hwb.org');
      expect(restored.fullName, 'Nurse Real');
      expect(restored.role, UserRole.nurse);
      expect(restored.organizationId, 'org-2');
      expect(restored.organizationName, 'Clinic 2');
      expect(restored.isActive, isTrue);
    });

    test('serializa el rol como wire string (org_admin), no enum name', () {
      final session = UserSession(
        id: '1',
        email: 'a@b.com',
        fullName: 'Admin',
        role: UserRole.orgAdmin,
        organizationId: 'o1',
      );

      expect(session.toJson()['role'], 'org_admin');
    });
  });

  group('UserRole.wireValue', () {
    test('cada rol mapea a su string de backend', () {
      expect(UserRole.superadmin.wireValue, 'superadmin');
      expect(UserRole.orgAdmin.wireValue, 'org_admin');
      expect(UserRole.doctor.wireValue, 'doctor');
      expect(UserRole.nurse.wireValue, 'nurse');
    });

    test('wireValue round-trips vía fromJson para todos los roles', () {
      for (final role in UserRole.values) {
        final json = <String, dynamic>{
          'id': '1',
          'email': 'a@b.com',
          'full_name': 'X',
          'role': role.wireValue,
          'organization_id': 'o1',
        };
        expect(UserSession.fromJson(json).role, role);
      }
    });
  });
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

Map<String, dynamic> _baseJson({String? role}) => {
  'id': '1',
  'email': 'test@org.com',
  'full_name': 'Test User',
  'role': role,
  'organization_id': 'org-1',
};

UserSession _sessionWithName(String name) => UserSession(
  id: '1',
  email: 'a@b.com',
  fullName: name,
  role: UserRole.doctor,
  organizationId: 'o1',
);
