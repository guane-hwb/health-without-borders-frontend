// test/widget/step5_review_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/register_nfc_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step5_review.dart';

// ── Helper ──────────────────────────────────────────────────────────────────
RegisterDraft buildDraft({
  String firstName = 'Isabella',
  String firstLastName = 'Martínez',
  String? secondName,
  String? secondLastName,
  String biologicalSex = 'F',
  String? deviceUid = 'AA:BB:CC:DD',
  DateTime? dob,
  String? guardianName,
  String? guardianRelationship,
  String? guardianPhone,
  String? guardianDeviceUid,
  String? zone,
  List<AllergyInfo>? allergies,
  List<ChronicConditionItem>? chronicConditions,
  List<FamilyHistoryItem>? familyHistory,
  List<MedicationStatementItem>? medications,
}) {
  final d = RegisterDraft()
    ..firstName = firstName
    ..firstLastName = firstLastName
    ..secondName = secondName
    ..secondLastName = secondLastName
    ..biologicalSex = biologicalSex
    ..deviceUid = deviceUid
    ..dob = dob ?? DateTime(2015, 8, 22)
    ..guardianName = guardianName
    ..guardianRelationship = guardianRelationship
    ..guardianPhone = guardianPhone
    ..guardianDeviceUid = guardianDeviceUid
    ..zone = zone
    ..allergies = allergies ?? []
    ..chronicConditions = chronicConditions ?? []
    ..familyHistory = familyHistory ?? []
    ..medications = medications ?? [];
  return d;
}

Widget buildTestApp({
  required RegisterDraft draft,
  VoidCallback? onBack,
  Future<void> Function()? onConfirm,
  String locale = 'es',
}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(
      home: Scaffold(
        body: Step5Review(
          draft: draft,
          onBack: onBack ?? () {},
          onConfirm: onConfirm ?? () async {},
        ),
      ),
    ),
  );
}

void main() {
  void configureMobileScreenSize(WidgetTester tester) {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      412 * 3,
      892 * 3,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  }

  group('Renderizado básico', () {
    testWidgets('renderiza sin errores', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft()));
      await tester.pumpAndSettle();
      expect(find.byType(Step5Review), findsOneWidget);
    });

    testWidgets('muestra el título "Revisar datos"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft()));
      await tester.pumpAndSettle();
      expect(find.text('Revisar datos'), findsOneWidget);
    });

    testWidgets('muestra subtítulo de verificación', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft()));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Verifica la información antes de guardar'),
        findsOneWidget,
      );
    });

    testWidgets('muestra las 4 cards (NFC, Paciente, Guardián, Antecedentes)', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.nfc), findsWidgets);
      expect(find.byIcon(Icons.person_outline), findsWidgets);
      expect(find.byIcon(Icons.family_restroom), findsWidgets);

      final historyIcon = find.byIcon(Icons.history_edu_outlined);
      await tester.ensureVisible(historyIcon);
      expect(historyIcon, findsWidgets);
    });

    testWidgets('muestra el banner de sincronización', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft()));
      await tester.pumpAndSettle();

      final bannerIcon = find.byIcon(Icons.cloud_upload_outlined);
      await tester.ensureVisible(bannerIcon);
      expect(bannerIcon, findsOneWidget);
    });
  });
  group('Card NFC', () {
    testWidgets('muestra el UID del dispositivo', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(draft: buildDraft(deviceUid: 'AA:BB:CC:DD')),
      );
      await tester.pumpAndSettle();
      expect(find.text('AA:BB:CC:DD'), findsOneWidget);
    });

    testWidgets('muestra "—" cuando deviceUid es null', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft(deviceUid: null)));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsWidgets);
    });
  });
  group('Card Paciente', () {
    testWidgets('muestra el nombre completo', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(
            firstName: 'Isabella',
            secondName: 'María',
            firstLastName: 'Martínez',
            secondLastName: 'Silva',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Isabella María Martínez Silva'), findsOneWidget);
    });

    testWidgets('muestra la fecha de nacimiento formateada', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(draft: buildDraft(dob: DateTime(2015, 8, 22))),
      );
      await tester.pumpAndSettle();
      expect(find.text('2015-08-22'), findsOneWidget);
    });

    testWidgets('muestra "Femenino" para sexo F', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(draft: buildDraft(biologicalSex: 'F')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Femenino'), findsOneWidget);
    });

    testWidgets('muestra "Masculino" para sexo M', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(draft: buildDraft(biologicalSex: 'M')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Masculino'), findsOneWidget);
    });

    testWidgets('muestra zona "Urbana" cuando zone es null', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft(zone: null)));
      await tester.pumpAndSettle();
      expect(find.text('Urbana'), findsOneWidget);
    });

    testWidgets('muestra zona "Rural" cuando zone es "02"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft(zone: '02')));
      await tester.pumpAndSettle();
      expect(find.text('Rural'), findsOneWidget);
    });
  });

  group('Card Guardián — sin guardián', () {
    testWidgets('muestra "Sin guardián" cuando guardianName es null', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(draft: buildDraft(guardianName: null)),
      );
      await tester.pumpAndSettle();

      final noGuardianText = find.text('Sin guardián');
      await tester.ensureVisible(noGuardianText);
      expect(noGuardianText, findsOneWidget);
    });

    testWidgets('muestra "Sin guardián" cuando guardianName está vacío', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(draft: buildDraft(guardianName: '')),
      );
      await tester.pumpAndSettle();

      final noGuardianText = find.text('Sin guardián');
      await tester.ensureVisible(noGuardianText);
      expect(noGuardianText, findsOneWidget);
    });
  });

  group('Card Guardián — con guardián', () {
    testWidgets('muestra el nombre del guardián', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(
            guardianName: 'Roberto Martínez',
            guardianRelationship: '04',
            guardianPhone: '+573202223439',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final guardianNameText = find.text('Roberto Martínez');
      await tester.ensureVisible(guardianNameText);
      expect(guardianNameText, findsOneWidget);
    });

    testWidgets('muestra el parentesco "Abuelos" para código "04"', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(guardianName: 'Carmen', guardianRelationship: '04'),
        ),
      );
      await tester.pumpAndSettle();

      final relationshipText = find.text('Abuelos');
      await tester.ensureVisible(relationshipText);
      expect(relationshipText, findsOneWidget);
    });

    testWidgets('muestra el teléfono del guardián', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(
            guardianName: 'Carmen',
            guardianPhone: '+573001234567',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final phoneText = find.text('+573001234567');
      await tester.ensureVisible(phoneText);
      expect(phoneText, findsOneWidget);
    });

    testWidgets('muestra "No registrada" cuando guardianDeviceUid es null', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(guardianName: 'Carmen', guardianDeviceUid: null),
        ),
      );
      await tester.pumpAndSettle();

      final notRegisteredText = find.text('No registrada');
      await tester.ensureVisible(notRegisteredText);
      expect(notRegisteredText, findsOneWidget);
    });

    testWidgets('muestra el UID del guardián cuando está registrado', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(
            guardianName: 'Carmen',
            guardianDeviceUid: 'GG:HH:II:JJ',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final guardianUidText = find.text('GG:HH:II:JJ');
      await tester.ensureVisible(guardianUidText);
      expect(guardianUidText, findsOneWidget);
    });
  });

  group('Card Antecedentes — listas vacías', () {
    testWidgets('muestra "—" para crónicas vacías', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(draft: buildDraft(chronicConditions: [])),
      );
      await tester.pumpAndSettle();

      final emptyDash = find.text('—');
      await tester.ensureVisible(emptyDash.first);
      expect(emptyDash, findsWidgets);
    });
  });

  group('Card Antecedentes — con ítems', () {
    testWidgets('muestra "1 ítems" para 1 alergia', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(
            allergies: [AllergyInfo(category: '01', allergen: 'Penicilina')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final itemText = find.text('1 ítems');
      await tester.ensureVisible(itemText);
      expect(itemText, findsOneWidget);
    });

    testWidgets('muestra "2 ítems" para 2 condiciones crónicas', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(
            chronicConditions: [
              ChronicConditionItem(chronicDescription: 'Diabetes'),
              ChronicConditionItem(chronicDescription: 'HTA'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final itemsText = find.text('2 ítems');
      await tester.ensureVisible(itemsText);
      expect(itemsText, findsOneWidget);
    });

    testWidgets('muestra "3 ítems" para 3 medicamentos', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(
            medications: [
              MedicationStatementItem(medicationName: 'A'),
              MedicationStatementItem(medicationName: 'B'),
              MedicationStatementItem(medicationName: 'C'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final itemsText = find.text('3 ítems');
      await tester.ensureVisible(itemsText);
      expect(itemsText, findsOneWidget);
    });
  });

  group('Botones de acción', () {
    testWidgets('muestra botón Atrás', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft()));
      await tester.pumpAndSettle();
      expect(find.text('Atrás'), findsOneWidget);
    });

    testWidgets('muestra botón Confirmar', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft()));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar'), findsOneWidget);
    });

    testWidgets('botón Atrás invoca onBack', (tester) async {
      configureMobileScreenSize(tester);
      var tapped = false;
      await tester.pumpWidget(
        buildTestApp(draft: buildDraft(), onBack: () => tapped = true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atrás'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('botón Confirmar invoca onConfirm', (tester) async {
      configureMobileScreenSize(tester);
      var confirmed = false;
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(),
          onConfirm: () async => confirmed = true,
        ),
      );
      await tester.pumpAndSettle();

      final registerBtn = find.text('Confirmar');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(confirmed, isTrue);
    });

    testWidgets('ambos botones habilitados cuando no está guardando', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft()));
      await tester.pumpAndSettle();
      final back = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(back.onPressed, isNotNull);
    });
  });

  group('Estado de guardado', () {
    testWidgets('muestra CircularProgressIndicator mientras guarda', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(),
          onConfirm: () async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
        ),
      );
      await tester.pumpAndSettle();

      final registerBtn = find.text('Confirmar');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    });

    testWidgets('botón Registrar se deshabilita durante el guardado', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(),
          onConfirm: () async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
        ),
      );
      await tester.pumpAndSettle();

      final registerBtn = find.text('Confirmar');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);

      await tester.pump(const Duration(milliseconds: 100));

      final btn = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).last,
      );
      expect(btn.onPressed, isNull);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    });

    testWidgets('muestra "Guardando..." mientras guarda', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(),
          onConfirm: () async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
        ),
      );
      await tester.pumpAndSettle();

      final registerBtn = find.text('Confirmar');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Guardando...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    });

    testWidgets('muestra SnackBar si onConfirm lanza excepción', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(),
          onConfirm: () async => throw Exception('Error de prueba'),
        ),
      );
      await tester.pumpAndSettle();

      final registerBtn = find.text('Confirmar');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);

      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('Renderizado en inglés', () {
    testWidgets('muestra "Review data" en inglés', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft(), locale: 'en'));
      await tester.pumpAndSettle();
      expect(find.text('Review data'), findsOneWidget);
    });

    testWidgets('muestra "Confirm" en inglés', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(buildTestApp(draft: buildDraft(), locale: 'en'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('muestra "Female" para sexo F en inglés', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(biologicalSex: 'F'),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Female'), findsOneWidget);
    });

    testWidgets('muestra "No guardian" cuando no hay guardián en inglés', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(draft: buildDraft(guardianName: null), locale: 'en'),
      );
      await tester.pumpAndSettle();

      final noGuardianText = find.text('No guardian');
      await tester.ensureVisible(noGuardianText);
      expect(noGuardianText, findsOneWidget);
    });

    testWidgets('muestra "1 items" para 1 alergia en inglés', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        buildTestApp(
          draft: buildDraft(
            allergies: [AllergyInfo(category: '01', allergen: 'Penicillin')],
          ),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      final itemText = find.text('1 items');
      await tester.ensureVisible(itemText);
      expect(itemText, findsOneWidget);
    });
  });
}
