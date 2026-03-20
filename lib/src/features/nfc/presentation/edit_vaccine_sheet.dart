import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/tokens/app_colors.dart';
import '../domain/catalog_data.dart';

class EditVaccineSheet extends StatefulWidget {
  const EditVaccineSheet({
    super.key,
    this.initialVaccine,
    this.initialDose,
    this.initialDate,
    this.initialAdministeredBy,
    this.initialAdministeredAt,
  });

  final String? initialVaccine;
  final String? initialDose;
  final String? initialDate;
  final String? initialAdministeredBy;
  final String? initialAdministeredAt;

  @override
  State<EditVaccineSheet> createState() => _EditVaccineSheetState();
}

class _EditVaccineSheetState extends State<EditVaccineSheet> {
  late final TextEditingController _doseCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _byCtrl;
  late final TextEditingController _atCtrl;

  List<VaccineCatalogItem> _vaccines = [];
  String? _selectedVaccine;
  bool _loadingCatalogs = true;

  @override
  void initState() {
    super.initState();
    _selectedVaccine = widget.initialVaccine;
    _doseCtrl = TextEditingController(text: widget.initialDose);
    _dateCtrl = TextEditingController(text: widget.initialDate);
    _byCtrl = TextEditingController(text: widget.initialAdministeredBy);
    _atCtrl = TextEditingController(text: widget.initialAdministeredAt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingCatalogs) _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    try {
      final catalog = await AppScope.of(context).catalogRepository.getCatalogs();
      if (mounted) {
        setState(() {
          _vaccines = catalog.vaccines.where((v) => v.isActive).toList();
          _loadingCatalogs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCatalogs = false);
    }
  }

  @override
  void dispose() {
    _doseCtrl.dispose();
    _dateCtrl.dispose();
    _byCtrl.dispose();
    _atCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Edit vaccine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 18),
            _buildVaccineDropdown(),
            const SizedBox(height: 14),
            _buildField('Dose *', _doseCtrl),
            const SizedBox(height: 14),
            _buildField('Date *', _dateCtrl,
                prefixIcon: Icons.calendar_today),
            const SizedBox(height: 14),
            _buildField('Administrated By *', _byCtrl),
            const SizedBox(height: 14),
            _buildField('Administrated At *', _atCtrl),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.save,
                          size: 18, color: AppColors.white),
                      label: const Text(
                        'Save',
                        style:
                            TextStyle(color: AppColors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A396),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style:
                            TextStyle(color: AppColors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vaccine *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        _loadingCatalogs
            ? const SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedVaccine,
                    hint: const Text('Select a vaccine',
                        style: TextStyle(fontSize: 14)),
                    items: _vaccines
                        .map((VaccineCatalogItem v) => DropdownMenuItem(
                              value: v.name,
                              child: Text(v.name,
                                  style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (String? v) {
                      if (v != null) setState(() => _selectedVaccine = v);
                    },
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon:
                prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
        ),
      ],
    );
  }
}
