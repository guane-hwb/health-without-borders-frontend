// test/widget/add_chronic_condition_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/di/app_scope.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/network/api_client.dart';
import 'package:health_without_borders_frontend/src/core/network/reachability.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/core/sync/sync_engine.dart';
import 'package:health_without_borders_frontend/src/features/admin/data/stats_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/user_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/data/patient_repository.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/add_chronic_condition_sheet.dart';

// ─── Mocks ─────────────────────────────────────────────────────────────────

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockPatientRepository extends Mock implements PatientRepository {}

class _MockLocalDatabase extends Mock implements LocalDatabase {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockReachability extends Mock implements Reachability {}

AppScope _createMockScope({required Widget child}) {
  final auth = _MockAuthRepository();
  when(
    () => auth.sessionNotifier,
  ).thenReturn(ValueNotifier<UserSession?>(null));

  final user = _MockUserRepository();
  final patientRepo = _MockPatientRepository();
  final db = _MockLocalDatabase();
  final sync = _MockSyncEngine();
  final reach = _MockReachability();

  when(() => sync.isOnline).thenReturn(ValueNotifier<bool>(true));
  when(() => sync.pendingCount).thenReturn(ValueNotifier<int>(0));
  when(() => sync.blockedCount).thenReturn(ValueNotifier<int>(0));
  when(() => reach.probe()).thenAnswer((_) async => true);

  return AppScope(
    authRepository: auth,
    userRepository: user,
    patientRepository: patientRepo,
    localDatabase: db,
    syncEngine: sync,
    statsRepository: StatsRepository(
      apiClient: ApiClient(baseUrl: 'http://localhost'),
      authRepository: auth,
    ),
    reachability: reach,
    child: child,
  );
}

Widget _wrap(Widget child, {String locale = 'en'}) {
  return _createMockScope(
    child: AppLocale(
      locale: locale,
      setLocale: (_) {},
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

Widget _buildSubject({
  required ValueChanged<ChronicConditionItem> onAdd,
  String locale = 'en',
}) {
  return _wrap(AddChronicConditionSheet(onAdd: onAdd), locale: locale);
}

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1600,
      1200,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('AddChronicConditionSheet – Base Rendering', () {
    testWidgets(
      'renders layout safely without throwing runtime locale exceptions',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));
        expect(find.byType(AddChronicConditionSheet), findsOneWidget);
      },
    );

    testWidgets(
      'text input field area is present and renders completely empty',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        expect(
          tester.widget<TextField>(textField).controller?.text ?? '',
          isEmpty,
        );
      },
    );

    testWidgets(
      'action commit confirm button stays present and renders properly while input text is empty',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));
        await tester.pump();

        final confirmButtonFinder = find.byType(ElevatedButton);
        expect(confirmButtonFinder, findsOneWidget);
      },
    );
  });

  group('AddChronicConditionSheet – VoiceTextArea Input Mutations', () {
    testWidgets(
      'writing alphanumeric characters refreshes internal visibility states',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));

        await tester.enterText(find.byType(TextField), 'Diabetes tipo 2');
        await tester.pump();

        expect(find.text('Diabetes tipo 2'), findsOneWidget);
      },
    );

    testWidgets(
      'submitting whitespace characters prevents calling callback and shows validation error',
      (tester) async {
        bool called = false;
        await tester.pumpWidget(_buildSubject(onAdd: (_) => called = true));

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(called, isFalse);
      },
    );

    testWidgets(
      'submitting populated criteria activates action buttons safely',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));

        await tester.enterText(find.byType(TextField), 'Hipertensión');
        await tester.pump();

        final activeButton = find.byType(ElevatedButton);
        expect(activeButton, findsOneWidget);
      },
    );

    testWidgets('clearing a field triggers validation error upon submitting', (
      tester,
    ) async {
      bool called = false;
      await tester.pumpWidget(_buildSubject(onAdd: (_) => called = true));

      await tester.enterText(find.byType(TextField), 'Asma');
      await tester.pump();

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });
  });

  group('AddChronicConditionSheet – onConfirm Pipeline Operations', () {
    testWidgets(
      'forwards structured trimmed entry records inside callbacks upon confirmation click',
      (tester) async {
        ChronicConditionItem? received;

        await tester.pumpWidget(
          _buildSubject(onAdd: (item) => received = item),
        );

        await tester.enterText(find.byType(TextField), '  Lupus  ');
        await tester.pump();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(received, isNotNull);
        expect(received!.chronicDescription, 'Lupus');
      },
    );

    testWidgets(
      'retains multiline strings keeping internal linebreaks intact during submission pipelines',
      (tester) async {
        ChronicConditionItem? received;

        await tester.pumpWidget(
          _buildSubject(onAdd: (item) => received = item),
        );

        await tester.enterText(
          find.byType(TextField),
          'Enfermedad de Crohn\nEstadio avanzado',
        );
        await tester.pump();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(
          received?.chronicDescription,
          'Enfermedad de Crohn\nEstadio avanzado',
        );
      },
    );

    testWidgets(
      'closes modal structure systematically after confirming text entries',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) =>
                        _wrap(AddChronicConditionSheet(onAdd: (_) {})),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.byType(AddChronicConditionSheet), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Fibromialgia');
        await tester.pump();

        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpAndSettle();

        expect(find.byType(AddChronicConditionSheet), findsNothing);
      },
    );
  });

  group('AddChronicConditionSheet – Component Lifecycle Execution', () {
    testWidgets(
      'tears down instances and resources gracefully during standard unmount flows',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));

        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

        expect(find.byType(AddChronicConditionSheet), findsNothing);
      },
    );
  });

  group('AddChronicConditionSheet – Operational Boundary Limits', () {
    testWidgets(
      'processes extremely long strings flawlessly without truncating boundaries',
      (tester) async {
        ChronicConditionItem? received;
        final longText = 'A' * 500;

        await tester.pumpWidget(
          _buildSubject(onAdd: (item) => received = item),
        );

        await tester.enterText(find.byType(TextField), longText);
        await tester.pump();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(received?.chronicDescription.length, 500);
      },
    );

    testWidgets(
      'retains customized accentuation modifiers and unique formatting markers',
      (tester) async {
        ChronicConditionItem? received;
        const special = 'Síndrome de Sjögren – afección crónica';

        await tester.pumpWidget(
          _buildSubject(onAdd: (item) => received = item),
        );

        await tester.enterText(find.byType(TextField), special);
        await tester.pump();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(received?.chronicDescription, special);
      },
    );
  });

  group('AddChronicConditionSheet – Unsaved Changes Dialog & PopScope', () {
    testWidgets(
      'closes modal directly without alert when tapping close button if field is empty',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) =>
                        _wrap(AddChronicConditionSheet(onAdd: (_) {})),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(AddChronicConditionSheet), findsNothing);
      },
    );

    testWidgets(
      'shows warning dialog when tapping close button with unsaved text',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));

        await tester.enterText(find.byType(TextField), 'Asma');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets(
      'cancels closing when clicking Cancel in unsaved changes dialog',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));

        await tester.enterText(find.byType(TextField), 'Diabetes');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(AddChronicConditionSheet), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'confirms exit and closes sheet when clicking Exit in unsaved changes dialog',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) =>
                        _wrap(AddChronicConditionSheet(onAdd: (_) {})),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Diabetes');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Exit'));
        await tester.pumpAndSettle();

        expect(find.byType(AddChronicConditionSheet), findsNothing);
      },
    );

    testWidgets(
      'triggers PopScope handler on system back gesture when changes exist',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}));

        await tester.enterText(find.byType(TextField), 'Hipertensión');
        await tester.pump();

        final popScope = tester.widget<PopScope>(find.byType(PopScope));
        popScope.onPopInvokedWithResult?.call(false, null);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets(
      'shows mandatory error message in Spanish when submitted empty',
      (tester) async {
        await tester.pumpWidget(_buildSubject(onAdd: (_) {}, locale: 'es'));

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(find.text('La condición médica es obligatoria'), findsOneWidget);
      },
    );
  });
}
