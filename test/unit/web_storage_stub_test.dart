// test/unit/web_storage_stub_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/storage/web_storage_stub.dart';

void main() {
  group('WebStorageStub (Non-web platforms fallback)', () {
    test('getWebStorageItem siempre retorna null', () async {
      final result = await getWebStorageItem('any_key');
      expect(result, isNull);
    });

    test('setWebStorageItem se ejecuta sin lanzar excepciones', () async {
      await expectLater(setWebStorageItem('key', 'value'), completes);
    });

    test('removeWebStorageItem se ejecuta sin lanzar excepciones', () async {
      await expectLater(removeWebStorageItem('key'), completes);
    });

    test('clearAllWebStorage se ejecuta sin lanzar excepciones', () async {
      await expectLater(clearAllWebStorage(), completes);
    });

    test('listWebStorageEntries siempre retorna una lista vacía', () async {
      final entries = await listWebStorageEntries('prefix_');
      expect(entries, isEmpty);
      expect(entries, isA<List<MapEntry<String, String>>>());
    });

    test(
      'deleteWebStorageByPrefix se ejecuta sin lanzar excepciones',
      () async {
        await expectLater(deleteWebStorageByPrefix('prefix_'), completes);
      },
    );
  });
}
