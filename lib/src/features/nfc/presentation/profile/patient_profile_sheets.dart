// lib/src/features/nfc/presentation/profile/patient_profile_sheets.dart

import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../domain/patient_record.dart';
import 'sheets/add_allergy_sheet.dart';
import 'sheets/add_chronic_condition_sheet.dart';
import 'sheets/add_family_history_sheet.dart';
import 'sheets/add_medication_sheet.dart';
import 'sheets/allergies_manage_sheet.dart';
import 'sheets/background_manage_sheet.dart';
import 'sheets/edit_address_sheet.dart';
import 'sheets/edit_chronic_personal_sheet.dart';
import 'sheets/edit_guardian_sheet.dart';
import 'sheets/edit_vital_signs_sheet.dart';

abstract class PatientProfileSheets {
  static Future<void> openVitalSignsSheet(
    BuildContext context, {
    required PatientFullRecord draft,
    required PatientFullRecord original,
    required void Function({double? weight, double? height, String? bloodType})
    onConfirm,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditVitalSignsSheet(
        weight: draft.patientInfo.weight,
        height: draft.patientInfo.height,
        bloodType: draft.patientInfo.bloodType,
        previousWeight: original.patientInfo.weight,
        previousHeight: original.patientInfo.height,
        onConfirm: onConfirm,
      ),
    );
  }

  static Future<void> openAddressSheet(
    BuildContext context, {
    required Address address,
    required ValueChanged<Address> onConfirm,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditAddressSheet(address: address, onConfirm: onConfirm),
    );
  }

  static Future<void> openGuardianSheet(
    BuildContext context, {
    required PatientFullRecord draft,
    required int guardianIndex,
    required ValueChanged<GuardianInfo> onConfirm,
  }) async {
    final GuardianInfo? current = guardianIndex == 1
        ? draft.guardianInfo
        : draft.guardian2Info;
    if (current == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => EditGuardianSheet(
        guardian: current,
        guardianIndex: guardianIndex,
        onConfirm: onConfirm,
      ),
    );
  }

  static Future<void> openEditPersonalSheet(
    BuildContext context, {
    required PatientFullRecord draft,
    required ValueChanged<String?> onConfirm,
  }) async {
    final bg = draft.backgroundHistory ?? BackgroundHistory();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditChronicPersonalSheet(
        title: AppStrings.of(context).personalHistoryTitle,
        currentValue: bg.personalHistory,
        onConfirm: onConfirm,
      ),
    );
  }

  static Future<void> openAddChronicConditionSheet(
    BuildContext context, {
    required ValueChanged<ChronicConditionItem> onAdd,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddChronicConditionSheet(onAdd: onAdd),
    );
  }

  static Future<void> openAddMedicationSheet(
    BuildContext context, {
    required ValueChanged<MedicationStatementItem> onAdd,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMedicationSheet(onAdd: onAdd),
    );
  }

  static Future<void> openAddFamilyHistorySheet(
    BuildContext context, {
    required ValueChanged<FamilyHistoryItem> onAdd,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFamilyHistorySheet(onAdd: onAdd),
    );
  }

  static Future<void> openAddAllergySheet(
    BuildContext context, {
    required ValueChanged<AllergyInfo> onAdd,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAllergySheet(onAdd: onAdd),
    );
  }

  static void openAllergiesSheet(
    BuildContext context, {
    required PatientFullRecord draft,
    required ValueChanged<int> onRemove,
    required ValueChanged<AllergyInfo> onAddAllergy,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AllergiesManageSheet(
        allergies: draft.allergies,
        onAdd: () async {
          Navigator.of(context).pop();
          await openAddAllergySheet(context, onAdd: onAddAllergy);
        },
        onRemove: (i) {
          onRemove(i);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  static void openBackgroundSheet(
    BuildContext context, {
    required PatientFullRecord draft,
    required ValueChanged<ChronicConditionItem> onAddChronic,
    required ValueChanged<int> onRemoveChronic,
    required ValueChanged<String?> onEditPersonal,
    required ValueChanged<FamilyHistoryItem> onAddFamily,
    required ValueChanged<int> onRemoveFamily,
    required ValueChanged<MedicationStatementItem> onAddMedication,
    required ValueChanged<int> onRemoveMedication,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackgroundManageSheet(
        draft: draft,
        onAddChronic: () {
          Navigator.of(context).pop();
          openAddChronicConditionSheet(context, onAdd: onAddChronic);
        },
        onRemoveChronic: (i) {
          onRemoveChronic(i);
          Navigator.of(context).pop();
        },
        onEditPersonal: () {
          Navigator.of(context).pop();
          openEditPersonalSheet(
            context,
            draft: draft,
            onConfirm: onEditPersonal,
          );
        },
        onAddFamily: () {
          Navigator.of(context).pop();
          openAddFamilyHistorySheet(context, onAdd: onAddFamily);
        },
        onRemoveFamily: (i) {
          onRemoveFamily(i);
          Navigator.of(context).pop();
        },
        onAddMedication: () {
          Navigator.of(context).pop();
          openAddMedicationSheet(context, onAdd: onAddMedication);
        },
        onRemoveMedication: (i) {
          onRemoveMedication(i);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
