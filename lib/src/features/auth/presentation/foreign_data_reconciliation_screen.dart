// lib/src/features/auth/presentation/foreign_data_reconciliation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../core/storage/local_database.dart';
import '../data/auth_repository.dart';

class ForeignDataReconciliationScreen extends StatefulWidget {
  const ForeignDataReconciliationScreen({
    super.key,
    required this.authRepository,
    required this.exception,
  });

  final AuthRepository authRepository;
  final ForeignPendingDataException exception;

  @override
  State<ForeignDataReconciliationScreen> createState() =>
      _ForeignDataReconciliationScreenState();
}

class _ForeignDataReconciliationScreenState
    extends State<ForeignDataReconciliationScreen> {
  bool _isWorking = false;

  Future<void> _openExportReview() async {
    setState(() => _isWorking = true);
    try {
      final records = await widget.authRepository
          .pendingForeignRecordsForReview();
      final logs = await widget.authRepository
          .pendingForeignEmergencyLogsForReview();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              _PendingDataExportScreen(records: records, logs: logs),
        ),
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _confirmDiscard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          '¿Descartar los datos pendientes?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Esto borra permanentemente ${widget.exception.pendingPatients} '
          'registro(s) de paciente y ${widget.exception.pendingEmergencyLogs} '
          'acceso(s) de emergencia que aún no se han sincronizado con el '
          'servidor. Esta acción no se puede deshacer.\n\n'
          'Usa "Exportar / revisar" primero si necesitas conservar esta '
          'información.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Sí, descartar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isWorking = true);
    try {
      await widget.authRepository.discardForeignPendingData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Datos anteriores descartados. Ya puedes iniciar sesión.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exception;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Datos pendientes de otro usuario'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: AbsorbPointer(
        absorbing: _isWorking,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  'Este dispositivo aún tiene datos sin sincronizar de otra '
                  'cuenta (usuario ${e.previousOwnerUserId}):',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _Stat(label: 'Pacientes pendientes', value: e.pendingPatients),
                _Stat(
                  label: 'Accesos de emergencia pendientes',
                  value: e.pendingEmergencyLogs,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No puedes continuar como un usuario distinto hasta '
                  'resolver esto, para que esta información no se mezcle ni '
                  'se envíe al servidor bajo la identidad equivocada.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                _ActionButton(
                  icon: Icons.login,
                  label: 'Volver e iniciar sesión como el usuario anterior',
                  subtitle:
                      'Recomendado: esa cuenta podrá sincronizar y liberar '
                      'estos datos con normalidad.',
                  onPressed: _isWorking
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.file_download_outlined,
                  label: 'Exportar / revisar antes de decidir',
                  subtitle: 'Ver el detalle y copiarlo como texto.',
                  onPressed: _isWorking ? null : _openExportReview,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.delete_forever_outlined,
                  label: 'Descartar y continuar como usuario nuevo',
                  subtitle: 'Borra permanentemente los datos pendientes.',
                  destructive: true,
                  onPressed: _isWorking ? null : _confirmDiscard,
                ),
                if (_isWorking) ...[
                  const SizedBox(height: 20),
                  const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red.shade700 : AppColors.primary;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(14),
        alignment: Alignment.centerLeft,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }
}

// ── Export / review screen ──────────────────────────────────────────────────

class _PendingDataExportScreen extends StatelessWidget {
  const _PendingDataExportScreen({required this.records, required this.logs});

  final List<LocalPatientEntry> records;
  final List<Map<String, Object?>> logs;

  String _asText() {
    final buffer = StringBuffer();
    buffer.writeln('=== Pacientes pendientes (${records.length}) ===');
    for (final r in records) {
      buffer.writeln(
        '- ${r.patientId} | ${r.maskedName} | creado ${r.createdAt} | '
        'revisión ${r.revision} | dueño: ${r.ownerUserId ?? "(sin dueño)"}',
      );
    }
    buffer.writeln();
    buffer.writeln('=== Accesos de emergencia pendientes (${logs.length}) ===');
    for (final l in logs) {
      buffer.writeln(
        '- id ${l['id']} | paciente ${l['patient_uid']} | '
        'motivo ${l['reason']} | ocurrió ${l['occurred_at']} | '
        'dueño: ${l['owner_user_id'] ?? "(sin dueño)"}',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final text = _asText();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisión de datos pendientes'),
        actions: [
          IconButton(
            tooltip: 'Copiar como texto',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copiado al portapapeles.')),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Este listado identifica pacientes (PHI). Trátalo según '
                  'las políticas de manejo de datos de tu organización '
                  'antes de descartarlo.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    text,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
