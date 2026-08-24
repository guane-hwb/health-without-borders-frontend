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

  // ── Lost / damaged bracelet re-labeling ───────────────────────────────────

  Future<void> _reassignDevices() async {
    if (_isUpdatingChips || widget.readOnly) return;
    final scope = AppScope.of(context);
    final isEs = AppStrings.of(context).isEs;

    final selection = await _showReassignDialog(isEs);
    if (!mounted || selection == null || selection.targets.isEmpty) return;

    final nfcKey = await scope.authRepository.getNfcEncryptionKey();
    if (!mounted) return;
    if (nfcKey == null || nfcKey.isEmpty) {
      _showReassignSnack(
        isEs
            ? 'No hay clave NFC disponible para grabar.'
            : 'No NFC key available to write.',
        error: true,
      );
      return;
    }
    final codec = NfcPayloadCodec(hexKey: nfcKey);

    setState(() => _isUpdatingChips = true);
    var record = _draft;
    var patientDone = false;
    var guardianDone = false;

    for (final target in selection.targets) {
      final updated = await _reassignOne(
        target: target,
        record: record,
        codec: codec,
        isEs: isEs,
      );
      if (!mounted) return;
      if (updated == null) break; // skipped or rejected — stop before saving
      record = updated;
      if (target == _ReassignTarget.patient) {
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
      // Persist with the reason (B1 carries it on the next /sync), then flush
      // the queue directly. We call syncAll() rather than _sync(), because
      // _sync() re-saves the draft without a reason and would clear it.
      await scope.localDatabase.savePatient(
        record,
        retiredDeviceReason: selection.reason,
      );
      // The new chips were just written, so they are clean.
      await scope.localDatabase.clearChipsDirty(
        record.patientId,
        patient: patientDone,
        guardian: guardianDone,
      );
      if (!mounted) return;
      setState(() {
        _draft = record;
        _original = record;
        _isUpdatingChips = false;
      });
      await _loadChipStatus(scope.localDatabase);
      if (!mounted) return;
      if (_hasInternet) {
        await scope.syncEngine.syncAll();
      }
      if (!mounted) return;
      _showReassignSnack(isEs ? 'Manilla reasignada.' : 'Bracelet reassigned.');
    } catch (e, stack) {
      AppLogger.e(
        'Fallo al guardar la reasignación de manilla',
        error: e,
        stackTrace: stack,
      );
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

  /// Reads a fresh blank tag (verifying it is unassigned) and captures its UID,
  /// then writes the re-labeled payload to it. Returns the updated record, or
  /// null if the user skipped or the tag was rejected.
  Future<PatientFullRecord?> _reassignOne({
    required _ReassignTarget target,
    required PatientFullRecord record,
    required NfcPayloadCodec codec,
    required bool isEs,
  }) async {
    final title = _reassignTitle(target, record, isEs);

    // STEP 1 — read + verify the new tag is blank, capturing its UID.
    String? newUid;
    HwbChipKind? kind;
    final readOk = await showNfcGuidedWrite(
      context,
      title: title,
      instruction: isEs
          ? 'Acerque la manilla NUEVA (en blanco) para verificarla'
          : 'Bring the NEW (blank) tag close to verify it',
      write: () async {
        final result = await NfcPayloadService(codec: codec).readHwbChip();
        newUid = result.uid;
        kind = result.kind;
      },
    );
    if (!mounted) return null;
    if (!readOk || newUid == null || newUid!.trim().isEmpty) return null;

    if (kind != HwbChipKind.none) {
      _showReassignSnack(
        isEs
            ? 'Esa manilla ya está en uso. Use una en blanco.'
            : 'That tag is already in use. Use a blank one.',
        error: true,
      );
      return null;
    }

    final normalizedNew = newUid!.trim();
    if (_uidAlreadyOnRecord(record, normalizedNew)) {
      _showReassignSnack(
        isEs
            ? 'Esa manilla ya pertenece a este paciente.'
            : 'That tag already belongs to this patient.',
        error: true,
      );
      return null;
    }

    // STEP 2 — write the payload to the new tag, built with the new UID so the
    // guardian card's own backup is self-consistent.
    final updated = _withNewUid(record, target, normalizedNew);
    final writeOk = await showNfcGuidedWrite(
      context,
      title: title,
      instruction: isEs
          ? 'Acerque la MISMA manilla nueva para grabarla'
          : 'Bring the SAME new tag close to write it',
      write: () async {
        final service = NfcPayloadService(codec: codec);
        if (target == _ReassignTarget.patient) {
          await service.writeTriagePayload(
            NfcTriagePayload.buildPatientPayload(record: updated),
            expectedUid: normalizedNew,
          );
        } else {
          await service.writeGuardianRecord(
            buildFit: guardianFitBuilder(record: updated, codec: codec),
            expectedUid: normalizedNew,
          );
        }
      },
    );
    if (!mounted) return null;
    return writeOk ? updated : null;
  }

  bool _uidAlreadyOnRecord(PatientFullRecord r, String uid) {
    final existing = <String>{
      r.deviceUid.trim(),
      (r.guardianInfo.deviceUid ?? '').trim(),
      (r.guardian2Info?.deviceUid ?? '').trim(),
    }..removeWhere((e) => e.isEmpty);
    return existing.contains(uid);
  }

  PatientFullRecord _withNewUid(
    PatientFullRecord r,
    _ReassignTarget target,
    String uid,
  ) {
    switch (target) {
      case _ReassignTarget.patient:
        return r.copyWith(deviceUid: uid);
      case _ReassignTarget.guardian1:
        return r.copyWith(
          guardianInfo: r.guardianInfo.copyWith(deviceUid: uid),
        );
      case _ReassignTarget.guardian2:
        final g2 = r.guardian2Info;
        if (g2 == null) return r;
        return r.copyWith(guardian2Info: g2.copyWith(deviceUid: uid));
    }
  }

  String _reassignTitle(
    _ReassignTarget target,
    PatientFullRecord record,
    bool isEs,
  ) {
    final hasTwo = (record.guardian2Info?.deviceUid ?? '').trim().isNotEmpty;
    switch (target) {
      case _ReassignTarget.patient:
        return isEs ? 'Manilla del paciente' : 'Patient bracelet';
      case _ReassignTarget.guardian1:
        return hasTwo
            ? (isEs ? 'Tarjeta del guardián 1' : 'Guardian card 1')
            : (isEs ? 'Tarjeta del guardián' : 'Guardian card');
      case _ReassignTarget.guardian2:
        return isEs ? 'Tarjeta del guardián 2' : 'Guardian card 2';
    }
  }

  Future<_ReassignSelection?> _showReassignDialog(bool isEs) {
    final hasG1 = (_draft.guardianInfo.deviceUid ?? '').trim().isNotEmpty;
    final hasG2 = (_draft.guardian2Info?.deviceUid ?? '').trim().isNotEmpty;
    final selected = <_ReassignTarget>{_ReassignTarget.patient};
    String reason = 'lost';

    return showDialog<_ReassignSelection>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget deviceCheck(_ReassignTarget t, String label) {
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(label),
                value: selected.contains(t),
                onChanged: (v) => setLocal(() {
                  if (v ?? false) {
                    selected.add(t);
                  } else {
                    selected.remove(t);
                  }
                }),
              );
            }

            Widget reasonSegments() {
              return SegmentedButton<String>(
                segments: [
                  ButtonSegment<String>(
                    value: 'lost',
                    label: Text(isEs ? 'Perdida' : 'Lost'),
                  ),
                  ButtonSegment<String>(
                    value: 'damaged',
                    label: Text(isEs ? 'Dañada' : 'Damaged'),
                  ),
                ],
                selected: <String>{reason},
                onSelectionChanged: (Set<String> s) =>
                    setLocal(() => reason = s.first),
              );
            }

            return AlertDialog(
              title: Text(isEs ? 'Reasignar manilla' : 'Reassign bracelet'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEs
                          ? '¿Qué dispositivo se va a reemplazar?'
                          : 'Which device is being replaced?',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    deviceCheck(
                      _ReassignTarget.patient,
                      isEs ? 'Manilla del paciente' : 'Patient bracelet',
                    ),
                    if (hasG1)
                      deviceCheck(
                        _ReassignTarget.guardian1,
                        hasG2
                            ? (isEs
                                  ? 'Tarjeta del guardián 1'
                                  : 'Guardian card 1')
                            : (isEs
                                  ? 'Tarjeta del guardián'
                                  : 'Guardian card'),
                      ),
                    if (hasG2)
                      deviceCheck(
                        _ReassignTarget.guardian2,
                        isEs ? 'Tarjeta del guardián 2' : 'Guardian card 2',
                      ),
                    const SizedBox(height: 12),
                    Text(
                      isEs ? 'Motivo' : 'Reason',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    reasonSegments(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(AppStrings.of(ctx).cancel),
                ),
                ElevatedButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          final ordered = <_ReassignTarget>[
                            _ReassignTarget.patient,
                            _ReassignTarget.guardian1,
                            _ReassignTarget.guardian2,
                          ].where(selected.contains).toList();
                          Navigator.of(dialogCtx).pop(
                            _ReassignSelection(
                              targets: ordered,
                              reason: reason,
                            ),
                          );
                        },
                  child: Text(isEs ? 'Continuar' : 'Continue'),
                ),
              ],
            );
          },
        );
      },
    );
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
                  onReassignDevice: widget.readOnly ? null : _reassignDevices,
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

/// Which NFC device is being re-labeled in the reassign flow.
enum _ReassignTarget { patient, guardian1, guardian2 }

/// Result of the reassign selection dialog: which devices to replace and why.
class _ReassignSelection {
  const _ReassignSelection({required this.targets, required this.reason});

  final List<_ReassignTarget> targets;

  /// Retirement reason for this session — `'lost'` or `'damaged'`.
  final String reason;
}
