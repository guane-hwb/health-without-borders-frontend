// test/widget/nfc_guided_write_widget_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/nfc_guided_write.dart';

class _Harness extends StatefulWidget {
  const _Harness({
    super.key,
    required this.locale,
    required this.write,
    this.readMode = false,
  });

  final String locale;
  final ChipWriteAction write;
  final bool readMode;

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
                  if (widget.readMode) {
                    final ok = await showNfcGuidedRead(
                      innerContext,
                      title: 'Título Lectura',
                      instruction: 'Instrucción Lectura',
                      read: widget.write,
                    );
                    result = ok;
                  } else {
                    final ok = await showNfcGuidedWrite(
                      innerContext,
                      title: 'Título',
                      instruction: 'Instrucción',
                      write: widget.write,
                    );
                    result = ok;
                  }
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
    testWidgets('showNfcGuidedRead — flujo exitoso de lectura (es y en)', (
      tester,
    ) async {
      final harnessKey = GlobalKey<_HarnessState>();
      final readCompleter = Completer<void>();

      await tester.pumpWidget(
        _Harness(
          key: harnessKey,
          locale: 'es',
          readMode: true,
          write: () => readCompleter.future,
        ),
      );

      await _openSheet(tester);

      expect(find.text('Título Lectura'), findsOneWidget);
      expect(find.text('Instrucción Lectura'), findsOneWidget);

      await tester.tap(find.text('Empezar'));
      await tester.pump();

      expect(
        find.text('Leyendo… mantenga el dispositivo cerca'),
        findsOneWidget,
      );

      readCompleter.complete();
      await tester.pump();

      expect(find.text('Leído'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 300));

      expect(harnessKey.currentState!.result, true);
    });

    testWidgets('showNfcGuidedRead — error genérico en modo lectura (es)', (
      tester,
    ) async {
      final harnessKey = GlobalKey<_HarnessState>();

      await tester.pumpWidget(
        _Harness(
          key: harnessKey,
          locale: 'es',
          readMode: true,
          write: () async => throw Exception('read_error'),
        ),
      );

      await _openSheet(tester);

      await tester.tap(find.text('Empezar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('No se pudo leer'), findsOneWidget);
    });

    testWidgets(
      'Excepciones NfcCancelledException y NfcInterruptedException devuelven false',
      (tester) async {
        final harnessKey = GlobalKey<_HarnessState>();

        await tester.pumpWidget(
          _Harness(
            key: harnessKey,
            locale: 'es',
            write: () async => throw NfcCancelledException(),
          ),
        );

        await _openSheet(tester);
        await tester.tap(find.text('Empezar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(harnessKey.currentState!.result, false);

        await tester.pumpWidget(
          _Harness(
            key: harnessKey,
            locale: 'es',
            write: () async => throw NfcInterruptedException(),
          ),
        );

        await _openSheet(tester);
        await tester.tap(find.text('Empezar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(harnessKey.currentState!.result, false);
      },
    );

    testWidgets(
      'Manejo de errores: NfcTimeoutException, NfcTagAlreadyPresentException, NfcDisabledException',
      (tester) async {
        final harnessKey = GlobalKey<_HarnessState>();

        await tester.pumpWidget(
          _Harness(
            key: harnessKey,
            locale: 'es',
            write: () async =>
                throw NfcTimeoutException(const Duration(seconds: 10)),
          ),
        );
        await _openSheet(tester);
        await tester.tap(find.text('Empezar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.textContaining('No se detectó ningún dispositivo'),
          findsOneWidget,
        );

        await tester.tap(find.text('Omitir'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.pumpWidget(
          _Harness(
            key: harnessKey,
            locale: 'es',
            write: () async => throw NfcTagAlreadyPresentException(),
          ),
        );
        await _openSheet(tester);
        await tester.tap(find.text('Empezar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('Retire el dispositivo y vuelva a acercarlo.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Omitir'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.pumpWidget(
          _Harness(
            key: harnessKey,
            locale: 'es',
            write: () async => throw NfcDisabledException(),
          ),
        );
        await _openSheet(tester);
        await tester.tap(find.text('Empezar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('El NFC está apagado'), findsOneWidget);
      },
    );

    testWidgets(
      'Error NfcPayloadTooLargeException muestra el detalle de bytes en es y en',
      (tester) async {
        final harnessKey = GlobalKey<_HarnessState>();

        await tester.pumpWidget(
          _Harness(
            key: harnessKey,
            locale: 'es',
            write: () async => throw NfcPayloadTooLargeException(
              messageBytes: 250,
              payloadBytes: 250,
              chipCapacity: 180,
            ),
          ),
        );
        await _openSheet(tester);
        await tester.tap(find.text('Empezar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text(
            'Los datos no caben en este chip: necesita 250 bytes y el chip guarda 180.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Omitir'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.pumpWidget(
          _Harness(
            key: harnessKey,
            locale: 'en',
            write: () async => throw NfcPayloadTooLargeException(
              messageBytes: 300,
              payloadBytes: 300,
              chipCapacity: 200,
            ),
          ),
        );
        await _openSheet(tester);
        await tester.tap(find.text('Start'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text(
            'The data does not fit this chip: it needs 300 bytes and the chip holds 200.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Cancelar durante el proceso de escritura dispara la función de cancelación',
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
        await tester.tap(find.text('Empezar'));
        await tester.pump();

        expect(find.text('Cancelar'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pump();

        writeCompleter.completeError(NfcCancelledException());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(harnessKey.currentState!.result, false);
      },
    );
  });
}
