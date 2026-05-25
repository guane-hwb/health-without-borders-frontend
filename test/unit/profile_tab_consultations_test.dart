// test/src/features/nfc/presentation/profile/tabs/profile_tab_consultations_test.dart
//
// Covers:
// • Unit tests – pure logic: _formattedDate, _formattedTime, _modalityLabel, _DiagChip label
// • Widget tests – ProfileTabConsultations: empty state, list, "Add Query" button,
// descending order, detail navigation, _ConsultationDetailScreen
//
// Test dependencies required in pubspec.yaml:
// dev_dependencies:
// flutter_test:
// sdk: flutter
// mocktail: ^1.0.4        # optional, only if repos are injected; not needed here

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_consultations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers / factories
// ─────────────────────────────────────────────────────────────────────────────

/// Wrap the widget under test in MaterialApp so that Navigator and Theme are available.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Create a valid minimum [MedicalHistoryItem].
MedicalHistoryItem _makeItem({
  String startDateTime = '2026-05-20T10:30:00',
  String? endDateTime,
  String careModality = '01',
  String serviceGroup = '01',
  String careEnvironment = '01',
  String? historyOfCurrentIllness,
  String? treatmentPlanObservations,
  List<DiagnosisItem> diagnosis = const [],
  String diagnosisType = '01',
  PractitionerInfo? practitioner,
  ProviderInfo? provider,
}) =>
    MedicalHistoryItem(
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      careModality: careModality,
      serviceGroup: serviceGroup,
      careEnvironment: careEnvironment,
      clinicalEvaluation: ClinicalEvaluation(
        historyOfCurrentIllness: historyOfCurrentIllness,
        treatmentPlanObservations: treatmentPlanObservations,
        generalPhysicalExamination: null,
        systemsExamination: null,
      ),
      diagnosis: diagnosis,
      diagnosisType: diagnosisType,
      practitioner: practitioner,
      provider: provider,
      riskFactors: const [],
      incapacity: null,
      payer: null,
      entryRoute: null,
      externalCause: null,
      dischargeDisposition: null,
    );

/// Create a [PatientFullRecord] with the given query list.
PatientFullRecord _makeRecord(List<MedicalHistoryItem> history) =>
    PatientFullRecord(
      patientId: 'test-id',
      deviceUid: 'device-123',
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: 'CC',
          documentNumber: '123456',
        ),
        firstLastName: 'Test',
        firstName: 'Paciente',
        dob: '1990-01-01',
        biologicalSex: 'M',
        address: Address(city: 'Bogotá', state: 'Cundinamarca'),
      ),
      guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
      medicalHistory: history,
    );

// ─────────────────────────────────────────────────────────────────────────────
// 1. UNIT TESTS – formatting logic (accessed via widget in "black-box" mode
// because the getters are private; the rendered text is verified)
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Group: Date formatting ──────────────────────────────────────────────
  group('_ConsultationCard · _formattedDate', () {
    testWidgets('muestra día de semana, día, mes y año en español',
        (tester) async {
      final item = _makeItem(startDateTime: '2026-05-20T10:30:00');
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));

      expect(find.textContaining('mié'), findsOneWidget);
      expect(find.textContaining('20'), findsOneWidget);
      expect(find.textContaining('may'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
    });

    testWidgets('no lanza excepción con fecha inválida y muestra el raw string',
        (tester) async {
      final item = _makeItem(startDateTime: 'not-a-date');
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));

      expect(find.textContaining('not-a-date'), findsOneWidget);
    });
  });

  // ── Group: Time formatting ───────────────────────────────────────────────
  group('_ConsultationCard · _formattedTime', () {
    testWidgets('formatea hora a.m. correctamente', (tester) async {
      final item = _makeItem(startDateTime: '2026-05-20T09:05:00');
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));
      expect(find.textContaining('9:05 a.m.'), findsOneWidget);
    });

    testWidgets('formatea hora p.m. correctamente', (tester) async {
      final item = _makeItem(startDateTime: '2026-05-20T14:00:00');
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));
      expect(find.textContaining('2:00 p.m.'), findsOneWidget);
    });

    testWidgets('medianoche (00:xx) se muestra como 12:xx a.m.', (tester) async {
      final item = _makeItem(startDateTime: '2026-05-20T00:45:00');
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));
      expect(find.textContaining('12:45 a.m.'), findsOneWidget);
    });
  });

  // ── Group: modality label ──────────────────────────────────────────
  group('_ConsultationCard · _modalityLabel', () {
    const cases = {
      '01': 'Intramural',
      '02': 'Extramural',
      '06': 'Telemedicina',
      '09': 'Telemonitoreo',
    };

    for (final entry in cases.entries) {
      testWidgets('código ${entry.key} → "${entry.value}"', (tester) async {
        final item = _makeItem(careModality: entry.key);
        await tester.pumpWidget(_wrap(ProfileTabConsultations(
          draft: _makeRecord([item]),
          canAdd: false,
          onAdd: () {},
        )));
        expect(find.textContaining(entry.value), findsOneWidget);
      });
    }

    testWidgets('código desconocido muestra el código en bruto', (tester) async {
      final item = _makeItem(careModality: 'ZZ');
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));
      expect(find.textContaining('ZZ'), findsOneWidget);
    });
  });

  // ── Group: _DiagChip – truncated from label ─────────────────────────────────
  group('_DiagChip · label truncation', () {
    testWidgets('label ≤ 36 chars se muestra completo', (tester) async {
      final item = _makeItem(
        diagnosis: [
          DiagnosisItem(icd10Code: 'A00', description: 'Cólera'),
        ],
      );
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));
      expect(find.textContaining('A00 Cólera'), findsOneWidget);
    });

    testWidgets('label > 36 chars se trunca con "..."', (tester) async {
      final item = _makeItem(
        diagnosis: [
          DiagnosisItem(
            icd10Code: 'Z99',
            description: 'Descripción muy larga que supera el límite visible',
          ),
        ],
      );
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));
      expect(find.textContaining('...'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. WIDGET TESTS – ProfileTabConsultations
  // ─────────────────────────────────────────────────────────────────────────

  group('ProfileTabConsultations · empty state', () {
    testWidgets('muestra "Sin consultas registradas." cuando no hay items',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([]),
        canAdd: false,
        onAdd: () {},
      )));
      expect(find.text('Sin consultas registradas.'), findsOneWidget);
      expect(find.textContaining('CONSULTAS · 0'), findsOneWidget);
    });

    testWidgets('no muestra botón "Agregar consulta" cuando canAdd=false',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([]),
        canAdd: false,
        onAdd: () {},
      )));
      expect(find.text('Agregar consulta'), findsNothing);
    });
  });

  group('ProfileTabConsultations · lista con items', () {
    testWidgets('muestra una tarjeta por consulta', (tester) async {
      final items = [
        _makeItem(startDateTime: '2026-05-01T08:00:00'),
        _makeItem(startDateTime: '2026-04-15T14:00:00'),
        _makeItem(startDateTime: '2026-03-10T10:00:00'),
      ];
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord(items),
        canAdd: false,
        onAdd: () {},
      )));
      expect(find.textContaining('CONSULTAS · 3'), findsOneWidget);
    });

    testWidgets('ordena las consultas de más reciente a más antigua',
        (tester) async {
      final items = [
        _makeItem(startDateTime: '2026-01-01T00:00:00'),
        _makeItem(startDateTime: '2026-05-20T00:00:00'),
        _makeItem(startDateTime: '2026-03-15T00:00:00'),
      ];
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord(items),
        canAdd: false,
        onAdd: () {},
      )));

      // We collect the rendered date texts in DOM order
      final fechas = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where((s) =>
              s.contains('2026') &&
              (s.contains('ene') || s.contains('may') || s.contains('mar')))
          .toList();

      // The first one must contain "may" (May = most recent)
      expect(fechas.first, contains('may'));
    });

    testWidgets('muestra el resumen de la consulta cuando existe', (tester) async {
      final item =
          _makeItem(historyOfCurrentIllness: 'Paciente refiere dolor de cabeza');
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));
      expect(
          find.textContaining('Paciente refiere dolor de cabeza'), findsOneWidget);
    });

    testWidgets('muestra treatmentPlanObservations si no hay historyOfCurrentIllness',
        (tester) async {
      final item = _makeItem(
        historyOfCurrentIllness: null,
        treatmentPlanObservations: 'Reposo y analgésicos',
      );
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));
      expect(find.textContaining('Reposo y analgésicos'), findsOneWidget);
    });

    testWidgets('muestra el nombre del profesional cuando está presente',
        (tester) async {
      final item = _makeItem(
        practitioner: PractitionerInfo(
          name: 'Dr. García',
          documentType: 'CC',
          documentNumber: '987654',
        ),
      );
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));
      expect(find.textContaining('Dr. García'), findsOneWidget);
    });
  });

  // ── Group: Add consultation button ─────────────────────────────────────────
  group('ProfileTabConsultations · botón "Agregar consulta"', () {
    testWidgets('se muestra cuando canAdd=true', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([]),
        canAdd: true,
        onAdd: () {},
      )));
      expect(find.text('Agregar consulta'), findsOneWidget);
    });

    testWidgets('llama onAdd al presionar el botón', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([]),
        canAdd: true,
        onAdd: () => called = true,
      )));
      await tester.tap(find.text('Agregar consulta'));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('onAdd NO se llama si canAdd=false', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([]),
        canAdd: false,
        onAdd: () => called = true,
      )));
      // The button does not exist; we verified that it did not throw an exception and was not called.
      expect(find.text('Agregar consulta'), findsNothing);
      expect(called, isFalse);
    });
  });

  // ── Group: detailed navigation ──────────────────────────────────────────
  group('ProfileTabConsultations · navegación a detalle', () {
    testWidgets(
        'tap en una tarjeta navega a _ConsultationDetailScreen con el título correcto',
        (tester) async {
      final item = _makeItem(startDateTime: '2026-05-20T10:30:00');
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));

      await tester.tap(find.textContaining('Ver detalle').first);
      await tester.pumpAndSettle();

      expect(find.text('Detalle de consulta'), findsOneWidget);
    });

    testWidgets(
        '_ConsultationDetailScreen muestra la sección "Contexto de atención"',
        (tester) async {
      final item = _makeItem(
        startDateTime: '2026-05-20T10:30:00',
        careModality: '06',
        serviceGroup: '01',
        careEnvironment: '02',
      );
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));

      await tester.tap(find.textContaining('Ver detalle').first);
      await tester.pumpAndSettle();

      expect(find.text('Contexto de atención'), findsOneWidget);
      expect(find.textContaining('Telemedicina interactiva'), findsOneWidget);
      expect(find.textContaining('Consulta externa'), findsOneWidget);
      expect(find.textContaining('Comunitario'), findsOneWidget);
    });

    testWidgets(
        '_ConsultationDetailScreen muestra diagnósticos cuando los hay',
        (tester) async {
      final item = _makeItem(
        diagnosis: [
          DiagnosisItem(icd10Code: 'J00', description: 'Rinofaringitis aguda'),
        ],
        diagnosisType: '02',
      );
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));

      await tester.tap(find.textContaining('Ver detalle').first);
      await tester.pumpAndSettle();

      expect(find.text('Diagnósticos'), findsOneWidget);
      expect(find.textContaining('J00'), findsOneWidget);
      expect(find.textContaining('Rinofaringitis aguda'), findsOneWidget);
      expect(find.textContaining('Confirmado nuevo'), findsOneWidget);
    });

    testWidgets(
        '_ConsultationDetailScreen muestra sección Prestador cuando existe provider',
        (tester) async {
      final item = _makeItem(
        provider: ProviderInfo(name: 'Hospital Central', repsCode: 'REP001'),
      );
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));

      await tester.tap(find.textContaining('Ver detalle').first);
      await tester.pumpAndSettle();

      expect(find.text('Prestador'), findsOneWidget);
      expect(find.textContaining('Hospital Central'), findsOneWidget);
      expect(find.textContaining('REP001'), findsOneWidget);
    });

    testWidgets('botón back de AppBar regresa a la pantalla anterior',
        (tester) async {
      final item = _makeItem();
      await tester.pumpWidget(_wrap(ProfileTabConsultations(
        draft: _makeRecord([item]),
        canAdd: false,
        onAdd: () {},
      )));

      await tester.tap(find.textContaining('Ver detalle').first);
      await tester.pumpAndSettle();

      expect(find.text('Detalle de consulta'), findsOneWidget);

      // Navigate back
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      // Return to the queries tab
      expect(find.textContaining('CONSULTAS ·'), findsOneWidget);
    });
  });
}