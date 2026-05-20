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

/// Screen for adding a medical consultation (MedicalHistoryItem) to a patient.
/// Covers every field of MedicalHistoryItem from patient.py.
/// diagnosis[] is always sent as [] — the backend LLM fills it.
class AddConsultationScreen extends StatefulWidget {
  const AddConsultationScreen({
    super.key,
    this.patient,
    this.returnToProfile = false,
  });

  final PatientFullRecord? patient;
  final bool returnToProfile;

  @override
  State<AddConsultationScreen> createState() => _AddConsultationScreenState();
}

class _AddConsultationScreenState extends State<AddConsultationScreen> {
  PatientFullRecord? _patient;
  bool _scanning = false;
  String? _scanError;
  bool _isSaving = false;
  bool _saved = false;

  // ── Vitals (stored in patientInfo) ───────────────────────────────────────
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  // ── Encounter metadata ────────────────────────────────────────────────────
  DateTime _startDateTime = DateTime.now();
  DateTime? _endDateTime;
  String _careModality = '01';
  String _serviceGroup = '01';
  String _careEnvironment = '05';

  // ── Practitioner (Res. 866 Elems. 49.1, 49.2) ────────────────────────────
  String _practitionerDocType = 'CC';
  final _practitionerDocCtrl = TextEditingController();
  final _practitionerNameCtrl = TextEditingController();

  // ── Provider (Res. 866 Elem. 16) ─────────────────────────────────────────
  final _providerRepsCtrl = TextEditingController();
  final _providerNameCtrl = TextEditingController();

  // ── Payer (Res. 866 Elems. 15.1, 15.2) ───────────────────────────────────
  final _payerNameCtrl = TextEditingController(text: 'No asegurado');

  // ── Clinical evaluation ───────────────────────────────────────────────────
  final _historyCtrl = TextEditingController(); // historyOfCurrentIllness
  final _physicalExamCtrl =
      TextEditingController(); // generalPhysicalExamination
  final _systemsCtrl = TextEditingController(); // systemsExamination
  final _treatmentCtrl = TextEditingController(); // treatmentPlanObservations

  // ── Diagnosis type ────────────────────────────────────────────────────────
  String _diagnosisType = '01';

  // ── Discharge disposition (Elem. 41) ─────────────────────────────────────
  String? _dischargeDisposition;

  // ── Catalogs ──────────────────────────────────────────────────────────────
  static const Map<String, String> _careModalityOpts = {
    '01': 'Intramural',
    '02': 'Extramural - Móvil',
    '03': 'Extramural - Domiciliaria',
    '04': 'Extramural - Jornada',
    '05': 'Extramural - Prehospitalaria',
    '06': 'Telemedicina interactiva',
    '07': 'Telemedicina no interactiva',
    '08': 'Telemedicina - Telexperticia',
    '09': 'Telemedicina - Telemonitoreo',
  };
  static const Map<String, String> _serviceGroupOpts = {
    '01': 'Consulta externa',
    '02': 'Apoyo diagnóstico',
    '03': 'Internación',
    '04': 'Quirúrgico',
    '05': 'Atención inmediata',
  };
  static const Map<String, String> _careEnvOpts = {
    '01': 'Hogar',
    '02': 'Comunitario',
    '03': 'Escolar',
    '04': 'Laboral',
    '05': 'Institucional',
  };
  static const Map<String, String> _diagnosisTypeOpts = {
    '01': 'Impresión diagnóstica',
    '02': 'Confirmado nuevo',
    '03': 'Confirmado repetido',
  };
  static const Map<String, String> _dischargeOpts = {
    '': 'No aplica',
    '01': 'Alta voluntaria',
    '02': 'Paciente muerto',
    '03': 'Remitido',
    '04': 'Alta médica',
  };
  static const Map<String, String> _docTypeOpts = {
    'CC': 'Cédula Ciudadanía',
    'CE': 'Cédula Extranjería',
    'PA': 'Pasaporte',
    'TI': 'Tarjeta Identidad',
    'RC': 'Registro Civil',
    'MS': 'Sin identificación',
  };

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    if (_patient != null) {
      _weightCtrl.text = _patient!.patientInfo.weight?.toString() ?? '';
      _heightCtrl.text = _patient!.patientInfo.height?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _practitionerDocCtrl.dispose();
    _practitionerNameCtrl.dispose();
    _providerRepsCtrl.dispose();
    _providerNameCtrl.dispose();
    _payerNameCtrl.dispose();
    _historyCtrl.dispose();
    _physicalExamCtrl.dispose();
    _systemsCtrl.dispose();
    _treatmentCtrl.dispose();
    super.dispose();
  }

  bool get _isFormValid => _historyCtrl.text.trim().isNotEmpty;

  // ── NFC scan ──────────────────────────────────────────────────────────────

  Future<void> _scanPatient() async {
    setState(() {
      _scanning = true;
      _scanError = null;
    });
    final repo = AppScope.of(context).patientRepository;
    try {
      final uid = await NfcService.readDeviceUid();
      final patient = await repo.scanDevice(uid);
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

    // Build PractitionerInfo only if name is provided
    final practDoc = _practitionerDocCtrl.text.trim();
    final practName = _practitionerNameCtrl.text.trim();
    final PractitionerInfo? practitioner = practName.isNotEmpty
        ? PractitionerInfo(
            documentType: _practitionerDocType,
            documentNumber: practDoc.isEmpty ? '0' : practDoc,
            name: practName,
          )
        : null;

    // Build ProviderInfo only if name is provided
    final provReps = _providerRepsCtrl.text.trim();
    final provName = _providerNameCtrl.text.trim();
    final ProviderInfo? provider = provName.isNotEmpty
        ? ProviderInfo(
            repsCode: provReps.isEmpty ? '0' : provReps,
            name: provName,
          )
        : null;

    // Build PayerInfo
    final payerName = _payerNameCtrl.text.trim();
    final PayerInfo? payer = payerName.isNotEmpty
        ? PayerInfo(name: payerName)
        : null;

    final newConsultation = MedicalHistoryItem(
      type: 'Consultation',
      startDateTime: _startDateTime.toIso8601String(),
      endDateTime: _endDateTime?.toIso8601String(),
      careModality: _careModality,
      serviceGroup: _serviceGroup,
      careEnvironment: _careEnvironment,
      practitioner: practitioner,
      provider: provider,
      payer: payer,
      clinicalEvaluation: ClinicalEvaluation(
        historyOfCurrentIllness: _historyCtrl.text.trim().isNotEmpty
            ? _historyCtrl.text.trim()
            : null,
        generalPhysicalExamination: _physicalExamCtrl.text.trim().isNotEmpty
            ? _physicalExamCtrl.text.trim()
            : null,
        systemsExamination: _systemsCtrl.text.trim().isNotEmpty
            ? _systemsCtrl.text.trim()
            : null,
        treatmentPlanObservations: _treatmentCtrl.text.trim().isNotEmpty
            ? _treatmentCtrl.text.trim()
            : null,
      ),
      // Always empty — backend LLM fills this
      diagnosis: <DiagnosisItem>[],
      diagnosisType: _diagnosisType,
      dischargeDisposition: (_dischargeDisposition?.isEmpty ?? true)
          ? null
          : _dischargeDisposition,
      riskFactors: <RiskFactor>[],
    );

    // When called from PatientProfileScreen, return item to caller.
    if (widget.returnToProfile) {
      if (mounted) Navigator.of(context).pop(newConsultation);
      return;
    }

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
      // 1. Save locally — instant, never blocks
      await scope.localDatabase.savePatient(updatedRecord);

      if (mounted) {
        setState(() {
          _saved = true;
          _isSaving = false;
        });

        // 2. Fire-and-forget sync
        scope.syncEngine.syncAll().ignore();

        // 3. Success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consulta guardada exitosamente ✓'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                      ? _buildSuccessStep()
                      : _buildFormStep(),
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

  // ── Step A: Scan ──────────────────────────────────────────────────────────

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
            'Acerque el dispositivo NFC del paciente para registrar la consulta.',
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
                color: AppColors.primary.withValues(alpha: 0.06),
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
          SizedBox(
            width: 200,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _showManualSearchDialog,
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
            hintText: 'Ingrese UID del dispositivo NFC',
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
                      if (mounted) {
                        setState(() {
                          _patient = p;
                          _scanning = false;
                        });
                      }
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

  // ── Step B: Form ──────────────────────────────────────────────────────────

  Widget _buildFormStep() {
    final p = _patient!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Patient badge ────────────────────────────────────────────────
          _PatientBadge(patient: p),
          const SizedBox(height: 16),

          // ── Vitals (weight + height saved on patientInfo) ────────────────
          _SectionCard(
            icon: Icons.monitor_heart_outlined,
            title: 'Signos vitales',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _vitalField(
                      'Peso (kg)',
                      _weightCtrl,
                      Icons.monitor_weight_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _vitalField('Talla (cm)', _heightCtrl, Icons.height),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Encounter date/time ──────────────────────────────────────────
          _SectionCard(
            icon: Icons.schedule,
            title: 'Fecha y hora de atención',
            children: [
              _DateTimeRow(
                label: 'Inicio de atención *',
                value: _startDateTime,
                onPick: (dt) => setState(() => _startDateTime = dt),
              ),
              const SizedBox(height: 10),
              _DateTimeRow(
                label: 'Fin de atención (opcional)',
                value: _endDateTime,
                onPick: (dt) => setState(() => _endDateTime = dt),
                allowClear: true,
                onClear: () => setState(() => _endDateTime = null),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Care context ─────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.local_hospital_outlined,
            title: 'Contexto de atención',
            children: [
              _dropdownField(
                'Modalidad de atención (Elem. 18.1)',
                _careModality,
                _careModalityOpts,
                (v) {
                  if (v != null) setState(() => _careModality = v);
                },
              ),
              const SizedBox(height: 10),
              _dropdownField(
                'Grupo de servicios (Elem. 18.2)',
                _serviceGroup,
                _serviceGroupOpts,
                (v) {
                  if (v != null) setState(() => _serviceGroup = v);
                },
              ),
              const SizedBox(height: 10),
              _dropdownField(
                'Entorno de atención (Elem. 19)',
                _careEnvironment,
                _careEnvOpts,
                (v) {
                  if (v != null) setState(() => _careEnvironment = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Practitioner ─────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.badge_outlined,
            title: 'Profesional de salud (Elems. 49.1, 49.2)',
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: _dropdownField(
                      'Tipo doc.',
                      _practitionerDocType,
                      _docTypeOpts,
                      (v) {
                        if (v != null) setState(() => _practitionerDocType = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _textField(
                      'Nº documento',
                      _practitionerDocCtrl,
                      Icons.badge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _textField(
                'Nombre del profesional',
                _practitionerNameCtrl,
                Icons.person_outline,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Provider ─────────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.apartment_outlined,
            title: 'Prestador de servicios (Elem. 16)',
            children: [
              _textField(
                'Código REPS del prestador',
                _providerRepsCtrl,
                Icons.tag,
              ),
              const SizedBox(height: 10),
              _textField(
                'Nombre del prestador / brigada',
                _providerNameCtrl,
                Icons.business_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Payer ────────────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Entidad pagadora (Elem. 15)',
            children: [
              _textField(
                'Nombre de la EAPB / aseguradora',
                _payerNameCtrl,
                Icons.shield_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Clinical evaluation ──────────────────────────────────────────
          _SectionCard(
            icon: Icons.edit_note_outlined,
            title: 'Evaluación clínica',
            children: [
              _textArea(
                'Enfermedad actual / motivo de consulta *',
                _historyCtrl,
                hint: 'Fiebre de 3 días de evolución, tos seca, rinorrea...',
                required: true,
              ),
              const SizedBox(height: 10),
              _textArea(
                'Examen físico general',
                _physicalExamCtrl,
                hint: 'T: 38.2°C, FC: 110, FR: 28. Faringe eritematosa...',
              ),
              const SizedBox(height: 10),
              _textArea(
                'Revisión por sistemas',
                _systemsCtrl,
                hint:
                    'Pulmones: murmullo vesicular conservado sin agregados...',
              ),
              const SizedBox(height: 10),
              _textArea(
                'Plan de tratamiento y observaciones',
                _treatmentCtrl,
                hint: 'Acetaminofén 15mg/kg cada 6h. Control en 72h...',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Diagnosis type + discharge ────────────────────────────────────
          _SectionCard(
            icon: Icons.medical_information_outlined,
            title: 'Diagnóstico y egreso',
            children: [
              _dropdownField(
                'Tipo de diagnóstico (Elem. 37.3)',
                _diagnosisType,
                _diagnosisTypeOpts,
                (v) {
                  if (v != null) setState(() => _diagnosisType = v);
                },
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Los códigos CIE-10/11 se completan automáticamente por el LLM del backend a partir de la evaluación clínica.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _dropdownField(
                'Condición al egreso (Elem. 41)',
                _dischargeDisposition ?? '',
                _dischargeOpts,
                (v) {
                  setState(
                    () =>
                        _dischargeDisposition = (v?.isEmpty ?? true) ? null : v,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Save button ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
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
                  : const Icon(Icons.save, size: 22, color: AppColors.white),
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

  Widget _buildSuccessStep() {
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
              color: AppColors.success,
            ),
            child: const Icon(Icons.check, size: 48, color: AppColors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Consulta guardada exitosamente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _patient?.patientInfo.fullName ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _StatusRow(
            icon: Icons.storage_outlined,
            color: AppColors.success,
            label: 'Guardado local',
            value: 'Exitoso',
          ),
          const SizedBox(height: 8),
          _StatusRow(
            icon: Icons.cloud_upload_outlined,
            color: const Color(0xFFFB8C00),
            label: 'Sincronización',
            value: 'En cola (segundo plano)',
          ),
          if (_patient?.allergies.any((a) => a.category == '01') == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, size: 16, color: AppColors.error),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Recuerde las alertas de alergia al entregar la prescripción.',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: const Text('Volver', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────────────────

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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              filled: true,
              fillColor: AppColors.white,
              prefixIcon: Icon(icon, size: 16, color: AppColors.secondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFB0B8C4),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
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
              fontSize: 12,
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
                vertical: 11,
              ),
              filled: true,
              fillColor: AppColors.white,
              prefixIcon: Icon(icon, size: 17, color: AppColors.secondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFB0B8C4),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );

  Widget _textArea(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool required = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(fontSize: 12, color: AppColors.error),
            ),
        ],
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
          filled: true,
          fillColor: AppColors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFFB0B8C4),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
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
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            items: opts.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      e.value,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
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

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _PatientBadge extends StatelessWidget {
  const _PatientBadge({required this.patient});
  final PatientFullRecord patient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 22, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.patientInfo.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${patient.patientInfo.dob} · ${patient.patientInfo.biologicalSex}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (patient.allergies.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 14,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${patient.allergies.length} alergia(s)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.onPick,
    this.allowClear = false,
    this.onClear,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final bool allowClear;
  final VoidCallback? onClear;

  String _format(DateTime dt) {
    final d =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final t =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: value ?? now,
                    firstDate: DateTime(2000),
                    lastDate: now,
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(value ?? now),
                    );
                    if (context.mounted) {
                      onPick(
                        DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time?.hour ?? (value?.hour ?? now.hour),
                          time?.minute ?? (value?.minute ?? now.minute),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 15,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        value != null ? _format(value!) : '— no definido —',
                        style: TextStyle(
                          fontSize: 13,
                          color: value != null
                              ? AppColors.textPrimary
                              : AppColors.disabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (allowClear && value != null) ...[
              const SizedBox(width: 6),
              IconButton(
                onPressed: onClear,
                icon: const Icon(
                  Icons.clear,
                  size: 16,
                  color: AppColors.disabled,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}