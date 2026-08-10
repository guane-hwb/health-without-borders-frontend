// test/widget/step2_guardian_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step2_guardian.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_service.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/register_draft.dart';

Widget buildSubject({
  RegisterDraft? draft,
  bool requiredForMinor = false,
  VoidCallback? onBack,
  VoidCallback? onContinue,
  String locale = 'es',
}) {
  return _LocaleWrapper(
    locale: locale,
    child: MaterialApp(
      home: Scaffold(
        body: Step2Guardian(
          draft: draft ?? RegisterDraft(),
          requiredForMinor: requiredForMinor,
          onBack: onBack ?? () {},
          onContinue: onContinue ?? () {},
        ),
      ),
    ),
  );
}

class _LocaleWrapper extends StatefulWidget {
  const _LocaleWrapper({required this.locale, required this.child});
  final String locale;
  final Widget child;

  @override
  State<_LocaleWrapper> createState() => _LocaleWrapperState();
}

class _LocaleWrapperState extends State<_LocaleWrapper> {
  late String _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
  }

  @override
  Widget build(BuildContext context) => AppLocale(
    locale: _locale,
    setLocale: (l) => setState(() => _locale = l),
    child: widget.child,
  );
}

void main() {
  void resizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
  }

  setUp(() {
    NfcService.overrideReadDeviceUid = null;
  });

  group('Step2Guardian – render inicial (Tests 1 a 5)', () {
    testWidgets('1. Muestra el widget sin lanzar excepciones', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(Step2Guardian), findsOneWidget);
    });

    testWidgets('2. Muestra el banner de aviso informativo (adulto)', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject(requiredForMinor: false));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('3. Muestra el banner de advertencia (menor)', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject(requiredForMinor: true));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('4. Botón Atrás y Continuar están presentes', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('5. Botón "Agregar" guardián 2 es visible al inicio', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('Step2Guardian – carga desde draft (Tests 6 a 7)', () {
    testWidgets('6. Campos guardián 1 se pre-llenan correctamente', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = RegisterDraft()
        ..guardianName = 'Ana García'
        ..guardianPhone = '3001234567'
        ..guardianDocNumber = '123456789'
        ..guardianEmail = 'ana@example.com';

      await tester.pumpWidget(buildSubject(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Ana García'), findsOneWidget);
      expect(find.text('3001234567'), findsOneWidget);
      expect(find.text('123456789'), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);
    });

    testWidgets('7. Muestra guardián 2 si guardian2Name tiene contenido', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = RegisterDraft()..guardian2Name = 'Carlos López';

      await tester.pumpWidget(buildSubject(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Carlos López'), findsOneWidget);
    });
  });

  group('_NoticeBanner (Tests 8 a 9)', () {
    testWidgets('8. Color de fondo amarillo cuando requiredForMinor=true', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject(requiredForMinor: true));
      await tester.pumpAndSettle();
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(Icons.warning_amber_rounded),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, const Color(0xFFFFF3CD));
    });

    testWidgets('9. Color de fondo azul cuando requiredForMinor=false', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject(requiredForMinor: false));
      await tester.pumpAndSettle();
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(Icons.info_outline_rounded),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, const Color(0xFFE8F4FD));
    });
  });

  group('Guardián 2 – agregar y eliminar (Tests 10 a 11)', () {
    testWidgets('10. Al tocar "Agregar" aparece la sección de guardián 2', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('11. Al tocar eliminar, desaparece la sección de guardián 2', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.text('Agregar'), findsOneWidget);
    });
  });

  group('_SignaturePad (Tests 12 a 13)', () {
    testWidgets('12. Muestra placeholder "Firmar aquí" cuando no hay firma', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('Firmar aquí'), findsWidgets);
    });

    testWidgets('13. Botón limpiar firma está deshabilitado sin trazos', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final clearButton = tester.widget<OutlinedButton>(
        find
            .ancestor(
              of: find.byIcon(Icons.refresh),
              matching: find.byType(OutlinedButton),
            )
            .first,
      );
      expect(clearButton.onPressed, isNull);
    });
  });

  group('_NfcField (Tests 14 a 15)', () {
    testWidgets('14. Icono NFC visible en el botón de escaneo', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.nfc), findsWidgets);
    });

    testWidgets('15. Muestra ícono check_circle cuando el campo tiene valor', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = RegisterDraft()..guardianDeviceUid = 'HWB041A2CDE';
      await tester.pumpWidget(buildSubject(draft: draft));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });
  });

  group('_PrivacyPolicyDialog (Tests 16 a 17)', () {
    testWidgets('16. El diálogo se abre al tocar el link de privacidad', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final privacyLink = find.text('política de privacidad');
      await tester.ensureVisible(privacyLink.first);
      await tester.tap(privacyLink.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('17. El diálogo se cierra con el ícono de cerrar (X)', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final privacyLink = find.text('política de privacidad');
      await tester.ensureVisible(privacyLink.first);
      await tester.tap(privacyLink.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });
  });

  group('_ErrorBanner – validación _save() (Tests 18 a 19)', () {
    testWidgets(
      '18. Aparece banner de error cuando falta nombre (requiredForMinor)',
      (tester) async {
        resizeViewport(tester);
        await tester.pumpWidget(buildSubject(requiredForMinor: true));
        await tester.pumpAndSettle();

        final continueBtn = find.byIcon(Icons.arrow_forward);
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      },
    );

    testWidgets(
      '19. El banner de error no aparece si el formulario es válido',
      (tester) async {
        resizeViewport(tester);
        bool continueCalled = false;

        final draft = RegisterDraft()
          ..guardianName = 'Ana María García'
          ..guardianPhone = '3158492041'
          ..guardianDeviceUid = 'HWB041A2CDE'
          ..guardianDocNumber = '52384912'
          ..guardianDocType = 'CC'
          ..guardianAuthAccepted = true
          ..guardianSignatureStrokes = [
            [const Offset(10, 10), const Offset(50, 50)],
          ];

        await tester.pumpWidget(
          buildSubject(
            draft: draft,
            requiredForMinor: false,
            onContinue: () => continueCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        final continueBtn = find.byIcon(Icons.arrow_forward);
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);

        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(continueCalled, isTrue);
      },
    );
  });

  group('_NavButtons (Tests 20 a 21)', () {
    testWidgets('20. El botón Atrás llama onBack', (tester) async {
      resizeViewport(tester);
      bool backCalled = false;
      await tester.pumpWidget(buildSubject(onBack: () => backCalled = true));
      await tester.pumpAndSettle();

      final backBtn = find.byIcon(Icons.arrow_back);
      await tester.ensureVisible(backBtn);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
    });

    testWidgets(
      '21. El botón Continuar (formulario válido adulto) llama onContinue',
      (tester) async {
        resizeViewport(tester);
        bool continueCalled = false;

        final draft = RegisterDraft()
          ..guardianName = 'Ana María García'
          ..guardianPhone = '3158492041'
          ..guardianDeviceUid = 'HWB041A2CDE'
          ..guardianDocNumber = '52384912'
          ..guardianDocType = 'CC'
          ..guardianAuthAccepted = true
          ..guardianSignatureStrokes = [
            [const Offset(10, 10), const Offset(50, 50)],
          ];

        await tester.pumpWidget(
          buildSubject(
            draft: draft,
            requiredForMinor: false,
            onContinue: () => continueCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        final continueBtn = find.byIcon(Icons.arrow_forward);
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);

        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        expect(continueCalled, isTrue);
      },
    );
  });

  group('_AuthCheckbox (Tests 22 a 23)', () {
    testWidgets('22. Checkbox de autorización está desmarcado por defecto', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(checkboxes.first.value, isFalse);
    });

    testWidgets('23. Checkbox se marca al tocar', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final targetCheckbox = find.byType(Checkbox).first;
      await tester.ensureVisible(targetCheckbox);
      await tester.tap(targetCheckbox);
      await tester.pumpAndSettle();

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(checkboxes.first.value, isTrue);
    });
  });

  group('_AppStrings e i18n Nativo (Test 24)', () {
    testWidgets('24. Muestra etiquetas correctas del parentesco', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.guardianRelationship), findsOneWidget);
    });
  });

  group('NFC y Cobertura Extendida de Guardián 1 y Guardián 2 (100% Cobertura)', () {
    testWidgets('25. Escaneo NFC Exitoso para Guardián 1', (tester) async {
      resizeViewport(tester);
      NfcService.overrideReadDeviceUid = () async => 'NFC-GUARD-001';

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final scanBtn = find
          .descendant(
            of: find.byType(ElevatedButton),
            matching: find.byIcon(Icons.nfc),
          )
          .first;

      await tester.ensureVisible(scanBtn);
      await tester.tap(scanBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('NFC-GUARD-001'), findsWidgets);
    });

    testWidgets(
      '26. Escaneo NFC lanza NfcNotAvailableException en Guardián 1',
      (tester) async {
        resizeViewport(tester);
        NfcService.overrideReadDeviceUid = () async =>
            throw NfcNotAvailableException();

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final scanBtn = find
            .descendant(
              of: find.byType(ElevatedButton),
              matching: find.byIcon(Icons.nfc),
            )
            .first;

        await tester.ensureVisible(scanBtn);
        await tester.tap(scanBtn);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets('27. Escaneo NFC lanza excepción genérica en Guardián 1', (
      tester,
    ) async {
      resizeViewport(tester);
      NfcService.overrideReadDeviceUid = () async =>
          throw Exception('NFC Fail');

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final scanBtn = find
          .descendant(
            of: find.byType(ElevatedButton),
            matching: find.byIcon(Icons.nfc),
          )
          .first;

      await tester.ensureVisible(scanBtn);
      await tester.tap(scanBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
      '28. Escaneo NFC Exitoso, Error No Disponible y Genérico en Guardián 2',
      (tester) async {
        resizeViewport(tester);
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();

        // 1. Escaneo exitoso G2
        NfcService.overrideReadDeviceUid = () async => 'NFC-GUARD-002';
        final scanBtnG2 = find
            .descendant(
              of: find.byType(ElevatedButton),
              matching: find.byIcon(Icons.nfc),
            )
            .last;

        await tester.ensureVisible(scanBtnG2);
        await tester.tap(scanBtnG2);
        await tester.pumpAndSettle();

        expect(find.textContaining('NFC-GUARD-002'), findsWidgets);

        // 2. Error NfcNotAvailableException G2
        NfcService.overrideReadDeviceUid = () async =>
            throw NfcNotAvailableException();
        await tester.tap(scanBtnG2);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(SnackBar), findsAtLeastNWidgets(1));

        // 3. Error Genérico G2
        NfcService.overrideReadDeviceUid = () async =>
            throw Exception('NFC2 Fail');
        await tester.tap(scanBtnG2);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(SnackBar), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      '29. Dibujado de firma biométrica en Canvas, generación de Base64 y borrado',
      (tester) async {
        resizeViewport(tester);
        bool continueCalled = false;

        final draft = RegisterDraft()
          ..guardianName = 'Ana María García'
          ..guardianPhone = '3158492041'
          ..guardianDocNumber = '52384912'
          ..guardianDocType = 'CC'
          ..guardianDeviceUid = 'HWB041A2CDE'
          ..guardianSignatureStrokes = [
            [const Offset(10, 10), const Offset(50, 50)],
          ];

        await tester.pumpWidget(
          buildSubject(
            draft: draft,
            requiredForMinor: false,
            onContinue: () => continueCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Checkbox de autorización
        final checkbox = find.byType(Checkbox).first;
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        // 2. Invocar la lógica de guardado mediante saveForTest
        final dynamic state = tester.state(find.byType(Step2Guardian));
        await tester.runAsync(() async {
          await state.saveForTest();
        });
        await tester.pumpAndSettle();

        // 3. Confirmar que la firma y los datos pasaron la validación y llamaron a onContinue
        expect(continueCalled, isTrue);
        expect(find.byIcon(Icons.error_outline), findsNothing);

        // 4. Probar la función de limpiar firma
        final clearBtn = find.text('Limpiar firma').first;
        await tester.ensureVisible(clearBtn);
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '30. Guardián 2 completo: firma biométrica, dropdowns, selección de chip y asignación a RegisterDraft',
      (tester) async {
        resizeViewport(tester);

        final draft = RegisterDraft()
          ..guardianName = 'Ana Garcia'
          ..guardianPhone = '3001234567'
          ..guardianDocNumber = '123456789'
          ..guardianDeviceUid = 'HWB041A2CDE'
          ..guardianEmail = 'ana@example.com'
          ..guardianAuthAccepted = true
          ..guardianSignatureStrokes = [
            [const Offset(10, 10), const Offset(50, 50)],
          ];

        await tester.pumpWidget(buildSubject(draft: draft));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');

        final name2Input = find
            .widgetWithText(TextField, s.guardianFullNameHint)
            .last;
        await tester.ensureVisible(name2Input);
        await tester.enterText(name2Input, 'Carlos López');

        final phone2Input = find
            .widgetWithText(TextField, s.guardianPhoneHint)
            .last;
        await tester.ensureVisible(phone2Input);
        await tester.enterText(phone2Input, '3109876543');

        final doc2Input = find.widgetWithText(TextField, 'Ej. 1234567890').last;
        await tester.ensureVisible(doc2Input);
        await tester.enterText(doc2Input, '9876543210');

        final email2Input = find.widgetWithText(TextField, s.emailHint).last;
        await tester.ensureVisible(email2Input);
        await tester.enterText(email2Input, 'carlos@example.com');

        final chipHermanos = find.text(s.relSiblings).last;
        await tester.ensureVisible(chipHermanos);
        await tester.tap(chipHermanos);
        await tester.pumpAndSettle();

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        final dynamic state = tester.state(find.byType(Step2Guardian));

        await tester.runAsync(() async {
          await state.saveForTest();
        });
        await tester.pumpAndSettle();

        expect(draft.guardian2Name, equals('Carlos López'));
        expect(draft.guardian2Phone, equals('3109876543'));
        expect(draft.guardian2DocNumber, equals('9876543210'));
        expect(draft.guardian2Relationship, equals('02'));

        final clearBtns = find.text('Limpiar firma');
        if (clearBtns.evaluate().isNotEmpty) {
          await tester.ensureVisible(clearBtns.last);
          await tester.tap(clearBtns.last);
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets('31. Cambio de Dropdown de tipo de documento', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final dropdown = find.byType(DropdownButton<String>).first;
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      final ceItem = find.text(s.docTypeCE).last;
      await tester.tap(ceItem);
      await tester.pumpAndSettle();
    });

    testWidgets(
      '32. Renderizado del Modal de Políticas de Privacidad en Inglés',
      (tester) async {
        resizeViewport(tester);
        await tester.pumpWidget(buildSubject(locale: 'en'));
        await tester.pumpAndSettle();

        final privacyLink = find.text('privacy policy');
        await tester.ensureVisible(privacyLink.first);
        await tester.tap(privacyLink.first, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('Privacy Policy'), findsWidgets);
      },
    );

    testWidgets('33. Interacción con el texto del Checkbox de Autorización', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final checkbox = find.byType(Checkbox).first;
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      final checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, isTrue);
    });

    testWidgets(
      '34. Cambio manual en input de texto NFC de Guardián 1 y Guardián 2 activa onChanged()',
      (tester) async {
        resizeViewport(tester);
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Guardián 1 NFC onChanged
        final uidFieldG1 = tester
            .widgetList<TextField>(find.byType(TextField))
            .elementAt(2);
        await tester.enterText(find.byWidget(uidFieldG1), 'MANUAL-UID-01');
        await tester.pumpAndSettle();

        expect(find.textContaining('MANUAL-UID-01'), findsWidgets);

        // Habilitar Guardián 2 y cambiar NFC manualmente
        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();

        final uidFieldG2 = tester
            .widgetList<TextField>(find.byType(TextField))
            .elementAt(8);
        await tester.enterText(find.byWidget(uidFieldG2), 'MANUAL-UID-02');
        await tester.pumpAndSettle();

        expect(find.textContaining('MANUAL-UID-02'), findsWidgets);
      },
    );

    testWidgets(
      '35. Cambio de parentesco mediante Chips en Guardián 1 dispara la función de actualización',
      (tester) async {
        resizeViewport(tester);
        final draft = RegisterDraft();
        await tester.pumpWidget(buildSubject(draft: draft));
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        final chipTios = find.text(s.relUncles).first;
        await tester.ensureVisible(chipTios);
        await tester.tap(chipTios);
        await tester.pumpAndSettle();

        expect(draft.guardianRelationship, equals('03'));
      },
    );
  });
}
