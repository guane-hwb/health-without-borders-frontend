// lib/src/features/nfc/presentation/profile/widgets/profile_tabs_bar.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../design/tokens/app_colors.dart';
import '../../../domain/patient_record.dart';

class ProfileTabsBar extends StatelessWidget {
  const ProfileTabsBar({
    super.key,
    required this.controller,
    required this.draft,
  });
  final TabController controller;
  final PatientFullRecord draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.white,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: '  ${AppStrings.of(context).tabSummary}  '),
          Tab(
            child: TabLabelWithBadge(
              text: AppStrings.of(context).consultations,
              count: draft.medicalHistory.length,
            ),
          ),
          Tab(
            child: TabLabelWithBadge(
              text: AppStrings.of(context).vaccines,
              count: draft.vaccinationRecord.length,
            ),
          ),
        ],
      ),
    );
  }
}

class TabLabelWithBadge extends StatelessWidget {
  const TabLabelWithBadge({super.key, required this.text, required this.count});
  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
