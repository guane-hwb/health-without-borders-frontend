// test/unit/app_version_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/network/app_version.dart';

void main() {
  group('appVersionHeaderValue', () {
    test('agrega la plataforma a la versión', () {
      expect(
        appVersionHeaderValue(
          version: '1.2.3+45',
          isWeb: false,
          platform: TargetPlatform.android,
        ),
        '1.2.3+45 (android)',
      );
      expect(
        appVersionHeaderValue(
          version: '1.2.3+45',
          isWeb: false,
          platform: TargetPlatform.iOS,
        ),
        '1.2.3+45 (ios)',
      );
      expect(
        appVersionHeaderValue(version: '1.2.3', isWeb: true),
        '1.2.3 (web)',
      );
    });

    test('en otras plataformas envía solo la versión', () {
      expect(
        appVersionHeaderValue(
          version: '1.0.0+1',
          isWeb: false,
          platform: TargetPlatform.linux,
        ),
        '1.0.0+1',
      );
    });

    test('sin versión, o con una mal formada, no hay cabecera', () {
      for (final String version in <String>[
        '',
        '1.2',
        'v1.2.3',
        '1.2.3+',
        '1.2.3 (android)',
        '1.2.3+45\nx',
      ]) {
        expect(
          appVersionHeaderValue(version: version, isWeb: true),
          isNull,
          reason: version,
        );
      }
    });

    test('una build de test no trae HWB_APP_VERSION', () {
      expect(appVersionHeaderValue(), isNull);
    });
  });
}
