// lib/src/features/nfc/presentation/add_vaccine_screen.dart
import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/nfc/nfc_service.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'shared_read_nfc_header.dart';

/// Screen for adding a VaccinationRecordItem to an existing patient.
/// Covers every field of VaccinationRecordItem from patient.py.
class AddVaccineScreen extends StatefulWidget {
  const AddVaccineScreen({
    super.key,
    this.patient,
    this.returnToProfile = false,
  });

  final PatientFullRecord? patient;
  final bool returnToProfile;

  @override
  State<AddVaccineScreen> createState() => _AddVaccineScreenState();
}

class _AddVaccineScreenState extends State<AddVaccineScreen> {
  PatientFullRecord? _patient;
  bool _scanning = false;
  String? _scanError;
  bool _isSaving = false;
  bool _saved = false;

  // ── Form fields (mirror VaccinationRecordItem exactly) ────────────────────
  final _vaccineNameCtrl = TextEditingController(); // vaccineName: str
  final _cvxCodeCtrl = TextEditingController();     // vaccineCode: str (CVX)
  int _dose = 1;                                    // dose: int
  DateTime _date = DateTime.now();                  // date: date (YYYY-MM-DD)
  final _byCtrl = TextEditingController();          // administratedBy: str
  final _atCtrl = TextEditingController();          // administratedAt: str
  String _status = 'completed';                     // status: str

  // ── Common vaccines catalog ───────────────────────────────────────────────
  static const List<Map<String, String>> _commonVaccines = [
    {'name': 'BCG (Tuberculosis)', 'code': '19'},
    {'name': 'Hepatitis B', 'code': '08'},
    {'name': 'Pentavalente (DPT+HB+Hib)', 'code': '01'},
    {'name': 'Polio oral (VOP)', 'code': '02'},
    {'name': 'Polio inactivada (VIP)', 'code': '10'},
    {'name': 'Triple Viral (SRP)', 'code': '03'},
    {'name': 'Varicela', 'code': '21'},
    {'name': 'Influenza pediátrica', 'code': '141'},
    {'name': 'Influenza adulto', 'code': '140'},
    {'name': 'Neumococo (PCV13)', 'code': '133'},
    {'name': 'Rotavirus', 'code': '116'},
    {'name': 'Meningococo', 'code': '108'},
    {'name': 'Fiebre amarilla', 'code': '37'},
    {'name': 'COVID-19', 'code': '213'},
    {'name': 'Otra (especificar)', 'code': ''},
  ];

  static const Map<String, String> _statusOpts = {
    'completed': 'Administrada',
    'refused': 'Rehusada por paciente',
    'not_given': 'No administrada (justificar)',
  };

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  @override
  void dispose() {
    _vaccineNameCtrl.dispose();
    _cvxCodeCtrl.dispose();
    _byCtrl.dispose();
    _atCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _formattedDate =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  bool get _isFormValid =>
      _vaccineNameCtrl.text.trim().isNotEmpty &&
      _cvxCodeCtrl.text.trim().isNotEmpty &&
      _byCtrl.text.trim().isNotEmpty &&
      _atCtrl.text.trim().isNotEmpty;

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

    final newVaccine = VaccinationRecordItem(
      date: _formattedDate,
      vaccineName: _vaccineNameCtrl.text.trim(),
      vaccineCode: _cvxCodeCtrl.text.trim(),
      dose: _dose,
      administratedBy: _byCtrl.text.trim(),
      administratedAt: _atCtrl.text.trim(),
      status: _status,
    );

    // When called from PatientProfileScreen, return item to caller.
    if (widget.returnToProfile) {
      if (mounted) Navigator.of(context).pop(newVaccine);
      return;
    }

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
            content: Text('Vacuna guardada exitosamente ✓'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
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
                  title: s.addVaccine,
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
          const Icon(Icons.vaccines, size: 64, color: AppColors.secondary),
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
            'Acerque la manilla del paciente para registrar la vacuna.',
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
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                  : const Icon(Icons.nfc_rounded, size: 80, color: AppColors.primary),
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
              icon: const Icon(Icons.search, size: 18, color: AppColors.primary),
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
          decoration: const InputDecoration(hintText: 'Ingrese UID de la manilla'),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 22, color: AppColors.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.patientInfo.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
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
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Vaccine selection ────────────────────────────────────────────
          _SectionCard(
            icon: Icons.vaccines_outlined,
            title: 'Vacuna *',
            children: [
              const Text(
                'Seleccione una vacuna frecuente',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: _commonVaccines.map((v) {
                  final sel = _vaccineNameCtrl.text == v['name'] &&
                      _cvxCodeCtrl.text == v['code'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _vaccineNameCtrl.text = v['name']!;
                      _cvxCodeCtrl.text = v['code']!;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.secondary : AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: sel
                              ? AppColors.secondary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        v['name']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: sel
                              ? AppColors.white
                              : AppColors.textPrimary,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _labeledField(
                'Nombre de la vacuna *',
                _vaccineNameCtrl,
                hint: 'Ej: Triple Viral (SRP)',
              ),
              const SizedBox(height: 10),
              _labeledField(
                'Código CVX *',
                _cvxCodeCtrl,
                hint: 'Ej: 03',
                keyboard: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Dose ─────────────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.numbers_outlined,
            title: 'Dosis',
            children: [
              const Text(
                'Número de dosis',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (int i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () => setState(() => _dose = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: _dose == i
                              ? AppColors.secondary
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _dose == i
                                ? AppColors.secondary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          i == 5 ? 'Refuerzo' : '${i}ª',
                          style: TextStyle(
                            fontSize: 13,
                            color: _dose == i
                                ? AppColors.white
                                : AppColors.textPrimary,
                            fontWeight: _dose == i
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Administration ────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.event_available_outlined,
            title: 'Administración',
            children: [
              // Date picker
              const Text(
                'Fecha de administración *',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && mounted) {
                    setState(() => _date = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.divider, width: 1.4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        _formattedDate,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit,
                          size: 14, color: AppColors.disabled),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _labeledField(
                'Administrado por *',
                _byCtrl,
                hint: 'Ej: Enf. Ana Ruiz',
              ),
              const SizedBox(height: 10),
              _labeledField(
                'Lugar de administración *',
                _atCtrl,
                hint: 'Ej: Brigada Frontera Cúcuta',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Status ────────────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.check_circle_outline,
            title: 'Estado de la vacuna',
            children: [
              const Text(
                'Estado',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Column(
                children: _statusOpts.entries.map((e) {
                  final sel = _status == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _status = e.key),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.secondary.withValues(alpha: 0.08)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? AppColors.secondary
                              : AppColors.divider,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sel
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: sel
                                ? AppColors.secondary
                                : AppColors.disabled,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 13,
                                color: sel
                                    ? AppColors.secondary
                                    : AppColors.textPrimary,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
                backgroundColor: AppColors.secondary,
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
                  : const Icon(Icons.vaccines, size: 22, color: AppColors.white),
              label: Text(
                _isSaving ? 'Guardando...' : 'Guardar vacuna',
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
            'Vacuna guardada exitosamente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${_patient?.patientInfo.fullName ?? ''} · ${_vaccineNameCtrl.text}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
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
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _saved = false;
                  _patient = null;
                  _vaccineNameCtrl.clear();
                  _cvxCodeCtrl.clear();
                  _dose = 1;
                  _date = DateTime.now();
                  _byCtrl.clear();
                  _atCtrl.clear();
                  _status = 'completed';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.vaccines, size: 20, color: AppColors.white),
              label: const Text(
                'Registrar otra vacuna',
                style: TextStyle(color: AppColors.white, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
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

  Widget _labeledField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType keyboard = TextInputType.text,
  }) =>
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
            keyboardType: keyboard,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.disabled,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
            ),
          ),
        ],
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

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
              Icon(icon, size: 16, color: AppColors.secondary),
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
