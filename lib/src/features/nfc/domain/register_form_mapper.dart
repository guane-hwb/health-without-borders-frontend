import 'register_form_models.dart';

Map<String, dynamic> buildPatientSyncPayload(RegisterNfcDraft draft) {
  return <String, dynamic>{
    'patientId': draft.firstName.trim().isEmpty
        ? 'pending-id'
        : draft.firstName.trim().toLowerCase().replaceAll(' ', '-'),
    'device_uid': draft.deviceUid,
    'patientInfo': <String, dynamic>{
      'firstName': draft.firstName,
      'lastName': '',
      'birthDate': draft.birthDate,
      'gender': draft.gender,
      'country': draft.country,
      'bloodType': draft.bloodType,
      'weight': draft.weight,
      'height': draft.height,
    },
    'guardianInfo': <String, dynamic>{
      'name': draft.guardianName,
      'relationship': draft.guardianRelationship,
      'address': draft.guardianAddress,
      'phone': draft.guardianContact,
      'device_uid': draft.deviceUid,
    },
    'medicalHistory': <Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'consultation',
        'date': draft.medicalStaffDate,
        'location': draft.medicalStaffPlace,
        'physician': draft.medicalStaffName,
        'clinicalEvaluation': <String, dynamic>{
          'historyOfCurrentIllness': draft.currentIllness,
          'generalPhysicalExamination': draft.generalPhysicalExamination,
          'systemsExamination': draft.systemsExamination,
          'treatmentPlanObservations': '',
        },
        'diagnosis': <Map<String, dynamic>>[],
      },
    ],
    'backgroundHistory': <String, dynamic>{
      'personalHistory': draft.personalHistory,
      'familyHistory': draft.familyHistory,
      'chronicConditions': '',
    },
    'vaccines': draft.vaccines
        .map((VaccineEntry entry) => <String, dynamic>{
              'vaccine': entry.vaccine,
              'doses': entry.doses,
              'date': entry.date,
              'administratedBy': entry.administratedBy,
            })
        .toList(),
    'allergens': draft.allergens
        .map((AllergenEntry entry) => <String, dynamic>{
              'allergen': entry.allergen,
              'reaction': entry.reaction,
              'severity': entry.severity,
              'notes': entry.notes,
            })
        .toList(),
  };
}
