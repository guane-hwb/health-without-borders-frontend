// =============================================================================
// Domain Models — 1:1 mirror of backend app/schemas/patient.py
//
// Every class, field name, and enum value here matches exactly what the
// FastAPI backend expects in POST /sync and returns from GET /scan.
//
// Reference: Resolution 866/2021 & 1888/2025 (RDA elements)
// =============================================================================

// ---------------------------------------------------------------------------
// Address
// ---------------------------------------------------------------------------
class Address {
  Address({
    this.street,
    required this.city,
    this.cityCode,
    required this.state,
    this.zipCode,
    this.country = 'COL',
    this.countryName,
    this.zone,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street']?.toString(),
      city: json['city']?.toString() ?? '',
      cityCode: json['cityCode']?.toString(),
      state: json['state']?.toString() ?? '',
      zipCode: json['zipCode']?.toString(),
      country: json['country']?.toString() ?? 'COL',
      countryName: json['countryName']?.toString(),
      zone: json['zone']?.toString(),
    );
  }

  final String? street;
  final String city;
  final String? cityCode;
  final String state;
  final String? zipCode;
  final String country;
  final String? countryName;
  final String? zone; // "U" or "R"

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (street != null) 'street': street,
    'city': city,
    if (cityCode != null) 'cityCode': cityCode,
    'state': state,
    if (zipCode != null) 'zipCode': zipCode,
    'country': country,
    if (countryName != null) 'countryName': countryName,
    if (zone != null) 'zone': zone,
  };
}

// ---------------------------------------------------------------------------
// PatientIdentification — Res. 866 Elems. 2.1, 2.2
// ---------------------------------------------------------------------------
class PatientIdentification {
  PatientIdentification({
    required this.documentType,
    required this.documentNumber,
  });

  factory PatientIdentification.fromJson(Map<String, dynamic> json) {
    return PatientIdentification(
      documentType: json['documentType']?.toString() ?? 'MS',
      documentNumber: json['documentNumber']?.toString() ?? '',
    );
  }

  /// CC, CE, PA, RC, TI, SC, PE, PT, MS, AS, CN, DE
  final String documentType;
  final String documentNumber;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'documentType': documentType,
    'documentNumber': documentNumber,
  };
}

// ---------------------------------------------------------------------------
// PatientInfo — RDA Identificación del Paciente
// ---------------------------------------------------------------------------
class PatientInfo {
  PatientInfo({
    required this.identification,
    required this.firstLastName,
    this.secondLastName,
    required this.firstName,
    this.secondName,
    required this.dob,
    this.nationalityCode = 'COL',
    this.nationalityName,
    required this.biologicalSex,
    this.genderIdentity,
    this.ethnicity,
    this.ethnicCommunity,
    this.disabilityCategory,
    required this.address,
    this.bloodType,
    this.weight,
    this.height,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      identification: json['identification'] is Map<String, dynamic>
          ? PatientIdentification.fromJson(
              json['identification'] as Map<String, dynamic>,
            )
          : PatientIdentification(documentType: 'MS', documentNumber: ''),
      firstLastName: json['firstLastName']?.toString() ?? '',
      secondLastName: json['secondLastName']?.toString(),
      firstName: json['firstName']?.toString() ?? '',
      secondName: json['secondName']?.toString(),
      dob: json['dob']?.toString() ?? '',
      nationalityCode: json['nationalityCode']?.toString() ?? 'COL',
      nationalityName: json['nationalityName']?.toString(),
      biologicalSex: json['biologicalSex']?.toString() ?? 'I',
      genderIdentity: json['genderIdentity']?.toString(),
      ethnicity: json['ethnicity']?.toString(),
      ethnicCommunity: json['ethnicCommunity']?.toString(),
      disabilityCategory: json['disabilityCategory']?.toString(),
      address: json['address'] is Map<String, dynamic>
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : Address(city: '', state: ''),
      bloodType: json['bloodType']?.toString(),
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
    );
  }

  final PatientIdentification identification;
  final String firstLastName; // Primer apellido (Elem. 3.1)
  final String? secondLastName; // Segundo apellido (Elem. 3.2)
  final String firstName; // Primer nombre (Elem. 3.3)
  final String? secondName; // Segundo nombre (Elem. 3.4)
  final String dob; // YYYY-MM-DD (Elem. 4)
  final String nationalityCode; // ISO 3166-1 alpha-3 (Elem. 1.1)
  final String? nationalityName;
  final String biologicalSex; // "M", "F", "I" (Elem. 5)
  final String? genderIdentity; // "01"-"04", "99" (Elem. 6)
  final String? ethnicity; // "01"-"06" (Elem. 13.1)
  final String? ethnicCommunity;
  final String? disabilityCategory; // "00"-"07" (Elem. 10)
  final Address address;
  final String? bloodType;
  final double? weight;
  final double? height;

  String get fullName {
    final parts = <String>[firstName];
    if (secondName != null && secondName!.isNotEmpty) parts.add(secondName!);
    parts.add(firstLastName);
    if (secondLastName != null && secondLastName!.isNotEmpty) {
      parts.add(secondLastName!);
    }
    return parts.join(' ').trim();
  }

  PatientInfo copyWith({double? weight, double? height}) {
    return PatientInfo(
      identification: identification,
      firstLastName: firstLastName,
      secondLastName: secondLastName,
      firstName: firstName,
      secondName: secondName,
      dob: dob,
      nationalityCode: nationalityCode,
      nationalityName: nationalityName,
      biologicalSex: biologicalSex,
      genderIdentity: genderIdentity,
      ethnicity: ethnicity,
      ethnicCommunity: ethnicCommunity,
      disabilityCategory: disabilityCategory,
      address: address,
      bloodType: bloodType,
      weight: weight ?? this.weight,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'identification': identification.toJson(),
    'firstLastName': firstLastName,
    if (secondLastName != null) 'secondLastName': secondLastName,
    'firstName': firstName,
    if (secondName != null) 'secondName': secondName,
    'dob': dob,
    'nationalityCode': nationalityCode,
    if (nationalityName != null) 'nationalityName': nationalityName,
    'biologicalSex': biologicalSex,
    if (genderIdentity != null) 'genderIdentity': genderIdentity,
    if (ethnicity != null) 'ethnicity': ethnicity,
    if (ethnicCommunity != null) 'ethnicCommunity': ethnicCommunity,
    if (disabilityCategory != null) 'disabilityCategory': disabilityCategory,
    'address': address.toJson(),
    if (bloodType != null) 'bloodType': bloodType,
    if (weight != null) 'weight': weight,
    if (height != null) 'height': height,
  };
}

// ---------------------------------------------------------------------------
// GuardianInfo
// ---------------------------------------------------------------------------
class GuardianInfo {
  GuardianInfo({
    required this.name,
    required this.relationship,
    required this.phone,
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
  final String? deviceUid; // NFC UID of the guardian's wristband

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'relationship': relationship,
    'phone': phone,
    if (deviceUid != null) 'device_uid': deviceUid,
  };
}

// ---------------------------------------------------------------------------
// FamilyHistoryItem — Res. 866 Elems. 47.3, 47.4
//
// Frontend sends: conditionDescription + relationship
// Backend LLM resolves: conditionCie10Code + conditionCie11Code
// ---------------------------------------------------------------------------
class FamilyHistoryItem {
  FamilyHistoryItem({
    this.conditionCie10Code,
    this.conditionCie11Code,
    required this.conditionDescription,
    required this.relationship,
  });

  factory FamilyHistoryItem.fromJson(Map<String, dynamic> json) {
    return FamilyHistoryItem(
      conditionCie10Code: json['conditionCie10Code']?.toString(),
      conditionCie11Code: json['conditionCie11Code']?.toString(),
      conditionDescription: json['conditionDescription']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '01',
    );
  }

  final String? conditionCie10Code; // Resolved by LLM
  final String? conditionCie11Code; // Resolved by LLM
  final String conditionDescription; // Free text from frontend
  final String
  relationship; // "01"=Padres, "02"=Hermanos, "03"=Tíos, "04"=Abuelos

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (conditionCie10Code != null) 'conditionCie10Code': conditionCie10Code,
    if (conditionCie11Code != null) 'conditionCie11Code': conditionCie11Code,
    'conditionDescription': conditionDescription,
    'relationship': relationship,
  };
}

// ---------------------------------------------------------------------------
// BackgroundHistory
// ---------------------------------------------------------------------------
class BackgroundHistory {
  BackgroundHistory({
    this.chronicConditions,
    this.personalHistory,
    this.familyHistory = const <FamilyHistoryItem>[],
    this.familyHistoryNotes,
  });

  factory BackgroundHistory.fromJson(Map<String, dynamic> json) {
    return BackgroundHistory(
      chronicConditions: json['chronicConditions']?.toString(),
      personalHistory: json['personalHistory']?.toString(),
      familyHistory:
          (json['familyHistory'] as List<dynamic>?)
              ?.map(
                (dynamic e) =>
                    FamilyHistoryItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          <FamilyHistoryItem>[],
      familyHistoryNotes: json['familyHistoryNotes']?.toString(),
    );
  }

  final String? chronicConditions;
  final String? personalHistory;
  final List<FamilyHistoryItem> familyHistory;
  final String? familyHistoryNotes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (chronicConditions != null) 'chronicConditions': chronicConditions,
    if (personalHistory != null) 'personalHistory': personalHistory,
    'familyHistory': familyHistory
        .map((FamilyHistoryItem f) => f.toJson())
        .toList(),
    if (familyHistoryNotes != null) 'familyHistoryNotes': familyHistoryNotes,
  };
}

// ---------------------------------------------------------------------------
// AllergyInfo — Res. 866 Elems. 47.1, 47.2
// ---------------------------------------------------------------------------
class AllergyInfo {
  AllergyInfo({
    required this.category,
    required this.allergen,
    this.reaction,
    this.notes,
  });

  factory AllergyInfo.fromJson(Map<String, dynamic> json) {
    return AllergyInfo(
      category: json['category']?.toString() ?? '06',
      allergen: json['allergen']?.toString() ?? '',
      reaction: json['reaction']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  /// "01"=Medicamento, "02"=Alimento, "03"=Sustancia ambiente,
  /// "04"=Sustancia piel, "05"=Picadura insectos, "06"=Otra
  final String category;
  final String allergen;
  final String? reaction;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'category': category,
    'allergen': allergen,
    if (reaction != null) 'reaction': reaction,
    if (notes != null) 'notes': notes,
  };
}

// ---------------------------------------------------------------------------
// VaccinationRecordItem
// ---------------------------------------------------------------------------
class VaccinationRecordItem {
  VaccinationRecordItem({
    required this.date,
    required this.vaccineName,
    required this.vaccineCode,
    required this.dose,
    required this.administratedBy,
    required this.administratedAt,
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

  final String date; // YYYY-MM-DD
  final String vaccineName;
  final String vaccineCode; // CVX code
  final int dose;
  final String administratedBy;
  final String administratedAt;
  final String status;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'date': date,
    'vaccineName': vaccineName,
    'vaccineCode': vaccineCode,
    'dose': dose,
    'administratedBy': administratedBy,
    'administratedAt': administratedAt,
    'status': status,
  };
}

// ---------------------------------------------------------------------------
// ClinicalEvaluation
// ---------------------------------------------------------------------------
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
      generalPhysicalExamination: json['generalPhysicalExamination']
          ?.toString(),
      systemsExamination: json['systemsExamination']?.toString(),
      treatmentPlanObservations: json['treatmentPlanObservations']?.toString(),
    );
  }

  final String? historyOfCurrentIllness;
  final String? generalPhysicalExamination;
  final String? systemsExamination;
  final String? treatmentPlanObservations;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (historyOfCurrentIllness != null)
      'historyOfCurrentIllness': historyOfCurrentIllness,
    if (generalPhysicalExamination != null)
      'generalPhysicalExamination': generalPhysicalExamination,
    if (systemsExamination != null) 'systemsExamination': systemsExamination,
    if (treatmentPlanObservations != null)
      'treatmentPlanObservations': treatmentPlanObservations,
  };
}

// ---------------------------------------------------------------------------
// DiagnosisItem — Resolved by backend LLM, NOT sent by frontend
// ---------------------------------------------------------------------------
class DiagnosisItem {
  DiagnosisItem({
    required this.icd10Code,
    this.icd11Code,
    required this.description,
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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'icd10Code': icd10Code,
    if (icd11Code != null) 'icd11Code': icd11Code,
    'description': description,
  };
}

// ---------------------------------------------------------------------------
// RiskFactor — Res. 866 Elems. 48.1, 48.2
// ---------------------------------------------------------------------------
class RiskFactor {
  RiskFactor({required this.type, required this.name});

  factory RiskFactor.fromJson(Map<String, dynamic> json) {
    return RiskFactor(
      type: json['type']?.toString() ?? '06',
      name: json['name']?.toString() ?? '',
    );
  }

  /// "01"-"06"
  final String type;
  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'name': name,
  };
}

// ---------------------------------------------------------------------------
// IncapacityInfo — Res. 866 Elems. 45.1, 45.2, 46
// ---------------------------------------------------------------------------
class IncapacityInfo {
  IncapacityInfo({
    required this.scope,
    required this.days,
    this.maternityLeaveDays,
  });

  factory IncapacityInfo.fromJson(Map<String, dynamic> json) {
    return IncapacityInfo(
      scope: json['scope']?.toString() ?? '01',
      days: (json['days'] as num?)?.toInt() ?? 0,
      maternityLeaveDays: (json['maternityLeaveDays'] as num?)?.toInt(),
    );
  }

  final String scope; // "01"=Nueva, "02"=Prórroga
  final int days;
  final int? maternityLeaveDays;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'scope': scope,
    'days': days,
    if (maternityLeaveDays != null) 'maternityLeaveDays': maternityLeaveDays,
  };
}

// ---------------------------------------------------------------------------
// PractitionerInfo — Res. 866 Elems. 49.1, 49.2
// ---------------------------------------------------------------------------
class PractitionerInfo {
  PractitionerInfo({
    required this.documentType,
    required this.documentNumber,
    required this.name,
  });

  factory PractitionerInfo.fromJson(Map<String, dynamic> json) {
    return PractitionerInfo(
      documentType: json['documentType']?.toString() ?? 'CC',
      documentNumber: json['documentNumber']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  final String documentType; // Same DocumentType enum as patient
  final String documentNumber;
  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'documentType': documentType,
    'documentNumber': documentNumber,
    'name': name,
  };
}

// ---------------------------------------------------------------------------
// ProviderInfo — Res. 866 Elem. 16
// ---------------------------------------------------------------------------
class ProviderInfo {
  ProviderInfo({required this.repsCode, required this.name});

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    return ProviderInfo(
      repsCode: json['repsCode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  final String repsCode; // Código REPS del prestador
  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'repsCode': repsCode,
    'name': name,
  };
}

// ---------------------------------------------------------------------------
// PayerInfo — Res. 866 Elems. 15.1, 15.2
// ---------------------------------------------------------------------------
class PayerInfo {
  PayerInfo({this.code, this.name});

  factory PayerInfo.fromJson(Map<String, dynamic> json) {
    return PayerInfo(
      code: json['code']?.toString(),
      name: json['name']?.toString(),
    );
  }

  final String? code;
  final String? name;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (code != null) 'code': code,
    if (name != null) 'name': name,
  };
}

// ---------------------------------------------------------------------------
// MedicalHistoryItem — One clinical encounter (RDA-Consulta)
// ---------------------------------------------------------------------------
class MedicalHistoryItem {
  MedicalHistoryItem({
    this.type = 'Consultation',
    required this.startDateTime,
    this.endDateTime,
    this.careModality = '01',
    this.serviceGroup = '01',
    this.careEnvironment = '05',
    this.entryRoute,
    this.externalCause,
    this.provider,
    this.practitioner,
    this.location,
    this.physician,
    ClinicalEvaluation? clinicalEvaluation,
    this.diagnosis = const <DiagnosisItem>[],
    this.diagnosisType = '01',
    this.dischargeDisposition,
    this.riskFactors = const <RiskFactor>[],
    this.incapacity,
    this.payer,
  }) : clinicalEvaluation = clinicalEvaluation ?? ClinicalEvaluation();

  factory MedicalHistoryItem.fromJson(Map<String, dynamic> json) {
    return MedicalHistoryItem(
      type: json['type']?.toString() ?? 'Consultation',
      startDateTime: json['startDateTime']?.toString() ?? '',
      endDateTime: json['endDateTime']?.toString(),
      careModality: json['careModality']?.toString() ?? '01',
      serviceGroup: json['serviceGroup']?.toString() ?? '01',
      careEnvironment: json['careEnvironment']?.toString() ?? '05',
      entryRoute: json['entryRoute']?.toString(),
      externalCause: json['externalCause']?.toString(),
      provider: json['provider'] is Map<String, dynamic>
          ? ProviderInfo.fromJson(json['provider'] as Map<String, dynamic>)
          : null,
      practitioner: json['practitioner'] is Map<String, dynamic>
          ? PractitionerInfo.fromJson(
              json['practitioner'] as Map<String, dynamic>,
            )
          : null,
      location: json['location']?.toString(),
      physician: json['physician']?.toString(),
      clinicalEvaluation: json['clinicalEvaluation'] is Map<String, dynamic>
          ? ClinicalEvaluation.fromJson(
              json['clinicalEvaluation'] as Map<String, dynamic>,
            )
          : ClinicalEvaluation(),
      diagnosis:
          (json['diagnosis'] as List<dynamic>?)
              ?.map(
                (dynamic e) =>
                    DiagnosisItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          <DiagnosisItem>[],
      diagnosisType: json['diagnosisType']?.toString() ?? '01',
      dischargeDisposition: json['dischargeDisposition']?.toString(),
      riskFactors:
          (json['riskFactors'] as List<dynamic>?)
              ?.map(
                (dynamic e) => RiskFactor.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          <RiskFactor>[],
      incapacity: json['incapacity'] is Map<String, dynamic>
          ? IncapacityInfo.fromJson(json['incapacity'] as Map<String, dynamic>)
          : null,
      payer: json['payer'] is Map<String, dynamic>
          ? PayerInfo.fromJson(json['payer'] as Map<String, dynamic>)
          : null,
    );
  }

  final String type;
  final String startDateTime; // ISO 8601 datetime
  final String? endDateTime;
  final String careModality; // "01"-"09"
  final String serviceGroup; // "01"-"05"
  final String careEnvironment; // "01"-"05"
  final String? entryRoute;
  final String? externalCause;
  final ProviderInfo? provider;
  final PractitionerInfo? practitioner;
  final String? location; // Legacy
  final String? physician; // Legacy
  final ClinicalEvaluation clinicalEvaluation;
  final List<DiagnosisItem> diagnosis; // Empty array from frontend — LLM fills
  final String diagnosisType; // "01", "02", "03"
  final String? dischargeDisposition; // "01"-"04"
  final List<RiskFactor> riskFactors;
  final IncapacityInfo? incapacity;
  final PayerInfo? payer;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'startDateTime': startDateTime,
    if (endDateTime != null) 'endDateTime': endDateTime,
    'careModality': careModality,
    'serviceGroup': serviceGroup,
    'careEnvironment': careEnvironment,
    if (entryRoute != null) 'entryRoute': entryRoute,
    if (externalCause != null) 'externalCause': externalCause,
    if (provider != null) 'provider': provider!.toJson(),
    if (practitioner != null) 'practitioner': practitioner!.toJson(),
    if (location != null) 'location': location,
    if (physician != null) 'physician': physician,
    'clinicalEvaluation': clinicalEvaluation.toJson(),
    'diagnosis': diagnosis.map((DiagnosisItem d) => d.toJson()).toList(),
    'diagnosisType': diagnosisType,
    if (dischargeDisposition != null)
      'dischargeDisposition': dischargeDisposition,
    'riskFactors': riskFactors.map((RiskFactor r) => r.toJson()).toList(),
    if (incapacity != null) 'incapacity': incapacity!.toJson(),
    if (payer != null) 'payer': payer!.toJson(),
  };
}

// ---------------------------------------------------------------------------
// PatientFullRecord — Root model (POST /sync body & GET /scan response)
// ---------------------------------------------------------------------------
class PatientFullRecord {
  PatientFullRecord({
    required this.patientId,
    required this.deviceUid,
    required this.patientInfo,
    required this.guardianInfo,
    this.backgroundHistory,
    this.allergies = const <AllergyInfo>[],
    this.medicalHistory = const <MedicalHistoryItem>[],
    this.vaccinationRecord = const <VaccinationRecordItem>[],
  });

  factory PatientFullRecord.fromJson(Map<String, dynamic> json) {
    return PatientFullRecord(
      patientId: json['patientId']?.toString() ?? '',
      deviceUid: json['device_uid']?.toString() ?? '',
      patientInfo: json['patientInfo'] is Map<String, dynamic>
          ? PatientInfo.fromJson(json['patientInfo'] as Map<String, dynamic>)
          : PatientInfo(
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
      guardianInfo: json['guardianInfo'] is Map<String, dynamic>
          ? GuardianInfo.fromJson(json['guardianInfo'] as Map<String, dynamic>)
          : GuardianInfo(name: '', relationship: '', phone: ''),
      backgroundHistory: json['backgroundHistory'] is Map<String, dynamic>
          ? BackgroundHistory.fromJson(
              json['backgroundHistory'] as Map<String, dynamic>,
            )
          : null,
      allergies:
          (json['allergies'] as List<dynamic>?)
              ?.map(
                (dynamic e) => AllergyInfo.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          <AllergyInfo>[],
      medicalHistory:
          (json['medicalHistory'] as List<dynamic>?)
              ?.map(
                (dynamic e) =>
                    MedicalHistoryItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          <MedicalHistoryItem>[],
      vaccinationRecord:
          (json['vaccinationRecord'] as List<dynamic>?)
              ?.map(
                (dynamic e) =>
                    VaccinationRecordItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          <VaccinationRecordItem>[],
    );
  }

  final String patientId; // UUID v4 generated by frontend
  final String deviceUid; // NFC hardware UID
  final PatientInfo patientInfo;
  final GuardianInfo guardianInfo;
  final BackgroundHistory? backgroundHistory;
  final List<AllergyInfo> allergies;
  final List<MedicalHistoryItem> medicalHistory;
  final List<VaccinationRecordItem> vaccinationRecord;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'patientId': patientId,
    'device_uid': deviceUid,
    'patientInfo': patientInfo.toJson(),
    'guardianInfo': guardianInfo.toJson(),
    if (backgroundHistory != null)
      'backgroundHistory': backgroundHistory!.toJson(),
    'allergies': allergies.map((AllergyInfo a) => a.toJson()).toList(),
    'medicalHistory': medicalHistory
        .map((MedicalHistoryItem m) => m.toJson())
        .toList(),
    'vaccinationRecord': vaccinationRecord
        .map((VaccinationRecordItem v) => v.toJson())
        .toList(),
  };
}

// ---------------------------------------------------------------------------
// PatientSyncResponse — Response from POST /sync
// ---------------------------------------------------------------------------
class PatientSyncResponse {
  PatientSyncResponse({
    required this.status,
    required this.internalId,
    this.fhirStatus,
    this.vidaCode,
    required this.message,
  });

  factory PatientSyncResponse.fromJson(Map<String, dynamic> json) {
    return PatientSyncResponse(
      status: json['status']?.toString() ?? '',
      internalId: json['internal_id']?.toString() ?? '',
      fhirStatus: json['fhir_status']?.toString(),
      vidaCode: json['vida_code']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }

  final String status;
  final String internalId;
  final String? fhirStatus;
  final String? vidaCode;
  final String message;
}
