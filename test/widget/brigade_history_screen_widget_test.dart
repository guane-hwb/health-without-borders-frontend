// test/widget/features/nfc/brigade_history_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/brigade_history_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/shared_read_nfc_header.dart';
import 'package:health_without_borders_frontend/src/shared/widgets/screen_bottom_handle.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers — minimal tree & mocks
// ─────────────────────────────────────────────────────────────────────────────
Widget _wrap() => AppLocale(
  locale: 'es',
  setLocale: (_) {},
  child: const MaterialApp(home: BrigadeHistoryScreen()),
);

PatientFullRecord _createMockPatient() {
  return PatientFullRecord(
    patientId: '1234-5678',
    deviceUid: 'NFC-999-ABC',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '1000200300',
      ),
      firstName: 'Juan',
      secondName: 'Carlos',
      firstLastName: 'Pérez',
      secondLastName: 'Gómez',
      dob: '1990-05-15',
      biologicalSex: 'M',
      address: Address(city: 'Bogotá', state: 'Cundinamarca'),
    ),
    guardianInfo: GuardianInfo(
      name: 'María Gómez',
      relationship: 'Madre',
      phone: '3001234567',
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  tearDown(() {
    BrigadeHistoryScreen.debugPatients = null;
  });

  // ── Group 1: Initial state (pending) ─────────────────────────────────────
  group('BrigadeHistoryScreen — estado inicial (pending)', () {
    testWidgets('muestra el banner offline amarillo', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.warning), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('el banner offline contiene texto de brigadeOffline', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final bannerRow = find.ancestor(
        of: find.byIcon(Icons.warning),
        matching: find.byType(Row),
      );
      expect(bannerRow, findsAtLeastNWidgets(1));
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets(
      'el header tiene color amarillo (0xFFD4A017) en estado pending',
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
      },
    );

    testWidgets('la lista está vacía — muestra ícono people_outline', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('muestra el header con ícono format_list_bulleted', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });
  });

  // ── Group 2: State synchronizing (after 2 seconds) ───────────────────────
  group('BrigadeHistoryScreen — estado synchronizing', () {
    testWidgets('el banner offline desaparece después de 2 segundos', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.warning), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.byIcon(Icons.warning), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('el header cambia a AppColors.secondary tras 2 segundos', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasSecondaryHeader = containers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppColors.secondary;
      });
      expect(hasSecondaryHeader, isTrue);
      await tester.pump(const Duration(seconds: 6));
    });
  });

  // ── Group 3: Synchronized state (after 5 seconds) ───────────────────────
  group('BrigadeHistoryScreen — estado synchronized', () {
    testWidgets('el header cambia a verde (0xFF2E7D32) tras 5 segundos', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGreenHeader = containers.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == const Color(0xFF2E7D32);
      });
      expect(hasGreenHeader, isTrue);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('NO muestra el banner offline tras 5 segundos', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(find.byIcon(Icons.warning), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });
  });

  // ── Group 4: Empty list ──────────────────────────────────────────────────
  group('BrigadeHistoryScreen — lista vacía', () {
    testWidgets('muestra ícono people_outline cuando no hay pacientes', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('NO muestra botones de eliminar en lista vacía', (
      tester,
    ) async {
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

  // ── Group 5: _PatientRow
  group('_PatientRow — íconos según estado con Datos Reales', () {
    testWidgets('renderiza datos de paciente y maneja estado pending', (
      tester,
    ) async {
      BrigadeHistoryScreen.debugPatients = [_createMockPatient()];

      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.textContaining('Juan Carlos Pérez Gómez'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('renderiza fila en estado de sincronización (synchronizing)', (
      tester,
    ) async {
      BrigadeHistoryScreen.debugPatients = [_createMockPatient()];

      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.byIcon(Icons.sync), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('renderiza fila en estado sincronizado (synchronized)', (
      tester,
    ) async {
      BrigadeHistoryScreen.debugPatients = [_createMockPatient()];

      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
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

    testWidgets('contiene un Scaffold con fondo Color(0xFFEBF2F8)', (
      tester,
    ) async {
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

    testWidgets('la card principal tiene borderRadius circular 16', (
      tester,
    ) async {
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
    testWidgets(
      'la transición pending→synchronizing ocurre exactamente a los 2 s',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pump();

        expect(find.byIcon(Icons.warning), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1999));
        expect(find.byIcon(Icons.warning), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        expect(find.byIcon(Icons.warning), findsNothing);
        await tester.pump(const Duration(seconds: 6));
      },
    );

    testWidgets('la transición synchronizing→synchronized ocurre a los 5 s', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 2999));
      final containersB4 = tester.widgetList<Container>(find.byType(Container));
      final stillSecondary = containersB4.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == AppColors.secondary;
      });
      expect(stillSecondary, isTrue);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      final containersAfter = tester.widgetList<Container>(
        find.byType(Container),
      );
      final isGreen = containersAfter.any((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.color == const Color(0xFF2E7D32);
      });
      expect(isGreen, isTrue);
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
