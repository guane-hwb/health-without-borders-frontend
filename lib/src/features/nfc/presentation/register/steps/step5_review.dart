// lib/src/features/nfc/presentation/register/steps/step5_review.dart
import 'package:flutter/material.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../register_nfc_screen.dart';
import '../../../../../core/i18n/app_strings.dart';

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

  String _formatDob(DateTime? dob, bool isEs) {
    if (dob == null) return '—';

    if (isEs) {
      const mEs = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      return '${dob.day} de ${mEs[dob.month - 1]} de ${dob.year}';
    } else {
      const mEn = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${mEn[dob.month - 1]} ${dob.day}, ${dob.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';

    final name = [
      d.firstName,
      d.secondName,
      d.firstLastName,
      d.secondLastName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    // ── Local variable mappings resolved via AppStrings ───────────────────
    final sexLabel =
        {
          'M': s.sexMale,
          'F': s.sexFemale,
          'I': s.sexIndeterminate,
        }[d.biologicalSex] ??
        d.biologicalSex;

    final zoneLabel = d.zone == '02' ? s.zoneRural : s.zoneUrban;

    final guardianRelationshipLabel =
        const {
          '01': 'Padres',
          '02': 'Hermanos',
          '03': 'Tíos',
          '04': 'Abuelos',
        }[d.guardianRelationship ?? '01'] ??
        '';

    final guardianRelationshipLabelEn =
        const {
          '01': 'Parents',
          '02': 'Siblings',
          '03': 'Uncles',
          '04': 'Grandparents',
        }[d.guardianRelationship ?? '01'] ??
        '';

    // Text items counter string builder helper
    String itemsCount(int count) {
      if (count == 0) return '—';
      return isEs ? '$count ítems' : '$count items';
    }

    final bannerText = isEs
        ? 'El registro se guarda en el dispositivo. Si hay internet se sincroniza ahora; si no, queda en la cola y se enviará automáticamente.'
        : 'The record is saved on the device. If internet is available, it syncs now; otherwise, it remains in the queue and will be sent automatically.';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              Text(
                s.reviewData,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEs
                    ? 'Verifica la información antes de guardar. Si algo está incorrecto, vuelve atrás.'
                    : 'Verify the information before saving. If anything is incorrect, go back.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              _Card(
                icon: Icons.nfc,
                title: isEs ? 'Dispositivo NFC' : 'NFC Device',
                rows: [_kv('UID', d.deviceUid ?? '—')],
              ),
              const SizedBox(height: 10),
              _Card(
                icon: Icons.person_outline,
                title: s.patient,
                rows: [
                  _kv(isEs ? 'Nombre' : 'Name', name),
                  _kv(
                    s.identification,
                    '${d.documentType} ${d.documentNumber}',
                  ),
                  _kv(
                    isEs ? 'F. nacimiento' : 'D.O.B.',
                    _formatDob(d.dob, isEs),
                  ),
                  _kv(isEs ? 'Sexo' : 'Sex', sexLabel),
                  _kv(s.nationality, d.nationalityName ?? d.nationalityCode),
                  if (d.bloodType != null) _kv(s.bloodType, d.bloodType!),
                  _kv(
                    s.address,
                    [
                      d.street,
                      d.addressCity,
                      d.addressState,
                      zoneLabel,
                    ].where((s) => s != null && s.isNotEmpty).join(', '),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Card(
                icon: Icons.family_restroom,
                title: s.guardian,
                rows: d.guardianName == null || d.guardianName!.isEmpty
                    ? [_kv('—', isEs ? 'Sin guardián' : 'No guardian')]
                    : [
                        _kv(isEs ? 'Nombre' : 'Name', d.guardianName!),
                        _kv(
                          s.guardianRelationship,
                          isEs
                              ? guardianRelationshipLabel
                              : guardianRelationshipLabelEn,
                        ),
                        _kv(
                          isEs ? 'Teléfono' : 'Phone',
                          d.guardianPhone ?? '—',
                        ),
                        _kv(
                          'NFC',
                          d.guardianDeviceUid ??
                              (isEs ? 'No registrada' : 'Not registered'),
                        ),
                      ],
              ),
              const SizedBox(height: 10),
              _Card(
                icon: Icons.history_edu_outlined,
                title: s.backgroundHistory,
                rows: [
                  _kv(
                    isEs ? 'Crónicas' : 'Chronic',
                    itemsCount(d.chronicConditions.length),
                  ),
                  _kv(isEs ? 'Personal' : 'Personal', d.personalHistory ?? '—'),
                  _kv(
                    isEs ? 'Medicam.' : 'Medication',
                    itemsCount(d.medications.length),
                  ),
                  _kv(
                    isEs ? 'Fam.' : 'Family',
                    itemsCount(d.familyHistory.length),
                  ),
                  _kv(s.allergiesSheetTitle, itemsCount(d.allergies.length)),
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 16,
                      color: Color(0xFF8B6914),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bannerText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8B6914),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                    label: Text(
                      s.back,
                      style: const TextStyle(
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
                      _saving ? s.saving : (isEs ? 'Confirmar' : 'Confirm'),
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
