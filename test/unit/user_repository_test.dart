// test/unit/features/auth/data/user_repository_test.dart

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthRepository
// ─────────────────────────────────────────────────────────────────────────────.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({required super.apiClient});

  String? tokenToReturn;
  Exception? errorToThrow;

  @override
  Future<String> getAccessToken({bool forceRefresh = false}) async {
    if (errorToThrow != null) throw errorToThrow!;
    return tokenToReturn ?? 'fake-token';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const String kToken = 'fake-token';
const String kBaseUrl = 'https://api.test';

http.Response _ok(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

http.Response _err(int status, [String detail = 'error']) => http.Response(
  jsonEncode({'detail': detail}),
  status,
  headers: {'content-type': 'application/json'},
);

final Map<String, dynamic> kUserJson = {
  'id': 'user-1',
  'email': 'doctor@clinic.com',
  'full_name': 'Dr. House',
  'role': 'doctor',
  'organization_id': 'org-1',
  'organization_name': 'Clínica Norte',
  'is_active': true,
};

final Map<String, dynamic> kOrgJson = {
  'id': 'org-1',
  'name': 'Clínica Norte',
  'is_active': true,
};

// ─────────────────────────────────────────────────────────────────────────────
// Helper: builds SUT wiring a custom MockClient
// ─────────────────────────────────────────────────────────────────────────────

({UserRepository repo, FakeAuthRepository fakeAuth}) _buildSut(
  MockClient mockClient,
) {
  final apiClient = ApiClient(baseUrl: kBaseUrl, client: mockClient);
  final fakeAuth = FakeAuthRepository(apiClient: apiClient)
    ..tokenToReturn = kToken;
  final repo = UserRepository(apiClient: apiClient, authRepository: fakeAuth);
  return (repo: repo, fakeAuth: fakeAuth);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('OrgSummary', () {
    group('constructor', () {
      test('asigna todos los campos correctamente', () {
        const org = OrgSummary(id: 'x', name: 'Y', isActive: false);
        expect(org.id, 'x');
        expect(org.name, 'Y');
        expect(org.isActive, isFalse);
      });
    });

    group('fromJson', () {
      test('parsea todos los campos cuando vienen completos', () {
        final org = OrgSummary.fromJson(kOrgJson);
        expect(org.id, 'org-1');
        expect(org.name, 'Clínica Norte');
        expect(org.isActive, isTrue);
      });

      test('is_active es true por defecto cuando la clave está ausente', () {
        final org = OrgSummary.fromJson({'id': 'org-2', 'name': 'Sin flag'});
        expect(org.isActive, isTrue);
      });

      test('respeta is_active=false cuando viene explícito', () {
        final org = OrgSummary.fromJson({
          'id': 'org-3',
          'name': 'Inactiva',
          'is_active': false,
        });
        expect(org.isActive, isFalse);
      });
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // _authHeaders
  // ══════════════════════════════════════════════════════════════════════════

  group('_authHeaders', () {
    test(
      'construye el header Authorization: Bearer <token> correcto',
      () async {
        String? capturedAuthHeader;

        final client = MockClient((request) async {
          capturedAuthHeader = request.headers['authorization'];
          return _ok(kUserJson);
        });

        final (:repo, :fakeAuth) = _buildSut(client);
        fakeAuth.tokenToReturn = 'my-special-token';

        await repo.getMe();

        expect(capturedAuthHeader, 'Bearer my-special-token');
      },
    );

    test('propaga la excepción si getAccessToken falla', () async {
      final client = MockClient((_) async => _ok(kUserJson));
      final (:repo, :fakeAuth) = _buildSut(client);
      fakeAuth.errorToThrow = ApiException('Session expired', statusCode: 401);

      await expectLater(repo.getMe(), throwsA(isA<ApiException>()));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // getMe — GET /api/v1/users/me
  // ══════════════════════════════════════════════════════════════════════════

  group('getMe', () {
    test(
      'llama a GET /api/v1/users/me y retorna UserSession mapeado',
      () async {
        String? capturedPath;

        final client = MockClient((request) async {
          capturedPath = request.url.path;
          return _ok(kUserJson);
        });

        final (:repo, fakeAuth: _) = _buildSut(client);
        final result = await repo.getMe();

        expect(capturedPath, '/api/v1/users/me');
        expect(result, isA<UserSession>());
        expect(result.id, 'user-1');
        expect(result.email, 'doctor@clinic.com');
        expect(result.fullName, 'Dr. House');
        expect(result.role, UserRole.doctor);
        expect(result.organizationId, 'org-1');
      },
    );

    test('propaga ApiException en respuesta 4xx/5xx', () async {
      final client = MockClient((_) async => _err(401, 'Unauthorized'));
      final (:repo, fakeAuth: _) = _buildSut(client);

      await expectLater(
        repo.getMe(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('propaga errores de red (timeout, socket)', () async {
      final client = MockClient((_) async => throw Exception('Network error'));
      final (:repo, fakeAuth: _) = _buildSut(client);

      await expectLater(repo.getMe(), throwsException);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // listUsers — GET /api/v1/users/
  // ══════════════════════════════════════════════════════════════════════════

  group('listUsers', () {
    test('llama a GET /api/v1/users/ y retorna lista de UserSession', () async {
      String? capturedPath;

      final client = MockClient((request) async {
        capturedPath = request.url.path;
        return _ok([kUserJson, kUserJson]);
      });

      final (:repo, fakeAuth: _) = _buildSut(client);
      final result = await repo.listUsers();

      expect(capturedPath, '/api/v1/users/');
      expect(result, hasLength(2));
    });

    test('retorna lista vacía cuando la respuesta es []', () async {
      final client = MockClient((_) async => _ok(<dynamic>[]));
      final (:repo, fakeAuth: _) = _buildSut(client);

      final result = await repo.listUsers();
      expect(result, isEmpty);
    });

    test('filtra elementos que no sean Map<String, dynamic>', () async {
      final client = MockClient(
        (_) async => _ok([kUserJson, 'invalid', null, 42]),
      );
      final (:repo, fakeAuth: _) = _buildSut(client);

      final result = await repo.listUsers();
      expect(result, hasLength(1));
    });

    test('propaga ApiException en respuesta 4xx/5xx', () async {
      final client = MockClient((_) async => _err(403, 'Forbidden'));
      final (:repo, fakeAuth: _) = _buildSut(client);

      await expectLater(
        repo.listUsers(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // createUser — POST /api/v1/users/
  // ══════════════════════════════════════════════════════════════════════════

  group('createUser', () {
    test(
      'envía POST /api/v1/users/ con el body correcto (sin organizationId)',
      () async {
        Map<String, dynamic>? capturedBody;
        String? capturedPath;

        final client = MockClient((request) async {
          capturedPath = request.url.path;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _ok(kUserJson);
        });

        final (:repo, fakeAuth: _) = _buildSut(client);
        await repo.createUser(
          email: 'nurse@clinic.com',
          fullName: 'Nurse Joy',
          role: 'nurse',
          password: 'pass123',
        );

        expect(capturedPath, '/api/v1/users/');
        expect(capturedBody, containsPair('email', 'nurse@clinic.com'));
        expect(capturedBody, containsPair('full_name', 'Nurse Joy'));
        expect(capturedBody, containsPair('role', 'nurse'));
        expect(capturedBody, containsPair('password', 'pass123'));
        expect(capturedBody!.containsKey('organization_id'), isTrue);
        expect(capturedBody!['organization_id'], isNull);
      },
    );

    test('incluye organization_id cuando se proporciona', () async {
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _ok(kUserJson);
      });

      final (:repo, fakeAuth: _) = _buildSut(client);
      await repo.createUser(
        email: 'admin@clinic.com',
        fullName: 'Admin',
        role: 'org_admin',
        password: 'secret',
        organizationId: 'org-99',
      );

      expect(capturedBody, containsPair('organization_id', 'org-99'));
    });

    test('retorna UserSession correctamente mapeado', () async {
      final client = MockClient((_) async => _ok(kUserJson));
      final (:repo, fakeAuth: _) = _buildSut(client);

      final result = await repo.createUser(
        email: 'x@x.com',
        fullName: 'X',
        role: 'doctor',
        password: 'p',
      );

      expect(result, isA<UserSession>());
      expect(result.id, 'user-1');
    });

    test('propaga ApiException en respuesta 4xx/5xx', () async {
      final client = MockClient((_) async => _err(409, 'Conflict'));
      final (:repo, fakeAuth: _) = _buildSut(client);

      await expectLater(
        repo.createUser(
          email: 'dup@x.com',
          fullName: 'Dup',
          role: 'doctor',
          password: 'p',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // listOrganizations — GET /api/v1/organizations/
  // ══════════════════════════════════════════════════════════════════════════

  group('listOrganizations', () {
    test(
      'llama a GET /api/v1/organizations/ y retorna lista de OrgSummary',
      () async {
        String? capturedPath;

        final client = MockClient((request) async {
          capturedPath = request.url.path;
          return _ok([kOrgJson, kOrgJson]);
        });

        final (:repo, fakeAuth: _) = _buildSut(client);
        final result = await repo.listOrganizations();

        expect(capturedPath, '/api/v1/organizations/');
        expect(result, hasLength(2));
      },
    );

    test('retorna lista vacía cuando la respuesta es []', () async {
      final client = MockClient((_) async => _ok(<dynamic>[]));
      final (:repo, fakeAuth: _) = _buildSut(client);

      expect(await repo.listOrganizations(), isEmpty);
    });

    test('filtra elementos que no sean Map<String, dynamic>', () async {
      final client = MockClient((_) async => _ok([kOrgJson, null, 'bad', 99]));
      final (:repo, fakeAuth: _) = _buildSut(client);

      final result = await repo.listOrganizations();
      expect(result, hasLength(1));
    });

    test('propaga ApiException en respuesta 4xx/5xx', () async {
      final client = MockClient((_) async => _err(403, 'Forbidden'));
      final (:repo, fakeAuth: _) = _buildSut(client);

      await expectLater(repo.listOrganizations(), throwsA(isA<ApiException>()));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // createOrganization — POST /api/v1/organizations/
  // ══════════════════════════════════════════════════════════════════════════

  group('createOrganization', () {
    test(
      'envía POST /api/v1/organizations/ con name e is_active=true',
      () async {
        Map<String, dynamic>? capturedBody;
        String? capturedPath;

        final client = MockClient((request) async {
          capturedPath = request.url.path;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _ok(kOrgJson);
        });

        final (:repo, fakeAuth: _) = _buildSut(client);
        await repo.createOrganization('Nueva Clínica');

        expect(capturedPath, '/api/v1/organizations/');
        expect(capturedBody, containsPair('name', 'Nueva Clínica'));
        expect(capturedBody, containsPair('is_active', true));
      },
    );

    test('retorna OrgSummary correctamente mapeado', () async {
      final client = MockClient((_) async => _ok(kOrgJson));
      final (:repo, fakeAuth: _) = _buildSut(client);

      final result = await repo.createOrganization('Cualquier Nombre');

      expect(result, isA<OrgSummary>());
      expect(result.id, 'org-1');
      expect(result.name, 'Clínica Norte');
      expect(result.isActive, isTrue);
    });

    test('propaga ApiException en respuesta 4xx/5xx', () async {
      final client = MockClient((_) async => _err(500, 'Server Error'));
      final (:repo, fakeAuth: _) = _buildSut(client);

      await expectLater(
        repo.createOrganization('Fallo'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // createOrgAdminUser
  // ══════════════════════════════════════════════════════════════════════════

  group('createOrgAdminUser', () {
    test(
      'envía POST /api/v1/users/ con role=org_admin y todos los parámetros',
      () async {
        Map<String, dynamic>? capturedBody;

        final client = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _ok(kUserJson);
        });

        final (:repo, fakeAuth: _) = _buildSut(client);
        await repo.createOrgAdminUser(
          fullName: 'Admin Org',
          email: 'admin@org.com',
          password: 'adminPass',
          organizationId: 'org-55',
        );

        expect(capturedBody, containsPair('role', 'org_admin'));
        expect(capturedBody, containsPair('email', 'admin@org.com'));
        expect(capturedBody, containsPair('full_name', 'Admin Org'));
        expect(capturedBody, containsPair('password', 'adminPass'));
        expect(capturedBody, containsPair('organization_id', 'org-55'));
      },
    );

    test('retorna UserSession correctamente mapeado', () async {
      final client = MockClient((_) async => _ok(kUserJson));
      final (:repo, fakeAuth: _) = _buildSut(client);

      final result = await repo.createOrgAdminUser(
        fullName: 'Admin',
        email: 'a@b.com',
        password: 'pw',
        organizationId: 'org-1',
      );

      expect(result, isA<UserSession>());
      expect(result.id, 'user-1');
    });

    test('propaga ApiException en respuesta 4xx/5xx', () async {
      final client = MockClient((_) async => _err(422, 'Unprocessable'));
      final (:repo, fakeAuth: _) = _buildSut(client);

      await expectLater(
        repo.createOrgAdminUser(
          fullName: 'X',
          email: 'x@x.com',
          password: 'p',
          organizationId: 'org-1',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // createOrganizationWithAdmin (atomic org + admin)
  // ══════════════════════════════════════════════════════════════════════════

  group('createOrganizationWithAdmin', () {
    test('envía POST /organizations/ con name y bloque admin', () async {
      Map<String, dynamic>? capturedBody;
      String? capturedPath;

      final client = MockClient((request) async {
        capturedPath = request.url.path;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _ok(kOrgJson);
      });

      final (:repo, fakeAuth: _) = _buildSut(client);
      await repo.createOrganizationWithAdmin(
        name: 'Org C',
        adminFullName: 'Admin C',
        adminEmail: 'admin_c@org.com',
        adminPassword: 'provisional123',
      );

      expect(capturedPath, '/api/v1/organizations/');
      expect(capturedBody, containsPair('name', 'Org C'));
      final admin = capturedBody!['admin'] as Map<String, dynamic>;
      expect(admin, containsPair('full_name', 'Admin C'));
      expect(admin, containsPair('email', 'admin_c@org.com'));
      expect(admin, containsPair('password', 'provisional123'));
    });

    test('mapea user_count y patient_count del response', () async {
      final client = MockClient(
        (_) async => _ok({
          'id': 'org-9',
          'name': 'Org C',
          'is_active': true,
          'user_count': 1,
          'patient_count': 0,
        }),
      );
      final (:repo, fakeAuth: _) = _buildSut(client);

      final result = await repo.createOrganizationWithAdmin(
        name: 'Org C',
        adminFullName: 'A',
        adminEmail: 'a@b.com',
        adminPassword: 'password1',
      );

      expect(result.userCount, 1);
      expect(result.patientCount, 0);
      expect(result.isEmpty, isFalse);
    });

    test('propaga ApiException en 400', () async {
      final client = MockClient((_) async => _err(400, 'exists'));
      final (:repo, fakeAuth: _) = _buildSut(client);

      await expectLater(
        repo.createOrganizationWithAdmin(
          name: 'Dup',
          adminFullName: 'A',
          adminEmail: 'a@b.com',
          adminPassword: 'password1',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // setOrganizationActive / deleteOrganization
  // ══════════════════════════════════════════════════════════════════════════

  group('setOrganizationActive', () {
    test('envía PATCH /organizations/{id} con is_active', () async {
      Map<String, dynamic>? capturedBody;
      String? capturedPath;
      String? capturedMethod;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _ok({'id': 'org-1', 'name': 'X', 'is_active': false});
      });

      final (:repo, fakeAuth: _) = _buildSut(client);
      final result = await repo.setOrganizationActive('org-1', false);

      expect(capturedMethod, 'PATCH');
      expect(capturedPath, '/api/v1/organizations/org-1');
      expect(capturedBody, containsPair('is_active', false));
      expect(result.isActive, isFalse);
    });
  });

  group('deleteOrganization', () {
    test('envía DELETE /organizations/{id} y completa en 204', () async {
      String? capturedMethod;
      String? capturedPath;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;
        return http.Response('', 204);
      });

      final (:repo, fakeAuth: _) = _buildSut(client);
      await repo.deleteOrganization('org-1');

      expect(capturedMethod, 'DELETE');
      expect(capturedPath, '/api/v1/organizations/org-1');
    });

    test('propaga ApiException en 409 (organización no vacía)', () async {
      final client = MockClient((_) async => _err(409, 'not empty'));
      final (:repo, fakeAuth: _) = _buildSut(client);

      await expectLater(
        repo.deleteOrganization('org-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // setUserActive / deleteUser
  // ══════════════════════════════════════════════════════════════════════════

  group('setUserActive', () {
    test('envía PATCH /users/{id} con is_active', () async {
      Map<String, dynamic>? capturedBody;
      String? capturedPath;

      final client = MockClient((request) async {
        capturedPath = request.url.path;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _ok(kUserJson);
      });

      final (:repo, fakeAuth: _) = _buildSut(client);
      await repo.setUserActive('user-1', false);

      expect(capturedPath, '/api/v1/users/user-1');
      expect(capturedBody, containsPair('is_active', false));
    });
  });

  group('deleteUser', () {
    test('envía DELETE /users/{id} y completa en 204', () async {
      String? capturedMethod;
      String? capturedPath;

      final client = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;
        return http.Response('', 204);
      });

      final (:repo, fakeAuth: _) = _buildSut(client);
      await repo.deleteUser('user-1');

      expect(capturedMethod, 'DELETE');
      expect(capturedPath, '/api/v1/users/user-1');
    });

    test('propaga ApiException en 409 (último admin)', () async {
      final client = MockClient((_) async => _err(409, 'last admin'));
      final (:repo, fakeAuth: _) = _buildSut(client);

      await expectLater(
        repo.deleteUser('user-1'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
