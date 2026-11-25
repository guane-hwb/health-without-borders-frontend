// test/widget/muac_widget_test.dart
//
// The arm circumference in the «Medidas» sheet, the profile summary and the
// registration (steps 3 and 5): shown for 6 to 59 months, with the colour
// and the word of its risk level.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/register_draft.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_vital_signs_sheet.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_summary.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step3_patient_data.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step5_review.dart';

final _es = AppStrings.forTesting('es');

Widget _wrap(Widget child) => AppLocale(
  locale: 'es',
  setLocale: (_) {},
  child: MaterialApp(home: Scaffold(body: child)),
);

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

/// A birth date [months] months before today, on the 1st so the months are
/// completed whatever today's day is.
DateTime _monthsAgo(int months) {
  final now = DateTime.now();
  return DateTime(now.year, now.month - months, 1);
}

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

final Finder _muacField = find.byKey(const ValueKey('muac_field'));

Finder _badge(String risk) => find.byKey(ValueKey('muac_risk_$risk'));

void main() {
  group('Hoja «Medidas»', () {
    Widget sheet({
      bool applies = true,
      double? muac,
      double? previousMuac,
      void Function(double? muac)? onMuac,
    }) => _wrap(
      EditVitalSignsSheet(
        muac: muac,
        previousMuac: previousMuac,
        muacApplies: applies,
        onConfirm:
            ({
              double? weight,
              double? height,
              double? muac,
              String? bloodType,
              bool isBloodTypeCertified = false,
            }) => onMuac?.call(muac),
      ),
    );

    Future<void> confirm(WidgetTester tester) async {
      final button = find.text(_es.confirmChanges);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('no field for a patient outside 6-59 months without a value', (
      tester,
    ) async {
      await tester.pumpWidget(sheet(applies: false));
      expect(_muacField, findsNothing);
      expect(find.text(_es.muacCm), findsNothing);
    });

    testWidgets('the level follows what is typed: colour and word', (
      tester,
    ) async {
      await tester.pumpWidget(sheet());
      expect(_muacField, findsOneWidget);
      expect(find.byKey(const ValueKey('muac_risk_advice')), findsNothing);

      await tester.enterText(_muacField, '11.0');
      await tester.pump();
      expect(_badge('red'), findsOneWidget);
      expect(find.text(_es.muacRiskRed), findsOneWidget);
      expect(find.text(_es.muacActionRed), findsOneWidget);
      expect(
        tester.widget<Container>(_badge('red')).decoration,
        isA<BoxDecoration>().having((d) => d.color, 'color', AppColors.riskRed),
      );

      await tester.enterText(_muacField, '12,5');
      await tester.pump();
      expect(_badge('yellow'), findsOneWidget);
      expect(find.text(_es.muacRiskYellow), findsOneWidget);

      await tester.enterText(_muacField, '14');
      await tester.pump();
      expect(_badge('green'), findsOneWidget);
      expect(find.text(_es.muacRiskGreen), findsOneWidget);
    });

    testWidgets('confirm sends the measure rounded to millimetres', (
      tester,
    ) async {
      double? sent;
      await tester.pumpWidget(sheet(onMuac: (m) => sent = m));
      await tester.enterText(_muacField, '12.34');
      await confirm(tester);
      expect(sent, 12.3);
    });

    testWidgets('a value out of range shows the error and is not sent', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(sheet(onMuac: (_) => called = true));
      await tester.enterText(_muacField, '45');
      await tester.pump();
      expect(find.byKey(const ValueKey('muac_risk_advice')), findsNothing);

      await confirm(tester);
      expect(called, isFalse);
      expect(find.text(_es.muacRangeError), findsOneWidget);
    });

    testWidgets('an older patient with a stored value can correct it, but '
        'without a level', (tester) async {
      await tester.pumpWidget(sheet(applies: false, muac: 12.0));
      expect(_muacField, findsOneWidget);
      expect(find.text(_es.muacNoClassification), findsOneWidget);
      expect(_badge('yellow'), findsNothing);
    });

    testWidgets('shows the previous value and counts as unsaved input', (
      tester,
    ) async {
      await tester.pumpWidget(sheet(muac: 12.0, previousMuac: 11.4));
      expect(find.text('${_es.previous}: 11.4 cm'), findsOneWidget);

      final popScope = find.byWidgetPredicate((w) => w is PopScope);
      expect(tester.widget<PopScope>(popScope).canPop, isTrue);
      await tester.enterText(_muacField, '13.0');
      await tester.pump();
      expect(tester.widget<PopScope>(popScope).canPop, isFalse);
    });
  });

  group('Resumen del perfil', () {
    PatientFullRecord record({required String dob, double? muac}) =>
        PatientFullRecord(
          patientId: 'p-1',
          deviceUid: 'UID-1',
          patientInfo: PatientInfo(
            identification: PatientIdentification(
              documentType: 'RC',
              documentNumber: '1100000001',
            ),
            firstLastName: 'Pérez',
            firstName: 'Lucía',
            dob: dob,
            biologicalSex: 'F',
            address: Address(city: 'Riohacha', state: 'La Guajira'),
            muac: muac,
          ),
          guardianInfo: GuardianInfo(
            name: 'Ana',
            relationship: '01',
            phone: '300',
          ),
        );

    Widget summary(PatientFullRecord draft, {PatientFullRecord? original}) =>
        _wrap(
          ProfileTabSummary(
            draft: draft,
            original: original ?? draft,
            canEdit: true,
            onEditVitalSigns: () {},
            onEditAddress: () {},
            onEditGuardian: (_) {},
            onOpenAllergies: () {},
            onOpenBackground: () {},
          ),
        );

    final row = find.byKey(const ValueKey('muac_summary_row'));

    testWidgets('a child with a value shows it with its level', (tester) async {
      _tallView(tester);
      await tester.pumpWidget(
        summary(record(dob: _iso(_monthsAgo(24)), muac: 12.3)),
      );
      expect(row, findsOneWidget);
      expect(find.text('12.3 cm'), findsOneWidget);
      expect(_badge('yellow'), findsOneWidget);
    });

    testWidgets('a child without a value shows the empty row', (tester) async {
      _tallView(tester);
      await tester.pumpWidget(summary(record(dob: _iso(_monthsAgo(24)))));
      expect(row, findsOneWidget);
      expect(find.descendant(of: row, matching: find.text('—')), findsOne);
    });

    testWidgets('an adult without a value has no row', (tester) async {
      _tallView(tester);
      await tester.pumpWidget(summary(record(dob: '1990-06-15')));
      expect(row, findsNothing);
    });

    testWidgets('a value outside 6-59 months shows without a level', (
      tester,
    ) async {
      _tallView(tester);
      await tester.pumpWidget(
        summary(record(dob: _iso(_monthsAgo(72)), muac: 15.0)),
      );
      expect(find.text('15.0 cm'), findsOneWidget);
      expect(find.text(_es.muacNoClassification), findsOneWidget);
      expect(_badge('green'), findsNothing);
    });

    test('muacChanged compares the draft with the original', () {
      final dob = _iso(_monthsAgo(24));
      final widget = ProfileTabSummary(
        draft: record(dob: dob, muac: 13.0),
        original: record(dob: dob, muac: 12.0),
        canEdit: true,
        onEditVitalSigns: () {},
        onEditAddress: () {},
        onEditGuardian: (_) {},
        onOpenAllergies: () {},
        onOpenBackground: () {},
      );
      expect(widget.muacChanged, isTrue);
    });
  });

  group('Registro', () {
    final registerField = find.byKey(const ValueKey('register_muac_field'));

    RegisterDraft filledDraft(DateTime dob) => RegisterDraft()
      ..deviceUid = 'P-UID-999'
      ..documentType = 'RC'
      ..documentNumber = '1098765432'
      ..firstName = 'Lucía'
      ..firstLastName = 'Pérez'
      ..dob = dob
      ..addressCity = 'Riohacha'
      ..addressState = 'La Guajira';

    Future<void> pumpStep3(
      WidgetTester tester,
      RegisterDraft draft,
      VoidCallback onContinue,
    ) async {
      tester.view.physicalSize = const Size(800, 3500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: AppLocale(
            locale: 'es',
            setLocale: (_) {},
            child: Scaffold(
              body: Step3PatientData(
                draft: draft,
                onBack: () {},
                onContinue: onContinue,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapContinue(WidgetTester tester) async {
      final button = find.ancestor(
        of: find.byIcon(Icons.arrow_forward),
        matching: find.byType(ElevatedButton),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    Finder registerInput() =>
        find.descendant(of: registerField, matching: find.byType(TextField));

    testWidgets('step 3: a child of 6-59 months gets the field and its level, '
        'and the value reaches the draft', (tester) async {
      final draft = filledDraft(_monthsAgo(18));
      var continued = false;
      await pumpStep3(tester, draft, () => continued = true);

      expect(registerField, findsOneWidget);
      await tester.enterText(registerInput(), '11.2');
      await tester.pump();
      expect(_badge('red'), findsOneWidget);
      expect(find.text(_es.muacActionRed), findsOneWidget);

      await tapContinue(tester);
      expect(continued, isTrue);
      expect(draft.muac, 11.2);
    });

    testWidgets('step 3: a value out of range stops «Continuar»', (
      tester,
    ) async {
      final draft = filledDraft(_monthsAgo(18));
      var continued = false;
      await pumpStep3(tester, draft, () => continued = true);

      await tester.enterText(registerInput(), '3');
      await tapContinue(tester);
      expect(continued, isFalse);
      expect(find.text(_es.muacRangeError), findsWidgets);
      expect(draft.muac, isNull);
    });

    testWidgets('step 3: no field for an adult, and nothing is kept', (
      tester,
    ) async {
      final draft = filledDraft(DateTime(1995, 5, 20))..muac = 12.0;
      var continued = false;
      await pumpStep3(tester, draft, () => continued = true);

      expect(registerField, findsNothing);
      await tapContinue(tester);
      expect(continued, isTrue);
      expect(draft.muac, isNull);
    });

    testWidgets('step 5 shows the value with the word of its level', (
      tester,
    ) async {
      final draft = filledDraft(_monthsAgo(18))..muac = 13.8;
      await tester.pumpWidget(
        _wrap(Step5Review(draft: draft, onBack: () {}, onConfirm: () async {})),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('13.8 cm · ${_es.muacRiskGreen}'), findsOne);
    });
  });
}
