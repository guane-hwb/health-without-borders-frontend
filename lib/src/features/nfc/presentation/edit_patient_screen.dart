// lib/src/features/nfc/presentation/edit_patient_screen.dart

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'shared_read_nfc_header.dart';

class EditPatientScreen extends StatefulWidget {
  const EditPatientScreen({super.key, required this.patient});
  final PatientFullRecord patient;
  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  late final String _fullName, _dob, _biologicalSex, _bloodType, _documentInfo;
  late final TextEditingController _weightCtrl,
      _heightCtrl,
      _streetCtrl,
      _cityCtrl,
      _stateCtrl;
  late String _nationalityCode;
  bool _isSaving = false;

  static const _nationCodes = {
    'COL': 'Colombia',
    'VEN': 'Venezuela',
    'ECU': 'Ecuador',
    'PER': 'Perú',
  };

  @override
  void initState() {
    super.initState();
    final info = widget.patient.patientInfo;
    _fullName = info.fullName;
    _dob = info.dob;
    _bloodType = info.bloodType ?? 'N/A';
    _documentInfo =
        '${info.identification.documentType} ${info.identification.documentNumber}';
    _weightCtrl = TextEditingController(text: info.weight?.toString() ?? '');
    _heightCtrl = TextEditingController(text: info.height?.toString() ?? '');
    _streetCtrl = TextEditingController(text: info.address.street ?? '');
    _cityCtrl = TextEditingController(text: info.address.city);
    _stateCtrl = TextEditingController(text: info.address.state);
    _nationalityCode = _nationCodes.containsKey(info.nationalityCode)
        ? info.nationalityCode
        : 'COL';
    _biologicalSex = info.biologicalSex;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  // fe-edit-patient-guardar-descarta: Implementación de guardado y persistencia
  Future<void> _save() async {
    setState(() => _isSaving = true);
    final s = AppStrings.of(context);
    final isEs = s.welcome == 'Bienvenido';

    final double? parsedWeight = double.tryParse(
      _weightCtrl.text.trim().replaceAll(',', '.'),
    );
    final double? parsedHeight = double.tryParse(
      _heightCtrl.text.trim().replaceAll(',', '.'),
    );

    final currentInfo = widget.patient.patientInfo;
    final updatedInfo = PatientInfo(
      identification: currentInfo.identification,
      firstName: currentInfo.firstName,
      secondName: currentInfo.secondName,
      firstLastName: currentInfo.firstLastName,
      secondLastName: currentInfo.secondLastName,
      dob: currentInfo.dob,
      nationalityCode: _nationalityCode,
      nationalityName: _nationCodes[_nationalityCode],
      biologicalSex: currentInfo.biologicalSex,
      genderIdentity: currentInfo.genderIdentity,
      ethnicity: currentInfo.ethnicity,
      ethnicCommunity: currentInfo.ethnicCommunity,
      disabilityCategory: currentInfo.disabilityCategory,
      address: Address(
        street: _streetCtrl.text.trim().isNotEmpty
            ? _streetCtrl.text.trim()
            : currentInfo.address.street,
        city: _cityCtrl.text.trim(),
        cityCode: currentInfo.address.cityCode,
        state: _stateCtrl.text.trim(),
        country: currentInfo.address.country,
        countryName: currentInfo.address.countryName,
        zone: currentInfo.address.zone,
      ),
      bloodType: currentInfo.bloodType,
      weight: parsedWeight,
      height: parsedHeight,
    );

    final updatedRecord = PatientFullRecord(
      patientId: widget.patient.patientId,
      deviceUid: widget.patient.deviceUid,
      patientInfo: updatedInfo,
      guardianInfo: widget.patient.guardianInfo,
      guardian2Info: widget.patient.guardian2Info,
      backgroundHistory: widget.patient.backgroundHistory,
      allergies: widget.patient.allergies,
      medicalHistory: widget.patient.medicalHistory,
      vaccinationRecord: widget.patient.vaccinationRecord,
    );

    try {
      final scope = AppScope.of(context);
      await scope.localDatabase.savePatient(updatedRecord);
      await scope.localDatabase.markChipsDirty(
        updatedRecord.patientId,
        guardian: true,
      );
      scope.syncEngine.syncAll().ignore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEs
                  ? 'Paciente actualizado exitosamente'
                  : 'Patient updated successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(updatedRecord);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEs
                  ? 'Error al guardar cambios: $e'
                  : 'Error saving changes: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final sexLabels = {'M': 'Masculino', 'F': 'Femenino', 'I': 'Indeterminado'};
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
                        _sec(s.patientInfoReadOnly),
                        const SizedBox(height: 4),
                        Text(
                          s.fieldsProtected,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ro(s.name, _fullName, Icons.person),
                        const SizedBox(height: 10),
                        _ro(s.documentNumber, _documentInfo, Icons.badge),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ro(
                                s.dateOfBirth,
                                _dob,
                                Icons.calendar_today,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ro(
                                s.gender,
                                sexLabels[_biologicalSex] ?? _biologicalSex,
                                Icons.wc,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _ro(s.bloodType, _bloodType, Icons.bloodtype),
                        const SizedBox(height: 20),
                        _sec(s.editableInfo),
                        const SizedBox(height: 12),
                        _dd(s.nationality, _nationalityCode, _nationCodes, (v) {
                          if (v != null) setState(() => _nationalityCode = v);
                        }),
                        const SizedBox(height: 12),
                        _tf(
                          s.weight,
                          _weightCtrl,
                          icon: Icons.monitor_weight,
                          keyboard: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _tf(
                          s.height,
                          _heightCtrl,
                          icon: Icons.open_in_full,
                          keyboard: TextInputType.number,
                        ),
                        const SizedBox(height: 20),
                        _sec(s.address),
                        const SizedBox(height: 12),
                        _tf(s.street, _streetCtrl, icon: Icons.location_on),
                        const SizedBox(height: 12),
                        _tf(s.city, _cityCtrl, icon: Icons.location_city),
                        const SizedBox(height: 12),
                        _tf(s.state, _stateCtrl, icon: Icons.map),
                        const SizedBox(height: 24),
                        _btns(context, s),
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

  Widget _sec(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    ),
  );
  Widget _ro(String label, String val, IconData icon) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.disabled),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                val,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.lock_outline, size: 14, color: AppColors.disabled),
          ],
        ),
      ),
    ],
  );
  Widget _tf(
    String label,
    TextEditingController c, {
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 4),
      TextField(
        controller: c,
        keyboardType: keyboard,
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

  Widget _btns(BuildContext context, AppStrings s) => Row(
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
              style: const TextStyle(color: AppColors.white, fontSize: 13),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A396),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.save, size: 18, color: AppColors.white),
            label: Text(
              s.save,
              style: const TextStyle(color: AppColors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    ],
  );
}
