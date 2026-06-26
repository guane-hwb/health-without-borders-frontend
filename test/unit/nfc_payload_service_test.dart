// test/unit/nfc/nfc_payload_service_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_triage_payload.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockNfcPayloadCodec extends Mock implements NfcPayloadCodec {}

class MockNfcTag extends Mock implements NfcTag {}

class MockNdef extends Mock implements Ndef {}

class MockTriageSummary extends Mock implements TriageSummary {}

// ── Helpers ──────────────────────────────────────────────────────────────────

MockNfcTag _tagWithoutUid() {
  final tag = MockNfcTag();
  when(() => tag.handle).thenReturn('test_tag_handle');
  when(() => tag.data).thenReturn(<String, dynamic>{});
  return tag;
}

MockNfcTag _tagWithNonListIdentifier() {
  final tag = MockNfcTag();
  when(() => tag.handle).thenReturn('test_tag_handle');
  when(() => tag.data).thenReturn({
    'nfca': {'identifier': 'not-a-list'},
  });
  return tag;
}

const String kExpectedUid = 'AB:CD:EF';

// ── Test doubles for NfcManager ──────────────────────────────────────────────

class _FakeNfcManager extends Mock implements NfcManager {
  bool isAvailableResult = true;
  bool stopSessionCalled = false;

  Future<void> Function(NfcTag tag)? onDiscoveredCapture;
  Future<void> Function(dynamic error)? onErrorCapture;

  @override
  Future<bool> isAvailable() async => isAvailableResult;

  @override
  Future<void> startSession({
    String? alertMessage,
    bool? invalidateAfterFirstRead,
    required Future<void> Function(NfcTag tag) onDiscovered,
    Future<void> Function(NfcError error)? onError,
    Set<NfcPollingOption>? pollingOptions,
  }) async {
    onDiscoveredCapture = onDiscovered;
    if (onError != null) {
      onErrorCapture = (dynamic err) async {
        onError(
          NfcError(
            type: NfcErrorType.unknown,
            message: err.toString(),
            details: null,
          ),
        );
      };
    }
  }

  @override
  Future<void> stopSession({String? alertMessage, String? errorMessage}) async {
    stopSessionCalled = true;
  }
}

void main() {
  setUpAll(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(MockNfcTag());

    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/nfc_manager'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  late MockNfcPayloadCodec codec;
  late _FakeNfcManager fakeManager;
  late NfcPayloadService service;

  const tPayload = <String, dynamic>{
    'name': 'Juan Pérez',
    'bloodType': 'O+',
    'allergies': ['penicillin'],
  };

  final tEncrypted = Uint8List.fromList([1, 2, 3, 4, 5]);

  setUp(() {
    codec = MockNfcPayloadCodec();
    fakeManager = _FakeNfcManager();
    service = NfcPayloadService(codec: codec, nfcManager: fakeManager);
  });

  // ════════════════════════════════════════════════════════════════════════════
  // NfcWriteResult
  // ════════════════════════════════════════════════════════════════════════════

  group('NfcWriteResult', () {
    test('utilizationPercent calculates correctly', () {
      const result = NfcWriteResult(
        uid: 'AA:BB:CC',
        bytesWritten: 50,
        chipCapacity: 200,
      );
      expect(result.utilizationPercent, equals(25.0));
    });

    test('utilizationPercent is 100 when chip is full', () {
      const result = NfcWriteResult(
        uid: 'AA:BB:CC',
        bytesWritten: 180,
        chipCapacity: 180,
      );
      expect(result.utilizationPercent, equals(100.0));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // NfcReadResult
  // ════════════════════════════════════════════════════════════════════════════

  group('NfcReadResult', () {
    test('stores uid and null triage', () {
      const result = NfcReadResult(uid: 'AA:BB:CC', triage: null);
      expect(result.uid, equals('AA:BB:CC'));
      expect(result.triage, isNull);
    });

    test('stores uid and non-null triage', () {
      final triage = MockTriageSummary();
      final result = NfcReadResult(uid: 'AA:BB:CC', triage: triage);
      expect(result.triage, same(triage));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Exception classes
  // ════════════════════════════════════════════════════════════════════════════

  group('NfcNotAvailableException', () {
    test('toString returns descriptive message', () {
      expect(
        NfcNotAvailableException().toString(),
        equals('NFC is not available on this device.'),
      );
    });
  });

  group('NfcWriteException', () {
    test('toString returns provided message', () {
      const msg = 'Write failed: something went wrong';
      expect(NfcWriteException(msg).toString(), equals(msg));
    });
  });

  group('NfcReadException', () {
    test('toString returns provided message', () {
      const msg = 'Read failed: something went wrong';
      expect(NfcReadException(msg).toString(), equals(msg));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // writeTriagePayload
  // ════════════════════════════════════════════════════════════════════════════

  group('writeTriagePayload', () {
    test('throws NfcNotAvailableException when NFC is unavailable', () async {
      fakeManager.isAvailableResult = false;

      expect(
        () => service.writeTriagePayload(tPayload),
        throwsA(isA<NfcNotAvailableException>()),
      );
    });

    test('completes with error when UID cannot be extracted', () async {
      when(() => codec.encode(tPayload)).thenAnswer((_) async => tEncrypted);

      final tag = _tagWithoutUid();
      final future = service.writeTriagePayload(tPayload);

      await Future.delayed(Duration.zero);

      expect(future, throwsA(isA<NfcWriteException>()));
      await fakeManager.onDiscoveredCapture!(tag);
      expect(fakeManager.stopSessionCalled, isTrue);
    });

    test('completes with error when identifier is not a list', () async {
      when(() => codec.encode(tPayload)).thenAnswer((_) async => tEncrypted);

      final tag = _tagWithNonListIdentifier();
      final future = service.writeTriagePayload(tPayload);

      await Future.delayed(Duration.zero);

      expect(future, throwsA(isA<NfcWriteException>()));
      await fakeManager.onDiscoveredCapture!(tag);
    });

    test('completes with error when chip does not support NDEF', () async {
      when(() => codec.encode(tPayload)).thenAnswer((_) async => tEncrypted);

      final tag = MockNfcTag();
      when(() => tag.handle).thenReturn('test_tag_handle');
      when(() => tag.data).thenReturn({
        'nfca': {
          'identifier': [0xAB, 0xCD, 0xEF],
        },
      });

      final future = service.writeTriagePayload(tPayload);

      await Future.delayed(Duration.zero);

      expect(
        future,
        throwsA(
          isA<NfcWriteException>().having(
            (e) => e.message,
            'message',
            contains('NDEF'),
          ),
        ),
      );
      await fakeManager.onDiscoveredCapture!(tag);
    });

    test('completes with error when chip is read-only', () async {
      when(() => codec.encode(tPayload)).thenAnswer((_) async => tEncrypted);

      final tag = MockNfcTag();
      when(() => tag.handle).thenReturn('test_tag_handle');
      when(() => tag.data).thenReturn({
        'nfca': {
          'identifier': [0xAB, 0xCD, 0xEF],
        },
        'ndef': {'isWritable': false, 'maxSize': 540, 'cachedMessage': null},
      });

      final future = service.writeTriagePayload(tPayload);

      await Future.delayed(Duration.zero);

      expect(
        future,
        throwsA(
          isA<NfcWriteException>().having(
            (e) => e.message,
            'message',
            contains('read-only'),
          ),
        ),
      );
      await fakeManager.onDiscoveredCapture!(tag);
    });

    test('completes with error when payload exceeds chip capacity', () async {
      final largePayload = Uint8List(1000);
      when(() => codec.encode(tPayload)).thenAnswer((_) async => largePayload);

      final tag = MockNfcTag();
      when(() => tag.handle).thenReturn('test_tag_handle');
      when(() => tag.data).thenReturn({
        'nfca': {
          'identifier': [0xAB, 0xCD, 0xEF],
        },
        'ndef': {'isWritable': true, 'maxSize': 144, 'cachedMessage': null},
      });

      final future = service.writeTriagePayload(tPayload);

      await Future.delayed(Duration.zero);

      expect(
        future,
        throwsA(
          isA<NfcWriteException>().having(
            (e) => e.message,
            'message',
            contains('too large'),
          ),
        ),
      );
      await fakeManager.onDiscoveredCapture!(tag);
    });

    test('returns NfcWriteResult on successful write', () async {
      when(() => codec.encode(tPayload)).thenAnswer((_) async => tEncrypted);

      final tag = MockNfcTag();
      when(() => tag.handle).thenReturn('test_tag_handle');
      when(() => tag.data).thenReturn({
        'nfca': {
          'identifier': [0xAB, 0xCD, 0xEF],
        },
        'ndef': {'isWritable': true, 'maxSize': 540, 'cachedMessage': null},
      });

      final future = service.writeTriagePayload(tPayload);

      await Future.delayed(Duration.zero);
      await fakeManager.onDiscoveredCapture!(tag);

      final result = await future;
      expect(result.uid, equals(kExpectedUid));
      expect(result.bytesWritten, equals(tEncrypted.length));
      expect(result.chipCapacity, equals(540));
    });

    for (final techKey in ['nfca', 'nfcb', 'nfcv', 'nfcf', 'iso7816']) {
      test('extracts UID from tech key "$techKey"', () async {
        when(() => codec.encode(tPayload)).thenAnswer((_) async => tEncrypted);

        final tag = MockNfcTag();
        when(() => tag.handle).thenReturn('test_tag_handle');
        when(() => tag.data).thenReturn({
          techKey: {
            'identifier': [0xAB, 0xCD, 0xEF],
          },
          'ndef': <String, dynamic>{
            'isWritable': true,
            'maxSize': 540,
            'cachedMessage': null,
          },
        });

        final future = service.writeTriagePayload(tPayload);

        await Future.delayed(Duration.zero);
        await fakeManager.onDiscoveredCapture!(tag);

        final result = await future;
        expect(result.uid, equals(kExpectedUid));
      });
    }

    test('completes with NfcWriteException on NFC session error', () async {
      when(() => codec.encode(tPayload)).thenAnswer((_) async => tEncrypted);

      final future = service.writeTriagePayload(tPayload);

      await Future.delayed(Duration.zero);

      expect(
        future,
        throwsA(
          isA<NfcWriteException>().having(
            (e) => e.message,
            'message',
            contains('NFC error'),
          ),
        ),
      );
      await fakeManager.onErrorCapture!('hardware error');
      expect(fakeManager.stopSessionCalled, isTrue);
    });

    test(
      'wraps unexpected exceptions thrown inside onDiscovered as NfcWriteException',
      () async {
        when(() => codec.encode(tPayload)).thenAnswer((_) async => tEncrypted);

        final tag = MockNfcTag();
        when(() => tag.handle).thenReturn('test_tag_handle');
        when(() => tag.data).thenThrow(Exception('boom'));

        final future = service.writeTriagePayload(tPayload);

        await Future.delayed(Duration.zero);

        expect(
          future,
          throwsA(
            isA<NfcWriteException>().having(
              (e) => e.message,
              'message',
              startsWith('Write failed:'),
            ),
          ),
        );
        await fakeManager.onDiscoveredCapture!(tag);
      },
    );

    test(
      'ignores second onDiscovered call after completer is already completed',
      () async {
        when(() => codec.encode(tPayload)).thenAnswer((_) async => tEncrypted);

        final tag = MockNfcTag();
        when(() => tag.handle).thenReturn('test_tag_handle');
        when(() => tag.data).thenReturn({
          'nfca': {
            'identifier': [0xAB, 0xCD, 0xEF],
          },
          'ndef': <String, dynamic>{
            'isWritable': true,
            'maxSize': 540,
            'cachedMessage': null,
          },
        });

        final future = service.writeTriagePayload(tPayload);

        await Future.delayed(Duration.zero);
        await fakeManager.onDiscoveredCapture!(tag);
        final result = await future;
        expect(result.uid, equals(kExpectedUid));

        expect(() => fakeManager.onDiscoveredCapture!(tag), returnsNormally);
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════════
  // readTriagePayload
  // ════════════════════════════════════════════════════════════════════════════

  group('readTriagePayload', () {
    test('throws NfcNotAvailableException when NFC is unavailable', () async {
      fakeManager.isAvailableResult = false;

      expect(
        () => service.readTriagePayload(),
        throwsA(isA<NfcNotAvailableException>()),
      );
    });

    test(
      'completes with NfcReadException when UID cannot be extracted',
      () async {
        final tag = _tagWithoutUid();
        final future = service.readTriagePayload();

        await Future.delayed(Duration.zero);

        expect(future, throwsA(isA<NfcReadException>()));
        await fakeManager.onDiscoveredCapture!(tag);
      },
    );

    test(
      'returns NfcReadResult with null triage when chip has no NDEF support',
      () async {
        final tag = MockNfcTag();
        when(() => tag.handle).thenReturn('test_tag_handle');
        when(() => tag.data).thenReturn({
          'nfca': {
            'identifier': [0xAB, 0xCD, 0xEF],
          },
        });

        final future = service.readTriagePayload();

        await Future.delayed(Duration.zero);
        await fakeManager.onDiscoveredCapture!(tag);

        final result = await future;
        expect(result.uid, equals(kExpectedUid));
        expect(result.triage, isNull);
      },
    );

    test(
      'returns NfcReadResult with null triage when cachedMessage is null',
      () async {
        final tag = MockNfcTag();
        when(() => tag.handle).thenReturn('test_tag_handle');
        when(() => tag.data).thenReturn({
          'nfca': {
            'identifier': [0xAB, 0xCD, 0xEF],
          },
          'ndef': <String, dynamic>{
            'isWritable': true,
            'maxSize': 540,
            'cachedMessage': null,
          },
        });

        final future = service.readTriagePayload();

        await Future.delayed(Duration.zero);
        await fakeManager.onDiscoveredCapture!(tag);

        final result = await future;
        expect(result.uid, equals(kExpectedUid));
        expect(result.triage, isNull);
      },
    );

    test(
      'returns NfcReadResult with null triage when records list is empty',
      () async {
        final tag = MockNfcTag();
        when(() => tag.handle).thenReturn('test_tag_handle');
        when(() => tag.data).thenReturn({
          'nfca': {
            'identifier': [0xAB, 0xCD, 0xEF],
          },
          'ndef': <String, dynamic>{
            'isWritable': true,
            'maxSize': 540,
            'cachedMessage': {'records': <dynamic>[]},
          },
        });

        final future = service.readTriagePayload();

        await Future.delayed(Duration.zero);
        await fakeManager.onDiscoveredCapture!(tag);

        final result = await future;
        expect(result.triage, isNull);
      },
    );

    test('returns null triage when no record matches HWB MIME type', () async {
      final tag = MockNfcTag();
      when(() => tag.handle).thenReturn('test_tag_handle');
      when(() => tag.data).thenReturn({
        'nfca': {
          'identifier': [0xAB, 0xCD, 0xEF],
        },
        'ndef': <String, dynamic>{
          'isWritable': true,
          'maxSize': 540,
          'cachedMessage': {
            'records': [
              {
                'typeNameFormat': 2,
                'type': Uint8List.fromList(
                  'application/vnd.OTHER.type'.codeUnits,
                ),
                'identifier': Uint8List(0),
                'payload': Uint8List.fromList([9, 8, 7]),
              },
            ],
          },
        },
      });

      final future = service.readTriagePayload();

      await Future.delayed(Duration.zero);
      await fakeManager.onDiscoveredCapture!(tag);

      final result = await future;
      expect(result.triage, isNull);
    });

    test('returns null triage when codec.decode returns null', () async {
      final hwbPayload = Uint8List.fromList([10, 20, 30]);
      when(() => codec.decode(hwbPayload)).thenAnswer((_) async => null);

      final tag = MockNfcTag();
      when(() => tag.handle).thenReturn('test_tag_handle');
      when(() => tag.data).thenReturn({
        'nfca': {
          'identifier': [0xAB, 0xCD, 0xEF],
        },
        'ndef': <String, dynamic>{
          'isWritable': true,
          'maxSize': 540,
          'cachedMessage': {
            'records': [
              {
                'typeNameFormat': 2,
                'type': Uint8List.fromList(kHwbNdefMimeType.codeUnits),
                'identifier': Uint8List(0),
                'payload': hwbPayload,
              },
            ],
          },
        },
      });

      final future = service.readTriagePayload();

      await Future.delayed(Duration.zero);
      await fakeManager.onDiscoveredCapture!(tag);

      final result = await future;
      expect(result.uid, equals(kExpectedUid));
      expect(result.triage, isNull);
    });

    test(
      'returns NfcReadResult with triage when chip has valid HWB payload',
      () async {
        final hwbPayload = Uint8List.fromList([10, 20, 30]);
        final decoded = <String, dynamic>{'fn': 'Juan', 'ln': 'Pérez'};

        when(() => codec.decode(hwbPayload)).thenAnswer((_) async => decoded);

        final tag = MockNfcTag();
        when(() => tag.handle).thenReturn('test_tag_handle');
        when(() => tag.data).thenReturn({
          'nfca': {
            'identifier': [0xAB, 0xCD, 0xEF],
          },
          'ndef': <String, dynamic>{
            'isWritable': true,
            'maxSize': 540,
            'cachedMessage': {
              'records': [
                {
                  'typeNameFormat': 2,
                  'type': Uint8List.fromList(kHwbNdefMimeType.codeUnits),
                  'identifier': Uint8List(0),
                  'payload': hwbPayload,
                },
              ],
            },
          },
        });

        final future = service.readTriagePayload();

        await Future.delayed(Duration.zero);
        await fakeManager.onDiscoveredCapture!(tag);

        final result = await future;
        expect(result.uid, equals(kExpectedUid));
        expect(result.triage, isNotNull);
      },
    );

    test('completes with NfcReadException on NFC session error', () async {
      final future = service.readTriagePayload();

      await Future.delayed(Duration.zero);

      expect(
        future,
        throwsA(
          isA<NfcReadException>().having(
            (e) => e.message,
            'message',
            contains('NFC error'),
          ),
        ),
      );
      await fakeManager.onErrorCapture!('hardware error');
      expect(fakeManager.stopSessionCalled, isTrue);
    });

    test(
      'wraps unexpected exceptions thrown inside onDiscovered as NfcReadException',
      () async {
        final tag = MockNfcTag();
        when(() => tag.handle).thenReturn('test_tag_handle');
        when(() => tag.data).thenThrow(Exception('unexpected'));

        final future = service.readTriagePayload();

        await Future.delayed(Duration.zero);

        expect(
          future,
          throwsA(
            isA<NfcReadException>().having(
              (e) => e.message,
              'message',
              startsWith('Read failed:'),
            ),
          ),
        );
        await fakeManager.onDiscoveredCapture!(tag);
      },
    );

    test(
      'ignores second onDiscovered call after completer is already completed',
      () async {
        final tag = MockNfcTag();
        when(() => tag.handle).thenReturn('test_tag_handle');
        when(() => tag.data).thenReturn({
          'nfca': {
            'identifier': [0xAB, 0xCD, 0xEF],
          },
          'ndef': <String, dynamic>{
            'isWritable': true,
            'maxSize': 540,
            'cachedMessage': null,
          },
        });

        final future = service.readTriagePayload();

        await Future.delayed(Duration.zero);
        await fakeManager.onDiscoveredCapture!(tag);
        final result = await future;
        expect(result.uid, equals(kExpectedUid));

        expect(() => fakeManager.onDiscoveredCapture!(tag), returnsNormally);
      },
    );

    test('skips records whose typeNameFormat is not media', () async {
      final tag = MockNfcTag();
      when(() => tag.handle).thenReturn('test_tag_handle');
      when(() => tag.data).thenReturn({
        'nfca': {
          'identifier': [0xAB, 0xCD, 0xEF],
        },
        'ndef': <String, dynamic>{
          'isWritable': true,
          'maxSize': 540,
          'cachedMessage': {
            'records': [
              {
                'typeNameFormat': 1,
                'type': Uint8List.fromList(kHwbNdefMimeType.codeUnits),
                'identifier': Uint8List(0),
                'payload': Uint8List.fromList([1, 2, 3]),
              },
            ],
          },
        },
      });

      final future = service.readTriagePayload();

      await Future.delayed(Duration.zero);
      await fakeManager.onDiscoveredCapture!(tag);

      final result = await future;
      expect(result.triage, isNull);
    });
  });

  group('kHwbNdefMimeType', () {
    test('has the expected value', () {
      expect(kHwbNdefMimeType, equals('application/vnd.hwb.triage'));
    });
  });
}
