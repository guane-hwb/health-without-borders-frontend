// lib/src/features/auth/domain/user_session.dart

/// Local representation of the authenticated user.
///
/// Populated after login by calling GET /api/v1/users/me (once that endpoint
/// exists in the backend). Until then, only [email] is guaranteed from the JWT.
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
    return UserSession(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? json['email']?.toString() ?? '',
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
      fullName: email.split('@').first,
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

  /// Greeting name: "Dr. Juan Pérez" → "Dr. Juan"
  String get shortName {
    final parts = fullName.split(' ');
    return parts.length >= 2 ? '${parts[0]} ${parts[1]}' : fullName;
  }

  static UserRole _parseRole(String? raw) {
    switch (raw) {
      case 'superadmin': return UserRole.superadmin;
      case 'org_admin': return UserRole.orgAdmin;
      case 'nurse': return UserRole.nurse;
      case 'doctor': default: return UserRole.doctor;
    }
  }
}

enum UserRole {
  superadmin,
  orgAdmin,
  doctor,
  nurse;

  bool get isAdmin => this == orgAdmin || this == superadmin;
  bool get canAddConsultation => this == doctor || this == superadmin;
  bool get canAddVaccine => this == doctor || this == nurse || this == superadmin;
  bool get canRegisterPatient => this != orgAdmin;
  bool get canSyncPatient => this == doctor || this == nurse;
  bool get canManageUsers => isAdmin;
  bool get canViewAnalytics => isAdmin;
}