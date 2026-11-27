// test/widget/validation_feedback_widget_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/widgets/validation_feedback.dart';

void main() {
  group('announceValidation & validationLiveRegion', () {
    testWidgets(
      'anuncia inmediatamente en Android/plataformas con supportsAnnounce=true',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          late BuildContext capturedContext;
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(supportsAnnounce: true),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Builder(
                  builder: (context) {
                    capturedContext = context;
                    return validationLiveRegion(context, const Text('Banner'));
                  },
                ),
              ),
            ),
          );

          announceValidation(capturedContext, 'Faltan campos');
          await tester.pump();

          expect(
            tester.takeAnnouncements(),
            contains(isAccessibilityAnnouncement('Faltan campos')),
          );

          final semantics = tester.widget<Semantics>(
            find
                .ancestor(
                  of: find.text('Banner'),
                  matching: find.byType(Semantics),
                )
                .first,
          );
          expect(semantics.properties.liveRegion, isFalse);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('en iOS retrasa el anuncio 1 segundo antes de enviarlo', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        late BuildContext capturedContext;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(supportsAnnounce: true),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        announceValidation(capturedContext, 'Aviso iOS');
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeAnnouncements(), isEmpty);

        await tester.pump(const Duration(milliseconds: 600));
        expect(
          tester.takeAnnouncements(),
          contains(isAccessibilityAnnouncement('Aviso iOS')),
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'no envía anuncio cuando supportsAnnounce es false y activa liveRegion',
      (tester) async {
        late BuildContext capturedContext;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(supportsAnnounce: false),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Builder(
                builder: (context) {
                  capturedContext = context;
                  return validationLiveRegion(
                    context,
                    const Text('Banner web'),
                  );
                },
              ),
            ),
          ),
        );

        announceValidation(capturedContext, 'No debe anunciarse');
        await tester.pump(const Duration(seconds: 2));

        expect(tester.takeAnnouncements(), isEmpty);

        final semantics = tester.widget<Semantics>(
          find
              .ancestor(
                of: find.text('Banner web'),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(semantics.properties.liveRegion, isTrue);
      },
    );
  });

  group('revealFirstInvalid', () {
    testWidgets('no falla si ScrollController no tiene clientes adjuntos', (
      tester,
    ) async {
      final scroll = ScrollController();
      final focus = FocusNode();
      addTearDown(scroll.dispose);
      addTearDown(focus.dispose);

      revealFirstInvalid(scroll, focus);
      await tester.pumpAndSettle();

      expect(focus.hasFocus, isFalse);
    });

    testWidgets(
      'hace scroll al inicio y sale limpiamente si field es null o no está montado',
      (tester) async {
        final scroll = ScrollController();
        final unmountedFocus = FocusNode();
        addTearDown(scroll.dispose);
        addTearDown(unmountedFocus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                controller: scroll,
                itemCount: 30,
                itemBuilder: (_, i) =>
                    SizedBox(height: 80, child: Text('Item $i')),
              ),
            ),
          ),
        );

        scroll.jumpTo(600);
        await tester.pump();
        expect(scroll.offset, 600);

        revealFirstInvalid(scroll, unmountedFocus);
        await tester.pumpAndSettle();

        expect(scroll.offset, 0);
      },
    );

    testWidgets(
      'si el campo ya es visible desde arriba, anima al tope (0) y lo enfoca',
      (tester) async {
        final scroll = ScrollController();
        final topFocus = FocusNode();
        addTearDown(scroll.dispose);
        addTearDown(topFocus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                controller: scroll,
                children: [
                  const SizedBox(height: 60),
                  TextField(focusNode: topFocus),
                  const SizedBox(height: 1500),
                ],
              ),
            ),
          ),
        );

        scroll.jumpTo(20);
        await tester.pump();

        revealFirstInvalid(scroll, topFocus);
        await tester.pumpAndSettle();

        expect(scroll.offset, 0);
        expect(topFocus.hasFocus, isTrue);
      },
    );

    testWidgets(
      'si el campo está lejos fuera de pantalla, lo revela y lo enfoca',
      (tester) async {
        final scroll = ScrollController();
        final bottomFocus = FocusNode();
        addTearDown(scroll.dispose);
        addTearDown(bottomFocus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                controller: scroll,
                child: Column(
                  children: [
                    const SizedBox(height: 1800),
                    TextField(focusNode: bottomFocus),
                    const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(scroll.offset, 0);
        expect(bottomFocus.hasFocus, isFalse);

        revealFirstInvalid(scroll, bottomFocus);
        await tester.pumpAndSettle();

        expect(scroll.offset, greaterThan(0));
        expect(bottomFocus.hasFocus, isTrue);
      },
    );

    testWidgets(
      'cubre _visibleFromTheTop cuando el widget no tiene RenderAbstractViewport',
      (tester) async {
        final scroll = ScrollController();
        final standaloneFocus = FocusNode();
        addTearDown(scroll.dispose);
        addTearDown(standaloneFocus.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TextField(focusNode: standaloneFocus),
                  Expanded(
                    child: ListView(
                      controller: scroll,
                      children: const [SizedBox(height: 1000)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        revealFirstInvalid(scroll, standaloneFocus);
        await tester.pumpAndSettle();

        expect(standaloneFocus.hasFocus, isTrue);
      },
    );
  });
}
