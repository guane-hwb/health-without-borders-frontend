// lib/src/features/nfc/presentation/loss_of_wristband_screen.dart
import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import 'profile/patient_profile_screen.dart';
import 'shared_read_nfc_header.dart';

class LossOfWristbandScreen extends StatefulWidget {
  const LossOfWristbandScreen({super.key});

  @override
  State<LossOfWristbandScreen> createState() => _LossOfWristbandScreenState();
}

class _LossOfWristbandScreenState extends State<LossOfWristbandScreen> {
  String _docType = 'TI';
  final _docCtrl = TextEditingController();
  final _fnCtrl = TextEditingController();
  final _lnCtrl = TextEditingController();
  final _gnCtrl = TextEditingController();
  DateTime? _dob;
  bool _searching = false;
  String? _error;

  // Common Colombian document types from the patient registration screen
  static const Map<String, String> _docTypes = {
    'TI': 'TI',
    'CC': 'CC',
    'RC': 'RC',
    'CE': 'CE',
    'PA': 'PA',
    'PE': 'PE',
    'PT': 'PT',
    'MS': 'MS',
    'AS': 'AS',
  };

  static const Map<String, String> _docTypeFullNames = {
    'TI': 'Tarjeta de Identidad',
    'CC': 'Cédula de Ciudadanía',
    'RC': 'Registro Civil',
    'CE': 'Cédula de Extranjería',
    'PA': 'Pasaporte',
    'PE': 'Permiso Especial',
    'PT': 'Permiso por Protección',
    'MS': 'Menor sin ID',
    'AS': 'Adulto sin ID',
  };

  @override
  void dispose() {
    _docCtrl.dispose();
    _fnCtrl.dispose();
    _lnCtrl.dispose();
    _gnCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 5),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _search() async {
    final s = AppStrings.of(context);
    if (_docCtrl.text.trim().isEmpty ||
        _dob == null ||
        _fnCtrl.text.trim().isEmpty ||
        _lnCtrl.text.trim().isEmpty) {
      setState(() => _error = s.searchFieldsRequired);
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final patient = await AppScope.of(context).patientRepository
          .searchPatient(
            documentNumber: _docCtrl.text.trim(),
            birthDate: _formatDate(_dob!),
            firstName: _fnCtrl.text.trim(),
            lastName: _lnCtrl.text.trim(),
            guardianName: _gnCtrl.text.trim().isEmpty
                ? null
                : _gnCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PatientProfileScreen(patient: patient),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.statusCode == 404
            ? AppStrings.of(context).searchNoMatch
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SharedReadNfcHeader(
                  title: s.searchPatientTitle,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.searchSubtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Privacy banner ──────────────────────
                        _PrivacyBanner(message: s.searchPrivacyNotice),
                        const SizedBox(height: 18),

                        // ── Document type + number ───────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: _DocTypeDropdown(
                                value: _docType,
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _docType = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _LabeledField(
                                label: s.documentNumberLabel,
                                hint: 'Ej. 1098765432',
                                controller: _docCtrl,
                                requiredField: true,
                                helper: s.minThreeChars,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── First name ─────────────────────────
                        _LabeledField(
                          label: s.firstNameLabel,
                          controller: _fnCtrl,
                          requiredField: true,
                        ),
                        const SizedBox(height: 14),

                        // ── Last name ──────────────────────────
                        _LabeledField(
                          label: s.lastNameLabel,
                          hint: s.firstOrSecondLastName,
                          controller: _lnCtrl,
                          requiredField: true,
                        ),
                        const SizedBox(height: 14),

                        // ── DOB ────────────────────────────────
                        _DateField(
                          label: s.dobLabel,
                          requiredField: true,
                          value: _dob == null ? '' : _formatDate(_dob!),
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 14),

                        // ── Guardian name (optional) ───────────
                        _LabeledField(
                          label: s.guardianNameOptionalLabel,
                          hint: 'Ej. Carmen Vargas Pinto',
                          controller: _gnCtrl,
                          helper: s.guardianHelper,
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        // ── Search button ──────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _searching ? null : _search,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.disabled,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: _searching
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.search,
                                    color: AppColors.white,
                                    size: 22,
                                  ),
                            label: Text(
                              s.searchPatientButton,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            s.searchFooterNote,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
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
}

// ── Doc type dropdown ──────────────────────────────────────────────────────

class _DocTypeDropdown extends StatelessWidget {
  const _DocTypeDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.documentTypeLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE3E5EA)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.textSecondary,
              ),
              items: _LossOfWristbandScreenState._docTypes.entries.map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Labeled field ──────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.requiredField = false,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final String? hint;
  final String? helper;
  final TextEditingController controller;
  final bool requiredField;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            if (requiredField) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.disabled),
            filled: true,
            fillColor: AppColors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE3E5EA),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Date field ──────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.requiredField = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            if (requiredField) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE3E5EA)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? 'YYYY-MM-DD' : value,
                    style: TextStyle(
                      fontSize: 14,
                      color: value.isEmpty
                          ? AppColors.disabled
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Privacy banner ──────────────────────────────────────────────────────────

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.privacy_tip_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
