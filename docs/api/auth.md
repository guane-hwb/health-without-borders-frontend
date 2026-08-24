# Authentication

## Login Flow

```
LoginScreen
    │
    ▼
AuthRepository.login(email, password)
    │
    ├── POST /api/v1/login/access-token  (form-encoded)
    │       → { access_token: "..." }
    │
    └── GET /api/v1/users/me
            → UserSession { id, email, fullName, role, organizationId }
```

The JWT token is persisted in `FlutterSecureStorage` with the key `hwb_access_token`. On app restart, `AuthRepository.getCurrentUser()` attempts to retrieve the token and rebuild the session.

## `UserSession`

```dart
class UserSession {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String organizationId;
  final String? organizationName;
  final bool isActive;

  String get shortName; // First two words of fullName
}
```

If the backend does not return `full_name`, the repository constructs it by humanizing the email: `"doctor.juan@org.com"` → `"Doctor Juan"`.

## Roles — `UserRole`

```dart
enum UserRole { superadmin, orgAdmin, doctor, nurse }
```

| Permission | doctor | nurse | orgAdmin | superadmin |
|---|:---:|:---:|:---:|:---:|
| `canReadPatients` | ✓ | ✓ | ✓ | ✓ |
| `canRegisterPatient` | ✓ | ✓ | | |
| `canAddConsultation` | ✓ | | | |
| `canAddVaccine` | ✓ | ✓ | | |
| `canSyncPatient` | ✓ | ✓ | | |
| `canScanNfc` | ✓ | ✓ | | |
| `canSearchPatient` | ✓ | ✓ | ✓ | |
| `canManageUsers` | | | ✓ | ✓ |
| `canViewAnalytics` | | | ✓ | ✓ |

The UI uses these getters directly to show or hide actions:

```dart
if (AppScope.of(context).currentUser?.role.canAddConsultation ?? false)
  AddConsultationButton(),
```

## Logout

```dart
await authRepository.logout();
// Deletes the token from FlutterSecureStorage and clears the session
```

After logout, the app navigates to the `LoginScreen` and the `SyncEngine` must stop.

## Token Security

- The token is stored exclusively in `FlutterSecureStorage` — on iOS it uses the Keychain, on Android the Android Keystore.
- It is **Never** stored in `SharedPreferences` or the flat file system.
- The `SyncEngine` stops the entire synchronization process upon receiving a 401 error and delegates the re-login to the UI.