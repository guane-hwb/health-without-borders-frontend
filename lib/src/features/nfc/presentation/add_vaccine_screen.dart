// lib/src/features/nfc/presentation/add_vaccine_screen.dart
import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/nfc/nfc_service.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'read_nfc_screen.dart';
import 'shared_read_nfc_header.dart';

/// Screen for adding a vaccine to an existing patient.
///
/// Flow:
///   1. If [patient] is null → first scan the patient's wristband.
///   2. Fill vaccine form.
///   3. Calls POST /sync with the full updated PatientFullRecord.
class AddVaccineScreen extends StatefulWidget {
  const AddVaccineScreen({super.key, this.patient});

  /// Pre-loaded patient. When null the screen starts at the NFC scan step.
  final PatientFullRecord? patient;

  @override
  State<AddVaccineScreen> createState() => _AddVaccineScreenState();
}

class _AddVaccineScreenState extends State<AddVaccineScreen> {
  // ── State ─────────────────────────────────────────────────────────────────
  PatientFullRecord? _patient;
  bool _scanning = false;
  String? _scanError;
  bool _isSaving = false;
  bool _saved = false;

  // ── Form controllers ──────────────────────────────────────────────────────
  final _vaccineNameCtrl = TextEditingController();
  final _cvxCodeCtrl = TextEditingController();
  final _doseCtrl = TextEditingController(text: '1');
  final _byCtrl = TextEditingController();
  final _atCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _reaction = 'Sin reacción';

  static const List<String> _reactionOptions = [
    'Sin reacción', 'Eritema leve', 'Fiebre 24h', 'Dolor local',
  ];

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  @override
  void dispose() {
    _vaccineNameCtrl.dispose();
    _cvxCodeCtrl.dispose();
    _doseCtrl.dispose();
    _byCtrl.dispose();
    _atCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _formattedDate =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  // ── NFC scan ──────────────────────────────────────────────────────────────

  Future<void> _scanPatient() async {
    setState(() { _scanning = true; _scanError = null; });
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

  // ── Validation ────────────────────────────────────────────────────────────

  bool get _isFormValid =>
      _vaccineNameCtrl.text.trim().isNotEmpty &&
      _cvxCodeCtrl.text.trim().isNotEmpty &&
      _byCtrl.text.trim().isNotEmpty;

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_patient == null) return;
    setState(() => _isSaving = true);

    final newVaccine = VaccinationRecordItem(
      date: _formattedDate,
      vaccineName: _vaccineNameCtrl.text.trim(),
      vaccineCode: _cvxCodeCtrl.text.trim(),
      dose: int.tryParse(_doseCtrl.text) ?? 1,
      administratedBy: _byCtrl.text.trim(),
      administratedAt: _atCtrl.text.trim(),
      status: 'completed',
    );

    final updatedRecord = PatientFullRecord(
      patientId: _patient!.patientId,
      deviceUid: _patient!.deviceUid,
      patientInfo: _patient!.patientInfo,
      guardianInfo: _patient!.guardianInfo,
      backgroundHistory: _patient!.backgroundHistory,
      allergies: _patient!.allergies,
      medicalHistory: _patient!.medicalHistory,
      vaccinationRecord: [..._patient!.vaccinationRecord, newVaccine],
    );

    try {
      final scope = AppScope.of(context);
      // Save locally first (offline-first)
      await scope.localDatabase.savePatient(updatedRecord);
      // Try cloud sync
      try {
        await scope.patientRepository.syncPatient(updatedRecord);
        await scope.localDatabase.markSynced(updatedRecord.patientId);
      } catch (_) {
        // Sync will retry — local save is enough
      }
      if (mounted) setState(() { _saved = true; _isSaving = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
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
        child: Stack(children: [
          Column(children: [
            SharedReadNfcHeader(
              title: s.addVaccine,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _patient == null
                  ? _buildScanStep(s)
                  : _saved
                      ? _buildSuccessStep(s)
                      : _buildFormStep(s),
            ),
          ]),
          const Positioned(
            left: 116, right: 116, bottom: 14,
            child: ScreenBottomHandle(),
          ),
        ]),
      ),
    );
  }

  // ── Step A: Scan patient ──────────────────────────────────────────────────

  Widget _buildScanStep(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.vaccines, size: 64, color: AppColors.secondary),
          const SizedBox(height: 16),
          Text('Escanear paciente',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.secondary)),
          const SizedBox(height: 8),
          Text('Acerque la manilla del paciente para registrar la vacuna.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _scanning ? null : _scanPatient,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
                color: const Color(0x0A1CABE2),
              ),
              child: _scanning
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                  : const Icon(Icons.nfc_rounded, size: 80, color: AppColors.primary),
            ),
          ),
          if (_scanError != null) ...[
            const SizedBox(height: 12),
            Text(_scanError!,
                style: const TextStyle(fontSize: 13, color: AppColors.error),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          Text('o', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6))),
          const SizedBox(height: 12),
          SizedBox(
            width: 200, height: 40,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Navigate to full ReadNFC flow and wait for a patient
                final result = await Navigator.of(context).push<PatientFullRecord>(
                  MaterialPageRoute(builder: (_) => const ReadNfcScreen()),
                );
                if (result != null && mounted) {
                  setState(() => _patient = result);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.search, size: 18, color: AppColors.white),
              label: Text(s.readNfc, style: const TextStyle(color: AppColors.white, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step B: Vaccine form ──────────────────────────────────────────────────

  Widget _buildFormStep(AppStrings s) {
    final p = _patient!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 60),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Patient badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.person, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.patientInfo.fullName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
              Text('${p.patientInfo.dob} · ${p.patientInfo.biologicalSex}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            // Allergy warning if any drug allergies
            if (p.allergies.any((a) => a.category == '01'))
              const Tooltip(
                message: 'Tiene alergia a medicamentos',
                child: Icon(Icons.warning_amber, size: 20, color: AppColors.error),
              ),
          ]),
        ),

        const SizedBox(height: 20),
        _sectionTitle('Vacuna'),
        const SizedBox(height: 12),
        _textField(s.vaccineName, _vaccineNameCtrl, hint: 'ej: Triple Viral (SRP)'),
        const SizedBox(height: 12),
        _textField(s.cvxCode, _cvxCodeCtrl, hint: 'ej: 03'),
        const SizedBox(height: 12),

        // Dose picker
        _label(s.dose),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8, runSpacing: 6,
          children: List.generate(5, (i) {
            final dose = '${i + 1}';
            final selected = _doseCtrl.text == dose;
            return GestureDetector(
              onTap: () => setState(() => _doseCtrl.text = dose),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.secondary : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? AppColors.secondary : AppColors.divider),
                ),
                child: Text(
                  i == 4 ? 'Refuerzo' : '${i + 1}ª dosis',
                  style: TextStyle(fontSize: 13, color: selected ? AppColors.white : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),
        _sectionTitle('Administración'),
        const SizedBox(height: 12),

        // Date
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider, width: 1.5),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today, size: 18, color: AppColors.secondary),
              const SizedBox(width: 10),
              Text(_formattedDate, style: const TextStyle(fontSize: 14)),
              const Spacer(),
              const Icon(Icons.edit, size: 14, color: AppColors.disabled),
            ]),
          ),
        ),

        const SizedBox(height: 12),
        _textField(s.administeredBy, _byCtrl, hint: 'ej: Enf. Ana Ruiz'),
        const SizedBox(height: 12),
        _textField(s.administeredAt, _atCtrl, hint: 'ej: Brigada Frontera'),

        const SizedBox(height: 16),
        _sectionTitle('Reacciones / notas'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 6,
          children: _reactionOptions.map((opt) {
            final sel = _reaction == opt;
            return FilterChip(
              label: Text(opt, style: TextStyle(fontSize: 12, color: sel ? AppColors.white : AppColors.textPrimary)),
              selected: sel,
              onSelected: (_) => setState(() => _reaction = opt),
              selectedColor: AppColors.secondary,
              checkmarkColor: AppColors.white,
              backgroundColor: AppColors.white,
              side: BorderSide(color: sel ? AppColors.secondary : AppColors.divider),
            );
          }).toList(),
        ),

        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton.icon(
            onPressed: (!_isFormValid || _isSaving) ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              disabledBackgroundColor: AppColors.disabled,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                : const Icon(Icons.vaccines, size: 22, color: AppColors.white),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar vacuna',
                style: const TextStyle(color: AppColors.white, fontSize: 16)),
          ),
        ),
      ]),
    );
  }

  // ── Step C: Success ───────────────────────────────────────────────────────

  Widget _buildSuccessStep(AppStrings s) {
    final p = _patient!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00A396),
            ),
            child: const Icon(Icons.check, size: 48, color: AppColors.white),
          ),
          const SizedBox(height: 20),
          const Text('Vacuna registrada',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.secondary)),
          const SizedBox(height: 6),
          Text('${p.patientInfo.firstName} · ${_vaccineNameCtrl.text}',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          _confirmRow(Icons.check_circle, AppColors.success, 'Guardado:', 'Localmente'),
          const SizedBox(height: 8),
          _confirmRow(Icons.cloud_upload, const Color(0xFFE6A817), 'Sync:', 'Pendiente'),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() { _saved = false; _patient = null; _vaccineNameCtrl.clear(); _cvxCodeCtrl.clear(); _doseCtrl.text = '1'; _byCtrl.clear(); _atCtrl.clear(); _reaction = 'Sin reacción'; });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.vaccines, size: 20, color: AppColors.white),
              label: const Text('Registrar otra vacuna',
                  style: TextStyle(color: AppColors.white, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: AppColors.textSecondary),
              ),
              child: const Text('Volver', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(IconData icon, Color color, String label, String value) {
    return Row(children: [
      Icon(icon, size: 20, color: color), const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(width: 6),
      Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
    ]);
  }

  // ── Widget helpers ────────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary));

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary));

  Widget _textField(String label, TextEditingController ctrl, {String? hint}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true, hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.disabled),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ]);
}