// lib/src/core/validation/identity_validators.dart

class ValidationErrorKey {
  static const String documentFormat = 'invalidDocumentFormat';
  static const String phoneFormat = 'invalidPhoneFormat';
  static const String emailFormat = 'invalidEmailFormat';
}

final RegExp _documentRegex = RegExp(r'^[a-zA-Z0-9.-]{5,20}$');

final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

final RegExp _phoneSeparators = RegExp(r'[\s().-]');

final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

String? validateDocumentNumber(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return null;
  return _documentRegex.hasMatch(clean)
      ? null
      : ValidationErrorKey.documentFormat;
}

/// The phone as it is stored: digits only, with the leading «+» if it has one.
/// Spaces, hyphens, dots and parentheses («+57 (310) 482-9914») are dropped.
String normalizePhone(String value) =>
    value.trim().replaceAll(_phoneSeparators, '');

String? validatePhone(String value) {
  if (value.trim().isEmpty) return null;
  return _phoneRegex.hasMatch(normalizePhone(value))
      ? null
      : ValidationErrorKey.phoneFormat;
}

String? validateEmail(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return null;
  return _emailRegex.hasMatch(clean) ? null : ValidationErrorKey.emailFormat;
}
