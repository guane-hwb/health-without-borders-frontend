// lib/src/features/sync/presentation/sync_queue_screen.dart

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/storage/local_database.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_logo.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../nfc/domain/patient_record.dart';

/// "Pendientes por sincronizar" — shows all local records queued for sync.
///
/// Key behavior:
///   • No manual "Sync" buttons — sync happens automatically in the
///     background whenever the device detects connectivity.
///   • "Ver resumen" opens a read-only summary of the patient data.
///   • Records with errors show the error message and can be deleted.
///   • Successfully synced records are removed from this list.
class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({super.key});
  @override
  State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  List<LocalPatientEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final entries = await AppScope.of(
      context,
    ).localDatabase.getUnsyncedRecords();
    if (mounted)
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
  }

  Future<void> _deleteRecord(LocalPatientEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Eliminar el registro local de ${entry.patientName}? '
          'Si no ha sido sincronizado, se perderán los datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AppScope.of(context).localDatabase.deleteRecord(entry.patientId);
      _load();
    }
  }

  void _reviewRecord(LocalPatientEntry entry) {
    final record = entry.toPatientRecord();
    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los datos del registro no están disponibles.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReviewSummaryScreen(
          patient: record,
          createdAt: entry.createdAt,
          syncError: entry.syncError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header ──
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
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
                      ),
                      const SizedBox(width: 8),
                      const HwbLogo(size: 28, onDark: true),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Pendientes por sincronizar',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Info banner ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Los registros se sincronizan automáticamente cuando '
                            'se detecta conexión a internet. No se requiere acción manual.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Content ──
                Expanded(child: _buildContent()),
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_done,
              size: 80,
              color: AppColors.success.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Todo sincronizado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No hay registros pendientes por enviar.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
        itemCount: _entries.length,
        itemBuilder: (_, i) => _QueueCard(
          entry: _entries[i],
          onReview: () => _reviewRecord(_entries[i]),
          onDelete: () => _deleteRecord(_entries[i]),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Queue card — one per pending record
// ═════════════════════════════════════════════════════════════════════════════

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.entry,
    required this.onReview,
    required this.onDelete,
  });

  final LocalPatientEntry entry;
  final VoidCallback onReview;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasError = entry.syncError != null && entry.syncError!.isNotEmpty;
    final dateStr = entry.createdAt.contains('T')
        ? entry.createdAt.split('T').first
        : entry.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: hasError
            ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _initials(entry.patientName),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.patientName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Creado: $dateStr',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: hasError
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasError
                            ? Icons.error_outline
                            : Icons.cloud_upload_outlined,
                        size: 12,
                        color: hasError
                            ? AppColors.error
                            : const Color(0xFFB8800F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasError ? 'Error' : 'En cola',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: hasError
                              ? AppColors.error
                              : const Color(0xFFB8800F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (hasError)
            Padding(
              padding: const EdgeInsets.fromLTRB(64, 6, 14, 0),
              child: Text(
                entry.syncError!,
                style: const TextStyle(fontSize: 11, color: AppColors.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 10),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                // "Ver resumen" button
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: onReview,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'Ver resumen',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Delete button
                SizedBox(
                  height: 36,
                  width: 36,
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Review summary — read-only view of the patient record (like Step 5)
// ═════════════════════════════════════════════════════════════════════════════

class _ReviewSummaryScreen extends StatelessWidget {
  const _ReviewSummaryScreen({
    required this.patient,
    required this.createdAt,
    this.syncError,
  });

  final PatientFullRecord patient;
  final String createdAt;
  final String? syncError;

  @override
  Widget build(BuildContext context) {
    final p = patient.patientInfo;
    final g = patient.guardianInfo;
    final bg = patient.backgroundHistory;
    final dateStr = createdAt.contains('T')
        ? createdAt.split('T').first
        : createdAt;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
              child: Row(
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
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
                  ),
                  const SizedBox(width: 8),
                  const HwbLogo(size: 28, onDark: true),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Resumen del registro',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                children: [
                  // Status pill
                  Row(
                    children: [
                      Icon(
                        syncError != null
                            ? Icons.error_outline
                            : Icons.cloud_upload_outlined,
                        size: 16,
                        color: syncError != null
                            ? AppColors.error
                            : const Color(0xFFB8800F),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        syncError != null
                            ? 'Error de sincronización'
                            : 'Pendiente de sincronización',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: syncError != null
                              ? AppColors.error
                              : const Color(0xFFB8800F),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· $dateStr',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  if (syncError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        syncError!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Dispositivo NFC ──
                  _SummaryCard(
                    icon: Icons.nfc,
                    title: 'Dispositivo NFC',
                    rows: [MapEntry('UID', patient.deviceUid)],
                  ),
                  const SizedBox(height: 10),

                  // ── Paciente ──
                  _SummaryCard(
                    icon: Icons.person_outline,
                    title: 'Paciente',
                    rows: [
                      MapEntry('Nombre', p.fullName),
                      MapEntry(
                        'Documento',
                        '${p.identification.documentType} ${p.identification.documentNumber}',
                      ),
                      MapEntry('F. nacimiento', p.dob),
                      MapEntry('Sexo', _sexLabel(p.biologicalSex)),
                      MapEntry(
                        'Nacionalidad',
                        p.nationalityName ?? p.nationalityCode,
                      ),
                      if (p.bloodType != null) MapEntry('Sangre', p.bloodType!),
                      MapEntry(
                        'Dirección',
                        [
                          p.address.street,
                          p.address.city,
                          p.address.state,
                          p.address.zone == 'R' ? 'Rural' : 'Urbana',
                        ].where((s) => s != null && s.isNotEmpty).join(', '),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Guardián ──
                  _SummaryCard(
                    icon: Icons.family_restroom,
                    title: 'Guardián',
                    rows: (g == null || g.name.isEmpty)
                        ? [const MapEntry('—', 'Sin guardián')]
                        : [
                            MapEntry('Nombre', g.name),
                            MapEntry('Parentesco', _relLabel(g.relationship)),
                            MapEntry('Teléfono', g.phone ?? '—'),
                            MapEntry('NFC', g.deviceUid ?? 'No registrada'),
                          ],
                  ),
                  const SizedBox(height: 10),

                  // ── Antecedentes ──
                  _SummaryCard(
                    icon: Icons.history_edu_outlined,
                    title: 'Antecedentes',
                    rows: [
                      MapEntry('Crónicas', bg?.chronicConditions ?? '—'),
                      MapEntry('Personal', bg?.personalHistory ?? '—'),
                      MapEntry(
                        'Familiares',
                        bg == null || bg.familyHistory.isEmpty
                            ? '—'
                            : '${bg.familyHistory.length} ítems',
                      ),
                      MapEntry(
                        'Alergias',
                        patient.allergies.isEmpty
                            ? '—'
                            : '${patient.allergies.length} ítems',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Consultas ──
                  if (patient.medicalHistory.isNotEmpty)
                    _SummaryCard(
                      icon: Icons.medical_services_outlined,
                      title: 'Consultas',
                      rows: [
                        MapEntry('Total', '${patient.medicalHistory.length}'),
                        for (final c in patient.medicalHistory)
                          MapEntry(
                            c.startDateTime.contains('T')
                                ? c.startDateTime.split('T').first
                                : c.startDateTime,
                            c.clinicalEvaluation.historyOfCurrentIllness ?? '—',
                          ),
                      ],
                    ),
                  if (patient.medicalHistory.isNotEmpty)
                    const SizedBox(height: 10),

                  // ── Vacunas ──
                  if (patient.vaccinationRecord.isNotEmpty)
                    _SummaryCard(
                      icon: Icons.vaccines_outlined,
                      title: 'Vacunas',
                      rows: [
                        MapEntry(
                          'Total',
                          '${patient.vaccinationRecord.length}',
                        ),
                        for (final v in patient.vaccinationRecord)
                          MapEntry(
                            v.vaccineName,
                            'Dosis ${v.dose} · ${v.date}',
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _sexLabel(String c) {
    switch (c) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Femenino';
      default:
        return 'Indeterminado';
    }
  }

  static String _relLabel(String c) {
    switch (c) {
      case '01':
        return 'Padres';
      case '02':
        return 'Hermanos';
      case '03':
        return 'Tíos';
      case '04':
        return 'Abuelos';
      default:
        return c;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.rows,
  });
  final IconData icon;
  final String title;
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (kv) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      kv.key,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      kv.value.isEmpty ? '—' : kv.value,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
