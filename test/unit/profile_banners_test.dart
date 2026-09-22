// test/unit/profile_banners_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

void main() {
  group('Profile Banners – AppStrings Localizations (es)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('es'));

    test('isEs evaluates to true under Spanish locale settings', () {
      expect(s.isEs, isTrue);
    });
  });

  group('Profile Banners – AppStrings Localizations (en)', () {
    late AppStrings s;

    setUpAll(() => s = AppStrings.forTesting('en'));

    test('isEs evaluates to false under English locale settings', () {
      expect(s.isEs, isFalse);
    });
  });
}
