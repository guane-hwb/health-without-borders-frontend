// test/src/features/nfc/presentation/profile/tabs/profile_tab_vaccines_test.dart
//
// Covers unit tests for ProfileTabVaccines via rendered text:
// • _formattedDate — valid date, month out of range, no hyphens, insufficient parts
// • Header — pluralization VACCINE / VACCINES and count
// • Empty state — "No vaccines registered."

// • Order — ascending by date
// • _VaccineCard — vaccineName, dose, CVX, administeredAt, check icon for status
// • Button — always visible, calls onAdd

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_vaccines.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Minimal constructor of [VaccinationRecordItem] using the required fields.
VaccinationRecordItem _makeVaccine({
  String date = '2024-06-15',
  String vaccineName = 'BCG',
  String vaccineCode = '19',
  int dose = 1,
  String administratedBy = 'Enfermera Pérez',
  String administratedAt = 'Hospital Central',
  String status = 'completed',
}) =>
    VaccinationRecordItem(
      date: date,
      vaccineName: vaccineName,
      vaccineCode: vaccineCode,
      dose: dose,
      administratedBy: administratedBy,
      administratedAt: administratedAt,
      status: status,
    );

/// [PatientFullRecord] minimum with the given vaccine list.
PatientFullRecord _makeRecord(List<VaccinationRecordItem> vaccines) =>
    PatientFullRecord(
      patientId: 'test-id',
      deviceUid: 'AA:BB:CC:DD',
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: 'MS',
          documentNumber: '000',
        ),
        firstLastName: 'Test',
        firstName: 'Paciente',
        dob: '2000-01-01',
        biologicalSex: 'I',
        address: Address(city: 'Bogotá', state: 'Cundinamarca'),
      ),
      guardianInfo: GuardianInfo(
        name: 'Tutor',
        relationship: 'padre',
        phone: '3000000000',
      ),
      vaccinationRecord: vaccines,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── _formattedDate ──────────────────────────────────────────────────────────
  group('_VaccineCard · _formattedDate', () {
    testWidgets('fecha válida se formatea como "d mes. de yyyy"',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(date: '2024-06-15')]),
        onAdd: () {},
      )));

      expect(find.textContaining('15 jun. de 2024'), findsOneWidget);
    });

    testWidgets('mes 1 (enero) se formatea correctamente', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(date: '2023-01-03')]),
        onAdd: () {},
      )));

      expect(find.textContaining('3 ene. de 2023'), findsOneWidget);
    });

    testWidgets('mes 12 (diciembre) se formatea correctamente', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(date: '2022-12-31')]),
        onAdd: () {},
      )));

      expect(find.textContaining('31 dic. de 2022'), findsOneWidget);
    });

    testWidgets('fecha sin guiones devuelve el string tal cual', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(date: '20240615')]),
        onAdd: () {},
      )));

      expect(find.textContaining('20240615'), findsOneWidget);
    });

    testWidgets('fecha con partes insuficientes devuelve el raw string',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(date: '2024-06')]),
        onAdd: () {},
      )));

      expect(find.textContaining('2024-06'), findsOneWidget);
    });

    testWidgets('mes fuera de rango (0) devuelve el raw string', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(date: '2024-00-10')]),
        onAdd: () {},
      )));

      expect(find.textContaining('2024-00-10'), findsOneWidget);
    });

    testWidgets('mes fuera de rango (13) devuelve el raw string',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(date: '2024-13-10')]),
        onAdd: () {},
      )));

      expect(find.textContaining('2024-13-10'), findsOneWidget);
    });

    testWidgets('campo mes no numérico devuelve el raw string', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(date: '2024-xx-10')]),
        onAdd: () {},
      )));

      expect(find.textContaining('2024-xx-10'), findsOneWidget);
    });
  });

  // ── Header / pluralization ──────────────────────────────────────────────────
  group('ProfileTabVaccines · header', () {
    testWidgets('sin vacunas muestra "ESQUEMA · 0 VACUNAS"', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([]),
        onAdd: () {},
      )));

      expect(find.text('ESQUEMA · 0 VACUNAS'), findsOneWidget);
    });

    testWidgets('una vacuna muestra "ESQUEMA · 1 VACUNA" (singular)',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine()]),
        onAdd: () {},
      )));

      expect(find.text('ESQUEMA · 1 VACUNA'), findsOneWidget);
    });

    testWidgets('dos vacunas muestra "ESQUEMA · 2 VACUNAS" (plural)',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(), _makeVaccine(date: '2025-01-10')]),
        onAdd: () {},
      )));

      expect(find.text('ESQUEMA · 2 VACUNAS'), findsOneWidget);
    });
  });

  // ── Empty state ────────────────────────────────────────────────────────────
  group('ProfileTabVaccines · empty state', () {
    testWidgets('muestra "Sin vacunas registradas." cuando la lista está vacía',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([]),
        onAdd: () {},
      )));

      expect(find.text('Sin vacunas registradas.'), findsOneWidget);
    });

    testWidgets('no muestra tarjetas de vacuna cuando la lista está vacía',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([]),
        onAdd: () {},
      )));

      expect(find.textContaining('Dosis'), findsNothing);
    });
  });

  // ── Ascending order ────────────────────────────────────────────────────────
  group('ProfileTabVaccines · orden de vacunas', () {
    testWidgets('ordena las vacunas de más antigua a más reciente',
        (tester) async {
      final vaccines = [
        _makeVaccine(date: '2025-03-01', vaccineName: 'VacunaC'),
        _makeVaccine(date: '2023-01-10', vaccineName: 'VacunaA'),
        _makeVaccine(date: '2024-07-20', vaccineName: 'VacunaB'),
      ];
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord(vaccines),
        onAdd: () {},
      )));

      final names = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where((s) => s.startsWith('Vacuna'))
          .toList();

      // Expected order: A (2023) → B (2024) → C (2025)
      expect(names, ['VacunaA', 'VacunaB', 'VacunaC']);
    });
  });

  // ── _VaccineCard content ──────────────────────────────────────────────────
  group('_VaccineCard · contenido', () {
    testWidgets('muestra el nombre de la vacuna', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(vaccineName: 'Hepatitis B')]),
        onAdd: () {},
      )));

      expect(find.text('Hepatitis B'), findsOneWidget);
    });

    testWidgets('muestra dosis y código CVX en el subtítulo', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(dose: 2, vaccineCode: '45')]),
        onAdd: () {},
      )));

      expect(find.textContaining('Dosis 2'), findsOneWidget);
      expect(find.textContaining('CVX 45'), findsOneWidget);
    });

    testWidgets('muestra administratedAt cuando no está vacío', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([
          _makeVaccine(administratedAt: 'Centro de Salud Norte'),
        ]),
        onAdd: () {},
      )));

      expect(find.text('Centro de Salud Norte'), findsOneWidget);
    });

    testWidgets('no muestra administratedAt cuando está vacío', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(administratedAt: '')]),
        onAdd: () {},
      )));

      expect(find.textContaining('BCG'), findsOneWidget);
    });

    testWidgets('muestra ícono check_circle cuando status == "completed"',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(status: 'completed')]),
        onAdd: () {},
      )));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('NO muestra ícono check_circle cuando status != "completed"',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(status: 'pending')]),
        onAdd: () {},
      )));

      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('muestra la fecha formateada en el subtítulo', (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(date: '2024-09-05')]),
        onAdd: () {},
      )));

      expect(find.textContaining('5 sep. de 2024'), findsOneWidget);
    });
  });

  // ── Button "Registrar vacuna" ────────────────────────────────────────────────
  group('ProfileTabVaccines · botón Registrar vacuna', () {
    testWidgets('siempre se muestra independiente del estado de la lista',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([]),
        onAdd: () {},
      )));

      expect(find.text('Registrar vacuna'), findsOneWidget);
    });

    testWidgets('llama onAdd al presionarlo', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([]),
        onAdd: () => called = true,
      )));

      await tester.tap(find.text('Registrar vacuna'));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('también se muestra cuando hay vacunas en la lista',
        (tester) async {
      await tester.pumpWidget(_wrap(ProfileTabVaccines(
        draft: _makeRecord([_makeVaccine(), _makeVaccine(date: '2025-01-01')]),
        onAdd: () {},
      )));

      expect(find.text('Registrar vacuna'), findsOneWidget);
    });
  });
}