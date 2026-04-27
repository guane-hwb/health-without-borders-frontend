// lib/src/features/nfc/presentation/add_consultation_screen.dart
import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/nfc/nfc_service.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'shared_read_nfc_header.dart';

/// Screen for adding a medical consultation to an existing patient.
/// Only accessible to users with [UserRole.doctor] or [UserRole.superadmin].
///
/// Flow:
///   1. If [patient] is null → scan patient wristband first.
///   2. Fill consultation form (vitals + chief complaint + diagnosis plan).
///   3. Save locally → sync to backend.
class AddConsultationScreen extends StatefulWidget {
  const AddConsultationScreen({super.key, this.patient});

  /// Pre-loaded patient. When null the screen starts at the NFC scan step.
  final PatientFullRecord? patient;

  @override
  State<AddConsultationScreen> createState() => _AddConsultationScreenState();
}

class _AddConsultationScreenState extends State<AddConsultationScreen> {
  PatientFullRecord? _patient;
  bool _scanning = false;
  String? _scanError;
  bool _isSaving = false;
  bool _saved = false;

  // ── Vital signs ──────────────────────────────────────────────────────────
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _satO2Ctrl = TextEditingController();

  // ── Chief complaint ──────────────────────────────────────────────────────
  String _mainSymptom = '';
  final _clinicalDescCtrl = TextEditingController();

  // ── Diagnosis + plan ─────────────────────────────────────────────────────
  final _diagnosisDescCtrl = TextEditingController();
  final _prescriptionCtrl = TextEditingController();
  String _diagnosisType = '01';

  // ── Care metadata ─────────────────────────────────────────────────────────
  final _practitionerNameCtrl = TextEditingController();
  final _providerNameCtrl = TextEditingController();
  String _careModality = '01';

  static const List<String> _symptoms = [
    'Fiebre y tos',
    'Dolor abdominal',
    'Cefalea',
    'Diarrea',
    'Vómito',
    'Dificultad respiratoria',
    'Dolor torácico',
    'Otro',
  ];

  static const Map<String, String> _diagnosisTypes = {
    '01': 'Impresión diagnóstica',
    '02': 'Confirmado nuevo',
    '03': 'Confirmado repetido',
  };

  static const Map<String, String> _careModalities = {
    '01': 'Intramural',
    '02': 'Extramural - Móvil',
    '05': 'Extramural - Prehospitalaria',
  };

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    // Pre-fill patient weight/height from existing record
    if (_patient != null) {
      _weightCtrl.text = _patient!.patientInfo.weight?.toString() ?? '';
      _heightCtrl.text = _patient!.patientInfo.height?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _tempCtrl.dispose();
    _heartRateCtrl.dispose();
    _satO2Ctrl.dispose();
    _clinicalDescCtrl.dispose();
    _diagnosisDescCtrl.dispose();
    _prescriptionCtrl.dispose();
    _practitionerNameCtrl.dispose();
    _providerNameCtrl.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────

  bool get _isFormValid =>
      _mainSymptom.isNotEmpty && _clinicalDescCtrl.text.trim().isNotEmpty;

  // ── NFC scan ──────────────────────────────────────────────────────────────

  Future<void> _scanPatient() async {
    setState(() {
      _scanning = true;
      _scanError = null;
    });
    try {
      final uid = await NfcService.readDeviceUid();
      final patient = await AppScope.of(
        context,
      ).patientRepository.scanDevice(uid);
      if (mounted) setState(() => _patient = patient);
    } on NfcNotAvailableException {
      if (mounted) setState(() => _scanError = 'NFC no disponible.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _scanError = e.message);
    } catch (e) {
      if (mounted) setState(() => _scanError = e.toString());
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_patient == null) return;
    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();

    final newConsultation = MedicalHistoryItem(
      type: 'Consultation',
      startDateTime: now,
      careModality: _careModality,
      serviceGroup: '01',
      careEnvironment: '05',
      diagnosisType: _diagnosisType,
      practitioner: PractitionerInfo(
        documentType: 'CC',
        documentNumber: '',
        name: _practitionerNameCtrl.text.trim(),
      ),
      provider: ProviderInfo(repsCode: '', name: _providerNameCtrl.text.trim()),
      clinicalEvaluation: ClinicalEvaluation(
        historyOfCurrentIllness: _clinicalDescCtrl.text.trim().isNotEmpty
            ? _clinicalDescCtrl.text.trim()
            : null,
        generalPhysicalExamination: null,
        systemsExamination: null,
        treatmentPlanObservations: _prescriptionCtrl.text.trim().isNotEmpty
            ? _prescriptionCtrl.text.trim()
            : null,
      ),
      // Backend LLM fills icd10/icd11 codes from the free-text description
      diagnosis: <DiagnosisItem>[],
    );

    final updatedRecord = PatientFullRecord(
      patientId: _patient!.patientId,
      deviceUid: _patient!.deviceUid,
      patientInfo: _patient!.patientInfo.copyWith(
        weight:
            double.tryParse(_weightCtrl.text) ?? _patient!.patientInfo.weight,
        height:
            double.tryParse(_heightCtrl.text) ?? _patient!.patientInfo.height,
      ),
      guardianInfo: _patient!.guardianInfo,
      backgroundHistory: _patient!.backgroundHistory,
      allergies: _patient!.allergies,
      medicalHistory: [..._patient!.medicalHistory, newConsultation],
      vaccinationRecord: _patient!.vaccinationRecord,
    );

    try {
      final scope = AppScope.of(context);
      await scope.localDatabase.savePatient(updatedRecord);
      try {
        await scope.patientRepository.syncPatient(updatedRecord);
        await scope.localDatabase.markSynced(updatedRecord.patientId);
      } catch (_) {}
      if (mounted)
        setState(() {
          _saved = true;
          _isSaving = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SharedReadNfcHeader(
                  title: s.addConsultation,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _patient == null
                      ? _buildScanStep()
                      : _saved
                      ? _buildSuccessStep(s)
                      : _buildFormStep(s),
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

  // ── Step A: Scan patient wristband ────────────────────────────────────────

  Widget _buildScanStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medical_services,
            size: 64,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Escanear paciente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Acerque la manilla del paciente para registrar la consulta.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _scanning ? null : _scanPatient,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
                color: const Color(0x0A1CABE2),
              ),
              child: _scanning
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(
                      Icons.nfc_rounded,
                      size: 80,
                      color: AppColors.primary,
                    ),
            ),
          ),
          if (_scanError != null) ...[
            const SizedBox(height: 12),
            Text(
              _scanError!,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          // Manual search button as fallback
          SizedBox(
            width: 200,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () => _showManualSearchDialog(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: const BorderSide(color: AppColors.primary),
              ),
              icon: const Icon(
                Icons.search,
                size: 18,
                color: AppColors.primary,
              ),
              label: const Text(
                'Buscar paciente',
                style: TextStyle(fontSize: 14, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualSearchDialog() {
    final uidCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buscar por UID'),
        content: TextField(
          controller: uidCtrl,
          decoration: const InputDecoration(
            hintText: 'Ingrese UID de la manilla',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (uidCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _scanning = true;
                  _scanError = null;
                });
                AppScope.of(context).patientRepository
                    .scanDevice(uidCtrl.text.trim())
                    .then((p) {
                      if (mounted)
                        setState(() {
                          _patient = p;
                          _scanning = false;
                        });
                    })
                    .catchError((Object e) {
                      if (mounted) {
                        setState(() {
                          _scanError = e.toString();
                          _scanning = false;
                        });
                      }
                    });
              }
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  // ── Step B: Consultation form ─────────────────────────────────────────────

  Widget _buildFormStep(AppStrings s) {
    final p = _patient!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.patientInfo.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${p.patientInfo.dob} · ${p.patientInfo.biologicalSex}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Allergy warning
                if (p.allergies.isNotEmpty)
                  Tooltip(
                    message:
                        'Alerta: ${p.allergies.length} alergia(s) registrada(s)',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${p.allergies.length} alergia(s)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Drug allergy alerts
          for (final a in p.allergies.where((a) => a.category == '01'))
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠ Alerta de alergia: ${a.allergen}. No prescribir derivados.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // ── Vital signs ─────────────────────────────────────────────────
          _sectionTitle('Signos vitales'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _vitalField(
                  'Peso (kg)',
                  _weightCtrl,
                  Icons.monitor_weight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _vitalField(
                  'Estatura (cm)',
                  _heightCtrl,
                  Icons.open_in_full,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _vitalField('T° (°C)', _tempCtrl, Icons.thermostat),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _vitalField('FC (lpm)', _heartRateCtrl, Icons.favorite),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _vitalField('SatO₂ (%)', _satO2Ctrl, Icons.air),

          const SizedBox(height: 20),

          // ── Chief complaint ──────────────────────────────────────────────
          _sectionTitle('Motivo de consulta'),
          const SizedBox(height: 10),
          // Main symptom chip selector
          const Text(
            'Síntoma principal *',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _symptoms.map((sym) {
              final sel = _mainSymptom == sym;
              return GestureDetector(
                onTap: () => setState(() => _mainSymptom = sym),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.secondary : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppColors.secondary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    sym,
                    style: TextStyle(
                      fontSize: 13,
                      color: sel ? AppColors.white : AppColors.textPrimary,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _textArea(
            'Descripción clínica *',
            _clinicalDescCtrl,
            hint: 'Paciente con fiebre >48h, tos seca nocturna...',
          ),

          const SizedBox(height: 20),

          // ── Diagnosis + plan ─────────────────────────────────────────────
          _sectionTitle('Diagnóstico y plan'),
          const SizedBox(height: 10),
          _dropdownField(
            'Tipo de diagnóstico',
            _diagnosisType,
            _diagnosisTypes,
            (v) {
              if (v != null) setState(() => _diagnosisType = v);
            },
          ),
          const SizedBox(height: 10),
          _textArea(
            'Diagnóstico / observaciones',
            _diagnosisDescCtrl,
            hint:
                'El LLM del backend completará los códigos CIE-10/11 automáticamente',
          ),
          const SizedBox(height: 10),
          _textArea(
            'Prescripción',
            _prescriptionCtrl,
            hint: 'Acetaminofén 500mg c/8h x 3 días...',
          ),

          const SizedBox(height: 20),

          // ── Care metadata ────────────────────────────────────────────────
          _sectionTitle('Personal médico'),
          const SizedBox(height: 10),
          _textField(
            'Nombre del médico',
            _practitionerNameCtrl,
            Icons.local_hospital,
          ),
          const SizedBox(height: 10),
          _textField(
            'Nombre del prestador / brigada',
            _providerNameCtrl,
            Icons.apartment,
          ),
          const SizedBox(height: 10),
          _dropdownField(
            'Modalidad de atención',
            _careModality,
            _careModalities,
            (v) {
              if (v != null) setState(() => _careModality = v);
            },
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (!_isFormValid || _isSaving) ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.disabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(
                      Icons.medical_services,
                      size: 22,
                      color: AppColors.white,
                    ),
              label: Text(
                _isSaving ? 'Guardando...' : 'Guardar consulta',
                style: const TextStyle(color: AppColors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step C: Success ───────────────────────────────────────────────────────

  Widget _buildSuccessStep(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00A396),
            ),
            child: const Icon(Icons.check, size: 48, color: AppColors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Consulta guardada',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _patient?.patientInfo.fullName ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Allergy reminder in success screen
          if (_patient?.allergies.any((a) => a.category == '01') == true) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Recuerde las alertas de alergia al entregar la prescripción.',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              const Text(
                'Guardado:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              const Text(
                'Localmente',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.cloud_upload,
                size: 20,
                color: Color(0xFFE6A817),
              ),
              const SizedBox(width: 10),
              const Text(
                'Sync:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              const Text(
                'Pendiente',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.textSecondary),
              ),
              child: const Text('Volver', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    ),
  );

  Widget _vitalField(String label, TextEditingController ctrl, IconData icon) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              prefixIcon: Icon(icon, size: 16, color: AppColors.secondary),
            ),
          ),
        ],
      );

  Widget _textField(String label, TextEditingController ctrl, IconData icon) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              prefixIcon: Icon(icon, size: 18, color: AppColors.secondary),
            ),
          ),
        ],
      );

  Widget _textArea(
    String label,
    TextEditingController ctrl, {
    String? hint,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        maxLines: 3,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.disabled),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    ],
  );

  Widget _dropdownField(
    String label,
    String value,
    Map<String, String> opts,
    ValueChanged<String?> cb,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            items: opts.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: cb,
          ),
        ),
      ),
    ],
  );
}
