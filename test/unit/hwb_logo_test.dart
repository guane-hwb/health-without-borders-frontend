// test/unit/hwb_logo_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:health_without_borders_frontend/src/shared/widgets/hwb_logo.dart';

void main() {
  group('HwbLogo — constructor defaults', () {
    test('uses default size, elevated and onDark values', () {
      const logo = HwbLogo();
      expect(logo.size, equals(48));
      expect(logo.elevated, isFalse);
      expect(logo.onDark, isFalse);
    });

    test('accepts explicit values for size, elevated and onDark', () {
      const logo = HwbLogo(size: 90, elevated: true, onDark: true);
      expect(logo.size, equals(90));
      expect(logo.elevated, isTrue);
      expect(logo.onDark, isTrue);
    });
  });

  group('HwbLogo — factory constructors', () {
    test('small() sets size 32, onDark true and elevated false', () {
      final logo = HwbLogo.small();
      expect(logo.size, equals(32));
      expect(logo.onDark, isTrue);
      expect(logo.elevated, isFalse);
    });

    test('medium() sets size 60, onDark false and elevated false', () {
      final logo = HwbLogo.medium();
      expect(logo.size, equals(60));
      expect(logo.onDark, isFalse);
      expect(logo.elevated, isFalse);
    });

    test('large() sets size 120, elevated true and onDark false', () {
      final logo = HwbLogo.large();
      expect(logo.size, equals(120));
      expect(logo.elevated, isTrue);
      expect(logo.onDark, isFalse);
    });

    test('factory constructors forward the provided key', () {
      const key = Key('logo-key');
      final logo = HwbLogo.small(key: key);
      expect(logo.key, equals(key));
    });
  });
}
