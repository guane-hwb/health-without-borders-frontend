// test/unit/api_error_codes_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/network/api_error_codes.dart';

void main() {
  group('sync_in_progress', () {
    test('tiene mensaje propio que dice que se reintenta solo', () {
      expect(
        ApiErrorCode.describe(ApiErrorCode.syncInProgress, isEs: true),
        'Otro envío estaba guardando este paciente. Se reintentará '
        'automáticamente en unos instantes.',
      );
      expect(
        ApiErrorCode.describe(ApiErrorCode.syncInProgress, isEs: false),
        contains('retry automatically'),
      );
    });

    test('es el único code temporal', () {
      expect(ApiErrorCode.isTransient(ApiErrorCode.syncInProgress), isTrue);
      expect(ApiErrorCode.isTransient(ApiErrorCode.deviceUidConflict), isFalse);
      expect(ApiErrorCode.isTransient(null), isFalse);
    });
  });
}
