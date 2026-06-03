// lib/src/features/nfc/presentation/profile/patient_profile_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../design/tokens/app_colors.dart';
import '../../../../shared/widgets/screen_bottom_handle.dart';
import '../../../auth/domain/user_session.dart';
import '../../domain/patient_record.dart';
import '../add_consultation_screen.dart';
import '../add_vaccine_screen.dart';
import 'sheets/add_allergy_sheet.dart';
import 'sheets/add_chronic_condition_sheet.dart';
import 'sheets/add_family_history_sheet.dart';
import 'sheets/add_medication_sheet.dart';
import 'sheets/edit_address_sheet.dart';
import 'sheets/edit_chronic_personal_sheet.dart';
import 'sheets/edit_guardian_sheet.dart';
import 'sheets/edit_vital_signs_sheet.dart';
import 'tabs/profile_tab_consultations.dart';
import 'tabs/profile_tab_summary.dart';
import 'tabs/profile_tab_vaccines.dart';
import '../../../home/presentation/home_screen.dart';

/// Canonical patient profile screen.
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({
    super.key,
    required this.patient,
    this.lastSyncedAt,
  });

  final PatientFullRecord patient;
  final String? lastSyncedAt;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PatientFullRecord _draft;
  late PatientFullRecord _original; // for change detection
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _draft = widget.patient;
    _original = widget.patient;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasUnsyncedChanges {
    return _draft.toJson().toString() != _original.toJson().toString();
  }

  UserRole get _currentRole =>
      AppScope.of(context).authRepository.currentUser?.role ?? UserRole.doctor;

  // ── Mutators (called by tabs/sheets) ─────────────────────────────────────

  void _updateVitalSigns({double? weight, double? height}) {
    setState(() {
      _draft = _replacePatientInfo(
        _draft.patientInfo.copyWith(weight: weight, height: height),
      );
    });
  }

  void _updateAddress(Address address) {
    setState(() {
      _draft = _replacePatientInfo(
        PatientInfo(
          identification: _draft.patientInfo.identification,
          firstLastName: _draft.patientInfo.firstLastName,
          secondLastName: _draft.patientInfo.secondLastName,
          firstName: _draft.patientInfo.firstName,
          secondName: _draft.patientInfo.secondName,
          dob: _draft.patientInfo.dob,
          nationalityCode: _draft.patientInfo.nationalityCode,
          nationalityName: _draft.patientInfo.nationalityName,
          biologicalSex: _draft.patientInfo.biologicalSex,
          genderIdentity: _draft.patientInfo.genderIdentity,
          ethnicity: _draft.patientInfo.ethnicity,
          ethnicCommunity: _draft.patientInfo.ethnicCommunity,
          disabilityCategory: _draft.patientInfo.disabilityCategory,
          address: address,
          bloodType: _draft.patientInfo.bloodType,
          weight: _draft.patientInfo.weight,
          height: _draft.patientInfo.height,
        ),
      );
    });
  }

  void _updateGuardian(GuardianInfo guardian) {
    setState(() {
      _draft = PatientFullRecord(
        patientId: _draft.patientId,
        deviceUid: _draft.deviceUid,
        patientInfo: _draft.patientInfo,
        guardianInfo: guardian,
        guardian2Info: _draft.guardian2Info,
        backgroundHistory: _draft.backgroundHistory,
        allergies: _draft.allergies,
        medicalHistory: _draft.medicalHistory,
        vaccinationRecord: _draft.vaccinationRecord,
      );
    });
  }

  void _updateBackground({
    List<ChronicConditionItem>? chronicConditions,
    String? personalHistory,
  }) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    setState(() {
      _draft = _replaceBackground(
        BackgroundHistory(
          chronicConditions: chronicConditions ?? old.chronicConditions,
          personalHistory: personalHistory ?? old.personalHistory,
          familyHistory: old.familyHistory,
          familyHistoryNotes: old.familyHistoryNotes,
          medications: old.medications,
        ),
      );
    });
  }

  void _addChronicCondition(ChronicConditionItem item) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    setState(() {
      _draft = _replaceBackground(
        BackgroundHistory(
          chronicConditions: [...old.chronicConditions, item],
          personalHistory: old.personalHistory,
          familyHistory: old.familyHistory,
          familyHistoryNotes: old.familyHistoryNotes,
          medications: old.medications,
        ),
      );
    });
  }

  void _removeChronicCondition(int index) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    final updated = [...old.chronicConditions]..removeAt(index);
    setState(() {
      _draft = _replaceBackground(
        BackgroundHistory(
          chronicConditions: updated,
          personalHistory: old.personalHistory,
          familyHistory: old.familyHistory,
          familyHistoryNotes: old.familyHistoryNotes,
          medications: old.medications,
        ),
      );
    });
  }

  void _addMedication(MedicationStatementItem item) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    setState(() {
      _draft = _replaceBackground(
        BackgroundHistory(
          chronicConditions: old.chronicConditions,
          personalHistory: old.personalHistory,
          familyHistory: old.familyHistory,
          familyHistoryNotes: old.familyHistoryNotes,
          medications: [...old.medications, item],
        ),
      );
    });
  }

  void _removeMedication(int index) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    final updated = [...old.medications]..removeAt(index);
    setState(() {
      _draft = _replaceBackground(
        BackgroundHistory(
          chronicConditions: old.chronicConditions,
          personalHistory: old.personalHistory,
          familyHistory: old.familyHistory,
          familyHistoryNotes: old.familyHistoryNotes,
          medications: updated,
        ),
      );
    });
  }

  void _addFamilyHistory(FamilyHistoryItem item) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    setState(() {
      _draft = _replaceBackground(
        BackgroundHistory(
          chronicConditions: old.chronicConditions,
          personalHistory: old.personalHistory,
          familyHistory: [...old.familyHistory, item],
          familyHistoryNotes: old.familyHistoryNotes,
          medications: old.medications,
        ),
      );
    });
  }

  void _removeFamilyHistory(int index) {
    final old = _draft.backgroundHistory ?? BackgroundHistory();
    final updated = [...old.familyHistory]..removeAt(index);
    setState(() {
      _draft = _replaceBackground(
        BackgroundHistory(
          chronicConditions: old.chronicConditions,
          personalHistory: old.personalHistory,
          familyHistory: updated,
          familyHistoryNotes: old.familyHistoryNotes,
          medications: old.medications,
        ),
      );
    });
  }

  void _addAllergy(AllergyInfo allergy) {
    setState(() {
      _draft = PatientFullRecord(
        patientId: _draft.patientId,
        deviceUid: _draft.deviceUid,
        patientInfo: _draft.patientInfo,
        guardianInfo: _draft.guardianInfo,
        guardian2Info: _draft.guardian2Info,
        backgroundHistory: _draft.backgroundHistory,
        allergies: [..._draft.allergies, allergy],
        medicalHistory: _draft.medicalHistory,
        vaccinationRecord: _draft.vaccinationRecord,
      );
    });
  }

  void _removeAllergy(int index) {
    final updated = [..._draft.allergies]..removeAt(index);
    setState(() {
      _draft = PatientFullRecord(
        patientId: _draft.patientId,
        deviceUid: _draft.deviceUid,
        patientInfo: _draft.patientInfo,
        guardianInfo: _draft.guardianInfo,
        guardian2Info: _draft.guardian2Info,
        backgroundHistory: _draft.backgroundHistory,
        allergies: updated,
        medicalHistory: _draft.medicalHistory,
        vaccinationRecord: _draft.vaccinationRecord,
      );
    });
  }

  void _addVaccine(VaccinationRecordItem vaccine) {
    setState(() {
      _draft = PatientFullRecord(
        patientId: _draft.patientId,
        deviceUid: _draft.deviceUid,
        patientInfo: _draft.patientInfo,
        guardianInfo: _draft.guardianInfo,
        guardian2Info: _draft.guardian2Info,
        backgroundHistory: _draft.backgroundHistory,
        allergies: _draft.allergies,
        medicalHistory: _draft.medicalHistory,
        vaccinationRecord: [..._draft.vaccinationRecord, vaccine],
      );
    });
  }

  void _addConsultation(MedicalHistoryItem consultation) {
    setState(() {
      _draft = PatientFullRecord(
        patientId: _draft.patientId,
        deviceUid: _draft.deviceUid,
        patientInfo: _draft.patientInfo,
        guardianInfo: _draft.guardianInfo,
        guardian2Info: _draft.guardian2Info,
        backgroundHistory: _draft.backgroundHistory,
        allergies: _draft.allergies,
        medicalHistory: [..._draft.medicalHistory, consultation],
        vaccinationRecord: _draft.vaccinationRecord,
      );
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  PatientFullRecord _replacePatientInfo(PatientInfo info) => PatientFullRecord(
    patientId: _draft.patientId,
    deviceUid: _draft.deviceUid,
    patientInfo: info,
    guardianInfo: _draft.guardianInfo,
    guardian2Info: _draft.guardian2Info,
    backgroundHistory: _draft.backgroundHistory,
    allergies: _draft.allergies,
    medicalHistory: _draft.medicalHistory,
    vaccinationRecord: _draft.vaccinationRecord,
  );

  PatientFullRecord _replaceBackground(BackgroundHistory bg) =>
      PatientFullRecord(
        patientId: _draft.patientId,
        deviceUid: _draft.deviceUid,
        patientInfo: _draft.patientInfo,
        guardianInfo: _draft.guardianInfo,
        guardian2Info: _draft.guardian2Info,
        backgroundHistory: bg,
        allergies: _draft.allergies,
        medicalHistory: _draft.medicalHistory,
        vaccinationRecord: _draft.vaccinationRecord,
      );

  // ── Sync ─────────────────────────────────────────────────────────────────

  Future<void> _sync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
    });
    try {
      final scope = AppScope.of(context);
      await scope.localDatabase.savePatient(_draft);
      scope.syncEngine.syncAll().ignore();
      if (!mounted) return;
      setState(() {
        _original = _draft;
        _isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).savedChangesMsg),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  Future<void> _navigateAddConsultation() async {
    if (!_currentRole.canAddConsultation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).notAuthorizedConsultations),
        ),
      );
      return;
    }
    final result = await Navigator.of(context).push<MedicalHistoryItem>(
      MaterialPageRoute(
        builder: (_) =>
            AddConsultationScreen(patient: _draft, returnToProfile: true),
      ),
    );
    if (result != null) {
      _addConsultation(result);
    }
  }

  Future<void> _navigateAddVaccine() async {
    final result = await Navigator.of(context).push<VaccinationRecordItem>(
      MaterialPageRoute(
        builder: (_) =>
            AddVaccineScreen(patient: _draft, returnToProfile: true),
      ),
    );
    if (result != null) {
      _addVaccine(result);
    }
  }

  // ── Sheets ────────────────────────────────────────────────────────────────

  Future<void> _openVitalSignsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditVitalSignsSheet(
        weight: _draft.patientInfo.weight,
        height: _draft.patientInfo.height,
        previousWeight: _original.patientInfo.weight,
        previousHeight: _original.patientInfo.height,
        onConfirm: _updateVitalSigns,
      ),
    );
  }

  Future<void> _openAddressSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditAddressSheet(
        address: _draft.patientInfo.address,
        onConfirm: _updateAddress,
      ),
    );
  }

  Future<void> _openGuardianSheet() async {
    final current = _draft.guardianInfo;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          EditGuardianSheet(guardian: current, onConfirm: _updateGuardian),
    );
  }

  Future<void> _openEditPersonalSheet() async {
    final bg = _draft.backgroundHistory ?? BackgroundHistory();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditChronicPersonalSheet(
        title: AppStrings.of(context).personalHistoryTitle,
        currentValue: bg.personalHistory,
        onConfirm: (text) {
          _updateBackground(personalHistory: text);
        },
      ),
    );
  }

  Future<void> _openAddChronicConditionSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddChronicConditionSheet(onAdd: _addChronicCondition),
    );
  }

  Future<void> _openAddMedicationSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMedicationSheet(onAdd: _addMedication),
    );
  }

  Future<void> _openAddFamilyHistorySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFamilyHistorySheet(onAdd: _addFamilyHistory),
    );
  }

  Future<void> _openAddAllergySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAllergySheet(onAdd: _addAllergy),
    );
  }

  void _openAllergiesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllergiesManageSheet(
        allergies: _draft.allergies,
        onAdd: () async {
          Navigator.of(context).pop();
          await _openAddAllergySheet();
        },
        onRemove: (i) {
          _removeAllergy(i);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openBackgroundSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BackgroundManageSheet(
        draft: _draft,
        onAddChronic: () {
          Navigator.of(context).pop();
          _openAddChronicConditionSheet();
        },
        onRemoveChronic: (i) {
          _removeChronicCondition(i);
          Navigator.of(context).pop();
        },
        onEditPersonal: () {
          Navigator.of(context).pop();
          _openEditPersonalSheet();
        },
        onAddFamily: () {
          Navigator.of(context).pop();
          _openAddFamilyHistorySheet();
        },
        onRemoveFamily: (i) {
          _removeFamilyHistory(i);
          Navigator.of(context).pop();
        },
        onAddMedication: () {
          Navigator.of(context).pop();
          _openAddMedicationSheet();
        },
        onRemoveMedication: (i) {
          _removeMedication(i);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = _draft;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _ProfileHeader(
                  patient: p,
                  hasUnsyncedChanges: _hasUnsyncedChanges,
                  isSyncing: _isSyncing,
                  lastSyncedAt: widget.lastSyncedAt,
                  onBack: () => _confirmExit(),
                  onSync: _sync,
                ),
                _ProfileTabsBar(controller: _tabController, draft: _draft),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ProfileTabSummary(
                        draft: _draft,
                        original: _original,
                        canEdit:
                            _currentRole.canAddConsultation ||
                            _currentRole.canAddVaccine,
                        onEditVitalSigns: _openVitalSignsSheet,
                        onEditAddress: _openAddressSheet,
                        onEditGuardian: _openGuardianSheet,
                        onOpenAllergies: _openAllergiesSheet,
                        onOpenBackground: _openBackgroundSheet,
                      ),
                      ProfileTabConsultations(
                        draft: _draft,
                        canAdd: _currentRole.canAddConsultation,
                        onAdd: _navigateAddConsultation,
                      ),
                      ProfileTabVaccines(
                        draft: _draft,
                        onAdd: _navigateAddVaccine,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 116,
              right: 116,
              bottom: 14,
              child: ScreenBottomHandle(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    if (!_hasUnsyncedChanges) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.of(context).unsyncedChangesTitle),
        content: Text(AppStrings.of(context).exitWithoutSyncMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppStrings.of(context).exit,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER (avatar, name, age, ID, sync status, sync button)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.patient,
    required this.hasUnsyncedChanges,
    required this.isSyncing,
    required this.onBack,
    required this.onSync,
    this.lastSyncedAt,
  });

  final PatientFullRecord patient;
  final bool hasUnsyncedChanges;
  final bool isSyncing;
  final VoidCallback onBack;
  final VoidCallback onSync;
  final String? lastSyncedAt;

  int? get _age {
    try {
      final parts = patient.patientInfo.dob.split('-');
      if (parts.length != 3) return null;
      final dob = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final now = DateTime.now();
      var age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _sexLabel(BuildContext context) {
    final s = AppStrings.of(context);
    switch (patient.patientInfo.biologicalSex) {
      case 'M':
        return s.sexMale;
      case 'F':
        return s.sexFemale;
      default:
        return s.sexIndeterminate;
    }
  }

  String _docTypeLabel(BuildContext context) {
    final s = AppStrings.of(context);
    switch (patient.patientInfo.identification.documentType) {
      case 'RC':
        return s.docTypeRC;
      case 'TI':
        return s.docTypeTI;
      case 'CC':
        return s.docTypeCC;
      case 'CE':
        return s.docTypeCE;
      case 'PA':
        return s.docTypePA;
      case 'PE':
        return s.docTypePE;
      case 'PT':
        return s.docTypePT;
      case 'MS':
        return s.docTypeMS;
      case 'AS':
        return s.docTypeAS;
      default:
        return patient.patientInfo.identification.documentType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _age;
    final docNumber = patient.patientInfo.identification.documentNumber;
    final s = AppStrings.of(context);
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
              ),
              const Spacer(),
              _LanguageToggle(),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _Avatar(initials: _initials(patient.patientInfo.fullName)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.patientInfo.fullName,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (age != null)
                            _PillChip(
                              label:
                                  '$age ${s.yearsOldSuffix} · ${_sexLabel(context)}',
                              filled: true,
                            ),
                          if (docNumber.isNotEmpty)
                            _PillChip(
                              label: '${_docTypeLabel(context)} $docNumber',
                              filled: false,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasUnsyncedChanges
                        ? const Color(0xFFFFB300)
                        : const Color(0xFF00E676),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (hasUnsyncedChanges
                                    ? const Color(0xFFFFB300)
                                    : const Color(0xFF00E676))
                                .withValues(alpha: 0.55),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hasUnsyncedChanges
                      ? s.unsyncedChanges
                      : (lastSyncedAt != null
                            ? s.syncedAt.replaceAll('{time}', lastSyncedAt!)
                            : s.synced),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (hasUnsyncedChanges)
                  ElevatedButton.icon(
                    onPressed: isSyncing ? null : onSync,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      disabledBackgroundColor: const Color(0xFFFFB74D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    icon: isSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(
                            Icons.sync,
                            size: 16,
                            color: AppColors.white,
                          ),
                    label: Text(
                      isSyncing ? s.syncingBtn : s.syncBtn,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  static Color _avatarColor(String initials) {
    const colors = [
      Color(0xFFE6A817),
      Color(0xFF2563EB),
      Color(0xFF16A34A),
      Color(0xFFDC2626),
      Color(0xFF9333EA),
      Color(0xFF0891B2),
      Color(0xFFEA580C),
      Color(0xFF0F766E),
    ];
    var hash = 0;
    for (var i = 0; i < initials.length; i++) {
      hash = hash * 31 + initials.codeUnitAt(i);
    }
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: _avatarColor(initials),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({required this.label, this.filled = false});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled
            ? Colors.white.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.of(context);
    final isEs = loc.locale == 'es';
    return GestureDetector(
      onTap: () => loc.setLocale(isEs ? 'en' : 'es'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _LangDot(label: 'ES', selected: isEs),
            const SizedBox(width: 2),
            _LangDot(label: 'EN', selected: !isEs),
          ],
        ),
      ),
    );
  }
}

class _LangDot extends StatelessWidget {
  const _LangDot({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? AppColors.white : Colors.white.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TABS BAR
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTabsBar extends StatelessWidget {
  const _ProfileTabsBar({required this.controller, required this.draft});
  final TabController controller;
  final PatientFullRecord draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.white,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: '  ${AppStrings.of(context).tabSummary}  '),
          Tab(
            child: _TabLabelWithBadge(
              text: AppStrings.of(context).consultations,
              count: draft.medicalHistory.length,
            ),
          ),
          Tab(
            child: _TabLabelWithBadge(
              text: AppStrings.of(context).vaccines,
              count: draft.vaccinationRecord.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabelWithBadge extends StatelessWidget {
  const _TabLabelWithBadge({required this.text, required this.count});
  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Manage sheets (opened from Summary clickable sections)
// ═════════════════════════════════════════════════════════════════════════════

class _AllergiesManageSheet extends StatelessWidget {
  const _AllergiesManageSheet({
    required this.allergies,
    required this.onAdd,
    required this.onRemove,
  });
  final List<AllergyInfo> allergies;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${AppStrings.of(context).allergiesSheetTitle} · ${allergies.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: allergies.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.of(context).noAllergiesRegistered,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                      itemCount: allergies.length,
                      itemBuilder: (_, i) {
                        final a = allergies[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE3E5EA)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.allergen,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _catLabel(context, a.category),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (a.reaction != null &&
                                        a.reaction!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${AppStrings.of(context).reactionLabel}${a.reaction}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                onPressed: () => onRemove(i),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                      color: AppColors.white,
                    ),
                    label: Text(
                      AppStrings.of(context).addAllergyBtn,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _catLabel(BuildContext context, String c) {
    final s = AppStrings.of(context);
    switch (c) {
      case '01':
        return s.allergenMedication;
      case '02':
        return s.allergenFood;
      case '03':
        return s.allergenEnvironment;
      case '04':
        return s.allergenSkin;
      case '05':
        return s.allergenInsect;
      case '06':
        return s.allergenOther;
      default:
        return c;
    }
  }
}

class _BackgroundManageSheet extends StatelessWidget {
  const _BackgroundManageSheet({
    required this.draft,
    required this.onAddChronic,
    required this.onRemoveChronic,
    required this.onEditPersonal,
    required this.onAddFamily,
    required this.onRemoveFamily,
    required this.onAddMedication,
    required this.onRemoveMedication,
  });
  final PatientFullRecord draft;
  final VoidCallback onAddChronic;
  final void Function(int) onRemoveChronic;
  final VoidCallback onEditPersonal;
  final VoidCallback onAddFamily;
  final void Function(int) onRemoveFamily;
  final VoidCallback onAddMedication;
  final void Function(int) onRemoveMedication;

  @override
  Widget build(BuildContext context) {
    final bg = draft.backgroundHistory;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_edu_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.of(context).backgroundSheetTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                children: [
                  Row(
                    children: [
                      Text(
                        AppStrings.of(context).chronicConditions,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onAddChronic,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.of(context).add),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (bg == null || bg.chronicConditions.isEmpty)
                    Text(
                      AppStrings.of(context).noChronicConditions,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    for (var i = 0; i < bg.chronicConditions.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE3E5EA)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bg.chronicConditions[i].chronicDescription,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (bg
                                          .chronicConditions[i]
                                          .chronicCie10Code !=
                                      null)
                                    Text(
                                      '${AppStrings.of(context).cie10Label}${bg.chronicConditions[i].chronicCie10Code}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () => onRemoveChronic(i),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 12),
                  _BgSection(
                    title: AppStrings.of(context).personalHistoryTitle,
                    value: bg?.personalHistory,
                    onEdit: onEditPersonal,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        AppStrings.of(context).medications,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onAddMedication,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.of(context).add),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (bg == null || bg.medications.isEmpty)
                    Text(
                      AppStrings.of(context).noMedications,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    for (var i = 0; i < bg.medications.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE3E5EA)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bg.medications[i].medicationName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _medStatusLabel(
                                          context,
                                          bg.medications[i].status,
                                        ) +
                                        (bg.medications[i].dosage != null
                                            ? ' · ${bg.medications[i].dosage}'
                                            : ''),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () => onRemoveMedication(i),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        AppStrings.of(context).familyHistory,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onAddFamily,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppStrings.of(context).add),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (bg == null || bg.familyHistory.isEmpty)
                    Text(
                      AppStrings.of(context).noFamilyHistoryEntries,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    for (var i = 0; i < bg.familyHistory.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE3E5EA)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bg.familyHistory[i].conditionDescription,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _relLabel(
                                      context,
                                      bg.familyHistory[i].relationship,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () => onRemoveFamily(i),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relLabel(BuildContext context, String r) {
    final s = AppStrings.of(context);
    switch (r) {
      case '01':
        return s.relParents;
      case '02':
        return s.relSiblings;
      case '03':
        return s.relUncles;
      case '04':
        return s.relGrandparents;
      default:
        return r;
    }
  }

  String _medStatusLabel(BuildContext context, String c) {
    final s = AppStrings.of(context);
    switch (c) {
      case 'active':
        return s.medStatusActive;
      case 'completed':
        return s.medStatusCompleted;
      case 'stopped':
        return s.medStatusStopped;
      case 'unknown':
        return s.medStatusUnknown;
      default:
        return c;
    }
  }
}

class _BgSection extends StatelessWidget {
  const _BgSection({
    required this.title,
    required this.value,
    required this.onEdit,
  });
  final String title;
  final String? value;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE3E5EA)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value != null && value!.isNotEmpty ? value! : '—',
                    style: TextStyle(
                      fontSize: 13,
                      color: value != null && value!.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
