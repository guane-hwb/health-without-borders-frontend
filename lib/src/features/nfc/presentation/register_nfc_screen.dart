import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../domain/register_form_mapper.dart';
import '../domain/register_form_models.dart';

class RegisterNfcScreen extends StatefulWidget {
  const RegisterNfcScreen({super.key});

  @override
  State<RegisterNfcScreen> createState() => _RegisterNfcScreenState();
}

class _RegisterNfcScreenState extends State<RegisterNfcScreen> {
  bool _isSaving = false;

  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController(
    text: '2020-01-01',
  );
  final TextEditingController _countryController = TextEditingController(
    text: 'Select an option',
  );

  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _guardianRelationshipController =
      TextEditingController(text: 'Select an option');
  final TextEditingController _guardianAddressController =
      TextEditingController();
  final TextEditingController _guardianContactController =
      TextEditingController();

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _genderController = TextEditingController(
    text: 'Male',
  );
  final TextEditingController _bloodTypeController = TextEditingController(
    text: 'Select an option',
  );

  final TextEditingController _illnessController = TextEditingController();
  final TextEditingController _personalHistoryController =
      TextEditingController();
  final TextEditingController _familyHistoryController =
      TextEditingController();
  final TextEditingController _generalExamController = TextEditingController();
  final TextEditingController _systemsExamController = TextEditingController();

  final TextEditingController _medicalNameController = TextEditingController(
    text: 'Joe Doe',
  );
  final TextEditingController _medicalPlaceController = TextEditingController(
    text: 'CONSULTORIO 101',
  );
  final TextEditingController _medicalDateController = TextEditingController(
    text: '2026-02-05',
  );

  final List<VaccineEntry> _vaccines = <VaccineEntry>[
    VaccineEntry(
      vaccine: 'MMR',
      doses: '2',
      date: '2025-11-12',
      administratedBy: 'Nurse C.',
    ),
    VaccineEntry(
      vaccine: 'DTP',
      doses: '1',
      date: '2025-07-09',
      administratedBy: 'Nurse B.',
    ),
  ];

  final List<AllergenEntry> _allergens = <AllergenEntry>[
    AllergenEntry(
      allergen: 'Peanut',
      reaction: 'Rash',
      severity: 'Mild',
      notes: 'Monitor',
    ),
    AllergenEntry(
      allergen: 'Penicillin',
      reaction: 'Swelling',
      severity: 'High',
      notes: 'Avoid use',
    ),
  ];

  @override
  void dispose() {
    _patientNameController.dispose();
    _birthDateController.dispose();
    _countryController.dispose();
    _guardianNameController.dispose();
    _guardianRelationshipController.dispose();
    _guardianAddressController.dispose();
    _guardianContactController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _genderController.dispose();
    _bloodTypeController.dispose();
    _illnessController.dispose();
    _personalHistoryController.dispose();
    _familyHistoryController.dispose();
    _generalExamController.dispose();
    _systemsExamController.dispose();
    _medicalNameController.dispose();
    _medicalPlaceController.dispose();
    _medicalDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register NFC'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Patient'),
            const SizedBox(height: 10),
            _InputRow(
              label: 'Name',
              icon: Icons.person,
              controller: _patientNameController,
            ),
            const SizedBox(height: 8),
            _InputRow(
              label: 'Date Birthday',
              icon: Icons.calendar_month,
              controller: _birthDateController,
            ),
            const SizedBox(height: 8),
            _InputRow(
              label: 'Gender',
              controller: _genderController,
              trailingIcon: Icons.arrow_drop_down,
            ),
            const SizedBox(height: 8),
            _InputRow(
              label: 'Country',
              controller: _countryController,
              trailingIcon: Icons.arrow_drop_down,
            ),
            const SizedBox(height: 12),
            const _ActionButton(
              label: 'Register patient',
              background: AppColors.secondary,
              icon: Icons.nfc,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const _SectionTitle('Companion / Guardian'),
            const SizedBox(height: 10),
            _InputRow(
              label: 'Name',
              icon: Icons.person,
              controller: _guardianNameController,
            ),
            const SizedBox(height: 8),
            _InputRow(
              label: 'Relationship',
              controller: _guardianRelationshipController,
              trailingIcon: Icons.arrow_drop_down,
            ),
            const SizedBox(height: 8),
            _InputRow(
              label: 'Address',
              icon: Icons.location_on,
              controller: _guardianAddressController,
            ),
            const SizedBox(height: 8),
            _InputRow(
              label: 'Contact (Cellphone)',
              icon: Icons.call,
              controller: _guardianContactController,
            ),
            const SizedBox(height: 12),
            const _ActionButton(
              label: 'Register guardian',
              background: AppColors.disabled,
              icon: Icons.nfc,
              enabled: false,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const _SectionTitle('Physical information'),
            const SizedBox(height: 10),
            _InputRow(
              label: 'Weight',
              icon: Icons.monitor_weight,
              controller: _weightController,
            ),
            const SizedBox(height: 8),
            _InputRow(
              label: 'Height',
              icon: Icons.height,
              controller: _heightController,
            ),
            const SizedBox(height: 8),
            _InputRow(
              label: 'Gender',
              controller: _genderController,
              trailingIcon: Icons.arrow_drop_down,
            ),
            const SizedBox(height: 8),
            _InputRow(
              label: 'Blood Type',
              controller: _bloodTypeController,
              trailingIcon: Icons.arrow_drop_down,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const _SectionTitle('General'),
            const SizedBox(height: 10),
            _TextAreaWithCounter(
              label: 'History of current illness',
              controller: _illnessController,
            ),
            const SizedBox(height: 8),
            _TextAreaWithCounter(
              label: 'Personal History',
              controller: _personalHistoryController,
            ),
            const SizedBox(height: 8),
            _TextAreaWithCounter(
              label: 'Family History',
              controller: _familyHistoryController,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const _SectionTitle('Physical Examination'),
            const SizedBox(height: 10),
            _TextAreaWithCounter(
              label: 'General Physical Examination',
              controller: _generalExamController,
            ),
            const SizedBox(height: 8),
            _TextAreaWithCounter(
              label: 'Systems Examination',
              controller: _systemsExamController,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const _SectionTitle('Vaccine'),
            const SizedBox(height: 10),
            const _SimpleTableHeader(
              columns: <String>['Vaccine', 'Doses', 'Date', 'Administrated By'],
            ),
            ..._vaccines.map(
              (VaccineEntry row) => _SimpleTableRow(
                values: <String>[
                  row.vaccine,
                  row.doses,
                  row.date,
                  row.administratedBy,
                ],
              ),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Add Vaccine',
              background: AppColors.primary,
              icon: Icons.add,
              onPressed: _addVaccine,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const _SectionTitle('Allergen'),
            const SizedBox(height: 10),
            const _SimpleTableHeader(
              columns: <String>['Allergen', 'Reaction', 'Severity', 'Notes'],
            ),
            ..._allergens.map(
              (AllergenEntry row) => _SimpleTableRow(
                values: <String>[
                  row.allergen,
                  row.reaction,
                  row.severity,
                  row.notes,
                ],
              ),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Add Allergen',
              background: AppColors.primary,
              icon: Icons.add,
              onPressed: _addAllergen,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const _SectionTitle('Medical Staff'),
            const SizedBox(height: 10),
            _InputRow(label: 'Name', controller: _medicalNameController),
            const SizedBox(height: 8),
            _InputRow(label: 'Place', controller: _medicalPlaceController),
            const SizedBox(height: 8),
            _InputRow(label: 'Date', controller: _medicalDateController),
            const SizedBox(height: 8),
            _InputRow(
              label: 'Blood Type',
              controller: _bloodTypeController,
              trailingIcon: Icons.arrow_drop_down,
            ),
            const SizedBox(height: 16),
            _ActionButton(
              label: _isSaving ? 'Saving...' : 'Save',
              background: AppColors.secondary,
              icon: Icons.save,
              fullWidth: true,
              enabled: !_isSaving,
              onPressed: _saveDraft,
            ),
          ],
        ),
      ),
    );
  }

  RegisterNfcDraft _buildDraft() {
    return RegisterNfcDraft(
      deviceUid: 'device-ui-demo-001',
      firstName: _patientNameController.text,
      birthDate: _birthDateController.text,
      gender: _genderController.text,
      country: _countryController.text,
      guardianName: _guardianNameController.text,
      guardianRelationship: _guardianRelationshipController.text,
      guardianAddress: _guardianAddressController.text,
      guardianContact: _guardianContactController.text,
      weight: _weightController.text,
      height: _heightController.text,
      bloodType: _bloodTypeController.text,
      currentIllness: _illnessController.text,
      personalHistory: _personalHistoryController.text,
      familyHistory: _familyHistoryController.text,
      generalPhysicalExamination: _generalExamController.text,
      systemsExamination: _systemsExamController.text,
      medicalStaffName: _medicalNameController.text,
      medicalStaffPlace: _medicalPlaceController.text,
      medicalStaffDate: _medicalDateController.text,
      vaccines: List<VaccineEntry>.from(_vaccines),
      allergens: List<AllergenEntry>.from(_allergens),
    );
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    final RegisterNfcDraft draft = _buildDraft();
    final Map<String, dynamic> payload = buildPatientSyncPayload(draft);

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, dynamic> response = await AppScope.of(
        context,
      ).patientRepository.syncPatient(payload);
      if (!mounted) {
        return;
      }

      final String status = response['status']?.toString() ?? 'ok';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Sync success: $status',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Sync failed: ${error.message}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Sync failed due to unexpected error.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _addVaccine() {
    setState(() {
      _vaccines.add(
        VaccineEntry(
          vaccine: 'New vaccine',
          doses: '1',
          date: 'YYYY-MM-DD',
          administratedBy: 'Staff',
        ),
      );
    });
  }

  void _addAllergen() {
    setState(() {
      _allergens.add(
        AllergenEntry(
          allergen: 'New allergen',
          reaction: 'Reaction',
          severity: 'Low',
          notes: 'Notes',
        ),
      );
    });
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.label,
    required this.controller,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10),
        prefixIcon: icon != null
            ? Icon(icon, size: 14, color: AppColors.primary)
            : null,
        suffixIcon: trailingIcon != null
            ? Icon(trailingIcon, size: 18, color: AppColors.primary)
            : null,
      ),
    );
  }
}

class _TextAreaWithCounter extends StatefulWidget {
  const _TextAreaWithCounter({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  State<_TextAreaWithCounter> createState() => _TextAreaWithCounterState();
}

class _TextAreaWithCounterState extends State<_TextAreaWithCounter> {
  static const int _maxLength = 100;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuildOnTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuildOnTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
          minLines: 2,
          maxLines: 2,
          maxLength: _maxLength,
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            labelText: widget.label,
            labelStyle: const TextStyle(fontSize: 10),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${widget.controller.text.length}/$_maxLength',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _rebuildOnTextChange() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _SimpleTableHeader extends StatelessWidget {
  const _SimpleTableHeader({required this.columns});

  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navigationBackgroundLight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          for (final String item in columns)
            Expanded(
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _SimpleTableRow extends StatelessWidget {
  const _SimpleTableRow({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.divider),
          right: BorderSide(color: AppColors.divider),
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          for (final String value in values)
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.background,
    required this.icon,
    this.enabled = true,
    this.fullWidth = false,
    this.onPressed,
  });

  final String label;
  final Color background;
  final IconData icon;
  final bool enabled;
  final bool fullWidth;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? callback;
    if (!enabled) {
      callback = null;
    } else if (onPressed != null) {
      callback = onPressed;
    } else {
      callback = () {};
    }

    final Widget button = SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 28,
      child: ElevatedButton.icon(
        onPressed: callback,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? background : AppColors.disabled,
          disabledBackgroundColor: AppColors.disabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: fullWidth ? const Size.fromHeight(28) : null,
        ),
        icon: Icon(icon, size: 14, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );

    if (fullWidth) {
      return button;
    }

    return Align(alignment: Alignment.centerLeft, child: button);
  }
}
