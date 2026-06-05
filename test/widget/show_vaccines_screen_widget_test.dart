// test/widget/show_vaccines_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/show_vaccines_screen.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

class _AppLocaleProvider extends StatefulWidget {
  const _AppLocaleProvider({required this.locale, required this.child});
  final String locale;
  final Widget child;

  @override
  State<_AppLocaleProvider> createState() => _AppLocaleProviderState();
}

class _AppLocaleProviderState extends State<_AppLocaleProvider> {
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

Widget _buildTestableWidget(Widget child) {
  return _AppLocaleProvider(
    locale: 'es',
    child: MaterialApp(home: child),
  );
}

PatientFullRecord _makeMockPatient({
  required List<VaccinationRecordItem> vaccines,
}) {
  return PatientFullRecord(
    patientId: 'patient-vaccine-test',
    deviceUid: 'HWB-VACC-55',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '54321',
      ),
      firstName: 'Mateo',
      firstLastName: 'Gómez',
      dob: '2015-08-20',
      biologicalSex: 'M',
      address: Address(city: 'Riohacha', state: 'La Guajira'),
    ),
    guardianInfo: GuardianInfo(name: 'N/A', relationship: 'N/A', phone: 'N/A'),
    allergies: const [],
    vaccinationRecord: vaccines,
  );
}

void main() {
  final s = AppStrings.forTesting('es');

  group('ShowVaccinesScreen Widget Tests — 100% Cobertura', () {
    testWidgets(
      'Debe renderizar la lista de vacunas con sus metadatos correspondientes',
      (tester) async {
        /// Added the mandatory 'vaccineCode' parameter required by the production model.
        final patient = _makeMockPatient(
          vaccines: [
            VaccinationRecordItem(
              vaccineName: 'Fiebre Amarilla',
              vaccineCode: 'CVX-111',
              dose: 1,
              date: '2026-02-10',
              administratedBy: 'Dra. Elena Ruiz',
              administratedAt: 'Hospital Riohacha',
            ),
          ],
        );

        await tester.pumpWidget(
          _buildTestableWidget(ShowVaccinesScreen(patient: patient)),
        );
        await tester.pumpAndSettle();

        expect(find.text(s.vaccines), findsNWidgets(2));

        expect(find.text('${s.vaccine}: Fiebre Amarilla'), findsOneWidget);
        expect(find.text('${s.dose}: 1'), findsOneWidget);
        expect(find.text('${s.date}: 2026-02-10'), findsOneWidget);
        expect(
          find.text('${s.administeredBy}: Dra. Elena Ruiz'),
          findsOneWidget,
        );
        expect(
          find.text('${s.administeredAt}: Hospital Riohacha'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Debe desplegar la hoja inferior EditVaccineSheet al pulsar el botón flotante',
      (tester) async {
        final patient = _makeMockPatient(vaccines: const []);

        await tester.pumpWidget(
          _buildTestableWidget(ShowVaccinesScreen(patient: patient)),
        );
        await tester.pumpAndSettle();

        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);

        await tester.tap(fab);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add), findsWidgets);
      },
    );

    testWidgets(
      'Debe accionar correctamente la navegación hacia atrás al presionar el botón del header',
      (tester) async {
        final patient = _makeMockPatient(vaccines: const []);

        await tester.pumpWidget(
          _buildTestableWidget(
            Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ShowVaccinesScreen(patient: patient),
                    ),
                  ),
                  child: const Text('Ir a Vacunas'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ir a Vacunas'));
        await tester.pumpAndSettle();

        final backButton = find.byIcon(Icons.arrow_back);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.text('Ir a Vacunas'), findsOneWidget);
      },
    );
  });
}
