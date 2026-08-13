// lib/src/features/nfc/presentation/profile/patient_profile_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/nfc/nfc_guardian_payload.dart';
import '../../../../core/nfc/nfc_payload_codec.dart';
import '../../../../core/nfc/nfc_payload_service.dart';
import '../../../../core/nfc/nfc_triage_payload.dart';
import '../../../../core/nfc/partial_card_notice.dart';
import '../../../../core/storage/local_database.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../design/tokens/app_colors.dart';
import '../../../../shared/widgets/screen_bottom_handle.dart';
import '../../../auth/domain/user_session.dart';
import '../../domain/patient_record.dart';
import '../add_consultation_screen.dart';
import '../add_vaccine_screen.dart';
import '../nfc_guided_write.dart';
import 'patient_profile_helpers.dart';
import 'sheets/add_allergy_sheet.dart';
import 'sheets/add_chronic_condition_sheet.dart';
import 'sheets/add_family_history_sheet.dart';
import 'sheets/add_medication_sheet.dart';
import 'sheets/allergies_manage_sheet.dart';
import 'sheets/background_manage_sheet.dart';
import 'sheets/edit_address_sheet.dart';
import 'sheets/edit_chronic_personal_sheet.dart';
import 'sheets/edit_guardian_sheet.dart';
import 'sheets/edit_vital_signs_sheet.dart';
import 'tabs/profile_tab_consultations.dart';
import 'tabs/profile_tab_summary.dart';
import 'tabs/profile_tab_vaccines.dart';
import 'widgets/profile_banners.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_tabs_bar.dart';

/// Canonical patient profile screen.
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({
    super.key,
    required this.patient,
    this.lastSyncedAt,
    this.readOnly = false,
    this.offline = false,
    this.emergency = false,
  });

  final PatientFullRecord patient;
  final String? lastSyncedAt;
  final bool readOnly;
  final bool offline;
  final bool emergency;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PatientFullRecord _draft;
  late PatientFullRecord _original;
  bool _isSyncing = false;
  bool _hasInternet = true;
  NfcChipStatus? _chipStatus;
  bool _chipStatusLoaded = false;
  bool _isUpdatingChips = false;

  bool _lastSaveFailed = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _draft = widget.patient;
    _original = widget.patient;

    _checkInitialConnectivity();
    _subscribeToConnectivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_chipStatusLoaded) {
      _chipStatusLoaded = true;
      _loadChipStatus(AppScope.of(context).localDatabase);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (!mounted) return;
    _updateConnectivityStatus(result);
  }

  void _subscribeToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!mounted) return;
      _updateConnectivityStatus(results);
    });
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    if (!mounted) return;
    final hasNet = hasInternetConnection(results);
    if (_hasInternet != hasNet) {
      setState(() {
        _hasInternet = hasNet;
      });
      if (_hasInternet && _hasUnsyncedChanges) {
        _sync(silent: true);
      }
    }
  }

  bool get _hasUnsyncedChanges => _draft != _original;

  UserRole get _currentRole =>
      AppScope.of(context).authRepository.currentUser?.role ?? UserRole.doctor;

  Future<void> _markNfcChipsDirtyIfChanged(LocalDatabase db) async {
    if (_draft.patientId.isEmpty) return;
    if (_original == _draft) return;
    final triageChanged =
        jsonEncode(NfcTriagePayload.buildPatientPayload(record: _original)) !=
        jsonEncode(NfcTriagePayload.buildPatientPayload(record: _draft));
    await db.markChipsDirty(
      _draft.patientId,
      patient: triageChanged,
      guardian: true,
    );
    await _loadChipStatus(db);
  }

  Future<void> _loadChipStatus(LocalDatabase db) async {
    NfcChipStatus? status;
    try {
      status = await db.getChipStatus(_draft.patientId);
    } catch (_) {
      status = null;
    }
    if (!mounted) return;
    setState(() => _chipStatus = status);
  }

  Future<void> _updateNfcChips() async {
    if (_isUpdatingChips) return;
    final scope = AppScope.of(context);
    final isEs = AppStrings.of(context).isEs;

    final nfcKey = await scope.authRepository.getNfcEncryptionKey();
    if (!mounted) return;
    if (nfcKey == null || nfcKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEs
                ? 'No hay clave NFC disponible para grabar.'
                : 'No NFC key available to write.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final status = _chipStatus;
    if (status == null || !status.anyDirty) return;

    setState(() => _isUpdatingChips = true);
    final codec = NfcPayloadCodec(hexKey: nfcKey);
    final record = _draft;

    if (status.patientChipDirty) {
      final ok = await showNfcGuidedWrite(
        context,
        title: isEs ? 'Pulsera del paciente' : 'Patient wristband',
        instruction: isEs
            ? 'Acerque la pulsera del paciente al teléfono'
            : 'Bring the patient wristband to the phone',
        write: () => NfcPayloadService(codec: codec).writeTriagePayload(
          NfcTriagePayload.buildPatientPayload(record: record),
          expectedUid: record.deviceUid,
        ),
      );
      if (!mounted) return;
      if (ok) {
        await scope.localDatabase.clearChipsDirty(
          record.patientId,
          patient: true,
        );
      }
    }
    if (!mounted) return;

    if (status.guardianChipDirty) {
      final guardian1Uid = (record.guardianInfo.deviceUid ?? '').trim();
      final guardian2Uid = (record.guardian2Info?.deviceUid ?? '').trim();
      final hasTwoGuardians =
          guardian1Uid.isNotEmpty && guardian2Uid.isNotEmpty;
      final messenger = ScaffoldMessenger.of(context);

      Future<bool> writeGuardianCard({
        required String expectedUid,
        required String title,
        required String instruction,
      }) async {
        GuardianPayloadFit? fit;
        final written = await showNfcGuidedWrite(
          context,
          title: title,
          instruction: instruction,
          write: () async {
            final result = await NfcPayloadService(codec: codec)
                .writeGuardianRecord(
                  buildFit: guardianFitBuilder(record: record, codec: codec),
                  expectedUid: expectedUid,
                );
            fit = result.fit;
          },
        );
        if (written && (fit?.isPartial ?? false)) {
          _showPartialCardNotice(messenger, fit!, isEs);
        }
        return written;
      }

      var allWritten = true;

      if (guardian1Uid.isNotEmpty) {
        final ok = await writeGuardianCard(
          expectedUid: guardian1Uid,
          title: hasTwoGuardians
              ? (isEs ? 'Tarjeta del guardián 1' : 'Guardian card 1')
              : (isEs ? 'Tarjeta del guardián' : 'Guardian card'),
          instruction: hasTwoGuardians
              ? (isEs
                    ? 'Acerque la tarjeta del guardián 1 al teléfono'
                    : 'Bring guardian card 1 to the phone')
              : (isEs
                    ? 'Acerque la tarjeta del guardián al teléfono'
                    : 'Bring the guardian card to the phone'),
        );
        if (!mounted) return;
        allWritten = allWritten && ok;
      }

      if (guardian2Uid.isNotEmpty) {
        final ok = await writeGuardianCard(
          expectedUid: guardian2Uid,
          title: isEs ? 'Tarjeta del guardián 2' : 'Guardian card 2',
          instruction: isEs
              ? 'Acerque la tarjeta del guardián 2 al teléfono'
              : 'Bring guardian card 2 to the phone',
        );
        if (!mounted) return;
        allWritten = allWritten && ok;
      }

      final hadAnyGuardian = guardian1Uid.isNotEmpty || guardian2Uid.isNotEmpty;
      if (allWritten && hadAnyGuardian) {
        await scope.localDatabase.clearChipsDirty(
          record.patientId,
          guardian: true,
        );
      }
    }

    if (!mounted) return;
    await _loadChipStatus(scope.localDatabase);
    if (!mounted) return;
    setState(() => _isUpdatingChips = false);
  }

  void _showPartialCardNotice(
    ScaffoldMessengerState messenger,
    GuardianPayloadFit fit,
    bool isEs,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(partialCardNoticeMessage(fit, isEs)),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _saveAndPendingSync() async {
    final scope = AppScope.of(context);
    try {
      await scope.localDatabase.savePatient(_draft);
      await _markNfcChipsDirtyIfChanged(scope.localDatabase);
      if (mounted && _lastSaveFailed) {
        setState(() => _lastSaveFailed = false);
      }

      if (_hasInternet) {
        await _sync(silent: true);
      }
    } catch (e, stack) {
      AppLogger.e(
        'Fallo al persistir localmente el borrador del paciente',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return;
      setState(() => _lastSaveFailed = true);
      final isEs = AppStrings.of(context).isEs;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEs
                ? 'No se pudo guardar en el dispositivo. El cambio NO está a salvo.'
                : 'Could not save on this device. The change is NOT safe.',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: AppStrings.of(context).retry,
            textColor: AppColors.white,
            onPressed: _saveAndPendingSync,
          ),
        ),
      );
    }
  }

  void _updateVitalSigns({double? weight, double? height, String? bloodType}) {
    setState(() {
      _draft = _replacePatientInfo(
        _draft.patientInfo.copyWith(
          bloodType: bloodType,
          weight: weight ?? _draft.patientInfo.weight,
          height: height ?? _draft.patientInfo.height,
        ),
      );
    });
    _saveAndPendingSync();
  }

  void _updateAddress(Address address) {
    setState(() {
      _draft = _replacePatientInfo(
        _draft.patientInfo.copyWith(address: address),
      );
    });
    _saveAndPendingSync();
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
    _saveAndPendingSync();
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
    _saveAndPendingSync();
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
    _saveAndPendingSync();
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
    _saveAndPendingSync();
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
    _saveAndPendingSync();
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
    _saveAndPendingSync();
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
    _saveAndPendingSync();
  }

  void _addAllergy(AllergyInfo allergy) {
    setState(() {
      _draft = _draft.copyWith(allergies: [..._draft.allergies, allergy]);
    });
    _saveAndPendingSync();
  }

  void _removeAllergy(int index) {
    final updated = [..._draft.allergies]..removeAt(index);
    setState(() {
      _draft = _draft.copyWith(allergies: updated);
    });
    _saveAndPendingSync();
  }

  void _addVaccines(List<VaccinationRecordItem> vaccines) {
    setState(() {
      _draft = _draft.copyWith(
        vaccinationRecord: [..._draft.vaccinationRecord, ...vaccines],
      );
    });
    _saveAndPendingSync();
  }

  void _addConsultation(MedicalHistoryItem consultation) {
    setState(() {
      _draft = _draft.copyWith(
        medicalHistory: [..._draft.medicalHistory, consultation],
      );
    });
    _saveAndPendingSync();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  PatientFullRecord _replacePatientInfo(PatientInfo info) =>
      _draft.copyWith(patientInfo: info);

  PatientFullRecord _replaceBackground(BackgroundHistory bg) =>
      _draft.copyWith(backgroundHistory: bg);

  // ── Sync ─────────────────────────────────────────────────────────────────

  Future<void> _sync({bool silent = false}) async {
    if (widget.readOnly) return;
    if (_isSyncing) return;

    final isEs = AppStrings.of(context).isEs;

    if (!_hasInternet && !silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEs
                ? 'Sin conexión. Se sincronizará automáticamente al reconectar.'
                : 'Offline. It will sync automatically once reconnected.',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (!silent) {
      setState(() {
        _isSyncing = true;
      });
    }
    try {
      final scope = AppScope.of(context);
      await scope.localDatabase.savePatient(_draft);
      await _markNfcChipsDirtyIfChanged(scope.localDatabase);
      final bool ok = await scope.syncEngine.syncAll();
      if (!mounted) return;
      setState(() {
        if (ok) {
          _original = _draft;
        }
        _isSyncing = false;
      });
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? AppStrings.of(context).savedChangesMsg
                  : (isEs
                        ? 'Fallo al sincronizar con el servidor. Cambios preservados localmente.'
                        : 'Sync failed with server. Changes preserved locally.'),
            ),
            backgroundColor: ok ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
      });
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEs
                  ? 'Fallo al sincronizar con el servidor. Cambios preservados localmente.'
                  : 'Sync failed with server. Changes preserved locally.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  Future<void> _navigateAddConsultation() async {
    if (widget.readOnly) return;
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
    if (widget.readOnly) return;
    final result = await Navigator.of(context)
        .push<List<VaccinationRecordItem>>(
          MaterialPageRoute(
            builder: (_) =>
                AddVaccineScreen(patient: _draft, returnToProfile: true),
          ),
        );
    if (result != null && result.isNotEmpty) {
      _addVaccines(result);
    }
  }

  // ── Sheets ────────────────────────────────────────────────────────────────

  Future<void> _openVitalSignsSheet() async {
    if (widget.readOnly) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditVitalSignsSheet(
        weight: _draft.patientInfo.weight,
        height: _draft.patientInfo.height,
        bloodType: _draft.patientInfo.bloodType,
        previousWeight: _original.patientInfo.weight,
        previousHeight: _original.patientInfo.height,
        onConfirm: _updateVitalSigns,
      ),
    );
  }

  Future<void> _openAddressSheet() async {
    if (widget.readOnly) return;
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

  Future<void> _openGuardianSheet(int guardianIndex) async {
    if (widget.readOnly) return;
    final GuardianInfo? current = guardianIndex == 1
        ? _draft.guardianInfo
        : _draft.guardian2Info;
    if (current == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditGuardianSheet(
        guardian: current,
        guardianIndex: guardianIndex,
        onConfirm: (GuardianInfo updatedGuardian) {
          setState(() {
            _draft = _draft.copyWith(
              guardianInfo: guardianIndex == 1
                  ? updatedGuardian
                  : _draft.guardianInfo,
              guardian2Info: guardianIndex == 2
                  ? updatedGuardian
                  : _draft.guardian2Info,
            );
          });
          _saveAndPendingSync();
        },
      ),
    );
  }

  Future<void> _openEditPersonalSheet() async {
    if (widget.readOnly) return;
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
    if (widget.readOnly) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AllergiesManageSheet(
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
    if (widget.readOnly) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackgroundManageSheet(
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
                ProfileHeader(
                  patient: p,
                  hasUnsyncedChanges: !_hasInternet && _hasUnsyncedChanges,
                  lastSyncedAt: widget.lastSyncedAt,
                  onBack: () => _confirmExit(),
                  onSync: widget.readOnly ? null : () => _sync(silent: false),
                ),
                ProfileTabsBar(controller: _tabController, draft: _draft),
                if (widget.emergency) const EmergencyBanner(),
                if (!_hasInternet || widget.offline)
                  OfflineBanner(isDynamicDisconnect: !_hasInternet),
                if (!widget.readOnly && (_chipStatus?.anyDirty ?? false))
                  NfcStaleBanner(
                    isUpdating: _isUpdatingChips,
                    onUpdate: _updateNfcChips,
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ProfileTabSummary(
                        draft: _draft,
                        original: _original,
                        canEdit:
                            !widget.readOnly &&
                            (_currentRole.canAddConsultation ||
                                _currentRole.canAddVaccine),
                        onEditVitalSigns: _openVitalSignsSheet,
                        onEditAddress: _openAddressSheet,
                        onEditGuardian: _openGuardianSheet,
                        onOpenAllergies: _openAllergiesSheet,
                        onOpenBackground: _openBackgroundSheet,
                      ),
                      ProfileTabConsultations(
                        draft: _draft,
                        canAdd:
                            !widget.readOnly && _currentRole.canAddConsultation,
                        onAdd: _navigateAddConsultation,
                      ),
                      ProfileTabVaccines(
                        draft: _draft,
                        canEdit: !widget.readOnly && _currentRole.canAddVaccine,
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
    if (_lastSaveFailed) {
      final isEs = AppStrings.of(context).isEs;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isEs ? 'Cambios sin guardar' : 'Unsaved changes'),
          content: Text(
            isEs
                ? 'El último cambio no pudo guardarse en el dispositivo. '
                      'Si sale ahora se perderá.'
                : 'The last change could not be saved on this device. '
                      'Leaving now will discard it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppStrings.of(ctx).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                AppStrings.of(ctx).exit,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
