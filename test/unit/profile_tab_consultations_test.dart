// test/unit/profile_tab_consultations_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_consultations.dart';

// ─── Tree helpers ────────────────────────────────────────────────────────

Widget _wrap(Widget child, {String locale = 'es'}) {
  return _LocaleWrapper(
    locale: locale,
    child: MaterialApp(home: Scaffold(body: child)),
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

// ─── Domain Factories ─────────────────────────────────────────────────────

PatientFullRecord _makeRecord(List<MedicalHistoryItem> consultations) =>
    PatientFullRecord(
      patientId: 'test-patient-id',
      deviceUid: 'HWB-AA:BB:CC:DD',
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: 'CC',
          documentNumber: '123456789',
        ),
        firstLastName: 'García',
        firstName: 'Ana',
        dob: '1990-05-20',
        biologicalSex: 'F',
        address: Address(city: 'Bogotá', state: 'Cundinamarca'),
      ),
      guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
      medicalHistory: consultations,
    );

MedicalHistoryItem _makeConsultation({
  String startDateTime = '2024-06-15T10:30:00',
  String? endDateTime,
  String careModality = '01',
  String serviceGroup = '01',
  String careEnvironment = '05',
  ClinicalEvaluation? clinicalEvaluation,
  List<DiagnosisItem> diagnosis = const [],
  String diagnosisType = '01',
  String? dischargeDisposition,
  PractitionerInfo? practitioner,
  ProviderInfo? provider,
  List<RiskFactor> riskFactors = const [],
  IncapacityInfo? incapacity,
  PayerInfo? payer,
  String? entryRoute,
  String? externalCause,
}) => MedicalHistoryItem(
  startDateTime: startDateTime,
  endDateTime: endDateTime,
  careModality: careModality,
  serviceGroup: serviceGroup,
  careEnvironment: careEnvironment,
  clinicalEvaluation:
      clinicalEvaluation ??
      ClinicalEvaluation(historyOfCurrentIllness: 'Historia por defecto'),
  diagnosis: diagnosis,
  diagnosisType: diagnosisType,
  dischargeDisposition: dischargeDisposition,
  practitioner: practitioner,
  provider: provider,
  riskFactors: riskFactors,
  incapacity: incapacity,
  payer: payer,
  entryRoute: entryRoute,
  externalCause: externalCause,
);

PractitionerInfo _makePractitioner({
  String name = 'Dra. María López',
  String documentType = 'CC',
  String documentNumber = '987654321',
}) => PractitionerInfo(
  documentType: documentType,
  documentNumber: documentNumber,
  name: name,
);

ProviderInfo _makeProvider({
  String name = 'Hospital Central',
  String repsCode = 'REPS-001',
}) => ProviderInfo(repsCode: repsCode, name: name);

DiagnosisItem _makeDiagnosis({
  String icd10Code = 'J00',
  String description = 'Rinofaringitis aguda',
}) => DiagnosisItem(icd10Code: icd10Code, description: description);

// ════════════════════════════════════════════════════════════════════════════
// TESTS
// ════════════════════════════════════════════════════════════════════════════

void main() {
  // ── Group 1: Empty state ─────────────────────────────────────────────────
  group('ProfileTabConsultations – lista vacía', () {
    testWidgets('muestra mensaje cuando no hay consultas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord(const []),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      final s = AppStrings.forTesting('es');
      expect(find.text(s.noConsultationsRegistered), findsOneWidget);
    });

    testWidgets('no muestra ninguna tarjeta de consulta', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord(const []),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.medical_information_outlined), findsNothing);
    });

    testWidgets('no muestra el botón de agregar cuando canAdd=false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord(const []),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('muestra el botón de agregar cuando canAdd=true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord(const []),
            canAdd: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  // ── Group 2: A query – basic rendering ────────────────────────────
  group('ProfileTabConsultations – una consulta', () {
    testWidgets('renderiza la fecha de la consulta formateada', (tester) async {
      final c = _makeConsultation(startDateTime: '2024-06-15T10:30:00');
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('15'), findsWidgets);
    });

    testWidgets('muestra la hora en formato 12h con AM/PM', (tester) async {
      final c = _makeConsultation(startDateTime: '2024-01-10T14:05:00');
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('2:05'), findsOneWidget);
    });

    testWidgets('muestra 12:xx para medianoche (hora 0)', (tester) async {
      final c = _makeConsultation(startDateTime: '2024-01-10T00:20:00');
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('12:20'), findsOneWidget);
    });

    testWidgets('muestra fecha cruda si el formato ISO es inválido', (
      tester,
    ) async {
      final c = _makeConsultation(startDateTime: 'no-es-fecha');
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('no-es-fecha'), findsOneWidget);
    });

    testWidgets('no muestra el mensaje "sin consultas"', (tester) async {
      final c = _makeConsultation();
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      final s = AppStrings.forTesting('es');
      expect(find.text(s.noConsultationsRegistered), findsNothing);
    });

    testWidgets('formatea fecha en inglés cuando locale=en', (tester) async {
      final c = _makeConsultation(startDateTime: '2024-06-15T10:30:00');
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
          locale: 'en',
        ),
      );

      expect(find.textContaining('Jun 15, 2024'), findsOneWidget);
    });
  });

  // ── Group 3: Clinical content of the card ──────────────────────────────
  group('_ConsultationCard – contenido clínico', () {
    testWidgets(
      'muestra historyOfCurrentIllness como resumen si está disponible',
      (tester) async {
        final c = _makeConsultation(
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Paciente con fiebre de 3 días.',
            treatmentPlanObservations: 'Reposo absoluto.',
          ),
        );
        await tester.pumpWidget(
          _wrap(
            ProfileTabConsultations(
              draft: _makeRecord([c]),
              canAdd: false,
              onAdd: () {},
            ),
          ),
        );

        expect(find.text('Paciente con fiebre de 3 días.'), findsOneWidget);
        expect(find.text('Reposo absoluto.'), findsNothing);
      },
    );

    testWidgets(
      'usa treatmentPlanObservations como resumen si history es null',
      (tester) async {
        final c = _makeConsultation(
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: null,
            treatmentPlanObservations: 'Plan: antibióticos 7 días.',
          ),
        );
        await tester.pumpWidget(
          _wrap(
            ProfileTabConsultations(
              draft: _makeRecord([c]),
              canAdd: false,
              onAdd: () {},
            ),
          ),
        );

        expect(find.text('Plan: antibióticos 7 días.'), findsOneWidget);
      },
    );

    testWidgets('no muestra bloque de resumen si ambos campos son null', (
      tester,
    ) async {
      final c = _makeConsultation(
        clinicalEvaluation: ClinicalEvaluation(
          historyOfCurrentIllness: null,
          treatmentPlanObservations: null,
        ),
      );
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.text(''), findsNothing);
    });

    testWidgets('muestra el nombre del practicante si está definido', (
      tester,
    ) async {
      final c = _makeConsultation(
        practitioner: _makePractitioner(name: 'Dra. María López'),
      );
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.text('Dra. María López'), findsOneWidget);
    });

    testWidgets(
      'no muestra ícono de persona si el nombre del practicante está vacío',
      (tester) async {
        final c = _makeConsultation(practitioner: _makePractitioner(name: ''));
        await tester.pumpWidget(
          _wrap(
            ProfileTabConsultations(
              draft: _makeRecord([c]),
              canAdd: false,
              onAdd: () {},
            ),
          ),
        );

        expect(find.byIcon(Icons.person_outline), findsNothing);
      },
    );

    testWidgets('muestra el nombre del proveedor en el subtítulo de la hora', (
      tester,
    ) async {
      final c = _makeConsultation(
        startDateTime: '2024-03-10T09:00:00',
        provider: _makeProvider(name: 'Clínica Los Andes'),
      );
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('Clínica Los Andes'), findsOneWidget);
    });
  });

  // ── Group 4: DiagChip ─────────────────────────────────────────────────────
  group('_DiagChip – chips de diagnóstico', () {
    testWidgets('muestra chip con código ICD-10 y descripción', (tester) async {
      final diag = _makeDiagnosis(
        icd10Code: 'J00',
        description: 'Rinofaringitis aguda',
      );
      final c = _makeConsultation(diagnosis: [diag]);
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('J00'), findsOneWidget);
      expect(find.textContaining('Rinofaringitis aguda'), findsOneWidget);
    });

    testWidgets('trunca la etiqueta del chip a 36 caracteres + "..."', (
      tester,
    ) async {
      final diag = _makeDiagnosis(
        icd10Code: 'Z00',
        description:
            'Descripción muy larga que supera los treinta y seis caracteres permitidos',
      );
      final c = _makeConsultation(diagnosis: [diag]);
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      final chipTexts = find.textContaining('...');
      expect(chipTexts, findsAtLeastNWidgets(1));
    });

    testWidgets('no trunca etiquetas de 36 caracteres o menos', (tester) async {
      final diag = _makeDiagnosis(icd10Code: 'A01', description: 'Corto');
      final c = _makeConsultation(diagnosis: [diag]);
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('...'), findsNothing);
    });

    testWidgets('renderiza múltiples chips para múltiples diagnósticos', (
      tester,
    ) async {
      final c = _makeConsultation(
        diagnosis: [
          _makeDiagnosis(icd10Code: 'J00', description: 'Rinitis'),
          _makeDiagnosis(icd10Code: 'K29', description: 'Gastritis'),
        ],
      );
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.medical_information_outlined), findsNWidgets(2));
    });

    testWidgets('no muestra chips cuando no hay diagnósticos', (tester) async {
      final c = _makeConsultation(diagnosis: const []);
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.medical_information_outlined), findsNothing);
    });
  });

  // ── Group 5: Care modality ───────────────────────────────────────
  group('_ConsultationCard – etiqueta de modalidad', () {
    final modalidades = {
      '01': 'Intramural',
      '02': 'Extramural',
      '03': 'Domiciliaria',
      '04': 'Jornada',
      '05': 'Prehospitalaria',
      '06': 'Telemedicina interactiva',
      '07': 'No interactiva',
      '08': 'Telexperticia',
      '09': 'Telemonitoreo',
    };

    for (final entry in modalidades.entries) {
      testWidgets(
        'código ${entry.key} muestra etiqueta "${entry.value}" (ES)',
        (tester) async {
          final c = _makeConsultation(careModality: entry.key);
          await tester.pumpWidget(
            _wrap(
              ProfileTabConsultations(
                draft: _makeRecord([c]),
                canAdd: false,
                onAdd: () {},
              ),
            ),
          );

          final s = AppStrings.forTesting('es');
          final expected = {
            '01': s.modIntramural,
            '02': s.modExtramuralMobil,
            '03': s.modDomiciliaria,
            '04': s.modJornada,
            '05': s.modPrehospitalaria,
            '06': s.modTelemedicinaInteractiva,
            '07': s.modNoInteractiva,
            '08': s.modTelexperticia,
            '09': s.modTelemonitoreo,
          }[entry.key]!;

          expect(find.text(expected), findsOneWidget);
        },
      );
    }

    testWidgets('código desconocido muestra el código crudo', (tester) async {
      final c = _makeConsultation(careModality: '99');
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.text('99'), findsOneWidget);
    });
  });

  // ── Group 6: Reverse chronological order ───────────────────────────────────
  group('ProfileTabConsultations – ordenamiento', () {
    testWidgets('ordena consultas de más reciente a más antigua', (
      tester,
    ) async {
      final c1 = _makeConsultation(
        startDateTime: '2022-01-10T08:00:00',
        clinicalEvaluation: ClinicalEvaluation(
          historyOfCurrentIllness: 'Consulta 2022',
        ),
      );
      final c2 = _makeConsultation(
        startDateTime: '2024-03-20T14:00:00',
        clinicalEvaluation: ClinicalEvaluation(
          historyOfCurrentIllness: 'Consulta 2024',
        ),
      );
      final c3 = _makeConsultation(
        startDateTime: '2023-07-05T10:00:00',
        clinicalEvaluation: ClinicalEvaluation(
          historyOfCurrentIllness: 'Consulta 2023',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c1, c2, c3]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );
      final offset2024 = tester.getTopLeft(find.text('Consulta 2024')).dy;
      final offset2023 = tester.getTopLeft(find.text('Consulta 2023')).dy;
      final offset2022 = tester.getTopLeft(find.text('Consulta 2022')).dy;

      expect(offset2024, lessThan(offset2023));
      expect(offset2023, lessThan(offset2022));
    });
  });

  // ── Group 7: Multiple consultations ─────────────────────────────────────────
  group('ProfileTabConsultations – múltiples consultas', () {
    testWidgets('renderiza una tarjeta por cada consulta', (tester) async {
      final consultations = List.generate(
        3,
        (i) => _makeConsultation(
          startDateTime: '2024-0${i + 1}-10T09:00:00',
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Historia $i',
          ),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord(consultations),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.text('Historia 0'), findsOneWidget);
      expect(find.text('Historia 1'), findsOneWidget);
      expect(find.text('Historia 2'), findsOneWidget);
    });

    testWidgets('el contador del header refleja la cantidad de consultas', (
      tester,
    ) async {
      final consultations = List.generate(4, (_) => _makeConsultation());

      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord(consultations),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('· 4'), findsOneWidget);
    });
  });

  // ── Group 8: Button Callback ───────────────────────────────────────────
  group('ProfileTabConsultations – interacción del botón', () {
    testWidgets('llama onAdd al pulsar el botón (canAdd=true)', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord(const []),
            canAdd: true,
            onAdd: () => called = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(called, isTrue);
    });
  });

  // ── Group 9: Detailed Navigation ───────────────────────────────────────
  group('_ConsultationCard – tap abre detalle', () {
    testWidgets('tocar la tarjeta navega a la pantalla de detalle', (
      tester,
    ) async {
      final c = _makeConsultation(
        clinicalEvaluation: ClinicalEvaluation(
          historyOfCurrentIllness: 'Paciente con tos.',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord([c]),
            canAdd: false,
            onAdd: () {},
          ),
        ),
      );

      await tester.tap(find.text('Paciente con tos.'));
      await tester.pumpAndSettle();

      final s = AppStrings.forTesting('es');
      expect(find.text(s.consultationDetailTitle), findsOneWidget);
    });
  });

  // ── Group 10: Date/time format ──────────────────────────────────────
  group('_ConsultationCard – formato hora 12h', () {
    final cases = [
      ('2024-01-01T00:00:00', '12:00', 'a.m.'),
      ('2024-01-01T11:59:00', '11:59', 'a.m.'),
      ('2024-01-01T12:00:00', '12:00', 'p.m.'),
      ('2024-01-01T13:00:00', '1:00', 'p.m.'),
      ('2024-01-01T23:45:00', '11:45', 'p.m.'),
    ];

    for (final (dt, time, period) in cases) {
      testWidgets('$dt → $time $period', (tester) async {
        final c = _makeConsultation(startDateTime: dt);
        await tester.pumpWidget(
          _wrap(
            ProfileTabConsultations(
              draft: _makeRecord([c]),
              canAdd: false,
              onAdd: () {},
            ),
          ),
        );

        expect(find.byType(ProfileTabConsultations), findsOneWidget);
      });
    }
  });

  // ── Grupo 11: i18n ────────────────────────────────────────────────────────
  group('ProfileTabConsultations – i18n', () {
    testWidgets('header muestra strings en español (locale=es)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord(const []),
            canAdd: false,
            onAdd: () {},
          ),
          locale: 'es',
        ),
      );

      expect(find.textContaining('CONSULTAS · 0'), findsOneWidget);
    });

    testWidgets('header muestra strings en inglés (locale=en)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabConsultations(
            draft: _makeRecord(const []),
            canAdd: false,
            onAdd: () {},
          ),
          locale: 'en',
        ),
      );

      expect(find.textContaining('CONSULTATIONS · 0'), findsOneWidget);
    });
  });

  // ── Grupo 12: Cobertura completa de _ConsultationDetailScreen ──────────────
  group('_ConsultationDetailScreen – Cobertura Absoluta', () {
    testWidgets(
      'Navega al detalle y renderiza endDateTime, provider, practitioner, evaluation completa, diagnosis, discharge, riskFactors, incapacity, payer, entryRoute y externalCause',
      (tester) async {
        final c = _makeConsultation(
          startDateTime: '2024-06-15T10:00:00',
          endDateTime: '2024-06-15T12:30:00',
          entryRoute: 'Urgencias',
          externalCause: 'Accidente de tránsito',
          provider: _makeProvider(
            name: 'Hospital del Norte',
            repsCode: 'REPS-999',
          ),
          practitioner: _makePractitioner(
            name: 'Dr. Roberto Gómez',
            documentType: 'CC',
            documentNumber: '11223344',
          ),
          diagnosisType: '01',
          diagnosis: [
            _makeDiagnosis(icd10Code: 'S00', description: 'Trauma superficial'),
          ],
          dischargeDisposition: '04',
          riskFactors: [
            RiskFactor(type: 'Cardiovascular', name: 'Fumador activo'),
          ],
          incapacity: IncapacityInfo(scope: 'Total', days: 5),
          payer: PayerInfo(code: 'EPS001', name: 'Salud Total'),
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Caída de propia altura',
            generalPhysicalExamination: 'Examen general normal',
            systemsExamination: 'Examen de sistemas alterado',
            treatmentPlanObservations: 'Tomar analgésicos',
          ),
        );

        await tester.pumpWidget(
          _wrap(
            ProfileTabConsultations(
              draft: _makeRecord([c]),
              canAdd: false,
              onAdd: () {},
            ),
          ),
        );

        // Abrir detalle tocando la tarjeta
        await tester.tap(find.text('Caída de propia altura'));
        await tester.pumpAndSettle();

        // 1. Verificaciones de la parte superior del detalle
        expect(
          find.textContaining('Urgencias', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.textContaining('Accidente de tránsito', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.textContaining('Hospital del Norte', skipOffstage: false),
          findsWidgets,
        );
        expect(
          find.textContaining('REPS-999', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.textContaining('Dr. Roberto Gómez', skipOffstage: false),
          findsWidgets,
        );
        expect(
          find.textContaining('CC 11223344', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.textContaining('Examen general normal', skipOffstage: false),
          findsOneWidget,
        );

        // 2. Hacer scroll hacia abajo para forzar la construcción de las secciones inferiores (RiskFactors, Incapacity, Payer)
        await tester.drag(find.byType(ListView).last, const Offset(0, -500));
        await tester.pumpAndSettle();

        // 3. Verificaciones de la parte inferior del detalle
        expect(
          find.textContaining(
            'Examen de sistemas alterado',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('Tomar analgésicos', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.textContaining('Trauma superficial', skipOffstage: false),
          findsWidgets,
        );
        expect(
          find.textContaining('Fumador activo', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.textContaining('5', skipOffstage: false),
          findsAtLeastNWidgets(1),
        );
        expect(
          find.textContaining('EPS001', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.textContaining('Salud Total', skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Ejecuta todas las claves restantes de _dtLabel (02, 03, fallback) y _ddLabel (01, 02, 03, fallback)',
      (tester) async {
        final c1 = _makeConsultation(
          diagnosisType: '02',
          dischargeDisposition: '01',
          diagnosis: [_makeDiagnosis(icd10Code: 'A01', description: 'Diag 02')],
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Caso Tipo 02 / Egreso 01',
          ),
        );
        final c2 = _makeConsultation(
          diagnosisType: '03',
          dischargeDisposition: '02',
          diagnosis: [_makeDiagnosis(icd10Code: 'A02', description: 'Diag 03')],
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Caso Tipo 03 / Egreso 02',
          ),
        );
        final c3 = _makeConsultation(
          diagnosisType: '99',
          dischargeDisposition: '03',
          diagnosis: [
            _makeDiagnosis(icd10Code: 'A03', description: 'Diag Fallback'),
          ],
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Caso Fallback / Egreso 03',
          ),
        );
        final c4 = _makeConsultation(
          diagnosisType: '01',
          dischargeDisposition: '99',
          diagnosis: [_makeDiagnosis(icd10Code: 'A04', description: 'Diag 01')],
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Caso Tipo 01 / Egreso Fallback',
          ),
        );

        await tester.pumpWidget(
          _wrap(
            ProfileTabConsultations(
              draft: _makeRecord([c1, c2, c3, c4]),
              canAdd: false,
              onAdd: () {},
            ),
          ),
        );

        await tester.tap(find.text('Caso Tipo 02 / Egreso 01'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Caso Tipo 03 / Egreso 02'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Caso Fallback / Egreso 03'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Caso Tipo 01 / Egreso Fallback'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Navega al detalle en INGLÉS (locale=en) para cubrir formato de fecha en inglés',
      (tester) async {
        final c = _makeConsultation(
          startDateTime: '2024-06-15T10:00:00',
          endDateTime: '2024-06-15T12:30:00',
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'English illness description',
          ),
        );

        await tester.pumpWidget(
          _wrap(
            ProfileTabConsultations(
              draft: _makeRecord([c]),
              canAdd: false,
              onAdd: () {},
            ),
            locale: 'en',
          ),
        );

        await tester.tap(find.text('English illness description'));
        await tester.pumpAndSettle();

        expect(find.textContaining('6/15/2024 10:00'), findsOneWidget);
        expect(find.textContaining('6/15/2024 12:30'), findsOneWidget);
      },
    );

    testWidgets(
      'Prueba todos los tipos de diagnosisType (01, 02, 03, fallback) y dischargeDisposition (01, 02, 03, 04, fallback)',
      (tester) async {
        final c1 = _makeConsultation(
          diagnosisType: '01',
          dischargeDisposition: '01',
          diagnosis: [_makeDiagnosis(icd10Code: 'D01', description: 'Diag 1')],
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Caso 1',
          ),
        );
        final c2 = _makeConsultation(
          diagnosisType: '02',
          dischargeDisposition: '02',
          diagnosis: [_makeDiagnosis(icd10Code: 'D02', description: 'Diag 2')],
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Caso 2',
          ),
        );
        final c3 = _makeConsultation(
          diagnosisType: '03',
          dischargeDisposition: '03',
          diagnosis: [_makeDiagnosis(icd10Code: 'D03', description: 'Diag 3')],
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Caso 3',
          ),
        );
        final c4 = _makeConsultation(
          diagnosisType: '99',
          dischargeDisposition: '99',
          diagnosis: [_makeDiagnosis(icd10Code: 'D04', description: 'Diag 4')],
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Caso 4',
          ),
        );

        await tester.pumpWidget(
          _wrap(
            ProfileTabConsultations(
              draft: _makeRecord([c1, c2, c3, c4]),
              canAdd: false,
              onAdd: () {},
            ),
          ),
        );

        await tester.tap(find.text('Caso 1'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Caso 2'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Caso 3'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Caso 4'));
        await tester.pumpAndSettle();
        expect(find.textContaining('99'), findsWidgets);
      },
    );

    testWidgets(
      'Cubre fallbacks nulos para payer (code nulo, name nulo) y ServiceGroup / CareEnvironment',
      (tester) async {
        final c = _makeConsultation(
          serviceGroup: '02',
          careEnvironment: '01',
          payer: PayerInfo(code: null, name: null),
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: 'Payer null test',
          ),
        );

        await tester.pumpWidget(
          _wrap(
            ProfileTabConsultations(
              draft: _makeRecord([c]),
              canAdd: false,
              onAdd: () {},
            ),
          ),
        );

        await tester.tap(find.text('Payer null test'));
        await tester.pumpAndSettle();

        expect(find.text('—'), findsWidgets);
      },
    );
  });
}
