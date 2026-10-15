// lib/src/core/network/api_error_codes.dart

/// Machine-readable error codes the backend sends next to `detail`.
///
/// `detail` stays a human (English) string for older app builds; `code` is
/// what the app decides on. Matching `detail` text broke whenever the server
/// reworded a message, and could not tell apart errors that share a status
/// (the four 409s of /sync, the two guardian 403s of /scan).
abstract final class ApiErrorCode {
  /// The user's account is deactivated: 403 on the API, 401 on login/refresh.
  static const String userInactive = 'user_inactive';

  /// The user's organization is deactivated: same statuses as [userInactive].
  static const String organizationInactive = 'organization_inactive';

  /// Login or password change (429): too many wrong passwords for the account
  /// in 15 minutes. Comes with Retry-After; the pause starts at 60 s and
  /// doubles up to 15 minutes.
  static const String loginPaused = 'login_paused';

  /// /scan of a minor without the guardian card (403).
  static const String guardianRequired = 'guardian_required';

  /// /scan of a minor with a card that is not one of the guardians' (403).
  static const String guardianMismatch = 'guardian_mismatch';

  /// /sync: the device already belongs to another patient (409).
  static const String deviceUidConflict = 'device_uid_conflict';

  /// /sync (503, Retry-After 5): another request created this same new
  /// patient a moment before, usually a retry racing the first attempt.
  /// Transient: the next attempt merges into the record it created.
  static const String syncInProgress = 'sync_in_progress';

  /// The record stays queued and the engine retries it; the queue shows it
  /// as pending, not as an error to fix.
  static bool isTransient(String? code) => code == syncInProgress;

  /// /sync: a new patient whose identity document is already registered (409).
  static const String duplicateIdentity = 'duplicate_identity';

  /// /sync: the device belongs to a patient with another identity (409).
  static const String identityMismatch = 'identity_mismatch';

  /// /sync (409) or /scan (410): the device was retired.
  static const String deviceRetired = 'device_retired';

  /// /scan or /search (500): the stored record no longer reads. Not
  /// transient: asking again gives the same answer.
  static const String storedRecordInvalid = 'stored_record_invalid';

  /// The account can no longer use the API: sign out, keep pending data.
  static bool isAccountInactive(String? code) =>
      code == userInactive || code == organizationInactive;

  static bool isGuardianCheck(String? code) =>
      code == guardianRequired || code == guardianMismatch;

  /// A 429 from login or password change: [loginPaused], or the per-IP limit
  /// (no code). Says how long to wait when the server sent Retry-After.
  static String tooManyAttempts(Duration? retryAfter, {required bool isEs}) {
    if (retryAfter == null || retryAfter <= Duration.zero) {
      return isEs
          ? 'Demasiados intentos. Espere unos minutos e intente de nuevo.'
          : 'Too many attempts. Wait a few minutes and try again.';
    }
    final int seconds = retryAfter.inSeconds;
    final bool inSeconds = seconds < 60;
    final int n = inSeconds ? seconds : (seconds / 60).ceil();
    final String unit = switch ((inSeconds, n == 1, isEs)) {
      (true, true, true) => 'segundo',
      (true, false, true) => 'segundos',
      (false, true, true) => 'minuto',
      (false, false, true) => 'minutos',
      (true, true, false) => 'second',
      (true, false, false) => 'seconds',
      (false, true, false) => 'minute',
      (false, false, false) => 'minutes',
    };
    final String wait = '$n $unit';
    return isEs
        ? 'Demasiados intentos. Intente de nuevo en $wait.'
        : 'Too many attempts. Try again in $wait.';
  }

  /// The user-facing message for [code], or null when the app has none and
  /// should fall back to the server's `detail`.
  static String? describe(String? code, {required bool isEs}) => switch (code) {
    userInactive =>
      isEs
          ? 'Tu cuenta está desactivada. Contacta al administrador de tu '
                'organización.'
          : 'Your account is deactivated. Contact your organization '
                'administrator.',
    organizationInactive =>
      isEs
          ? 'Tu organización está desactivada en HWB. Contacta al '
                'administrador.'
          : 'Your organization is deactivated in HWB. Contact the '
                'administrator.',
    loginPaused => tooManyAttempts(null, isEs: isEs),
    guardianRequired =>
      isEs
          ? 'Paciente menor de edad: se requiere el dispositivo del acudiente.'
          : 'Minor patient: the guardian device is required.',
    guardianMismatch =>
      isEs
          ? 'El dispositivo no corresponde a ningún acudiente registrado de '
                'este paciente.'
          : 'This device does not belong to any registered guardian of this '
                'patient.',
    deviceUidConflict =>
      isEs
          ? 'Este dispositivo ya está registrado para otro paciente. '
                'Registra al paciente con un dispositivo nuevo.'
          : 'This device is already registered to another patient. '
                'Register the patient with a new device.',
    syncInProgress =>
      isEs
          ? 'Otro envío estaba guardando este paciente. Se reintentará '
                'automáticamente en unos instantes.'
          : 'Another request was saving this patient. It will retry '
                'automatically in a moment.',
    duplicateIdentity =>
      isEs
          ? 'Ya existe un paciente registrado con este número de '
                'documento.'
          : 'A patient is already registered with this identity document.',
    identityMismatch =>
      isEs
          ? 'El dispositivo pertenece a un paciente con otro documento de '
                'identidad. Verifica el dispositivo y los datos del paciente.'
          : 'This device belongs to a patient with another identity '
                'document. Check the device and the patient data.',
    deviceRetired =>
      isEs
          ? 'Este dispositivo fue retirado y ya no identifica a un paciente. '
                'Usa un dispositivo nuevo.'
          : 'This device was retired and no longer identifies a '
                'patient. Use a new device.',
    storedRecordInvalid =>
      isEs
          ? 'No se pudo leer el registro de este paciente en el servidor. '
                'Contacte a soporte.'
          : "The server could not read this patient's record. Contact "
                'support.',
    _ => null,
  };
}
