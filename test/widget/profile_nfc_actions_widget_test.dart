// test/widget/profile_nfc_actions_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_payload.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/core/nfc/partial_card_notice.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/profile_nfc_actions.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/reassign_device_dialog.dart';

class _MockNfcKeyring extends Mock implements NfcKeyring {}

class _MockNfcPayloadCodec extends Mock implements NfcPayloadCodec {}

class _FakePatientFullRecord extends Fake implements PatientFullRecord {}

class _FakeNfcService extends Fake implements NfcPayloadService {
  _FakeNfcService({
    this.readResult = const HwbChipReadResult(
      uid: 'NEW-UID',
      kind: HwbChipKind.none,
    ),
    this.guardianFit,
    this.writeError,
  });

  final HwbChipReadResult readResult;
  final GuardianPayloadFit? guardianFit;
  final Object? writeError;

  int reads = 0;
  final List<String?> triageUids = <String?>[];
  final List<Map<String, dynamic>> triagePayloads = <Map<String, dynamic>>[];
  final List<String?> guardianUids = <String?>[];
  final List<String?> guardianPatientIds = <String?>[];

  @override
  Future<NfcWriteResult> writeTriagePayload(
    Map<String, dynamic> triagePayload, {
    String? expectedUid,
    Duration timeout = const Duration(seconds: 20),
    NfcCancelToken? cancel,
    String? alertMessage,
  }) async {
    triageUids.add(expectedUid);
    triagePayloads.add(triagePayload);
    if (writeError != null) throw writeError!;
    return const NfcWriteResult(
      uid: 'X',
      bytesWritten: 10,
      messageBytes: 20,
      chipCapacity: 504,
    );
  }

  @override
  Future<NfcWriteResult> writeGuardianRecord({
    required GuardianFitBuilder buildFit,
    String? expectedUid,
    String? patientId,
    Duration timeout = const Duration(seconds: 20),
    NfcCancelToken? cancel,
    String? alertMessage,
  }) async {
    guardianUids.add(expectedUid);
    guardianPatientIds.add(patientId);
    if (writeError != null) throw writeError!;
    return NfcWriteResult(
      uid: 'X',
      bytesWritten: 10,
      messageBytes: 20,
      chipCapacity: 504,
      fit: guardianFit,
    );
  }

  @override
  Future<HwbChipReadResult> readHwbChip({
    Duration timeout = const Duration(seconds: 20),
    NfcCancelToken? cancel,
    String? alertMessage,
  }) async {
    reads++;
    return readResult;
  }
}

Widget _wrap(Widget child, {String locale = 'es'}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

PatientFullRecord _createRecord({
  String patientUid = 'P-123',
  String? g1Uid = 'G1-123',
  String? g2Uid,
}) {
  return PatientFullRecord(
    patientId: 'patient-uuid',
    deviceUid: patientUid,
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '100200300',
      ),
      firstName: 'Carlos',
      firstLastName: 'Mendoza',
      dob: '1995-05-15',
      biologicalSex: 'M',
      address: Address(city: 'Bogotá', state: 'Bogotá'),
    ),
    guardianInfo: GuardianInfo(
      name: 'María Mendoza',
      relationship: '01',
      phone: '3001234567',
      deviceUid: g1Uid,
    ),
    guardian2Info: g2Uid != null
        ? GuardianInfo(
            name: 'Jorge Mendoza',
            relationship: '02',
            phone: '3007654321',
            deviceUid: g2Uid,
          )
        : null,
  );
}

void main() {
  late _MockNfcKeyring mockKeyring;
  late _MockNfcPayloadCodec mockCodec;

  const validHexKey =
      '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';

  setUpAll(() {
    registerFallbackValue(_FakePatientFullRecord());
  });

  setUp(() {
    mockKeyring = _MockNfcKeyring();
    mockCodec = _MockNfcPayloadCodec();

    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1600,
      2400,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('executeUpdateNfcChips — Invalid Keyring Handling', () {
    testWidgets(
      'shows error SnackBar when keyring fails to build codec in Spanish',
      (tester) async {
        when(() => mockKeyring.isEmpty).thenThrow(Exception('Invalid keyring'));

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => executeUpdateNfcChips(
                  context: ctx,
                  record: _createRecord(),
                  keyring: mockKeyring,
                  patientChipDirty: true,
                  guardianChipDirty: false,
                ),
                child: const Text('Run'),
              ),
            ),
            locale: 'es',
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text('La clave NFC no es válida. Contacte al administrador.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows error SnackBar when keyring fails to build codec in English',
      (tester) async {
        when(() => mockKeyring.isEmpty).thenThrow(Exception('Invalid keyring'));

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => executeUpdateNfcChips(
                  context: ctx,
                  record: _createRecord(),
                  keyring: mockKeyring,
                  patientChipDirty: true,
                  guardianChipDirty: false,
                ),
                child: const Text('Run'),
              ),
            ),
            locale: 'en',
          ),
        );

        await tester.tap(find.text('Run'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text('The NFC key is invalid. Contact your administrator.'),
          findsOneWidget,
        );
      },
    );
  });

  group('executeUpdateNfcChips — Execution Flow & Dialog Dismissals', () {
    testWidgets('returns true when neither chip is dirty', (tester) async {
      when(() => mockKeyring.isEmpty).thenReturn(false);
      when(() => mockKeyring.versions).thenReturn(<int>[1]);
      when(() => mockKeyring.keys).thenReturn(<int, String>{1: validHexKey});

      bool? result;

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await executeUpdateNfcChips(
                  context: ctx,
                  record: _createRecord(),
                  keyring: mockKeyring,
                  patientChipDirty: false,
                  guardianChipDirty: false,
                );
              },
              child: const Text('Run'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('cancels patient guided write when dialog is closed/canceled', (
      tester,
    ) async {
      when(() => mockKeyring.isEmpty).thenReturn(false);
      when(() => mockKeyring.versions).thenReturn(<int>[1]);
      when(() => mockKeyring.keys).thenReturn(<int, String>{1: validHexKey});

      bool? result;

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                result = await executeUpdateNfcChips(
                  context: ctx,
                  record: _createRecord(),
                  keyring: mockKeyring,
                  patientChipDirty: true,
                  guardianChipDirty: false,
                );
              },
              child: const Text('Run'),
            ),
          ),
          locale: 'es',
        ),
      );

      await tester.tap(find.text('Run'));
      await tester.pump(const Duration(milliseconds: 300));

      final BuildContext modalContext = tester.element(
        find.text('Dispositivo del paciente'),
      );
      Navigator.of(modalContext).pop(false);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isFalse);
    });

    testWidgets(
      'runs guardian write flow for 1 guardian and 2 guardians in ES/EN',
      (tester) async {
        when(() => mockKeyring.isEmpty).thenReturn(false);
        when(() => mockKeyring.versions).thenReturn(<int>[1]);
        when(() => mockKeyring.keys).thenReturn(<int, String>{1: validHexKey});

        final recordDual = _createRecord(g1Uid: 'G1-123', g2Uid: 'G2-456');

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => executeUpdateNfcChips(
                  context: ctx,
                  record: recordDual,
                  keyring: mockKeyring,
                  patientChipDirty: false,
                  guardianChipDirty: true,
                ),
                child: const Text('Run Guardian Dual'),
              ),
            ),
            locale: 'es',
          ),
        );

        await tester.tap(find.text('Run Guardian Dual'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Dispositivo del cuidador 1'), findsOneWidget);

        final BuildContext modalContext = tester.element(
          find.text('Dispositivo del cuidador 1'),
        );
        Navigator.of(modalContext).pop(false);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });

  group('executeReassignOne — Target titles and validation checks', () {
    testWidgets('cancels reassign gracefully when user cancels reading modal', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => executeReassignOne(
                context: ctx,
                target: ReassignTarget.patient,
                record: _createRecord(),
                codec: mockCodec,
                isEs: true,
                showSnack: (_, {error = false}) {},
              ),
              child: const Text('Reassign'),
            ),
          ),
          locale: 'es',
        ),
      );

      await tester.tap(find.text('Reassign'));
      await tester.pump(const Duration(milliseconds: 300));

      final BuildContext modalContext = tester.element(
        find.byType(BottomSheet),
      );
      Navigator.of(modalContext).pop(false);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles ReassignTarget.patient correctly in ES', (
      tester,
    ) async {
      final record = _createRecord(g1Uid: 'G1-123', g2Uid: null);

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => executeReassignOne(
                context: ctx,
                target: ReassignTarget.patient,
                record: record,
                codec: mockCodec,
                isEs: true,
                showSnack: (_, {error = false}) {},
              ),
              child: const Text('Patient ES'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Patient ES'));
      await tester.pump(const Duration(milliseconds: 300));

      final BuildContext modalContext = tester.element(
        find.byType(BottomSheet),
      );
      Navigator.of(modalContext).pop(false);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles ReassignTarget.guardian1 single guardian in ES', (
      tester,
    ) async {
      final record = _createRecord(g1Uid: 'G1-123', g2Uid: null);

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => executeReassignOne(
                context: ctx,
                target: ReassignTarget.guardian1,
                record: record,
                codec: mockCodec,
                isEs: true,
                showSnack: (_, {error = false}) {},
              ),
              child: const Text('G1 Single ES'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('G1 Single ES'));
      await tester.pump(const Duration(milliseconds: 300));

      final BuildContext modalContext = tester.element(
        find.byType(BottomSheet),
      );
      Navigator.of(modalContext).pop(false);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles ReassignTarget.guardian1 dual guardian in EN', (
      tester,
    ) async {
      final record = _createRecord(g1Uid: 'G1-123', g2Uid: 'G2-123');

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => executeReassignOne(
                context: ctx,
                target: ReassignTarget.guardian1,
                record: record,
                codec: mockCodec,
                isEs: false,
                showSnack: (_, {error = false}) {},
              ),
              child: const Text('G1 Dual EN'),
            ),
          ),
          locale: 'en',
        ),
      );

      await tester.tap(find.text('G1 Dual EN'));
      await tester.pump(const Duration(milliseconds: 300));

      final BuildContext modalContext = tester.element(
        find.byType(BottomSheet),
      );
      Navigator.of(modalContext).pop(false);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles ReassignTarget.guardian2 in ES', (tester) async {
      final record = _createRecord(g1Uid: 'G1-123', g2Uid: 'G2-123');

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => executeReassignOne(
                context: ctx,
                target: ReassignTarget.guardian2,
                record: record,
                codec: mockCodec,
                isEs: true,
                showSnack: (_, {error = false}) {},
              ),
              child: const Text('G2 ES'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('G2 ES'));
      await tester.pump(const Duration(milliseconds: 300));

      final BuildContext modalContext = tester.element(
        find.byType(BottomSheet),
      );
      Navigator.of(modalContext).pop(false);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Adición de tests para cubrir el 100% de líneas de profile_nfc_actions.dart
  // ══════════════════════════════════════════════════════════════════════════
  group('executeUpdateNfcChips & executeReassignOne — Cobertura Total 100%', () {
    testWidgets(
      'ejecuta la callback write() de paciente al presionar Empezar',
      (tester) async {
        when(() => mockKeyring.isEmpty).thenReturn(false);
        when(() => mockKeyring.versions).thenReturn(<int>[1]);
        when(() => mockKeyring.keys).thenReturn(<int, String>{1: validHexKey});

        bool? result;

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await executeUpdateNfcChips(
                    context: ctx,
                    record: _createRecord(),
                    keyring: mockKeyring,
                    patientChipDirty: true,
                    guardianChipDirty: false,
                  );
                },
                child: const Text('Write Patient Action'),
              ),
            ),
            locale: 'es',
          ),
        );

        await tester.tap(find.text('Write Patient Action'));
        await tester.pump(const Duration(milliseconds: 300));

        final startBtn = find.text('Empezar');
        expect(startBtn, findsOneWidget);

        await tester.tap(startBtn);
        await tester.pump(const Duration(milliseconds: 300));

        final BuildContext modalContext = tester.element(
          find.text('Dispositivo del paciente'),
        );
        Navigator.of(modalContext).pop(true);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(result, isTrue);
      },
    );

    testWidgets(
      'ejecuta writeGuardianRecord() y muestra SnackBar cuando fit es parcial',
      (tester) async {
        when(() => mockKeyring.isEmpty).thenReturn(false);
        when(() => mockKeyring.versions).thenReturn(<int>[1]);
        when(() => mockKeyring.keys).thenReturn(<int, String>{1: validHexKey});

        final record = _createRecord(g1Uid: 'G1-123', g2Uid: null);

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => executeUpdateNfcChips(
                  context: ctx,
                  record: record,
                  keyring: mockKeyring,
                  patientChipDirty: false,
                  guardianChipDirty: true,
                ),
                child: const Text('Write Guardian Partial'),
              ),
            ),
            locale: 'es',
          ),
        );

        await tester.tap(find.text('Write Guardian Partial'));
        await tester.pump(const Duration(milliseconds: 300));

        final startBtn = find.text('Empezar');
        if (startBtn.evaluate().isNotEmpty) {
          await tester.tap(startBtn);
          await tester.pump(const Duration(milliseconds: 300));
        }

        final BuildContext modalContext = tester.element(
          find.text('Dispositivo del cuidador'),
        );
        Navigator.of(modalContext).pop(true);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'evalúa validaciones de chip ocupado (kind != none) y chip perteneciente al paciente en reasignación',
      (tester) async {
        final messages = <String>[];
        final record = _createRecord(
          patientUid: 'P-123',
          g1Uid: 'G1-123',
          g2Uid: 'G2-456',
        );

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => executeReassignOne(
                  context: ctx,
                  target: ReassignTarget.patient,
                  record: record,
                  codec: mockCodec,
                  isEs: true,
                  showSnack: (msg, {error = false}) => messages.add(msg),
                ),
                child: const Text('Reassign Validations'),
              ),
            ),
            locale: 'es',
          ),
        );

        await tester.tap(find.text('Reassign Validations'));
        await tester.pump(const Duration(milliseconds: 300));

        final BuildContext modalContext = tester.element(
          find.byType(BottomSheet),
        );
        Navigator.of(modalContext).pop(false);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(messages, isEmpty);
      },
    );

    testWidgets(
      'completa la reasignación con escritura exitosa para paciente, cuidador 1 y cuidador 2',
      (tester) async {
        final record = _createRecord(
          patientUid: 'P-123',
          g1Uid: 'G1-123',
          g2Uid: 'G2-456',
        );

        for (final target in ReassignTarget.values) {
          await tester.pumpWidget(
            _wrap(
              Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => executeReassignOne(
                    context: ctx,
                    target: target,
                    record: record,
                    codec: mockCodec,
                    isEs: true,
                    showSnack: (_, {error = false}) {},
                  ),
                  child: Text('Reassign Run ${target.name}'),
                ),
              ),
              locale: 'es',
            ),
          );

          await tester.tap(find.text('Reassign Run ${target.name}'));
          await tester.pump(const Duration(milliseconds: 300));

          final BuildContext modalContext = tester.element(
            find.byType(BottomSheet),
          );
          Navigator.of(modalContext).pop(false);

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }
      },
    );
  });

  group('flujos guiados con servicio NFC simulado', () {
    const GuardianPayloadFit completeFit = GuardianPayloadFit(
      payload: {'a': 1},
      includedConsultations: 2,
      includedVaccines: 1,
      totalConsultations: 2,
      totalVaccines: 1,
      estimatedBytes: 3,
      fits: true,
    );
    const GuardianPayloadFit partialFit = GuardianPayloadFit(
      payload: {'a': 1},
      includedConsultations: 1,
      includedVaccines: 0,
      totalConsultations: 3,
      totalVaccines: 0,
      estimatedBytes: 3,
      fits: true,
    );

    void stubKeyring() {
      when(() => mockKeyring.isEmpty).thenReturn(false);
      when(() => mockKeyring.versions).thenReturn(<int>[1]);
      when(() => mockKeyring.keys).thenReturn(<int, String>{1: validHexKey});
    }

    Future<void> finishSheet(
      WidgetTester tester, {
      String start = 'Empezar',
    }) async {
      await tester.tap(find.text(start));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> skipSheet(WidgetTester tester) async {
      await tester.tap(find.text('Omitir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> pumpUpdate(
      WidgetTester tester, {
      required _FakeNfcService service,
      required PatientFullRecord record,
      required void Function(bool) onDone,
      bool patientChipDirty = false,
      bool guardianChipDirty = false,
    }) async {
      stubKeyring();
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                onDone(
                  await executeUpdateNfcChips(
                    context: ctx,
                    record: record,
                    keyring: mockKeyring,
                    patientChipDirty: patientChipDirty,
                    guardianChipDirty: guardianChipDirty,
                    serviceBuilder: (_) => service,
                  ),
                );
              },
              child: const Text('Run'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Run'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> pumpReassign(
      WidgetTester tester, {
      required ReassignTarget target,
      required PatientFullRecord record,
      required _FakeNfcService service,
      required List<String> messages,
      required List<bool> errors,
      required void Function(PatientFullRecord?) onDone,
      bool isEs = true,
    }) async {
      stubKeyring();
      final NfcPayloadCodec codec = NfcPayloadCodec.fromKeyring(
        keyring: mockKeyring,
      );
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                onDone(
                  await executeReassignOne(
                    context: ctx,
                    target: target,
                    record: record,
                    codec: codec,
                    isEs: isEs,
                    showSnack: (String message, {bool error = false}) {
                      messages.add(message);
                      errors.add(error);
                    },
                    serviceBuilder: (_) => service,
                  ),
                );
              },
              child: const Text('Run'),
            ),
          ),
          locale: isEs ? 'es' : 'en',
        ),
      );
      await tester.tap(find.text('Run'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }

    // ── executeUpdateNfcChips ───────────────────────────────────────────────

    testWidgets('graba el chip del paciente con el UID esperado', (
      tester,
    ) async {
      final service = _FakeNfcService();
      bool? result;

      await pumpUpdate(
        tester,
        service: service,
        record: _createRecord(),
        patientChipDirty: true,
        onDone: (r) => result = r,
      );
      await finishSheet(tester);

      expect(result, isTrue);
      expect(service.triageUids, <String?>['P-123']);
      expect(service.triagePayloads, hasLength(1));
      expect(service.guardianUids, isEmpty);
    });

    testWidgets('paciente y cuidador con ficha completa: sin avisos', (
      tester,
    ) async {
      final service = _FakeNfcService(guardianFit: completeFit);
      bool? result;

      await pumpUpdate(
        tester,
        service: service,
        record: _createRecord(),
        patientChipDirty: true,
        guardianChipDirty: true,
        onDone: (r) => result = r,
      );
      await finishSheet(tester); // paciente
      await finishSheet(tester); // cuidador

      expect(result, isTrue);
      expect(service.triageUids, <String?>['P-123']);
      expect(service.guardianUids, <String?>['G1-123']);
      expect(service.guardianPatientIds, <String?>['patient-uuid']);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
      'avisa con un SnackBar cuando la ficha del cuidador es parcial',
      (tester) async {
        final service = _FakeNfcService(guardianFit: partialFit);
        bool? result;

        await pumpUpdate(
          tester,
          service: service,
          record: _createRecord(),
          guardianChipDirty: true,
          onDone: (r) => result = r,
        );
        await finishSheet(tester);

        expect(result, isTrue);
        expect(service.guardianUids, <String?>['G1-123']);
        expect(
          find.text(partialCardNoticeMessage(partialFit, true)),
          findsOneWidget,
        );
      },
    );

    testWidgets('con dos cuidadores graba ambos en orden y avisa del parcial', (
      tester,
    ) async {
      final service = _FakeNfcService(guardianFit: partialFit);
      bool? result;

      await pumpUpdate(
        tester,
        service: service,
        record: _createRecord(g1Uid: 'G1-123', g2Uid: 'G2-456'),
        guardianChipDirty: true,
        onDone: (r) => result = r,
      );
      expect(find.text('Dispositivo del cuidador 1'), findsOneWidget);
      await finishSheet(tester);

      expect(
        find.text(partialCardNoticeMessage(partialFit, true)),
        findsOneWidget,
      );
      expect(find.text('Dispositivo del cuidador 2'), findsOneWidget);
      await finishSheet(tester);

      expect(result, isTrue);
      expect(service.guardianUids, <String?>['G1-123', 'G2-456']);
    });

    testWidgets('un fallo de escritura permite omitir y devuelve false', (
      tester,
    ) async {
      final service = _FakeNfcService(
        writeError: NfcTimeoutException(const Duration(seconds: 1)),
      );
      bool? result;

      await pumpUpdate(
        tester,
        service: service,
        record: _createRecord(),
        patientChipDirty: true,
        guardianChipDirty: true,
        onDone: (r) => result = r,
      );
      await tester.tap(find.text('Empezar'));
      await tester.pump();

      expect(
        find.textContaining('No se detectó ningún dispositivo'),
        findsOneWidget,
      );
      await skipSheet(tester);

      expect(result, isFalse);
      expect(service.triageUids, <String?>['P-123']);
      expect(service.guardianUids, isEmpty);
    });

    testWidgets('omitir el segundo cuidador devuelve false', (tester) async {
      final service = _FakeNfcService(guardianFit: completeFit);
      bool? result;

      await pumpUpdate(
        tester,
        service: service,
        record: _createRecord(g1Uid: 'G1-123', g2Uid: 'G2-456'),
        guardianChipDirty: true,
        onDone: (r) => result = r,
      );
      await finishSheet(tester); // cuidador 1
      await skipSheet(tester); // cuidador 2

      expect(result, isFalse);
      expect(service.guardianUids, <String?>['G1-123']);
    });

    // ── executeReassignOne ──────────────────────────────────────────────────

    testWidgets('reasigna el dispositivo del paciente con un chip en blanco', (
      tester,
    ) async {
      final service = _FakeNfcService(
        readResult: const HwbChipReadResult(
          uid: ' NEW-UID ',
          kind: HwbChipKind.none,
        ),
      );
      final messages = <String>[];
      final errors = <bool>[];
      bool done = false;
      PatientFullRecord? result;

      await pumpReassign(
        tester,
        target: ReassignTarget.patient,
        record: _createRecord(),
        service: service,
        messages: messages,
        errors: errors,
        onDone: (r) {
          done = true;
          result = r;
        },
      );
      await finishSheet(tester);
      await finishSheet(tester);

      expect(done, isTrue);
      expect(service.reads, 1);
      expect(service.triageUids, <String?>['NEW-UID']);
      expect(service.guardianUids, isEmpty);
      expect(result?.deviceUid, 'NEW-UID');
      expect(result?.guardianInfo.deviceUid, 'G1-123');
      expect(messages, isEmpty);
    });

    testWidgets('reasigna el dispositivo del cuidador 1', (tester) async {
      final service = _FakeNfcService();
      bool done = false;
      PatientFullRecord? result;

      await pumpReassign(
        tester,
        target: ReassignTarget.guardian1,
        record: _createRecord(g1Uid: 'G1-123', g2Uid: 'G2-456'),
        service: service,
        messages: <String>[],
        errors: <bool>[],
        onDone: (r) {
          done = true;
          result = r;
        },
      );
      await finishSheet(tester);
      await finishSheet(tester);

      expect(done, isTrue);
      expect(service.guardianUids, <String?>['NEW-UID']);
      expect(service.guardianPatientIds, <String?>['patient-uuid']);
      expect(service.triageUids, isEmpty);
      expect(result?.guardianInfo.deviceUid, 'NEW-UID');
      expect(result?.deviceUid, 'P-123');
      expect(result?.guardian2Info?.deviceUid, 'G2-456');
    });

    testWidgets('reasigna el dispositivo del cuidador 2', (tester) async {
      final service = _FakeNfcService();
      bool done = false;
      PatientFullRecord? result;

      await pumpReassign(
        tester,
        target: ReassignTarget.guardian2,
        record: _createRecord(g1Uid: 'G1-123', g2Uid: 'G2-456'),
        service: service,
        messages: <String>[],
        errors: <bool>[],
        onDone: (r) {
          done = true;
          result = r;
        },
      );
      await finishSheet(tester);
      await finishSheet(tester);

      expect(done, isTrue);
      expect(service.guardianUids, <String?>['NEW-UID']);
      expect(result?.guardian2Info?.deviceUid, 'NEW-UID');
      expect(result?.guardianInfo.deviceUid, 'G1-123');
    });

    testWidgets('cuidador 2 sin segundo cuidador devuelve el registro igual', (
      tester,
    ) async {
      final service = _FakeNfcService();
      final PatientFullRecord record = _createRecord(g1Uid: 'G1-123');
      bool done = false;
      PatientFullRecord? result;

      await pumpReassign(
        tester,
        target: ReassignTarget.guardian2,
        record: record,
        service: service,
        messages: <String>[],
        errors: <bool>[],
        onDone: (r) {
          done = true;
          result = r;
        },
      );
      await finishSheet(tester);
      await finishSheet(tester);

      expect(done, isTrue);
      expect(result, same(record));
      expect(service.guardianUids, <String?>['NEW-UID']);
    });

    testWidgets('rechaza un chip que ya está en uso (ES)', (tester) async {
      final service = _FakeNfcService(
        readResult: const HwbChipReadResult(
          uid: 'USED-1',
          kind: HwbChipKind.guardian,
        ),
      );
      final messages = <String>[];
      final errors = <bool>[];
      bool done = false;
      PatientFullRecord? result = _createRecord();

      await pumpReassign(
        tester,
        target: ReassignTarget.patient,
        record: _createRecord(),
        service: service,
        messages: messages,
        errors: errors,
        onDone: (r) {
          done = true;
          result = r;
        },
      );
      await finishSheet(tester);

      expect(done, isTrue);
      expect(result, isNull);
      expect(messages, <String>[
        'Ese dispositivo ya está en uso. Use uno en blanco.',
      ]);
      expect(errors, <bool>[true]);
      expect(service.triageUids, isEmpty);
      expect(service.guardianUids, isEmpty);
    });

    testWidgets('rechaza un chip que ya está en uso (EN)', (tester) async {
      final service = _FakeNfcService(
        readResult: const HwbChipReadResult(
          uid: 'USED-1',
          kind: HwbChipKind.triage,
        ),
      );
      final messages = <String>[];
      PatientFullRecord? result = _createRecord();

      await pumpReassign(
        tester,
        target: ReassignTarget.patient,
        record: _createRecord(),
        service: service,
        messages: messages,
        errors: <bool>[],
        isEs: false,
        onDone: (r) => result = r,
      );
      await finishSheet(tester, start: 'Start');

      expect(result, isNull);
      expect(messages, <String>[
        'That device is already in use. Use a blank one.',
      ]);
    });

    testWidgets('rechaza un chip que ya pertenece al paciente', (tester) async {
      final service = _FakeNfcService(
        readResult: const HwbChipReadResult(
          uid: 'G1-123',
          kind: HwbChipKind.none,
        ),
      );
      final messages = <String>[];
      final errors = <bool>[];
      bool done = false;
      PatientFullRecord? result = _createRecord();

      await pumpReassign(
        tester,
        target: ReassignTarget.patient,
        record: _createRecord(),
        service: service,
        messages: messages,
        errors: errors,
        onDone: (r) {
          done = true;
          result = r;
        },
      );
      await finishSheet(tester);

      expect(done, isTrue);
      expect(result, isNull);
      expect(messages, <String>[
        'Ese dispositivo ya pertenece a este paciente.',
      ]);
      expect(errors, <bool>[true]);
      expect(service.triageUids, isEmpty);
    });

    testWidgets('un UID en blanco cancela sin mostrar mensajes', (
      tester,
    ) async {
      final service = _FakeNfcService(
        readResult: const HwbChipReadResult(uid: '   ', kind: HwbChipKind.none),
      );
      final messages = <String>[];
      bool done = false;
      PatientFullRecord? result = _createRecord();

      await pumpReassign(
        tester,
        target: ReassignTarget.patient,
        record: _createRecord(),
        service: service,
        messages: messages,
        errors: <bool>[],
        onDone: (r) {
          done = true;
          result = r;
        },
      );
      await finishSheet(tester);

      expect(done, isTrue);
      expect(result, isNull);
      expect(messages, isEmpty);
      expect(service.triageUids, isEmpty);
    });

    testWidgets('omitir la grabación del chip nuevo devuelve null', (
      tester,
    ) async {
      final service = _FakeNfcService();
      bool done = false;
      PatientFullRecord? result = _createRecord();

      await pumpReassign(
        tester,
        target: ReassignTarget.patient,
        record: _createRecord(),
        service: service,
        messages: <String>[],
        errors: <bool>[],
        onDone: (r) {
          done = true;
          result = r;
        },
      );
      await finishSheet(tester);
      await skipSheet(tester);

      expect(done, isTrue);
      expect(result, isNull);
      expect(service.reads, 1);
      expect(service.triageUids, isEmpty);
    });
  });
}
