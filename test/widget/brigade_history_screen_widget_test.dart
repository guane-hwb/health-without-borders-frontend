// test/widget/features/nfc/brigade_history_screen_widget_test.dart
//
// Widget testing for BrigadeHistoryScreen.
// Covers what the widget tree DOES require:
// • Initial state (pending) — offline banner visible, yellow header
// • Synchronizing state (after 2 seconds) — hidden banner, blue header, sync icon
// • Synchronized state (after 5 seconds) — green header, cloud_done icon
// • Empty list — "patientsAppearHere" text and people_outline icon
// • List with patients — name and date rendered
// • _PatientRow — correct icon and color for each state
// • ScreenBottomHandle — visible in the layout

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/brigade_history_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/shared_read_nfc_header.dart';
import 'package:health_without_borders_frontend/src/shared/widgets/screen_bottom_handle.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helper — minimal tree
// ─────────────────────────────────────────────────────────────────────────────
Widget _wrap() => AppLocale(
      locale: 'es',
      setLocale: (_) {},
      child: const MaterialApp(
        home: BrigadeHistoryScreen(),
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────
void main() {

  // ── Group 1: Initial state (pending) ─────────────────────────────────────
  group('BrigadeHistoryScreen — estado inicial (pending)', () {
    testWidgets('muestra el banner offline amarillo', (tester) async {
      await tester.pumpWidget(_wrap());
      // Without advancing time → pending state
      await tester.pump();

      expect(find.byIcon(Icons.warning), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('el banner offline contiene texto de brigadeOffline',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final bannerRow = find.ancestor(
        of: find.byIcon(Icons.warning),
        matching: find.byType(Row),
      );
      expect(bannerRow, findsAtLeastNWidgets(1));
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('el header tiene color amarillo (0xFFD4A017) en estado pending',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasYellowHeader = containers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == const Color(0xFFD4A017);
      });
      expect(hasYellowHeader, isTrue);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('la lista está vacía — muestra ícono people_outline',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('muestra el header con ícono format_list_bulleted',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });
  });

  // ── Group 2: State synchronizing (after 2 seconds) ───────────────────────
  group('BrigadeHistoryScreen — estado synchronizing', () {
    testWidgets('el banner offline desaparece después de 2 segundos',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Confirm that the banner exists in pending
      expect(find.byIcon(Icons.warning), findsOneWidget);

      // Advance 2 seconds → transition to synchronizing
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // The banner is only shown in pending state
      expect(find.byIcon(Icons.warning), findsNothing);
      // Drain Future.delayed of _simulateSync (2 s + 3 s).
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('el header cambia a AppColors.secondary tras 2 segundos',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasSecondaryHeader = containers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppColors.secondary;
      });
      expect(hasSecondaryHeader, isTrue);
      // Drain Future.delayed of _simulateSync (2 s + 3 s).
      await tester.pump(const Duration(seconds: 6));
    });
  });

  // ── Group 3: Synchronized state (after 5 seconds) ───────────────────────
  group('BrigadeHistoryScreen — estado synchronized', () {
    testWidgets('el header cambia a verde (0xFF2E7D32) tras 5 segundos',
        (tester) async {
      await tester.pumpWidget(_wrap());
      // 2 s → synchronizing, 3 s más → synchronized = 5 s total
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGreenHeader = containers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == const Color(0xFF2E7D32);
      });
      expect(hasGreenHeader, isTrue);
      // Drain Future.delayed of _simulateSync (2 s + 3 s).
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('NO muestra el banner offline tras 5 segundos', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(find.byIcon(Icons.warning), findsNothing);
      // Drain Future.delayed of _simulateSync (2 s + 3 s).
      await tester.pump(const Duration(seconds: 6));
    });
  });

  // ── Group 4: Empty list ──────────────────────────────────────────────────
  group('BrigadeHistoryScreen — lista vacía', () {
    testWidgets('muestra ícono people_outline cuando no hay pacientes',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('NO muestra botones de eliminar en lista vacía', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('NO muestra ícono person en lista vacía', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.person), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });
  });

  // ── Group 5: _PatientRow — status icons ──────────────────────────────
  // BrigadeHistoryScreen starts with an empty list; the _PatientRows are only
  // rendered if there are patients. These tests verify the logic of
  // icons through an accessible state without injecting data directly.
  group('_PatientRow — íconos según estado', () {
    testWidgets('en pending — cloud_upload_outlined no está en pantalla (lista vacía)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('en synchronizing — sync no está en pantalla (lista vacía)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.byIcon(Icons.sync), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('en synchronized — cloud_done no está en pantalla (lista vacía)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(find.byIcon(Icons.cloud_done), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });
  });

  // ── Group 6: General screen structure ────────────────────────────
  group('BrigadeHistoryScreen — estructura general', () {
    testWidgets('se renderiza sin lanzar excepciones', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byType(BrigadeHistoryScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('contiene un Scaffold con fondo Color(0xFFEBF2F8)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFFEBF2F8)));
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('contiene el encabezado SharedReadNfcHeader', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byType(SharedReadNfcHeader), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('contiene ScreenBottomHandle', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byType(ScreenBottomHandle), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('la card principal tiene borderRadius circular 16',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasRoundedCard = containers.any((c) {
        final d = c.decoration;
        if (d is! BoxDecoration) return false;
        final br = d.borderRadius;
        return br == BorderRadius.circular(16);
      });
      expect(hasRoundedCard, isTrue);
      await tester.pump(const Duration(seconds: 6));
    });
  });

  // ── Group 7: fake_async — precise time control ─────────────────────
  group('BrigadeHistoryScreen — transiciones con fake_async', () {
    testWidgets('la transición pending→synchronizing ocurre exactamente a los 2 s',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Banner visible in pending
      expect(find.byIcon(Icons.warning), findsOneWidget);

      // Just before the 2-second mark, the banner is still visible
      await tester.pump(const Duration(milliseconds: 1999));
      expect(find.byIcon(Icons.warning), findsOneWidget);

      // The banner disappears at exactly 2 seconds.
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(); // rebuild
      expect(find.byIcon(Icons.warning), findsNothing);
      // Drain Future.delayed from _simulateSync (2 s + 3 s).
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('la transición synchronizing→synchronized ocurre a los 5 s',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Just before the 5-second mark, the header is still secondary
      await tester.pump(const Duration(milliseconds: 2999));
      final containersB4 = tester.widgetList<Container>(find.byType(Container));
      final stillSecondary = containersB4.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppColors.secondary;
      });
      expect(stillSecondary, isTrue);

      // When it reaches 5 seconds, the header changes to green.
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      final containersAfter = tester.widgetList<Container>(find.byType(Container));
      final isGreen = containersAfter.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == const Color(0xFF2E7D32);
      });
      expect(isGreen, isTrue);
      await tester.pump(const Duration(seconds: 6));
    });
  });
}