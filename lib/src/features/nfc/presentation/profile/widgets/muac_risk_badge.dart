// lib/src/features/nfc/presentation/profile/widgets/muac_risk_badge.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/muac.dart';

/// The colour and the word of each level: colour alone is lost to red-green
/// colour blindness and in the sun, so the word always goes with it.
({Color background, Color foreground, String label}) muacRiskStyle(
  AppStrings s,
  MuacRisk risk,
) => switch (risk) {
  MuacRisk.red => (
    background: AppColors.riskRed,
    foreground: AppColors.white,
    label: s.muacRiskRed,
  ),
  MuacRisk.yellow => (
    background: AppColors.riskYellow,
    foreground: AppColors.textPrimary,
    label: s.muacRiskYellow,
  ),
  MuacRisk.green => (
    background: AppColors.riskGreen,
    foreground: AppColors.white,
    label: s.muacRiskGreen,
  ),
};

/// A coloured chip with ROJO / AMARILLO / VERDE.
class MuacRiskBadge extends StatelessWidget {
  const MuacRiskBadge({super.key, required this.risk});

  final MuacRisk risk;

  @override
  Widget build(BuildContext context) {
    final style = muacRiskStyle(AppStrings.of(context), risk);
    return Container(
      key: ValueKey('muac_risk_${risk.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: style.foreground,
        ),
      ),
    );
  }
}

/// The chip with what the level means and what to do, for the forms where
/// the measure is typed.
class MuacRiskAdvice extends StatelessWidget {
  const MuacRiskAdvice({super.key, required this.risk});

  final MuacRisk risk;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final (meaning, action) = switch (risk) {
      MuacRisk.red => (s.muacMeaningRed, s.muacActionRed),
      MuacRisk.yellow => (s.muacMeaningYellow, s.muacActionYellow),
      MuacRisk.green => (s.muacMeaningGreen, s.muacActionGreen),
    };
    final color = muacRiskStyle(s, risk).background;
    return Container(
      key: const ValueKey('muac_risk_advice'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MuacRiskBadge(risk: risk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meaning,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            action,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
