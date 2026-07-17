import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'shared_read_nfc_header.dart';

class EditGuardianScreen extends StatefulWidget {
  const EditGuardianScreen({super.key, required this.patient});
  final PatientFullRecord patient;
  @override
  State<EditGuardianScreen> createState() => _EditGuardianScreenState();
}

class _EditGuardianScreenState extends State<EditGuardianScreen> {
  late final TextEditingController _nameCtrl,
      _docNumberCtrl,
      _addressCtrl,
      _contactCtrl;
  String _docType = 'CC';
  String _country = 'COL';

  @override
  void initState() {
    super.initState();
    final g = widget.patient.guardianInfo;
    _nameCtrl = TextEditingController(text: g.name);
    _docNumberCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _contactCtrl = TextEditingController(text: g.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _docNumberCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    const docTypes = {
      'CC': 'Cédula de Ciudadanía',
      'PA': 'Pasaporte',
      'CE': 'Cédula Extranjería',
    };
    const countries = {'COL': 'Colombia', 'VEN': 'Venezuela'};
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SharedReadNfcHeader(
                  title: s.editUpdate,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.guardianSection,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _tf(s.name, _nameCtrl, icon: Icons.person),
                        const SizedBox(height: 14),
                        _dd(s.documentType, _docType, docTypes, (v) {
                          if (v != null) setState(() => _docType = v);
                        }),
                        const SizedBox(height: 14),
                        _tf(
                          s.documentNumber,
                          _docNumberCtrl,
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 14),
                        _dd(s.nationality, _country, countries, (v) {
                          if (v != null) setState(() => _country = v);
                        }),
                        const SizedBox(height: 14),
                        _tf(s.address, _addressCtrl, icon: Icons.location_on),
                        const SizedBox(height: 14),
                        _tf(s.guardianPhone, _contactCtrl, icon: Icons.call),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF666666),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    size: 14,
                                    color: AppColors.white,
                                  ),
                                  label: Text(
                                    s.back,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00A396),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.save,
                                    size: 18,
                                    color: AppColors.white,
                                  ),
                                  label: Text(
                                    s.save,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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

  Widget _tf(String label, TextEditingController c, {IconData? icon}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 4),
      TextField(
        controller: c,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: AppColors.secondary)
              : null,
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );

  Widget _dd(
    String label,
    String val,
    Map<String, String> opts,
    ValueChanged<String?> cb,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: val,
            items: opts.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: cb,
          ),
        ),
      ),
    ],
  );
}
