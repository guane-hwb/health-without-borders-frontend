// lib/src/features/nfc/presentation/profile/sheets/edit_vital_signs_sheet.dart
import 'package:flutter/material.dart';

import '../../../../../design/tokens/app_colors.dart';
import '../shared/sheet_scaffold.dart';

class EditVitalSignsSheet extends StatefulWidget {
  const EditVitalSignsSheet({
    super.key,
    this.weight,
    this.height,
    this.previousWeight,
    this.previousHeight,
    required this.onConfirm,
  });

  final double? weight;
  final double? height;
  final double? previousWeight;
  final double? previousHeight;
  final void Function({double? weight, double? height}) onConfirm;

  @override
  State<EditVitalSignsSheet> createState() =>
      _EditVitalSignsSheetState();
}

class _EditVitalSignsSheetState extends State<EditVitalSignsSheet> {
  late double _weight;
  late double _height;

  @override
  void initState() {
    super.initState();
    _weight = widget.weight ?? 0;
    _height = widget.height ?? 0;
  }

  String _diff(double current, double? previous, String unit) {
    if (previous == null) return '';
    final delta = current - previous;
    if (delta == 0) return '';
    final sign = delta > 0 ? '+' : '';
    return ' $sign${delta.toStringAsFixed(unit == 'kg' ? 1 : 0)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Editar signos',
      subtitle: 'Última toma: ${_lastTaken()}',
      onConfirm: () {
        widget.onConfirm(weight: _weight, height: _height);
        Navigator.of(context).pop();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Weight ─────────────────────────────────
          const Text('PESO (KG)',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          _Stepper(
            value: _weight.toStringAsFixed(1),
            onMinus: () => setState(() {
              if (_weight > 0.5) _weight -= 0.5;
            }),
            onPlus: () => setState(() => _weight += 0.5),
          ),
          if (widget.previousWeight != null) ...[
            const SizedBox(height: 6),
            Text(
              'Anterior: ${widget.previousWeight!.toStringAsFixed(1)} kg'
              '${_diff(_weight, widget.previousWeight, 'kg')}',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary),
            ),
          ],

          const SizedBox(height: 22),

          // ── Height ─────────────────────────────────
          const Text('TALLA (CM)',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          _Stepper(
            value: _height.toStringAsFixed(0),
            onMinus: () => setState(() {
              if (_height > 1) _height -= 1;
            }),
            onPlus: () => setState(() => _height += 1),
          ),
          if (widget.previousHeight != null) ...[
            const SizedBox(height: 6),
            Text(
              'Anterior: ${widget.previousHeight!.toStringAsFixed(0)} cm'
              '${_diff(_height, widget.previousHeight, 'cm')}',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary),
            ),
          ],

          const SizedBox(height: 18),

          // ── Info block: blood type not editable ────
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'El tipo de sangre no se edita aquí — es un dato '
                    'biológico permanente. Para corregirlo, contacte al admin.',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _lastTaken() {
    final now = DateTime.now();
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _StepperBtn(icon: Icons.remove, onTap: onMinus),
          Expanded(
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
            ),
          ),
          _StepperBtn(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Icon(icon, size: 24, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
