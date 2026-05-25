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

// ── Internal template for each vaccine in the session ──────────────────────────────
class _VaccineEntry {
  _VaccineEntry()
      : nameCtrl = TextEditingController(),
        cvxCtrl = TextEditingController(),
        dose = 1;

  final TextEditingController nameCtrl;
  final TextEditingController cvxCtrl;
  int dose;

  bool get isValid =>
      nameCtrl.text.trim().isNotEmpty && cvxCtrl.text.trim().isNotEmpty;

  void dispose() {
    nameCtrl.dispose();
    cvxCtrl.dispose();
  }
}

typedef VaccineEntry = _VaccineEntry;

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

  // ── Vaccine list — starts with a blank entry ─────────────────────
  final List<_VaccineEntry> _entries = [_VaccineEntry()];

  // ── Shared administration fields ─────────────────────────────────
  DateTime _date = DateTime.now();
  final _byCtrl = TextEditingController();
  final _atCtrl = TextEditingController();
  String _status = 'completed';

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
    for (final e in _entries) {
      e.dispose();
    }
    _byCtrl.dispose();
    _atCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _formattedDate =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  bool get _isFormValid =>
      _entries.isNotEmpty &&
      _entries.every((e) => e.isValid) &&
      _byCtrl.text.trim().isNotEmpty &&
      _atCtrl.text.trim().isNotEmpty;

  void _addEntry() {
    setState(() => _entries.add(_VaccineEntry()));
  }

  void _removeEntry(int index) {
    if (_entries.length <= 1) return;
    final removed = _entries[index];
    setState(() {
      _entries.removeAt(index);
    });
    removed.dispose();
  }

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
    } catch (_) {
      if (mounted) setState(() => _scanError = 'No se pudo leer el dispositivo.');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_patient == null) return;
    setState(() => _isSaving = true);

    final newVaccines = _entries.map((e) => VaccinationRecordItem(
      date: _formattedDate,
      vaccineName: e.nameCtrl.text.trim(),
      vaccineCode: e.cvxCtrl.text.trim(),
      dose: e.dose,
      administratedBy: _byCtrl.text.trim(),
      administratedAt: _atCtrl.text.trim(),
      status: _status,
    )).toList();

    if (widget.returnToProfile) {
      if (mounted) Navigator.of(context).pop(newVaccines.first);
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
      vaccinationRecord: [..._patient!.vaccinationRecord, ...newVaccines],
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
          SnackBar(
            content: Text(
              newVaccines.length == 1
                  ? 'Vacuna guardada exitosamente'
                  : '${newVaccines.length} vacunas guardadas exitosamente ✓',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo guardar. Intentalo de nuevo.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final titleText = s.addVaccine ?? 'Agregar vacuna';
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SharedReadNfcHeader(
                  title: titleText,
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
            'Acerque el dispositivo NFC del paciente para registrar las vacunas.',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      if (mounted) setState(() {
                        _patient = p;
                        _scanning = false;
                      });
                    })
                    .catchError((Object e) {
                      if (mounted) setState(() {
                        _scanError = e.toString();
                        _scanning = false;
                      });
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Patient badge ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.2),
                width: 1.5,
              ),
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
                        '${p.patientInfo.dob} - ${p.patientInfo.biologicalSex}',
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
          const SizedBox(height: 20),

          // ── Vaccine header + Add button ─────────────────────────
          Row(
            children: [
              const Icon(
                Icons.vaccines_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Vacunas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addEntry,
                icon: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppColors.secondary,
                ),
                label: const Text(
                  'Agregar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Vaccine list ──────────────────────────────────────────────
          ...List.generate(_entries.length, (i) {
            final entry = _entries[i];
            return _VaccineEntryCard(
              key: ObjectKey(entry),
              index: i,
              total: _entries.length,
              entry: entry,
              commonVaccines: _commonVaccines,
              onRemove: _entries.length > 1 ? () => _removeEntry(i) : null,
              onChanged: () => setState(() {}),
            );
          }),

          const SizedBox(height: 20),

          // ── Administration section (shared for all) ────────────────
          _SectionCard(
            icon: Icons.event_available_outlined,
            title: 'Administracion',
            subtitle: 'Aplica a todas las vacunas de esta sesion',
            children: [
              _FieldLabel(label: 'Fecha de administracion', required: true),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primary,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null && mounted) setState(() => _date = picked);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _StyledTextField(
                label: 'Administrado por',
                controller: _byCtrl,
                hint: 'Ej: Enf. Ana Ruiz',
                required: true,
                icon: Icons.person_outline,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),

              _StyledTextField(
                label: 'Lugar de administracion',
                controller: _atCtrl,
                hint: 'Ej: Brigada Frontera Cucuta',
                required: true,
                icon: Icons.location_on_outlined,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Status ────────────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.check_circle_outline,
            title: 'Estado',
            children: [
              Column(
                children: _statusOpts.entries.map((e) {
                  final sel = _status == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _status = e.key),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.secondary.withValues(alpha: 0.08)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? AppColors.secondary
                              : const Color(0xFFB0B8C4),
                          width: 1.5,
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
                elevation: 0,
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
                      Icons.vaccines,
                      size: 22,
                      color: AppColors.white,
                    ),
              label: Text(
                _isSaving
                    ? 'Guardando...'
                    : _entries.length == 1
                        ? 'Guardar vacuna'
                        : 'Guardar ${_entries.length} vacunas',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
          Text(
            _entries.length == 1
                ? 'Vacuna guardada exitosamente'
                : '${_entries.length} vacunas guardadas exitosamente',
            style: const TextStyle(
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
            label: 'Sincronizacion',
            value: 'En cola (segundo plano)',
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                final toDispose = List<_VaccineEntry>.from(_entries);
                setState(() {
                  _saved = false;
                  _patient = null;
                  _entries
                    ..clear()
                    ..add(_VaccineEntry());
                  _date = DateTime.now();
                  _byCtrl.clear();
                  _atCtrl.clear();
                  _status = 'completed';
                });
                for (final e in toDispose) {
                  e.dispose();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.vaccines, size: 20, color: AppColors.white),
              label: const Text(
                'Registrar otra sesion',
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
                side: const BorderSide(color: Color(0xFFB0B8C4), width: 1.5),
              ),
              child: const Text('Volver', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Individual vaccination card (Vaccine + Dose)
// ═════════════════════════════════════════════════════════════════════════════

class _VaccineEntryCard extends StatefulWidget {
  const _VaccineEntryCard({
    Key? key,
    required this.index,
    required this.total,
    required this.entry,
    required this.commonVaccines,
    required this.onChanged,
    this.onRemove,
  }) : super(key: key);

  final int index;
  final int total;
  final _VaccineEntry entry;
  final List<Map<String, String>> commonVaccines;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  State<_VaccineEntryCard> createState() => _VaccineEntryCardState();
}

class _VaccineEntryCardState extends State<_VaccineEntryCard> {
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final hasName = entry.nameCtrl.text.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasName
              ? AppColors.secondary.withValues(alpha: 0.4)
              : const Color(0xFFB0B8C4),
          width: 1.5,
        ),
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
          // ── Header de la card ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasName
                        ? entry.nameCtrl.text.trim()
                        : 'Vacuna ${widget.index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasName
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Botón eliminar (solo si hay más de una vacuna)
                if (widget.onRemove != null)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.error,
                    ),
                    tooltip: 'Eliminar esta vacuna',
                  ),
              ],
            ),
          ),

          const Divider(height: 16, thickness: 1, color: Color(0xFFF0F0F0)),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Vacunas frecuentes ──────────────────────────────────
                const Text(
                  'Seleccione una vacuna frecuente',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.commonVaccines.map((v) {
                    final sel =
                        entry.nameCtrl.text == v['name'] &&
                        entry.cvxCtrl.text == v['code'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          entry.nameCtrl.text = v['name']!;
                          entry.cvxCtrl.text = v['code']!;
                        });
                        widget.onChanged();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.secondary : AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: sel
                                ? AppColors.secondary
                                : const Color(0xFFB0B8C4),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          v['name']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: sel
                                ? AppColors.white
                                : AppColors.textPrimary,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // ── Vaccine name ───────────────────────────────────────
                _StyledTextField(
                  label: 'Nombre de la vacuna',
                  controller: entry.nameCtrl,
                  hint: 'Ej: Triple Viral (SRP)',
                  required: true,
                  onChanged: () {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: 10),

                // ── CVX Code ──────────────────────────────────────────
                _StyledTextField(
                  label: 'Codigo CVX',
                  controller: entry.cvxCtrl,
                  hint: 'Ej: 03',
                  required: true,
                  keyboardType: TextInputType.number,
                  onChanged: () {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: 14),

                // ── Dosis ───────────────────────────────────────────────
                const Text(
                  'Numero de dosis',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      GestureDetector(
                        onTap: () {
                          setState(() => entry.dose = i);
                          widget.onChanged();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: entry.dose == i
                                ? AppColors.secondary
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: entry.dose == i
                                  ? AppColors.secondary
                                  : const Color(0xFFB0B8C4),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            i == 5 ? 'Refuerzo' : 'Dosis $i',
                            style: TextStyle(
                              fontSize: 13,
                              color: entry.dose == i
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                              fontWeight: entry.dose == i
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
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.required = false,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool required;
  final IconData? icon;
  final TextInputType keyboardType;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged != null ? (_) => onChanged!() : null,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.white,
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: AppColors.textSecondary)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
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
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
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
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}