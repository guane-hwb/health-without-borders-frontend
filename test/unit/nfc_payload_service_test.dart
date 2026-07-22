// test/unit/nfc_payload_service_test.dart

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nfc_manager/ndef_record.dart';

import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_session_manager.dart';

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
  // Capacidad — el bug que dejó la tarjeta del guardián en blanco
  // ══════════════════════════════════════════════════════════════════════════

  group('capacidad', () {
    test('el overhead del registro MIME es real y medible', () {
      // 3 (header + type len + payload len) + 26 (application/vnd.hwb.triage)
      // + 3 (registro largo, payload > 255). El chequeo viejo lo ignoraba.
      final message = _messageOf(kHwbNdefMimeType, Uint8List(300));
      expect(message.byteLength, 300 + 32);
    });

    test(
      'rechaza un payload que el chequeo viejo habría dejado pasar',
      () async {
        // 470 bytes contra un NTAG215 de 492: el chequeo anterior comparaba
        // payload contra maxSize (470 <= 492 → pasa) y reventaba dentro de
        // write(). El mensaje NDEF real ocupa 502.
        final payload = Uint8List(470);
        when(() => codec.encode(any())).thenAnswer((_) async => payload);
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
      when(() => codec.encode(any())).thenAnswer((_) async => payload);
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));

      final result = await service.writeTriagePayload({'a': 1});
      expect(result.messageBytes, kNtag215MaxSize);
      expect(result.utilizationPercent, 100.0);
      expect(ndef.written, isNotNull);
    });

    test('rechaza un solo byte de más', () async {
      final payload = Uint8List(kNtag215MaxSize - 32 + 1);
      when(() => codec.encode(any())).thenAnswer((_) async => payload);
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

    test('el payload del guardián paga más overhead que el de triage', () {
      // 'application/vnd.hwb.guardian' es dos caracteres más largo.
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
        () => codec.encode(any()),
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
      // Si encode() ocurriera dentro de withTag, el chip tendría que quedarse
      // en el campo mientras corre CBOR + DEFLATE + AES-GCM.
      final service = _service(codec, _blankChip());
      await service.writeTriagePayload({'fn': 'Martha'});
      verify(() => codec.encode({'fn': 'Martha'})).called(1);
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
      // Una DESFire virgen se ve así: Ndef.from(tag) devuelve null.
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
        () => codec.encode(any()),
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

    test('también aplica a la tarjeta del guardián', () async {
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
        () => codec.encode(any()),
      ).thenAnswer((_) async => Uint8List.fromList([9, 8, 7]));
    });

    test('usa el MIME del guardián, no el de triage', () async {
      final ndef = _FakeNdef(maxSize: kNtag215MaxSize);
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));
      await service.writeGuardianPayload({'patientInfo': {}});
      final record = ndef.written!.records.single;
      expect(String.fromCharCodes(record.type), kHwbGuardianMimeType);
    });

    test('reporta capacidad y utilización del chip', () async {
      final ndef = _FakeNdef(maxSize: 888); // NTAG216
      final service = _service(codec, HwbTag(uid: kExpectedUid, ndef: ndef));
      final result = await service.writeGuardianPayload({'a': 1});
      expect(result.chipCapacity, 888);
      expect(result.bytesWritten, 3);
      expect(result.utilizationPercent, lessThan(10));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // readTriagePayload
  // ══════════════════════════════════════════════════════════════════════════

  group('readTriagePayload', () {
    test('devuelve el triage decodificado', () async {
      final payload = Uint8List.fromList([1, 2, 3]);
      when(
        () => codec.decode(any()),
      ).thenAnswer((_) async => <String, dynamic>{'fn': 'Martha'});

      final service = _service(codec, _chipWith(kHwbNdefMimeType, payload));
      final result = await service.readTriagePayload();

      expect(result.uid, kExpectedUid);
      expect(result.triage, isNotNull);
      verify(() => codec.decode(payload)).called(1);
    });

    test('triage null cuando el chip está en blanco', () async {
      final service = _service(codec, _blankChip());
      final result = await service.readTriagePayload();
      expect(result.uid, kExpectedUid);
      expect(result.triage, isNull);
      verifyNever(() => codec.decode(any()));
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
      verifyNever(() => codec.decode(any()));
    });

    test('triage null cuando el codec no puede descifrar', () async {
      when(() => codec.decode(any())).thenAnswer((_) async => null);
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
      verifyNever(() => codec.decode(any()));
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
      // Exactamente lo que reporta un NTAG215 virgen: formateado, mensaje de
      // 0 bytes. Es el estado en que quedó la tarjeta del guardián al fallar
      // siempre la escritura por capacidad.
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

    test('guardian cuando el chip trae el registro del guardián', () async {
      final payload = Uint8List.fromList([5, 5]);
      when(
        () => codec.decode(any()),
      ).thenAnswer((_) async => <String, dynamic>{'patientId': 'x'});
      final service = _service(codec, _chipWith(kHwbGuardianMimeType, payload));

      final result = await service.readHwbChip();

      expect(result.kind, HwbChipKind.guardian);
      expect(result.guardianRecord, {'patientId': 'x'});
      expect(result.triage, isNull);
    });

    test('triage cuando el chip solo trae el registro de triage', () async {
      when(
        () => codec.decode(any()),
      ).thenAnswer((_) async => <String, dynamic>{'fn': 'Martha'});
      final service = _service(
        codec,
        _chipWith(kHwbNdefMimeType, Uint8List.fromList([1])),
      );

      final result = await service.readHwbChip();

      expect(result.kind, HwbChipKind.triage);
      expect(result.triage, isNotNull);
      expect(result.guardianRecord, isNull);
    });

    test('prefiere el registro del guardián si el chip trae los dos', () async {
      // El del guardián es un superconjunto del de triage.
      final guardianPayload = Uint8List.fromList([9]);
      when(
        () => codec.decode(any()),
      ).thenAnswer((_) async => <String, dynamic>{'patientId': 'x'});
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
      verify(() => codec.decode(guardianPayload)).called(1);
    });

    test('none cuando el guardián no se puede descifrar', () async {
      when(() => codec.decode(any())).thenAnswer((_) async => null);
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
      // Antes estaba declarada por separado en nfc_service_mobile.dart y en
      // nfc_payload_service.dart: dos clases distintas con el mismo nombre que
      // ningún archivo podía importar a la vez.
      expect(NfcNotAvailableException().toString(), isNotEmpty);
    });
  });
}
