// test/widget/show_allergens_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/show_allergens_screen.dart';
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

PatientFullRecord _makeMockPatient({required List<AllergyInfo> allergies}) {
  return PatientFullRecord(
    patientId: 'patient-allergy-test',
    deviceUid: 'HWB-ALLERGY-99',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '123',
      ),
      firstName: 'Camila',
      firstLastName: 'Vargas',
      dob: '1995-05-15',
      biologicalSex: 'F',
      address: Address(city: 'Riohacha', state: 'La Guajira'),
    ),
    guardianInfo: GuardianInfo(name: 'N/A', relationship: 'N/A', phone: 'N/A'),
    allergies: allergies,
  );
}

void main() {
  final s = AppStrings.forTesting('es');

  group('ShowAllergensScreen Widget Tests — Cobertura Completa', () {
    testWidgets(
      'Debe renderizar la lista completa de alérgenos con reacciones y notas',
      (tester) async {
        final patient = _makeMockPatient(
          allergies: [
            AllergyInfo(
              category: '01',
              allergen: 'Penicilina',
              reaction: 'Anafilaxia severa',
              notes: 'Evitar derivados beta-lactámicos',
            ),
          ],
        );

        await tester.pumpWidget(
          _buildTestableWidget(ShowAllergensScreen(patient: patient)),
        );
        await tester.pumpAndSettle();

        expect(find.text(s.allergens), findsNWidgets(2));

        expect(find.text('${s.allergens}: Penicilina'), findsOneWidget);
        expect(find.text('Anafilaxia severa'), findsOneWidget);
        expect(find.text('Evitar derivados beta-lactámicos'), findsOneWidget);

        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    testWidgets(
      'Caso Borde: Debe ocultar filas opcionales si reacción y notas vienen vacías',
      (tester) async {
        final patient = _makeMockPatient(
          allergies: [
            AllergyInfo(
              category: '02',
              allergen: 'Maní',
              reaction: '',
              notes: null,
            ),
          ],
        );

        await tester.pumpWidget(
          _buildTestableWidget(ShowAllergensScreen(patient: patient)),
        );
        await tester.pumpAndSettle();

        expect(find.text('${s.allergens}: Maní'), findsOneWidget);

        expect(find.byIcon(Icons.favorite_border), findsNothing);
        expect(find.byIcon(Icons.note_alt), findsNothing);
      },
    );

    testWidgets('Debe interactuar con el botón de retroceso de la cabecera', (
      tester,
    ) async {
      final patient = _makeMockPatient(allergies: []);

      /// Wrap the navigation flow within the testable widget to maintain localization context on pushed routes.
      await tester.pumpWidget(
        _buildTestableWidget(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ShowAllergensScreen(patient: patient),
                  ),
                ),
                child: const Text('Ir a Alérgenos'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ir a Alérgenos'));
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Ir a Alérgenos'), findsOneWidget);
    });
  });
}
