// lib/src/features/nfc/presentation/profile/sheets/edit_address_sheet.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';
import '../shared/sheet_scaffold.dart';

class EditAddressSheet extends StatefulWidget {
  const EditAddressSheet({
    super.key,
    required this.address,
    required this.onConfirm,
  });

  final Address address;
  final ValueChanged<Address> onConfirm;

  @override
  State<EditAddressSheet> createState() => _EditAddressSheetState();
}

class _EditAddressSheetState extends State<EditAddressSheet> {
  late TextEditingController _streetCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late String _zone;

  @override
  void initState() {
    super.initState();
    _streetCtrl = TextEditingController(text: widget.address.street ?? '');
    _cityCtrl = TextEditingController(text: widget.address.city);
    _stateCtrl = TextEditingController(text: widget.address.state);
    _zone = widget.address.zone ?? 'U';
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Editar residencia',
      subtitle: 'Dirección y zona del paciente',
      onConfirm: () {
        widget.onConfirm(
          Address(
            street: _streetCtrl.text.trim().isEmpty
                ? null
                : _streetCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            cityCode: widget.address.cityCode,
            state: _stateCtrl.text.trim(),
            zipCode: widget.address.zipCode,
            country: widget.address.country,
            countryName: widget.address.countryName,
            zone: _zone,
          ),
        );
        Navigator.of(context).pop();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Dirección'),
          _input(
            _streetCtrl,
            hint: 'ej: Cra. 18 #27-43',
            icon: Icons.home_outlined,
          ),
          const SizedBox(height: 14),
          _label('Municipio'),
          _input(_cityCtrl, hint: 'ej: Riohacha', icon: Icons.location_city),
          const SizedBox(height: 14),
          _label('Departamento'),
          _input(_stateCtrl, hint: 'ej: La Guajira', icon: Icons.map_outlined),
          const SizedBox(height: 14),
          _label('Zona'),
          Row(
            children: [
              _ZoneChip(
                label: 'Urbana',
                selected: _zone == 'U',
                onTap: () => setState(() => _zone = 'U'),
              ),
              const SizedBox(width: 10),
              _ZoneChip(
                label: 'Rural',
                selected: _zone == 'R',
                onTap: () => setState(() => _zone = 'R'),
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
  }) => TextField(
    controller: c,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      isDense: true,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
