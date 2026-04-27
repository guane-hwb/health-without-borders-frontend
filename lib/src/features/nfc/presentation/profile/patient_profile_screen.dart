// lib/src/features/nfc/presentation/profile/patient_profile_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../design/tokens/app_colors.dart';
import '../../../../shared/widgets/screen_bottom_handle.dart';
import '../../../auth/domain/user_session.dart';
import '../../domain/patient_record.dart';
import '../add_consultation_screen.dart';
import '../add_vaccine_screen.dart';
import 'sheets/add_allergy_sheet.dart';
import 'sheets/add_family_history_sheet.dart';
import 'sheets/edit_address_sheet.dart';
import 'sheets/edit_chronic_personal_sheet.dart';
import 'sheets/edit_guardian_sheet.dart';
import 'sheets/edit_vital_signs_sheet.dart';
import 'tabs/profile_tab_allergies.dart';
import 'tabs/profile_tab_background.dart';
import 'tabs/profile_tab_consultations.dart';
import 'tabs/profile_tab_summary.dart';
import 'tabs/profile_tab_vaccines.dart';

/// Canonical patient profile screen.
///
/// Shows after:
///  • A successful NFC scan (read flow).
///  • A successful identity search (loss-of-wristband flow).
///  • A successful patient registration.
///
/// Displays a tab navigator (Resumen / Antecedentes / Consultas / Vacunas /
/// Alergias). The screen holds a *draft* of the patient record. All edits
/// (vital signs, allergies, vaccines, consultations, etc.) mutate this draft
/// in memory only. The user must tap "Sincronizar" to persist changes via
/// `POST /api/v1/patients/sync`.
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
  String? _syncError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _draft = widget.patient;
    _original = widget.patient;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasUnsyncedChanges {
    // Compare JSON of draft vs original
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
        backgroundHistory: _draft.backgroundHistory,
        allergies: _draft.allergies,
        medicalHistory: _draft.medicalHistory,
        vaccinationRecord: _draft.vaccinationRecord,
      );
    });
  }

  void _updateBackground({
    String? chronicConditions,
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
        backgroundHistory: _draft.backgroundHistory,
        allergies: _draft.allergies,
        medicalHistory: [..._draft.medicalHistory, consultation],
        vaccinationRecord: _draft.vaccinationRecord,
      );
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  PatientFullRecord _replacePatientInfo(PatientInfo info) =>
      PatientFullRecord(
        patientId: _draft.patientId,
        deviceUid: _draft.deviceUid,
        patientInfo: info,
        guardianInfo: _draft.guardianInfo,
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
      _syncError = null;
    });
    try {
      final scope = AppScope.of(context);
      // Save locally first (offline-first)
      await scope.localDatabase.savePatient(_draft);
      // Try cloud sync
      try {
        await scope.patientRepository.syncPatient(_draft);
        await scope.localDatabase.markSynced(_draft.patientId);
      } catch (_) {
        // Will be retried by the SyncEngine
      }
      if (!mounted) return;
      setState(() {
        _original = _draft; // baseline reset → no more diff
        _isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios sincronizados'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _syncError = e.message;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _syncError = e.toString();
      });
    }
  }

  // ── Navigation: add consultation ──────────────────────────────────────────

  Future<void> _navigateAddConsultation() async {
    if (!_currentRole.canAddConsultation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No autorizado: solo doctores pueden agregar consultas.'),
        ),
      );
      return;
    }
    final result = await Navigator.of(context).push<MedicalHistoryItem>(
      MaterialPageRoute(
        builder: (_) => AddConsultationScreen(
          patient: _draft,
          returnToProfile: true,
        ),
      ),
    );
    if (result != null) {
      _addConsultation(result);
    }
  }

  Future<void> _navigateAddVaccine() async {
    final result = await Navigator.of(context).push<VaccinationRecordItem>(
      MaterialPageRoute(
        builder: (_) => AddVaccineScreen(
          patient: _draft,
          returnToProfile: true,
        ),
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
    if (current == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditGuardianSheet(
        guardian: current,
        onConfirm: _updateGuardian,
      ),
    );
  }

  Future<void> _openChronicPersonalSheet({required bool chronic}) async {
    final bg = _draft.backgroundHistory ?? BackgroundHistory();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditChronicPersonalSheet(
        title: chronic ? 'Condiciones crónicas' : 'Historial personal',
        currentValue:
            chronic ? bg.chronicConditions : bg.personalHistory,
        onConfirm: (text) {
          if (chronic) {
            _updateBackground(chronicConditions: text);
          } else {
            _updateBackground(personalHistory: text);
          }
        },
      ),
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
                        onEditVitalSigns: _openVitalSignsSheet,
                        onEditAddress: _openAddressSheet,
                        onEditGuardian: _openGuardianSheet,
                      ),
                      ProfileTabBackground(
                        draft: _draft,
                        onEditChronic: () =>
                            _openChronicPersonalSheet(chronic: true),
                        onEditPersonal: () =>
                            _openChronicPersonalSheet(chronic: false),
                        onAddFamilyHistory: _openAddFamilyHistorySheet,
                        onRemoveFamilyHistory: _removeFamilyHistory,
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
                      ProfileTabAllergies(
                        draft: _draft,
                        onAdd: _openAddAllergySheet,
                        onRemove: _removeAllergy,
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
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambios sin sincronizar'),
        content: const Text(
            'Tienes cambios pendientes. ¿Salir sin sincronizar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salir',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
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
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
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

  String get _sexLabel {
    switch (patient.patientInfo.biologicalSex) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Femenino';
      default:
        return 'Indeterminado';
    }
  }

  String get _docTypeLabel {
    switch (patient.patientInfo.identification.documentType) {
      case 'RC':
        return 'Reg. civil';
      case 'TI':
        return 'Tarjeta identidad';
      case 'CC':
        return 'Cédula';
      case 'CE':
        return 'Céd. extranjería';
      case 'PA':
        return 'Pasaporte';
      case 'PE':
        return 'Permiso esp.';
      case 'PT':
        return 'PPT';
      case 'MS':
        return 'Menor s/ID';
      case 'AS':
        return 'Adulto s/ID';
      default:
        return patient.patientInfo.identification.documentType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _age;
    final docNumber = patient.patientInfo.identification.documentNumber;
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: back arrow, lang toggle, menu
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
              ),
              const Spacer(),
              _LanguageToggle(),
              const SizedBox(width: 4),
              const Icon(Icons.more_vert, color: AppColors.white),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 4),
          // Identity card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _Avatar(
                  initials: _initials(patient.patientInfo.fullName),
                ),
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
                              label: '$age años · $_sexLabel',
                              filled: true,
                            ),
                          if (docNumber.isNotEmpty)
                            _PillChip(
                              label: '$_docTypeLabel $docNumber',
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

          // Sync status row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasUnsyncedChanges
                        ? const Color(0xFFFFB300)
                        : const Color(0xFF66BB6A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  hasUnsyncedChanges
                      ? 'Cambios sin sincronizar'
                      : (lastSyncedAt != null
                          ? 'Sincronizado · $lastSyncedAt'
                          : 'Sincronizado'),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (hasUnsyncedChanges)
                  ElevatedButton.icon(
                    onPressed: isSyncing ? null : onSync,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      disabledBackgroundColor:
                          const Color(0xFFFFB74D),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
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
                        : const Icon(Icons.sync,
                            size: 16, color: AppColors.white),
                    label: Text(
                      isSyncing ? 'Sincronizando...' : 'Sincronizar',
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFE6A817),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700),
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
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: const TextStyle(color: AppColors.white, fontSize: 11)),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
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
        color:
            selected ? AppColors.white : Colors.white.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.white,
          fontSize: 11,
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
        indicatorPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.white,
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: [
          const Tab(text: '  Resumen  '),
          const Tab(text: '  Antecedentes  '),
          Tab(child: _TabLabelWithBadge(
              text: 'Consultas', count: draft.medicalHistory.length)),
          Tab(child: _TabLabelWithBadge(
              text: 'Vacunas', count: draft.vaccinationRecord.length)),
          Tab(child: _TabLabelWithBadge(
              text: 'Alergias', count: draft.allergies.length)),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ],
    );
  }
}
