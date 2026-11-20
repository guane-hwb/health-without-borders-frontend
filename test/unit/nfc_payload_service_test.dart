// test/unit/nfc_payload_service_test.dart

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nfc_manager/ndef_record.dart';

import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_alias.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_payload.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_format.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_session_manager.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_write_metric.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_triage_payload.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

// ── Fakes ───────────────────────────────────────────────────────────────────
//
// The plugin is absent from this file on purpose. v4 seals NfcTag, so the old
// MockNfcTag/MockNdef approach cannot compile; HwbTag/HwbNdef are the seam now,
// which also means these tests describe HWB's rules rather than the plugin's
// tag-data wire format.

class MockNfcPayloadCodec extends Mock implements NfcPayloadCodec {}

class _FakeNdef implements HwbNdef {
  _FakeNdef({
    required this.maxSize,
    this.isWritable = true,
    this.cachedMessage,
    this.writeError,
  });

  @override
  final int maxSize;

  @override
  final bool isWritable;

  @override
  final NdefMessage? cachedMessage;

  final Object? writeError;

  /// What write() was handed, or null if it was never called.
  NdefMessage? written;

  @override
  Future<void> write(NdefMessage message) async {
    if (writeError != null) throw writeError!;
    written = message;
  }
}

class _FakeTagSource implements NfcTagSource {
  _FakeTagSource.tag(this._tag);
  _FakeTagSource.throws(this._error);

  HwbTag? _tag;
  Object? _error;

  @override
  Future<T> withTag<T>(
    Future<T> Function(HwbTag tag) action, {
    Duration timeout = const Duration(seconds: 20),
    NfcCancelToken? cancel,
    String? alertMessage,
  }) async {
    if (_error != null) throw _error!;
    return action(_tag!);
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

const String kExpectedUid = 'AB:CD:EF';

/// An NTAG215's NDEF budget, as Android reports it.
const int kNtag215MaxSize = 492;

NdefMessage _messageOf(String mime, Uint8List payload) =>
    NdefMessage(records: [NfcPayloadService.buildMimeRecord(mime, payload)]);

/// A chip carrying one MIME record of [mime] with [payload].
HwbTag _chipWith(String mime, Uint8List payload, {String uid = kExpectedUid}) =>
    HwbTag(
      uid: uid,
      ndef: _FakeNdef(
        maxSize: kNtag215MaxSize,
        cachedMessage: _messageOf(mime, payload),
      ),
    );

/// A blank but NDEF-formatted chip — what a factory-fresh NTAG215 looks like.
HwbTag _blankChip({String uid = kExpectedUid, int maxSize = kNtag215MaxSize}) =>
    HwbTag(
      uid: uid,
      ndef: _FakeNdef(
        maxSize: maxSize,
        cachedMessage: const NdefMessage(records: []),
      ),
    );

NfcPayloadService _service(MockNfcPayloadCodec codec, HwbTag tag) =>
    NfcPayloadService(codec: codec, tagSource: _FakeTagSource.tag(tag));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNfcPayloadCodec codec;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    codec = MockNfcPayloadCodec();
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Capacidad — el bug que dejó el dispositivo del cuidador en blanco
  // ══════════════════════════════════════════════════════════════════════════

  group('capacidad', () {
    test('el overhead del registro MIME es real y medible', () {
      final message = _messageOf(kHwbNdefMimeType, Uint8List(300));
      expect(message.byteLength, 300 + 32);
    });

    // El aviso previo del registro comparaba el payload con los 492 B del
    // chip, sin restar el registro: un payload de 459–492 B pasaba el aviso y
    // fallaba al grabar.
    test('el presupuesto del cuidador llena el chip exactamente', () {
      for (final int capacity in <int>[kNtag215NdefCapacity, 888]) {
        final int budget = guardianPayloadBudget(capacity);

        expect(
          _messageOf(kHwbGuardianMimeType, Uint8List(budget)).byteLength,
          capacity,
        );
        expect(
          _messageOf(kHwbGuardianMimeType, Uint8List(budget + 1)).byteLength,
          greaterThan(capacity),
        );
      }
      expect(guardianPayloadBudget(kNtag215NdefCapacity), 492 - 34);
    });

    test('el presupuesto nunca se pasa con un payload corto', () {
      final int budget = guardianPayloadBudget(kNtag215NdefCapacity);
      for (final int size in <int>[0, 100, 255, 256]) {
        expect(
          _messageOf(kHwbGuardianMimeType, Uint8List(size)).byteLength - size,
          lessThanOrEqualTo(kNtag215NdefCapacity - budget),
        );
      }
    });

    test(
      'rechaza un payload que el chequeo viejo habría dejado pasar',
      () async {
        final payload = Uint8List(470);
        when(
          () => codec.encode(any(), extraAad: any(named: 'extraAad')),
        ).thenAnswer((_) async => payload);
        final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
        final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

        await expectLater(
          service.writeTriagePayload({'a': 1}),
          throwsA(
            isA<NfcPayloadTooLargeException>()
                .having((e) => e.payloadBytes, 'payloadBytes', 470)
                .having((e) => e.messageBytes, 'messageBytes', 502)
                .having((e) => e.chipCapacity, 'chipCapacity', kNtag215MaxSize)
                .having((e) => e.overflowBytes, 'overflowBytes', 10),
          ),
        );
        expect(ndef.written, isNull, reason: 'no debe intentar escribir');
      },
    );

    test('acepta un payload que llena el chip exactamente', () async {
      final payload = Uint8List(kNtag215MaxSize - 32);
      when(
        () => codec.encode(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => payload);
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

      final result = await service.writeTriagePayload({'a': 1});
      expect(result.messageBytes, kNtag215MaxSize);
      expect(result.utilizationPercent, 100.0);
      expect(ndef.written, isNotNull);
    });

    test('rechaza un solo byte de más', () async {
      final payload = Uint8List(kNtag215MaxSize - 32 + 1);
      when(
        () => codec.encode(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => payload);
      final service = _service(
        codec,
        HwbTag(
          uid: kExpectedUid,
          ndef: _FakeNdef(maxSize: kNtag215MaxSize),
        ),
      );
      await expectLater(
        service.writeTriagePayload({'a': 1}),
        throwsA(
          isA<NfcPayloadTooLargeException>().having(
            (e) => e.overflowBytes,
            'overflowBytes',
            1,
          ),
        ),
      );
    });

    test('el payload del cuidador paga más overhead que el de triage', () {
      final triage = _messageOf(kHwbNdefMimeType, Uint8List(300)).byteLength;
      final guardian = _messageOf(
        kHwbGuardianMimeType,
        Uint8List(300),
      ).byteLength;
      expect(guardian, triage + 2);
    });

    test('NfcPayloadTooLargeException desglosa los tres números', () {
      final e = NfcPayloadTooLargeException(
        messageBytes: 819,
        payloadBytes: 787,
        chipCapacity: 492,
      );
      expect(e.overflowBytes, 327);
      expect(e.toString(), contains('819'));
      expect(e.toString(), contains('492'));
      expect(e.toString(), contains('327'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // writeTriagePayload
  // ══════════════════════════════════════════════════════════════════════════

  group('writeTriagePayload', () {
    setUp(() {
      when(
        () => codec.encode(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
    });

    test('escribe un único registro MIME de tipo triage', () async {
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

      final result = await service.writeTriagePayload({'fn': 'Martha'});

      expect(result.uid, kExpectedUid);
      expect(result.bytesWritten, 3);
      expect(ndef.written!.records, hasLength(1));
      final record = ndef.written!.records.single;
      expect(record.typeNameFormat, TypeNameFormat.media);
      expect(String.fromCharCodes(record.type), kHwbNdefMimeType);
      expect(record.payload, orderedEquals([1, 2, 3]));
      expect(record.identifier, isEmpty);
    });

    test('cifra antes de pedir el tap, no durante', () async {
      final service = _service(codec, _blankChip());
      await service.writeTriagePayload({'fn': 'Martha'});
      verify(
        () => codec.encode({'fn': 'Martha'}, extraAad: any(named: 'extraAad')),
      ).called(1);
    });

    test('falla si el chip no tiene identificador legible', () async {
      final service = _service(
        codec,
        HwbTag(
          uid: '',
          ndef: _FakeNdef(maxSize: kNtag215MaxSize),
        ),
      );
      await expectLater(
        service.writeTriagePayload({'a': 1}),
        throwsA(isA<NfcWriteException>()),
      );
    });

    test('falla si el chip no está formateado como NDEF', () async {
      final service = _service(codec, const HwbTag(uid: kExpectedUid));
      await expectLater(
        service.writeTriagePayload({'a': 1}),
        throwsA(
          isA<NfcWriteException>().having(
            (e) => e.message,
            'message',
            contains('NDEF'),
          ),
        ),
      );
    });

    test('falla si el chip es de solo lectura', () async {
      final service = _service(
        codec,
        HwbTag(
          uid: kExpectedUid,
          ndef: _FakeNdef(maxSize: kNtag215MaxSize, isWritable: false),
        ),
      );
      await expectLater(
        service.writeTriagePayload({'a': 1}),
        throwsA(isA<NfcWriteException>()),
      );
    });

    test('propaga el error del chip si write() falla', () async {
      final service = _service(
        codec,
        HwbTag(
          uid: kExpectedUid,
          ndef: _FakeNdef(
            maxSize: kNtag215MaxSize,
            writeError: StateError('tag lost'),
          ),
        ),
      );
      await expectLater(
        service.writeTriagePayload({'a': 1}),
        throwsA(isA<StateError>()),
      );
    });

    test('propaga NfcTimeoutException de la radio', () async {
      final service = NfcPayloadService(
        codec: codec,
        tagSource: _FakeTagSource.throws(
          NfcTimeoutException(const Duration(seconds: 20)),
        ),
      );
      await expectLater(
        service.writeTriagePayload({'a': 1}),
        throwsA(isA<NfcTimeoutException>()),
      );
    });

    test('propaga NfcCancelledException de la radio', () async {
      final service = NfcPayloadService(
        codec: codec,
        tagSource: _FakeTagSource.throws(NfcCancelledException()),
      );
      await expectLater(
        service.writeTriagePayload({'a': 1}),
        throwsA(isA<NfcCancelledException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // expectedUid — no sellar los datos de alguien en el chip equivocado
  // ══════════════════════════════════════════════════════════════════════════

  group('expectedUid', () {
    setUp(() {
      when(
        () => codec.encode(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
    });

    test('rechaza el tap cuando el UID no corresponde', () async {
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final service = _service(codec, HwbTag(uid: '11:22:33', ndef: ndef));

      await expectLater(
        service.writeTriagePayload({'a': 1}, expectedUid: kExpectedUid),
        throwsA(
          isA<NfcUidMismatchException>()
              .having((e) => e.expected, 'expected', kExpectedUid)
              .having((e) => e.actual, 'actual', '11:22:33'),
        ),
      );
      expect(ndef.written, isNull, reason: 'no debe escribir el chip ajeno');
    });

    test('acepta el mismo UID con formato distinto', () async {
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final service = _service(codec, HwbTag(uid: 'ab:cd:ef', ndef: ndef));
      await service.writeTriagePayload({'a': 1}, expectedUid: 'AB-CD-EF');
      expect(ndef.written, isNotNull);
    });

    test('sin expectedUid escribe cualquier chip', () async {
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final service = _service(codec, HwbTag(uid: '99:99', ndef: ndef));
      await service.writeTriagePayload({'a': 1});
      expect(ndef.written, isNotNull);
    });

    test('también aplica al dispositivo del cuidador', () async {
      final service = _service(
        codec,
        HwbTag(
          uid: '11:22',
          ndef: _FakeNdef(maxSize: kNtag215MaxSize),
        ),
      );
      await expectLater(
        service.writeGuardianPayload({'a': 1}, expectedUid: kExpectedUid),
        throwsA(isA<NfcUidMismatchException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // writeGuardianPayload
  // ══════════════════════════════════════════════════════════════════════════

  group('writeGuardianPayload', () {
    setUp(() {
      when(
        () => codec.encode(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => Uint8List.fromList([9, 8, 7]));
    });

    test('usa el MIME del cuidador, no el de triage', () async {
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));
      await service.writeGuardianPayload(<String, dynamic>{
        'patientInfo': <String, dynamic>{},
      });
      final record = ndef.written!.records.single;
      expect(String.fromCharCodes(record.type), kHwbGuardianMimeType);
    });

    test('reporta capacidad y utilización del chip', () async {
      final ndef = _FakeNdef(maxSize: 888); // NTAG216
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));
      final result = await service.writeGuardianPayload(<String, dynamic>{
        'a': 1,
      });
      expect(result.chipCapacity, 888);
      expect(result.bytesWritten, 3);
      expect(result.utilizationPercent, lessThan(10));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // writeGuardianRecord — capacidad dinámica (fit calculado dentro del tap)
  // ══════════════════════════════════════════════════════════════════════════

  group('writeGuardianRecord', () {
    setUp(() {
      when(
        () => codec.encode(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
    });

    GuardianFitBuilder recordingBuilder({
      required List<int> budgetSink,
      int kept = 1,
      int total = 3,
    }) {
      return (int budget) {
        budgetSink.add(budget);
        return GuardianPayloadFit(
          payload: const {'a': 1},
          includedConsultations: kept,
          includedVaccines: 0,
          totalConsultations: total,
          totalVaccines: 0,
          estimatedBytes: 3,
          fits: true,
        );
      };
    }

    test('hands buildFit the chip capacity minus record overhead', () async {
      final budgets = <int>[];
      final ndef = _FakeNdef(maxSize: 888); // NTAG216
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

      await service.writeGuardianRecord(
        buildFit: recordingBuilder(budgetSink: budgets),
      );

      expect(budgets, hasLength(1));
      expect(budgets.single, guardianPayloadBudget(888));
      expect(budgets.single, greaterThan(888 - 60));
    });

    test('carries the fit back on the result', () async {
      final ndef = _FakeNdef(maxSize: 888);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

      final result = await service.writeGuardianRecord(
        buildFit: recordingBuilder(budgetSink: <int>[], kept: 1, total: 3),
      );

      expect(result.fit, isNotNull);
      expect(result.fit!.droppedConsultations, 2);
      expect(result.fit!.isPartial, isTrue);
    });

    test('writes one guardian MIME record', () async {
      final ndef = _FakeNdef(maxSize: 888);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

      await service.writeGuardianRecord(
        buildFit: recordingBuilder(budgetSink: <int>[]),
      );

      expect(ndef.written!.records, hasLength(1));
      expect(
        String.fromCharCodes(ndef.written!.records.single.type),
        kHwbGuardianMimeType,
      );
    });

    test('falla si el chip no tiene identificador legible', () async {
      final service = _service(
        codec,
        HwbTag(uid: '', ndef: _FakeNdef(maxSize: 888)),
      );
      await expectLater(
        service.writeGuardianRecord(
          buildFit: recordingBuilder(budgetSink: <int>[]),
        ),
        throwsA(isA<NfcWriteException>()),
      );
    });

    test('falla si el chip no está formateado como NDEF', () async {
      final service = _service(codec, const HwbTag(uid: kExpectedUid));
      await expectLater(
        service.writeGuardianRecord(
          buildFit: recordingBuilder(budgetSink: <int>[]),
        ),
        throwsA(
          isA<NfcWriteException>().having(
            (e) => e.message,
            'message',
            contains('NDEF'),
          ),
        ),
      );
    });

    test('falla si el chip es de solo lectura', () async {
      final ndef = _FakeNdef(maxSize: 888, isWritable: false);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));
      await expectLater(
        service.writeGuardianRecord(
          buildFit: recordingBuilder(budgetSink: <int>[]),
        ),
        throwsA(isA<NfcWriteException>()),
      );
      expect(ndef.written, isNull);
    });

    test('rejects a chip whose UID does not match', () async {
      final ndef = _FakeNdef(maxSize: 888);
      final service = _service(codec, HwbTag(uid: '11:22', ndef: ndef));

      await expectLater(
        service.writeGuardianRecord(
          buildFit: recordingBuilder(budgetSink: <int>[]),
          expectedUid: kExpectedUid,
        ),
        throwsA(isA<NfcUidMismatchException>()),
      );
      expect(ndef.written, isNull);
    });

    test('throws when even the trimmed base does not fit', () async {
      when(
        () => codec.encode(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => Uint8List(600));
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

      await expectLater(
        service.writeGuardianRecord(
          buildFit: (int budget) => const GuardianPayloadFit(
            payload: {'a': 1},
            includedConsultations: 0,
            includedVaccines: 0,
            totalConsultations: 0,
            totalVaccines: 0,
            estimatedBytes: 600,
            fits: false,
          ),
        ),
        throwsA(isA<NfcPayloadTooLargeException>()),
      );
      expect(ndef.written, isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // readTriagePayload
  // ══════════════════════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════════════════════
  // Un dispositivo del cuidador por menor
  // ══════════════════════════════════════════════════════════════════════════

  group('writeGuardianRecord con patientId', () {
    GuardianPayloadFit fit(int _) => const GuardianPayloadFit(
      payload: {'a': 1},
      includedConsultations: 0,
      includedVaccines: 0,
      totalConsultations: 0,
      totalVaccines: 0,
      estimatedBytes: 3,
      fits: true,
    );

    void decodesTo(Map<String, dynamic>? data) {
      when(
        () => codec.decodeDetailed(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer(
        (_) async => data == null
            ? null
            : NfcDecodeResult(data: data, keyVersion: 0, hadHeader: false),
      );
    }

    setUp(() {
      when(
        () => codec.encode(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
    });

    Future<_FakeNdef> write(HwbTag tag) async {
      await _service(
        codec,
        tag,
      ).writeGuardianRecord(buildFit: fit, patientId: 'p-ana');
      return tag.ndef! as _FakeNdef;
    }

    test('rechaza la copia de otro menor y no graba nada', () async {
      decodesTo(<String, dynamic>{'patientId': 'p-hermano'});
      final tag = _chipWith(kHwbGuardianMimeType, Uint8List.fromList([7]));

      await expectLater(
        write(tag),
        throwsA(
          isA<NfcDeviceInUseException>().having(
            (e) => e.patientDevice,
            'patientDevice',
            isFalse,
          ),
        ),
      );
      expect((tag.ndef! as _FakeNdef).written, isNull);
    });

    test('lee el patientId de una copia con claves cortas', () async {
      decodesTo(<String, dynamic>{
        kAliasSchemaKey: kAliasSchemaVersion,
        'pid': 'p-hermano',
      });

      await expectLater(
        write(_chipWith(kHwbGuardianMimeType, Uint8List.fromList([7]))),
        throwsA(isA<NfcDeviceInUseException>()),
      );
    });

    test('rechaza un dispositivo del paciente', () async {
      decodesTo(<String, dynamic>{'fn': 'Martha'});

      await expectLater(
        write(_chipWith(kHwbNdefMimeType, Uint8List.fromList([1]))),
        throwsA(
          isA<NfcDeviceInUseException>().having(
            (e) => e.patientDevice,
            'patientDevice',
            isTrue,
          ),
        ),
      );
    });

    test('graba sobre la copia del mismo menor', () async {
      decodesTo(<String, dynamic>{'patientId': 'p-ana'});

      final ndef = await write(
        _chipWith(kHwbGuardianMimeType, Uint8List.fromList([7])),
      );

      expect(ndef.written, isNotNull);
    });

    test('graba sobre un dispositivo en blanco', () async {
      final ndef = await write(_blankChip());
      expect(ndef.written, isNotNull);
    });

    test('graba si ninguna llave abre lo que trae (no hay con qué '
        'comparar)', () async {
      decodesTo(null);

      final guardian = await write(
        _chipWith(kHwbGuardianMimeType, Uint8List.fromList([7])),
      );
      final patient = await write(
        _chipWith(kHwbNdefMimeType, Uint8List.fromList([1])),
      );

      expect(guardian.written, isNotNull);
      expect(patient.written, isNotNull);
    });

    test('una copia sin patientId no se puede atribuir: se graba', () async {
      decodesTo(<String, dynamic>{'patientInfo': <String, dynamic>{}});

      final ndef = await write(
        _chipWith(kHwbGuardianMimeType, Uint8List.fromList([7])),
      );

      expect(ndef.written, isNotNull);
    });

    test('sin patientId no compara (comportamiento anterior)', () async {
      decodesTo(<String, dynamic>{'patientId': 'p-hermano'});
      final tag = _chipWith(kHwbGuardianMimeType, Uint8List.fromList([7]));

      await _service(codec, tag).writeGuardianRecord(buildFit: fit);

      expect((tag.ndef! as _FakeNdef).written, isNotNull);
    });

    test('NfcDeviceInUseException se describe', () {
      expect(
        NfcDeviceInUseException(patientDevice: true).toString(),
        contains('patient device'),
      );
      expect(
        NfcDeviceInUseException(patientDevice: false).toString(),
        contains('guardian copy'),
      );
    });
  });

  group('readTriagePayload', () {
    test('devuelve el triage decodificado', () async {
      final payload = Uint8List.fromList([1, 2, 3]);
      when(
        () => codec.decodeDetailed(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer(
        (_) async => const NfcDecodeResult(
          data: <String, dynamic>{'fn': 'Martha'},
          keyVersion: 0,
          hadHeader: false,
        ),
      );

      final service = _service(codec, _chipWith(kHwbNdefMimeType, payload));
      final result = await service.readTriagePayload();

      expect(result.uid, kExpectedUid);
      expect(result.triage, isNotNull);
      verify(
        () => codec.decodeDetailed(payload, extraAad: any(named: 'extraAad')),
      ).called(1);
    });

    test('triage null cuando el chip está en blanco', () async {
      final service = _service(codec, _blankChip());
      final result = await service.readTriagePayload();
      expect(result.uid, kExpectedUid);
      expect(result.triage, isNull);
      verifyNever(
        () => codec.decodeDetailed(any(), extraAad: any(named: 'extraAad')),
      );
    });

    test('triage null cuando el chip no soporta NDEF', () async {
      final service = _service(codec, const HwbTag(uid: kExpectedUid));
      final result = await service.readTriagePayload();
      expect(result.triage, isNull);
    });

    test('triage null cuando el registro es de otro MIME', () async {
      final service = _service(
        codec,
        _chipWith(kHwbGuardianMimeType, Uint8List.fromList([1])),
      );
      final result = await service.readTriagePayload();
      expect(result.triage, isNull);
      verifyNever(
        () => codec.decodeDetailed(any(), extraAad: any(named: 'extraAad')),
      );
    });

    test('triage null cuando el codec no puede descifrar', () async {
      when(
        () => codec.decodeDetailed(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => null);
      final service = _service(
        codec,
        _chipWith(kHwbNdefMimeType, Uint8List.fromList([1])),
      );
      final result = await service.readTriagePayload();
      expect(result.triage, isNull);
    });

    test('ignora registros cuyo typeNameFormat no es media', () async {
      final service = _service(
        codec,
        HwbTag(
          uid: kExpectedUid,
          ndef: _FakeNdef(
            maxSize: kNtag215MaxSize,
            cachedMessage: NdefMessage(
              records: [
                NdefRecord(
                  typeNameFormat: TypeNameFormat.wellKnown,
                  type: Uint8List.fromList('T'.codeUnits),
                  identifier: Uint8List(0),
                  payload: Uint8List.fromList([1, 2, 3]),
                ),
              ],
            ),
          ),
        ),
      );
      final result = await service.readTriagePayload();
      expect(result.triage, isNull);
      verifyNever(
        () => codec.decodeDetailed(any(), extraAad: any(named: 'extraAad')),
      );
    });

    test('falla si el chip no tiene identificador legible', () async {
      final service = _service(codec, _blankChip(uid: ''));
      await expectLater(
        service.readTriagePayload(),
        throwsA(isA<NfcReadException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // readHwbChip — un solo tap, cualquiera de los dos chips
  // ══════════════════════════════════════════════════════════════════════════

  group('readHwbChip', () {
    test('none cuando el chip está en blanco de fábrica', () async {
      final service = _service(codec, _blankChip());
      final result = await service.readHwbChip();
      expect(result.kind, HwbChipKind.none);
      expect(result.uid, kExpectedUid);
      expect(result.triage, isNull);
      expect(result.guardianRecord, isNull);
    });

    test('none cuando el chip no está formateado como NDEF', () async {
      final service = _service(codec, const HwbTag(uid: kExpectedUid));
      final result = await service.readHwbChip();
      expect(result.kind, HwbChipKind.none);
      expect(result.uid, kExpectedUid);
    });

    test('guardian cuando el chip trae el registro del cuidador', () async {
      final payload = Uint8List.fromList([5, 5]);
      when(
        () => codec.decodeDetailed(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer(
        (_) async => const NfcDecodeResult(
          data: <String, dynamic>{'patientId': 'x'},
          keyVersion: 0,
          hadHeader: false,
        ),
      );
      final service = _service(codec, _chipWith(kHwbGuardianMimeType, payload));

      final result = await service.readHwbChip();

      expect(result.kind, HwbChipKind.guardian);
      expect(result.guardianRecord, {'patientId': 'x'});
      expect(result.triage, isNull);
    });

    test('triage cuando el chip solo trae el registro de triage', () async {
      when(
        () => codec.decodeDetailed(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer(
        (_) async => const NfcDecodeResult(
          data: <String, dynamic>{'fn': 'Martha'},
          keyVersion: 0,
          hadHeader: false,
        ),
      );
      final service = _service(
        codec,
        _chipWith(kHwbNdefMimeType, Uint8List.fromList([1])),
      );

      final result = await service.readHwbChip();

      expect(result.kind, HwbChipKind.triage);
      expect(result.triage, isNotNull);
      expect(result.guardianRecord, isNull);
    });

    test('prefiere el registro del cuidador si el chip trae los dos', () async {
      final guardianPayload = Uint8List.fromList([9]);
      when(
        () => codec.decodeDetailed(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer(
        (_) async => const NfcDecodeResult(
          data: <String, dynamic>{'patientId': 'x'},
          keyVersion: 0,
          hadHeader: false,
        ),
      );
      final service = _service(
        codec,
        HwbTag(
          uid: kExpectedUid,
          ndef: _FakeNdef(
            maxSize: kNtag215MaxSize,
            cachedMessage: NdefMessage(
              records: [
                NfcPayloadService.buildMimeRecord(
                  kHwbNdefMimeType,
                  Uint8List.fromList([1]),
                ),
                NfcPayloadService.buildMimeRecord(
                  kHwbGuardianMimeType,
                  guardianPayload,
                ),
              ],
            ),
          ),
        ),
      );

      final result = await service.readHwbChip();

      expect(result.kind, HwbChipKind.guardian);
      verify(
        () => codec.decodeDetailed(
          guardianPayload,
          extraAad: any(named: 'extraAad'),
        ),
      ).called(1);
    });

    test('none cuando el cuidador no se puede descifrar', () async {
      when(
        () => codec.decodeDetailed(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => null);
      final service = _service(
        codec,
        _chipWith(kHwbGuardianMimeType, Uint8List.fromList([1])),
      );
      final result = await service.readHwbChip();
      expect(result.kind, HwbChipKind.none);
      expect(result.guardianRecord, isNull);
    });

    test('conserva el UID aunque el chip no sea de HWB', () async {
      final service = _service(codec, _blankChip(uid: '04:03:46:71'));
      final result = await service.readHwbChip();
      expect(result.uid, '04:03:46:71');
      expect(result.kind, HwbChipKind.none);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Objetos de valor y excepciones
  // ══════════════════════════════════════════════════════════════════════════

  group('NfcWriteResult', () {
    test('utilizationPercent se calcula sobre el mensaje, no el payload', () {
      const result = NfcWriteResult(
        uid: 'AA',
        bytesWritten: 50,
        messageBytes: 100,
        chipCapacity: 200,
      );
      expect(result.utilizationPercent, 50.0);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Métricas de escritura: tamaños y conteos de cada escritura que salió bien
  // ══════════════════════════════════════════════════════════════════════════

  group('métricas de escritura', () {
    late List<NfcWriteMetric> reported;

    Future<void> record(NfcWriteMetric m) async => reported.add(m);

    NfcPayloadService observed(HwbTag tag, {NfcWriteObserver? onWritten}) =>
        NfcPayloadService(
          codec: codec,
          tagSource: _FakeTagSource.tag(tag),
          onWritten: onWritten ?? record,
        );

    setUp(() {
      reported = <NfcWriteMetric>[];
      when(() => codec.writeKeyVersion).thenReturn(0);
      when(
        () => codec.encode(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => Uint8List(150));
    });

    test(
      'una manilla escrita informa sus tamaños y nada de historial',
      () async {
        final result = await observed(
          _blankChip(),
        ).writeTriagePayload({'fn': 'Martha'});
        await pumpEventQueue();

        expect(reported, hasLength(1));
        final m = reported.single;
        expect(m.deviceRole, 'patient');
        expect(m.payloadFormat, kCurrentNfcPayloadFormat);
        expect(m.keyVersion, 0);
        expect(m.payloadBytes, 150);
        expect(m.messageBytes, result.messageBytes);
        expect(m.chipCapacity, kNtag215MaxSize);
        expect(m.consultationsKept, isNull);
        expect(m.vaccinesTotal, isNull);
        expect(m.writtenAt.isUtc, isTrue);
      },
    );

    test('una copia del acudiente informa cuánto historial cupo', () async {
      await observed(_blankChip(maxSize: 888)).writeGuardianRecord(
        buildFit: (int budget) => const GuardianPayloadFit(
          payload: {'a': 1},
          includedConsultations: 1,
          includedVaccines: 3,
          totalConsultations: 4,
          totalVaccines: 5,
          estimatedBytes: 178,
          fits: true,
        ),
      );
      await pumpEventQueue();

      expect(reported, hasLength(1));
      final m = reported.single;
      expect(m.deviceRole, 'guardian');
      expect(m.chipCapacity, 888);
      expect(m.consultationsKept, 1);
      // El registro tiene 4 y 5, pero la copia nunca lleva más de 3: el total
      // es lo que cabría en un chip sin límite, y sólo la capacidad dejó fuera
      // dos consultas.
      expect(m.consultationsTotal, 3);
      expect(m.vaccinesKept, 3);
      expect(m.vaccinesTotal, 3);
    });

    test(
      'la copia escrita con writeGuardianPayload cuenta como acudiente',
      () async {
        await observed(_blankChip()).writeGuardianPayload({'a': 1});
        await pumpEventQueue();

        expect(reported.single.deviceRole, 'guardian');
        expect(reported.single.consultationsKept, isNull);
      },
    );

    test('una escritura que no cabe no informa nada', () async {
      when(
        () => codec.encode(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => Uint8List(600));

      await expectLater(
        observed(_blankChip()).writeTriagePayload({'fn': 'Martha'}),
        throwsA(isA<NfcPayloadTooLargeException>()),
      );
      await pumpEventQueue();

      expect(reported, isEmpty);
    });

    test('un chip de otro paciente no informa nada', () async {
      await expectLater(
        observed(
          _blankChip(uid: '11:22:33'),
        ).writeTriagePayload({'fn': 'Martha'}, expectedUid: kExpectedUid),
        throwsA(isA<NfcUidMismatchException>()),
      );
      await pumpEventQueue();

      expect(reported, isEmpty);
    });

    test('si registrar la métrica falla, la escritura sigue bien', () async {
      final result = await observed(
        _blankChip(),
        onWritten: (NfcWriteMetric m) async => throw StateError('disco lleno'),
      ).writeTriagePayload({'fn': 'Martha'});
      await pumpEventQueue();

      expect(result.uid, kExpectedUid);
    });

    test('sin observador escribe igual', () async {
      final result = await _service(
        codec,
        _blankChip(),
      ).writeTriagePayload({'fn': 'Martha'});

      expect(result.bytesWritten, 150);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Formato 2 (ADR 005): registro externo, CBOR tipado, diccionario
  // ══════════════════════════════════════════════════════════════════════════

  group('formato 2', () {
    const String hexKey =
        '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20';
    final NfcPayloadCodec real = NfcPayloadCodec.fromKeyring(
      keyring: NfcKeyring.single(hexKey),
    );

    PatientFullRecord record() => PatientFullRecord(
      patientId: '3b2e1f00-aaaa-4bbb-8ccc-0123456789ab',
      deviceUid: kExpectedUid,
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: 'PT',
          documentNumber: '1234567890',
        ),
        firstLastName: 'Rodríguez',
        firstName: 'Valentina',
        dob: '2019-03-14',
        biologicalSex: 'F',
        address: Address(city: 'Cúcuta', state: 'Norte de Santander'),
        bloodType: 'O+',
      ),
      guardianInfo: GuardianInfo(
        name: 'María Pérez',
        relationship: '01',
        phone: '3001234567',
        deviceUid: '04:11:22:33',
      ),
      medicalHistory: <MedicalHistoryItem>[
        MedicalHistoryItem(
          encounterIdentifier: '7f1c2a9e-0b4d-4c3e-9a51-2d6f8e0c1b77',
          startDateTime: '2026-06-10T09:30:00-05:00',
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Fiebre de 3 días y tos seca.',
          ),
        ),
      ],
    );

    NfcPayloadService writer(
      HwbTag tag, {
      NfcPayloadCodec? codec,
      NfcPayloadFormat format = NfcPayloadFormat.v2,
    }) => NfcPayloadService(
      codec: codec ?? real,
      tagSource: _FakeTagSource.tag(tag),
      writeFormat: format,
    );

    /// The same chip after the write, as the next tap would see it.
    HwbTag readBack(_FakeNdef ndef, {String uid = kExpectedUid}) => HwbTag(
      uid: uid,
      ndef: _FakeNdef(maxSize: ndef.maxSize, cachedMessage: ndef.written),
    );

    test('una escritura en formato 2 se informa como formato 2', () async {
      final reported = <NfcWriteMetric>[];
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);

      final result =
          await NfcPayloadService(
            codec: real,
            tagSource: _FakeTagSource.tag(
              HwbTag(uid: kExpectedUid, ndef: ndef),
            ),
            writeFormat: NfcPayloadFormat.v2,
            onWritten: (NfcWriteMetric m) async => reported.add(m),
          ).writeTriagePayload(
            NfcTriagePayload.buildPatientPayload(record: record()),
            expectedUid: kExpectedUid,
          );
      await pumpEventQueue();

      expect(reported, hasLength(1));
      expect(reported.single.payloadFormat, 2);
      expect(reported.single.deviceRole, 'patient');
      expect(reported.single.messageBytes, result.messageBytes);
      expect(reported.single.messageBytes, ndef.written!.byteLength);
    });

    test('la manilla se escribe en un registro externo y se lee', () async {
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final payload = NfcTriagePayload.buildPatientPayload(record: record());

      await writer(
        HwbTag(uid: kExpectedUid, ndef: ndef),
      ).writeTriagePayload(payload, expectedUid: kExpectedUid);

      final written = ndef.written!.records.single;
      expect(written.typeNameFormat, TypeNameFormat.external);
      expect(String.fromCharCodes(written.type), kHwbTriageV2Type);

      // Lo lee un servicio que escribe formato 1: toda build lee los dos.
      final read = await writer(
        readBack(ndef),
        format: NfcPayloadFormat.v1,
      ).readHwbChip();
      expect(read.kind, HwbChipKind.triage);
      expect(read.triage!.firstName, 'Valentina');
      expect(read.triage!.dob, '2019-03-14');
      expect(read.triage!.guardianDeviceUid, '04:11:22:33');
      expect(read.keyVersion, kLegacyNfcKeyVersion);
    });

    test(
      'la copia del acudiente se ajusta al presupuesto del formato 2',
      () async {
        final budgets = <int>[];
        final ndef = _FakeNdef(maxSize: 872);
        final GuardianFitBuilder fit = guardianFitBuilder(
          record: record(),
          codec: real,
          format: NfcPayloadFormat.v2,
        );

        final result = await writer(HwbTag(uid: kExpectedUid, ndef: ndef))
            .writeGuardianRecord(
              buildFit: (int budget) {
                budgets.add(budget);
                return fit(budget);
              },
            );

        expect(
          budgets.single,
          guardianPayloadBudget(872, format: NfcPayloadFormat.v2),
        );
        expect(
          String.fromCharCodes(ndef.written!.records.single.type),
          kHwbGuardianV2Type,
        );
        expect(result.messageBytes, ndef.written!.byteLength);

        final read = await writer(readBack(ndef)).readHwbChip();
        expect(read.kind, HwbChipKind.guardian);
        expect(read.guardianRecord, result.fit!.payload);
        final rebuilt = NfcGuardianPayload.reconstructFromGuardian(
          read.guardianRecord!,
        );
        expect(
          rebuilt.medicalHistory.single.encounterIdentifier,
          '7f1c2a9e-0b4d-4c3e-9a51-2d6f8e0c1b77',
        );
      },
    );

    test('el registro externo deja más presupuesto que el MIME', () {
      final int v1 = guardianPayloadBudget(492, format: NfcPayloadFormat.v1);
      final int v2 = guardianPayloadBudget(492, format: NfcPayloadFormat.v2);
      expect(v1, 492 - 34);
      expect(v2, 492 - 23);
    });

    test('un servicio de formato 2 sigue leyendo chips de formato 1', () async {
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      await writer(
        HwbTag(uid: kExpectedUid, ndef: ndef),
        format: NfcPayloadFormat.v1,
      ).writeTriagePayload(
        NfcTriagePayload.buildPatientPayload(record: record()),
      );
      expect(ndef.written!.records.single.typeNameFormat, TypeNameFormat.media);

      final read = await writer(readBack(ndef)).readHwbChip();
      expect(read.kind, HwbChipKind.triage);
      expect(read.triage!.lastName, 'Rodríguez');
    });

    test('con llave versión 1 queda amarrado al chip', () async {
      final NfcPayloadCodec v1Key = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(hexKey, version: 1),
      );
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      await writer(
        HwbTag(uid: kExpectedUid, ndef: ndef),
        codec: v1Key,
      ).writeTriagePayload(
        NfcTriagePayload.buildPatientPayload(record: record()),
        expectedUid: kExpectedUid,
      );

      final own = await writer(readBack(ndef), codec: v1Key).readHwbChip();
      expect(own.kind, HwbChipKind.triage);
      expect(own.keyVersion, 1);
      expect(own.hadHeader, isTrue);

      // El mismo contenido copiado a otro chip no se abre.
      final copied = await writer(
        readBack(ndef, uid: '99:88:77'),
        codec: v1Key,
      ).readHwbChip();
      expect(copied.kind, HwbChipKind.none);
    });

    test('rechaza la copia de otro paciente también en formato 2', () async {
      final ndef = _FakeNdef(maxSize: 872);
      await writer(HwbTag(uid: kExpectedUid, ndef: ndef)).writeGuardianRecord(
        buildFit: guardianFitBuilder(
          record: record(),
          codec: real,
          format: NfcPayloadFormat.v2,
        ),
      );

      await expectLater(
        writer(readBack(ndef)).writeGuardianRecord(
          buildFit: guardianFitBuilder(
            record: record(),
            codec: real,
            format: NfcPayloadFormat.v2,
          ),
          patientId: 'otro-paciente',
        ),
        throwsA(isA<NfcDeviceInUseException>()),
      );
    });

    test(
      'una manilla de formato 2 cuenta como dispositivo de paciente',
      () async {
        final ndef = _FakeNdef(maxSize: 872);
        await writer(HwbTag(uid: kExpectedUid, ndef: ndef)).writeTriagePayload(
          NfcTriagePayload.buildPatientPayload(record: record()),
        );

        await expectLater(
          writer(readBack(ndef)).writeGuardianRecord(
            buildFit: guardianFitBuilder(
              record: record(),
              codec: real,
              format: NfcPayloadFormat.v2,
            ),
            patientId: record().patientId,
          ),
          throwsA(
            isA<NfcDeviceInUseException>().having(
              (NfcDeviceInUseException e) => e.patientDevice,
              'patientDevice',
              isTrue,
            ),
          ),
        );
      },
    );

    test('lo que no volvería idéntico no se escribe', () async {
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);

      await expectLater(
        writer(
          HwbTag(uid: kExpectedUid, ndef: ndef),
        ).writeTriagePayload(<String, dynamic>{'docN': 123}),
        throwsA(isA<NfcWriteException>()),
      );
      expect(ndef.written, isNull);
    });

    test('un registro externo dañado se lee como chip sin datos', () async {
      final tag = HwbTag(
        uid: kExpectedUid,
        ndef: _FakeNdef(
          maxSize: kNtag215MaxSize,
          cachedMessage: NdefMessage(
            records: <NdefRecord>[
              buildExternalRecord(kHwbTriageV2Type, Uint8List(60)),
            ],
          ),
        ),
      );

      final read = await writer(tag).readHwbChip();

      expect(read.kind, HwbChipKind.none);
    });

    test(
      'la lectura de triaje por separado también lee el formato 2',
      () async {
        final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
        await writer(HwbTag(uid: kExpectedUid, ndef: ndef)).writeTriagePayload(
          NfcTriagePayload.buildPatientPayload(record: record()),
        );

        final read = await writer(readBack(ndef)).readTriagePayload();

        expect(read.triage!.documentNumber, '1234567890');
      },
    );
  });

  group('HwbChipReadResult', () {
    test('los campos opcionales son null por defecto', () {
      const result = HwbChipReadResult(uid: 'AA', kind: HwbChipKind.none);
      expect(result.triage, isNull);
      expect(result.guardianRecord, isNull);
    });
  });

  group('excepciones', () {
    test('NfcWriteException devuelve su mensaje', () {
      expect(NfcWriteException('boom').toString(), 'boom');
    });

    test('NfcReadException devuelve su mensaje', () {
      expect(NfcReadException('boom').toString(), 'boom');
    });

    test('NfcUidMismatchException describe ambos UIDs', () {
      final e = NfcUidMismatchException(expected: 'AA:BB', actual: 'CC:DD');
      expect(e.toString(), contains('AA:BB'));
      expect(e.toString(), contains('CC:DD'));
    });

    test('NfcNotAvailableException es una sola clase en toda la app', () {
      expect(NfcNotAvailableException().toString(), isNotEmpty);
    });
  });

  group('constructor sin tagSource', () {
    test('usa el NfcSessionManager singleton como fuente de tags', () {
      final service = NfcPayloadService(codec: codec);

      expect(service.codec, same(codec));
      expect(NfcSessionManager.instance, isA<NfcTagSource>());
    });

    test('un tagSource explícito sigue teniendo prioridad', () async {
      final tag = _blankChip();
      final service = NfcPayloadService(
        codec: codec,
        tagSource: _FakeTagSource.tag(tag),
      );

      final result = await service.readHwbChip();

      expect(result.uid, kExpectedUid);
      expect(result.kind, HwbChipKind.none);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Binding al chip — la clave de escritura ya no es la legacy
  // ══════════════════════════════════════════════════════════════════════════

  group('binding al chip', () {
    // Any version that is neither null nor the legacy one turns binding on.
    const int boundVersion = kLegacyNfcKeyVersion + 1;

    setUp(() {
      when(
        () => codec.encode(any(), extraAad: any(named: 'extraAad')),
      ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
    });

    /// The extraAad handed to the (single) codec.encode call.
    Uint8List? capturedAad() {
      final captured = verify(
        () => codec.encode(any(), extraAad: captureAny(named: 'extraAad')),
      ).captured;
      expect(captured, hasLength(1), reason: 'encode debe llamarse una vez');
      return captured.single as Uint8List?;
    }

    test('sin versión de clave (null) no ata el payload al chip', () async {
      when(() => codec.writeKeyVersion).thenReturn(null);
      final service = _service(codec, _blankChip());

      await service.writeTriagePayload({'a': 1}, expectedUid: kExpectedUid);

      expect(capturedAad(), isNull);
    });

    test('con la clave legacy no ata el payload al chip', () async {
      when(() => codec.writeKeyVersion).thenReturn(kLegacyNfcKeyVersion);
      final service = _service(codec, _blankChip());

      await service.writeTriagePayload({'a': 1}, expectedUid: kExpectedUid);

      expect(capturedAad(), isNull);
    });

    test(
      'sin expectedUid cifra dentro del tap, atado al UID del chip',
      () async {
        when(() => codec.writeKeyVersion).thenReturn(boundVersion);
        final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
        final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

        final result = await service.writeTriagePayload({'a': 1});

        expect(
          capturedAad(),
          orderedEquals(chipBindingAad(kExpectedUid, kHwbNdefMimeType)),
        );
        expect(result.bytesWritten, 3);
        expect(ndef.written!.records, hasLength(1));
        final record = ndef.written!.records.single;
        expect(String.fromCharCodes(record.type), kHwbNdefMimeType);
        expect(record.payload, orderedEquals([1, 2, 3]));
      },
    );

    test('con expectedUid vacío también cifra dentro del tap', () async {
      when(() => codec.writeKeyVersion).thenReturn(boundVersion);
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

      await service.writeTriagePayload({'a': 1}, expectedUid: '');

      expect(
        capturedAad(),
        orderedEquals(chipBindingAad(kExpectedUid, kHwbNdefMimeType)),
      );
      expect(ndef.written, isNotNull);
    });

    test('con expectedUid cifra antes del tap, atado a ese UID', () async {
      when(() => codec.writeKeyVersion).thenReturn(boundVersion);
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      // Same chip, different UID formatting: the binding is normalized.
      final service = _service(codec, HwbTag(uid: 'ab:cd:ef', ndef: ndef));

      await service.writeTriagePayload({'a': 1}, expectedUid: 'AB-CD-EF');

      expect(
        capturedAad(),
        orderedEquals(chipBindingAad(kExpectedUid, kHwbNdefMimeType)),
        reason: 'el payload ya cifrado se reutiliza, sin cifrar de nuevo',
      );
      expect(ndef.written!.records.single.payload, orderedEquals([1, 2, 3]));
    });

    test('el cuidador usa su propio MIME en el binding', () async {
      when(() => codec.writeKeyVersion).thenReturn(boundVersion);
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

      await service.writeGuardianPayload({'a': 1});

      expect(
        capturedAad(),
        orderedEquals(chipBindingAad(kExpectedUid, kHwbGuardianMimeType)),
      );
      expect(
        String.fromCharCodes(ndef.written!.records.single.type),
        kHwbGuardianMimeType,
      );
    });

    test('writeGuardianRecord ata el payload al UID del chip', () async {
      when(() => codec.writeKeyVersion).thenReturn(boundVersion);
      final ndef = _FakeNdef(maxSize: 888);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

      await service.writeGuardianRecord(
        buildFit: (int budget) => const GuardianPayloadFit(
          payload: {'a': 1},
          includedConsultations: 1,
          includedVaccines: 0,
          totalConsultations: 1,
          totalVaccines: 0,
          estimatedBytes: 3,
          fits: true,
        ),
      );

      expect(
        capturedAad(),
        orderedEquals(chipBindingAad(kExpectedUid, kHwbGuardianMimeType)),
      );
      expect(ndef.written, isNotNull);
    });

    test('writeGuardianRecord con clave legacy no ata el payload', () async {
      when(() => codec.writeKeyVersion).thenReturn(kLegacyNfcKeyVersion);
      final service = _service(
        codec,
        HwbTag(uid: kExpectedUid, ndef: _FakeNdef(maxSize: 888)),
      );

      await service.writeGuardianRecord(
        buildFit: (int budget) => const GuardianPayloadFit(
          payload: {'a': 1},
          includedConsultations: 1,
          includedVaccines: 0,
          totalConsultations: 1,
          totalVaccines: 0,
          estimatedBytes: 3,
          fits: true,
        ),
      );

      expect(capturedAad(), isNull);
    });
  });
}
