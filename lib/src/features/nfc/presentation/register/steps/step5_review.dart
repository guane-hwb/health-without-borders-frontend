// lib/src/features/nfc/presentation/register/steps/step5_review.dart
import 'package:flutter/material.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../register_nfc_screen.dart';

class Step5Review extends StatefulWidget {
  const Step5Review({
    super.key,
    required this.draft,
    required this.onBack,
    required this.onConfirm,
  });
  final RegisterDraft draft;
  final VoidCallback onBack;
  final Future<void> Function() onConfirm;
  @override
  State<Step5Review> createState() => _Step5State();
}

class _Step5State extends State<Step5Review> {
  bool _saving = false;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      await widget.onConfirm();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final name = [
      d.firstName,
      d.secondName,
      d.firstLastName,
      d.secondLastName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              const Text(
                'Revisa los datos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Verifica la información antes de guardar. Si algo está incorrecto, vuelve atrás.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              _Card(
                icon: Icons.nfc,
                title: 'Dispositivo NFC',
                rows: [_kv('UID', d.deviceUid ?? '—')],
              ),
              const SizedBox(height: 10),
              _Card(
                icon: Icons.person_outline,
                title: 'Paciente',
                rows: [
                  _kv('Nombre', name),
                  _kv('Documento', '${d.documentType} ${d.documentNumber}'),
                  _kv(
                    'F. nacimiento',
                    d.dob == null
                        ? '—'
                        : '${d.dob!.year}-${d.dob!.month.toString().padLeft(2, '0')}-${d.dob!.day.toString().padLeft(2, '0')}',
                  ),
                  _kv(
                    'Sexo',
                    {
                          'M': 'Masculino',
                          'F': 'Femenino',
                          'I': 'Indeterminado',
                        }[d.biologicalSex] ??
                        d.biologicalSex,
                  ),
                  _kv('Nacionalidad', d.nationalityName ?? d.nationalityCode),
                  if (d.bloodType != null) _kv('Sangre', d.bloodType!),
                  _kv(
                    'Dirección',
                    [
                      d.street,
                      d.addressCity,
                      d.addressState,
                      d.zone == 'R' ? 'Rural' : 'Urbana',
                    ].where((s) => s != null && s.isNotEmpty).join(', '),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Card(
                icon: Icons.family_restroom,
                title: 'Guardián',
                rows: d.guardianName == null || d.guardianName!.isEmpty
                    ? [_kv('—', 'Sin guardián')]
                    : [
                        _kv('Nombre', d.guardianName!),
                        _kv(
                          'Parentesco',
                          const {
                                '01': 'Padres',
                                '02': 'Hermanos',
                                '03': 'Tíos',
                                '04': 'Abuelos',
                              }[d.guardianRelationship ?? '01'] ??
                              '',
                        ),
                        _kv('Teléfono', d.guardianPhone ?? '—'),
                        _kv('NFC', d.guardianDeviceUid ?? 'No registrada'),
                      ],
              ),
              const SizedBox(height: 10),
              _Card(
                icon: Icons.history_edu_outlined,
                title: 'Antecedentes',
                rows: [
                  _kv('Crónicas', d.chronicConditions ?? '—'),
                  _kv('Personal', d.personalHistory ?? '—'),
                  _kv(
                    'Fam.',
                    d.familyHistory.isEmpty
                        ? '—'
                        : '${d.familyHistory.length} ítems',
                  ),
                  _kv(
                    'Alergias',
                    d.allergies.isEmpty ? '—' : '${d.allergies.length} ítems',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD4A017),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 16,
                      color: Color(0xFF8B6914),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El registro se guarda en el dispositivo. Si hay internet se sincroniza ahora; si no, queda en la cola y se enviará automáticamente.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8B6914),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : widget.onBack,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    label: const Text(
                      'Atrás',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      disabledBackgroundColor: AppColors.disabled,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: AppColors.white,
                          ),
                    label: Text(
                      _saving ? 'Guardando...' : 'Registrar paciente',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static MapEntry<String, String> _kv(String k, String v) =>
      MapEntry(k, v.isEmpty ? '—' : v);
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.rows});
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
        border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
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
                      kv.value,
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
