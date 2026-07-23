// test/widget/voice_text_area_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/shared/voice_text_area.dart';

class FakeSpeechRecognitionResult extends Fake
    implements SpeechRecognitionResult {
  FakeSpeechRecognitionResult(this._recognizedWords, this._finalResult);

  final String _recognizedWords;
  final bool _finalResult;

  @override
  String get recognizedWords => _recognizedWords;

  @override
  bool get finalResult => _finalResult;
}

class FakeSpeechToText implements stt.SpeechToText {
  FakeSpeechToText({this.initAvailable = true, this.shouldThrowOnInit = false});

  final bool initAvailable;
  final bool shouldThrowOnInit;

  stt.SpeechResultListener? onResultCallback;
  stt.SpeechErrorListener? onErrorCallback;
  stt.SpeechStatusListener? onStatusCallback;

  bool listenCalled = false;
  bool stopCalled = false;
  bool cancelCalled = false;

  @override
  Future<bool> initialize({
    stt.SpeechErrorListener? onError,
    stt.SpeechStatusListener? onStatus,
    Object? debugLogging,
    Duration? finalTimeout,
    dynamic options,
  }) async {
    if (shouldThrowOnInit) {
      throw Exception('Speech init error');
    }
    onErrorCallback = onError;
    onStatusCallback = onStatus;
    return initAvailable;
  }

  @override
  Future<void> listen({
    stt.SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    dynamic onSoundLevelChange,
    stt.SpeechListenOptions? listenOptions,
    stt.ListenMode listenMode = stt.ListenMode.confirmation,
    dynamic sampleRate,
    dynamic cancelOnError,
    dynamic partialResults,
    dynamic onDevice,
  }) async {
    listenCalled = true;
    onResultCallback = onResult;
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }

  @override
  Future<void> cancel() async {
    cancelCalled = true;
  }

  void triggerError() {
    onErrorCallback?.call(SpeechRecognitionError('test_error', false));
  }

  void triggerStatus(String status) {
    onStatusCallback?.call(status);
  }

  void triggerResult(String recognizedWords, {bool isFinal = false}) {
    final result = FakeSpeechRecognitionResult(recognizedWords, isFinal);
    onResultCallback?.call(result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  Widget build(BuildContext context) => AppLocale(
    locale: _locale,
    setLocale: (l) => setState(() => _locale = l),
    child: widget.child,
  );
}

Widget _wrapWithApp(Widget child, {String locale = 'es'}) {
  return _LocaleWrapper(
    locale: locale,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('VoiceTextArea Widget & Dynamic Callbacks (100% Cobertura)', () {
    testWidgets('1. Inicializacion exitosa y render basico', (tester) async {
      final fakeSpeech = FakeSpeechToText(initAvailable: true);

      await tester.pumpWidget(
        _wrapWithApp(
          VoiceTextArea(
            label: 'Observaciones',
            controller: controller,
            hint: 'Escriba aqui...',
            onChanged: (_) {},
            speech: fakeSpeech,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Observaciones'), findsOneWidget);
      expect(find.text('Escriba aqui...'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('2. Muestra SnackBar cuando el microfono NO esta disponible', (
      tester,
    ) async {
      final fakeSpeech = FakeSpeechToText(initAvailable: false);

      await tester.pumpWidget(
        _wrapWithApp(
          VoiceTextArea(
            label: 'Observaciones',
            controller: controller,
            hint: 'Escriba...',
            onChanged: (_) {},
            speech: fakeSpeech,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Micrófono no disponible'), findsOneWidget);
    });

    testWidgets('3. Muestra SnackBar en ingles cuando locale es en', (
      tester,
    ) async {
      final fakeSpeech = FakeSpeechToText(initAvailable: false);

      await tester.pumpWidget(
        _wrapWithApp(
          VoiceTextArea(
            label: 'Notes',
            controller: controller,
            hint: 'Type here...',
            onChanged: (_) {},
            speech: fakeSpeech,
          ),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Microphone not available'), findsOneWidget);
    });

    testWidgets('4. Exception durante _initSpeech deshabilita speech', (
      tester,
    ) async {
      final fakeSpeech = FakeSpeechToText(shouldThrowOnInit: true);

      await tester.pumpWidget(
        _wrapWithApp(
          VoiceTextArea(
            label: 'Notas',
            controller: controller,
            hint: 'Hint',
            onChanged: (_) {},
            speech: fakeSpeech,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
      '5. Iniciar dictado por voz, mostrar banner "Escuchando...", formatear _baseText y detener manualmente',
      (tester) async {
        final fakeSpeech = FakeSpeechToText(initAvailable: true);
        controller.text = 'Texto previo';
        String changedText = '';

        await tester.pumpWidget(
          _wrapWithApp(
            VoiceTextArea(
              label: 'Notas',
              controller: controller,
              hint: 'Hint',
              onChanged: (val) => changedText = val,
              speech: fakeSpeech,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.mic_none_rounded));
        await tester.pump();

        expect(fakeSpeech.listenCalled, isTrue);
        expect(
          find.text('Escuchando... toque el micrófono para detener'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

        fakeSpeech.triggerResult('nuevo dictado', isFinal: false);
        await tester.pump();

        expect(controller.text, equals('Texto previo nuevo dictado'));
        expect(changedText, equals('Texto previo nuevo dictado'));

        await tester.tap(find.byIcon(Icons.stop_rounded));
        await tester.pumpAndSettle();

        expect(fakeSpeech.stopCalled, isTrue);
        expect(
          find.text('Escuchando... toque el micrófono para detener'),
          findsNothing,
        );
      },
    );

    testWidgets(
      '6. Banner en ingles y cierre automatico al recibir finalResult',
      (tester) async {
        final fakeSpeech = FakeSpeechToText(initAvailable: true);
        controller.text = 'Hello ';

        await tester.pumpWidget(
          _wrapWithApp(
            VoiceTextArea(
              label: 'Notes',
              controller: controller,
              hint: 'Hint',
              onChanged: (_) {},
              speech: fakeSpeech,
            ),
            locale: 'en',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.mic_none_rounded));
        await tester.pump();

        expect(
          find.text('Listening... tap microphone to stop'),
          findsOneWidget,
        );

        fakeSpeech.triggerResult('world', isFinal: true);
        await tester.pumpAndSettle();

        expect(controller.text, equals('Hello world'));
        expect(find.text('Listening... tap microphone to stop'), findsNothing);
      },
    );

    testWidgets('7. Probar callback onError de SpeechToText', (tester) async {
      final fakeSpeech = FakeSpeechToText(initAvailable: true);

      await tester.pumpWidget(
        _wrapWithApp(
          VoiceTextArea(
            label: 'Notas',
            controller: controller,
            hint: 'Hint',
            onChanged: (_) {},
            speech: fakeSpeech,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pump();

      expect(
        find.text('Escuchando... toque el micrófono para detener'),
        findsOneWidget,
      );

      fakeSpeech.triggerError();
      await tester.pumpAndSettle();

      expect(
        find.text('Escuchando... toque el micrófono para detener'),
        findsNothing,
      );
    });

    testWidgets(
      '8. Probar callback onStatus de SpeechToText (done / notListening)',
      (tester) async {
        final fakeSpeech = FakeSpeechToText(initAvailable: true);

        await tester.pumpWidget(
          _wrapWithApp(
            VoiceTextArea(
              label: 'Notas',
              controller: controller,
              hint: 'Hint',
              onChanged: (_) {},
              speech: fakeSpeech,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.mic_none_rounded));
        await tester.pump();

        expect(
          find.text('Escuchando... toque el micrófono para detener'),
          findsOneWidget,
        );

        fakeSpeech.triggerStatus(stt.SpeechToText.doneStatus);
        await tester.pumpAndSettle();

        expect(
          find.text('Escuchando... toque el micrófono para detener'),
          findsNothing,
        );

        await tester.tap(find.byIcon(Icons.mic_none_rounded));
        await tester.pump();

        expect(
          find.text('Escuchando... toque el micrófono para detener'),
          findsOneWidget,
        );

        fakeSpeech.triggerStatus(stt.SpeechToText.notListeningStatus);
        await tester.pumpAndSettle();

        expect(
          find.text('Escuchando... toque el micrófono para detener'),
          findsNothing,
        );
      },
    );

    testWidgets('9. Modificacion directa del TextField dispara onChanged', (
      tester,
    ) async {
      final fakeSpeech = FakeSpeechToText(initAvailable: true);
      String valueTyped = '';

      await tester.pumpWidget(
        _wrapWithApp(
          VoiceTextArea(
            label: 'Notas',
            controller: controller,
            hint: 'Hint',
            onChanged: (v) => valueTyped = v,
            speech: fakeSpeech,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Texto escrito');
      await tester.pump();

      expect(valueTyped, equals('Texto escrito'));
    });
  });
}
