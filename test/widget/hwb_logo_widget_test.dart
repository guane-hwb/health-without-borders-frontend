// test/widget/hwb_logo_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/shared/widgets/hwb_logo.dart';

void main() {
  Future<void> pumpLogo(
    WidgetTester tester, {
    double size = 48,
    bool elevated = false,
    bool onDark = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HwbLogo(size: size, elevated: elevated, onDark: onDark),
        ),
      ),
    );
  }

  Finder logoDescendant(Type type) =>
      find.descendant(of: find.byType(HwbLogo), matching: find.byType(type));

  group('HwbLogo — layout', () {
    testWidgets('sizes the outer SizedBox to match size', (tester) async {
      await pumpLogo(tester, size: 80);

      final sizedBox = tester.widget<SizedBox>(logoDescendant(SizedBox));
      expect(sizedBox.width, equals(80));
      expect(sizedBox.height, equals(80));
    });

    testWidgets('centers its content inside a Stack', (tester) async {
      await pumpLogo(tester, onDark: true);

      final stack = tester.widget<Stack>(logoDescendant(Stack));
      expect(stack.alignment, equals(Alignment.center));
    });

    testWidgets('always renders the logo image with matching dimensions', (
      tester,
    ) async {
      await pumpLogo(tester, size: 64);

      final image = tester.widget<Image>(logoDescendant(Image));
      expect(image.width, equals(64));
      expect(image.height, equals(64));
      expect(image.fit, equals(BoxFit.cover));
      expect(
        (image.image as AssetImage).assetName,
        equals('assets/images/app-icon.png'),
      );
    });

    testWidgets('clips the image with a radius proportional to size', (
      tester,
    ) async {
      await pumpLogo(tester, size: 100);

      final clipRRect = tester.widget<ClipRRect>(logoDescendant(ClipRRect));
      expect(clipRRect.borderRadius, equals(BorderRadius.circular(100 * 0.22)));
    });
  });

  group('HwbLogo — onDark background', () {
    testWidgets('does not render a background container when onDark is false', (
      tester,
    ) async {
      await pumpLogo(tester, onDark: false);

      expect(logoDescendant(Container), findsNothing);
    });

    testWidgets(
      'renders a white rounded background container when onDark is true',
      (tester) async {
        await pumpLogo(tester, size: 40, onDark: true);

        final container = tester.widget<Container>(logoDescendant(Container));
        final decoration = container.decoration! as BoxDecoration;

        expect(container.constraints?.maxWidth, equals(40 * 0.75));
        expect(container.constraints?.maxHeight, equals(40 * 0.75));
        expect(decoration.color, equals(Colors.white));
        expect(
          decoration.borderRadius,
          equals(BorderRadius.circular(40 * 0.22 * 0.8)),
        );
      },
    );

    testWidgets('has no boxShadow when onDark is true but elevated is false', (
      tester,
    ) async {
      await pumpLogo(tester, onDark: true, elevated: false);

      final container = tester.widget<Container>(logoDescendant(Container));
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.boxShadow, isNull);
    });

    testWidgets(
      'adds a single boxShadow when onDark and elevated are both true',
      (tester) async {
        await pumpLogo(tester, size: 120, onDark: true, elevated: true);

        final container = tester.widget<Container>(logoDescendant(Container));
        final decoration = container.decoration! as BoxDecoration;

        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow, hasLength(1));

        final shadow = decoration.boxShadow!.single;
        expect(shadow.color, equals(AppColors.primary.withValues(alpha: 0.3)));
        expect(shadow.blurRadius, equals(120 * 0.16));
        expect(shadow.offset, equals(Offset(0, 120 * 0.06)));
      },
    );

    testWidgets('elevated has no visible effect while onDark is false', (
      tester,
    ) async {
      await pumpLogo(tester, onDark: false, elevated: true);

      expect(logoDescendant(Container), findsNothing);
    });
  });

  group('HwbLogo — factory constructors render correctly', () {
    testWidgets('HwbLogo.small renders the onDark background at size 32', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HwbLogo.small())),
      );

      expect(logoDescendant(Container), findsOneWidget);
      final sizedBox = tester.widget<SizedBox>(logoDescendant(SizedBox));
      expect(sizedBox.width, equals(32));
    });

    testWidgets('HwbLogo.medium renders without the onDark background', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HwbLogo.medium())),
      );

      expect(logoDescendant(Container), findsNothing);
      final sizedBox = tester.widget<SizedBox>(logoDescendant(SizedBox));
      expect(sizedBox.width, equals(60));
    });

    testWidgets(
      'HwbLogo.large renders no container since onDark defaults to false',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: HwbLogo.large())),
        );

        expect(logoDescendant(Container), findsNothing);
        final sizedBox = tester.widget<SizedBox>(logoDescendant(SizedBox));
        expect(sizedBox.width, equals(120));
      },
    );
  });
}
