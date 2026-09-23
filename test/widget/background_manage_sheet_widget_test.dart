// test/widget/background_manage_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/background_manage_sheet.dart';

class _LocaleWrapper extends StatelessWidget {
  const _LocaleWrapper({required this.locale, required this.child});

  final String locale;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AppLocale(locale: locale, setLocale: (_) {}, child: child);
}

Widget _buildDirect({
  required PatientFullRecord draft,
  VoidCallback? onAddChronic,
  void Function(int)? onRemoveChronic,
  VoidCallback? onEditPersonal,
  VoidCallback? onAddFamily,
  void Function(int)? onRemoveFamily,
  VoidCallback? onAddMedication,
  void Function(int)? onRemoveMedication,
  String locale = 'es',
}) => _LocaleWrapper(
  locale: locale,
  child: MaterialApp(
    home: Scaffold(
      body: BackgroundManageSheet(
        draft: draft,
        onAddChronic: onAddChronic ?? () {},
        onRemoveChronic: onRemoveChronic ?? (_) {},
        onEditPersonal: onEditPersonal ?? () {},
        onAddFamily: onAddFamily ?? () {},
        onRemoveFamily: onRemoveFamily ?? (_) {},
        onAddMedication: onAddMedication ?? () {},
        onRemoveMedication: onRemoveMedication ?? (_) {},
      ),
    ),
  ),
);

Widget _buildViaBottomSheet({
  required PatientFullRecord draft,
  VoidCallback? onAddChronic,
  void Function(int)? onRemoveChronic,
  VoidCallback? onEditPersonal,
  VoidCallback? onAddFamily,
  void Function(int)? onRemoveFamily,
  VoidCallback? onAddMedication,
  void Function(int)? onRemoveMedication,
  String locale = 'es',
}) => _LocaleWrapper(
  locale: locale,
  child: MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: ctx,
              isScrollControlled: true,
              builder: (_) => BackgroundManageSheet(
                draft: draft,
                onAddChronic: onAddChronic ?? () {},
                onRemoveChronic: onRemoveChronic ?? (_) {},
                onEditPersonal: onEditPersonal ?? () {},
                onAddFamily: onAddFamily ?? () {},
                onRemoveFamily: onRemoveFamily ?? (_) {},
                onAddMedication: onAddMedication ?? () {},
                onRemoveMedication: onRemoveMedication ?? (_) {},
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

PatientFullRecord _createRecord({BackgroundHistory? backgroundHistory}) {
  return PatientFullRecord(
    patientId: 'uuid-123',
    deviceUid: 'NFC-123',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '12345',
      ),
      firstName: 'Juan',
      firstLastName: 'Pérez',
      dob: '2000-01-01',
      biologicalSex: 'M',
      address: Address(city: 'Bogota', state: 'Cundinamarca'),
    ),
    guardianInfo: GuardianInfo(name: 'N/A', relationship: 'N/A', phone: 'N/A'),
    backgroundHistory: backgroundHistory,
  );
}

void main() {
  final sEs = AppStrings.forTesting('es');

  setUp(() {
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

  group('BackgroundManageSheet – Empty / Null backgroundHistory Rendering', () {
    testWidgets(
      'renders empty placeholder labels when backgroundHistory is null',
      (tester) async {
        final draft = _createRecord(backgroundHistory: null);

        await tester.pumpWidget(_buildDirect(draft: draft));

        expect(find.text(sEs.backgroundSheetTitle), findsOneWidget);
        expect(find.text(sEs.noChronicConditions), findsOneWidget);
        expect(find.text(sEs.noMedications), findsOneWidget);
        expect(find.text(sEs.noFamilyHistoryEntries), findsOneWidget);
        expect(
          find.text('—'),
          findsOneWidget,
        ); // Empty personal history fallback
      },
    );

    testWidgets(
      'renders empty placeholder labels when backgroundHistory lists are empty',
      (tester) async {
        final draft = _createRecord(
          backgroundHistory: BackgroundHistory(
            chronicConditions: [],
            medications: [],
            familyHistory: [],
            personalHistory: '',
          ),
        );

        await tester.pumpWidget(_buildDirect(draft: draft));

        expect(find.text(sEs.noChronicConditions), findsOneWidget);
        expect(find.text(sEs.noMedications), findsOneWidget);
        expect(find.text(sEs.noFamilyHistoryEntries), findsOneWidget);
        expect(find.text('—'), findsOneWidget);
      },
    );
  });

  group('BackgroundManageSheet – Populated Content & Formatter Variations', () {
    testWidgets(
      'renders populated chronic conditions, medications and family entries with details',
      (tester) async {
        final bg = BackgroundHistory(
          chronicConditions: [
            ChronicConditionItem(
              chronicDescription: 'Asma',
              chronicCie10Code: 'J45',
            ),
            ChronicConditionItem(
              chronicDescription: 'Diabetes',
              chronicCie10Code: null,
            ),
          ],
          personalHistory: 'Cirugía de rodilla en 2018',
          medications: [
            MedicationStatementItem(
              medicationName: 'Salbutamol',
              status: 'active',
              dosage: '2 puff c/8h',
            ),
            MedicationStatementItem(
              medicationName: 'Metformina',
              status: 'completed',
              dosage: null,
            ),
            MedicationStatementItem(
              medicationName: 'Ibuprofeno',
              status: 'unknown_status',
            ),
          ],
          familyHistory: [
            FamilyHistoryItem(
              conditionDescription: 'Hipertensión',
              relationship: '01',
            ),
            FamilyHistoryItem(
              conditionDescription: 'Cáncer',
              relationship: '99',
            ),
          ],
        );

        final draft = _createRecord(backgroundHistory: bg);

        await tester.pumpWidget(_buildDirect(draft: draft));

        expect(find.text('Asma'), findsOneWidget);
        expect(find.text('${sEs.cie10Label}J45'), findsOneWidget);
        expect(find.text('Diabetes'), findsOneWidget);

        expect(find.text('Cirugía de rodilla en 2018'), findsOneWidget);

        expect(find.text('Salbutamol'), findsOneWidget);
        expect(find.text('Activo · 2 puff c/8h'), findsOneWidget);
        expect(find.text('Metformina'), findsOneWidget);
        expect(find.text('Completado'), findsOneWidget);
        expect(find.text('Ibuprofeno'), findsOneWidget);
        expect(find.text('unknown_status'), findsOneWidget);

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump();

        expect(find.text('Hipertensión'), findsOneWidget);
        expect(find.text('Padres'), findsOneWidget);
        expect(find.text('Cáncer'), findsOneWidget);
        expect(find.text('99'), findsOneWidget);
      },
    );
  });

  group('BackgroundManageSheet – Action Callbacks & Navigation', () {
    testWidgets(
      'triggers onAddChronic callback when clicking Add Chronic button',
      (tester) async {
        var addCalled = false;
        final draft = _createRecord();

        await tester.pumpWidget(
          _buildDirect(draft: draft, onAddChronic: () => addCalled = true),
        );

        final addButtons = find.widgetWithText(TextButton, sEs.add);
        await tester.tap(addButtons.at(0));
        await tester.pump();

        expect(addCalled, isTrue);
      },
    );

    testWidgets('triggers onRemoveChronic callback with correct index', (
      tester,
    ) async {
      int? removedIndex;
      final bg = BackgroundHistory(
        chronicConditions: [
          ChronicConditionItem(chronicDescription: 'Asma'),
          ChronicConditionItem(chronicDescription: 'Diabetes'),
        ],
      );
      final draft = _createRecord(backgroundHistory: bg);

      await tester.pumpWidget(
        _buildDirect(
          draft: draft,
          onRemoveChronic: (idx) => removedIndex = idx,
        ),
      );

      final deleteIcons = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteIcons.at(1));
      await tester.pump();

      expect(removedIndex, equals(1));
    });

    testWidgets(
      'triggers onEditPersonal callback when clicking personal history card',
      (tester) async {
        var editCalled = false;
        final draft = _createRecord();

        await tester.pumpWidget(
          _buildDirect(draft: draft, onEditPersonal: () => editCalled = true),
        );

        await tester.tap(find.text(sEs.personalHistoryTitle));
        await tester.pump();

        expect(editCalled, isTrue);
      },
    );

    testWidgets(
      'triggers onAddMedication callback when clicking Add Medication button',
      (tester) async {
        var addCalled = false;
        final draft = _createRecord();

        await tester.pumpWidget(
          _buildDirect(draft: draft, onAddMedication: () => addCalled = true),
        );

        final addButtons = find.widgetWithText(TextButton, sEs.add);
        await tester.tap(addButtons.at(1));
        await tester.pump();

        expect(addCalled, isTrue);
      },
    );

    testWidgets('triggers onRemoveMedication callback with correct index', (
      tester,
    ) async {
      int? removedIndex;
      final bg = BackgroundHistory(
        medications: [
          MedicationStatementItem(medicationName: 'Med 1', status: 'active'),
          MedicationStatementItem(medicationName: 'Med 2', status: 'active'),
        ],
      );
      final draft = _createRecord(backgroundHistory: bg);

      await tester.pumpWidget(
        _buildDirect(
          draft: draft,
          onRemoveMedication: (idx) => removedIndex = idx,
        ),
      );

      final deleteIcons = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteIcons.at(0));
      await tester.pump();

      expect(removedIndex, equals(0));
    });

    testWidgets(
      'triggers onAddFamily callback when clicking Add Family button',
      (tester) async {
        var addCalled = false;
        final draft = _createRecord();

        await tester.pumpWidget(
          _buildDirect(draft: draft, onAddFamily: () => addCalled = true),
        );

        final addButtons = find.widgetWithText(TextButton, sEs.add);
        await tester.tap(addButtons.at(2));
        await tester.pump();

        expect(addCalled, isTrue);
      },
    );

    testWidgets('triggers onRemoveFamily callback with correct index', (
      tester,
    ) async {
      int? removedIndex;
      final bg = BackgroundHistory(
        familyHistory: [
          FamilyHistoryItem(conditionDescription: 'Cond 1', relationship: '01'),
        ],
      );
      final draft = _createRecord(backgroundHistory: bg);

      await tester.pumpWidget(
        _buildDirect(draft: draft, onRemoveFamily: (idx) => removedIndex = idx),
      );

      final deleteIcons = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteIcons.first);
      await tester.pump();

      expect(removedIndex, equals(0));
    });

    testWidgets('dismisses sheet when clicking top right close button', (
      tester,
    ) async {
      final draft = _createRecord();

      await tester.pumpWidget(_buildViaBottomSheet(draft: draft));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(BackgroundManageSheet), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(BackgroundManageSheet), findsNothing);
    });
  });
}
