// test/widget/nfc_save_flow_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/nfc_save_flow.dart';

class _AppLocaleProvider extends StatefulWidget {
  const _AppLocaleProvider({required this.locale, required this.child});
  final String locale;
  final Widget child;

  @override
  State<_AppLocaleProvider> createState() => _AppLocaleProviderState();
}

class _AppLocaleProviderState extends State<_AppLocaleProvider> {
  late String _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
  }

  @override
  Widget build(BuildContext context) {
    return AppLocale(
      locale: _locale,
      setLocale: (l) => setState(() => _locale = l),
      child: widget.child,
    );
  }
}

Widget _buildTestableWidget({required Widget child, String locale = 'es'}) {
  return _AppLocaleProvider(
    locale: locale,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  final s = AppStrings.forTesting('es');

  /// Set the viewport size to tablet dimensions (1600x1200) to give the BottomSheet
  /// sufficient vertical space, preventing layout overflow exceptions during testing.
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

  group('NfcSaveFlow Widget Tests', () {
    testWidgets(
      'Initial State (_SS.put): Renders initial text and NFC indicator icon',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showNfcSaveFlow(context),
                child: const Text('Abrir Flujo'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir Flujo'));
        await tester.pumpAndSettle();

        expect(find.text(s.putOnWristband), findsOneWidget);
        expect(find.text(s.placeWristband), findsOneWidget);
        expect(find.byIcon(Icons.nfc), findsOneWidget);
        expect(find.text(s.startWriting), findsOneWidget);
      },
    );

    testWidgets(
      'No callback fallback flow: Transitions to success state after a simulated 3-second delay',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showNfcSaveFlow(context),
                child: const Text('Abrir Flujo'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir Flujo'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(s.startWriting));
        await tester.pump();

        expect(find.text(s.syncingServer), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text(s.successRegistration), findsOneWidget);
      },
    );

    testWidgets(
      'Success Flow (_SS.success): Executes synchronous context callback immediately and advances state',
      (tester) async {
        bool syncCalled = false;

        await tester.pumpWidget(
          _buildTestableWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showNfcSaveFlow(
                  context,
                  onSync: () async {
                    syncCalled = true;
                    return true;
                  },
                ),
                child: const Text('Abrir Flujo'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir Flujo'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(s.startWriting));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(syncCalled, isTrue);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text(s.patientSavedSynced), findsOneWidget);
        expect(find.text(s.goHome), findsOneWidget);
      },
    );

    testWidgets(
      'Error Flow (_SS.error): Catches callback exceptions, displays error state, and allows user retry',
      (tester) async {
        int executions = 0;

        await tester.pumpWidget(
          _buildTestableWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showNfcSaveFlow(
                  context,
                  onSync: () async {
                    executions++;
                    if (executions == 1) {
                      throw Exception('Error de Conexión NFC');
                    }
                    return true;
                  },
                ),
                child: const Text('Abrir Flujo'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir Flujo'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(s.startWriting));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text(s.syncFailed), findsOneWidget);
        expect(find.text('Exception: Error de Conexión NFC'), findsOneWidget);

        await tester.tap(find.text(s.retry));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(executions, equals(2));
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text(s.successRegistration), findsOneWidget);
      },
    );

    testWidgets(
      'Cancel action button inside error view closes sheet modal completely',
      (tester) async {
        await tester.pumpWidget(
          _buildTestableWidget(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showNfcSaveFlow(
                  context,
                  onSync: () async {
                    throw Exception('Abortar');
                  },
                ),
                child: const Text('Abrir Flujo'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir Flujo'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(s.startWriting));
        await tester.pumpAndSettle();

        await tester.tap(find.text(s.cancel));
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text(s.syncFailed), findsNothing);
      },
    );
  });
}
