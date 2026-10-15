// test/unit/web_session_wipe_test.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';

void main() {
  late Map<String, String> idb;
  late FlutterSecureStorage secure;
  late LocalDatabase db;

  AuthRepository build({required bool web}) => AuthRepository(
    apiClient: ApiClient(baseUrl: 'http://localhost'),
    secureStorage: secure,
    localDatabase: db,
    forceWeb: web,
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'hwb_sqlite_aes_key': 'a2V5',
    });
    secure = const FlutterSecureStorage();
    idb = <String, String>{
      'hwb_web_patient::p1': '{"patient_id":"p1","is_synced":0}',
      'hwb_web_chip::p1': '{}',
    };
    db = LocalDatabase.forTesting(
      secureStorage: secure,
      forceWeb: true,
      webGet: (k) async => idb[k],
      webSet: (k, v) async => idb[k] = v,
      webRemove: (k) async => idb.remove(k),
      webClearAll: () async => idb.clear(),
      webList: (p) async => idb.entries
          .where((e) => e.key.startsWith(p))
          .map((e) => MapEntry<String, String>(e.key, e.value))
          .toList(),
      webDeleteByPrefix: (p) async =>
          idb.removeWhere((k, _) => k.startsWith(p)),
    );
  });

  test('web: arrancar sin token borra la cola y la llave de la BD', () async {
    await build(web: true).restoreSession();

    expect(idb, isEmpty);
    expect(await secure.read(key: 'hwb_sqlite_aes_key'), isNull);
  });

  test('móvil: arrancar sin token NO borra pendientes', () async {
    await build(web: false).restoreSession();
    expect(idb, isNotEmpty);
  });

  test('web: logout borra PHI, llave y tokens', () async {
    final AuthRepository auth = build(web: true);
    await auth.logout();
    expect(idb, isEmpty);
    expect(await secure.read(key: 'hwb_sqlite_aes_key'), isNull);
  });
}
