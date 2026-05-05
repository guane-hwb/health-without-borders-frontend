// lib/src/features/nfc/presentation/profile/sheets/edit_guardian_sheet.dart
import 'package:flutter/material.dart';

import '../../../../../core/nfc/nfc_service.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';
import '../shared/sheet_scaffold.dart';

class EditGuardianSheet extends StatefulWidget {
  const EditGuardianSheet({
    super.key,
    required this.guardian,
    required this.onConfirm,
  });

  final GuardianInfo guardian;
  final ValueChanged<GuardianInfo> onConfirm;

  @override
  State<EditGuardianSheet> createState() => _EditGuardianSheetState();
}

class _EditGuardianSheetState extends State<EditGuardianSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _uidCtrl;
  late String _relationship;
  bool _scanning = false;

  static const Map<String, String> _relationships = {
    '01': 'Padres',
    '02': 'Hermanos',
    '03': 'Tíos',
    '04': 'Abuelos',
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.guardian.name);
    _phoneCtrl = TextEditingController(text: widget.guardian.phone);
    _uidCtrl = TextEditingController(text: widget.guardian.deviceUid ?? '');
    _relationship = widget.guardian.relationship;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _uidCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanGuardianNfc() async {
    setState(() => _scanning = true);
    try {
      final uid = await NfcService.readDeviceUid();
      if (mounted) {
        setState(() {
          _uidCtrl.text = uid;
          _scanning = false;
        });
      }
    } on NfcNotAvailableException {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NFC no disponible. Ingrese el UID manualmente.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Editar guardián',
      onConfirm: () {
        widget.onConfirm(
          GuardianInfo(
            name: _nameCtrl.text.trim(),
            relationship: _relationship,
            phone: _phoneCtrl.text.trim(),
            deviceUid: _uidCtrl.text.trim().isEmpty
                ? null
                : _uidCtrl.text.trim(),
          ),
        );
        Navigator.of(context).pop();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Nombre completo'),
          _input(
            _nameCtrl,
            hint: 'ej: Carmen Vargas Pinto',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          _label('Parentesco'),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _relationships.entries.map((e) {
              final sel = _relationship == e.key;
              return GestureDetector(
                onTap: () => setState(() => _relationship = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sel ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _label('Teléfono'),
          _input(
            _phoneCtrl,
            hint: 'ej: +57 310 482 9914',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _label('Dispositivo NFC del guardián'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _uidCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'UID del dispositivo NFC',
                    prefixIcon: Icon(
                      Icons.family_restroom,
                      size: 18,
                      color: _uidCtrl.text.trim().isNotEmpty
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _scanning ? null : _scanGuardianNfc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.disabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: _scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.nfc, size: 22, color: AppColors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _input(
    TextEditingController c, {
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) => TextField(
    controller: c,
    keyboardType: keyboard,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      isDense: true,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}
