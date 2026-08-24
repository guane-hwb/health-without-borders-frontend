// lib/src/features/auth/domain/user_session.dart

/// Local representation of the authenticated user.
///
/// Populated after login by calling GET /api/v1/users/me.
class UserSession {
  UserSession({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.organizationId,
    this.organizationName,
    this.isActive = true,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final email = json['email']?.toString() ?? '';
    final rawName = json['full_name']?.toString();
    // Use full_name if available; otherwise build a readable name from email
    final displayName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : _humanizeEmail(email);

    return UserSession(
      id: json['id']?.toString() ?? '',
      email: email,
      fullName: displayName,
      role: _parseRole(json['role']?.toString()),
      organizationId: json['organization_id']?.toString() ?? '',
      organizationName: json['organization_name']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Minimal session built only from the JWT subject (email).
  /// Used as a fallback until /users/me is available.
  factory UserSession.fromEmail(String email) {
    return UserSession(
      id: '',
      email: email,
      fullName: _humanizeEmail(email),
      role: UserRole.doctor, // safe default — UI adapts once role is confirmed
      organizationId: '',
    );
  }

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String organizationId;
  final String? organizationName;
  final bool isActive;

  /// Serializes the session for local persistence (secure storage), so the
  /// app can restore the authenticated user offline after the OS kills the
  /// process. Round-trips through [UserSession.fromJson]: [role] is emitted as
  /// its backend wire string (e.g. `org_admin`), not the Dart enum name, so the
  /// correct role is restored — never silently downgraded to the default.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.wireValue,
        'organization_id': organizationId,
        'organization_name': organizationName,
        'is_active': isActive,
      };

  /// Greeting name: takes first two words of fullName.
  /// "Juan Carlos Pérez" → "Juan Carlos"
  /// "doctor.juan" → "Doctor Juan" (already humanized by factory)
  String get shortName {
    final parts = fullName.split(' ');
    if (parts.length >= 2) return '${parts[0]} ${parts[1]}';
    return fullName;
  }

  /// Converts "doctor.juan@org.com" → "Doctor Juan"
  static String _humanizeEmail(String email) {
    final local = email.split('@').first;
    // Replace dots, underscores, hyphens with spaces then capitalize each word
    final words = local
        .replaceAll(RegExp(r'[._\-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .toList();
    return words.join(' ');
  }

  static UserRole _parseRole(String? raw) {
    switch (raw) {
      case 'superadmin':
        return UserRole.superadmin;
      case 'org_admin':
        return UserRole.orgAdmin;
      case 'nurse':
        return UserRole.nurse;
      case 'doctor':
      default:
        return UserRole.doctor;
    }
  }
}

enum UserRole {
  superadmin,
  orgAdmin,
  doctor,
  nurse;

  bool get isAdmin => this == orgAdmin || this == superadmin;
  bool get isSuperadmin => this == superadmin;

  /// Clinical access — can read patient records via NFC/search
  bool get canReadPatients =>
      this == doctor || this == nurse || this == orgAdmin;

  /// Can register new patients (step-by-step wizard)
  bool get canRegisterPatient => this == doctor || this == nurse;

  /// Can add medical consultations (medicalHistory entries)
  bool get canAddConsultation => this == doctor;

  /// Can add vaccination records
  bool get canAddVaccine => this == doctor || this == nurse;

  /// Can sync patient data to the cloud
  bool get canSyncPatient => this == doctor || this == nurse;

  /// Can manage users (create/list)
  bool get canManageUsers => isAdmin;

  /// Can view analytics/KPIs
  bool get canViewAnalytics => isAdmin;

  /// Can scan NFC wristbands
  bool get canScanNfc => this == doctor || this == nurse;

  /// Can search patients (loss of wristband)
  bool get canSearchPatient =>
      this == doctor || this == nurse || this == orgAdmin;

  /// Backend wire string for this role. Mirrors [UserSession._parseRole] so a
  /// session survives a toJson/fromJson round-trip. Do NOT use `.name`: it would
  /// emit `orgAdmin`, which `_parseRole` does not recognize and would collapse
  /// to the doctor default on restore.
  String get wireValue {
    switch (this) {
      case UserRole.superadmin:
        return 'superadmin';
      case UserRole.orgAdmin:
        return 'org_admin';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.nurse:
        return 'nurse';
    }
  }
}
