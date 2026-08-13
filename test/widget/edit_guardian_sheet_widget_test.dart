// test/widget/edit_guardian_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/edit_guardian_sheet.dart';

class FakeGuardianConsent extends Mock implements GuardianConsent {}

Widget _wrap(Widget child, {String locale = 'es'}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Widget _buildSubject({
  required GuardianInfo guardian,
  required int guardianIndex,
  required ValueChanged<GuardianInfo> onConfirm,
  String locale = 'es',
}) {
  return _wrap(
    EditGuardianSheet(
      guardian: guardian,
      guardianIndex: guardianIndex,
      onConfirm: onConfirm,
    ),
    locale: locale,
  );
}

GuardianInfo _sampleGuardian({
  String name = 'María García',
  String relationship = '01',
  String phone = '3001234567',
  String? deviceUid = 'HWB-AA:BB:CC',
  GuardianConsent? consent,
}) => GuardianInfo(
  name: name,
  relationship: relationship,
  phone: phone,
  deviceUid: deviceUid,
  consent: consent,
);

void main() {
  final fakeConsent = FakeGuardianConsent();
  final sEs = AppStrings.forTesting('es');

  group('Initial Structure and Field Pre-population Rendering', () {
    testWidgets(
      'Displays the correct action header title for guardianIndex == 1 on Spanish locales',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
            locale: 'es',
          ),
        );
        expect(find.text('Editar Guardián Principal'), findsOneWidget);
      },
    );

    testWidgets(
      'Displays the correct action header title for guardianIndex == 2 on Spanish locales',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(consent: fakeConsent),
            guardianIndex: 2,
            onConfirm: (_) {},
            locale: 'es',
          ),
        );
        expect(find.text('Editar Guardián Secundario'), findsOneWidget);
      },
    );

    testWidgets(
      'Displays the correct action header title for guardianIndex == 1 on English locales',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
            locale: 'en',
          ),
        );
        expect(find.text('Edit Primary Guardian'), findsOneWidget);
      },
    );

    testWidgets(
      'Displays the correct action header title for guardianIndex == 2 on English locales',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(consent: fakeConsent),
            guardianIndex: 2,
            onConfirm: (_) {},
            locale: 'en',
          ),
        );
        expect(find.text('Edit Secondary Guardian'), findsOneWidget);
      },
    );

    testWidgets(
      'Pre-populates name entry fields using parameters from baseline models',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(name: 'Juan Pérez', consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );
        expect(find.text('Juan Pérez'), findsOneWidget);
      },
    );

    testWidgets(
      'Pre-populates phone entry fields using parameters from baseline models',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              phone: '3109876543',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );
        expect(find.text('3109876543'), findsOneWidget);
      },
    );

    testWidgets(
      'Pre-populates deviceUid entry fields using parameters from baseline models',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              deviceUid: 'HWB-01:23:45',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );
        expect(find.text('HWB-01:23:45'), findsOneWidget);
      },
    );

    testWidgets(
      'Leaves deviceUid text controllers blank when initialized with null references',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(deviceUid: null, consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );
        final uidField = tester.widget<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && w.controller?.text == '',
            description: 'Empty UID TextField',
          ),
        );
        expect(uidField.controller?.text, '');
      },
    );

    testWidgets(
      'Renders all four relationship tracking choice chips on the interface view',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );
        expect(find.text(sEs.relParents), findsOneWidget);
        expect(find.text(sEs.relSiblings), findsOneWidget);
        expect(find.text(sEs.relUncles), findsOneWidget);
        expect(find.text(sEs.relGrandparents), findsOneWidget);
      },
    );

    testWidgets(
      'Hardware interaction trigger button defaults to baseline NFC icons initially',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );
        expect(find.byIcon(Icons.nfc), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });

  group('Relationship Selection Modifiers Matrix Loops', () {
    for (final entry in {
      '02': (AppStrings s) => s.relSiblings,
      '03': (AppStrings s) => s.relUncles,
      '04': (AppStrings s) => s.relGrandparents,
    }.entries) {
      final code = entry.key;
      final labelFn = entry.value;

      testWidgets(
        'Tapping relationship chip code $code mutates state property values cleanly',
        (tester) async {
          GuardianInfo? received;

          await tester.pumpWidget(
            _buildSubject(
              guardian: _sampleGuardian(
                relationship: '01',
                consent: fakeConsent,
              ),
              guardianIndex: 1,
              onConfirm: (g) => received = g,
            ),
          );

          await tester.tap(find.text(labelFn(sEs)));
          await tester.pump();

          await tester.tap(find.text(sEs.confirmChanges));
          await tester.pump();

          expect(received?.relationship, code);
        },
      );
    }
  });

  group('Form Action Pipelines and Payload Assembly Constraints', () {
    testWidgets(
      'Applies trim transformations to name and phone text entries upon execution',
      (tester) async {
        GuardianInfo? received;

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              name: 'Viejo',
              phone: '000',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (g) => received = g,
          ),
        );

        final nameField = find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'Viejo',
        );
        await tester.enterText(nameField, '  Nuevo Nombre  ');

        final phoneField = find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == '000',
        );
        await tester.enterText(phoneField, ' 3001111111 ');

        await tester.tap(find.text(sEs.confirmChanges));
        await tester.pump();

        expect(received?.name, 'Nuevo Nombre');
        expect(received?.phone, '3001111111');
      },
    );

    testWidgets(
      'Preserves manually typed string contents into the deviceUid destination payload properties',
      (tester) async {
        NavigatorState? navigatorState;
        GuardianInfo? received;

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) {
                navigatorState = Navigator.of(ctx);
                return ElevatedButton(
                  onPressed: () {
                    navigatorState!.push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          body: EditGuardianSheet(
                            guardian: _sampleGuardian(
                              deviceUid: null,
                              consent: fakeConsent,
                            ),
                            guardianIndex: 1,
                            onConfirm: (g) => received = g,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        final uidFields = find.byType(TextField);
        await tester.enterText(uidFields.last, 'HWB-FF:EE:DD');

        await tester.tap(find.text(sEs.confirmChanges));
        await tester.pumpAndSettle();

        expect(received?.deviceUid, 'HWB-FF:EE:DD');
      },
    );

    testWidgets(
      'Wiping deviceUid input field down maps into explicit null references downstream',
      (tester) async {
        GuardianInfo? received;

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(deviceUid: null, consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (g) => received = g,
          ),
        );

        await tester.tap(find.text(sEs.confirmChanges));
        await tester.pump();

        expect(received?.deviceUid, isNull);
      },
    );

    testWidgets(
      'Inherits primitive consent reference parameters across action execution lifetimes',
      (tester) async {
        GuardianInfo? received;

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (g) => received = g,
          ),
        );

        await tester.tap(find.text(sEs.confirmChanges));
        await tester.pump();

        expect(received?.consent, equals(fakeConsent));
      },
    );

    testWidgets(
      'Pops active routing layouts cleanly once form confirmation runs completely',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          body: EditGuardianSheet(
                            guardian: _sampleGuardian(consent: fakeConsent),
                            guardianIndex: 1,
                            onConfirm: (_) {},
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir'),
                );
              },
            ),
            locale: 'es',
          ),
        );

        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        expect(find.text('Editar Guardián Principal'), findsOneWidget);

        await tester.tap(find.text(sEs.confirmChanges));
        await tester.pumpAndSettle();

        expect(find.text('Editar Guardián Principal'), findsNothing);
      },
    );
  });

  group('Visual Layout Asset Color Evaluation Rules', () {
    testWidgets(
      'family_restroom prefix icon utilizes AppColors.secondary parameters when text fields are blank',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(deviceUid: null, consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );

        final icon = tester.widget<Icon>(find.byIcon(Icons.family_restroom));
        expect(icon.color, AppColors.secondary);
      },
    );

    testWidgets(
      'family_restroom prefix icon updates into check_circle_outline icon when valid parameters exist',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              deviceUid: 'HWB-01:02:03',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );

        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      },
    );

    testWidgets(
      'Prefix icon signals context switches into check_circle_outline instantly upon typing',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(deviceUid: null, consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );

        await tester.enterText(find.byType(TextField).last, 'HWB-AA');
        await tester.pump();

        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      },
    );
  });

  group('Memory Lifecycle and Instance Cleanup Routine Validations', () {
    testWidgets(
      'Destroys active controller instances cleanly without background exceptions leaky traces',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );

        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Structural Typography Styling Parameter Checks', () {
    testWidgets(
      'Label components explicitly configure text sizes to 13 along w600 weight bounds',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );

        final labelText = tester.widget<Text>(find.text(sEs.guardianFullName));
        expect(labelText.style?.fontSize, 13);
        expect(labelText.style?.fontWeight, FontWeight.w600);
      },
    );
  });

  group('TextInputType Virtual Keyboard Domain Constraints', () {
    testWidgets(
      'Phone number field sets active virtual layouts directly into TextInputType.phone',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              phone: '3001234567',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );

        final phoneField = tester.widget<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && w.controller?.text == '3001234567',
          ),
        );
        expect(phoneField.keyboardType, TextInputType.phone);
      },
    );

    testWidgets(
      'Full name entry fields default configuration into TextInputType.text layouts safely',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              name: 'NombreUnico',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );

        final nameField = tester.widget<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && w.controller?.text == 'NombreUnico',
          ),
        );
        expect(nameField.keyboardType, TextInputType.text);
      },
    );
  });
}
