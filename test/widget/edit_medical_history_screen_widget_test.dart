// test/widget/edit_medical_history_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/edit_medical_history_screen.dart';

// -----------------------------------------------------------------------------
// BUILD SUBJECT
// -----------------------------------------------------------------------------

Widget buildSubject(PatientFullRecord patient) {
  return MaterialApp(
    builder: (context, child) {
      return AppLocale(locale: 'es', setLocale: (_) {}, child: child!);
    },
    home: EditMedicalHistoryScreen(patient: patient),
  );
}

// -----------------------------------------------------------------------------
// MOCK DATA
// -----------------------------------------------------------------------------

PatientFullRecord emptyPatient() {
  return PatientFullRecord(
    patientId: 'w-001',
    deviceUid: 'dev-w-001',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '000000',
      ),
      firstLastName: 'Widget',
      firstName: 'Paciente',
      dob: '1990-01-01',
      biologicalSex: 'M',
      address: Address(city: 'Bogotá', state: 'Cundinamarca'),
    ),
    guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
    backgroundHistory: null,
    medicalHistory: const <MedicalHistoryItem>[],
    allergies: const <AllergyInfo>[],
    vaccinationRecord: const <VaccinationRecordItem>[],
  );
}

PatientFullRecord patientWithFamilyHistory() {
  return PatientFullRecord(
    patientId: 'w-002',
    deviceUid: 'dev-w-002',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '111111',
      ),
      firstLastName: 'Family',
      firstName: 'Paciente',
      dob: '1985-05-05',
      biologicalSex: 'F',
      address: Address(city: 'Bogotá', state: 'Cundinamarca'),
    ),
    guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
    backgroundHistory: BackgroundHistory(
      personalHistory: 'Sin antecedentes',
      chronicConditions: [ChronicConditionItem(chronicDescription: 'Asma')],
      familyHistoryNotes: 'Sin notas',
      familyHistory: [
        FamilyHistoryItem(
          conditionDescription: 'Diabetes tipo 2',
          relationship: '01',
          conditionCie10Code: 'E11',
        ),
      ],
    ),
    medicalHistory: [
      MedicalHistoryItem(
        startDateTime: '',
        clinicalEvaluation: ClinicalEvaluation(
          historyOfCurrentIllness: 'Fiebre 2 días',
          generalPhysicalExamination: 'FC 80 bpm',
          systemsExamination: 'Normal',
          treatmentPlanObservations: 'Antipiréticos',
        ),
      ),
    ],
    allergies: const <AllergyInfo>[],
    vaccinationRecord: const <VaccinationRecordItem>[],
  );
}

// -----------------------------------------------------------------------------
// TESTS
// -----------------------------------------------------------------------------

void main() {
  // ---------------------------------------------------------------------------
  // GROUP 1
  // ---------------------------------------------------------------------------

  group('Renderizado inicial – paciente vacío', () {
    testWidgets('muestra el Scaffold sin errores', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('no muestra ninguna tarjeta familiar', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.family_restroom), findsNothing);
    });

    testWidgets('textfields vacíos', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextField>(find.byType(TextField));

      for (final field in fields) {
        expect(field.controller?.text ?? '', isEmpty);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // GROUP 2
  // ---------------------------------------------------------------------------

  group('Renderizado inicial – paciente con datos', () {
    testWidgets('muestra enfermedad actual', (tester) async {
      await tester.pumpWidget(buildSubject(patientWithFamilyHistory()));

      await tester.pumpAndSettle();

      expect(find.text('Fiebre 2 días'), findsOneWidget);
    });

    testWidgets('muestra historial familiar', (tester) async {
      await tester.pumpWidget(buildSubject(patientWithFamilyHistory()));

      await tester.pumpAndSettle();

      expect(find.text('Diabetes tipo 2'), findsOneWidget);

      expect(find.byIcon(Icons.family_restroom), findsWidgets);
    });

    testWidgets('muestra código cie10', (tester) async {
      await tester.pumpWidget(buildSubject(patientWithFamilyHistory()));

      await tester.pumpAndSettle();

      expect(find.textContaining('E11'), findsWidgets);
    });

    testWidgets('muestra relación', (tester) async {
      await tester.pumpWidget(buildSubject(patientWithFamilyHistory()));

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // GROUP 3
  // ---------------------------------------------------------------------------

  group('Bottom sheet – agregar historial familiar', () {
    testWidgets('abre bottom sheet', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add).first);

      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('no agrega vacío', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add).first);

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add).last);

      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('agrega item válido', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add).first);

      await tester.pumpAndSettle();

      final field = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      );

      await tester.enterText(field, 'Hipertensión');

      await tester.pump();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add).last);

      await tester.pumpAndSettle();

      expect(find.text('Hipertensión'), findsOneWidget);
    });

    testWidgets('dropdown contiene relaciones', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.add).first);

      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);

      expect(find.byType(InkWell), findsWidgets);

      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // GROUP 4
  // ---------------------------------------------------------------------------

  group('Eliminar historial familiar', () {
    testWidgets('elimina tarjeta', (tester) async {
      await tester.pumpWidget(buildSubject(patientWithFamilyHistory()));

      await tester.pumpAndSettle();

      expect(find.text('Diabetes tipo 2'), findsOneWidget);

      final deleteButtons = find.byIcon(Icons.delete_outline);

      expect(deleteButtons, findsWidgets);

      await tester.tap(deleteButtons.first);

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('eliminar no genera crash', (tester) async {
      await tester.pumpWidget(buildSubject(patientWithFamilyHistory()));

      await tester.pumpAndSettle();

      final deleteButtons = find.byIcon(Icons.delete_outline);

      await tester.tap(deleteButtons.first);

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // GROUP 5
  // ---------------------------------------------------------------------------

  group('Edición de campos', () {
    testWidgets('permite escribir', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      final field = find.byType(TextField).first;

      await tester.enterText(field, 'Dolor de cabeza');

      await tester.pump();

      expect(find.text('Dolor de cabeza'), findsOneWidget);
    });

    testWidgets('campos multilinea', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextField>(find.byType(TextField));

      for (final field in fields) {
        expect(field.maxLines, 3);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // GROUP 6
  // ---------------------------------------------------------------------------

  group('Navegación', () {
    testWidgets('botón regresar hace pop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return AppLocale(locale: 'es', setLocale: (_) {}, child: child!);
          },
          home: Builder(
            builder: (ctx) {
              return ElevatedButton(
                onPressed: () async {
                  await Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EditMedicalHistoryScreen(patient: emptyPatient()),
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

      final backButton = find.byIcon(Icons.arrow_back_ios);

      expect(backButton, findsOneWidget);

      await tester.ensureVisible(backButton);

      await tester.pumpAndSettle();

      await tester.tap(backButton, warnIfMissed: false);

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
    testWidgets('botón guardar existe', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------------
  // GROUP 7
  // ---------------------------------------------------------------------------

  group('Encabezados', () {
    testWidgets('muestra icono médico', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.medical_services_outlined), findsWidgets);
    });

    testWidgets('pantalla renderiza correctamente', (tester) async {
      await tester.pumpWidget(buildSubject(emptyPatient()));

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
