// lib/src/shared/widgets/form_widgets.dart
import 'package:flutter/material.dart';
import '../../design/tokens/app_colors.dart';

class FormSectionHeader extends StatelessWidget {
  const FormSectionHeader({super.key, required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32, margin: const EdgeInsets.only(right: 10, top: 1),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
        ])),
      ]),
    );
  }
}

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({super.key, required this.label, required this.controller, this.hint, this.helper, this.prefixIcon, this.suffix, this.requiredField = false, this.keyboardType = TextInputType.text, this.maxLines = 1, this.onChanged});
  final String label; final String? hint; final String? helper; final TextEditingController controller;
  final IconData? prefixIcon; final Widget? suffix; final bool requiredField; final TextInputType keyboardType; final int maxLines; final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FieldLabel(label: label, required_: requiredField),
      const SizedBox(height: 5),
      TextField(
        controller: controller, keyboardType: keyboardType, maxLines: maxLines, onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint, counterText: '', hintStyle: const TextStyle(fontSize: 13, color: AppColors.disabled),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary) : null,
          suffixIcon: suffix, filled: true, fillColor: AppColors.white, isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE3E5EA), width: 1.2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
      if (helper != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(helper!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
    ]);
  }
}

class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({super.key, required this.label, required this.value, required this.items, required this.onChanged, this.requiredField = false});
  final String label; final T value; final Map<T, String> items; final ValueChanged<T?> onChanged; final bool requiredField;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FieldLabel(label: label, required_: requiredField),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE3E5EA), width: 1.2)),
        child: DropdownButtonHideUnderline(child: DropdownButton<T>(
          isExpanded: true, value: value, icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textSecondary),
          items: items.entries.map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 14)))).toList(), onChanged: onChanged,
        )),
      ),
    ]);
  }
}

class LabeledDateField extends StatelessWidget {
  const LabeledDateField({super.key, required this.label, required this.value, required this.onChanged, this.requiredField = false});
  final String label; final DateTime? value; final ValueChanged<DateTime> onChanged; final bool requiredField;
  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: value ?? DateTime(now.year - 5), firstDate: DateTime(1920), lastDate: now);
    if (picked != null) onChanged(picked);
  }
  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FieldLabel(label: label, required_: requiredField),
      const SizedBox(height: 5),
      InkWell(
        onTap: () => _pick(context), borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE3E5EA), width: 1.2)),
          child: Row(children: [
            Expanded(child: Text(value == null ? 'YYYY-MM-DD' : _fmt(value!), style: TextStyle(fontSize: 14, color: value == null ? AppColors.disabled : AppColors.textPrimary))),
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
          ]),
        ),
      ),
    ]);
  }
}

class ChipSelector<T> extends StatelessWidget {
  const ChipSelector({super.key, required this.label, required this.options, required this.value, required this.onChanged, this.requiredField = false, this.showLabel = true});
  final String label; final Map<T, String> options; final T value; final ValueChanged<T> onChanged; final bool requiredField; final bool showLabel;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showLabel) _FieldLabel(label: label, required_: requiredField),
      if (showLabel) const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: options.entries.map((e) {
        final sel = e.key == value;
        return GestureDetector(onTap: () => onChanged(e.key), child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE3E5EA))),
          child: Text(e.value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? AppColors.white : AppColors.textPrimary)),
        ));
      }).toList()),
    ]);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required bool required_}) : _required = required_;
  final String label; final bool _required;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Flexible(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.4))),
      if (_required) const Padding(padding: EdgeInsets.only(left: 4), child: Text('*', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w700))),
    ]);
  }
}
