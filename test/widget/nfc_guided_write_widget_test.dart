import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/nfc_guided_write.dart';

class _Harness extends StatefulWidget {
  const _Harness({super.key, required this.locale, required this.write});

  final String locale;
  final ChipWriteAction write;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool? result;

  @override
  Widget build(BuildContext context) {
    return AppLocale(
      locale: widget.locale,
      setLocale: (_) {},
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (innerContext) => ElevatedButton(
                onPressed: () async {
                  final ok = await showNfcGuidedWrite(
                    innerContext,
                    title: 'Título',
                    instruction: 'Instrucción',
                    write: widget.write,
                  );
                  result = ok;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('showNfcGuidedWrite', () {
    testWidgets(
      'flujo exitoso (es): prompt -> writing -> success -> pop(true)',
      (tester) async {
        final harnessKey = GlobalKey<_HarnessState>();
        final writeCompleter = Completer<void>();
        await tester.pumpWidget(
          _Harness(
            key: harnessKey,
            locale: 'es',
            write: () => writeCompleter.future,
          ),
        );

        await _openSheet(tester);

        expect(find.text('Título'), findsOneWidget);
        expect(find.text('Instrucción'), findsOneWidget);
        expect(find.text('Empezar'), findsOneWidget);
        expect(find.text('Omitir'), findsOneWidget);

        await tester.tap(find.text('Empezar'));
        await tester.pump();
        expect(
          find.text('Grabando… mantenga el dispositivo cerca'),
          findsOneWidget,
        );

        writeCompleter.complete();
        await tester.pump();
        expect(find.text('Grabado'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(harnessKey.currentState!.result, true);
      },
    );

    testWidgets('skip desde el prompt (en): pop(false) inmediato', (
      tester,
    ) async {
      final harnessKey = GlobalKey<_HarnessState>();
      await tester.pumpWidget(
        _Harness(key: harnessKey, locale: 'en', write: () async {}),
      );

      await _openSheet(tester);

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(harnessKey.currentState!.result, false);
    });

    testWidgets(
      'UID equivocado (es) muestra el mensaje de mismatch y permite reintentar con éxito',
      (tester) async {
        var attempt = 0;
        late Completer<void> retryCompleter;
        final harnessKey = GlobalKey<_HarnessState>();
        await tester.pumpWidget(
          _Harness(
            key: harnessKey,
            locale: 'es',
            write: () {
              attempt++;
              if (attempt == 1) {
                return Future<void>.error(
                  NfcUidMismatchException(expected: 'AA:BB', actual: 'CC:DD'),
                );
              }
              retryCompleter = Completer<void>();
              return retryCompleter.future;
            },
          ),
        );

        await _openSheet(tester);

        await tester.tap(find.text('Empezar'));
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Ese no es el dispositivo registrado para este paciente'),
          findsOneWidget,
        );
        expect(find.text('Reintentar'), findsOneWidget);
        expect(find.text('Omitir'), findsOneWidget);

        await tester.tap(find.text('Reintentar'));
        await tester.pump();
        expect(
          find.text('Grabando… mantenga el dispositivo cerca'),
          findsOneWidget,
        );

        retryCompleter.complete();
        await tester.pump();
        expect(find.text('Grabado'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(harnessKey.currentState!.result, true);
        expect(attempt, 2);
      },
    );

    testWidgets(
      'error genérico (en) muestra "Could not write" y permite hacer skip',
      (tester) async {
        final harnessKey = GlobalKey<_HarnessState>();
        await tester.pumpWidget(
          _Harness(
            key: harnessKey,
            locale: 'en',
            write: () async => throw Exception('boom'),
          ),
        );

        await _openSheet(tester);

        await tester.tap(find.text('Start'));
        await tester.pump();
        await tester.pump();

        expect(find.text('Could not write'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);

        await tester.tap(find.text('Skip'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(harnessKey.currentState!.result, false);
      },
    );
  });
}
