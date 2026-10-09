// lib/src/features/nfc/presentation/profile/state/patient_draft_controller.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../../core/sync/sync_engine.dart';
import '../../../domain/patient_record.dart';

/// What [PatientDraftController.applySyncResult] did with a saved record.
enum SyncResultEffect {
  /// Another patient's record, or another copy of this one that the draft
  /// does not come from: the draft keeps its version.
  ignored,

  /// The draft is what was sent: it is synced and carries the new version.
  synced,

  /// The draft changed while the sync was in flight. It carries the new
  /// version now and must be saved again, so the pending copy does too.
  resaveDraft,

  /// The server merged the copy and sent its record back: the draft is now
  /// the server's.
  replacedByServer,

  /// The server merged the copy without sending its record. The draft keeps
  /// its old version, so what is edited next is merged too, never applied
  /// over the server's copy.
  conflictsKept,
}

class PatientDraftController extends ChangeNotifier {
  PatientDraftController(PatientFullRecord initial)
    : _draft = initial,
      _original = initial;

  PatientFullRecord _draft;
  PatientFullRecord _original;

  PatientFullRecord get draft => _draft;
  PatientFullRecord get original => _original;
  bool get hasUnsyncedChanges => _draft != _original;

  /// Starts over from [record], taken as what the server has.
  void reset(PatientFullRecord record) {
    _draft = record;
    _original = record;
    notifyListeners();
  }

  /// Takes in what the server answered for a sync of this patient.
  ///
  /// The next edit is sent with the version set here as its baseVersion; an
  /// older one would make the server take it for an old copy and keep its
  /// guardians and allergies.
  SyncResultEffect applySyncResult(RecordSyncResult result) {
    if (result.patientId != _draft.patientId) return SyncResultEffect.ignored;
    final bool draftWasSent = sameContent(_draft, result.sent);

    if (result.hasConflicts) {
      final PatientFullRecord? server = result.serverRecord;
      if (server != null && draftWasSent) {
        reset(server);
        return SyncResultEffect.replacedByServer;
      }
      if (draftWasSent) {
        _original = _draft;
        notifyListeners();
      }
      return SyncResultEffect.conflictsKept;
    }

    // Another copy of this patient (a row queued before the screen opened)
    // and no edit here: the server now holds more than the draft shows. Its
    // version stays, so what is edited next is merged, not applied over it.
    if (!draftWasSent && !hasUnsyncedChanges) return SyncResultEffect.ignored;

    final int? version = result.recordVersion;
    _draft = _draft.copyWith(recordVersion: version);
    _original = draftWasSent
        ? _draft
        : result.sent.copyWith(recordVersion: version);
    notifyListeners();
    return draftWasSent || version == null
        ? SyncResultEffect.synced
        : SyncResultEffect.resaveDraft;
  }

  /// Whether two copies hold the same data, whatever their version.
  ///
  /// Compared as JSON after a round trip: a synced copy comes back from the
  /// local queue, and not every item type compares by value.
  @visibleForTesting
  static bool sameContent(PatientFullRecord a, PatientFullRecord b) =>
      _content(a) == _content(b);

  static String _content(PatientFullRecord record) => jsonEncode(
    PatientFullRecord.fromJson(record.toJson()).toJson()..remove('baseVersion'),
  );

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
