// test/widget/edit_chronic_personal_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_chronic_personal_sheet.dart';

final _s = AppStrings.forTesting('es');

class _LocaleWrapper extends StatefulWidget {
  const _LocaleWrapper({required this.locale, required this.child});
  final String locale;
  final Widget child;

  @override
  State<_LocaleWrapper> createState() => _LocaleWrapperState();
}

class _LocaleWrapperState extends State<_LocaleWrapper> {
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

Widget _wrap({
  required String title,
  String? currentValue,
  required ValueChanged<String?> onConfirm,
  String locale = 'es',
}) {
  return _LocaleWrapper(
    locale: locale,
    child: MaterialApp(
      home: Scaffold(
        body: EditChronicPersonalSheet(
          title: title,
          currentValue: currentValue,
          onConfirm: onConfirm,
        ),
      ),
    ),
  );
}

void main() {
  group('EditChronicPersonalSheet – Initial Rendering', () {
    testWidgets('Displays the title passed as a parameter', (tester) async {
      await tester.pumpWidget(
        _wrap(
          title: 'Enfermedades crónicas',
          currentValue: null,
          onConfirm: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enfermedades crónicas'), findsWidgets);
    });

    testWidgets('Displays the placeholder hint inside VoiceTextArea', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(title: 'T', currentValue: null, onConfirm: (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.text(_s.editChronicPersonalHint), findsOneWidget);
    });

    testWidgets(
      'TextField remains completely empty when currentValue parameter is null',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        final tf = tester.widget<TextField>(find.byType(TextField).first);
        expect(tf.controller?.text ?? '', isEmpty);
      },
    );

    testWidgets(
      'TextField remains completely empty when currentValue parameter is an empty string',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: '', onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        final tf = tester.widget<TextField>(find.byType(TextField).first);
        expect(tf.controller?.text ?? '', isEmpty);
      },
    );

    testWidgets(
      'TextField pre-populates successfully matching valid non-empty currentValue metrics',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: 'Diabetes tipo 2', onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        final tf = tester.widget<TextField>(find.byType(TextField).first);
        expect(tf.controller?.text, equals('Diabetes tipo 2'));
      },
    );

    testWidgets(
      'Displays the commit confirmation button with confirmChanges string labels',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        expect(find.text(_s.confirmChanges), findsOneWidget);
      },
    );

    testWidgets(
      'Displays the close chevron action icon within the SheetScaffold layer boundary',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close), findsOneWidget);
      },
    );

    testWidgets(
      'Displays the fallback microphone action icon toggle inside VoiceTextArea elements',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'TextField structural constraints configure exactly maxLines=8 parameters',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        final tf = tester.widget<TextField>(find.byType(TextField).first);
        expect(tf.maxLines, equals(8));
      },
    );
  });

  group('EditChronicPersonalSheet – Field Entry Mutations', () {
    testWidgets(
      'Allows typing alphanumeric characters inside text input forms seamlessly',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Hipertensión');
        await tester.pump();

        expect(find.text('Hipertensión'), findsOneWidget);
      },
    );

    testWidgets(
      'Allows overriding and replacing previous string configurations cleanly',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: 'Valor antiguo', onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Valor nuevo');
        await tester.pump();

        expect(find.text('Valor nuevo'), findsOneWidget);
        expect(find.text('Valor antiguo'), findsNothing);
      },
    );

    testWidgets(
      'Allows purging all contents resetting form controllers values directly',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: 'Texto a borrar', onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, '');
        await tester.pump();

        final tf = tester.widget<TextField>(find.byType(TextField).first);
        expect(tf.controller?.text ?? '', isEmpty);
      },
    );
  });

  group('EditChronicPersonalSheet – Callback onConfirm Actions Pipelines', () {
    testWidgets(
      'Forwards updated populated text values downstream upon confirmation click',
      (tester) async {
        String? captured;
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (v) => captured = v),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Asma crónica');
        await tester.pump();
        await tester.tap(find.text(_s.confirmChanges));
        await tester.pumpAndSettle();

        expect(captured, equals('Asma crónica'));
      },
    );

    testWidgets(
      'Evaluates empty unpopulated interface fields into explicit null values on callback arguments',
      (tester) async {
        String? captured = 'previo';
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (v) => captured = v),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(_s.confirmChanges));
        await tester.pumpAndSettle();

        expect(captured, isNull);
      },
    );

    testWidgets(
      'Evaluates modified forms wiped into empty strings directly into null arguments downstream',
      (tester) async {
        String? captured = 'previo';
        await tester.pumpWidget(
          _wrap(
            title: 'T',
            currentValue: 'Texto a borrar',
            onConfirm: (v) => captured = v,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, '');
        await tester.pump();
        await tester.tap(find.text(_s.confirmChanges));
        await tester.pumpAndSettle();

        expect(captured, isNull);
      },
    );

    testWidgets(
      'Applies absolute trim formatting to drops leading or trailing blank whitespace boundaries',
      (tester) async {
        String? captured;
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (v) => captured = v),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, '  Rinitis  ');
        await tester.pump();
        await tester.tap(find.text(_s.confirmChanges));
        await tester.pumpAndSettle();

        expect(captured, equals('Rinitis'));
      },
    );

    testWidgets(
      'Evaluates string arguments containing only whitespaces directly into null parameters tracking',
      (tester) async {
        String? captured = 'previo';
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (v) => captured = v),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, '     ');
        await tester.pump();
        await tester.tap(find.text(_s.confirmChanges));
        await tester.pumpAndSettle();

        expect(captured, isNull);
      },
    );

    testWidgets(
      'Retains and forwards unmutated current values if form triggers save without modifications',
      (tester) async {
        String? captured;
        await tester.pumpWidget(
          _wrap(
            title: 'T',
            currentValue: 'Diabetes',
            onConfirm: (v) => captured = v,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(_s.confirmChanges));
        await tester.pumpAndSettle();

        expect(captured, equals('Diabetes'));
      },
    );

    testWidgets(
      'Fires the target onConfirm callback pipeline exactly once upon commit confirmation execution',
      (tester) async {
        var callCount = 0;
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: 'x', onConfirm: (_) => callCount++),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(_s.confirmChanges));
        await tester.pumpAndSettle();

        expect(callCount, equals(1));
      },
    );
  });

  group('EditChronicPersonalSheet – Modal Navigation Context Dismissals', () {
    testWidgets(
      'Tapping the confirmation button pops the material routing chain clearing the views hierarchy',
      (tester) async {
        await tester.pumpWidget(
          _LocaleWrapper(
            locale: 'es',
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _LocaleWrapper(
                          locale: 'es',
                          child: Scaffold(
                            body: EditChronicPersonalSheet(
                              title: 'T',
                              currentValue: null,
                              onConfirm: (_) {},
                            ),
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Push'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Push'));
        await tester.pumpAndSettle();
        expect(find.byType(EditChronicPersonalSheet), findsOneWidget);

        await tester.tap(find.text(_s.confirmChanges));
        await tester.pumpAndSettle();

        expect(find.byType(EditChronicPersonalSheet), findsNothing);
      },
    );

    testWidgets(
      'Tapping close icons pops navigator layout structures without invoking confirmation pipelines',
      (tester) async {
        var confirmCalled = false;

        await tester.pumpWidget(
          _LocaleWrapper(
            locale: 'es',
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _LocaleWrapper(
                          locale: 'es',
                          child: Scaffold(
                            body: EditChronicPersonalSheet(
                              title: 'T',
                              currentValue: null,
                              onConfirm: (_) => confirmCalled = true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Push'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Push'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byType(EditChronicPersonalSheet), findsNothing);
        expect(confirmCalled, isFalse);
      },
    );
  });

  group('EditChronicPersonalSheet – VoiceTextArea Hardware Simulation Elements', () {
    testWidgets(
      'Microphone layout action initializes to mic_none_rounded state when not recording',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
        expect(find.byIcon(Icons.stop_rounded), findsNothing);
      },
    );

    testWidgets(
      'Tapping microphone buttons logs standard SnackBar alert hints when hardware triggers unavailable',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.mic_none_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Micrófono no disponible'), findsOneWidget);
      },
    );

    testWidgets(
      'Listening context string labels do not render upon structural execution startup routines',
      (tester) async {
        await tester.pumpWidget(
          _wrap(title: 'T', currentValue: null, onConfirm: (_) {}),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Escuchando... toque el micrófono para detener'),
          findsNothing,
        );
      },
    );
  });

  group(
    'EditChronicPersonalSheet – Instance Lifecycles Unmount Flow Verification',
    () {
      testWidgets(
        'Destroys layout layers without throwing unhandled lifecycle background anomalies',
        (tester) async {
          await tester.pumpWidget(
            _wrap(title: 'T', currentValue: 'Valor', onConfirm: (_) {}),
          );
          await tester.pumpAndSettle();

          await tester.pumpWidget(const MaterialApp(home: SizedBox()));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Form entry controllers teardown successfully following standard workflow confirmations',
        (tester) async {
          await tester.pumpWidget(
            _LocaleWrapper(
              locale: 'es',
              child: MaterialApp(
                home: Scaffold(
                  body: Builder(
                    builder: (ctx) => ElevatedButton(
                      onPressed: () => Navigator.of(ctx).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _LocaleWrapper(
                            locale: 'es',
                            child: Scaffold(
                              body: EditChronicPersonalSheet(
                                title: 'T',
                                currentValue: 'Valor inicial',
                                onConfirm: (_) {},
                              ),
                            ),
                          ),
                        ),
                      ),
                      child: const Text('Push'),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Push'));
          await tester.pumpAndSettle();

          final tf = tester.widget<TextField>(find.byType(TextField).first);
          expect(tf.controller?.text, equals('Valor inicial'));

          await tester.tap(find.text(_s.confirmChanges));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    },
  );

  group(
    'EditChronicPersonalSheet – Dynamic Boundary Parameters Validation Matrix',
    () {
      testWidgets(
        'VoiceTextArea section header string label explicitly tracks layout heading arguments parameters',
        (tester) async {
          const titleMetric = 'Condiciones personales';
          await tester.pumpWidget(
            _wrap(title: titleMetric, currentValue: null, onConfirm: (_) {}),
          );
          await tester.pumpAndSettle();

          expect(find.text(titleMetric), findsWidgets);
        },
      );

      testWidgets(
        'Executes rendering routines smoothly when passing an empty string as a layout heading parameter',
        (tester) async {
          await tester.pumpWidget(
            _wrap(title: '', currentValue: null, onConfirm: (_) {}),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'Processes extremely long input value configurations flawlessly matching text limits bounds',
        (tester) async {
          final textStringBound = 'A' * 500;
          await tester.pumpWidget(
            _wrap(title: 'T', currentValue: textStringBound, onConfirm: (_) {}),
          );
          await tester.pumpAndSettle();

          final tf = tester.widget<TextField>(find.byType(TextField).first);
          expect(tf.controller?.text, equals(textStringBound));
        },
      );
    },
  );
}
