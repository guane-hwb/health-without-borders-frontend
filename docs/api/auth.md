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
  final bool mustChangePassword; // set by an administrator: change it first

  String get shortName; // First two words of fullName
}
```

## Password change

`AuthRepository.changePassword(currentPassword, newPassword)` calls
`POST /api/v1/users/me/password`. The server ends **every** session of the user,
this device's included, and answers with a new token pair and NFC keyring (the
same shape as the login response); the repository stores them in place of the
old ones. A refresh that was already in flight with the revoked token does not
end the session.

- `400`: the current password is wrong. The screen refuses a new password equal
  to the current one before sending, so that is the only 400 left.
- `422`: the new password breaks the policy. `PasswordPolicy` checks it in the
  app first: at least 12 characters, at most 72 bytes in UTF-8, not a common
  password.
- `429`: too many attempts, by IP or `login_paused` with `Retry-After` (5 wrong
  passwords in 15 minutes pause the account; the pause also blocks the login).

`must_change_password` comes in the login, refresh and `GET /users/me`
responses. It is true for accounts an administrator created and after a reset.
While it is true, Home and every route open `ChangePasswordScreen(mandatory:
true)`: no way back, only change the password or sign out.

Administrators reset a password with `UserRepository.resetPassword(id)`
(`POST /api/v1/users/{id}/reset-password`): superadmin, or org_admin for the
doctors and nurses of their organization. The temporary password is shown once.

A login refused with `429` (`login_paused` or the per-IP limit) tells the user
how long to wait (`ApiErrorCode.tooManyAttempts`).

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