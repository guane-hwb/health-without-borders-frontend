// lib/src/features/nfc/presentation/profile/patient_profile_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/nfc/nfc_keyring.dart';
import '../../../../core/nfc/nfc_payload_codec.dart';
import '../../../../core/nfc/nfc_triage_payload.dart';
import '../../../../core/storage/local_database.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../design/tokens/app_colors.dart';
import '../../../../shared/widgets/screen_bottom_handle.dart';
import '../../../auth/domain/user_session.dart';
import '../../domain/patient_record.dart';
import '../add_consultation_screen.dart';
import '../add_vaccine_screen.dart';
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
import 'state/patient_draft_controller.dart';
import 'tabs/profile_tab_consultations.dart';
import 'tabs/profile_tab_summary.dart';
import 'tabs/profile_tab_vaccines.dart';
import 'widgets/profile_banners.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_nfc_actions.dart';
import 'widgets/profile_tabs_bar.dart';
import 'widgets/reassign_device_dialog.dart';

/// Canonical patient profile screen.
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({
    super.key,
    required this.patient,
    this.lastSyncedAt,
    this.readOnly = false,
    this.offline = false,
    this.emergency = false,
    this.allowReassign = false,
  });

  final PatientFullRecord patient;
  final String? lastSyncedAt;
  final bool readOnly;
  final bool offline;
  final bool emergency;
  final bool allowReassign;

  @visibleForTesting
  static Future<List<ConnectivityResult>> Function() checkConnectivityImpl =
      () => Connectivity().checkConnectivity();

  @visibleForTesting
  static Stream<List<ConnectivityResult>> Function() connectivityStreamImpl =
      () => Connectivity().onConnectivityChanged;

  @visibleForTesting
  static Future<ReassignSelection?> Function(
    BuildContext context, {
    required bool isEs,
    required bool hasG1,
    required bool hasG2,
  })
  showReassignDeviceDialogImpl = showReassignDeviceDialog;

  @visibleForTesting
  static Future<bool> Function({
    required BuildContext context,
    required PatientFullRecord record,
    required NfcKeyring keyring,
    required bool patientChipDirty,
    required bool guardianChipDirty,
  })
  executeUpdateNfcChipsImpl = executeUpdateNfcChips;

  @visibleForTesting
  static Future<PatientFullRecord?> Function({
    required BuildContext context,
    required ReassignTarget target,
    required PatientFullRecord record,
    required NfcPayloadCodec codec,
    required bool isEs,
    required void Function(String message, {bool error}) showSnack,
  })
  executeReassignOneImpl = executeReassignOne;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PatientDraftController _draftController;
  PatientFullRecord get _draft => _draftController.draft;
  PatientFullRecord get _original => _draftController.original;
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
    _draftController = PatientDraftController(widget.patient)
      ..addListener(_onDraftChanged);

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
    _draftController.removeListener(_onDraftChanged);
    _draftController.dispose();
    super.dispose();
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await PatientProfileScreen.checkConnectivityImpl();
    if (!mounted) return;
    _updateConnectivityStatus(result);
  }

  void _subscribeToConnectivity() {
    _connectivitySubscription = PatientProfileScreen.connectivityStreamImpl()
        .listen((List<ConnectivityResult> results) {
          if (!mounted) return;
          _updateConnectivityStatus(results);
        });
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    if (!mounted) return;
    final hasNet = hasInternetConnection(results);
    if (_hasInternet != hasNet) {
      setState(() => _hasInternet = hasNet);
      if (_hasInternet && _hasUnsyncedChanges) _sync(silent: true);
    }
  }

  bool get _hasUnsyncedChanges => _draft != _original;

  UserRole get _currentRole =>
      AppScope.of(context).authRepository.currentUser?.role ?? UserRole.doctor;

  Future<void> _markNfcChipsDirtyIfChanged(LocalDatabase db) async {
    if (_draft.patientId.isEmpty || _original == _draft) return;
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

    final keyring = await scope.authRepository.getNfcKeyring();
    if (!mounted) return;
    if (keyring == null || !keyring.canWrite) {
      final bool expired = await scope.authRepository.isNfcSessionExpired();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            expired
                ? (isEs
                      ? 'Su sesión expiró. Inicie sesión de nuevo para grabar.'
                      : 'Your session expired. Log in again to write.')
                : (isEs
                      ? 'No hay clave NFC disponible para grabar.'
                      : 'No NFC key available to write.'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final status = _chipStatus;
    if (status == null || !status.anyDirty) return;

    setState(() => _isUpdatingChips = true);

    try {
      final ok = await PatientProfileScreen.executeUpdateNfcChipsImpl(
        context: context,
        record: _draft,
        keyring: keyring,
        patientChipDirty: status.patientChipDirty,
        guardianChipDirty: status.guardianChipDirty,
      );

      if (!mounted) return;
      if (ok) {
        await scope.localDatabase.clearChipsDirty(
          _draft.patientId,
          patient: status.patientChipDirty,
          guardian: status.guardianChipDirty,
        );
      }

      await _loadChipStatus(scope.localDatabase);
    } finally {
      // Without this the button stays disabled until the screen is rebuilt if
      // anything above throws.
      if (mounted) setState(() => _isUpdatingChips = false);
    }
  }

  Future<void> _reassignDevices() async {
    if (_isUpdatingChips || widget.readOnly) return;
    final scope = AppScope.of(context);
    final isEs = AppStrings.of(context).isEs;

    final hasG1 = (_draft.guardianInfo.deviceUid ?? '').trim().isNotEmpty;
    final hasG2 = (_draft.guardian2Info?.deviceUid ?? '').trim().isNotEmpty;

    final selection = await PatientProfileScreen.showReassignDeviceDialogImpl(
      context,
      isEs: isEs,
      hasG1: hasG1,
      hasG2: hasG2,
    );
    if (!mounted || selection == null || selection.targets.isEmpty) return;

    final keyring = await scope.authRepository.getNfcKeyring();
    if (!mounted) return;
    if (keyring == null || !keyring.canWrite) {
      final bool expired = await scope.authRepository.isNfcSessionExpired();
      if (!mounted) return;
      _showReassignSnack(
        expired
            ? (isEs
                  ? 'Su sesión expiró. Inicie sesión de nuevo para grabar.'
                  : 'Your session expired. Log in again to write.')
            : (isEs
                  ? 'No hay clave NFC disponible para grabar.'
                  : 'No NFC key available to write.'),
        error: true,
      );
      return;
    }
    final NfcPayloadCodec codec;
    try {
      codec = NfcPayloadCodec.fromKeyring(keyring: keyring);
    } catch (e, stack) {
      AppLogger.e('Anillo de llaves NFC inválido', error: e, stackTrace: stack);
      _showReassignSnack(
        isEs
            ? 'La clave NFC no es válida. Contacte al administrador.'
            : 'The NFC key is invalid. Contact your administrator.',
        error: true,
      );
      return;
    }

    setState(() => _isUpdatingChips = true);
    var record = _draft;
    var patientDone = false;
    var guardianDone = false;

    for (final target in selection.targets) {
      final updated = await PatientProfileScreen.executeReassignOneImpl(
        context: context,
        target: target,
        record: record,
        codec: codec,
        isEs: isEs,
        showSnack: _showReassignSnack,
      );
      if (!mounted) return;
      if (updated == null) break;
      record = updated;
      if (target == ReassignTarget.patient) {
        patientDone = true;
      } else {
        guardianDone = true;
      }
    }

    if (!mounted) return;
    if (!patientDone && !guardianDone) {
      setState(() => _isUpdatingChips = false);
      return;
    }

    try {
      await scope.localDatabase.savePatient(
        record,
        retiredDeviceReason: selection.reason,
      );
      await scope.localDatabase.clearChipsDirty(
        record.patientId,
        patient: patientDone,
        guardian: guardianDone,
      );
      if (!mounted) return;
      setState(() {
        _draftController.markSynced();
        _isUpdatingChips = false;
      });
      await _loadChipStatus(scope.localDatabase);
      if (!mounted) return;
      if (_hasInternet) await scope.syncEngine.syncAll();
      if (!mounted) return;
      _showReassignSnack(
        isEs ? 'dispositivo reasignado.' : 'Device reassigned.',
      );
    } catch (e, stack) {
      AppLogger.e('Fallo al reasignar', error: e, stackTrace: stack);
      if (!mounted) return;
      setState(() => _isUpdatingChips = false);
      _showReassignSnack(
        isEs
            ? 'No se pudo guardar la reasignación.'
            : 'Could not save the reassignment.',
        error: true,
      );
    }
  }

  void _showReassignSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : null,
      ),
    );
  }

  Future<void> _saveAndPendingSync() async {
    final scope = AppScope.of(context);
    var currentUser = scope.authRepository.currentUser;
    currentUser ??= await scope.authRepository.restoreSession();

    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión no activa. Vuelve a iniciar sesión.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await scope.localDatabase.savePatient(
        _draft,
        ownerUserId: currentUser.id,
        organizationId: currentUser.organizationId,
      );
      await _markNfcChipsDirtyIfChanged(scope.localDatabase);
      if (_hasInternet) await _sync(silent: true);
    } catch (e, stack) {
      AppLogger.e('Error local_database', error: e, stackTrace: stack);
      if (!mounted) return;

      setState(() => _lastSaveFailed = true);
      final isEs = AppStrings.of(context).isEs;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEs
                ? 'El cambio NO está a salvo en este dispositivo.'
                : 'The change is NOT safe on this device.',
          ),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: isEs ? 'Reintentar' : 'Retry',
            textColor: Colors.white,
            onPressed: () {
              setState(() => _lastSaveFailed = false);
              _saveAndPendingSync();
            },
          ),
        ),
      );
    }
  }

  void _updateVitalSigns({double? weight, double? height, String? bloodType}) {
    _draftController.updateVitalSigns(
      weight: weight,
      height: height,
      bloodType: bloodType,
    );
    unawaited(_saveAndPendingSync());
  }

  void _updateAddress(Address address) {
    _draftController.updateAddress(address);
    unawaited(_saveAndPendingSync());
  }

  void _updateBackground({
    List<ChronicConditionItem>? chronicConditions,
    String? personalHistory,
  }) {
    _draftController.updateBackground(
      chronicConditions: chronicConditions,
      personalHistory: personalHistory,
    );
    unawaited(_saveAndPendingSync());
  }

  void _addChronicCondition(ChronicConditionItem item) {
    _draftController.addChronicCondition(item);
    unawaited(_saveAndPendingSync());
  }

  void _removeChronicCondition(int index) {
    _draftController.removeChronicCondition(index);
    unawaited(_saveAndPendingSync());
  }

  void _addMedication(MedicationStatementItem item) {
    _draftController.addMedication(item);
    unawaited(_saveAndPendingSync());
  }

  void _removeMedication(int index) {
    _draftController.removeMedication(index);
    unawaited(_saveAndPendingSync());
  }

  void _addFamilyHistory(FamilyHistoryItem item) {
    _draftController.addFamilyHistory(item);
    unawaited(_saveAndPendingSync());
  }

  void _removeFamilyHistory(int index) {
    _draftController.removeFamilyHistory(index);
    unawaited(_saveAndPendingSync());
  }

  void _addAllergy(AllergyInfo allergy) {
    _draftController.addAllergy(allergy);
    unawaited(_saveAndPendingSync());
  }

  void _removeAllergy(int index) {
    _draftController.removeAllergy(index);
    unawaited(_saveAndPendingSync());
  }

  void _addVaccines(List<VaccinationRecordItem> vaccines) {
    _draftController.addVaccines(vaccines);
    unawaited(_saveAndPendingSync());
  }

  void _addConsultation(MedicalHistoryItem consultation) {
    _draftController.addConsultation(consultation);
    unawaited(_saveAndPendingSync());
  }

  Future<void> _sync({bool silent = false}) async {
    if (widget.readOnly || _isSyncing) return;
    final isEs = AppStrings.of(context).isEs;

    if (!_hasInternet && !silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEs
                ? 'Sin conexión. Se sincronizará al reconectar.'
                : 'Offline. It will sync once reconnected.',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (!silent) setState(() => _isSyncing = true);
    try {
      final scope = AppScope.of(context);
      final currentUser = scope.authRepository.currentUser;

      await scope.localDatabase.savePatient(
        _draft,
        ownerUserId: currentUser?.id,
        organizationId: currentUser?.organizationId,
      );

      await _markNfcChipsDirtyIfChanged(scope.localDatabase);
      final bool ok = await scope.syncEngine.syncAll();
      if (!mounted) return;
      if (ok) _draftController.markSynced();
      setState(() => _isSyncing = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? AppStrings.of(context).savedChangesMsg
                  : (isEs ? 'Fallo al sincronizar.' : 'Sync failed.'),
            ),
            backgroundColor: ok ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSyncing = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEs ? 'Fallo al sincronizar.' : 'Sync failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

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
    if (result != null) _addConsultation(result);
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
    if (result != null && result.isNotEmpty) _addVaccines(result);
  }

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
        onConfirm: (updated) {
          _draftController.updateGuardian(guardianIndex, updated);
          unawaited(_saveAndPendingSync());
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
        onConfirm: (text) => _updateBackground(personalHistory: text),
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
                  isSyncing: _isSyncing,
                  onSync: widget.readOnly ? null : () => _sync(),
                  onBack: () async {
                    if (await confirmProfileExit(context, _lastSaveFailed)) {
                      if (!context.mounted) return;
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    }
                  },
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
                        onReassignDevice:
                            (widget.allowReassign && !widget.readOnly)
                            ? _reassignDevices
                            : null,
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
}
