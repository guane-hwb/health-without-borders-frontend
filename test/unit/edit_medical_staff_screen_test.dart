// test/unit/edit_medical_staff_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

const _docTypes = {
  'CC': 'Cédula de Ciudadanía',
  'CE': 'Cédula de Extranjería',
  'PA': 'Pasaporte',
};
const _diagTypes = {
  '01': 'Impresión diagnóstica',
  '02': 'Confirmado nuevo',
  '03': 'Confirmado repetido',
};
const _careModalities = {
  '01': 'Intramural',
  '02': 'Extramural - Móvil',
  '05': 'Extramural - Prehospitalaria',
};
const _dischargeOpts = {
  '04': 'Alta médica',
  '01': 'Alta voluntaria',
  '03': 'Remitido',
};

/// Represents the mapped initial values required by the medical staff edit view.
class InitialValues {
  const InitialValues({
    required this.practitionerName,
    required this.practitionerDocNumber,
    required this.practitionerDocType,
    required this.providerName,
    required this.providerRepsCode,
    required this.date,
    required this.diagnosisType,
    required this.careModality,
    required this.dischargeDisposition,
  });

  final String practitionerName;
  final String practitionerDocNumber;
  final String practitionerDocType;
  final String providerName;
  final String providerRepsCode;
  final String date;
  final String diagnosisType;
  final String careModality;
  final String dischargeDisposition;
}

/// Resolves the initial state values based on the last medical history encounter.
InitialValues resolveInitialValues(PatientFullRecord patient) {
  final v = patient.medicalHistory.isNotEmpty
      ? patient.medicalHistory.last
      : null;

  return InitialValues(
    practitionerName: v?.practitioner?.name ?? v?.physician ?? '',
    practitionerDocNumber: v?.practitioner?.documentNumber ?? '',
    practitionerDocType: _docTypes.containsKey(v?.practitioner?.documentType)
        ? v!.practitioner!.documentType
        : 'CC',
    providerName: v?.provider?.name ?? v?.location ?? '',
    providerRepsCode: v?.provider?.repsCode ?? '',
    date: v?.startDateTime ?? '',
    diagnosisType: _diagTypes.containsKey(v?.diagnosisType)
        ? v!.diagnosisType
        : '01',
    careModality: _careModalities.containsKey(v?.careModality)
        ? v!.careModality
        : '01',
    dischargeDisposition: _dischargeOpts.containsKey(v?.dischargeDisposition)
        ? v!.dischargeDisposition!
        : '04',
  );
}

// =============================================================================
// Fixture Construction Helpers
// =============================================================================

PatientFullRecord _patient({List<MedicalHistoryItem> history = const []}) =>
    PatientFullRecord(
      patientId: 'uuid-001',
      deviceUid: 'NFC-ABC',
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: 'CC',
          documentNumber: '123456',
        ),
        firstLastName: 'García',
        firstName: 'Ana',
        dob: '1990-03-20',
        biologicalSex: 'F',
        address: Address(city: 'Bogotá', state: 'Cundinamarca'),
      ),
      guardianInfo: GuardianInfo(
        name: 'Carlos',
        relationship: 'Padre',
        phone: '300',
      ),
      medicalHistory: history,
    );

MedicalHistoryItem _encounter({
  PractitionerInfo? practitioner,
  ProviderInfo? provider,
  String? physician,
  String? location,
  String startDateTime = '2024-06-01T09:00:00',
  String diagnosisType = '01',
  String careModality = '01',
  String? dischargeDisposition,
}) => MedicalHistoryItem(
  startDateTime: startDateTime,
  practitioner: practitioner,
  provider: provider,
  physician: physician,
  location: location,
  diagnosisType: diagnosisType,
  careModality: careModality,
  dischargeDisposition: dischargeDisposition,
);

PractitionerInfo _practitioner({
  String docType = 'CC',
  String docNumber = '99999',
  String name = 'Dr. Ramírez',
}) => PractitionerInfo(
  documentType: docType,
  documentNumber: docNumber,
  name: name,
);

ProviderInfo _provider({
  String repsCode = 'REPS-01',
  String name = 'Clínica Central',
}) => ProviderInfo(repsCode: repsCode, name: name);

// =============================================================================
// UNIT TESTS
// =============================================================================

void main() {
  group('No medical history — all fields fallback to defaults', () {
    late InitialValues init;

    setUp(() {
      init = resolveInitialValues(_patient());
    });

    test('practitionerName is an empty string', () {
      expect(init.practitionerName, '');
    });

    test('practitionerDocNumber is an empty string', () {
      expect(init.practitionerDocNumber, '');
    });

    test('practitionerDocType defaults to CC', () {
      expect(init.practitionerDocType, 'CC');
    });

    test('providerName is an empty string', () {
      expect(init.providerName, '');
    });

    test('providerRepsCode is an empty string', () {
      expect(init.providerRepsCode, '');
    });

    test('date is an empty string', () {
      expect(init.date, '');
    });

    test('diagnosisType defaults to 01', () {
      expect(init.diagnosisType, '01');
    });

    test('careModality defaults to 01', () {
      expect(init.careModality, '01');
    });

    test('dischargeDisposition defaults to 04', () {
      expect(init.dischargeDisposition, '04');
    });
  });

  group('With a complete practitioner record', () {
    late InitialValues init;

    setUp(() {
      init = resolveInitialValues(
        _patient(
          history: [
            _encounter(
              practitioner: _practitioner(
                docType: 'CE',
                docNumber: '88888',
                name: 'Dr. López',
              ),
            ),
          ],
        ),
      );
    });

    test('practitionerName resolves to practitioner name', () {
      expect(init.practitionerName, 'Dr. López');
    });

    test('practitionerDocNumber resolves to practitioner document number', () {
      expect(init.practitionerDocNumber, '88888');
    });

    test(
      'practitionerDocType resolves to CE (valid type within _docTypes)',
      () {
        expect(init.practitionerDocType, 'CE');
      },
    );
  });

  group('Practitioner with an invalid document type → fallback to CC', () {
    test('practitionerDocType defaults to CC when type is TI (not in map)', () {
      final init = resolveInitialValues(
        _patient(
          history: [_encounter(practitioner: _practitioner(docType: 'TI'))],
        ),
      );
      expect(init.practitionerDocType, 'CC');
    });

    test('practitionerDocType defaults to CC when type is an empty string', () {
      final init = resolveInitialValues(
        _patient(
          history: [_encounter(practitioner: _practitioner(docType: ''))],
        ),
      );
      expect(init.practitionerDocType, 'CC');
    });

    test('practitionerDocType accepts PA (present in _docTypes)', () {
      final init = resolveInitialValues(
        _patient(
          history: [_encounter(practitioner: _practitioner(docType: 'PA'))],
        ),
      );
      expect(init.practitionerDocType, 'PA');
    });
  });

  group('Legacy fallback: physician value when practitioner is null', () {
    test(
      'practitionerName falls back to physician when practitioner is missing',
      () {
        final init = resolveInitialValues(
          _patient(history: [_encounter(physician: 'Dr. Legacy')]),
        );
        expect(init.practitionerName, 'Dr. Legacy');
      },
    );

    test('practitionerName is empty when physician is also null', () {
      final init = resolveInitialValues(_patient(history: [_encounter()]));
      expect(init.practitionerName, '');
    });

    test('practitionerDocNumber is empty when practitioner is null', () {
      final init = resolveInitialValues(
        _patient(history: [_encounter(physician: 'X')]),
      );
      expect(init.practitionerDocNumber, '');
    });
  });

  group('With a complete provider record', () {
    late InitialValues init;

    setUp(() {
      init = resolveInitialValues(
        _patient(
          history: [
            _encounter(
              provider: _provider(repsCode: 'REPS-99', name: 'Hospital Norte'),
            ),
          ],
        ),
      );
    });

    test('providerName resolves to provider name', () {
      expect(init.providerName, 'Hospital Norte');
    });

    test('providerRepsCode resolves to provider reps code', () {
      expect(init.providerRepsCode, 'REPS-99');
    });
  });

  group('Legacy fallback: location value when provider is null', () {
    test('providerName falls back to location when provider is missing', () {
      final init = resolveInitialValues(
        _patient(history: [_encounter(location: 'Clínica Legacy')]),
      );
      expect(init.providerName, 'Clínica Legacy');
    });

    test('providerName is empty when location is also null', () {
      final init = resolveInitialValues(_patient(history: [_encounter()]));
      expect(init.providerName, '');
    });

    test('providerRepsCode is empty when provider is null', () {
      final init = resolveInitialValues(
        _patient(history: [_encounter(location: 'X')]),
      );
      expect(init.providerRepsCode, '');
    });
  });

  group('startDateTime parsing logic', () {
    test('date resolves to startDateTime from the latest encounter', () {
      final init = resolveInitialValues(
        _patient(history: [_encounter(startDateTime: '2024-06-01T09:00:00')]),
      );
      expect(init.date, '2024-06-01T09:00:00');
    });

    test('date is empty when startDateTime is an empty string', () {
      final init = resolveInitialValues(
        _patient(history: [_encounter(startDateTime: '')]),
      );
      expect(init.date, '');
    });
  });

  group('diagnosisType resolution logic', () {
    for (final code in ['01', '02', '03']) {
      test('accepts valid code: $code', () {
        final init = resolveInitialValues(
          _patient(history: [_encounter(diagnosisType: code)]),
        );
        expect(init.diagnosisType, code);
      });
    }

    test('defaults to 01 when code is missing from _diagTypes', () {
      final init = resolveInitialValues(
        _patient(history: [_encounter(diagnosisType: '99')]),
      );
      expect(init.diagnosisType, '01');
    });

    test('defaults to 01 when diagnosisType is an empty string', () {
      final init = resolveInitialValues(
        _patient(history: [_encounter(diagnosisType: '')]),
      );
      expect(init.diagnosisType, '01');
    });
  });

  group('careModality resolution logic', () {
    for (final code in ['01', '02', '05']) {
      test('accepts valid code: $code', () {
        final init = resolveInitialValues(
          _patient(history: [_encounter(careModality: code)]),
        );
        expect(init.careModality, code);
      });
    }

    test('defaults to 01 when code is missing from _careModalities', () {
      final init = resolveInitialValues(
        _patient(history: [_encounter(careModality: '03')]),
      );
      expect(init.careModality, '01');
    });

    test('defaults to 01 when careModality is an empty string', () {
      final init = resolveInitialValues(
        _patient(history: [_encounter(careModality: '')]),
      );
      expect(init.careModality, '01');
    });
  });

  group('dischargeDisposition resolution logic', () {
    for (final code in ['04', '01', '03']) {
      test('accepts valid code: $code', () {
        final init = resolveInitialValues(
          _patient(history: [_encounter(dischargeDisposition: code)]),
        );
        expect(init.dischargeDisposition, code);
      });
    }

    test('defaults to 04 when code is missing from _dischargeOpts', () {
      final init = resolveInitialValues(
        _patient(history: [_encounter(dischargeDisposition: '99')]),
      );
      expect(init.dischargeDisposition, '04');
    });

    test('defaults to 04 when dischargeDisposition is null', () {
      final init = resolveInitialValues(_patient(history: [_encounter()]));
      expect(init.dischargeDisposition, '04');
    });

    test('defaults to 04 when dischargeDisposition is an empty string', () {
      final init = resolveInitialValues(
        _patient(history: [_encounter(dischargeDisposition: '')]),
      );
      expect(init.dischargeDisposition, '04');
    });
  });

  group('Targeting the latest MedicalHistoryItem entry exclusively', () {
    test('uses the last item when multiple entries exist', () {
      final init = resolveInitialValues(
        _patient(
          history: [
            _encounter(
              practitioner: _practitioner(name: 'Dr. Primero'),
              startDateTime: '2023-01-01',
            ),
            _encounter(
              practitioner: _practitioner(name: 'Dr. Segundo'),
              startDateTime: '2024-06-01',
            ),
          ],
        ),
      );
      expect(init.practitionerName, 'Dr. Segundo');
      expect(init.date, '2024-06-01');
    });

    test('uses the single entry when only one encounter exists', () {
      final init = resolveInitialValues(
        _patient(
          history: [_encounter(practitioner: _practitioner(name: 'Dr. Único'))],
        ),
      );
      expect(init.practitionerName, 'Dr. Único');
    });
  });

  group('Fully populated encounter payload mapping validation', () {
    test('all fields map to their corresponding data points successfully', () {
      final init = resolveInitialValues(
        _patient(
          history: [
            _encounter(
              practitioner: _practitioner(
                docType: 'PA',
                docNumber: '77777',
                name: 'Dra. Torres',
              ),
              provider: _provider(repsCode: 'REPS-55', name: 'IPS Sur'),
              startDateTime: '2024-12-25T08:30:00',
              diagnosisType: '03',
              careModality: '05',
              dischargeDisposition: '03',
            ),
          ],
        ),
      );

      expect(init.practitionerName, 'Dra. Torres');
      expect(init.practitionerDocNumber, '77777');
      expect(init.practitionerDocType, 'PA');
      expect(init.providerName, 'IPS Sur');
      expect(init.providerRepsCode, 'REPS-55');
      expect(init.date, '2024-12-25T08:30:00');
      expect(init.diagnosisType, '03');
      expect(init.careModality, '05');
      expect(init.dischargeDisposition, '03');
    });
  });
}
