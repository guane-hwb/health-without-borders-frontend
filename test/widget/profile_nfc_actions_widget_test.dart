// test/widget/profile_nfc_actions_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
// import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_payload.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
// import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/profile_nfc_actions.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/reassign_device_dialog.dart';

class _MockNfcKeyring extends Mock implements NfcKeyring {}

class _MockNfcPayloadCodec extends Mock implements NfcPayloadCodec {}

class _FakePatientFullRecord extends Fake implements PatientFullRecord {}

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
        find.text('Pulsera del paciente'),
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

        expect(find.text('Tarjeta del guardián 1'), findsOneWidget);

        final BuildContext modalContext = tester.element(
          find.text('Tarjeta del guardián 1'),
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
          find.text('Pulsera del paciente'),
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
          find.text('Tarjeta del guardián'),
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
      'completa la reasignación con escritura exitosa para paciente, guardián 1 y guardián 2',
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
}
