// lib/src/features/nfc/domain/register_draft.dart

import 'dart:ui' show Offset;

import 'package:uuid/uuid.dart';
import 'patient_record.dart';

class RegisterDraft {
  String? deviceUid;
  String documentType = 'TI';
  String documentNumber = '';
  String firstName = '';
  String? secondName;
  String firstLastName = '';
  String? secondLastName;
  DateTime? dob;
  String biologicalSex = 'F';
  String? genderIdentity;
  String nationalityCode = 'COL';
  String? nationalityName = 'Colombia';
  String? ethnicity;
  String? ethnicCommunity;
  String? disabilityCategory;
  String? bloodType;
  double? weight;
  double? height;
  String? street;
  String addressCity = '';
  String? cityCode;
  String addressState = '';
  String? zone;
  String? guardianName;
  String? guardianRelationship;
  String? guardianPhone;
  String? guardianDeviceUid;
  String? guardianDocType;
  String? guardianDocNumber;
  bool? guardianAuthAccepted;
  String? guardianEmail;
  String? guardianSignatureBase64;

  List<List<Offset>> guardianSignatureStrokes = <List<Offset>>[];
  String? guardian2Name;
  String? guardian2Relationship;
  String? guardian2Phone;
  String? guardian2DeviceUid;
  String? guardian2DocType;
  String? guardian2DocNumber;
  bool? guardian2AuthAccepted;
  String? guardian2Email;
  String? guardian2SignatureBase64;

  List<List<Offset>> guardian2SignatureStrokes = <List<Offset>>[];
  List<ChronicConditionItem> chronicConditions = [];
  String? personalHistory;
  List<FamilyHistoryItem> familyHistory = [];
  List<MedicationStatementItem> medications = [];
  List<AllergyInfo> allergies = [];

  PatientFullRecord toRecord() {
    final dobStr = dob != null
        ? '${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}'
        : '';
    return PatientFullRecord(
      patientId: const Uuid().v4(),
      deviceUid: deviceUid ?? '',
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: documentType,
          documentNumber: documentNumber,
        ),
        firstName: firstName,
        secondName: secondName,
        firstLastName: firstLastName,
        secondLastName: secondLastName,
        dob: dobStr,
        nationalityCode: nationalityCode,
        nationalityName: nationalityName,
        biologicalSex: biologicalSex,
        genderIdentity: genderIdentity,
        ethnicity: ethnicity,
        ethnicCommunity: ethnicCommunity,
        disabilityCategory: disabilityCategory,
        address: Address(
          street: street,
          city: addressCity,
          cityCode: cityCode,
          state: addressState,
          country: 'COL',
          countryName: 'Colombia',
          zone: zone,
        ),
        bloodType: bloodType,
        weight: weight,
        height: height,
      ),
      guardianInfo: GuardianInfo(
        name: guardianName ?? '',
        relationship: guardianRelationship ?? '01',
        phone: guardianPhone ?? '',
        deviceUid: guardianDeviceUid,
        documentType: guardianDocType,
        documentNumber: guardianDocNumber,
        consent: (guardianAuthAccepted == true)
            ? GuardianConsent(
                accepted: true,
                acceptedAt: DateTime.now().toIso8601String(),
                email: guardianEmail,
                signatureBase64: guardianSignatureBase64,
              )
            : null,
      ),
      guardian2Info: guardian2Name != null && guardian2Name!.isNotEmpty
          ? GuardianInfo(
              name: guardian2Name!,
              relationship: guardian2Relationship ?? '01',
              phone: guardian2Phone ?? '',
              deviceUid: guardian2DeviceUid,
              documentType: guardian2DocType,
              documentNumber: guardian2DocNumber,
              consent: (guardian2AuthAccepted == true)
                  ? GuardianConsent(
                      accepted: true,
                      acceptedAt: DateTime.now().toIso8601String(),
                      email: guardian2Email,
                      signatureBase64: guardian2SignatureBase64,
                    )
                  : null,
            )
          : null,
      backgroundHistory: BackgroundHistory(
        chronicConditions: chronicConditions,
        personalHistory: personalHistory,
        familyHistory: familyHistory,
        medications: medications,
      ),
      allergies: allergies,
      medicalHistory: const [],
      vaccinationRecord: const [],
    );
  }
}
