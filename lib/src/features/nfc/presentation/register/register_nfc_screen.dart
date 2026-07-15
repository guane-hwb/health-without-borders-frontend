// lib/src/features/nfc/presentation/register/register_nfc_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../design/tokens/app_colors.dart';
import '../../../../shared/widgets/hwb_logo.dart';
import '../../../../shared/widgets/screen_bottom_handle.dart';
import '../../domain/patient_record.dart';
import '../../../../core/nfc/nfc_payload_codec.dart';
import '../../../../core/nfc/nfc_triage_payload.dart';
import '../../../../core/nfc/nfc_payload_service.dart';
import '../../../../core/nfc/nfc_guardian_payload.dart';
import '../nfc_guided_write.dart';
import '../add_consultation_screen.dart';
import '../add_vaccine_screen.dart';
import 'steps/step2_guardian.dart';
import 'steps/step3_patient_data.dart';
import 'steps/step4_background.dart';
import 'steps/step5_review.dart';
import 'steps/step6_success.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../home/presentation/home_screen.dart';

/// Conservative usable NDEF capacity (bytes) for the guardian DESFire
/// EV3 4K. The real limit is enforced by the chip at write time; this
/// only pre-trims so we rarely hit that hard limit.
const int _kGuardianCardCapacityBytes = 4000;

class RegisterNfcScreen extends StatefulWidget {
  const RegisterNfcScreen({super.key});
  @override
  State<RegisterNfcScreen> createState() => _RegisterNfcScreenState();
}

class _RegisterNfcScreenState extends State<RegisterNfcScreen> {
  int _step = 0;
  final RegisterDraft _draft = RegisterDraft();
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

  void _stepBack() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      _goToHomeDirectly();
    }
  }

  void _goToHomeDirectly() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  /// Locks in the form data: persists locally and moves to the hub.
  /// No chips are written here — that happens at _finalize().
  Future<void> _confirm() async {
    final record = _draft.toRecord();
    final scope = AppScope.of(context);
    await scope.localDatabase.savePatient(record);
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
    final result = await Navigator.of(context).push<VaccinationRecordItem>(
      MaterialPageRoute(
        builder: (_) =>
            AddVaccineScreen(patient: _savedRecord!, returnToProfile: true),
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
        medicalHistory: _savedRecord!.medicalHistory,
        vaccinationRecord: [..._savedRecord!.vaccinationRecord, result],
      );
      await _persistLocally(updated);
      if (!mounted) return;
      setState(() => _lastVaccineTime = _formatTimeNow(context));
      final s = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.vaccineSaved),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _persistLocally(PatientFullRecord record) async {
    final scope = AppScope.of(context);
    await scope.localDatabase.savePatient(record);
    if (mounted) setState(() => _savedRecord = record);
  }

  /// Writes the patient chip, queues the record for sync and shows the final
  /// sealed-confirmation screen. The guardian card write is added in Patch 4.
  // ── Finalize: write both chips with the guided overlay, then seal ──────────

  /// Writes the patient wristband and (if any) the guardian card, each through
  /// the guided NFC overlay, then shows the sealed confirmation screen.
  Future<void> _finalize() async {
    final scope = AppScope.of(context);
    final record = _savedRecord;
    if (record == null) {
      _goToHomeDirectly();
      return;
    }

    final nfcKey = await scope.authRepository.getNfcEncryptionKey();
    if (!mounted) return;

    // No NFC key (e.g. not provisioned): nothing to write, just queue sync.
    if (nfcKey == null || nfcKey.isEmpty) {
      _completeFinalize();
      return;
    }

    final codec = NfcPayloadCodec(hexKey: nfcKey);
    final isEs = AppStrings.of(context).welcome == 'Bienvenido';

    // Patient wristband (triage).
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

    // Guardian card (bounded full record), if the patient has one.
    final hasGuardian = (record.guardianInfo.deviceUid ?? '').trim().isNotEmpty;
    if (hasGuardian) {
      final guardianOk = await showNfcGuidedWrite(
        context,
        title: isEs ? 'Tarjeta del guardián' : 'Guardian card',
        instruction: isEs
            ? 'Acerque la tarjeta del guardián al teléfono'
            : 'Bring the guardian card to the phone',
        write: () {
          final fit = NfcGuardianPayload.buildWithinCapacity(
            record: record,
            capacityBytes: _kGuardianCardCapacityBytes,
            estimateSize: codec.estimateSize,
          );
          return NfcPayloadService(codec: codec).writeGuardianPayload(
            fit.payload,
            expectedUid: record.guardianInfo.deviceUid,
          );
        },
      );
      if (!mounted) return;
      if (guardianOk) {
        await scope.localDatabase.clearChipsDirty(
          record.patientId,
          guardian: true,
        );
        if (!mounted) return;
      }
    }

    _completeFinalize();
  }

  /// Queues sync and shows the sealed confirmation screen.
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

// ── Header ──────────────────────────────────────────────────────────────────
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
          _LocaleSwitcher(),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _LocaleSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context).locale;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['es', 'en'].map((lang) {
          final selected = locale == lang;
          return GestureDetector(
            onTap: () => AppLocale.of(context).setLocale(lang),
            child: Container(
              margin: const EdgeInsets.only(left: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                lang.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.white,
                ),
              ),
            ),
          );
        }).toList(),
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

// ── Draft ────────────────────────────────────────────────────────────────────
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
  String? guardian2Name;
  String? guardian2Relationship;
  String? guardian2Phone;
  String? guardian2DeviceUid;
  String? guardian2DocType;
  String? guardian2DocNumber;
  bool? guardian2AuthAccepted;
  String? guardian2Email;
  String? guardian2SignatureBase64;
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
