// lib/src/features/nfc/presentation/loss_of_wristband_screen.dart
import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import 'profile/patient_profile_screen.dart';

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
    'TI': 'TI — Tarjeta de identidad',
    'CC': 'CC — Cédula de ciudadanía',
    'RC': 'RC — Registro civil',
    'CE': 'CE — Cédula de extranjería',
    'PA': 'PA — Pasaporte',
    'PE': 'PE — Permiso especial',
    'PT': 'PT — PPT',
    'MS': 'MS — Menor sin ID',
    'AS': 'AS — Adulto sin ID',
  };

  static const Map<String, String> _docTypesShort = {
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            surface: AppColors.white,
          ),
        ),
        child: child!,
      ),
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = s.searchError);
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
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.searchPatientTitle,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _LocaleSwitcher(),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.searchSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Privacy banner ──────────────────────
                        _PrivacyBanner(message: s.searchPrivacyNotice),
                        const SizedBox(height: 20),

                        // ── Document type + number ───────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: _DocTypeDropdown(
                                value: _docType,
                                docTypes: _docTypes,
                                docTypesShort: _docTypesShort,
                                onChanged: (v) {
                                  if (v != null) setState(() => _docType = v);
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
                                keyboardType: TextInputType.number,
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
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 14),

                        // ── Last name ──────────────────────────
                        _LabeledField(
                          label: s.lastNameLabel,
                          hint: s.firstOrSecondLastName,
                          controller: _lnCtrl,
                          requiredField: true,
                          textCapitalization: TextCapitalization.words,
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
                          textCapitalization: TextCapitalization.words,
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 20,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // ── Search button ──────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 50,
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
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.white,
                                    size: 22,
                                  ),
                            label: Text(
                              _searching
                                  ? 'Buscando...'
                                  : s.searchPatientButton,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Center(
                          child: Text(
                            s.searchFooterNote,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.5,
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

class _LocaleSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context).locale;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['es', 'en'].map((lang) {
          final selected = locale == lang;
          return GestureDetector(
            onTap: () => AppLocale.of(context).setLocale(lang),
            child: Container(
              margin: const EdgeInsets.only(left: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                lang.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Doc type dropdown ──────────────────────────────────────────────────────
class _DocTypeDropdown extends StatelessWidget {
  const _DocTypeDropdown({
    required this.value,
    required this.docTypes,
    required this.docTypesShort,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> docTypes;
  final Map<String, String> docTypesShort;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              Text(
                s.documentTypeLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFB0B8C4), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.textSecondary,
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              selectedItemBuilder: (_) => docTypesShort.entries.map((e) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              items: docTypes.entries.map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
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
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String? hint;
  final String? helper;
  final TextEditingController controller;
  final bool requiredField;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (requiredField) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
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
          textCapitalization: textCapitalization,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFB0B8C4),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 5),
          Text(
            helper!,
            style: const TextStyle(
              fontSize: 12,
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
    final hasValue = value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (requiredField) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasValue ? AppColors.primary : const Color(0xFFB0B8C4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value : 'YYYY-MM-DD',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: hasValue ? AppColors.primary : AppColors.textSecondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.privacy_tip_outlined,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
