// lib/src/features/nfc/presentation/profile/patient_profile_helpers.dart

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/i18n/app_strings.dart';

DateTime? tryParsePatientDate(String dob) {
  try {
    return DateTime.parse(dob);
  } catch (_) {}

  final slashMatch = RegExp(
    r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})\s*\$',
  ).firstMatch(dob.trim());
  if (slashMatch != null) {
    final day = int.tryParse(slashMatch.group(1)!);
    final month = int.tryParse(slashMatch.group(2)!);
    final year = int.tryParse(slashMatch.group(3)!);
    if (day != null && month != null && year != null) {
      try {
        return DateTime(year, month, day);
      } catch (_) {}
    }
  }

  return null;
}

// ── Connectivity ─────────────────────────────────────────────────────────
bool hasInternetConnection(List<ConnectivityResult> results) {
  return !results.contains(ConnectivityResult.none);
}

// ── Age ──────────────────────────────────────────────────────────────────
int? computeAge(String dob, DateTime now) {
  final DateTime? dobDateTime = tryParsePatientDate(dob);
  if (dobDateTime == null) return null;

  var age = now.year - dobDateTime.year;
  if (now.month < dobDateTime.month ||
      (now.month == dobDateTime.month && now.day < dobDateTime.day)) {
    age--;
  }
  return age >= 0 ? age : null;
}

// ── Initials ─────────────────────────────────────────────────────────────

String computeInitials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || (parts.length == 1 && parts.first.isEmpty)) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

// ── Avatar color index ──────────────────────────────────────────────────
const int avatarColorPaletteLength = 8;

int avatarColorIndex(String initials) {
  var hash = 0;
  for (var i = 0; i < initials.length; i++) {
    hash = hash * 31 + initials.codeUnitAt(i);
  }
  return hash.abs() % avatarColorPaletteLength;
}

// ── Label lookups ────────────────────────────────────────────────────────

String sexLabel(AppStrings s, String biologicalSex) {
  switch (biologicalSex) {
    case 'M':
      return s.sexMale;
    case 'F':
      return s.sexFemale;
    default:
      return s.sexIndeterminate;
  }
}

String docTypeLabel(AppStrings s, String documentType) {
  final map = <String, String>{
    'RC': s.docTypeRC,
    'TI': s.docTypeTI,
    'CC': s.docTypeCC,
    'CE': s.docTypeCE,
    'PA': s.docTypePA,
    'PE': s.docTypePE,
    'PT': s.docTypePT,
    'MS': s.docTypeMS,
    'AS': s.docTypeAS,
    'SC': s.isEs ? 'Salvoconducto' : 'Safe-conduct',
    'CN': s.isEs ? 'Cert. Nacido Vivo' : 'Live Birth Cert.',
    'DE': s.isEs ? 'Doc. Extranjero' : 'Foreign ID',
  };
  return map[documentType] ?? (documentType.isNotEmpty ? documentType : '—');
}

String relLabel(AppStrings s, String relationshipCode) {
  return <String, String>{
        '01': s.relParents,
        '02': s.relSiblings,
        '03': s.relUncles,
        '04': s.relGrandparents,
      }[relationshipCode] ??
      relationshipCode;
}

String allergyCategoryLabel(AppStrings s, String categoryCode) {
  final map = <String, String>{
    '01': s.allergyShortMedication,
    '02': s.allergyShortFood,
    '03': s.allergyShortEnvironment,
    '04': s.allergyShortSkin,
    '05': s.allergyShortInsect,
    '06': s.allergyShortOther,
  };
  return map[categoryCode] ??
      (categoryCode.isNotEmpty ? categoryCode : (s.isEs ? 'Otra' : 'Other'));
}

/// Medication status label.
String medStatusLabel(AppStrings s, String statusCode) {
  switch (statusCode) {
    case 'active':
      return s.medStatusActive;
    case 'completed':
      return s.medStatusCompleted;
    case 'stopped':
      return s.medStatusStopped;
    case 'unknown':
      return s.medStatusUnknown;
    default:
      return statusCode;
  }
}
