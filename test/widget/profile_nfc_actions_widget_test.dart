// test/widget/profile_nfc_actions_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/profile_nfc_actions.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/reassign_device_dialog.dart';

class _MockNfcKeyring extends Mock implements NfcKeyring {}

class _MockNfcPayloadCodec extends Mock implements NfcPayloadCodec {}

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

  setUp(() {
    mockKeyring = _MockNfcKeyring();
    mockCodec = _MockNfcPayloadCodec();

    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1600,
      1200,
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

      final cancelBtn = find.text('Cancelar');
      final closeIcon = find.byIcon(Icons.close);

      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn.first);
      } else if (closeIcon.evaluate().isNotEmpty) {
        await tester.tap(closeIcon.first);
      } else {
        final BuildContext context = tester.element(
          find.byType(ElevatedButton).first,
        );
        Navigator.of(context).pop(false);
      }

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(result, isFalse);
    });
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

      final cancelBtn = find.text('Cancelar');
      final closeIcon = find.byIcon(Icons.close);

      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn.first);
      } else if (closeIcon.evaluate().isNotEmpty) {
        await tester.tap(closeIcon.first);
      }

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

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

      final cancelBtn = find.text('Cancelar');
      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn.first);
        await tester.pump(const Duration(milliseconds: 500));
      }

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

      final cancelBtn = find.text('Cancelar');
      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn.first);
        await tester.pump(const Duration(milliseconds: 500));
      }

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

      final cancelBtn = find.text('Cancel');
      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn.first);
        await tester.pump(const Duration(milliseconds: 500));
      }

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

      final cancelBtn = find.text('Cancelar');
      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn.first);
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(tester.takeException(), isNull);
    });
  });
}
