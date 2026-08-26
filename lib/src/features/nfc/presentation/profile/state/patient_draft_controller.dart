// lib/src/features/nfc/presentation/profile/state/patient_draft_controller.dart

import 'package:flutter/foundation.dart';

import '../../../domain/patient_record.dart';

class PatientDraftController extends ChangeNotifier {
  PatientDraftController(PatientFullRecord initial)
    : _draft = initial,
      _original = initial;

  PatientFullRecord _draft;
  PatientFullRecord _original;

  PatientFullRecord get draft => _draft;
  PatientFullRecord get original => _original;
  bool get hasUnsyncedChanges => _draft != _original;

  void markSynced() {
    _original = _draft;
    notifyListeners();
  }

  // ── Signos vitales / dirección ──────────────────────────────────────────

  void updateVitalSigns({double? weight, double? height, String? bloodType}) {
    final info = _draft.patientInfo;
    _replacePatientInfo(
      PatientInfo(
        identification: info.identification,
        firstLastName: info.firstLastName,
        secondLastName: info.secondLastName,
        firstName: info.firstName,
        secondName: info.secondName,
        dob: info.dob,
        nationalityCode: info.nationalityCode,
        nationalityName: info.nationalityName,
        biologicalSex: info.biologicalSex,
        genderIdentity: info.genderIdentity,
        ethnicity: info.ethnicity,
        ethnicCommunity: info.ethnicCommunity,
        disabilityCategory: info.disabilityCategory,
        address: info.address,
        bloodType: bloodType,
        weight: weight ?? info.weight,
        height: height ?? info.height,
      ),
    );
  }

  void updateAddress(Address address) {
    _replacePatientInfo(_draft.patientInfo.copyWith(address: address));
  }

  // ── Guardianes ───────────────────────────────────────────────────────────

  void updateGuardian(int guardianIndex, GuardianInfo updatedGuardian) {
    _draft = _draft.copyWith(
      guardianInfo: guardianIndex == 1 ? updatedGuardian : _draft.guardianInfo,
      guardian2Info: guardianIndex == 2
          ? updatedGuardian
          : _draft.guardian2Info,
    );
    notifyListeners();
  }

  // ── Antecedentes (background) ───────────────────────────────────────────

  void updateBackground({
    List<ChronicConditionItem>? chronicConditions,
    String? personalHistory,
  }) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    _replaceBackground(
      BackgroundHistory(
        chronicConditions: chronicConditions ?? old.chronicConditions,
        personalHistory: personalHistory ?? old.personalHistory,
        familyHistory: old.familyHistory,
        familyHistoryNotes: old.familyHistoryNotes,
        medications: old.medications,
      ),
    );
  }

  void addChronicCondition(ChronicConditionItem item) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    _replaceBackground(
      BackgroundHistory(
        chronicConditions: [...old.chronicConditions, item],
        personalHistory: old.personalHistory,
        familyHistory: old.familyHistory,
        familyHistoryNotes: old.familyHistoryNotes,
        medications: old.medications,
      ),
    );
  }

  void removeChronicCondition(int index) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    final updated = [...old.chronicConditions]..removeAt(index);
    _replaceBackground(
      BackgroundHistory(
        chronicConditions: updated,
        personalHistory: old.personalHistory,
        familyHistory: old.familyHistory,
        familyHistoryNotes: old.familyHistoryNotes,
        medications: old.medications,
      ),
    );
  }

  void addMedication(MedicationStatementItem item) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    _replaceBackground(
      BackgroundHistory(
        chronicConditions: old.chronicConditions,
        personalHistory: old.personalHistory,
        familyHistory: old.familyHistory,
        familyHistoryNotes: old.familyHistoryNotes,
        medications: [...old.medications, item],
      ),
    );
  }

  void removeMedication(int index) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    final updated = [...old.medications]..removeAt(index);
    _replaceBackground(
      BackgroundHistory(
        chronicConditions: old.chronicConditions,
        personalHistory: old.personalHistory,
        familyHistory: old.familyHistory,
        familyHistoryNotes: old.familyHistoryNotes,
        medications: updated,
      ),
    );
  }

  void addFamilyHistory(FamilyHistoryItem item) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    _replaceBackground(
      BackgroundHistory(
        chronicConditions: old.chronicConditions,
        personalHistory: old.personalHistory,
        familyHistory: [...old.familyHistory, item],
        familyHistoryNotes: old.familyHistoryNotes,
        medications: old.medications,
      ),
    );
  }

  void removeFamilyHistory(int index) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    final updated = [...old.familyHistory]..removeAt(index);
    _replaceBackground(
      BackgroundHistory(
        chronicConditions: old.chronicConditions,
        personalHistory: old.personalHistory,
        familyHistory: updated,
        familyHistoryNotes: old.familyHistoryNotes,
        medications: old.medications,
      ),
    );
  }

  // ── Alergias / vacunas / consultas ──────────────────────────────────────

  void addAllergy(AllergyInfo allergy) {
    _draft = _draft.copyWith(allergies: [..._draft.allergies, allergy]);
    notifyListeners();
  }

  void removeAllergy(int index) {
    final updated = [..._draft.allergies]..removeAt(index);
    _draft = _draft.copyWith(allergies: updated);
    notifyListeners();
  }

  void addVaccines(List<VaccinationRecordItem> vaccines) {
    _draft = _draft.copyWith(
      vaccinationRecord: [..._draft.vaccinationRecord, ...vaccines],
    );
    notifyListeners();
  }

  void addConsultation(MedicalHistoryItem consultation) {
    _draft = _draft.copyWith(
      medicalHistory: [..._draft.medicalHistory, consultation],
    );
    notifyListeners();
  }

  // ── Internos ─────────────────────────────────────────────────────────────

  void _replacePatientInfo(PatientInfo info) {
    _draft = _draft.copyWith(patientInfo: info);
    notifyListeners();
  }

  void _replaceBackground(BackgroundHistory bg) {
    _draft = _draft.copyWith(backgroundHistory: bg);
    notifyListeners();
  }
}
