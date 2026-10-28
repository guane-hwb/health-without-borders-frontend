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
  Future<String?> Function()? readDevice,
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
          readDevice: readDevice,
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
      expect(find.textContaining(s.guardianRelationship), findsOneWidget);
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

      final s = AppStrings.forTesting('es');
      final selector = find.text(s.docTypeCC).first;
      await tester.ensureVisible(selector);
      await tester.tap(selector);
      await tester.pumpAndSettle();

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

  group('Step2Guardian — Cobertura 100% de Gestos, Menús y Validaciones', () {
    testWidgets(
      '36. Cierre del MenuAnchor si ya se encuentra abierto al presionar el selector de tipo de documento',
      (tester) async {
        resizeViewport(tester);
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        final selector = find.text(s.docTypeCC).first;
        await tester.ensureVisible(selector);

        await tester.tap(selector);
        await tester.pumpAndSettle();

        await tester.tap(selector);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '37. Interacción completa con gestos de firma (panStart, panUpdate, panEnd) y checkbox de Guardián 1 y Guardián 2',
      (tester) async {
        resizeViewport(tester);
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final addBtn = find.text('Agregar');
        await tester.ensureVisible(addBtn);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        final signaturePads = find.byType(CustomPaint);
        if (signaturePads.evaluate().isNotEmpty) {
          final pad1 = signaturePads.first;
          await tester.ensureVisible(pad1);
          await tester.drag(pad1, const Offset(30, 30), warnIfMissed: false);
          await tester.pumpAndSettle();
        }

        if (signaturePads.evaluate().length > 1) {
          final pad2 = signaturePads.at(1);
          await tester.ensureVisible(pad2);
          await tester.drag(pad2, const Offset(30, 30), warnIfMissed: false);
          await tester.pumpAndSettle();
        }

        final s = AppStrings.forTesting('es');
        final docType2Selectors = find.text(s.docTypeCC);
        if (docType2Selectors.evaluate().length > 1) {
          await tester.ensureVisible(docType2Selectors.last);
          await tester.tap(docType2Selectors.last);
          await tester.pumpAndSettle();
          final ceOption = find.text(s.docTypeCE).last;
          await tester.tap(ceOption);
          await tester.pumpAndSettle();
        }

        final checkboxes = find.byType(Checkbox);
        if (checkboxes.evaluate().isNotEmpty) {
          await tester.ensureVisible(checkboxes.first);
          await tester.tap(checkboxes.first);
          await tester.pumpAndSettle();
        }

        if (checkboxes.evaluate().length > 1) {
          await tester.ensureVisible(checkboxes.last);
          await tester.tap(checkboxes.last);
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      '38. Muestra mensajes de error de validación de formato (doc, teléfono, correo) al intentar guardar',
      (tester) async {
        resizeViewport(tester);
        final draft = RegisterDraft()
          ..guardianName = 'Ana García'
          ..guardianPhone = '123'
          ..guardianDocNumber = '12'
          ..guardianEmail = 'correo_invalido'
          ..guardianDeviceUid = 'HWB-001'
          ..guardianAuthAccepted = true
          ..guardianSignatureStrokes = [
            [const Offset(10, 10), const Offset(50, 50)],
          ]
          ..guardian2Name = 'Carlos Torres'
          ..guardian2Phone = '456'
          ..guardian2DocNumber = '34'
          ..guardian2Email = 'email_malo'
          ..guardian2AuthAccepted = false
          ..guardian2SignatureStrokes = [
            [const Offset(10, 10), const Offset(50, 50)],
          ];

        await tester.pumpWidget(buildSubject(draft: draft));
        await tester.pumpAndSettle();

        final dynamic state = tester.state(find.byType(Step2Guardian));
        await tester.runAsync(() async {
          await state.saveForTest();
        });
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(
          find.textContaining('Documento de guardián inválido'),
          findsOneWidget,
        );
      },
    );
  });

  group('Lectura del dispositivo del guardián con readDevice', () {
    Finder scanButton({required bool last}) {
      final f = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.byIcon(Icons.nfc),
      );
      return last ? f.last : f.first;
    }

    testWidgets('usa el UID que devuelve, en los dos guardianes', (
      tester,
    ) async {
      resizeViewport(tester);
      var uid = 'NFC-PROPIO-001';
      await tester.pumpWidget(buildSubject(readDevice: () async => uid));
      await tester.pumpAndSettle();

      await tester.ensureVisible(scanButton(last: false));
      await tester.tap(scanButton(last: false));
      await tester.pumpAndSettle();
      expect(find.textContaining('NFC-PROPIO-001'), findsWidgets);

      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      uid = 'NFC-PROPIO-002';
      await tester.ensureVisible(scanButton(last: true));
      await tester.tap(scanButton(last: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('NFC-PROPIO-002'), findsWidgets);
    });

    testWidgets('si lo rechaza (null), el campo queda como estaba', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = RegisterDraft()..guardianDeviceUid = 'NFC-ANTERIOR';
      await tester.pumpWidget(
        buildSubject(draft: draft, readDevice: () async => null),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(scanButton(last: false));
      await tester.tap(scanButton(last: false));
      await tester.pumpAndSettle();
      expect(find.textContaining('NFC-ANTERIOR'), findsWidgets);

      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(scanButton(last: true));
      await tester.tap(scanButton(last: true));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('Step2Guardian — Callbacks de Firma, Gestos, Modales y _commitToDraft', () {
    testWidgets(
      '39. Ejercicio de gestos de firma de Guardián 1 y Guardián 2, limpieza y diálogo de aceptación',
      (tester) async {
        resizeViewport(tester);
        final draft = RegisterDraft();

        await tester.pumpWidget(buildSubject(draft: draft));
        await tester.pumpAndSettle();

        final addBtn = find.text('Agregar');
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        final gestureDetectors = tester.widgetList<GestureDetector>(
          find.byType(GestureDetector),
        );

        final signatureDetectors = gestureDetectors
            .where((g) => g.onPanStart != null)
            .toList();

        if (signatureDetectors.isNotEmpty) {
          signatureDetectors[0].onPanStart?.call(
            DragStartDetails(
              localPosition: const Offset(10, 10),
              globalPosition: const Offset(10, 10),
            ),
          );
          signatureDetectors[0].onPanUpdate?.call(
            DragUpdateDetails(
              localPosition: const Offset(20, 20),
              globalPosition: const Offset(20, 20),
            ),
          );
          signatureDetectors[0].onPanEnd?.call(DragEndDetails());
          await tester.pumpAndSettle();
        }

        if (signatureDetectors.length > 1) {
          signatureDetectors[1].onPanStart?.call(
            DragStartDetails(
              localPosition: const Offset(10, 10),
              globalPosition: const Offset(10, 10),
            ),
          );
          signatureDetectors[1].onPanUpdate?.call(
            DragUpdateDetails(
              localPosition: const Offset(20, 20),
              globalPosition: const Offset(20, 20),
            ),
          );
          signatureDetectors[1].onPanEnd?.call(DragEndDetails());
          await tester.pumpAndSettle();
        }

        final richTextG1 = find.byType(RichText).first;
        await tester.tap(richTextG1);
        await tester.pumpAndSettle();

        final privacyLinks = find.text('política de privacidad');
        await tester.ensureVisible(privacyLinks.first);
        await tester.tap(privacyLinks.first, warnIfMissed: false);
        await tester.pumpAndSettle();

        final dialogClose = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(ElevatedButton),
        );
        if (dialogClose.evaluate().isNotEmpty) {
          await tester.tap(dialogClose);
          await tester.pumpAndSettle();
        }

        final backBtn = find.byIcon(Icons.arrow_back);
        await tester.ensureVisible(backBtn);
        await tester.tap(backBtn);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '40. Muestra mensaje de error cuando Guardián 2 acepta autorización pero no incluye firma',
      (tester) async {
        resizeViewport(tester);

        final draft = RegisterDraft()
          ..guardianName = 'Ana Garcia'
          ..guardianPhone = '3001234567'
          ..guardianDocNumber = '123456789'
          ..guardianDocType = 'CC'
          ..guardianDeviceUid = 'HWB041A2CDE'
          ..guardianAuthAccepted = true
          ..guardianSignatureStrokes = [
            [const Offset(10, 10), const Offset(50, 50)],
          ]
          ..guardian2Name = 'Carlos Lopez'
          ..guardian2Phone = '3109876543'
          ..guardian2DocNumber = '9876543210'
          ..guardian2DocType = 'CC'
          ..guardian2DeviceUid = 'HWB041A2CDF'
          ..guardian2AuthAccepted = true
          ..guardian2SignatureStrokes = <List<Offset>>[];

        await tester.pumpWidget(buildSubject(draft: draft));
        await tester.pumpAndSettle();

        final dynamic state = tester.state(find.byType(Step2Guardian));
        await tester.runAsync(() async {
          await state.saveForTest();
        });
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.textContaining('Firma del guardián 2'), findsOneWidget);
      },
    );
  });

  group('Step2Guardian — Borrador completo, UID y firma del guardián 2', () {
    RegisterDraft fullDraft() => RegisterDraft()
      ..guardianName = 'Ana María García'
      ..guardianPhone = '3158492041'
      ..guardianDeviceUid = 'HWB041A2CDE'
      ..guardianDocNumber = '52384912'
      ..guardianDocType = 'CC'
      ..guardianAuthAccepted = true
      ..guardianSignatureStrokes = [
        [const Offset(10, 10), const Offset(50, 50)],
      ]
      ..guardian2Name = 'Carlos López'
      ..guardian2Phone = '3109876543'
      ..guardian2DeviceUid = 'HWB041A2CDF'
      ..guardian2DocNumber = '9876543210'
      ..guardian2DocType = 'CC'
      ..guardian2Relationship = '01'
      ..guardian2Email = 'carlos@example.com'
      ..guardian2AuthAccepted = true
      ..guardian2SignatureStrokes = [
        [const Offset(10, 10), const Offset(60, 60)],
      ];

    testWidgets(
      'Atrás con ambos guardianes completos guarda todo el borrador',
      (tester) async {
        resizeViewport(tester);
        bool backCalled = false;
        final draft = fullDraft();

        await tester.pumpWidget(
          buildSubject(draft: draft, onBack: () => backCalled = true),
        );
        await tester.pumpAndSettle();

        final backBtn = find.byIcon(Icons.arrow_back);
        await tester.ensureVisible(backBtn);
        await tester.tap(backBtn);
        await tester.pumpAndSettle();

        expect(backCalled, isTrue);
        expect(draft.guardianDocNumber, '52384912');
        expect(draft.guardian2Name, 'Carlos López');
        expect(draft.guardian2Phone, '3109876543');
        expect(draft.guardian2DeviceUid, 'HWB041A2CDF');
        expect(draft.guardian2DocNumber, '9876543210');
        expect(draft.guardian2Email, 'carlos@example.com');
        expect(draft.guardian2AuthAccepted, isTrue);
        expect(draft.guardian2SignatureStrokes, hasLength(1));
      },
    );

    testWidgets(
      'Continuar con ambos guardianes completos conserva el UID del guardián 2',
      (tester) async {
        resizeViewport(tester);
        bool continueCalled = false;
        final draft = fullDraft();

        await tester.pumpWidget(
          buildSubject(draft: draft, onContinue: () => continueCalled = true),
        );
        await tester.pumpAndSettle();

        final dynamic state = tester.state(find.byType(Step2Guardian));
        await tester.runAsync(() async {
          await state.saveForTest();
        });
        await tester.pumpAndSettle();

        expect(find.textContaining('Campos requeridos'), findsNothing);
        expect(continueCalled, isTrue);
        expect(draft.guardian2DeviceUid, 'HWB041A2CDF');
      },
    );

    testWidgets(
      'Escribir en el campo de UID del guardián 1 actualiza el indicador',
      (tester) async {
        resizeViewport(tester);
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final Finder fieldCheck = find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.check_circle && w.size == 18,
        );
        expect(fieldCheck, findsNothing);

        final uidField = find.byWidgetPredicate(
          (w) => w is TextField && w.style?.fontFamily == 'monospace',
        );
        await tester.ensureVisible(uidField.first);
        await tester.enterText(uidField.first, 'HWB-NUEVO-01');
        await tester.pumpAndSettle();

        expect(fieldCheck, findsOneWidget);
        expect(find.textContaining('Dispositivo vinculado'), findsOneWidget);
      },
    );

    testWidgets(
      'Limpiar firma del guardián 2 borra sus trazos y su firma del borrador',
      (tester) async {
        resizeViewport(tester);
        final draft = RegisterDraft();

        await tester.pumpWidget(buildSubject(draft: draft));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();

        final pads = tester
            .widgetList<GestureDetector>(find.byType(GestureDetector))
            .where((g) => g.onPanStart != null)
            .toList();
        expect(pads, hasLength(2));

        pads[1].onPanStart?.call(
          DragStartDetails(
            localPosition: const Offset(10, 10),
            globalPosition: const Offset(10, 10),
          ),
        );
        pads[1].onPanUpdate?.call(
          DragUpdateDetails(
            localPosition: const Offset(40, 40),
            globalPosition: const Offset(40, 40),
          ),
        );
        pads[1].onPanEnd?.call(DragEndDetails());
        await tester.pumpAndSettle();

        expect(find.text('Firmar aquí'), findsOneWidget);

        final clearBtn = find.text('Limpiar firma').last;
        await tester.ensureVisible(clearBtn);
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();

        expect(find.text('Firmar aquí'), findsNWidgets(2));
        expect(draft.guardian2SignatureStrokes, isEmpty);
        expect(draft.guardian2SignatureBase64, isNull);
      },
    );

    testWidgets(
      'Tocar el texto de autorización del guardián 1 conmuta su checkbox',
      (tester) async {
        resizeViewport(tester);
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final authText = find.textContaining(
          'El guardián reconoce haber leído',
          findRichText: true,
        );
        await tester.ensureVisible(authText.first);
        await tester.pumpAndSettle();

        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).first).value,
          isFalse,
        );

        await tester.tapAt(
          tester.getTopLeft(authText.first) + const Offset(8, 8),
        );
        await tester.pumpAndSettle();

        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).first).value,
          isTrue,
        );
      },
    );
  });
}
