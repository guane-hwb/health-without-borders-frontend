// lib/src/features/admin/presentation/manage_organizations_helpers.dart

int orgColorIndex(String name) => name.codeUnitAt(0) % 5;

String orgInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
}
