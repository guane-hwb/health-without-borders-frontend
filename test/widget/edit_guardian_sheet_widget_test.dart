// test/widget/edit_guardian_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
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
  String? docType = 'CC',
  String? docNumber = '1234567890',
  GuardianConsent? consent,
}) => GuardianInfo(
  name: name,
  relationship: relationship,
  phone: phone,
  docType: docType,
  docNumber: docNumber,
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
        expect(find.text('Editar Cuidador Principal'), findsOneWidget);
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
        expect(find.text('Editar Cuidador Secundario'), findsOneWidget);
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
      'Pre-populates document number entry fields using parameters from baseline models',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              docNumber: '987654321',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );
        expect(find.text('987654321'), findsOneWidget);
      },
    );

    testWidgets(
      'Pre-populates document type selection matching baseline model',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(docType: 'CE', consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );
        expect(find.text(sEs.docTypeCE), findsOneWidget);
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

  group('Consentimiento al editar el acudiente', () {
    testWidgets('editar el mismo acudiente conserva su consentimiento', (
      tester,
    ) async {
      GuardianInfo? received;
      await tester.pumpWidget(
        _buildSubject(
          guardian: _sampleGuardian(phone: '000', consent: fakeConsent),
          guardianIndex: 1,
          onConfirm: (g) => received = g,
        ),
      );

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == '000',
        ),
        '3009999999',
      );
      await tester.tap(find.text(sEs.confirmChanges));
      await tester.pump();

      expect(received?.phone, '3009999999');
      expect(received?.consent, same(fakeConsent));
    });

    testWidgets('otra persona (otro documento) no hereda el consentimiento', (
      tester,
    ) async {
      GuardianInfo? received;
      await tester.pumpWidget(
        _buildSubject(
          guardian: _sampleGuardian(
            name: 'María García',
            docNumber: '1234567890',
            consent: fakeConsent,
          ),
          guardianIndex: 1,
          onConfirm: (g) => received = g,
        ),
      );

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'María García',
        ),
        'Carlos Ruiz',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == '1234567890',
        ),
        '9876543210',
      );
      await tester.tap(find.text(sEs.confirmChanges));
      await tester.pump();

      expect(received?.name, 'Carlos Ruiz');
      expect(received?.consent, isNull);
    });
  });

  group('Form Action Pipelines and Payload Assembly Constraints', () {
    testWidgets(
      'Applies trim transformations to name, phone and document number entries upon execution',
      (tester) async {
        GuardianInfo? received;

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              name: 'Viejo',
              phone: '000',
              docNumber: '111',
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

        final docField = find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == '111',
        );
        await tester.enterText(docField, ' 1234567890 ');

        await tester.tap(find.text(sEs.confirmChanges));
        await tester.pump();

        expect(received?.name, 'Nuevo Nombre');
        expect(received?.phone, '3001111111');
        expect(received?.docNumber, '1234567890');
      },
    );

    testWidgets(
      'Updates docType correctly in payload when selected from menu selector',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        GuardianInfo? received;

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(docType: 'CC', consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (g) => received = g,
          ),
        );

        final docTypeFinder = find.text(sEs.docTypeCC);
        await tester.ensureVisible(docTypeFinder);
        await tester.tap(docTypeFinder);
        await tester.pumpAndSettle();

        final optionFinder = find.text(sEs.docTypeCE);
        await tester.tap(optionFinder.last);
        await tester.pumpAndSettle();

        final saveBtnFinder = find.text(sEs.confirmChanges);
        await tester.ensureVisible(saveBtnFinder);
        await tester.tap(saveBtnFinder);
        await tester.pump();

        expect(received?.docType, 'CE');
      },
    );

    testWidgets(
      'Wiping document number input field maps into explicit null references downstream',
      (tester) async {
        GuardianInfo? received;

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              docNumber: '123456789',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (g) => received = g,
          ),
        );

        final docField = find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == '123456789',
        );
        await tester.enterText(docField, '');

        await tester.tap(find.text(sEs.confirmChanges));
        await tester.pump();

        expect(received?.docNumber, isNull);
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

        expect(find.text('Editar Cuidador Principal'), findsOneWidget);

        await tester.tap(find.text(sEs.confirmChanges));
        await tester.pumpAndSettle();

        expect(find.text('Editar Cuidador Principal'), findsNothing);
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
      'Document number field sets active virtual layouts into TextInputType.number',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              docNumber: '1234567890',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );

        final docField = tester.widget<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && w.controller?.text == '1234567890',
          ),
        );
        expect(docField.keyboardType, TextInputType.number);
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

  group(
    'EditGuardianSheet — Unsaved Changes Dialog, PopScope & Menu Interactivity',
    () {
      testWidgets(
        'toggling menu anchor controller open and close on consecutive taps',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _buildSubject(
              guardian: _sampleGuardian(docType: 'CC', consent: fakeConsent),
              guardianIndex: 1,
              onConfirm: (_) {},
            ),
          );

          final selectorInkWell = find.ancestor(
            of: find.byIcon(Icons.credit_card_outlined).first,
            matching: find.byType(InkWell),
          );

          await tester.ensureVisible(selectorInkWell);

          await tester.tap(selectorInkWell);
          await tester.pumpAndSettle();

          await tester.tap(selectorInkWell);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'shows warning dialog on close when form fields are modified',
        (tester) async {
          await tester.pumpWidget(
            _buildSubject(
              guardian: _sampleGuardian(consent: fakeConsent),
              guardianIndex: 1,
              onConfirm: (_) {},
            ),
          );

          final nameField = find.byWidgetPredicate(
            (w) => w is TextField && w.controller?.text == 'María García',
          );
          await tester.enterText(nameField, 'María Modificada');
          await tester.pump();

          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsOneWidget);
        },
      );

      testWidgets('cancels closing when clicking Cancel in unsaved dialog', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );

        final nameField = find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'María García',
        );
        await tester.enterText(nameField, 'María Modificada');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(find.byType(EditGuardianSheet), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets(
        'confirms exit and closes sheet when clicking Exit in unsaved dialog',
        (tester) async {
          await tester.pumpWidget(
            _wrap(
              Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) => EditGuardianSheet(
                      guardian: _sampleGuardian(consent: fakeConsent),
                      guardianIndex: 1,
                      onConfirm: (_) {},
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
              locale: 'es',
            ),
          );

          await tester.tap(find.text('Abrir'));
          await tester.pumpAndSettle();

          final nameField = find.byWidgetPredicate(
            (w) => w is TextField && w.controller?.text == 'María García',
          );
          await tester.enterText(nameField, 'María Modificada');
          await tester.pump();

          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Salir'));
          await tester.pumpAndSettle();

          expect(find.byType(EditGuardianSheet), findsNothing);
        },
      );

      testWidgets('triggers PopScope unsaved handler on back gesture', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(consent: fakeConsent),
            guardianIndex: 1,
            onConfirm: (_) {},
          ),
        );

        final nameField = find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'María García',
        );
        await tester.enterText(nameField, 'María Modificada');
        await tester.pump();

        final popScope = tester.widget<PopScope>(find.byType(PopScope));
        popScope.onPopInvokedWithResult?.call(false, null);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets(
        'displays validation error messages when submitting empty mandatory fields in Spanish',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _buildSubject(
              guardian: _sampleGuardian(consent: fakeConsent),
              guardianIndex: 1,
              onConfirm: (_) {},
              locale: 'es',
            ),
          );

          final textFields = find.byType(TextField);
          await tester.enterText(textFields.at(0), '');
          await tester.enterText(textFields.at(1), '');
          await tester.enterText(textFields.at(2), '');
          await tester.pump();

          final confirmBtn = find.text('Confirmar cambios');
          await tester.ensureVisible(confirmBtn);
          await tester.tap(confirmBtn);
          await tester.pumpAndSettle();

          expect(
            find.text('El nombre del cuidador es obligatorio'),
            findsOneWidget,
          );
          expect(find.text('El teléfono es obligatorio'), findsOneWidget);
          expect(find.text('El documento es obligatorio'), findsOneWidget);
        },
      );

      testWidgets(
        'displays validation error messages when submitting empty mandatory fields in English',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _buildSubject(
              guardian: _sampleGuardian(consent: fakeConsent),
              guardianIndex: 1,
              onConfirm: (_) {},
              locale: 'en',
            ),
          );

          final textFields = find.byType(TextField);
          await tester.enterText(textFields.at(0), '');
          await tester.enterText(textFields.at(1), '');
          await tester.enterText(textFields.at(2), '');
          await tester.pump();

          final confirmBtn = find.text('Confirm changes');
          await tester.ensureVisible(confirmBtn);
          await tester.tap(confirmBtn);
          await tester.pumpAndSettle();

          expect(find.text('Guardian name is required'), findsOneWidget);
          expect(find.text('Phone number is required'), findsOneWidget);
          expect(find.text('Document number is required'), findsOneWidget);
        },
      );
    },
  );

  group('EditGuardianSheet — Firma Biométrica, Privacidad y Errores', () {
    testWidgets(
      'Muestra sección de autorización, interactúa con firma, checkbox y limpia la firma',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              name: 'María García',
              docNumber: '1234567890',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        final formFields = find.byType(TextFormField);

        await tester.enterText(formFields.at(0), 'Carlos Ruiz');
        await tester.pump();

        await tester.enterText(formFields.at(2), '9876543210');
        await tester.pumpAndSettle();

        expect(find.textContaining('Firma biométrica'), findsWidgets);

        final signaturePad = find.byType(CustomPaint).last;
        await tester.ensureVisible(signaturePad);
        await tester.drag(signaturePad, const Offset(50, 50));
        await tester.pumpAndSettle();

        final clearBtn = find.text('Limpiar firma');
        await tester.ensureVisible(clearBtn);
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();

        final checkbox = find.byType(Checkbox);
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Muestra banner de error cuando falta autorización o firma al cambiar identidad',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              name: 'María García',
              docNumber: '1234567890',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        final formFields = find.byType(TextFormField);
        await tester.enterText(formFields.at(0), 'Carlos Ruiz');
        await tester.pump();
        await tester.enterText(formFields.at(2), '9876543210');
        await tester.pumpAndSettle();

        final checkbox = find.byType(Checkbox);
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        final confirmBtn = find.text(sEs.confirmChanges);
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(find.textContaining('Campos requeridos:'), findsOneWidget);
      },
    );

    testWidgets(
      'Abre y navega por el diálogo de Política de Privacidad en ES y EN',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              name: 'María García',
              docNumber: '1234567890',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        final formFieldsEs = find.byType(TextFormField);
        await tester.enterText(formFieldsEs.at(0), 'Carlos Ruiz');
        await tester.pump();
        await tester.enterText(formFieldsEs.at(2), '9876543210');
        await tester.pumpAndSettle();

        final privacyLinkEs = find.text('política de privacidad');
        await tester.ensureVisible(privacyLinkEs);
        await tester.tap(privacyLinkEs);
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);

        final okBtn = find.text(sEs.ok);
        await tester.ensureVisible(okBtn);
        await tester.tap(okBtn);
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsNothing);

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              name: 'María García',
              docNumber: '1234567890',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
            locale: 'en',
          ),
        );
        await tester.pumpAndSettle();

        final formFieldsEn = find.byType(TextFormField);
        await tester.enterText(formFieldsEn.at(0), 'Carlos Ruiz');
        await tester.pump();
        await tester.enterText(formFieldsEn.at(2), '9876543210');
        await tester.pumpAndSettle();

        final privacyLinkEn = find.text('privacy policy');
        await tester.ensureVisible(privacyLinkEn);
        await tester.tap(privacyLinkEn);
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);

        final closeIcon = find.byIcon(Icons.close).last;
        await tester.tap(closeIcon);
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsNothing);
      },
    );
  });

  group('EditGuardianSheet — Cobertura 100% (Firma, Checkbox y Errores)', () {
    testWidgets(
      'Ejecuta gestos de firma (onPanStart, onPanUpdate, onPanEnd) y _clearSignature',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              name: 'María García',
              docNumber: '1234567890',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        final formFields = find.byType(TextFormField);
        await tester.enterText(formFields.at(0), 'Carlos Ruiz');
        await tester.enterText(formFields.at(2), '9876543210');
        await tester.pumpAndSettle();

        final signaturePad = find.byType(CustomPaint).last;
        await tester.ensureVisible(signaturePad);

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(signaturePad),
        );
        await tester.pump();

        await gesture.moveBy(const Offset(30, 0));
        await tester.pump();

        await gesture.moveBy(const Offset(0, 30));
        await tester.pump();

        await gesture.up();
        await tester.pumpAndSettle();

        final clearBtn = find.text('Limpiar firma');
        await tester.ensureVisible(clearBtn);
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Tocar el texto contenedor del Checkbox (_AuthCheckbox) conmuta la aceptación',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              name: 'María García',
              docNumber: '1234567890',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        final formFields = find.byType(TextFormField);
        await tester.enterText(formFields.at(0), 'Carlos Ruiz');
        await tester.enterText(formFields.at(2), '9876543210');
        await tester.pumpAndSettle();

        final checkboxFinder = find.byType(Checkbox);
        await tester.ensureVisible(checkboxFinder);

        Checkbox checkboxWidget = tester.widget<Checkbox>(checkboxFinder);
        expect(checkboxWidget.value, isFalse);

        await tester.tap(checkboxFinder);
        await tester.pumpAndSettle();

        checkboxWidget = tester.widget<Checkbox>(checkboxFinder);
        expect(checkboxWidget.value, isTrue);
      },
    );

    testWidgets(
      'Muestra el mensaje de error cuando falta la Autorización de política de privacidad',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              name: 'María García',
              docNumber: '1234567890',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        final formFields = find.byType(TextFormField);
        await tester.enterText(formFields.at(0), 'Carlos Ruiz');
        await tester.enterText(formFields.at(2), '9876543210');
        await tester.pumpAndSettle();

        final gestureDetectors = tester.widgetList<GestureDetector>(
          find.byType(GestureDetector),
        );
        final signatureDetector = gestureDetectors.firstWhere(
          (g) => g.onPanStart != null,
        );

        const offsetInitial = Offset(10, 10);
        const offsetMove = Offset(20, 20);

        signatureDetector.onPanStart?.call(
          DragStartDetails(
            localPosition: offsetInitial,
            globalPosition: offsetInitial,
          ),
        );
        signatureDetector.onPanUpdate?.call(
          DragUpdateDetails(
            localPosition: offsetMove,
            globalPosition: offsetMove,
          ),
        );
        signatureDetector.onPanEnd?.call(DragEndDetails());
        await tester.pumpAndSettle();

        final confirmBtn = find.text(sEs.confirmChanges);
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Autorización de política de privacidad'),
          findsOneWidget,
        );
      },
    );
  });

  group(
    'EditGuardianSheet — Limpiar firma y toque en el texto de autorización',
    () {
      Future<void> openAuthSection(WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildSubject(
            guardian: _sampleGuardian(
              name: 'María García',
              docNumber: '1234567890',
              consent: fakeConsent,
            ),
            guardianIndex: 1,
            onConfirm: (_) {},
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        final formFields = find.byType(TextFormField);
        await tester.enterText(formFields.at(0), 'Carlos Ruiz');
        await tester.enterText(formFields.at(2), '9876543210');
        await tester.pumpAndSettle();
      }

      testWidgets(
        'Limpiar firma borra los trazos y vuelve a mostrar "Firmar aquí"',
        (tester) async {
          await openAuthSection(tester);

          final signatureDetector = tester
              .widgetList<GestureDetector>(find.byType(GestureDetector))
              .firstWhere((g) => g.onPanStart != null);

          signatureDetector.onPanStart?.call(
            DragStartDetails(
              localPosition: const Offset(10, 10),
              globalPosition: const Offset(10, 10),
            ),
          );
          signatureDetector.onPanUpdate?.call(
            DragUpdateDetails(
              localPosition: const Offset(40, 40),
              globalPosition: const Offset(40, 40),
            ),
          );
          signatureDetector.onPanEnd?.call(DragEndDetails());
          await tester.pumpAndSettle();

          expect(find.text('Firmar aquí'), findsNothing);

          final clearBtn = find.text('Limpiar firma');
          await tester.ensureVisible(clearBtn);
          await tester.tap(clearBtn);
          await tester.pumpAndSettle();

          expect(find.text('Firmar aquí'), findsOneWidget);
        },
      );

      testWidgets('Tocar el texto de autorización conmuta el checkbox', (
        tester,
      ) async {
        await openAuthSection(tester);

        final authText = find.textContaining(
          'El cuidador reconoce haber leído',
          findRichText: true,
        );
        await tester.ensureVisible(authText);
        await tester.pumpAndSettle();

        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

        await tester.tapAt(tester.getTopLeft(authText) + const Offset(8, 8));
        await tester.pumpAndSettle();

        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      });
    },
  );
}
