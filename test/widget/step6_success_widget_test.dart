// test/widget/step6_success_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/steps/step6_success.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

PatientFullRecord _makePatient({
  String firstName = 'María',
  String firstLastName = 'García',
  String docType = 'CC',
  String docNumber = '12345678',
  List<MedicalHistoryItem> medicalHistory = const [],
  List<VaccinationRecordItem> vaccinationRecord = const [],
}) {
  return PatientFullRecord(
    patientId: 'test-patient-uuid-123',
    deviceUid: 'HWB-04:1A:2C:DE',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: docType,
        documentNumber: docNumber,
      ),
      firstName: firstName,
      firstLastName: firstLastName,
      dob: '1990-01-01',
      biologicalSex: 'F',
      address: Address(city: 'Riohacha', state: 'La Guajira'),
    ),
    guardianInfo: GuardianInfo(
      name: 'Carmen Vargas',
      relationship: '01',
      phone: '+573104829914',
    ),
    backgroundHistory: BackgroundHistory(
      chronicConditions: const [],
      familyHistory: const [],
      medications: const [],
    ),
    allergies: const [],
    medicalHistory: medicalHistory,
    vaccinationRecord: vaccinationRecord,
  );
}

Widget _wrap(Widget child, {String locale = 'es'}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(
      locale: Locale(locale),
      home: Scaffold(body: child),
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

  group('Step6Success · elementos siempre presentes', () {
    testWidgets('muestra ícono de check verde', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('muestra el nombre completo del paciente', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(firstName: 'Carlos', firstLastName: 'Pérez'),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Carlos Pérez'), findsOneWidget);
    });

    testWidgets('muestra tipo y número de documento', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(docType: 'TI', docNumber: '987654'),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TI 987654'), findsOneWidget);
    });

    testWidgets('muestra fila NFC con ícono nfc', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.nfc), findsOneWidget);
    });

    testWidgets('muestra fila de guardado con ícono save_outlined', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save_outlined), findsOneWidget);
    });

    testWidgets('muestra botón Finalizar siempre', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final finishBtn = find.byIcon(Icons.check_circle_outline);
      await tester.ensureVisible(finishBtn);
      expect(finishBtn, findsOneWidget);
    });
  });

  group('Step6Success · internacionalización ES / EN', () {
    testWidgets('en español muestra texto NFC en español', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Pendiente de grabar en el dispositivo NFC'),
        findsOneWidget,
      );
      expect(
        find.text('Toca "Finalizar" y acerca los dispositivos para sellar'),
        findsOneWidget,
      );
    });

    testWidgets('en inglés muestra texto NFC en inglés', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Pending write to the NFC device'),
        findsOneWidget,
      );
      expect(
        find.text('Tap "Finish" and bring the devices to seal the data'),
        findsOneWidget,
      );
    });

    testWidgets('en español el botón finalizar dice "Finalizar"', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text('Finalizar');
      await tester.ensureVisible(textFinder);
      expect(textFinder, findsOneWidget);
    });

    testWidgets('en inglés el botón finalizar dice "Finish"', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text('Finish');
      await tester.ensureVisible(textFinder);
      expect(textFinder, findsOneWidget);
    });

    testWidgets('en español pie de página muestra texto de cola ES', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text(
        'Al finalizar, el registro se envía a la cola de sincronización.',
      );
      await tester.ensureVisible(textFinder);
      expect(textFinder, findsOneWidget);
    });

    testWidgets('en inglés pie de página muestra texto de cola EN', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text(
        'Upon completion, the record is sent to the synchronization queue.',
      );
      await tester.ensureVisible(textFinder);
      expect(textFinder, findsOneWidget);
    });
  });

  group('Step6Success · filas condicionales', () {
    testWidgets('sin historial médico NO muestra fila de consulta', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(medicalHistory: const []),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Última consulta guardada'), findsNothing);
    });

    testWidgets('con historial médico SÍ muestra fila de consulta', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(
              medicalHistory: [
                MedicalHistoryItem(startDateTime: '2026-06-09T12:00:00Z'),
              ],
            ),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            lastConsultationTime: 'Hoy, 10:00 a.m.',
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Última consulta guardada'), findsOneWidget);
    });

    testWidgets('con historial médico muestra lastConsultationTime provisto', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(
              medicalHistory: [
                MedicalHistoryItem(startDateTime: '2026-06-09T12:00:00Z'),
              ],
            ),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            lastConsultationTime: 'Hoy, 3:00 p.m.',
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hoy, 3:00 p.m.'), findsOneWidget);
    });

    testWidgets('sin vacunas NO muestra fila de vacuna', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(vaccinationRecord: const []),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Última vacuna guardada'), findsNothing);
    });

    testWidgets('con vacunas SÍ muestra fila de vacuna', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(
              vaccinationRecord: [
                VaccinationRecordItem(
                  vaccineName: 'Fiebre Amarilla',
                  dose: 1,
                  date: '2026-06-09',
                  vaccineCode: '139',
                  administratedBy: 'Dra. Restrepo',
                  administratedAt: 'Brigada Riohacha',
                ),
              ],
            ),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            lastVaccineTime: 'Hoy, 9:00 a.m.',
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Última vacuna guardada'), findsOneWidget);
    });

    testWidgets('con vacunas muestra lastVaccineTime provisto', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(
              vaccinationRecord: [
                VaccinationRecordItem(
                  vaccineName: 'Fiebre Amarilla',
                  dose: 1,
                  date: '2026-06-09',
                  vaccineCode: '139',
                  administratedBy: 'Dra. Restrepo',
                  administratedAt: 'Brigada Riohacha',
                ),
              ],
            ),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            lastVaccineTime: 'Today, 9:00 AM',
          ),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today, 9:00 AM'), findsOneWidget);
    });
  });

  group('Step6Success · botón agregar consulta', () {
    testWidgets('canAddConsultation=true → botón consulta visible', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            canAddConsultation: true,
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      final btnFinder = find.byIcon(Icons.medical_services_outlined).last;
      await tester.ensureVisible(btnFinder);
      expect(btnFinder, findsOneWidget);
    });

    testWidgets('canAddConsultation=false → botón consulta NO visible', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            canAddConsultation: false,
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.medical_services_outlined), findsNothing);
    });

    testWidgets('sin consultas previas → usa label por defecto de AppStrings', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(medicalHistory: const []),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            canAddConsultation: true,
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Añadir otra consulta'), findsNothing);
    });

    testWidgets('con consultas previas + ES → "Añadir otra consulta"', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(
              medicalHistory: [
                MedicalHistoryItem(startDateTime: '2026-06-09T12:00:00Z'),
              ],
            ),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            canAddConsultation: true,
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text('Añadir otra consulta');
      await tester.ensureVisible(textFinder);
      expect(textFinder, findsOneWidget);
    });

    testWidgets('con consultas previas + EN → "Add another consultation"', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(
              medicalHistory: [
                MedicalHistoryItem(startDateTime: '2026-06-09T12:00:00Z'),
              ],
            ),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            canAddConsultation: true,
          ),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text('Add another consultation');
      await tester.ensureVisible(textFinder);
      expect(textFinder, findsOneWidget);
    });
  });

  group('Step6Success · botón agregar vacuna', () {
    testWidgets('sin vacunas previas → usa label por defecto de AppStrings', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(vaccinationRecord: const []),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Añadir otra vacuna'), findsNothing);
    });

    testWidgets('con vacunas previas + ES → "Añadir otra vacuna"', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(
              vaccinationRecord: [
                VaccinationRecordItem(
                  vaccineName: 'BCG',
                  dose: 1,
                  date: '2026-06-09',
                  vaccineCode: '03',
                  administratedBy: 'Nurse',
                  administratedAt: 'Brigada',
                ),
              ],
            ),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text('Añadir otra vacuna');
      await tester.ensureVisible(textFinder);
      expect(textFinder, findsOneWidget);
    });

    testWidgets('con vacunas previas + EN → "Add another vaccine"', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(
              vaccinationRecord: [
                VaccinationRecordItem(
                  vaccineName: 'BCG',
                  dose: 1,
                  date: '2026-06-09',
                  vaccineCode: '03',
                  administratedBy: 'Nurse',
                  administratedAt: 'Brigada',
                ),
              ],
            ),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text('Add another vaccine');
      await tester.ensureVisible(textFinder);
      expect(textFinder, findsOneWidget);
    });
  });

  group('Step6Success · callbacks', () {
    testWidgets('tap en botón de consulta dispara onAddConsultation', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      var called = false;

      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () => called = true,
            onAddVaccine: () {},
            onFinish: () {},
            canAddConsultation: true,
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      final btnFinder = find.byIcon(Icons.medical_services_outlined).last;
      await tester.ensureVisible(btnFinder);
      await tester.tap(btnFinder);
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('tap en botón de vacuna dispara onAddVaccine', (tester) async {
      configureMobileScreenSize(tester);
      var called = false;

      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () => called = true,
            onFinish: () {},
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      final btnFinder = find.byIcon(Icons.vaccines_outlined).last;
      await tester.ensureVisible(btnFinder);
      await tester.tap(btnFinder);
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('tap en botón Finalizar dispara onFinish', (tester) async {
      configureMobileScreenSize(tester);
      var called = false;

      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () => called = true,
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      final btnFinder = find.byIcon(Icons.check_circle_outline);
      await tester.ensureVisible(btnFinder);
      await tester.tap(btnFinder);
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('onAddConsultation NO se llama si canAddConsultation=false', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      var called = false;

      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () => called = true,
            onAddVaccine: () {},
            onFinish: () {},
            canAddConsultation: false,
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.medical_services_outlined), findsNothing);
      expect(called, isFalse);
    });
  });

  group('_ActivityRow · renderizado interno', () {
    testWidgets('todas las filas NFC y guardado están presentes', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.nfc), findsOneWidget);
      expect(find.byIcon(Icons.save_outlined), findsOneWidget);
    });

    testWidgets('fila NFC muestra subtitle de cifrado en ES', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Toca "Finalizar" y acerca los dispositivos para sellar'),
        findsOneWidget,
      );
    });

    testWidgets('fila syncronización muestra subtitle correcto en ES', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Listo para sincronizar cuando haya conexión'),
        findsOneWidget,
      );
    });

    testWidgets('fila sync muestra subtitle correcto en EN', (tester) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
          ),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Ready to synchronize when connection is available'),
        findsOneWidget,
      );
    });

    testWidgets('fila de vacuna EN muestra "Last vaccine saved"', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(
              vaccinationRecord: [
                VaccinationRecordItem(
                  vaccineName: 'BCG',
                  dose: 1,
                  date: '2026-06-09',
                  vaccineCode: '03',
                  administratedBy: 'Nurse',
                  administratedAt: 'Brigada',
                ),
              ],
            ),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            lastVaccineTime: 'Today, 8:00 AM',
          ),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Last vaccine saved'), findsOneWidget);
    });

    testWidgets('fila de consulta EN muestra "Last consultation saved"', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(
              medicalHistory: [
                MedicalHistoryItem(startDateTime: '2026-06-09T12:00:00Z'),
              ],
            ),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            lastConsultationTime: 'Today, 8:00 AM',
          ),
          locale: 'en',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Last consultation saved'), findsOneWidget);
    });
  });

  group('Step6Success · paciente con historial completo', () {
    testWidgets(
      'muestra las 4 filas de actividad cuando hay consultas y vacunas',
      (tester) async {
        configureMobileScreenSize(tester);
        await tester.pumpWidget(
          _wrap(
            Step6Success(
              patient: _makePatient(
                medicalHistory: [
                  MedicalHistoryItem(startDateTime: '2026-06-09T12:00:00Z'),
                ],
                vaccinationRecord: [
                  VaccinationRecordItem(
                    vaccineName: 'BCG',
                    dose: 1,
                    date: '2026-06-09',
                    vaccineCode: '03',
                    administratedBy: 'Nurse',
                    administratedAt: 'Brigada',
                  ),
                ],
              ),
              onAddConsultation: () {},
              onAddVaccine: () {},
              onFinish: () {},
              lastConsultationTime: 'Hoy, 10:00 a.m.',
              lastVaccineTime: 'Hoy, 11:00 a.m.',
              canAddConsultation: true,
            ),
            locale: 'es',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.nfc), findsOneWidget);
        expect(find.byIcon(Icons.save_outlined), findsOneWidget);
        expect(
          find.byIcon(Icons.medical_services_outlined).first,
          findsOneWidget,
        );
        expect(find.byIcon(Icons.vaccines_outlined).first, findsOneWidget);
      },
    );

    testWidgets('muestra los 3 botones de acción con el registro completo', (
      tester,
    ) async {
      configureMobileScreenSize(tester);
      await tester.pumpWidget(
        _wrap(
          Step6Success(
            patient: _makePatient(
              medicalHistory: [
                MedicalHistoryItem(startDateTime: '2026-06-09T12:00:00Z'),
              ],
              vaccinationRecord: [
                VaccinationRecordItem(
                  vaccineName: 'BCG',
                  dose: 1,
                  date: '2026-06-09',
                  vaccineCode: '03',
                  administratedBy: 'Nurse',
                  administratedAt: 'Brigada',
                ),
              ],
            ),
            onAddConsultation: () {},
            onAddVaccine: () {},
            onFinish: () {},
            canAddConsultation: true,
          ),
          locale: 'es',
        ),
      );
      await tester.pumpAndSettle();

      final consultBtn = find.text('Añadir otra consulta');
      await tester.ensureVisible(consultBtn);
      expect(consultBtn, findsOneWidget);

      final vaccineBtn = find.text('Añadir otra vacuna');
      await tester.ensureVisible(vaccineBtn);
      expect(vaccineBtn, findsOneWidget);

      final finishBtn = find.text('Finalizar');
      await tester.ensureVisible(finishBtn);
      expect(finishBtn, findsOneWidget);
    });
  });
}
