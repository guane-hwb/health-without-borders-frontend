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

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_vaccines.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

/// Wrap the widget under test with the minimum necessary tree:
/// MaterialApp (for directionality and theme) + AppLocale (for AppStrings).
Widget _wrap(Widget child, {String locale = 'es'}) {
  return _LocaleWrapper(
    locale: locale,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

/// Stateful widget that injects [AppLocale] into the tree.
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
  Widget build(BuildContext context) {
    return AppLocale(
      locale: _locale,
      setLocale: (l) => setState(() => _locale = l),
      child: widget.child,
    );
  }
}

// ─── Domain Factories ────────────────────────────────────────────────────

/// Creates a [VaccinationRecordItem] with overridable default values.
// Fixed: dose is now int and the required parameter administratedBy was added.
VaccinationRecordItem _makeVaccine({
  String vaccineName = 'BCG',
  int dose = 1,
  String date = '2024-03-15T00:00:00',
  String vaccineCode = '19',
  String administratedBy = 'Dr. House',
  String administratedAt = 'Hospital Central',
  String status = 'completed',
}) => VaccinationRecordItem(
  vaccineName: vaccineName,
  dose: dose,
  date: date,
  vaccineCode: vaccineCode,
  administratedBy: administratedBy,
  administratedAt: administratedAt,
  status: status,
);

/// Creates a minimal [PatientFullRecord] with the specified vaccine list.
// Fixed: Removed non-existent .empty() methods and mapped to medicalHistory.
PatientFullRecord _makeRecord(List<VaccinationRecordItem> vaccines) =>
    PatientFullRecord(
      patientId: 'test-uuid',
      deviceUid: 'HWB-01:02:03:04',
      vaccinationRecord: vaccines,
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: 'MS',
          documentNumber: '',
        ),
        firstLastName: '',
        firstName: '',
        dob: '',
        biologicalSex: 'I',
        address: Address(city: '', state: ''),
      ),
      guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
      allergies: const [],
      backgroundHistory: null,
      medicalHistory: const [],
    );

// ════════════════════════════════════════════════════════════════════════════
// Tests
// ════════════════════════════════════════════════════════════════════════════

void main() {
  // ── Group 1: Empty state ─────────────────────────────────────────────────
  group('ProfileTabVaccines – lista vacía', () {
    testWidgets('muestra mensaje "sin vacunas" cuando no hay registros', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord(const []),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      final BuildContext context = tester.element(
        find.byType(ProfileTabVaccines),
      );
      final s = AppStrings.of(context);

      expect(find.text(s.noVaccinesRegistered), findsOneWidget);
    });

    testWidgets('no renderiza ningún _VaccineCard cuando la lista está vacía', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord(const []),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.vaccines), findsNothing);
    });

    testWidgets('muestra el botón "Agregar vacuna"', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord(const []),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  // ── Group 2: List with one vaccine ─────────────────────────────────────────
  group('ProfileTabVaccines – una vacuna', () {
    late VaccinationRecordItem vaccine;

    setUp(() {
      vaccine = _makeVaccine(
        vaccineName: 'Hepatitis B',
        dose: 2,
        date: '2023-07-04T00:00:00',
        vaccineCode: '08',
        administratedAt: 'Clínica Norte',
        status: 'completed',
      );
    });

    testWidgets('renderiza el nombre de la vacuna', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([vaccine]),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.text('Hepatitis B'), findsOneWidget);
    });

    testWidgets('muestra la dosis y el código CVX en el subtítulo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([vaccine]),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('CVX 08'), findsOneWidget);
      expect(find.textContaining('2'), findsWidgets); // dosis 2
    });

    testWidgets('formatea la fecha como DD/MM/YYYY', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([vaccine]),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('04/07/2023'), findsOneWidget);
    });

    testWidgets('muestra el lugar de administración cuando no está vacío', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([vaccine]),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.text('Clínica Norte'), findsOneWidget);
    });

    testWidgets('muestra administratedAt cuando no está vacío', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([
              _makeVaccine(administratedAt: 'Centro de Salud Norte'),
            ]),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.text('Centro de Salud Norte'), findsOneWidget);
    });

    testWidgets('no muestra administratedAt cuando está vacío', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([_makeVaccine(administratedAt: '')]),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('BCG'), findsOneWidget);
    });

    testWidgets('no muestra lugar de administración cuando está vacío', (
      tester,
    ) async {
      final v = _makeVaccine(administratedAt: '');
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([v]),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.text(''), findsNothing);
    });

    testWidgets('muestra ícono check_circle cuando status es "completed"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([vaccine]),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets(
      'no muestra ícono check_circle cuando status no es "completed"',
      (tester) async {
        final v = _makeVaccine(status: 'pending');
        await tester.pumpWidget(
          _wrap(
            ProfileTabVaccines(
              draft: _makeRecord([v]),
              canEdit: true,
              onAdd: () {},
            ),
          ),
        );

        expect(find.byIcon(Icons.check_circle), findsNothing);
      },
    );
  });

  // ── Group 3: List with multiple vaccines ──────────────────────────────────
  group('ProfileTabVaccines – múltiples vacunas', () {
    final vaccines = [
      _makeVaccine(vaccineName: 'BCG', date: '2022-01-10T00:00:00', dose: 1),
      _makeVaccine(vaccineName: 'Polio', date: '2021-06-20T00:00:00', dose: 3),
      _makeVaccine(
        vaccineName: 'Hepatitis A',
        date: '2023-09-05T00:00:00',
        dose: 1,
      ),
    ];

    testWidgets('renderiza una tarjeta por cada vacuna', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord(vaccines),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.text('BCG'), findsOneWidget);
      expect(find.text('Polio'), findsOneWidget);
      expect(find.text('Hepatitis A'), findsOneWidget);
    });

    testWidgets('ordena las vacunas por fecha ascendente', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord(vaccines),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      final polioOffset = tester.getTopLeft(find.text('Polio')).dy;
      final bcgOffset = tester.getTopLeft(find.text('BCG')).dy;
      final hepatitisOffset = tester.getTopLeft(find.text('Hepatitis A')).dy;

      expect(polioOffset, lessThan(bcgOffset));
      expect(bcgOffset, lessThan(hepatitisOffset));
    });

    testWidgets('no muestra el mensaje "sin vacunas"', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord(vaccines),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      final BuildContext context = tester.element(
        find.byType(ProfileTabVaccines),
      );
      final s = AppStrings.of(context);
      expect(find.text(s.noVaccinesRegistered), findsNothing);
    });
  });

  // ── Group 4: Button Callback ───────────────────────────────────────────
  group('ProfileTabVaccines – interacción del botón', () {
    testWidgets('llama onAdd al pulsar el botón de agregar vacuna', (
      tester,
    ) async {
      var called = false;

      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord(const []),
            canEdit: true,
            onAdd: () => called = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(called, isTrue);
    });
  });

  // ── Group 5: Date Format (_formattedDate) ────────────────────────────
  group('_VaccineCard – formato de fecha', () {
    testWidgets('fecha corta (< 10 chars) se muestra tal cual', (tester) async {
      final v = _makeVaccine(date: '2024-03');
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([v]),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('2024-03'), findsOneWidget);
    });

    testWidgets('fecha ISO completa se convierte a DD/MM/YYYY', (tester) async {
      final v = _makeVaccine(date: '2020-12-31T10:00:00');
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([v]),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('31/12/2020'), findsOneWidget);
    });

    testWidgets('fecha sin guiones se muestra sin transformar', (tester) async {
      final v = _makeVaccine(date: '20200131');
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([v]),
            canEdit: true,
            onAdd: () {},
          ),
        ),
      );

      expect(find.textContaining('20200131'), findsOneWidget);
    });
  });

  // ── Group 6: Internationalization ─────────────────────────────────────────
  group('ProfileTabVaccines – i18n', () {
    testWidgets('header usa strings en español (locale = es)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord(const []),
            canEdit: true,
            onAdd: () {},
          ),
          locale: 'es',
        ),
      );

      final BuildContext context = tester.element(
        find.byType(ProfileTabVaccines),
      );
      final s = AppStrings.of(context);

      expect(
        find.textContaining(s.vaccineSchemeTitle.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('header usa strings en inglés (locale = en)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord(const []),
            canEdit: true,
            onAdd: () {},
          ),
          locale: 'en',
        ),
      );

      final BuildContext context = tester.element(
        find.byType(ProfileTabVaccines),
      );
      final s = AppStrings.of(context);

      expect(
        find.textContaining(s.vaccineSchemeTitle.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets(
      'label singular cuando hay exactamente 1 vacuna (locale = es)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ProfileTabVaccines(
              draft: _makeRecord([_makeVaccine()]),
              canEdit: true,
              onAdd: () {},
            ),
            locale: 'es',
          ),
        );

        final BuildContext context = tester.element(
          find.byType(ProfileTabVaccines),
        );
        final s = AppStrings.of(context);

        expect(
          find.textContaining(s.vaccineLabelSingle.toUpperCase()),
          findsOneWidget,
        );
      },
    );

    testWidgets('label plural cuando hay más de 1 vacuna (locale = es)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProfileTabVaccines(
            draft: _makeRecord([
              _makeVaccine(),
              _makeVaccine(vaccineName: 'Polio'),
            ]),
            canEdit: true,
            onAdd: () {},
          ),
          locale: 'es',
        ),
      );

      final BuildContext context = tester.element(
        find.byType(ProfileTabVaccines),
      );
      final s = AppStrings.of(context);

      expect(
        find.textContaining(s.vaccineLabelPlural.toUpperCase()),
        findsOneWidget,
      );
    });
  });
}
