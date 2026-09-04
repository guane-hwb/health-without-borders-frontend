// lib/src/features/nfc/presentation/register/register_nfc_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/network/api_client.dart';
import '../../../../design/tokens/app_colors.dart';
import '../../../../shared/widgets/hwb_logo.dart';
import '../../../../shared/widgets/locale_switcher.dart';
import '../../../../shared/widgets/screen_bottom_handle.dart';
import '../../domain/patient_record.dart';
import '../../domain/register_draft.dart';
import '../../../../core/nfc/nfc_payload_codec.dart';
import '../../../../core/nfc/nfc_triage_payload.dart';
import '../../../../core/nfc/nfc_payload_service.dart';
import '../nfc_guided_write.dart';
import '../add_consultation_screen.dart';
import '../add_vaccine_screen.dart';
import 'steps/step2_guardian.dart';
import 'steps/step3_patient_data.dart';
import 'steps/step4_background.dart';
import 'steps/step5_review.dart';
import 'steps/step6_success.dart';
import '../../../../core/i18n/app_strings.dart';

class RegisterNfcScreen extends StatefulWidget {
  const RegisterNfcScreen({super.key});
  @override
  State<RegisterNfcScreen> createState() => _RegisterNfcScreenState();
}

class _RegisterNfcScreenState extends State<RegisterNfcScreen> {
  int _step = 0;
  final RegisterDraft _draft = RegisterDraft();

  late final String _patientId = const Uuid().v4();

  PatientFullRecord? _savedRecord;
  String? _lastConsultationTime;
  String? _lastVaccineTime;

  bool get _isMinor {
    final dob = _draft.dob;
    if (dob == null) return true;
    final today = DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age < 18;
  }

  void _next() {
    if (_step < 4) setState(() => _step++);
  }

  void _stepBack() async {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      await _goToHomeDirectly();
    }
  }

  Future<bool> _confirmDiscard() async {
    if (_savedRecord != null || _step >= 4) {
      return true;
    }

    final s = AppStrings.of(context);
    final isEs = s.isEs;

    if (_draft.firstName.isEmpty && _draft.documentNumber.isEmpty) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEs ? '¿Descartar registro?' : 'Discard registration?'),
        content: Text(
          isEs
              ? 'Si regresa ahora, se perderán todos los datos ingresados en el formulario.'
              : 'If you leave now, all entered information will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isEs ? 'Descartar' : 'Discard',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _goToHomeDirectly() async {
    final canLeave = await _confirmDiscard();
    if (!canLeave || !mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _confirm() async {
    final draftRecord = _draft.toRecord();
    final record = PatientFullRecord(
      patientId: _patientId,
      deviceUid: draftRecord.deviceUid,
      patientInfo: draftRecord.patientInfo,
      guardianInfo: draftRecord.guardianInfo,
      guardian2Info: draftRecord.guardian2Info,
      backgroundHistory: draftRecord.backgroundHistory,
      allergies: draftRecord.allergies,
      medicalHistory: draftRecord.medicalHistory,
      vaccinationRecord: draftRecord.vaccinationRecord,
    );

    final scope = AppScope.of(context);

    var currentUser = scope.authRepository.currentUser;
    currentUser ??= await scope.authRepository.restoreSession();

    try {
      final response = await scope.patientRepository.syncPatient(record);

      if (response.status == 'success') {
        await scope.localDatabase.savePatient(
          record,
          ownerUserId: currentUser?.id,
          organizationId: currentUser?.organizationId,
          isSynced: true,
        );
        await scope.localDatabase.markSynced(record.patientId);

        if (!mounted) return;
        setState(() {
          _savedRecord = record;
          _step = 4;
        });
        return;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        if (!mounted) return;
        final isEs = AppStrings.of(context).isEs;

        await scope.localDatabase.deleteRecord(record.patientId);

        if (!mounted) return;

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.nfc_outlined,
                      color: AppColors.error,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEs ? 'Registro Duplicado' : 'Duplicate Record',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEs
                        ? 'El dispositivo NFC escaneado ya se encuentra asignado a otro paciente en el sistema.'
                        : 'The scanned NFC device is already assigned to another patient in the system.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        isEs ? 'Entendido' : 'Understand',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (!mounted) return;
        setState(() {});
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text(e.message)),
      );
      return;
    } catch (_) {}

    try {
      await scope.localDatabase.savePatient(
        record,
        ownerUserId: currentUser?.id,
        organizationId: currentUser?.organizationId,
        isSynced: false,
      );
    } catch (_) {
      if (!mounted) return;
      final s = AppStrings.of(context);
      final isEs = s.isEs;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            isEs
                ? 'No se pudo guardar el registro en este dispositivo.'
                : 'The record could not be saved on this device.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _savedRecord = record;
      _step = 4;
    });
  }

  Future<void> _addConsultation() async {
    if (_savedRecord == null) return;
    final result = await Navigator.of(context).push<MedicalHistoryItem>(
      MaterialPageRoute(
        builder: (_) => AddConsultationScreen(
          patient: _savedRecord!,
          returnToProfile: true,
        ),
      ),
    );
    if (result != null) {
      final updated = PatientFullRecord(
        patientId: _savedRecord!.patientId,
        deviceUid: _savedRecord!.deviceUid,
        patientInfo: _savedRecord!.patientInfo,
        guardianInfo: _savedRecord!.guardianInfo,
        guardian2Info: _savedRecord!.guardian2Info,
        backgroundHistory: _savedRecord!.backgroundHistory,
        allergies: _savedRecord!.allergies,
        medicalHistory: [..._savedRecord!.medicalHistory, result],
        vaccinationRecord: _savedRecord!.vaccinationRecord,
      );
      await _persistLocally(updated);
      if (!mounted) return;
      setState(() => _lastConsultationTime = _formatTimeNow(context));
      final s = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.consultationSaved),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _addVaccine() async {
    if (_savedRecord == null) return;
    final result = await Navigator.of(context)
        .push<List<VaccinationRecordItem>>(
          MaterialPageRoute(
            builder: (_) =>
                AddVaccineScreen(patient: _savedRecord!, returnToProfile: true),
          ),
        );
    if (result != null && result.isNotEmpty) {
      final updated = PatientFullRecord(
        patientId: _savedRecord!.patientId,
        deviceUid: _savedRecord!.deviceUid,
        patientInfo: _savedRecord!.patientInfo,
        guardianInfo: _savedRecord!.guardianInfo,
        guardian2Info: _savedRecord!.guardian2Info,
        backgroundHistory: _savedRecord!.backgroundHistory,
        allergies: _savedRecord!.allergies,
        medicalHistory: _savedRecord!.medicalHistory,
        vaccinationRecord: [..._savedRecord!.vaccinationRecord, ...result],
      );
      await _persistLocally(updated);
      if (!mounted) return;
      setState(() => _lastVaccineTime = _formatTimeNow(context));
      final s = AppStrings.of(context);
      final isEs = s.isEs;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.length == 1
                ? s.vaccineSaved
                : (isEs
                      ? '${result.length} vacunas guardadas exitosamente ✓'
                      : '${result.length} vaccines saved successfully ✓'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _persistLocally(PatientFullRecord record) async {
    final scope = AppScope.of(context);
    var currentUser = scope.authRepository.currentUser;
    currentUser ??= await scope.authRepository.restoreSession();

    try {
      final existingRecords = await scope.localDatabase.getAllRecords(
        ownerUserId: currentUser?.id,
      );
      final existing = existingRecords.where(
        (e) => e.patientId == record.patientId,
      );
      final bool alreadySynced = existing.isNotEmpty
          ? existing.first.isSynced
          : false;

      await scope.localDatabase.savePatient(
        record,
        ownerUserId: currentUser?.id,
        organizationId: currentUser?.organizationId,
        isSynced: alreadySynced,
      );
      if (mounted) setState(() => _savedRecord = record);
    } catch (_) {
      if (!mounted) return;
      final s = AppStrings.of(context);
      final isEs = s.isEs;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            isEs
                ? 'No se pudo actualizar el registro en este dispositivo.'
                : 'Could not update the record on this device.',
          ),
        ),
      );
    }
  }

  Future<void> _finalize() async {
    final scope = AppScope.of(context);
    final record = _savedRecord;
    if (record == null) {
      await _goToHomeDirectly();
      return;
    }

    final keyring = await scope.authRepository.getNfcKeyring();
    if (!mounted) return;

    if (keyring == null || !keyring.canWrite) {
      _completeFinalize();
      return;
    }

    final codec = NfcPayloadCodec.fromKeyring(keyring: keyring);
    final s = AppStrings.of(context);
    final isEs = s.isEs;

    final patientOk = await showNfcGuidedWrite(
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
    if (patientOk) {
      await scope.localDatabase.clearChipsDirty(
        record.patientId,
        patient: true,
      );
      if (!mounted) return;
    }

    Future<void> writeGuardianCard({
      required String expectedUid,
      required String title,
      required String instruction,
    }) async {
      final ok = await showNfcGuidedWrite(
        context,
        title: title,
        instruction: instruction,
        write: () => NfcPayloadService(codec: codec).writeGuardianRecord(
          buildFit: guardianFitBuilder(record: record, codec: codec),
          expectedUid: expectedUid,
        ),
      );
      if (!mounted) return;
      if (ok) {
        await scope.localDatabase.clearChipsDirty(
          record.patientId,
          guardian: true,
        );
      }
    }

    final guardian1Uid = (record.guardianInfo.deviceUid ?? '').trim();
    final guardian2Uid = (record.guardian2Info?.deviceUid ?? '').trim();
    final hasTwoGuardians = guardian1Uid.isNotEmpty && guardian2Uid.isNotEmpty;

    if (guardian1Uid.isNotEmpty) {
      await writeGuardianCard(
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
    }

    if (guardian2Uid.isNotEmpty) {
      await writeGuardianCard(
        expectedUid: guardian2Uid,
        title: isEs ? 'Tarjeta del guardián 2' : 'Guardian card 2',
        instruction: isEs
            ? 'Acerque la tarjeta del guardián 2 al teléfono'
            : 'Bring guardian card 2 to the phone',
      );
      if (!mounted) return;
    }

    _completeFinalize();
  }

  void _completeFinalize() {
    final scope = AppScope.of(context);
    unawaited(scope.syncEngine.syncAll());
    if (mounted) setState(() => _step = 5);
  }

  String _formatTimeNow(BuildContext context) {
    final s = AppStrings.of(context);
    final n = DateTime.now();
    final h = n.hour;
    final m = n.minute.toString().padLeft(2, '0');
    final period = h < 12 ? s.timeAm : s.timePm;
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${s.today}, $h12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final onSuccess = _step >= 4;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _WizardHeader(
                  title: s.newPatient,
                  onBack: onSuccess ? null : _goToHomeDirectly,
                  stepText: onSuccess ? null : '${_step + 1}/4',
                ),
                if (!onSuccess) _ProgressBar(step: _step, total: 4),
                Expanded(child: _buildStep()),
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

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Step3PatientData(
          draft: _draft,
          onBack: _stepBack,
          onContinue: _next,
        );
      case 1:
        return Step2Guardian(
          draft: _draft,
          requiredForMinor: _isMinor,
          onBack: _stepBack,
          onContinue: _next,
        );
      case 2:
        return Step4Background(
          draft: _draft,
          onBack: _stepBack,
          onContinue: _next,
        );
      case 3:
        return Step5Review(
          draft: _draft,
          onBack: _stepBack,
          onConfirm: _confirm,
        );
      case 4:
        final role = AppScope.of(context).authRepository.currentUser?.role;
        return Step6Success(
          patient: _savedRecord!,
          onAddConsultation: _addConsultation,
          onAddVaccine: _addVaccine,
          onFinish: _finalize,
          lastConsultationTime: _lastConsultationTime,
          lastVaccineTime: _lastVaccineTime,
          canAddConsultation: role?.canAddConsultation ?? true,
        );
      case 5:
        return Step6Success(
          patient: _savedRecord!,
          sealed: true,
          onGoHome: _goToHomeDirectly,
          onAddConsultation: () {},
          onAddVaccine: () {},
          onFinish: () {},
          lastConsultationTime: _lastConsultationTime,
          lastVaccineTime: _lastVaccineTime,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.title, this.onBack, this.stepText});
  final String title;
  final VoidCallback? onBack;
  final String? stepText;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: Row(
        children: [
          if (onBack != null)
            Material(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(4),
              child: HwbLogo(size: 32, onDark: true),
            ),
          const SizedBox(width: 8),
          if (onBack != null) const HwbLogo(size: 38, onDark: true),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (stepText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                stepText!,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const LocaleSwitcher(),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});
  final int step;
  final int total;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(
          total,
          (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: i <= step ? AppColors.primary : const Color(0xFFE3E5EA),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
