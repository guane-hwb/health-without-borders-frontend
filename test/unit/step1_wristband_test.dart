// test/unit/step1_wristband_test.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step1_wristband.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/register_nfc_screen.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_service.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';

typedef ReadUidFn = Future<String> Function();

class MockReadUid extends Mock {
  Future<String> call();
}

class _FakeAppStrings extends Fake implements AppStrings {
  @override
  String get nfcNotAvailable => 'NFC no disponible';
  @override
  String get nfcUidRequired => 'UID requerido';
  @override
  String get patientNfcDevice => 'Dispositivo NFC del paciente';
  @override
  String get patientNfcDeviceSub => 'Subtítulo NFC';
  @override
  String get manualUidHint => 'Ingreso manual';
  @override
  String get manualPatientUidHint => 'Ej. A1:B2:C3';
  @override
  String get continueBtn => 'Continuar';
}

class _FakeAppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _FakeAppStringsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppStrings> load(Locale locale) async => _FakeAppStrings();

  @override
  bool shouldReload(_) => false;
}

class _FakeMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FakeMaterialLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      DefaultMaterialLocalizations();
  @override
  bool shouldReload(_) => false;
}

class _FakeWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _FakeWidgetsLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<WidgetsLocalizations> load(Locale locale) async =>
      DefaultWidgetsLocalizations();
  @override
  bool shouldReload(_) => false;
}

class _FakeCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FakeCupertinoLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<CupertinoLocalizations> load(Locale locale) async =>
      DefaultCupertinoLocalizations();
  @override
  bool shouldReload(_) => false;
}

Widget _buildSubject({
  required RegisterDraft draft,
  required VoidCallback onContinue,
  ReadUidFn? readUid,
}) {
  return AppLocale(
    locale: 'es',
    setLocale: (_) {},
    child: MaterialApp(
      localizationsDelegates: const [
        _FakeAppStringsDelegate(),
        _FakeMaterialLocalizationsDelegate(),
        _FakeWidgetsLocalizationsDelegate(),
        _FakeCupertinoLocalizationsDelegate(),
      ],
      supportedLocales: const [Locale('es')],
      locale: const Locale('es'),
      home: Scaffold(
        body: Step1Wristband(
          draft: draft,
          onContinue: onContinue,
          readUid: readUid,
        ),
      ),
    ),
  );
}

RegisterDraft _emptyDraft() => RegisterDraft();

void main() {
  group('Step1Wristband – Initial UI Layout Rendering', () {
    testWidgets(
      'Displays baseline NFC vector icons instead of active progress indicators initially',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(draft: _emptyDraft(), onContinue: () {}),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.nfc), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'TextField populates matching baseline values from non-empty draft data states',
      (tester) async {
        final draft = _emptyDraft()..deviceUid = 'AA:BB:CC:DD';

        await tester.pumpWidget(_buildSubject(draft: draft, onContinue: () {}));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextField, 'AA:BB:CC:DD'), findsOneWidget);
      },
    );

    testWidgets(
      'TextField controllers initialize to completely empty text values when drafts lack data',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(draft: _emptyDraft(), onContinue: () {}),
        );
        await tester.pumpAndSettle();

        final tf = tester.widget<TextField>(find.byType(TextField));
        expect(tf.controller!.text, '');
      },
    );

    testWidgets(
      'Omits error indicator elements completely on startup configurations',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(draft: _emptyDraft(), onContinue: () {}),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsNothing);
      },
    );

    testWidgets(
      'Commit navigation button renders securely within current layout tree',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(draft: _emptyDraft(), onContinue: () {}),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsOneWidget);
      },
    );
  });

  group('Step1Wristband – NFC Scan Pipeline Actions', () {
    testWidgets(
      'Displays an active CircularProgressIndicator during hardware polling loops',
      (tester) async {
        final completer = Completer<String>();
        final draft = _emptyDraft();

        await tester.pumpWidget(
          _buildSubject(
            draft: draft,
            onContinue: () {},
            readUid: () => completer.future,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.nfc), findsNothing);

        completer.complete('FF:EE:DD:CC');
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Updates active TextField contents and matching model state metadata synchronously',
      (tester) async {
        final draft = _emptyDraft();

        await tester.pumpWidget(
          _buildSubject(
            draft: draft,
            onContinue: () {},
            readUid: () async => '11:22:33:44',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(draft.deviceUid, '11:22:33:44');
        final tf = tester.widget<TextField>(find.byType(TextField));
        expect(tf.controller!.text, '11:22:33:44');
      },
    );

    testWidgets(
      'Dismisses progressive spinner overlays and restores baseline icon tokens on completion',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            draft: _emptyDraft(),
            onContinue: () {},
            readUid: () async => 'AB:CD',
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byIcon(Icons.nfc), findsOneWidget);
      },
    );

    testWidgets(
      'GestureDetector.onTap evaluates to null during execution blocks to prevent consecutive click hazards',
      (tester) async {
        final completer = Completer<String>();

        await tester.pumpWidget(
          _buildSubject(
            draft: _emptyDraft(),
            onContinue: () {},
            readUid: () => completer.future,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        final gd = tester.widget<GestureDetector>(
          find.byType(GestureDetector).first,
        );
        expect(gd.onTap, isNull);

        completer.complete('X');
        await tester.pumpAndSettle();
      },
    );
  });

  group('Step1Wristband – Hardware Polling Error Boundaries Handlers', () {
    testWidgets(
      'Catches NfcNotAvailableException and maps context alerts successfully',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            draft: _emptyDraft(),
            onContinue: () {},
            readUid: () async => throw NfcNotAvailableException(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(find.textContaining('NFC no disponible'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      },
    );

    testWidgets(
      'Catches NfcSessionException and maps explicit target message tokens directly',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            draft: _emptyDraft(),
            onContinue: () {},
            readUid: () async =>
                throw NfcSessionException('Sesión NFC cancelada'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(find.textContaining('Sesión NFC cancelada'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      },
    );

    testWidgets(
      'Reverts structural scanning parameters into inactive layouts and restores standard icons after crashes',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            draft: _emptyDraft(),
            onContinue: () {},
            readUid: () async => throw NfcNotAvailableException(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byIcon(Icons.nfc), findsOneWidget);
      },
    );

    testWidgets(
      'Applies critical AppColors.error palettes styling to outstanding text alert widgets',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            draft: _emptyDraft(),
            onContinue: () {},
            readUid: () async => throw NfcNotAvailableException(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        final errorText = tester.widget<Text>(
          find.textContaining('NFC no disponible'),
        );
        expect(errorText.style?.color, AppColors.error);
      },
    );
  });

  group('Step1Wristband – Commit Form Gatekeeping Procedures', () {
    testWidgets(
      'Invokes target onContinue callbacks and bundles draft metadata parameters when inputs match format patterns',
      (tester) async {
        var called = false;
        final draft = _emptyDraft();

        await tester.pumpWidget(
          _buildSubject(draft: draft, onContinue: () => called = true),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'AB:CD:EF:01');

        final continueBtnFinder = find.byType(ElevatedButton);
        await tester.tap(continueBtnFinder);
        await tester.pumpAndSettle();

        expect(called, isTrue);
        expect(draft.deviceUid, 'AB:CD:EF:01');
      },
    );
  });

  group('Step1Wristband – TextField Entry Changes Pipeline Tracking', () {
    testWidgets(
      'Applies trim adjustments to typed string modifications before storing updates inside models',
      (tester) async {
        final draft = _emptyDraft();

        await tester.pumpWidget(_buildSubject(draft: draft, onContinue: () {}));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), ' CC:DD ');
        await tester.pump();

        expect(draft.deviceUid, 'CC:DD');
      },
    );
  });

  group('Step1Wristband – Widget Context Destruct Lifecycle Routines', () {
    testWidgets(
      'Tears down instance memory trees completely without throwing outstanding backdrop system anomalies',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(draft: _emptyDraft(), onContinue: () {}),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });

  group('Step1Wristband – Typography Formatting Rules Matrix Checks', () {
    testWidgets(
      'Main title text asserts to fontSize=19 properties accompanied by precise w700 font weight metrics',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(draft: _emptyDraft(), onContinue: () {}),
        );
        await tester.pumpAndSettle();

        final title = tester.widget<Text>(
          find.text('Dispositivo NFC del paciente'),
        );
        expect(title.style?.fontSize, 19.0);
        expect(title.style?.fontWeight, FontWeight.w700);
        expect(title.style?.color, AppColors.textPrimary);
      },
    );

    testWidgets(
      'Configures prefix input iconography exactly to Icons.keyboard_outlined tokens',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(draft: _emptyDraft(), onContinue: () {}),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.keyboard_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'Appends an exploratory trailing descriptive vector icon inside navigation buttons',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(draft: _emptyDraft(), onContinue: () {}),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      },
    );

    testWidgets(
      'Renders exactly three consecutive circular ripple bounding layout wrappers on the view layer',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(draft: _emptyDraft(), onContinue: () {}),
        );
        await tester.pumpAndSettle();

        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where(
              (c) =>
                  c.decoration is BoxDecoration &&
                  (c.decoration as BoxDecoration).shape == BoxShape.circle,
            )
            .toList();

        expect(containers.length, 3);
      },
    );
  });
}
