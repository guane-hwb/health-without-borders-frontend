// lib/src/features/nfc/presentation/profile/shared/code_source_label.dart

import '../../../../../core/i18n/app_strings.dart';
import '../../../domain/patient_record.dart';

/// Where a consultation diagnosis came from, for display next to it; null for
/// one a professional recorded.
///
/// The app never sends diagnoses: they are suggested by the backend's LLM, and
/// the RDA receives them as provisional. A reader must not take them for a
/// professional's. Diagnoses stored before the backend recorded the origin
/// carry none: they are labelled as such rather than guessed either way.
String? diagnosisSourceLabel(AppStrings s, String? source) => switch (source) {
  CodeSource.clinician => null,
  CodeSource.aiSuggested => s.sourceAiSuggested,
  CodeSource.aiFallback => s.sourceAiFallback,
  _ => s.sourceUnrecorded,
};

/// The ICD line under a background item (chronic condition, family history):
/// the code, its name, and whether the AI chose it. The professional's own
/// text is shown above it and is never replaced by the code's name.
String backgroundCodeLine(
  AppStrings s, {
  required String cie10Code,
  String? cie11Code,
  String? codedDisplay,
  String? codingSource,
}) {
  final StringBuffer line = StringBuffer('${s.cie10Label}$cie10Code');
  if (codedDisplay != null && codedDisplay.isNotEmpty) {
    line.write(' — $codedDisplay');
  }
  if (cie11Code != null) line.write(' · CIE-11: $cie11Code');
  if (CodeSource.isAi(codingSource)) line.write(' · ${s.codeSuggestedByAi}');
  return line.toString();
}
