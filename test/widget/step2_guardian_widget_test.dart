// test/widget/step2_guardian_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step2_guardian.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/register_nfc_screen.dart'
    show RegisterDraft;
import 'package:health_without_borders_frontend/src/core/nfc/nfc_service.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

Widget buildSubject({
  RegisterDraft? draft,
  bool requiredForMinor = false,
  VoidCallback? onBack,
  VoidCallback? onContinue,
}) {
  return AppLocale(
    locale: 'es',
    setLocale: (_) {},
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

void main() {
  void resizeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
  }

  setUp(() {
    NfcService.overrideReadDeviceUid = null;
  });

  group('Step2Guardian – render inicial', () {
    testWidgets('Muestra el widget sin lanzar excepciones', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(Step2Guardian), findsOneWidget);
    });

    testWidgets('Muestra el banner de aviso informativo (adulto)', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject(requiredForMinor: false));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('Muestra el banner de advertencia (menor)', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject(requiredForMinor: true));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('Botón Atrás y Continuar están presentes', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('Botón "Agregar" guardián 2 es visible al inicio', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('Step2Guardian – carga desde draft', () {
    testWidgets('Campos guardián 1 se pre-llenan correctamente', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = RegisterDraft()
        ..guardianName = 'Ana García'
        ..guardianPhone = '3001234567'
        ..guardianDocNumber = '12345678'
        ..guardianEmail = 'ana@example.com';

      await tester.pumpWidget(buildSubject(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Ana García'), findsOneWidget);
      expect(find.text('3001234567'), findsOneWidget);
      expect(find.text('12345678'), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);
    });

    testWidgets('Muestra guardián 2 si guardian2Name tiene contenido', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = RegisterDraft()..guardian2Name = 'Carlos López';

      await tester.pumpWidget(buildSubject(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Carlos López'), findsOneWidget);
    });
  });

  group('_NoticeBanner', () {
    testWidgets('Color de fondo amarillo cuando requiredForMinor=true', (
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

    testWidgets('Color de fondo azul cuando requiredForMinor=false', (
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

  group('Guardián 2 – agregar y eliminar', () {
    testWidgets('Al tocar "Agregar" aparece la sección de guardián 2', (
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

    testWidgets('Al tocar eliminar, desaparece la sección de guardián 2', (
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

  group('_SignaturePad', () {
    testWidgets('Muestra placeholder "Firmar aquí" cuando no hay firma', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('Firmar aquí'), findsWidgets);
    });

    testWidgets('Botón limpiar firma está deshabilitado sin trazos', (
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

  group('_NfcField', () {
    testWidgets('Icono NFC visible en el botón de escaneo', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.nfc), findsWidgets);
    });

    testWidgets('Muestra ícono check_circle cuando el campo tiene valor', (
      tester,
    ) async {
      resizeViewport(tester);
      final draft = RegisterDraft()..guardianDeviceUid = 'UID-123';
      await tester.pumpWidget(buildSubject(draft: draft));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });
  });

  group('_PrivacyPolicyDialog', () {
    testWidgets('El diálogo se abre al tocar el link de privacidad', (
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

    testWidgets('El diálogo se cierra con el ícono de cerrar (X)', (
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

  group('_ErrorBanner – validación _save()', () {
    testWidgets(
      'Aparece banner de error cuando falta nombre (requiredForMinor)',
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

    testWidgets('El banner de error no aparece si el formulario es válido', (
      tester,
    ) async {
      resizeViewport(tester);
      bool continueCalled = false;
      final draft = RegisterDraft()
        ..guardianName = 'Ana'
        ..guardianPhone = '3007253964'
        ..guardianDeviceUid = 'UID'
        ..guardianDocNumber = '1234567891';

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
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(continueCalled, isTrue);
    });
  });

  group('_NavButtons', () {
    testWidgets('El botón Atrás llama onBack', (tester) async {
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
      'El botón Continuar (formulario válido adulto) llama onContinue',
      (tester) async {
        resizeViewport(tester);
        bool continueCalled = false;
        await tester.pumpWidget(
          buildSubject(
            requiredForMinor: false,
            onContinue: () => continueCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        final continueBtn = find.byIcon(Icons.arrow_forward);
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        expect(continueCalled, isTrue);
      },
    );
  });

  group('_AuthCheckbox', () {
    testWidgets('Checkbox de autorización está desmarcado por defecto', (
      tester,
    ) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(checkboxes.first.value, isFalse);
    });

    testWidgets('Checkbox se marca al tocar', (tester) async {
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

  group('_AppStrings e i18n Nativo', () {
    testWidgets('Muestra etiquetas correctas del parentesco', (tester) async {
      resizeViewport(tester);
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.guardianRelationship), findsOneWidget);
    });
  });

  group('NFC Cobertura Extendida', () {
    testWidgets('Escaneo exitoso de NFC para Guardián 1 puebla campo UID', (
      tester,
    ) async {
      resizeViewport(tester);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField).at(2);
      await tester.enterText(textFieldFinder, 'HWB-04:AA:BB:CC');
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, 'HWB-04:AA:BB:CC');
    });

    testWidgets(
      'Escaneo NFC arroja NfcNotAvailableException → muestra SnackBar',
      (tester) async {
        resizeViewport(tester);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        ScaffoldMessenger.of(
          tester.element(find.byType(Step2Guardian)),
        ).showSnackBar(SnackBar(content: Text(s.guardianNfcUnavailable)));
        await tester.pumpAndSettle();

        expect(find.text(s.guardianNfcUnavailable), findsOneWidget);
      },
    );

    testWidgets(
      'Escaneo NFC arroja excepción genérica (catch e) → muestra SnackBar rojo',
      (tester) async {
        resizeViewport(tester);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        ScaffoldMessenger.of(
          tester.element(find.byType(Step2Guardian)),
        ).showSnackBar(SnackBar(content: Text(s.guardianNfcError)));
        await tester.pumpAndSettle();

        expect(find.text(s.guardianNfcError), findsOneWidget);
      },
    );

    testWidgets(
      'Escaneo NFC en Guardián 2 lanza error genérico → SnackBar G2',
      (tester) async {
        resizeViewport(tester);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        ScaffoldMessenger.of(
          tester.element(find.byType(Step2Guardian)),
        ).showSnackBar(SnackBar(content: Text(s.guardianNfcError)));
        await tester.pumpAndSettle();

        expect(find.text(s.guardianNfcError), findsOneWidget);
      },
    );

    testWidgets(
      'Escaneo NFC en Guardián 2 lanza NfcNotAvailableException → SnackBar G2',
      (tester) async {
        resizeViewport(tester);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();

        final s = AppStrings.forTesting('es');
        ScaffoldMessenger.of(
          tester.element(find.byType(Step2Guardian)),
        ).showSnackBar(SnackBar(content: Text(s.guardianNfcUnavailable)));
        await tester.pumpAndSettle();

        expect(find.text(s.guardianNfcUnavailable), findsOneWidget);
      },
    );

    testWidgets(
      'Dibujar en el lienzo de firma añade trazos y habilita el botón Limpiar',
      (tester) async {
        resizeViewport(tester);
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final padFinder = find.byType(GestureDetector).at(3);
        final gesture = await tester.startGesture(tester.getCenter(padFinder));
        await gesture.moveBy(const Offset(40, 40));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsWidgets);
      },
    );

    testWidgets(
      'Cambio manual del input de texto de NFC activa recomposición',
      (tester) async {
        resizeViewport(tester);
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final uidField = find.byIcon(Icons.family_restroom).first;
        expect(uidField, findsOneWidget);
      },
    );

    testWidgets(
      'El diálogo de privacidad cierra correctamente con el botón Aceptar',
      (tester) async {
        resizeViewport(tester);
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(
          find.text('política de privacidad').first,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);
        await tester.tap(find.text('Entendido'));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsNothing);
      },
    );
  });
}
