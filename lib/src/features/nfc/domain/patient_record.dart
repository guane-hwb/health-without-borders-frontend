// =============================================================================
// Domain Models — 1:1 mirror of backend app/schemas/patient.py
//
// Every class, field name, and enum value here matches exactly what the
// FastAPI backend expects in POST /sync and returns from GET /scan.
//
// Reference: Resolution 866/2021 & 1888/2025 (RDA elements)
// =============================================================================

// ---------------------------------------------------------------------------
// Equality helper — v2-modelos-sin-copywith-ni-equals (Hallazgo 24)
//
// Used by every model's operator== below so lists compare by content instead
// of by reference (the default List== in Dart).
// ---------------------------------------------------------------------------
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

DateTime? tryParsePatientDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final clean = raw.trim();

  final parsed = DateTime.tryParse(clean);
  if (parsed != null) return parsed;

  try {
    if (clean.contains('/')) {
      final parts = clean.split('/');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else if (parts[2].length == 4) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
    }
  } catch (_) {}
  return null;
}

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
  final String? zone; // "01" (Urbana) or "02" (Rural)

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

  Address copyWith({
    String? street,
    String? city,
    String? cityCode,
    String? state,
    String? zipCode,
    String? country,
    String? countryName,
    String? zone,
  }) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      cityCode: cityCode ?? this.cityCode,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      countryName: countryName ?? this.countryName,
      zone: zone ?? this.zone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          street == other.street &&
          city == other.city &&
          cityCode == other.cityCode &&
          state == other.state &&
          zipCode == other.zipCode &&
          country == other.country &&
          countryName == other.countryName &&
          zone == other.zone;

  @override
  int get hashCode => Object.hash(
    street,
    city,
    cityCode,
    state,
    zipCode,
    country,
    countryName,
    zone,
  );
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

  PatientIdentification copyWith({
    String? documentType,
    String? documentNumber,
  }) {
    return PatientIdentification(
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientIdentification &&
          runtimeType == other.runtimeType &&
          documentType == other.documentType &&
          documentNumber == other.documentNumber;

  @override
  int get hashCode => Object.hash(documentType, documentNumber);
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
  final String firstLastName;
  final String? secondLastName;
  final String firstName;
  final String? secondName;
  final String dob;
  final String nationalityCode;
  final String? nationalityName;
  final String biologicalSex;
  final String? genderIdentity;
  final String? ethnicity;
  final String? ethnicCommunity;
  final String? disabilityCategory;
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

  PatientInfo copyWith({
    PatientIdentification? identification,
    String? firstLastName,
    String? secondLastName,
    String? firstName,
    String? secondName,
    String? dob,
    String? nationalityCode,
    String? nationalityName,
    String? biologicalSex,
    String? genderIdentity,
    String? ethnicity,
    String? ethnicCommunity,
    String? disabilityCategory,
    Address? address,
    String? bloodType,
    double? weight,
    double? height,
  }) {
    return PatientInfo(
      identification: identification ?? this.identification,
      firstLastName: firstLastName ?? this.firstLastName,
      secondLastName: secondLastName ?? this.secondLastName,
      firstName: firstName ?? this.firstName,
      secondName: secondName ?? this.secondName,
      dob: dob ?? this.dob,
      nationalityCode: nationalityCode ?? this.nationalityCode,
      nationalityName: nationalityName ?? this.nationalityName,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      genderIdentity: genderIdentity ?? this.genderIdentity,
      ethnicity: ethnicity ?? this.ethnicity,
      ethnicCommunity: ethnicCommunity ?? this.ethnicCommunity,
      disabilityCategory: disabilityCategory ?? this.disabilityCategory,
      address: address ?? this.address,
      bloodType: bloodType ?? this.bloodType,
      weight: weight ?? this.weight,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientInfo &&
          runtimeType == other.runtimeType &&
          identification == other.identification &&
          firstLastName == other.firstLastName &&
          secondLastName == other.secondLastName &&
          firstName == other.firstName &&
          secondName == other.secondName &&
          dob == other.dob &&
          nationalityCode == other.nationalityCode &&
          nationalityName == other.nationalityName &&
          biologicalSex == other.biologicalSex &&
          genderIdentity == other.genderIdentity &&
          ethnicity == other.ethnicity &&
          ethnicCommunity == other.ethnicCommunity &&
          disabilityCategory == other.disabilityCategory &&
          address == other.address &&
          bloodType == other.bloodType &&
          weight == other.weight &&
          height == other.height;

  @override
  int get hashCode => Object.hash(
    identification,
    firstLastName,
    secondLastName,
    firstName,
    secondName,
    dob,
    nationalityCode,
    nationalityName,
    biologicalSex,
    genderIdentity,
    Object.hash(ethnicity, ethnicCommunity, disabilityCategory, address),
    bloodType,
    weight,
    height,
  );

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
    if (ethnicCommunity != null) ...<String, dynamic>{
      'ethnicCommunity': ethnicCommunity,
      'ethnic_community': ethnicCommunity,
    },
    if (disabilityCategory != null) 'disabilityCategory': disabilityCategory,
    'address': address.toJson(),
    if (bloodType != null) 'bloodType': bloodType,
    if (weight != null) 'weight': weight,
    if (height != null) 'height': height,
  };
}

// ---------------------------------------------------------------------------
// GuardianConsent — Ley 1581/2012 (Habeas Data)
// ---------------------------------------------------------------------------
class GuardianConsent {
  GuardianConsent({
    required this.accepted,
    required this.acceptedAt,
    this.email,
    this.signatureBase64,
  });

  factory GuardianConsent.fromJson(Map<String, dynamic> json) {
    return GuardianConsent(
      accepted: json['accepted'] == true,
      acceptedAt: json['acceptedAt']?.toString() ?? '',
      email: json['email']?.toString(),
      signatureBase64: json['signatureBase64']?.toString(),
    );
  }

  final bool accepted;
  final String acceptedAt; // ISO 8601
  final String? email;
  final String? signatureBase64; // PNG base64

  Map<String, dynamic> toJson() => <String, dynamic>{
    'accepted': accepted,
    'acceptedAt': acceptedAt,
    if (email != null) 'email': email,
    if (signatureBase64 != null) 'signatureBase64': signatureBase64,
  };

  GuardianConsent copyWith({
    bool? accepted,
    String? acceptedAt,
    String? email,
    String? signatureBase64,
  }) {
    return GuardianConsent(
      accepted: accepted ?? this.accepted,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      email: email ?? this.email,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuardianConsent &&
          runtimeType == other.runtimeType &&
          accepted == other.accepted &&
          acceptedAt == other.acceptedAt &&
          email == other.email &&
          signatureBase64 == other.signatureBase64;

  @override
  int get hashCode => Object.hash(accepted, acceptedAt, email, signatureBase64);
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
    this.docType,
    this.docNumber,
    this.documentType,
    this.documentNumber,
    this.consent,
  });

  factory GuardianInfo.fromJson(Map<String, dynamic> json) {
    return GuardianInfo(
      name: json['name']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      deviceUid: json['device_uid']?.toString(),
      docType: json['docType']?.toString() ?? json['documentType']?.toString(),
      docNumber:
          json['docNumber']?.toString() ?? json['documentNumber']?.toString(),
      documentType:
          json['documentType']?.toString() ?? json['docType']?.toString(),
      documentNumber:
          json['documentNumber']?.toString() ?? json['docNumber']?.toString(),
      consent: json['consent'] is Map<String, dynamic>
          ? GuardianConsent.fromJson(json['consent'] as Map<String, dynamic>)
          : null,
    );
  }

  final String name;
  final String relationship;
  final String phone;
  final String? deviceUid; // NFC UID of the guardian's wristband
  final String? docType;
  final String? docNumber;
  final String? documentType;
  final String? documentNumber;
  final GuardianConsent? consent;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'relationship': relationship,
    'phone': phone,
    if (deviceUid != null) 'device_uid': deviceUid,
    if (docType != null) 'docType': docType,
    if (docNumber != null) 'docNumber': docNumber,
    if (documentType != null) 'documentType': documentType,
    if (documentNumber != null) 'documentNumber': documentNumber,
    if (consent != null) 'consent': consent!.toJson(),
  };

  GuardianInfo copyWith({
    String? name,
    String? relationship,
    String? phone,
    String? deviceUid,
    String? docType,
    String? docNumber,
    String? documentType,
    String? documentNumber,
    GuardianConsent? consent,
  }) {
    return GuardianInfo(
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      deviceUid: deviceUid ?? this.deviceUid,
      docType: docType ?? this.docType,
      docNumber: docNumber ?? this.docNumber,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      consent: consent ?? this.consent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuardianInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          relationship == other.relationship &&
          phone == other.phone &&
          deviceUid == other.deviceUid &&
          docType == other.docType &&
          docNumber == other.docNumber &&
          documentType == other.documentType &&
          documentNumber == other.documentNumber &&
          consent == other.consent;

  @override
  int get hashCode => Object.hash(
    name,
    relationship,
    phone,
    deviceUid,
    docType,
    docNumber,
    documentType,
    documentNumber,
    consent,
  );
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

  FamilyHistoryItem copyWith({
    String? conditionCie10Code,
    String? conditionCie11Code,
    String? conditionDescription,
    String? relationship,
  }) {
    return FamilyHistoryItem(
      conditionCie10Code: conditionCie10Code ?? this.conditionCie10Code,
      conditionCie11Code: conditionCie11Code ?? this.conditionCie11Code,
      conditionDescription: conditionDescription ?? this.conditionDescription,
      relationship: relationship ?? this.relationship,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyHistoryItem &&
          runtimeType == other.runtimeType &&
          conditionCie10Code == other.conditionCie10Code &&
          conditionCie11Code == other.conditionCie11Code &&
          conditionDescription == other.conditionDescription &&
          relationship == other.relationship;

  @override
  int get hashCode => Object.hash(
    conditionCie10Code,
    conditionCie11Code,
    conditionDescription,
    relationship,
  );
}

// ---------------------------------------------------------------------------
// ChronicConditionItem — IG RDA v0.8.1 ConditionStatementRDA
//
// Frontend sends: chronicDescription (free text)
// Backend LLM resolves: chronicCie10Code + chronicCie11Code
// ---------------------------------------------------------------------------
class ChronicConditionItem {
  ChronicConditionItem({
    required this.chronicDescription,
    this.chronicCie10Code,
    this.chronicCie11Code,
  });

  factory ChronicConditionItem.fromJson(Map<String, dynamic> json) {
    return ChronicConditionItem(
      chronicDescription: json['chronicDescription']?.toString() ?? '',
      chronicCie10Code: json['chronicCie10Code']?.toString(),
      chronicCie11Code: json['chronicCie11Code']?.toString(),
    );
  }

  final String chronicDescription; // Free text from frontend
  final String? chronicCie10Code; // Resolved by LLM
  final String? chronicCie11Code; // Resolved by LLM

  Map<String, dynamic> toJson() => <String, dynamic>{
    'chronicDescription': chronicDescription,
    if (chronicCie10Code != null) 'chronicCie10Code': chronicCie10Code,
    if (chronicCie11Code != null) 'chronicCie11Code': chronicCie11Code,
  };

  ChronicConditionItem copyWith({
    String? chronicDescription,
    String? chronicCie10Code,
    String? chronicCie11Code,
  }) {
    return ChronicConditionItem(
      chronicDescription: chronicDescription ?? this.chronicDescription,
      chronicCie10Code: chronicCie10Code ?? this.chronicCie10Code,
      chronicCie11Code: chronicCie11Code ?? this.chronicCie11Code,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChronicConditionItem &&
          runtimeType == other.runtimeType &&
          chronicDescription == other.chronicDescription &&
          chronicCie10Code == other.chronicCie10Code &&
          chronicCie11Code == other.chronicCie11Code;

  @override
  int get hashCode =>
      Object.hash(chronicDescription, chronicCie10Code, chronicCie11Code);
}

// ---------------------------------------------------------------------------
// MedicationStatementItem — MedicationStatementRDA
// ---------------------------------------------------------------------------
class MedicationStatementItem {
  MedicationStatementItem({
    required this.medicationName,
    this.dciCode,
    this.status = 'active',
    this.dosage,
    this.notes,
  });

  factory MedicationStatementItem.fromJson(Map<String, dynamic> json) {
    return MedicationStatementItem(
      medicationName: json['medicationName']?.toString() ?? '',
      dciCode: json['dciCode']?.toString(),
      status: json['status']?.toString() ?? 'active',
      dosage: json['dosage']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  final String medicationName;
  final String? dciCode; // Código DCI — MIPRES
  final String status; // "active", "completed", "stopped", "unknown"
  final String? dosage; // Free text
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'medicationName': medicationName,
    if (dciCode != null) 'dciCode': dciCode,
    'status': status,
    if (dosage != null) 'dosage': dosage,
    if (notes != null) 'notes': notes,
  };

  MedicationStatementItem copyWith({
    String? medicationName,
    String? dciCode,
    String? status,
    String? dosage,
    String? notes,
  }) {
    return MedicationStatementItem(
      medicationName: medicationName ?? this.medicationName,
      dciCode: dciCode ?? this.dciCode,
      status: status ?? this.status,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationStatementItem &&
          runtimeType == other.runtimeType &&
          medicationName == other.medicationName &&
          dciCode == other.dciCode &&
          status == other.status &&
          dosage == other.dosage &&
          notes == other.notes;

  @override
  int get hashCode =>
      Object.hash(medicationName, dciCode, status, dosage, notes);
}

// ---------------------------------------------------------------------------
// BackgroundHistory
// ---------------------------------------------------------------------------
class BackgroundHistory {
  BackgroundHistory({
    this.chronicConditions = const <ChronicConditionItem>[],
    this.personalHistory,
    this.familyHistory = const <FamilyHistoryItem>[],
    this.familyHistoryNotes,
    this.medications = const <MedicationStatementItem>[],
  });

  factory BackgroundHistory.fromJson(Map<String, dynamic> json) {
    final rawCC = json['chronicConditions'];
    final chronicConditions = (rawCC is List)
        ? rawCC
              .map(
                (dynamic e) =>
                    ChronicConditionItem.fromJson(e as Map<String, dynamic>),
              )
              .toList()
        : <ChronicConditionItem>[];

    final rawMeds = json['medications'];
    final medications = (rawMeds is List)
        ? rawMeds
              .map(
                (dynamic e) =>
                    MedicationStatementItem.fromJson(e as Map<String, dynamic>),
              )
              .toList()
        : <MedicationStatementItem>[];

    return BackgroundHistory(
      chronicConditions: chronicConditions,
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
      medications: medications,
    );
  }

  final List<ChronicConditionItem> chronicConditions;
  final String? personalHistory;
  final List<FamilyHistoryItem> familyHistory;
  final String? familyHistoryNotes;
  final List<MedicationStatementItem> medications;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'chronicConditions': chronicConditions
        .map((ChronicConditionItem c) => c.toJson())
        .toList(),
    if (personalHistory != null) 'personalHistory': personalHistory,
    'familyHistory': familyHistory
        .map((FamilyHistoryItem f) => f.toJson())
        .toList(),
    if (familyHistoryNotes != null) 'familyHistoryNotes': familyHistoryNotes,
    'medications': medications
        .map((MedicationStatementItem m) => m.toJson())
        .toList(),
  };

  BackgroundHistory copyWith({
    List<ChronicConditionItem>? chronicConditions,
    String? personalHistory,
    List<FamilyHistoryItem>? familyHistory,
    String? familyHistoryNotes,
    List<MedicationStatementItem>? medications,
  }) {
    return BackgroundHistory(
      chronicConditions: chronicConditions ?? this.chronicConditions,
      personalHistory: personalHistory ?? this.personalHistory,
      familyHistory: familyHistory ?? this.familyHistory,
      familyHistoryNotes: familyHistoryNotes ?? this.familyHistoryNotes,
      medications: medications ?? this.medications,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundHistory &&
          runtimeType == other.runtimeType &&
          _listEquals(chronicConditions, other.chronicConditions) &&
          personalHistory == other.personalHistory &&
          _listEquals(familyHistory, other.familyHistory) &&
          familyHistoryNotes == other.familyHistoryNotes &&
          _listEquals(medications, other.medications);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(chronicConditions),
    personalHistory,
    Object.hashAll(familyHistory),
    familyHistoryNotes,
    Object.hashAll(medications),
  );
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

  AllergyInfo copyWith({
    String? category,
    String? allergen,
    String? reaction,
    String? notes,
  }) {
    return AllergyInfo(
      category: category ?? this.category,
      allergen: allergen ?? this.allergen,
      reaction: reaction ?? this.reaction,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllergyInfo &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          allergen == other.allergen &&
          reaction == other.reaction &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(category, allergen, reaction, notes);
}

// ---------------------------------------------------------------------------
// VaccinationRecordItem
// ---------------------------------------------------------------------------
class VaccinationRecordItem {
  VaccinationRecordItem({
    this.vaccinationId,
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
      vaccinationId: json['vaccinationId']?.toString(),
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
  final String? vaccinationId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (vaccinationId != null) 'vaccinationId': vaccinationId,
    'date': date,
    'vaccineName': vaccineName,
    'vaccineCode': vaccineCode,
    'dose': dose,
    'administratedBy': administratedBy,
    'administratedAt': administratedAt,
    'status': status,
  };

  VaccinationRecordItem copyWith({
    String? vaccinationId,
    String? date,
    String? vaccineName,
    String? vaccineCode,
    int? dose,
    String? administratedBy,
    String? administratedAt,
    String? status,
  }) {
    return VaccinationRecordItem(
      vaccinationId: vaccinationId ?? this.vaccinationId,
      date: date ?? this.date,
      vaccineName: vaccineName ?? this.vaccineName,
      vaccineCode: vaccineCode ?? this.vaccineCode,
      dose: dose ?? this.dose,
      administratedBy: administratedBy ?? this.administratedBy,
      administratedAt: administratedAt ?? this.administratedAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaccinationRecordItem &&
          runtimeType == other.runtimeType &&
          vaccinationId == other.vaccinationId &&
          date == other.date &&
          vaccineName == other.vaccineName &&
          vaccineCode == other.vaccineCode &&
          dose == other.dose &&
          administratedBy == other.administratedBy &&
          administratedAt == other.administratedAt &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
    vaccinationId,
    date,
    vaccineName,
    vaccineCode,
    dose,
    administratedBy,
    administratedAt,
    status,
  );
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

  ClinicalEvaluation copyWith({
    String? historyOfCurrentIllness,
    String? generalPhysicalExamination,
    String? systemsExamination,
    String? treatmentPlanObservations,
  }) {
    return ClinicalEvaluation(
      historyOfCurrentIllness:
          historyOfCurrentIllness ?? this.historyOfCurrentIllness,
      generalPhysicalExamination:
          generalPhysicalExamination ?? this.generalPhysicalExamination,
      systemsExamination: systemsExamination ?? this.systemsExamination,
      treatmentPlanObservations:
          treatmentPlanObservations ?? this.treatmentPlanObservations,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClinicalEvaluation &&
          runtimeType == other.runtimeType &&
          historyOfCurrentIllness == other.historyOfCurrentIllness &&
          generalPhysicalExamination == other.generalPhysicalExamination &&
          systemsExamination == other.systemsExamination &&
          treatmentPlanObservations == other.treatmentPlanObservations;

  @override
  int get hashCode => Object.hash(
    historyOfCurrentIllness,
    generalPhysicalExamination,
    systemsExamination,
    treatmentPlanObservations,
  );
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

  DiagnosisItem copyWith({
    String? icd10Code,
    String? icd11Code,
    String? description,
  }) {
    return DiagnosisItem(
      icd10Code: icd10Code ?? this.icd10Code,
      icd11Code: icd11Code ?? this.icd11Code,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosisItem &&
          runtimeType == other.runtimeType &&
          icd10Code == other.icd10Code &&
          icd11Code == other.icd11Code &&
          description == other.description;

  @override
  int get hashCode => Object.hash(icd10Code, icd11Code, description);
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

  final String type;
  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type,
    'name': name,
  };

  RiskFactor copyWith({String? type, String? name}) {
    return RiskFactor(type: type ?? this.type, name: name ?? this.name);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskFactor &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          name == other.name;

  @override
  int get hashCode => Object.hash(type, name);
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

  final String scope;
  final int days;
  final int? maternityLeaveDays;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'scope': scope,
    'days': days,
    if (maternityLeaveDays != null) 'maternityLeaveDays': maternityLeaveDays,
  };

  IncapacityInfo copyWith({String? scope, int? days, int? maternityLeaveDays}) {
    return IncapacityInfo(
      scope: scope ?? this.scope,
      days: days ?? this.days,
      maternityLeaveDays: maternityLeaveDays ?? this.maternityLeaveDays,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncapacityInfo &&
          runtimeType == other.runtimeType &&
          scope == other.scope &&
          days == other.days &&
          maternityLeaveDays == other.maternityLeaveDays;

  @override
  int get hashCode => Object.hash(scope, days, maternityLeaveDays);
}

// ---------------------------------------------------------------------------
// PractitionerInfo — Res. 866 Elems. 49.1, 49.2
// ---------------------------------------------------------------------------
class PractitionerInfo {
  PractitionerInfo({
    required this.documentType,
    required this.documentNumber,
    required this.name,
    this.firstName,
    this.secondName,
    this.firstLastName,
    this.secondLastName,
  });

  factory PractitionerInfo.fromJson(Map<String, dynamic> json) {
    return PractitionerInfo(
      documentType: json['documentType']?.toString() ?? 'CC',
      documentNumber: json['documentNumber']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      secondName: json['secondName']?.toString(),
      firstLastName: json['firstLastName']?.toString(),
      secondLastName: json['secondLastName']?.toString(),
    );
  }

  final String documentType;
  final String documentNumber;
  final String name;
  final String? firstName;
  final String? secondName;
  final String? firstLastName;
  final String? secondLastName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'documentType': documentType,
    'documentNumber': documentNumber,
    'name': name,
    if (firstName != null) 'firstName': firstName,
    if (secondName != null) 'secondName': secondName,
    if (firstLastName != null) 'firstLastName': firstLastName,
    if (secondLastName != null) 'secondLastName': secondLastName,
  };

  PractitionerInfo copyWith({
    String? documentType,
    String? documentNumber,
    String? name,
    String? firstName,
    String? secondName,
    String? firstLastName,
    String? secondLastName,
  }) {
    return PractitionerInfo(
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      secondName: secondName ?? this.secondName,
      firstLastName: firstLastName ?? this.firstLastName,
      secondLastName: secondLastName ?? this.secondLastName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PractitionerInfo &&
          runtimeType == other.runtimeType &&
          documentType == other.documentType &&
          documentNumber == other.documentNumber &&
          name == other.name &&
          firstName == other.firstName &&
          secondName == other.secondName &&
          firstLastName == other.firstLastName &&
          secondLastName == other.secondLastName;

  @override
  int get hashCode => Object.hash(
    documentType,
    documentNumber,
    name,
    firstName,
    secondName,
    firstLastName,
    secondLastName,
  );
}

// ---------------------------------------------------------------------------
// ProviderInfo — Res. 866 Elem. 16
// ---------------------------------------------------------------------------
class ProviderInfo {
  ProviderInfo({
    required this.repsCode,
    required this.name,
    this.nitNumber,
    this.locationSeatCode,
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    return ProviderInfo(
      repsCode: json['repsCode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nitNumber: json['nitNumber']?.toString(),
      locationSeatCode: json['locationSeatCode']?.toString(),
    );
  }

  final String repsCode;
  final String name;
  final String? nitNumber;
  final String? locationSeatCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'repsCode': repsCode,
    'name': name,
    if (nitNumber != null) 'nitNumber': nitNumber,
    if (locationSeatCode != null) 'locationSeatCode': locationSeatCode,
  };

  ProviderInfo copyWith({
    String? repsCode,
    String? name,
    String? nitNumber,
    String? locationSeatCode,
  }) {
    return ProviderInfo(
      repsCode: repsCode ?? this.repsCode,
      name: name ?? this.name,
      nitNumber: nitNumber ?? this.nitNumber,
      locationSeatCode: locationSeatCode ?? this.locationSeatCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderInfo &&
          runtimeType == other.runtimeType &&
          repsCode == other.repsCode &&
          name == other.name &&
          nitNumber == other.nitNumber &&
          locationSeatCode == other.locationSeatCode;

  @override
  int get hashCode => Object.hash(repsCode, name, nitNumber, locationSeatCode);
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

  PayerInfo copyWith({String? code, String? name}) {
    return PayerInfo(code: code ?? this.code, name: name ?? this.name);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayerInfo &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          name == other.name;

  @override
  int get hashCode => Object.hash(code, name);
}

// ---------------------------------------------------------------------------
// MedicationRequestItem — Prescripción estructurada para FHIR / RDA
// ---------------------------------------------------------------------------
class MedicationRequestItem {
  MedicationRequestItem({
    required this.medicationName,
    this.dciCode,
    this.iumCode,
    this.dosage,
    this.quantity,
    this.frequency,
    this.duration,
    this.route,
    this.status = 'active',
    this.intent = 'order',
    this.notes,
  });

  factory MedicationRequestItem.fromJson(Map<String, dynamic> json) {
    return MedicationRequestItem(
      medicationName: json['medicationName']?.toString() ?? '',
      dciCode: json['dciCode']?.toString(),
      iumCode: json['iumCode']?.toString(),
      dosage: json['dosage']?.toString(),
      quantity: json['quantity']?.toString(),
      frequency: json['frequency']?.toString(),
      duration: json['duration']?.toString(),
      route: json['route']?.toString(),
      status: json['status']?.toString() ?? 'active',
      intent: json['intent']?.toString() ?? 'order',
      notes: json['notes']?.toString(),
    );
  }

  final String medicationName;
  final String? dciCode;
  final String? iumCode;
  final String? dosage;
  final String? quantity;
  final String? frequency;
  final String? duration;
  final String? route;
  final String status;
  final String intent;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'medicationName': medicationName,
    if (dciCode != null) 'dciCode': dciCode,
    if (iumCode != null) 'iumCode': iumCode,
    if (dosage != null) 'dosage': dosage,
    if (quantity != null) 'quantity': quantity,
    if (frequency != null) 'frequency': frequency,
    if (duration != null) 'duration': duration,
    if (route != null) 'route': route,
    'status': status,
    'intent': intent,
    if (notes != null) 'notes': notes,
  };

  MedicationRequestItem copyWith({
    String? medicationName,
    String? dciCode,
    String? iumCode,
    String? dosage,
    String? quantity,
    String? frequency,
    String? duration,
    String? route,
    String? status,
    String? intent,
    String? notes,
  }) {
    return MedicationRequestItem(
      medicationName: medicationName ?? this.medicationName,
      dciCode: dciCode ?? this.dciCode,
      iumCode: iumCode ?? this.iumCode,
      dosage: dosage ?? this.dosage,
      quantity: quantity ?? this.quantity,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      route: route ?? this.route,
      status: status ?? this.status,
      intent: intent ?? this.intent,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationRequestItem &&
          runtimeType == other.runtimeType &&
          medicationName == other.medicationName &&
          dciCode == other.dciCode &&
          iumCode == other.iumCode &&
          dosage == other.dosage &&
          quantity == other.quantity &&
          frequency == other.frequency &&
          duration == other.duration &&
          route == other.route &&
          status == other.status &&
          intent == other.intent &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
    medicationName,
    dciCode,
    iumCode,
    dosage,
    quantity,
    frequency,
    duration,
    route,
    status,
    intent,
    notes,
  );
}

// ---------------------------------------------------------------------------
// MedicalHistoryItem — One clinical encounter (RDA-Consulta)
// ---------------------------------------------------------------------------
class MedicalHistoryItem {
  MedicalHistoryItem({
    this.encounterIdentifier,
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
    this.externalCauseDisplay,
    this.healthcareServiceCode,
    this.healthcareServiceDisplay,
    this.cupsCode,
    this.cupsDisplay,
    this.occupation,
    this.occupationDescription,
    this.prescriptions = const <MedicationRequestItem>[],
  }) : clinicalEvaluation = clinicalEvaluation ?? ClinicalEvaluation();

  factory MedicalHistoryItem.fromJson(Map<String, dynamic> json) {
    return MedicalHistoryItem(
      encounterIdentifier: json['encounterIdentifier']?.toString(),
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
      externalCauseDisplay: json['externalCauseDisplay']?.toString(),
      healthcareServiceCode: json['healthcareServiceCode']?.toString(),
      healthcareServiceDisplay: json['healthcareServiceDisplay']?.toString(),
      cupsCode: json['cupsCode']?.toString(),
      cupsDisplay: json['cupsDisplay']?.toString(),
      occupation: json['occupation']?.toString(),
      occupationDescription: json['occupationDescription']?.toString(),
      prescriptions:
          (json['prescriptions'] as List<dynamic>?)
              ?.map(
                (e) =>
                    MedicationRequestItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <MedicationRequestItem>[],
    );
  }

  final String type;
  final String startDateTime;
  final String? endDateTime;
  final String? encounterIdentifier;
  final String careModality;
  final String serviceGroup;
  final String careEnvironment;
  final String? entryRoute;
  final String? externalCause;
  final ProviderInfo? provider;
  final PractitionerInfo? practitioner;
  final String? location;
  final String? physician;
  final ClinicalEvaluation clinicalEvaluation;
  final List<DiagnosisItem> diagnosis;
  final String diagnosisType;
  final String? dischargeDisposition;
  final List<RiskFactor> riskFactors;
  final IncapacityInfo? incapacity;
  final PayerInfo? payer;

  final String? externalCauseDisplay;
  final String? healthcareServiceCode;
  final String? healthcareServiceDisplay;
  final String? cupsCode;
  final String? cupsDisplay;
  final String? occupation;
  final String? occupationDescription;
  final List<MedicationRequestItem> prescriptions;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (encounterIdentifier != null) 'encounterIdentifier': encounterIdentifier,
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
    if (externalCauseDisplay != null)
      'externalCauseDisplay': externalCauseDisplay,
    if (healthcareServiceCode != null)
      'healthcareServiceCode': healthcareServiceCode,
    if (healthcareServiceDisplay != null)
      'healthcareServiceDisplay': healthcareServiceDisplay,
    if (cupsCode != null) 'cupsCode': cupsCode,
    if (cupsDisplay != null) 'cupsDisplay': cupsDisplay,
    if (occupation != null) 'occupation': occupation,
    if (occupationDescription != null)
      'occupationDescription': occupationDescription,
    'prescriptions': prescriptions.map((m) => m.toJson()).toList(),
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
    this.guardian2Info,
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
      guardian2Info: json['guardian2Info'] is Map<String, dynamic>
          ? GuardianInfo.fromJson(json['guardian2Info'] as Map<String, dynamic>)
          : null,
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

  final String patientId;
  final String deviceUid;
  final PatientInfo patientInfo;
  final GuardianInfo guardianInfo;
  final GuardianInfo? guardian2Info;
  final BackgroundHistory? backgroundHistory;
  final List<AllergyInfo> allergies;
  final List<MedicalHistoryItem> medicalHistory;
  final List<VaccinationRecordItem> vaccinationRecord;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'patientId': patientId,
    'device_uid': deviceUid,
    'patientInfo': patientInfo.toJson(),
    'guardianInfo': guardianInfo.toJson(),
    if (guardian2Info != null) 'guardian2Info': guardian2Info!.toJson(),
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

  PatientFullRecord copyWith({
    String? patientId,
    String? deviceUid,
    PatientInfo? patientInfo,
    GuardianInfo? guardianInfo,
    GuardianInfo? guardian2Info,
    BackgroundHistory? backgroundHistory,
    List<AllergyInfo>? allergies,
    List<MedicalHistoryItem>? medicalHistory,
    List<VaccinationRecordItem>? vaccinationRecord,
  }) {
    return PatientFullRecord(
      patientId: patientId ?? this.patientId,
      deviceUid: deviceUid ?? this.deviceUid,
      patientInfo: patientInfo ?? this.patientInfo,
      guardianInfo: guardianInfo ?? this.guardianInfo,
      guardian2Info: guardian2Info ?? this.guardian2Info,
      backgroundHistory: backgroundHistory ?? this.backgroundHistory,
      allergies: allergies ?? this.allergies,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      vaccinationRecord: vaccinationRecord ?? this.vaccinationRecord,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientFullRecord &&
          runtimeType == other.runtimeType &&
          patientId == other.patientId &&
          deviceUid == other.deviceUid &&
          patientInfo == other.patientInfo &&
          guardianInfo == other.guardianInfo &&
          guardian2Info == other.guardian2Info &&
          backgroundHistory == other.backgroundHistory &&
          _listEquals(allergies, other.allergies) &&
          _listEquals(medicalHistory, other.medicalHistory) &&
          _listEquals(vaccinationRecord, other.vaccinationRecord);

  @override
  int get hashCode => Object.hash(
    patientId,
    deviceUid,
    patientInfo,
    guardianInfo,
    guardian2Info,
    backgroundHistory,
    Object.hashAll(allergies),
    Object.hashAll(medicalHistory),
    Object.hashAll(vaccinationRecord),
  );
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
