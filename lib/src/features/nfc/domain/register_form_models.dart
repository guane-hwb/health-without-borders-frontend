class VaccineEntry {
  VaccineEntry({
    required this.vaccine,
    required this.doses,
    required this.date,
    required this.administratedBy,
  });

  final String vaccine;
  final String doses;
  final String date;
  final String administratedBy;
}

class AllergenEntry {
  AllergenEntry({
    required this.allergen,
    required this.reaction,
    required this.severity,
    required this.notes,
  });

  final String allergen;
  final String reaction;
  final String severity;
  final String notes;
}

class RegisterNfcDraft {
  RegisterNfcDraft({
    required this.deviceUid,
    required this.firstName,
    required this.birthDate,
    required this.gender,
    required this.country,
    required this.guardianName,
    required this.guardianRelationship,
    required this.guardianAddress,
    required this.guardianContact,
    required this.weight,
    required this.height,
    required this.bloodType,
    required this.currentIllness,
    required this.personalHistory,
    required this.familyHistory,
    required this.generalPhysicalExamination,
    required this.systemsExamination,
    required this.medicalStaffName,
    required this.medicalStaffPlace,
    required this.medicalStaffDate,
    required this.vaccines,
    required this.allergens,
  });

  final String deviceUid;
  final String firstName;
  final String birthDate;
  final String gender;
  final String country;
  final String guardianName;
  final String guardianRelationship;
  final String guardianAddress;
  final String guardianContact;
  final String weight;
  final String height;
  final String bloodType;
  final String currentIllness;
  final String personalHistory;
  final String familyHistory;
  final String generalPhysicalExamination;
  final String systemsExamination;
  final String medicalStaffName;
  final String medicalStaffPlace;
  final String medicalStaffDate;
  final List<VaccineEntry> vaccines;
  final List<AllergenEntry> allergens;
}
