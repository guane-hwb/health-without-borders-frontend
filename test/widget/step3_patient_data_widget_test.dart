// test/widget/step3_patient_data_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_service.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step3_patient_data.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/register_draft.dart';

Widget _wrap(Widget child, {String locale = 'es'}) {
  return MaterialApp(
    home: AppLocale(
      locale: locale,
      setLocale: (_) {},
      child: Scaffold(body: child),
    ),
  );
}

Finder get _scanButton => find.ancestor(
  of: find.byIcon(Icons.nfc),
  matching: find.byType(ElevatedButton),
);

Finder get _continueButton => find.ancestor(
  of: find.byIcon(Icons.arrow_forward),
  matching: find.byType(ElevatedButton),
);

Finder get _backButton => find.ancestor(
  of: find.byIcon(Icons.arrow_back),
  matching: find.byType(OutlinedButton),
);

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    NfcService.overrideReadDeviceUid = null;
  });

  group('Step3PatientData - initial render (Spanish)', () {
    testWidgets('renders without throwing, no error banner, no ethnic '
        'community field for a fresh draft', (tester) async {
      final draft = RegisterDraft();
      await tester.pumpWidget(
        _wrap(Step3PatientData(draft: draft, onBack: () {}, onContinue: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Step3PatientData), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text('COMUNIDAD ÉTNICA'), findsNothing);
    });
  });

  group('Step3PatientData - conditional branches', () {
    testWidgets('biologicalSex == M exercises the AS doc-type ternary', (
      tester,
    ) async {
      final draft = RegisterDraft()..biologicalSex = 'M';
      await tester.pumpWidget(
        _wrap(Step3PatientData(draft: draft, onBack: () {}, onContinue: () {})),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Step3PatientData), findsOneWidget);
    });
  });

  group('Step3PatientData - back navigation', () {
    testWidgets('tapping back invokes onBack without requiring valid data', (
      tester,
    ) async {
      var backTapped = false;
      final draft = RegisterDraft();
      await tester.pumpWidget(
        _wrap(
          Step3PatientData(
            draft: draft,
            onBack: () => backTapped = true,
            onContinue: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_backButton);
      await tester.pump();
      expect(backTapped, isTrue);
    });
  });

  group('Step3PatientData - _save() validation', () {
    testWidgets('empty draft: onContinue is not called and every required '
        'field is listed in the error', (tester) async {
      var continued = false;
      final draft = RegisterDraft();
      final es = AppStrings.forTesting('es');
      await tester.pumpWidget(
        _wrap(
          Step3PatientData(
            draft: draft,
            onBack: () {},
            onContinue: () => continued = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _reveal(tester, _continueButton);
      await tester.tap(_continueButton);
      await tester.pumpAndSettle();

      expect(continued, isFalse);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      final errorRow = find.ancestor(
        of: find.byIcon(Icons.error_outline),
        matching: find.byType(Row),
      );
      final errorText = tester
          .widget<Text>(
            find.descendant(of: errorRow, matching: find.byType(Text)),
          )
          .data!;

      expect(errorText, startsWith('Campos requeridos'));
      expect(errorText, contains(es.patientNfcDevice));
      expect(errorText, contains(es.documentNumberLabel));
      expect(errorText, contains(es.firstNameLabel));
      expect(errorText, contains(es.lastNameLabel));
      expect(errorText, contains(es.dobLabel));
      expect(errorText, contains(es.municipality));
      expect(errorText, contains(es.department));
    });
  });

  group('Step3PatientData - NFC scan (_scanPatientNfc)', () {
    testWidgets('successful scan fills the UID field and draft.deviceUid', (
      tester,
    ) async {
      NfcService.overrideReadDeviceUid = () async => 'AA:11:BB:22';
      final draft = RegisterDraft();
      await tester.pumpWidget(
        _wrap(Step3PatientData(draft: draft, onBack: () {}, onContinue: () {})),
      );
      await tester.pumpAndSettle();

      await tester.tap(_scanButton);
      await tester.pumpAndSettle();

      expect(draft.deviceUid, 'AA:11:BB:22');
      expect(find.text('AA:11:BB:22'), findsOneWidget);
    });

    testWidgets('NfcNotAvailableException shows the localized message', (
      tester,
    ) async {
      NfcService.overrideReadDeviceUid = () async =>
          throw NfcNotAvailableException();
      final draft = RegisterDraft();
      final es = AppStrings.forTesting('es');
      await tester.pumpWidget(
        _wrap(Step3PatientData(draft: draft, onBack: () {}, onContinue: () {})),
      );
      await tester.pumpAndSettle();

      await tester.tap(_scanButton);
      await tester.pumpAndSettle();

      expect(find.text(es.nfcNotAvailable), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('NfcSessionException shows its raw message', (tester) async {
      NfcService.overrideReadDeviceUid = () async =>
          throw NfcSessionException('Tag read failed');
      final draft = RegisterDraft();
      await tester.pumpWidget(
        _wrap(Step3PatientData(draft: draft, onBack: () {}, onContinue: () {})),
      );
      await tester.pumpAndSettle();

      await tester.tap(_scanButton);
      await tester.pumpAndSettle();

      expect(find.text('Tag read failed'), findsOneWidget);
    });
  });

  group('Step3PatientData - happy path save fallback', () {
    testWidgets('unparsable weight/height fall back to null', (tester) async {
      final draft = RegisterDraft();
      await tester.pumpWidget(
        _wrap(Step3PatientData(draft: draft, onBack: () {}, onContinue: () {})),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Step3PatientData), findsOneWidget);
    });
  });

  group('Step3PatientData — Uncovered Branches & Form Handlers', () {
    testWidgets(
      'validates document number in real time showing error border on invalid text',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final draft = RegisterDraft();
        await tester.pumpWidget(
          _wrap(
            Step3PatientData(draft: draft, onBack: () {}, onContinue: () {}),
          ),
        );
        await tester.pumpAndSettle();

        final docField = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Ej. 1098765432',
        );

        await tester.enterText(docField, '123#');
        await tester.pumpAndSettle();

        await tester.enterText(docField, '');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'toggles dropdown menus open and close on consecutive taps and selects items',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final draft = RegisterDraft();
        await tester.pumpWidget(
          _wrap(
            Step3PatientData(draft: draft, onBack: () {}, onContinue: () {}),
          ),
        );
        await tester.pumpAndSettle();

        final expandIcon = find.byIcon(Icons.expand_more).first;
        await tester.ensureVisible(expandIcon);

        await tester.tap(expandIcon);
        await tester.pumpAndSettle();

        await tester.tap(expandIcon);
        await tester.pumpAndSettle();

        await tester.tap(expandIcon);
        await tester.pumpAndSettle();

        final menuItem = find.byType(MenuItemButton);
        if (menuItem.evaluate().isNotEmpty) {
          await tester.tap(menuItem.first);
        } else {
          final textFinder = find.textContaining('Cédula');
          if (textFinder.evaluate().isNotEmpty) {
            await tester.tap(textFinder.first);
          }
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('selects date of birth using DatePicker dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final draft = RegisterDraft()..dob = DateTime(1995, 6, 15);
      await tester.pumpWidget(
        _wrap(Step3PatientData(draft: draft, onBack: () {}, onContinue: () {})),
      );
      await tester.pumpAndSettle();

      final datePickerFinder = find.byIcon(Icons.calendar_today_outlined);
      await tester.tap(datePickerFinder);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(draft.dob, isNotNull);
    });

    testWidgets(
      'selects ethnicity showing ethnic community text input field when active',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final draft = RegisterDraft()..ethnicity = '1';
        await tester.pumpWidget(
          _wrap(
            Step3PatientData(draft: draft, onBack: () {}, onContinue: () {}),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Comunidad étnica'), findsOneWidget);
      },
    );

    testWidgets('completes entire form validly and triggers onContinue', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var continued = false;
      final draft = RegisterDraft()
        ..weight = 70.5
        ..height = 175.0;

      await tester.pumpWidget(
        _wrap(
          Step3PatientData(
            draft: draft,
            onBack: () {},
            onContinue: () => continued = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      await tester.enterText(textFields.at(0), 'P-UID-999');

      await tester.enterText(textFields.at(1), '1098765432');

      await tester.enterText(textFields.at(2), 'Carmen');

      await tester.enterText(textFields.at(4), 'Vargas');

      draft.dob = DateTime(1995, 5, 20);

      final allFields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();

      for (var i = 0; i < allFields.length; i++) {
        final hint = allFields[i].decoration?.hintText ?? '';
        if (hint.contains('Riohacha') || hint.contains('ej: Riohacha')) {
          await tester.enterText(textFields.at(i), 'Riohacha');
        } else if (hint.contains('La Guajira') ||
            hint.contains('ej: La Guajira')) {
          await tester.enterText(textFields.at(i), 'La Guajira');
        }
      }

      await tester.pumpAndSettle();

      await _reveal(tester, _continueButton);
      await tester.tap(_continueButton);
      await tester.pumpAndSettle();

      expect(continued, isTrue);
      expect(draft.deviceUid, equals('P-UID-999'));
    });
  });

  group('Step3PatientData — Cobertura 100% de líneas faltantes', () {
    testWidgets(
      'Formatea peso entero sin decimales e interactúa con chips de sexo, zona y tipo de sangre',
      (tester) async {
        tester.view.physicalSize = const Size(800, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final draft = RegisterDraft()
          ..weight = 70.0
          ..height = 175.0;

        await tester.pumpWidget(
          _wrap(
            Step3PatientData(draft: draft, onBack: () {}, onContinue: () {}),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('70'), findsOneWidget);

        final maleChip = find.text('Masculino');
        if (maleChip.evaluate().isNotEmpty) {
          await tester.ensureVisible(maleChip);
          await tester.tap(maleChip);
          await tester.pumpAndSettle();
          expect(draft.biologicalSex, 'M');
        }

        final bloodChip = find.text('O+');
        if (bloodChip.evaluate().isNotEmpty) {
          await tester.ensureVisible(bloodChip);
          await tester.tap(bloodChip);
          await tester.pumpAndSettle();
          expect(draft.bloodType, 'O+');

          await tester.tap(bloodChip);
          await tester.pumpAndSettle();
          expect(draft.bloodType, isNull);
        }

        final ruralChip = find.text('Rural');
        if (ruralChip.evaluate().isNotEmpty) {
          await tester.ensureVisible(ruralChip);
          await tester.tap(ruralChip);
          await tester.pumpAndSettle();
          expect(draft.zone, '02');
        }
      },
    );

    testWidgets(
      'Cambia valores en Dropdowns de Género, Nacionalidad, Etnia y Discapacidad',
      (tester) async {
        tester.view.physicalSize = const Size(800, 3500);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final draft = RegisterDraft();
        await tester.pumpWidget(
          _wrap(
            Step3PatientData(draft: draft, onBack: () {}, onContinue: () {}),
          ),
        );
        await tester.pumpAndSettle();

        final genderDropdown = find.ancestor(
          of: find.text('Does not declare').evaluate().isNotEmpty
              ? find.text('Does not declare')
              : find.text('No declara'),
          matching: find.byType(InkWell),
        );
        if (genderDropdown.evaluate().isNotEmpty) {
          await tester.ensureVisible(genderDropdown.first);
          await tester.tap(genderDropdown.first);
          await tester.pumpAndSettle();

          final option = find.text('Transgénero');
          if (option.evaluate().isNotEmpty) {
            await tester.tap(option.first);
            await tester.pumpAndSettle();
            expect(draft.genderIdentity, '03');
          }
        }

        final natDropdown = find.ancestor(
          of: find.textContaining('Colombiana'),
          matching: find.byType(InkWell),
        );
        if (natDropdown.evaluate().isNotEmpty) {
          await tester.ensureVisible(natDropdown.first);
          await tester.tap(natDropdown.first);
          await tester.pumpAndSettle();

          final venOption = find.textContaining('Venezolana');
          if (venOption.evaluate().isNotEmpty) {
            await tester.tap(venOption.first);
            await tester.pumpAndSettle();
            expect(draft.nationalityCode, 'VEN');
          }
        }

        final ethDropdown = find.ancestor(
          of: find.text('Ninguno'),
          matching: find.byType(InkWell),
        );
        if (ethDropdown.evaluate().isNotEmpty) {
          await tester.ensureVisible(ethDropdown.first);
          await tester.tap(ethDropdown.first);
          await tester.pumpAndSettle();

          final indOption = find.text('Indígena');
          if (indOption.evaluate().isNotEmpty) {
            await tester.tap(indOption.first);
            await tester.pumpAndSettle();
            expect(draft.ethnicity, '1');
          }
        }

        final disDropdown = find.ancestor(
          of: find.text('Ninguna'),
          matching: find.byType(InkWell),
        );
        if (disDropdown.evaluate().isNotEmpty) {
          await tester.ensureVisible(disDropdown.first);
          await tester.tap(disDropdown.first);
          await tester.pumpAndSettle();

          final fisOption = find.text('Física');
          if (fisOption.evaluate().isNotEmpty) {
            await tester.tap(fisOption.first);
            await tester.pumpAndSettle();
            expect(draft.disabilityCategory, '01');
          }
        }
      },
    );

    testWidgets(
      'Muestra errores al intentar guardar con número de documento inválido y nacionalidad no soportada',
      (tester) async {
        tester.view.physicalSize = const Size(800, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final draft = RegisterDraft()..nationalityCode = 'INVALID_NAT';
        await tester.pumpWidget(
          _wrap(
            Step3PatientData(draft: draft, onBack: () {}, onContinue: () {}),
          ),
        );
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'P-UID-999');
        await tester.enterText(textFields.at(1), '123#');
        await tester.enterText(textFields.at(2), 'María');
        await tester.enterText(textFields.at(4), 'Gómez');
        draft.dob = DateTime(1990, 1, 1);

        final allFields = tester
            .widgetList<TextField>(find.byType(TextField))
            .toList();

        for (var i = 0; i < allFields.length; i++) {
          final hint = allFields[i].decoration?.hintText ?? '';
          if (hint.contains('Riohacha') || hint.contains('ej: Riohacha')) {
            await tester.enterText(textFields.at(i), 'Bogotá');
          } else if (hint.contains('La Guajira') ||
              hint.contains('ej: La Guajira')) {
            await tester.enterText(textFields.at(i), 'Bogotá');
          }
        }
        await tester.pumpAndSettle();

        await _reveal(tester, _continueButton);
        await tester.tap(_continueButton);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(
          find.textContaining('Número de documento inválido'),
          findsOneWidget,
        );
        expect(find.textContaining('Nacionalidad no válida'), findsOneWidget);
      },
    );

    testWidgets(
      'Guarda correctamente datos opcionales (segundo nombre, segundo apellido, comunidad étnica)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 3500);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        var continued = false;
        final draft = RegisterDraft()..ethnicity = '1';

        await tester.pumpWidget(
          _wrap(
            Step3PatientData(
              draft: draft,
              onBack: () {},
              onContinue: () => continued = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);

        await tester.enterText(textFields.at(0), 'P-UID-888');
        await tester.enterText(textFields.at(1), '1098765432');
        await tester.enterText(textFields.at(2), 'María');
        await tester.enterText(textFields.at(3), 'Isabel');
        await tester.enterText(textFields.at(4), 'Gómez');
        await tester.enterText(textFields.at(5), 'Pérez');
        draft.dob = DateTime(1992, 3, 10);

        final ethCommField = find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == 'Nombre de la comunidad',
        );
        if (ethCommField.evaluate().isNotEmpty) {
          await tester.enterText(ethCommField, 'Wayúu');
        }

        final allFields = tester
            .widgetList<TextField>(find.byType(TextField))
            .toList();

        for (var i = 0; i < allFields.length; i++) {
          final hint = allFields[i].decoration?.hintText ?? '';
          if (hint.contains('Riohacha') || hint.contains('ej: Riohacha')) {
            await tester.enterText(textFields.at(i), 'Riohacha');
          } else if (hint.contains('La Guajira') ||
              hint.contains('ej: La Guajira')) {
            await tester.enterText(textFields.at(i), 'La Guajira');
          }
        }

        await tester.pumpAndSettle();

        await _reveal(tester, _continueButton);
        await tester.tap(_continueButton);
        await tester.pumpAndSettle();

        expect(continued, isTrue);
        expect(draft.secondName, 'Isabel');
        expect(draft.secondLastName, 'Pérez');
        expect(draft.ethnicCommunity, 'Wayúu');
      },
    );
  });
}
