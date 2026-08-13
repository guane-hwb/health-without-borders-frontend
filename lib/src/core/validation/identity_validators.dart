// lib/src/core/validation/identity_validators.dart

class ValidationErrorKey {
  static const String documentFormat = 'invalidDocumentFormat';
  static const String phoneFormat = 'invalidPhoneFormat';
  static const String emailFormat = 'invalidEmailFormat';
}

final RegExp _documentRegex = RegExp(r'^[a-zA-Z0-9.-]{5,20}$');

final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

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

String? validatePhone(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return null;
  return _phoneRegex.hasMatch(clean) ? null : ValidationErrorKey.phoneFormat;
}

String? validateEmail(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return null;
  return _emailRegex.hasMatch(clean) ? null : ValidationErrorKey.emailFormat;
}
