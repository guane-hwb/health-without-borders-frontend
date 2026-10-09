// lib/src/features/auth/domain/password_policy.dart

import 'dart:convert';

/// The rules POST /users/me/password applies to a new password
/// (`check_chosen_password` in the backend's app/schemas/user.py), checked
/// before sending so the user hears why at once instead of through a 422.
abstract final class PasswordPolicy {
  /// Counted in characters, as the backend's `len()`: code points, not UTF-16
  /// units, so an emoji counts once.
  static const int minLength = 12;

  /// bcrypt reads only the first 72 bytes; the backend refuses longer ones.
  static const int maxBytes = 72;

  /// Refused whatever their length, compared case-insensitively. Keep in step
  /// with COMMON_PASSWORDS in the backend.
  static const Set<String> common = <String>{
    '123456789012',
    '1234567890123',
    'password1234',
    'contraseña123',
    'contrasena123',
    'qwertyuiop12',
    'change_me_now',
    'health-without-borders',
    'healthwithoutborders',
  };

  /// Why [password] cannot be the new one, or null when it can.
  static String? problem(
    String password, {
    String? current,
    required bool isEs,
  }) {
    if (password.runes.length < minLength) {
      return isEs
          ? 'Debe tener al menos $minLength caracteres.'
          : 'It must have at least $minLength characters.';
    }
    if (utf8.encode(password).length > maxBytes) {
      return isEs
          ? 'Es demasiado larga: máximo $maxBytes bytes (las tildes y los '
                'emojis ocupan más de uno).'
          : 'It is too long: at most $maxBytes bytes (accents and emoji take '
                'more than one).';
    }
    if (common.contains(password.trim().toLowerCase())) {
      return isEs
          ? 'Es una contraseña demasiado común; elija otra.'
          : 'This password is too common; choose another one.';
    }
    if (current != null && password == current) {
      return isEs
          ? 'Debe ser distinta de la contraseña actual.'
          : 'It must be different from the current password.';
    }
    return null;
  }
}
