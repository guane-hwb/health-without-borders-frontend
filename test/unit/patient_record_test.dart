// test/unit/patient_record_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

void main() {
  // =========================================================================
  // Address
  // =========================================================================
  group('Address', () {
    test('constructor con todos los campos', () {
      final address = Address(
        street: 'Calle 123',
        city: 'Bogotá',
        cityCode: '11001',
        state: 'Cundinamarca',
        zipCode: '110111',
        country: 'COL',
        countryName: 'Colombia',
        zone: '01',
      );

      expect(address.street, 'Calle 123');
      expect(address.city, 'Bogotá');
      expect(address.cityCode, '11001');
      expect(address.state, 'Cundinamarca');
      expect(address.zipCode, '110111');
      expect(address.country, 'COL');
      expect(address.countryName, 'Colombia');
      expect(address.zone, '01');
    });

    test('constructor con campos mínimos — defaults correctos', () {
      final address = Address(city: 'Medellín', state: 'Antioquia');
      expect(address.country, 'COL');
      expect(address.street, isNull);
    });

    test('fromJson — todos los campos presentes', () {
      final json = <String, dynamic>{
        'street': 'Av. El Dorado',
        'city': 'Bogotá',
        'cityCode': '11001',
        'state': 'Cundinamarca',
        'zipCode': '110111',
        'country': 'COL',
        'countryName': 'Colombia',
        'zone': '02',
      };
      final address = Address.fromJson(json);
      expect(address.street, 'Av. El Dorado');
      expect(address.zone, '02');
      expect(address.countryName, 'Colombia');
    });

    test('fromJson — campos opcionales ausentes usan defaults', () {
      final json = <String, dynamic>{'city': 'Cali', 'state': 'Valle'};
      final address = Address.fromJson(json);
      expect(address.country, 'COL');
      expect(address.street, isNull);
      expect(address.zipCode, isNull);
    });

    test('toJson — incluye sólo campos no-null', () {
      final address = Address(city: 'Cali', state: 'Valle');
      final json = address.toJson();
      expect(json['city'], 'Cali');
      expect(json['state'], 'Valle');
      expect(json['country'], 'COL');
      expect(json.containsKey('street'), isFalse);
      expect(json.containsKey('zipCode'), isFalse);
    });

    test('toJson — incluye campos opcionales cuando no son null', () {
      final address = Address(
        street: 'Cra 7',
        city: 'Bogotá',
        cityCode: '11001',
        state: 'Cundinamarca',
        zipCode: '110111',
        countryName: 'Colombia',
        zone: '01',
      );
      final json = address.toJson();
      expect(json.containsKey('street'), isTrue);
      expect(json.containsKey('cityCode'), isTrue);
      expect(json.containsKey('zipCode'), isTrue);
      expect(json.containsKey('countryName'), isTrue);
      expect(json.containsKey('zone'), isTrue);
    });
  });

  // =========================================================================
  // PatientIdentification
  // =========================================================================
  group('PatientIdentification', () {
    test('constructor', () {
      final id = PatientIdentification(
        documentType: 'CC',
        documentNumber: '123456',
      );
      expect(id.documentType, 'CC');
      expect(id.documentNumber, '123456');
    });

    test('fromJson — campos presentes', () {
      final id = PatientIdentification.fromJson(<String, dynamic>{
        'documentType': 'TI',
        'documentNumber': '987654',
      });
      expect(id.documentType, 'TI');
      expect(id.documentNumber, '987654');
    });

    test('fromJson — campos ausentes usan defaults', () {
      final id = PatientIdentification.fromJson(<String, dynamic>{});
      expect(id.documentType, 'MS');
      expect(id.documentNumber, '');
    });

    test('toJson — roundtrip', () {
      final original = PatientIdentification(
        documentType: 'PA',
        documentNumber: 'A001',
      );
      final json = original.toJson();
      expect(json['documentType'], 'PA');
      expect(json['documentNumber'], 'A001');
    });
  });

  // =========================================================================
  // PatientInfo
  // =========================================================================
  group('PatientInfo', () {
    test('constructor con todos los campos', () {
      final info = PatientInfo(
        identification: _buildId(),
        firstLastName: 'García',
        secondLastName: 'López',
        firstName: 'Ana',
        secondName: 'María',
        dob: '2000-01-15',
        nationalityCode: 'COL',
        nationalityName: 'Colombia',
        biologicalSex: 'F',
        genderIdentity: '01',
        ethnicity: '02',
        ethnicCommunity: 'comunidad',
        disabilityCategory: '00',
        address: _buildAddress(),
        bloodType: 'O+',
        weight: 55.0,
        height: 1.65,
      );
      expect(info.firstLastName, 'García');
      expect(info.weight, 55.0);
    });

    test('fullName — con segundo nombre y segundo apellido', () {
      final info = PatientInfo(
        identification: _buildId(),
        firstLastName: 'García',
        secondLastName: 'López',
        firstName: 'Ana',
        secondName: 'María',
        dob: '2000-01-15',
        biologicalSex: 'F',
        address: _buildAddress(),
      );
      expect(info.fullName, 'Ana María García López');
    });

    test('fullName — sin segundo nombre ni segundo apellido', () {
      final info = PatientInfo(
        identification: _buildId(),
        firstLastName: 'García',
        firstName: 'Ana',
        dob: '2000-01-15',
        biologicalSex: 'F',
        address: _buildAddress(),
      );
      expect(info.fullName, 'Ana García');
    });

    test('fullName — segundo nombre vacío es ignorado', () {
      final info = PatientInfo(
        identification: _buildId(),
        firstLastName: 'García',
        secondLastName: '',
        firstName: 'Ana',
        secondName: '',
        dob: '2000-01-15',
        biologicalSex: 'F',
        address: _buildAddress(),
      );
      expect(info.fullName, 'Ana García');
    });

    test('copyWith — sobreescribe weight y height', () {
      final original = PatientInfo(
        identification: _buildId(),
        firstLastName: 'García',
        firstName: 'Ana',
        dob: '2000-01-15',
        biologicalSex: 'F',
        address: _buildAddress(),
        weight: 50.0,
        height: 1.60,
      );
      final copy = original.copyWith(weight: 55.0, height: 1.62);
      expect(copy.weight, 55.0);
      expect(copy.height, 1.62);
      expect(copy.firstName, 'Ana');
    });

    test('copyWith — sin argumentos conserva valores originales', () {
      final original = PatientInfo(
        identification: _buildId(),
        firstLastName: 'García',
        firstName: 'Ana',
        dob: '2000-01-15',
        biologicalSex: 'F',
        address: _buildAddress(),
        weight: 50.0,
      );
      final copy = original.copyWith();
      expect(copy.weight, 50.0);
    });

    test('fromJson — todos los campos', () {
      final json = <String, dynamic>{
        'identification': {'documentType': 'CC', 'documentNumber': '111'},
        'firstLastName': 'Pérez',
        'secondLastName': 'Gómez',
        'firstName': 'Juan',
        'secondName': 'Carlos',
        'dob': '1990-06-15',
        'nationalityCode': 'COL',
        'nationalityName': 'Colombia',
        'biologicalSex': 'M',
        'genderIdentity': '01',
        'ethnicity': '01',
        'ethnicCommunity': 'indigena',
        'disabilityCategory': '01',
        'address': {'city': 'Bogotá', 'state': 'Cundinamarca'},
        'bloodType': 'A+',
        'weight': 70.5,
        'height': 1.75,
      };
      final info = PatientInfo.fromJson(json);
      expect(info.firstLastName, 'Pérez');
      expect(info.weight, 70.5);
      expect(info.height, 1.75);
      expect(info.biologicalSex, 'M');
    });

    test('fromJson — identificación no es Map usa fallback', () {
      final json = <String, dynamic>{
        'firstLastName': 'Pérez',
        'firstName': 'Juan',
        'dob': '1990-06-15',
        'biologicalSex': 'M',
        'address': {'city': 'Cali', 'state': 'Valle'},
      };
      final info = PatientInfo.fromJson(json);
      expect(info.identification.documentType, 'MS');
      expect(info.identification.documentNumber, '');
    });

    test('fromJson — address no es Map usa fallback', () {
      final json = <String, dynamic>{
        'identification': {'documentType': 'CC', 'documentNumber': '111'},
        'firstLastName': 'Pérez',
        'firstName': 'Juan',
        'dob': '1990-06-15',
        'biologicalSex': 'M',
      };
      final info = PatientInfo.fromJson(json);
      expect(info.address.city, '');
      expect(info.address.state, '');
    });

    test('toJson — campos opcionales presentes', () {
      final info = PatientInfo(
        identification: _buildId(),
        firstLastName: 'García',
        secondLastName: 'López',
        firstName: 'Ana',
        secondName: 'María',
        dob: '2000-01-15',
        nationalityName: 'Colombia',
        biologicalSex: 'F',
        genderIdentity: '01',
        ethnicity: '02',
        ethnicCommunity: 'comunidad',
        disabilityCategory: '00',
        address: _buildAddress(),
        bloodType: 'O+',
        weight: 55.0,
        height: 1.65,
      );
      final json = info.toJson();
      expect(json.containsKey('secondLastName'), isTrue);
      expect(json.containsKey('secondName'), isTrue);
      expect(json.containsKey('nationalityName'), isTrue);
      expect(json.containsKey('genderIdentity'), isTrue);
      expect(json.containsKey('ethnicity'), isTrue);
      expect(json.containsKey('ethnicCommunity'), isTrue);
      expect(json.containsKey('disabilityCategory'), isTrue);
      expect(json.containsKey('bloodType'), isTrue);
      expect(json.containsKey('weight'), isTrue);
      expect(json.containsKey('height'), isTrue);
    });

    test('toJson — campos opcionales ausentes no aparecen', () {
      final info = PatientInfo(
        identification: _buildId(),
        firstLastName: 'García',
        firstName: 'Ana',
        dob: '2000-01-15',
        biologicalSex: 'F',
        address: _buildAddress(),
      );
      final json = info.toJson();
      expect(json.containsKey('secondLastName'), isFalse);
      expect(json.containsKey('bloodType'), isFalse);
    });
  });

  // =========================================================================
  // GuardianConsent
  // =========================================================================
  group('GuardianConsent', () {
    test('fromJson — todos los campos', () {
      final consent = GuardianConsent.fromJson(<String, dynamic>{
        'accepted': true,
        'acceptedAt': '2024-01-01T10:00:00',
        'email': 'padre@mail.com',
        'signatureBase64': 'abc123',
      });
      expect(consent.accepted, isTrue);
      expect(consent.email, 'padre@mail.com');
      expect(consent.signatureBase64, 'abc123');
    });

    test('fromJson — accepted=false y campos opcionales ausentes', () {
      final consent = GuardianConsent.fromJson(<String, dynamic>{
        'accepted': false,
        'acceptedAt': '2024-01-01',
      });
      expect(consent.accepted, isFalse);
      expect(consent.email, isNull);
      expect(consent.signatureBase64, isNull);
    });

    test('toJson — con email y firma', () {
      final consent = GuardianConsent(
        accepted: true,
        acceptedAt: '2024-01-01',
        email: 'test@mail.com',
        signatureBase64: 'sig',
      );
      final json = consent.toJson();
      expect(json['accepted'], isTrue);
      expect(json.containsKey('email'), isTrue);
      expect(json.containsKey('signatureBase64'), isTrue);
    });

    test('toJson — sin opcionales', () {
      final consent = GuardianConsent(accepted: false, acceptedAt: '2024');
      final json = consent.toJson();
      expect(json.containsKey('email'), isFalse);
      expect(json.containsKey('signatureBase64'), isFalse);
    });
  });

  // =========================================================================
  // GuardianInfo
  // =========================================================================
  group('GuardianInfo', () {
    test('fromJson — todos los campos incluyendo consent', () {
      final gi = GuardianInfo.fromJson(<String, dynamic>{
        'name': 'Pedro',
        'relationship': 'Padre',
        'phone': '3001234567',
        'device_uid': 'ABC123',
        'documentType': 'CC',
        'documentNumber': '555',
        'consent': {'accepted': true, 'acceptedAt': '2024-01-01'},
      });
      expect(gi.name, 'Pedro');
      expect(gi.deviceUid, 'ABC123');
      expect(gi.consent, isNotNull);
      expect(gi.consent!.accepted, isTrue);
    });

    test('fromJson — consent no es Map queda null', () {
      final gi = GuardianInfo.fromJson(<String, dynamic>{
        'name': 'María',
        'relationship': 'Madre',
        'phone': '300',
      });
      expect(gi.consent, isNull);
    });

    test('toJson — incluye campos opcionales', () {
      final gi = GuardianInfo(
        name: 'Pedro',
        relationship: 'Padre',
        phone: '300',
        deviceUid: 'UID1',
        documentType: 'CC',
        documentNumber: '555',
        consent: GuardianConsent(accepted: true, acceptedAt: '2024'),
      );
      final json = gi.toJson();
      expect(json.containsKey('device_uid'), isTrue);
      expect(json.containsKey('documentType'), isTrue);
      expect(json.containsKey('consent'), isTrue);
    });

    test('toJson — sin campos opcionales', () {
      final gi = GuardianInfo(
        name: 'María',
        relationship: 'Madre',
        phone: '300',
      );
      final json = gi.toJson();
      expect(json.containsKey('device_uid'), isFalse);
      expect(json.containsKey('documentType'), isFalse);
      expect(json.containsKey('consent'), isFalse);
    });
  });

  // =========================================================================
  // FamilyHistoryItem
  // =========================================================================
  group('FamilyHistoryItem', () {
    test('fromJson — con códigos CIE', () {
      final item = FamilyHistoryItem.fromJson(<String, dynamic>{
        'conditionCie10Code': 'E11',
        'conditionCie11Code': '5A11',
        'conditionDescription': 'Diabetes tipo 2',
        'relationship': '01',
      });
      expect(item.conditionCie10Code, 'E11');
      expect(item.conditionCie11Code, '5A11');
    });

    test('fromJson — sin códigos CIE', () {
      final item = FamilyHistoryItem.fromJson(<String, dynamic>{
        'conditionDescription': 'HTA',
        'relationship': '02',
      });
      expect(item.conditionCie10Code, isNull);
    });

    test('toJson — incluye/excluye códigos según null', () {
      final withCodes = FamilyHistoryItem(
        conditionCie10Code: 'I10',
        conditionCie11Code: 'BA80',
        conditionDescription: 'HTA',
        relationship: '01',
      );
      expect(withCodes.toJson().containsKey('conditionCie10Code'), isTrue);

      final withoutCodes = FamilyHistoryItem(
        conditionDescription: 'HTA',
        relationship: '01',
      );
      expect(withoutCodes.toJson().containsKey('conditionCie10Code'), isFalse);
    });
  });

  // =========================================================================
  // ChronicConditionItem
  // =========================================================================
  group('ChronicConditionItem', () {
    test('fromJson — con y sin códigos', () {
      final withCodes = ChronicConditionItem.fromJson(<String, dynamic>{
        'chronicDescription': 'Asma',
        'chronicCie10Code': 'J45',
        'chronicCie11Code': 'CA23',
      });
      expect(withCodes.chronicCie10Code, 'J45');

      final noCodes = ChronicConditionItem.fromJson(<String, dynamic>{
        'chronicDescription': 'Asma',
      });
      expect(noCodes.chronicCie10Code, isNull);
    });

    test('toJson — incluye/excluye códigos', () {
      final item = ChronicConditionItem(
        chronicDescription: 'Asma',
        chronicCie10Code: 'J45',
        chronicCie11Code: 'CA23',
      );
      final json = item.toJson();
      expect(json.containsKey('chronicCie10Code'), isTrue);
      expect(json.containsKey('chronicCie11Code'), isTrue);

      final itemNoCodes = ChronicConditionItem(chronicDescription: 'Asma');
      final jsonNoCodes = itemNoCodes.toJson();
      expect(jsonNoCodes.containsKey('chronicCie10Code'), isFalse);
    });
  });

  // =========================================================================
  // MedicationStatementItem
  // =========================================================================
  group('MedicationStatementItem', () {
    test('fromJson — todos los campos', () {
      final med = MedicationStatementItem.fromJson(<String, dynamic>{
        'medicationName': 'Metformina',
        'dciCode': '01234',
        'status': 'active',
        'dosage': '500mg',
        'notes': 'Con comida',
      });
      expect(med.medicationName, 'Metformina');
      expect(med.dciCode, '01234');
      expect(med.dosage, '500mg');
    });

    test('fromJson — campos opcionales ausentes', () {
      final med = MedicationStatementItem.fromJson(<String, dynamic>{
        'medicationName': 'Ibuprofeno',
      });
      expect(med.dciCode, isNull);
      expect(med.status, 'active');
    });

    test('toJson — incluye/excluye opcionales', () {
      final full = MedicationStatementItem(
        medicationName: 'Metformina',
        dciCode: '01234',
        dosage: '500mg',
        notes: 'Con comida',
      );
      final json = full.toJson();
      expect(json.containsKey('dciCode'), isTrue);
      expect(json.containsKey('dosage'), isTrue);
      expect(json.containsKey('notes'), isTrue);

      final minimal = MedicationStatementItem(medicationName: 'Ibuprofeno');
      final minJson = minimal.toJson();
      expect(minJson.containsKey('dciCode'), isFalse);
      expect(minJson.containsKey('notes'), isFalse);
    });
  });

  // =========================================================================
  // BackgroundHistory
  // =========================================================================
  group('BackgroundHistory', () {
    test('fromJson — chronicConditions como List', () {
      final bh = BackgroundHistory.fromJson(<String, dynamic>{
        'chronicConditions': [
          {'chronicDescription': 'Asma'},
        ],
        'personalHistory': 'Sin novedad',
        'familyHistory': [
          {'conditionDescription': 'HTA', 'relationship': '01'},
        ],
        'familyHistoryNotes': 'Paterno',
        'medications': [
          {'medicationName': 'Salbutamol'},
        ],
      });
      expect(bh.chronicConditions.length, 1);
      expect(bh.familyHistory.length, 1);
      expect(bh.medications.length, 1);
      expect(bh.personalHistory, 'Sin novedad');
      expect(bh.familyHistoryNotes, 'Paterno');
    });

    test(
      'fromJson — chronicConditions null usa lista vacía (rama defensiva)',
      () {
        final bh = BackgroundHistory.fromJson(<String, dynamic>{
          'chronicConditions': null,
          'medications': null,
        });
        expect(bh.chronicConditions, isEmpty);
        expect(bh.medications, isEmpty);
      },
    );

    test(
      'fromJson — chronicConditions String usa lista vacía (rama defensiva)',
      () {
        final bh = BackgroundHistory.fromJson(<String, dynamic>{
          'chronicConditions': 'ninguna',
          'medications': 'ninguno',
        });
        expect(bh.chronicConditions, isEmpty);
        expect(bh.medications, isEmpty);
      },
    );

    test('toJson — campos opcionales', () {
      final bh = BackgroundHistory(
        personalHistory: 'nada',
        familyHistoryNotes: 'notas',
      );
      final json = bh.toJson();
      expect(json.containsKey('personalHistory'), isTrue);
      expect(json.containsKey('familyHistoryNotes'), isTrue);

      final bh2 = BackgroundHistory();
      final json2 = bh2.toJson();
      expect(json2.containsKey('personalHistory'), isFalse);
      expect(json2.containsKey('familyHistoryNotes'), isFalse);
    });
  });

  // =========================================================================
  // AllergyInfo
  // =========================================================================
  group('AllergyInfo', () {
    test('fromJson — todos los campos', () {
      final a = AllergyInfo.fromJson(<String, dynamic>{
        'category': '01',
        'allergen': 'Penicilina',
        'reaction': 'Rash',
        'notes': 'Severa',
      });
      expect(a.reaction, 'Rash');
      expect(a.notes, 'Severa');
    });

    test('fromJson — sin opcionales', () {
      final a = AllergyInfo.fromJson(<String, dynamic>{'allergen': 'Maní'});
      expect(a.category, '06');
      expect(a.reaction, isNull);
    });

    test('toJson — incluye/excluye opcionales', () {
      final full = AllergyInfo(
        category: '02',
        allergen: 'Maní',
        reaction: 'Anafilaxia',
        notes: 'Urgencia',
      );
      final json = full.toJson();
      expect(json.containsKey('reaction'), isTrue);
      expect(json.containsKey('notes'), isTrue);

      final minimal = AllergyInfo(category: '02', allergen: 'Maní');
      expect(minimal.toJson().containsKey('reaction'), isFalse);
    });
  });

  // =========================================================================
  // VaccinationRecordItem
  // =========================================================================
  group('VaccinationRecordItem', () {
    test('fromJson — todos los campos', () {
      final v = VaccinationRecordItem.fromJson(<String, dynamic>{
        'vaccinationId': 'uuid-001',
        'date': '2023-01-10',
        'vaccineName': 'BCG',
        'vaccineCode': '19',
        'dose': 1,
        'administratedBy': 'Enfermera',
        'administratedAt': 'Clínica',
        'status': 'completed',
      });
      expect(v.vaccinationId, 'uuid-001');
      expect(v.dose, 1);
    });

    test('fromJson — dose ausente usa default 1', () {
      final v = VaccinationRecordItem.fromJson(<String, dynamic>{
        'date': '2023-01-10',
        'vaccineName': 'BCG',
        'vaccineCode': '19',
        'administratedBy': 'Enfermera',
        'administratedAt': 'Clínica',
      });
      expect(v.dose, 1);
      expect(v.status, 'completed');
    });

    test('toJson — incluye/excluye vaccinationId', () {
      final withId = VaccinationRecordItem(
        vaccinationId: 'uid',
        date: '2023-01-10',
        vaccineName: 'BCG',
        vaccineCode: '19',
        dose: 1,
        administratedBy: 'E',
        administratedAt: 'C',
      );
      expect(withId.toJson().containsKey('vaccinationId'), isTrue);

      final noId = VaccinationRecordItem(
        date: '2023-01-10',
        vaccineName: 'BCG',
        vaccineCode: '19',
        dose: 1,
        administratedBy: 'E',
        administratedAt: 'C',
      );
      expect(noId.toJson().containsKey('vaccinationId'), isFalse);
    });
  });

  // =========================================================================
  // ClinicalEvaluation
  // =========================================================================
  group('ClinicalEvaluation', () {
    test('constructor sin argumentos — todos null', () {
      final ce = ClinicalEvaluation();
      expect(ce.historyOfCurrentIllness, isNull);
    });

    test('fromJson — todos los campos', () {
      final ce = ClinicalEvaluation.fromJson(<String, dynamic>{
        'historyOfCurrentIllness': 'Fiebre 3 días',
        'generalPhysicalExamination': 'Normal',
        'systemsExamination': 'Sin alteraciones',
        'treatmentPlanObservations': 'Reposo',
      });
      expect(ce.historyOfCurrentIllness, 'Fiebre 3 días');
      expect(ce.treatmentPlanObservations, 'Reposo');
    });

    test('fromJson — sin campos usa null', () {
      final ce = ClinicalEvaluation.fromJson(<String, dynamic>{});
      expect(ce.historyOfCurrentIllness, isNull);
    });

    test('toJson — incluye sólo campos no-null', () {
      final ce = ClinicalEvaluation(historyOfCurrentIllness: 'Tos');
      final json = ce.toJson();
      expect(json.containsKey('historyOfCurrentIllness'), isTrue);
      expect(json.containsKey('generalPhysicalExamination'), isFalse);
      expect(json.containsKey('systemsExamination'), isFalse);
      expect(json.containsKey('treatmentPlanObservations'), isFalse);
    });

    test('toJson — todos presentes', () {
      final ce = ClinicalEvaluation(
        historyOfCurrentIllness: 'H',
        generalPhysicalExamination: 'G',
        systemsExamination: 'S',
        treatmentPlanObservations: 'T',
      );
      final json = ce.toJson();
      expect(json.keys.length, 4);
    });
  });

  // =========================================================================
  // DiagnosisItem
  // =========================================================================
  group('DiagnosisItem', () {
    test('fromJson — con icd11Code', () {
      final d = DiagnosisItem.fromJson(<String, dynamic>{
        'icd10Code': 'J06.9',
        'icd11Code': 'CA0Z',
        'description': 'IRA',
      });
      expect(d.icd11Code, 'CA0Z');
    });

    test('fromJson — sin icd11Code', () {
      final d = DiagnosisItem.fromJson(<String, dynamic>{
        'icd10Code': 'J06.9',
        'description': 'IRA',
      });
      expect(d.icd11Code, isNull);
    });

    test('toJson — incluye/excluye icd11Code', () {
      final withCode = DiagnosisItem(
        icd10Code: 'J06.9',
        icd11Code: 'CA0Z',
        description: 'IRA',
      );
      expect(withCode.toJson().containsKey('icd11Code'), isTrue);

      final noCode = DiagnosisItem(icd10Code: 'J06.9', description: 'IRA');
      expect(noCode.toJson().containsKey('icd11Code'), isFalse);
    });
  });

  // =========================================================================
  // RiskFactor
  // =========================================================================
  group('RiskFactor', () {
    test('constructor y toJson', () {
      final rf = RiskFactor(type: '01', name: 'Tabaquismo');
      expect(rf.type, '01');
      final json = rf.toJson();
      expect(json['type'], '01');
      expect(json['name'], 'Tabaquismo');
    });

    test('fromJson — defaults', () {
      final rf = RiskFactor.fromJson(<String, dynamic>{});
      expect(rf.type, '06');
      expect(rf.name, '');
    });
  });

  // =========================================================================
  // IncapacityInfo
  // =========================================================================
  group('IncapacityInfo', () {
    test('fromJson — con maternityLeaveDays', () {
      final ii = IncapacityInfo.fromJson(<String, dynamic>{
        'scope': '02',
        'days': 30,
        'maternityLeaveDays': 98,
      });
      expect(ii.scope, '02');
      expect(ii.days, 30);
      expect(ii.maternityLeaveDays, 98);
    });

    test('fromJson — sin maternity', () {
      final ii = IncapacityInfo.fromJson(<String, dynamic>{
        'scope': '01',
        'days': 5,
      });
      expect(ii.maternityLeaveDays, isNull);
    });

    test('toJson — incluye/excluye maternityLeaveDays', () {
      final with_ = IncapacityInfo(scope: '01', days: 3, maternityLeaveDays: 7);
      expect(with_.toJson().containsKey('maternityLeaveDays'), isTrue);

      final without = IncapacityInfo(scope: '01', days: 3);
      expect(without.toJson().containsKey('maternityLeaveDays'), isFalse);
    });
  });

  // =========================================================================
  // PractitionerInfo
  // =========================================================================
  group('PractitionerInfo', () {
    test('fromJson — todos los campos', () {
      final p = PractitionerInfo.fromJson(<String, dynamic>{
        'documentType': 'CC',
        'documentNumber': '999',
        'name': 'Dr. Ruiz',
        'firstName': 'Carlos',
        'secondName': 'Alberto',
        'firstLastName': 'Ruiz',
        'secondLastName': 'Mora',
      });
      expect(p.firstName, 'Carlos');
      expect(p.secondLastName, 'Mora');
    });

    test('fromJson — campos opcionales ausentes', () {
      final p = PractitionerInfo.fromJson(<String, dynamic>{
        'documentType': 'CC',
        'documentNumber': '999',
        'name': 'Dr. Ruiz',
      });
      expect(p.firstName, isNull);
    });

    test('toJson — incluye/excluye opcionales', () {
      final full = PractitionerInfo(
        documentType: 'CC',
        documentNumber: '999',
        name: 'Dr. Ruiz',
        firstName: 'Carlos',
        secondName: 'Alberto',
        firstLastName: 'Ruiz',
        secondLastName: 'Mora',
      );
      final json = full.toJson();
      expect(json.containsKey('firstName'), isTrue);
      expect(json.containsKey('secondLastName'), isTrue);

      final minimal = PractitionerInfo(
        documentType: 'CC',
        documentNumber: '999',
        name: 'Dr. Ruiz',
      );
      expect(minimal.toJson().containsKey('firstName'), isFalse);
    });
  });

  // =========================================================================
  // ProviderInfo
  // =========================================================================
  group('ProviderInfo', () {
    test('fromJson — todos los campos', () {
      final p = ProviderInfo.fromJson(<String, dynamic>{
        'repsCode': 'REP001',
        'name': 'Clínica',
        'nitNumber': '900111',
        'locationSeatCode': 'S01',
      });
      expect(p.nitNumber, '900111');
      expect(p.locationSeatCode, 'S01');
    });

    test('fromJson — sin opcionales', () {
      final p = ProviderInfo.fromJson(<String, dynamic>{
        'repsCode': 'REP001',
        'name': 'Clínica',
      });
      expect(p.nitNumber, isNull);
      expect(p.locationSeatCode, isNull);
    });

    test('toJson — incluye/excluye opcionales', () {
      final full = ProviderInfo(
        repsCode: 'REP001',
        name: 'Clínica',
        nitNumber: '900',
        locationSeatCode: 'S01',
      );
      expect(full.toJson().containsKey('nitNumber'), isTrue);

      final minimal = ProviderInfo(repsCode: 'REP001', name: 'Clínica');
      expect(minimal.toJson().containsKey('nitNumber'), isFalse);
    });
  });

  // =========================================================================
  // PayerInfo
  // =========================================================================
  group('PayerInfo', () {
    test('fromJson — con campos', () {
      final p = PayerInfo.fromJson(<String, dynamic>{
        'code': 'EPS001',
        'name': 'Sura',
      });
      expect(p.code, 'EPS001');
      expect(p.name, 'Sura');
    });

    test('fromJson — sin campos', () {
      final p = PayerInfo.fromJson(<String, dynamic>{});
      expect(p.code, isNull);
      expect(p.name, isNull);
    });

    test('toJson', () {
      final p = PayerInfo(code: 'EPS001', name: 'Sura');
      expect(p.toJson().containsKey('code'), isTrue);

      final empty = PayerInfo();
      expect(empty.toJson().containsKey('code'), isFalse);
    });
  });

  // =========================================================================
  // MedicalHistoryItem
  // =========================================================================
  group('MedicalHistoryItem', () {
    test('constructor con clinicalEvaluation null usa default', () {
      final item = MedicalHistoryItem(startDateTime: '2024-01-01T09:00:00');
      expect(item.clinicalEvaluation, isNotNull);
      expect(item.type, 'Consultation');
    });

    test('fromJson — todos los campos', () {
      final item = MedicalHistoryItem.fromJson(<String, dynamic>{
        'encounterIdentifier': 'enc-001',
        'type': 'Consultation',
        'startDateTime': '2024-01-01T09:00:00',
        'endDateTime': '2024-01-01T10:00:00',
        'careModality': '01',
        'serviceGroup': '01',
        'careEnvironment': '05',
        'entryRoute': '01',
        'externalCause': '01',
        'provider': {'repsCode': 'REP001', 'name': 'Clínica'},
        'practitioner': {
          'documentType': 'CC',
          'documentNumber': '999',
          'name': 'Dr. Ruiz',
        },
        'location': 'Consultorio 1',
        'physician': 'Dr. Ruiz',
        'clinicalEvaluation': {'historyOfCurrentIllness': 'Tos'},
        'diagnosis': [
          {'icd10Code': 'J06.9', 'description': 'IRA'},
        ],
        'diagnosisType': '01',
        'dischargeDisposition': '01',
        'riskFactors': [
          {'type': '01', 'name': 'Tabaquismo'},
        ],
        'incapacity': {'scope': '01', 'days': 3},
        'payer': {'code': 'EPS001', 'name': 'Sura'},
      });
      expect(item.encounterIdentifier, 'enc-001');
      expect(item.provider, isNotNull);
      expect(item.practitioner, isNotNull);
      expect(item.diagnosis.length, 1);
      expect(item.riskFactors.length, 1);
      expect(item.incapacity, isNotNull);
      expect(item.payer, isNotNull);
    });

    test('fromJson — provider/practitioner no Map quedan null', () {
      final item = MedicalHistoryItem.fromJson(<String, dynamic>{
        'startDateTime': '2024-01-01T09:00:00',
        'clinicalEvaluation': 'texto plano',
      });
      expect(item.provider, isNull);
      expect(item.practitioner, isNull);
    });

    test('fromJson — incapacity/payer no Map quedan null', () {
      final item = MedicalHistoryItem.fromJson(<String, dynamic>{
        'startDateTime': '2024-01-01T09:00:00',
        'incapacity': 'no aplica',
        'payer': null,
      });
      expect(item.incapacity, isNull);
      expect(item.payer, isNull);
    });

    test('toJson — campos opcionales presentes', () {
      final item = MedicalHistoryItem(
        encounterIdentifier: 'enc-001',
        startDateTime: '2024-01-01',
        endDateTime: '2024-01-01T10:00:00',
        entryRoute: '01',
        externalCause: '01',
        provider: ProviderInfo(repsCode: 'R', name: 'C'),
        practitioner: PractitionerInfo(
          documentType: 'CC',
          documentNumber: '1',
          name: 'Dr',
        ),
        location: 'Consultorio',
        physician: 'Dr',
        dischargeDisposition: '01',
        incapacity: IncapacityInfo(scope: '01', days: 1),
        payer: PayerInfo(code: 'EPS001'),
      );
      final json = item.toJson();
      expect(json.containsKey('encounterIdentifier'), isTrue);
      expect(json.containsKey('endDateTime'), isTrue);
      expect(json.containsKey('entryRoute'), isTrue);
      expect(json.containsKey('externalCause'), isTrue);
      expect(json.containsKey('provider'), isTrue);
      expect(json.containsKey('practitioner'), isTrue);
      expect(json.containsKey('location'), isTrue);
      expect(json.containsKey('physician'), isTrue);
      expect(json.containsKey('dischargeDisposition'), isTrue);
      expect(json.containsKey('incapacity'), isTrue);
      expect(json.containsKey('payer'), isTrue);
    });

    test('toJson — campos opcionales ausentes no aparecen', () {
      final item = MedicalHistoryItem(startDateTime: '2024-01-01');
      final json = item.toJson();
      expect(json.containsKey('encounterIdentifier'), isFalse);
      expect(json.containsKey('endDateTime'), isFalse);
      expect(json.containsKey('provider'), isFalse);
      expect(json.containsKey('incapacity'), isFalse);
    });
  });

  // =========================================================================
  // PatientFullRecord
  // =========================================================================
  group('PatientFullRecord', () {
    test('fromJson — todos los campos', () {
      final json = <String, dynamic>{
        'patientId': 'pid-001',
        'device_uid': 'dev-abc',
        'patientInfo': {
          'identification': {'documentType': 'CC', 'documentNumber': '1'},
          'firstLastName': 'García',
          'firstName': 'Ana',
          'dob': '2000-01-01',
          'biologicalSex': 'F',
          'address': {'city': 'Bogotá', 'state': 'Cundinamarca'},
        },
        'guardianInfo': {
          'name': 'Pedro',
          'relationship': 'Padre',
          'phone': '300',
        },
        'guardian2Info': {
          'name': 'Laura',
          'relationship': 'Madre',
          'phone': '301',
        },
        'backgroundHistory': <String, dynamic>{
          'chronicConditions': <String>[],
          'medications': <String>[],
        },
        'allergies': [
          {'category': '01', 'allergen': 'Penicilina'},
        ],
        'medicalHistory': [
          {'startDateTime': '2024-01-01T09:00:00'},
        ],
        'vaccinationRecord': [
          {
            'date': '2023-01-10',
            'vaccineName': 'BCG',
            'vaccineCode': '19',
            'dose': 1,
            'administratedBy': 'E',
            'administratedAt': 'C',
          },
        ],
      };
      final record = PatientFullRecord.fromJson(json);
      expect(record.patientId, 'pid-001');
      expect(record.guardian2Info, isNotNull);
      expect(record.backgroundHistory, isNotNull);
      expect(record.allergies.length, 1);
      expect(record.medicalHistory.length, 1);
      expect(record.vaccinationRecord.length, 1);
    });

    test('fromJson — patientInfo no es Map usa fallback', () {
      final record = PatientFullRecord.fromJson(<String, dynamic>{
        'patientId': 'pid',
        'device_uid': 'dev',
        'guardianInfo': {
          'name': 'Pedro',
          'relationship': 'Padre',
          'phone': '300',
        },
      });
      expect(record.patientInfo.firstLastName, '');
      expect(record.patientInfo.biologicalSex, 'I');
    });

    test('fromJson — guardianInfo no es Map usa fallback', () {
      final record = PatientFullRecord.fromJson(<String, dynamic>{
        'patientId': 'pid',
        'device_uid': 'dev',
        'patientInfo': {
          'identification': {'documentType': 'CC', 'documentNumber': '1'},
          'firstLastName': 'García',
          'firstName': 'Ana',
          'dob': '2000-01-01',
          'biologicalSex': 'F',
          'address': {'city': 'Bogotá', 'state': 'Cundinamarca'},
        },
      });
      expect(record.guardianInfo.name, '');
    });

    test('fromJson — guardian2Info no es Map queda null', () {
      final record = PatientFullRecord.fromJson(<String, dynamic>{
        'patientId': 'pid',
        'device_uid': 'dev',
        'guardian2Info': 'no aplica',
      });
      expect(record.guardian2Info, isNull);
    });

    test('fromJson — backgroundHistory no es Map queda null', () {
      final record = PatientFullRecord.fromJson(<String, dynamic>{
        'patientId': 'pid',
        'device_uid': 'dev',
        'backgroundHistory': 'texto',
      });
      expect(record.backgroundHistory, isNull);
    });

    test('toJson — campos opcionales presentes', () {
      final record = PatientFullRecord(
        patientId: 'pid',
        deviceUid: 'dev',
        patientInfo: PatientInfo(
          identification: PatientIdentification(
            documentType: 'CC',
            documentNumber: '1',
          ),
          firstLastName: 'García',
          firstName: 'Ana',
          dob: '2000-01-01',
          biologicalSex: 'F',
          address: Address(city: 'Bogotá', state: 'Cundinamarca'),
        ),
        guardianInfo: GuardianInfo(
          name: 'Pedro',
          relationship: 'Padre',
          phone: '300',
        ),
        guardian2Info: GuardianInfo(
          name: 'Laura',
          relationship: 'Madre',
          phone: '301',
        ),
        backgroundHistory: BackgroundHistory(),
        allergies: [AllergyInfo(category: '01', allergen: 'Pen')],
        medicalHistory: [MedicalHistoryItem(startDateTime: '2024-01-01')],
        vaccinationRecord: [
          VaccinationRecordItem(
            date: '2023-01-01',
            vaccineName: 'BCG',
            vaccineCode: '19',
            dose: 1,
            administratedBy: 'E',
            administratedAt: 'C',
          ),
        ],
      );
      final json = record.toJson();
      expect(json.containsKey('guardian2Info'), isTrue);
      expect(json.containsKey('backgroundHistory'), isTrue);
      expect((json['allergies'] as List).length, 1);
      expect((json['medicalHistory'] as List).length, 1);
      expect((json['vaccinationRecord'] as List).length, 1);
    });

    test('toJson — guardian2Info ausente no aparece', () {
      final json = _buildMinimal().toJson();
      expect(json.containsKey('guardian2Info'), isFalse);
      expect(json.containsKey('backgroundHistory'), isFalse);
    });
  });

  // =========================================================================
  // PatientSyncResponse
  // =========================================================================
  group('PatientSyncResponse', () {
    test('fromJson — todos los campos', () {
      final r = PatientSyncResponse.fromJson(<String, dynamic>{
        'status': 'ok',
        'internal_id': 'int-001',
        'fhir_status': 'created',
        'vida_code': 'V001',
        'message': 'Sincronizado correctamente',
      });
      expect(r.status, 'ok');
      expect(r.internalId, 'int-001');
      expect(r.fhirStatus, 'created');
      expect(r.vidaCode, 'V001');
      expect(r.message, 'Sincronizado correctamente');
    });

    test('fromJson — sin campos opcionales', () {
      final r = PatientSyncResponse.fromJson(<String, dynamic>{
        'status': 'error',
        'internal_id': '',
        'message': 'Fallo',
      });
      expect(r.fhirStatus, isNull);
      expect(r.vidaCode, isNull);
    });

    test('fromJson — campos ausentes usan defaults vacíos', () {
      final r = PatientSyncResponse.fromJson(<String, dynamic>{});
      expect(r.status, '');
      expect(r.internalId, '');
      expect(r.message, '');
    });
  });

  group('tryParsePatientDate – Parseo defensivo de fechas', () {
    test('retorna DateTime válido con formato ISO YYYY-MM-DD', () {
      final date = tryParsePatientDate('2022-05-15');
      expect(date, equals(DateTime(2022, 5, 15)));
    });

    test('retorna DateTime válido con formato ISO completo con hora', () {
      final date = tryParsePatientDate('2020-08-20T14:30:00.000Z');
      expect(date, equals(DateTime.utc(2020, 8, 20, 14, 30)));
    });

    test(
      'retorna DateTime válido con separadores slash YYYY/MM/DD o DD/MM/YYYY',
      () {
        final date1 = tryParsePatientDate('2019/12/31');
        final date2 = tryParsePatientDate('31/12/2019');

        expect(date1, equals(DateTime(2019, 12, 31)));
        expect(date2, equals(DateTime(2019, 12, 31)));
      },
    );

    test(
      'retorna null y NO lanza FormatException ante texto corrupto o nulo',
      () {
        expect(tryParsePatientDate(null), isNull);
        expect(tryParsePatientDate(''), isNull);
        expect(tryParsePatientDate('  '), isNull);
        expect(tryParsePatientDate('fecha-invalida-123'), isNull);
      },
    );
  });
}

// =========================================================================
// Helpers globales privados para las pruebas (Corrección de Linter)
// =========================================================================

PatientIdentification _buildId() =>
    PatientIdentification(documentType: 'CC', documentNumber: '111');

Address _buildAddress() => Address(city: 'Bogotá', state: 'Cundinamarca');

PatientFullRecord _buildMinimal() {
  return PatientFullRecord(
    patientId: 'pid-001',
    deviceUid: 'dev-abc',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '1',
      ),
      firstLastName: 'García',
      firstName: 'Ana',
      dob: '2000-01-01',
      biologicalSex: 'F',
      address: Address(city: 'Bogotá', state: 'Cundinamarca'),
    ),
    guardianInfo: GuardianInfo(
      name: 'Pedro',
      relationship: 'Padre',
      phone: '300',
    ),
  );
}
