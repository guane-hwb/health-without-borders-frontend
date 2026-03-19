class Address {
  Address({
    this.street = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.country = '',
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
    );
  }

  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
      };
}

class PatientInfo {
  PatientInfo({
    this.lastName = '',
    this.firstName = '',
    this.dob = '',
    this.gender = '',
    this.bloodType = '',
    Address? address,
    this.weight,
    this.height,
  }) : address = address ?? Address();

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      lastName: json['lastName']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      bloodType: json['bloodType']?.toString() ?? '',
      address: json['address'] is Map<String, dynamic>
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : Address(),
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
    );
  }

  final String lastName;
  final String firstName;
  final String dob;
  final String gender;
  final String bloodType;
  final Address address;
  final double? weight;
  final double? height;

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toJson() => {
        'lastName': lastName,
        'firstName': firstName,
        'dob': dob,
        'gender': gender,
        'bloodType': bloodType,
        'address': address.toJson(),
        if (weight != null) 'weight': weight,
        if (height != null) 'height': height,
      };
}

class GuardianInfo {
  GuardianInfo({
    this.name = '',
    this.relationship = '',
    this.phone = '',
    this.deviceUid,
  });

  factory GuardianInfo.fromJson(Map<String, dynamic> json) {
    return GuardianInfo(
      name: json['name']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      deviceUid: json['device_uid']?.toString(),
    );
  }

  final String name;
  final String relationship;
  final String phone;
  final String? deviceUid;

  Map<String, dynamic> toJson() => {
        'name': name,
        'relationship': relationship,
        'phone': phone,
        if (deviceUid != null) 'device_uid': deviceUid,
      };
}

class BackgroundHistory {
  BackgroundHistory({
    this.chronicConditions,
    this.personalHistory,
    this.familyHistory,
  });

  factory BackgroundHistory.fromJson(Map<String, dynamic> json) {
    return BackgroundHistory(
      chronicConditions: json['chronicConditions']?.toString(),
      personalHistory: json['personalHistory']?.toString(),
      familyHistory: json['familyHistory']?.toString(),
    );
  }

  final String? chronicConditions;
  final String? personalHistory;
  final String? familyHistory;

  Map<String, dynamic> toJson() => {
        if (chronicConditions != null) 'chronicConditions': chronicConditions,
        if (personalHistory != null) 'personalHistory': personalHistory,
        if (familyHistory != null) 'familyHistory': familyHistory,
      };
}

class VaccinationRecordItem {
  VaccinationRecordItem({
    this.date = '',
    this.vaccineName = '',
    this.vaccineCode = '',
    this.dose = 1,
    this.administratedBy = '',
    this.administratedAt = '',
    this.status = 'completed',
  });

  factory VaccinationRecordItem.fromJson(Map<String, dynamic> json) {
    return VaccinationRecordItem(
      date: json['date']?.toString() ?? '',
      vaccineName: json['vaccineName']?.toString() ?? '',
      vaccineCode: json['vaccineCode']?.toString() ?? '',
      dose: (json['dose'] as num?)?.toInt() ?? 1,
      administratedBy: json['administratedBy']?.toString() ?? '',
      administratedAt: json['administratedAt']?.toString() ?? '',
      status: json['status']?.toString() ?? 'completed',
    );
  }

  final String date;
  final String vaccineName;
  final String vaccineCode;
  final int dose;
  final String administratedBy;
  final String administratedAt;
  final String status;

  Map<String, dynamic> toJson() => {
        'date': date,
        'vaccineName': vaccineName,
        'vaccineCode': vaccineCode,
        'dose': dose,
        'administratedBy': administratedBy,
        'administratedAt': administratedAt,
        'status': status,
      };
}

class AllergyInfo {
  AllergyInfo({
    this.allergen = '',
    this.reaction = '',
    this.notes,
  });

  factory AllergyInfo.fromJson(Map<String, dynamic> json) {
    return AllergyInfo(
      allergen: json['allergen']?.toString() ?? '',
      reaction: json['reaction']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }

  final String allergen;
  final String reaction;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'allergen': allergen,
        'reaction': reaction,
        if (notes != null) 'notes': notes,
      };
}

class ClinicalEvaluation {
  ClinicalEvaluation({
    this.historyOfCurrentIllness,
    this.generalPhysicalExamination,
    this.systemsExamination,
    this.treatmentPlanObservations,
  });

  factory ClinicalEvaluation.fromJson(Map<String, dynamic> json) {
    return ClinicalEvaluation(
      historyOfCurrentIllness: json['historyOfCurrentIllness']?.toString(),
      generalPhysicalExamination:
          json['generalPhysicalExamination']?.toString(),
      systemsExamination: json['systemsExamination']?.toString(),
      treatmentPlanObservations: json['treatmentPlanObservations']?.toString(),
    );
  }

  final String? historyOfCurrentIllness;
  final String? generalPhysicalExamination;
  final String? systemsExamination;
  final String? treatmentPlanObservations;

  Map<String, dynamic> toJson() => {
        if (historyOfCurrentIllness != null)
          'historyOfCurrentIllness': historyOfCurrentIllness,
        if (generalPhysicalExamination != null)
          'generalPhysicalExamination': generalPhysicalExamination,
        if (systemsExamination != null)
          'systemsExamination': systemsExamination,
        if (treatmentPlanObservations != null)
          'treatmentPlanObservations': treatmentPlanObservations,
      };
}

class DiagnosisItem {
  DiagnosisItem({
    this.icd10Code = '',
    this.icd11Code,
    this.description = '',
  });

  factory DiagnosisItem.fromJson(Map<String, dynamic> json) {
    return DiagnosisItem(
      icd10Code: json['icd10Code']?.toString() ?? '',
      icd11Code: json['icd11Code']?.toString(),
      description: json['description']?.toString() ?? '',
    );
  }

  final String icd10Code;
  final String? icd11Code;
  final String description;

  Map<String, dynamic> toJson() => {
        'icd10Code': icd10Code,
        if (icd11Code != null) 'icd11Code': icd11Code,
        'description': description,
      };
}

class MedicalHistoryItem {
  MedicalHistoryItem({
    this.type = '',
    this.date = '',
    this.location = '',
    this.physician = '',
    ClinicalEvaluation? clinicalEvaluation,
    this.diagnosis = const [],
  }) : clinicalEvaluation = clinicalEvaluation ?? ClinicalEvaluation();

  factory MedicalHistoryItem.fromJson(Map<String, dynamic> json) {
    return MedicalHistoryItem(
      type: json['type']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      physician: json['physician']?.toString() ?? '',
      clinicalEvaluation:
          json['clinicalEvaluation'] is Map<String, dynamic>
              ? ClinicalEvaluation.fromJson(
                  json['clinicalEvaluation'] as Map<String, dynamic>)
              : ClinicalEvaluation(),
      diagnosis: (json['diagnosis'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  DiagnosisItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final String type;
  final String date;
  final String location;
  final String physician;
  final ClinicalEvaluation clinicalEvaluation;
  final List<DiagnosisItem> diagnosis;

  Map<String, dynamic> toJson() => {
        'type': type,
        'date': date,
        'location': location,
        'physician': physician,
        'clinicalEvaluation': clinicalEvaluation.toJson(),
        'diagnosis': diagnosis.map((DiagnosisItem d) => d.toJson()).toList(),
      };
}

class PatientFullRecord {
  PatientFullRecord({
    required this.patientId,
    required this.deviceUid,
    required this.patientInfo,
    required this.guardianInfo,
    this.backgroundHistory,
    this.allergies = const [],
    this.medicalHistory = const [],
    this.vaccinationRecord = const [],
  });

  factory PatientFullRecord.fromJson(Map<String, dynamic> json) {
    return PatientFullRecord(
      patientId: json['patientId']?.toString() ?? '',
      deviceUid: json['device_uid']?.toString() ?? '',
      patientInfo: json['patientInfo'] is Map<String, dynamic>
          ? PatientInfo.fromJson(
              json['patientInfo'] as Map<String, dynamic>)
          : PatientInfo(),
      guardianInfo: json['guardianInfo'] is Map<String, dynamic>
          ? GuardianInfo.fromJson(
              json['guardianInfo'] as Map<String, dynamic>)
          : GuardianInfo(),
      backgroundHistory: json['backgroundHistory'] is Map<String, dynamic>
          ? BackgroundHistory.fromJson(
              json['backgroundHistory'] as Map<String, dynamic>)
          : null,
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  AllergyInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      medicalHistory: (json['medicalHistory'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  MedicalHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      vaccinationRecord: (json['vaccinationRecord'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  VaccinationRecordItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final String patientId;
  final String deviceUid;
  final PatientInfo patientInfo;
  final GuardianInfo guardianInfo;
  final BackgroundHistory? backgroundHistory;
  final List<AllergyInfo> allergies;
  final List<MedicalHistoryItem> medicalHistory;
  final List<VaccinationRecordItem> vaccinationRecord;

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'device_uid': deviceUid,
        'patientInfo': patientInfo.toJson(),
        'guardianInfo': guardianInfo.toJson(),
        if (backgroundHistory != null)
          'backgroundHistory': backgroundHistory!.toJson(),
        'allergies':
            allergies.map((AllergyInfo a) => a.toJson()).toList(),
        'medicalHistory':
            medicalHistory.map((MedicalHistoryItem m) => m.toJson()).toList(),
        'vaccinationRecord': vaccinationRecord
            .map((VaccinationRecordItem v) => v.toJson())
            .toList(),
      };
}

class PatientSyncResponse {
  PatientSyncResponse({
    required this.status,
    required this.internalId,
    this.gcpStatus,
    required this.message,
  });

  factory PatientSyncResponse.fromJson(Map<String, dynamic> json) {
    return PatientSyncResponse(
      status: json['status']?.toString() ?? '',
      internalId: json['internal_id']?.toString() ?? '',
      gcpStatus: json['gcp_status']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }

  final String status;
  final String internalId;
  final String? gcpStatus;
  final String message;
}
