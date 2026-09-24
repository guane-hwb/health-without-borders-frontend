// test/unit/nfc_session_manager_mobile_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';

import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/src/nfc_manager_android/pigeon.g.dart' as apg;
import 'package:nfc_manager/src/nfc_manager_ios/pigeon.g.dart' as ipg;

import 'package:health_without_borders_frontend/src/core/nfc/nfc_session_manager_mobile.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_session_types.dart';

const _chAndroidIsEnabled =
    'dev.flutter.pigeon.nfc_manager.HostApiPigeon.nfcAdapterIsEnabled';
const _chAndroidEnableReaderMode =
    'dev.flutter.pigeon.nfc_manager.HostApiPigeon.nfcAdapterEnableReaderMode';
const _chAndroidDisableReaderMode =
    'dev.flutter.pigeon.nfc_manager.HostApiPigeon.nfcAdapterDisableReaderMode';
const _chAndroidWriteNdef =
    'dev.flutter.pigeon.nfc_manager.HostApiPigeon.ndefWriteNdefMessage';
const _chAndroidOnTagDiscovered =
    'dev.flutter.pigeon.nfc_manager.FlutterApiPigeon.onTagDiscovered';
const _chAndroidOnAdapterStateChanged =
    'dev.flutter.pigeon.nfc_manager.FlutterApiPigeon.onAdapterStateChanged';

const _chIosReadingAvailable =
    'dev.flutter.pigeon.nfc_manager.HostApiPigeon.tagSessionReadingAvailable';
const _chIosTagSessionBegin =
    'dev.flutter.pigeon.nfc_manager.HostApiPigeon.tagSessionBegin';
const _chIosTagSessionInvalidate =
    'dev.flutter.pigeon.nfc_manager.HostApiPigeon.tagSessionInvalidate';
const _chIosWriteNdef =
    'dev.flutter.pigeon.nfc_manager.HostApiPigeon.ndefWriteNdef';
const _chIosTagSessionDidDetect =
    'dev.flutter.pigeon.nfc_manager.FlutterApiPigeon.tagSessionDidDetect';
const _chIosTagSessionDidInvalidateWithError =
    'dev.flutter.pigeon.nfc_manager.FlutterApiPigeon.tagSessionDidInvalidateWithError';

const _mockedChannels = <String>[
  _chAndroidIsEnabled,
  _chAndroidEnableReaderMode,
  _chAndroidDisableReaderMode,
  _chAndroidWriteNdef,
  _chIosReadingAvailable,
  _chIosTagSessionBegin,
  _chIosTagSessionInvalidate,
  _chIosWriteNdef,
];

const MessageCodec<Object?> _androidCodec =
    apg.HostApiPigeon.pigeonChannelCodec;
const MessageCodec<Object?> _iosCodec = ipg.HostApiPigeon.pigeonChannelCodec;

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

List<Object?> _ok([Object? value]) =>
    value == null ? <Object?>[] : <Object?>[value];

List<Object?> _fail([String code = 'mock-error']) => <Object?>[
  code,
  'simulado por el test',
  null,
];

void _mock(
  MessageCodec<Object?> codec,
  String channel,
  List<Object?> Function(Object? args) reply,
) {
  _messenger.setMockMessageHandler(channel, (ByteData? message) async {
    final args = message == null ? null : codec.decodeMessage(message);
    return codec.encodeMessage(reply(args));
  });
}

Future<void> _emit(
  MessageCodec<Object?> codec,
  String channel,
  Object? message,
) async {
  await _messenger.handlePlatformMessage(
    channel,
    codec.encodeMessage(message),
    (_) {},
  );
}

apg.TagPigeon _androidTag({bool withNdef = true, bool isWritable = true}) {
  return apg.TagPigeon(
    handle: 'android-handle-1',
    id: Uint8List.fromList(<int>[0x04, 0xA1, 0xB2, 0xC3]),
    techList: const <String>['android.nfc.tech.NfcA'],
    ndef: withNdef
        ? apg.NdefPigeon(
            type: 'org.nfcforum.ndef.type1',
            canMakeReadOnly: false,
            isWritable: isWritable,
            maxSize: 137,
            cachedNdefMessage: apg.NdefMessagePigeon(
              records: <apg.NdefRecordPigeon>[
                apg.NdefRecordPigeon(
                  tnf: apg.TypeNameFormatPigeon.wellKnown,
                  type: Uint8List.fromList('T'.codeUnits),
                  id: Uint8List(0),
                  payload: Uint8List.fromList('hola'.codeUnits),
                ),
              ],
            ),
          )
        : null,
  );
}

ipg.TagPigeon _iosTag({bool withMifare = true, bool withNdef = true}) {
  return ipg.TagPigeon(
    handle: 'ios-handle-1',
    miFare: withMifare
        ? ipg.MiFarePigeon(
            mifareFamily: ipg.MiFareFamilyPigeon.ultralight,
            identifier: Uint8List.fromList(<int>[0x04, 0xA1, 0xB2, 0xC3]),
            historicalBytes: null,
          )
        : null,
    ndef: withNdef
        ? ipg.NdefPigeon(
            status: ipg.NdefStatusPigeon.readWrite,
            capacity: 504,
            cachedNdefMessage: ipg.NdefMessagePigeon(
              records: <ipg.NdefPayloadPigeon>[
                ipg.NdefPayloadPigeon(
                  typeNameFormat: ipg.TypeNameFormatPigeon.wellKnown,
                  type: Uint8List.fromList('T'.codeUnits),
                  identifier: Uint8List(0),
                  payload: Uint8List.fromList('hola'.codeUnits),
                ),
              ],
            ),
          )
        : null,
  );
}

NdefMessage _sampleMessageToWrite() => NdefMessage(
  records: <NdefRecord>[
    NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList('T'.codeUnits),
      identifier: Uint8List(0),
      payload: Uint8List.fromList('chau'.codeUnits),
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    NfcSessionManager.instance.cancelPending();
    await pumpEventQueue();
    await NfcSessionManager.instance.detach();
    debugDefaultTargetPlatformOverride = null;
    for (final channel in _mockedChannels) {
      _messenger.setMockMessageHandler(channel, null);
    }
  });

  group('NfcSessionManager — Android — attach/detach', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    test('attach() habilita reader mode y publica idle', () async {
      _mock(_androidCodec, _chAndroidEnableReaderMode, (_) => _ok());
      await NfcSessionManager.instance.attach();
      expect(NfcSessionManager.instance.radioState.value, NfcRadioState.idle);
    });

    test('attach() es no-op si ya está adjunto', () async {
      var calls = 0;
      _mock(_androidCodec, _chAndroidEnableReaderMode, (_) {
        calls++;
        return _ok();
      });
      await NfcSessionManager.instance.attach();
      await NfcSessionManager.instance.attach();
      expect(calls, 1);
    });

    test('detach() sin attach previo no falla', () async {
      await expectLater(NfcSessionManager.instance.detach(), completes);
    });

    test(
      'attach() reporta el error de enableReaderMode en vez de esconderlo',
      () async {
        _mock(_androidCodec, _chAndroidEnableReaderMode, (_) => _fail());
        FlutterErrorDetails? captured;
        final original = FlutterError.onError;
        FlutterError.onError = (details) => captured = details;
        await NfcSessionManager.instance.attach();
        FlutterError.onError = original;
        expect(captured, isNotNull);
        expect(NfcSessionManager.instance.radioState.value, NfcRadioState.off);
      },
    );
  });

  group('NfcSessionManager — Android — withTag', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      _mock(_androidCodec, _chAndroidIsEnabled, (_) => _ok(true));
      _mock(_androidCodec, _chAndroidEnableReaderMode, (_) => _ok());
      _mock(_androidCodec, _chAndroidDisableReaderMode, (_) => _ok());
    });

    test('recorrido completo: uid + ndef + escritura', () async {
      _mock(_androidCodec, _chAndroidWriteNdef, (_) => _ok());
      final states = <NfcRadioState>[];
      void listener() =>
          states.add(NfcSessionManager.instance.radioState.value);
      NfcSessionManager.instance.radioState.addListener(listener);
      addTearDown(
        () => NfcSessionManager.instance.radioState.removeListener(listener),
      );

      final future = NfcSessionManager.instance.withTag<String>((tag) async {
        expect(tag.uid, '04:A1:B2:C3');
        expect(tag.ndef, isNotNull);
        expect(tag.ndef!.isWritable, isTrue);
        expect(tag.ndef!.maxSize, 137);
        expect(tag.ndef!.cachedMessage, isNotNull);
        await tag.ndef!.write(_sampleMessageToWrite());
        return tag.uid;
      });

      await pumpEventQueue();
      await _emit(_androidCodec, _chAndroidOnTagDiscovered, <Object?>[
        _androidTag(),
      ]);
      await pumpEventQueue();

      expect(await future, '04:A1:B2:C3');
      expect(states, contains(NfcRadioState.waiting));
      expect(states, contains(NfcRadioState.working));
      expect(NfcSessionManager.instance.radioState.value, NfcRadioState.idle);
    });

    test('sin ndef en el chip, HwbTag.ndef es null', () async {
      final future = NfcSessionManager.instance.withTag<void>((tag) async {
        expect(tag.ndef, isNull);
        expect(tag.uid, '04:A1:B2:C3');
      });
      await pumpEventQueue();
      await _emit(_androidCodec, _chAndroidOnTagDiscovered, <Object?>[
        _androidTag(withNdef: false),
      ]);
      await pumpEventQueue();
      await future;
    });

    test('NfcBusyException si ya hay una espera en curso', () async {
      final first = NfcSessionManager.instance.withTag<void>((_) async {});
      await pumpEventQueue();
      await expectLater(
        NfcSessionManager.instance.withTag<void>((_) async {}),
        throwsA(isA<NfcBusyException>()),
      );
      NfcSessionManager.instance.cancelPending();
      await expectLater(first, throwsA(isA<NfcCancelledException>()));
    });

    test(
      'NfcTagAlreadyPresentException si un chip ya estaba en el campo',
      () async {
        await NfcSessionManager.instance.attach();
        await _emit(_androidCodec, _chAndroidOnTagDiscovered, <Object?>[
          _androidTag(),
        ]);
        await pumpEventQueue();
        await expectLater(
          NfcSessionManager.instance.withTag<void>((_) async {}),
          throwsA(isA<NfcTagAlreadyPresentException>()),
        );
      },
    );

    test('NfcCancelledException si el token ya estaba cancelado', () async {
      final token = NfcCancelToken()..cancel();
      await expectLater(
        NfcSessionManager.instance.withTag<void>((_) async {}, cancel: token),
        throwsA(isA<NfcCancelledException>()),
      );
    });

    test('NfcCancelledException si se cancela mientras espera', () async {
      final token = NfcCancelToken();
      final future = NfcSessionManager.instance.withTag<void>(
        (_) async {},
        cancel: token,
      );
      await pumpEventQueue();
      token.cancel();
      await expectLater(future, throwsA(isA<NfcCancelledException>()));
      expect(NfcSessionManager.instance.radioState.value, NfcRadioState.idle);
    });

    test('NfcTimeoutException si no llega ningún chip', () async {
      final future = NfcSessionManager.instance.withTag<void>(
        (_) async {},
        timeout: const Duration(milliseconds: 30),
      );
      await expectLater(future, throwsA(isA<NfcTimeoutException>()));
      expect(NfcSessionManager.instance.radioState.value, NfcRadioState.idle);
    });

    test(
      'el error de action() se propaga sin dejar el estado colgado',
      () async {
        final future = NfcSessionManager.instance.withTag<void>(
          (_) async => throw StateError('boom'),
        );
        await pumpEventQueue();

        await Future.wait<void>([
          expectLater(future, throwsA(isA<StateError>())),
          _emit(_androidCodec, _chAndroidOnTagDiscovered, <Object?>[
            _androidTag(),
          ]),
        ]);

        expect(NfcSessionManager.instance.radioState.value, NfcRadioState.idle);
      },
    );

    test('NfcDisabledException cuando NFC está apagado', () async {
      _mock(_androidCodec, _chAndroidIsEnabled, (_) => _ok(false));
      await expectLater(
        NfcSessionManager.instance.withTag<void>((_) async {}),
        throwsA(isA<NfcDisabledException>()),
      );
    });

    test('NfcNotAvailableException si el dispositivo no soporta NFC', () async {
      _mock(_androidCodec, _chAndroidIsEnabled, (_) => _fail());
      await expectLater(
        NfcSessionManager.instance.withTag<void>((_) async {}),
        throwsA(isA<NfcNotAvailableException>()),
      );
    });

    test(
      'NfcNotAvailableException si forceReaderMode no logra encender la radio',
      () async {
        _mock(_androidCodec, _chAndroidEnableReaderMode, (_) => _fail());
        await expectLater(
          NfcSessionManager.instance.withTag<void>((_) async {}),
          throwsA(isA<NfcNotAvailableException>()),
        );
      },
    );

    test(
      'forceReaderMode ignora el error de disableReaderMode y sigue adelante',
      () async {
        await NfcSessionManager.instance.attach();
        _mock(_androidCodec, _chAndroidDisableReaderMode, (_) => _fail());
        final future = NfcSessionManager.instance.withTag<void>(
          (_) async {},
          timeout: const Duration(milliseconds: 30),
        );
        await expectLater(future, throwsA(isA<NfcTimeoutException>()));
      },
    );
  });

  group('NfcSessionManager — Android — ciclo de vida y adaptador', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      _mock(_androidCodec, _chAndroidIsEnabled, (_) => _ok(true));
      _mock(_androidCodec, _chAndroidEnableReaderMode, (_) => _ok());
      _mock(_androidCodec, _chAndroidDisableReaderMode, (_) => _ok());
    });

    test('adaptador OFF falla la espera pendiente y pasa a disabled', () async {
      final future = NfcSessionManager.instance.withTag<void>((_) async {});
      await pumpEventQueue();

      await Future.wait<void>([
        expectLater(future, throwsA(isA<NfcDisabledException>())),
        _emit(_androidCodec, _chAndroidOnAdapterStateChanged, <Object?>[
          apg.AdapterStatePigeon.off,
        ]),
      ]);

      expect(
        NfcSessionManager.instance.radioState.value,
        NfcRadioState.disabled,
      );
    });

    test('adaptador TURNING_OFF también falla la espera pendiente', () async {
      final future = NfcSessionManager.instance.withTag<void>((_) async {});
      await pumpEventQueue();

      await Future.wait<void>([
        expectLater(future, throwsA(isA<NfcDisabledException>())),
        _emit(_androidCodec, _chAndroidOnAdapterStateChanged, <Object?>[
          apg.AdapterStatePigeon.turningOff,
        ]),
      ]);
    });

    test('adaptador TURNING_ON no altera el estado', () async {
      await NfcSessionManager.instance.attach();
      await _emit(_androidCodec, _chAndroidOnAdapterStateChanged, <Object?>[
        apg.AdapterStatePigeon.turningOn,
      ]);
      await pumpEventQueue();
      expect(NfcSessionManager.instance.radioState.value, NfcRadioState.idle);
    });

    test('adaptador ON reactiva reader mode tras haberse apagado', () async {
      await NfcSessionManager.instance.attach();
      await _emit(_androidCodec, _chAndroidOnAdapterStateChanged, <Object?>[
        apg.AdapterStatePigeon.off,
      ]);
      await pumpEventQueue();
      await _emit(_androidCodec, _chAndroidOnAdapterStateChanged, <Object?>[
        apg.AdapterStatePigeon.on,
      ]);
      await pumpEventQueue();
      expect(NfcSessionManager.instance.radioState.value, NfcRadioState.idle);
    });

    test('inactive no altera el estado', () async {
      await NfcSessionManager.instance.attach();
      NfcSessionManager.instance.didChangeAppLifecycleState(
        AppLifecycleState.inactive,
      );
      expect(NfcSessionManager.instance.radioState.value, NfcRadioState.idle);
    });

    test(
      'paused congela el timeout y libera la radio; resumed la retoma',
      () async {
        final future = NfcSessionManager.instance.withTag<String>(
          (tag) async => tag.uid,
          timeout: const Duration(seconds: 5),
        );
        await pumpEventQueue();
        expect(
          NfcSessionManager.instance.radioState.value,
          NfcRadioState.waiting,
        );

        NfcSessionManager.instance.didChangeAppLifecycleState(
          AppLifecycleState.paused,
        );
        await pumpEventQueue();
        expect(NfcSessionManager.instance.radioState.value, NfcRadioState.off);

        NfcSessionManager.instance.didChangeAppLifecycleState(
          AppLifecycleState.resumed,
        );
        await pumpEventQueue();
        expect(
          NfcSessionManager.instance.radioState.value,
          NfcRadioState.waiting,
        );

        await _emit(_androidCodec, _chAndroidOnTagDiscovered, <Object?>[
          _androidTag(),
        ]);
        await pumpEventQueue();
        expect(await future, '04:A1:B2:C3');
      },
    );

    test('hidden también libera la radio (mismo camino que paused)', () async {
      await NfcSessionManager.instance.attach();
      NfcSessionManager.instance.didChangeAppLifecycleState(
        AppLifecycleState.hidden,
      );
      await pumpEventQueue();
      expect(NfcSessionManager.instance.radioState.value, NfcRadioState.off);
    });

    test('detached interrumpe la espera pendiente', () async {
      final future = NfcSessionManager.instance.withTag<void>((_) async {});
      await pumpEventQueue();

      NfcSessionManager.instance.didChangeAppLifecycleState(
        AppLifecycleState.detached,
      );

      await expectLater(future, throwsA(isA<NfcInterruptedException>()));
    });

    test(
      '_disableReaderMode ignora el error y de igual forma pasa a off',
      () async {
        await NfcSessionManager.instance.attach();
        _mock(_androidCodec, _chAndroidDisableReaderMode, (_) => _fail());
        NfcSessionManager.instance.didChangeAppLifecycleState(
          AppLifecycleState.paused,
        );
        await pumpEventQueue();
        expect(NfcSessionManager.instance.radioState.value, NfcRadioState.off);
      },
    );
  });

  group('NfcSessionManager — iOS', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    test('attach() publica idle sin tocar ningún canal', () async {
      await NfcSessionManager.instance.attach();
      expect(NfcSessionManager.instance.radioState.value, NfcRadioState.idle);
    });

    test('NfcNotAvailableException si Core NFC no está disponible', () async {
      _mock(_iosCodec, _chIosReadingAvailable, (_) => _ok(false));
      await expectLater(
        NfcSessionManager.instance.withTag<void>((_) async {}),
        throwsA(isA<NfcNotAvailableException>()),
      );
    });

    test('recorrido completo: uid + ndef + escritura', () async {
      _mock(_iosCodec, _chIosReadingAvailable, (_) => _ok(true));
      _mock(_iosCodec, _chIosTagSessionBegin, (_) => _ok());
      _mock(_iosCodec, _chIosTagSessionInvalidate, (_) => _ok());
      _mock(_iosCodec, _chIosWriteNdef, (_) => _ok());

      final future = NfcSessionManager.instance.withTag<String>((tag) async {
        expect(tag.uid, '04:A1:B2:C3');
        expect(tag.ndef, isNotNull);
        expect(tag.ndef!.isWritable, isTrue);
        expect(tag.ndef!.maxSize, 504);
        expect(tag.ndef!.cachedMessage, isNotNull);
        await tag.ndef!.write(_sampleMessageToWrite());
        return tag.uid;
      });

      await pumpEventQueue();
      await _emit(_iosCodec, _chIosTagSessionDidDetect, <Object?>[_iosTag()]);
      await pumpEventQueue();

      expect(await future, '04:A1:B2:C3');
      expect(NfcSessionManager.instance.radioState.value, NfcRadioState.idle);
    });

    test('tag sin MiFare y sin Ndef produce un HwbTag vacío', () async {
      _mock(_iosCodec, _chIosReadingAvailable, (_) => _ok(true));
      _mock(_iosCodec, _chIosTagSessionBegin, (_) => _ok());
      _mock(_iosCodec, _chIosTagSessionInvalidate, (_) => _ok());

      final future = NfcSessionManager.instance.withTag<void>((tag) async {
        expect(tag.uid, '');
        expect(tag.ndef, isNull);
      });
      await pumpEventQueue();
      await _emit(_iosCodec, _chIosTagSessionDidDetect, <Object?>[
        _iosTag(withMifare: false, withNdef: false),
      ]);
      await pumpEventQueue();
      await future;
    });
    test(
      'el error de action() invalida la sesión y se propaga tal cual',
      () async {
        _mock(_iosCodec, _chIosReadingAvailable, (_) => _ok(true));
        _mock(_iosCodec, _chIosTagSessionBegin, (_) => _ok());
        _mock(_iosCodec, _chIosTagSessionInvalidate, (_) => _ok());

        final future = NfcSessionManager.instance.withTag<void>(
          (_) async => throw StateError('boom'),
        );
        await pumpEventQueue();

        await Future.wait<void>([
          expectLater(future, throwsA(isA<StateError>())),
          _emit(_iosCodec, _chIosTagSessionDidDetect, <Object?>[_iosTag()]),
        ]);
      },
    );

    test(
      'tagSessionInvalidate fallando no impide que la operación se resuelva',
      () async {
        _mock(_iosCodec, _chIosReadingAvailable, (_) => _ok(true));
        _mock(_iosCodec, _chIosTagSessionBegin, (_) => _ok());
        _mock(_iosCodec, _chIosTagSessionInvalidate, (_) => _fail());

        final future = NfcSessionManager.instance.withTag<String>(
          (tag) async => tag.uid,
        );
        await pumpEventQueue();
        await _emit(_iosCodec, _chIosTagSessionDidDetect, <Object?>[_iosTag()]);
        await pumpEventQueue();
        expect(await future, '04:A1:B2:C3');
      },
    );

    test('NfcTimeoutException si no llega ningún chip', () async {
      _mock(_iosCodec, _chIosReadingAvailable, (_) => _ok(true));
      _mock(_iosCodec, _chIosTagSessionBegin, (_) => _ok());
      _mock(_iosCodec, _chIosTagSessionInvalidate, (_) => _ok());

      final future = NfcSessionManager.instance.withTag<void>(
        (_) async {},
        timeout: const Duration(milliseconds: 30),
      );
      await expectLater(future, throwsA(isA<NfcTimeoutException>()));
    });

    test('NfcCancelledException si se cancela mientras espera', () async {
      _mock(_iosCodec, _chIosReadingAvailable, (_) => _ok(true));
      _mock(_iosCodec, _chIosTagSessionBegin, (_) => _ok());
      _mock(_iosCodec, _chIosTagSessionInvalidate, (_) => _ok());

      final token = NfcCancelToken();
      final future = NfcSessionManager.instance.withTag<void>(
        (_) async {},
        cancel: token,
      );
      await pumpEventQueue();
      token.cancel();
      await expectLater(future, throwsA(isA<NfcCancelledException>()));
    });

    test('cancelPending() aborta la sesión de Core NFC en curso', () async {
      _mock(_iosCodec, _chIosReadingAvailable, (_) => _ok(true));
      _mock(_iosCodec, _chIosTagSessionBegin, (_) => _ok());
      _mock(_iosCodec, _chIosTagSessionInvalidate, (_) => _ok());

      final future = NfcSessionManager.instance.withTag<void>((_) async {});
      await pumpEventQueue();

      NfcSessionManager.instance.cancelPending();

      await expectLater(future, throwsA(isA<NfcCancelledException>()));
    });

    test('cancelPending() sin nada pendiente no falla', () {
      expect(NfcSessionManager.instance.cancelPending, returnsNormally);
    });

    group('mapeo de errores de invalidación de Core NFC', () {
      final casos =
          <
            (
              ipg.NfcReaderErrorCodePigeon code,
              Matcher matcher,
              String etiqueta,
            )
          >[
            (
              ipg
                  .NfcReaderErrorCodePigeon
                  .readerSessionInvalidationErrorUserCanceled,
              isA<NfcCancelledException>(),
              'NfcCancelledException',
            ),
            (
              ipg
                  .NfcReaderErrorCodePigeon
                  .readerSessionInvalidationErrorSessionTimeout,
              isA<NfcTimeoutException>(),
              'NfcTimeoutException',
            ),
            (
              ipg
                  .NfcReaderErrorCodePigeon
                  .readerSessionInvalidationErrorSystemIsBusy,
              isA<NfcBusyException>(),
              'NfcBusyException',
            ),
            (
              ipg
                  .NfcReaderErrorCodePigeon
                  .readerSessionInvalidationErrorSessionTerminatedUnexpectedly,
              isA<NfcInterruptedException>(),
              'NfcInterruptedException',
            ),
            (
              ipg.NfcReaderErrorCodePigeon.ndefReaderSessionErrorTagNotWritable,
              predicate<Object>(
                (e) => e.runtimeType == NfcSessionException,
                'NfcSessionException genérica (caso default)',
              ),
              'NfcSessionException genérica',
            ),
          ];

      for (final caso in casos) {
        test('${caso.$1.name} ->${caso.$3}', () async {
          _mock(_iosCodec, _chIosReadingAvailable, (_) => _ok(true));
          _mock(_iosCodec, _chIosTagSessionBegin, (_) => _ok());
          _mock(_iosCodec, _chIosTagSessionInvalidate, (_) => _ok());

          final future = NfcSessionManager.instance.withTag<void>((_) async {});
          await pumpEventQueue();

          await Future.wait<void>([
            expectLater(future, throwsA(caso.$2)),
            _emit(_iosCodec, _chIosTagSessionDidInvalidateWithError, <Object?>[
              ipg.NfcReaderSessionErrorPigeon(
                code: caso.$1,
                message: 'simulado por el test',
              ),
            ]),
          ]);
        });
      }
    });
  });
}
