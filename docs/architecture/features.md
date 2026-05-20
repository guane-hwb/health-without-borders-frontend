# Modules and Features

Each feature resides in `lib/src/features/<name>/`. This page describes what each feature does and what screens it exposes.

## `auth` — Authentication

Manages the user session lifecycle.

**Screens:**

- `login_screen.dart` — email/password form. Calls `POST /api/v1/login/access-token` (form-encoded) and then `GET /api/v1/users/me` to retrieve the user profile.

**Domain:**

- `UserSession` — represents the authenticated user with their role, organization, and name.

- `UserRole` — enum with four roles: `doctor`, `nurse`, `orgAdmin`, `superadmin`. Each role exposes boolean getters (`canReadPatients`, `canAddConsultation`, etc.) that the UI consumes directly.

**Repositories:**

- `AuthRepository` — login, logout, and JWT token management in `FlutterSecureStorage`.
- `UserRepository` — retrieves the authenticated user's profile from the backend.

## `nfc` — Patients and NFC

Main feature of the app. It centralizes all the logic for capturing and displaying clinical data.

**Main Flow:**

1. **NFC Read** (`read_nfc_screen.dart`) — scans the wristband and obtains the device UID.
2. **Registration** (`register/register_nfc_screen.dart`) — a 6-step wizard to register a new patient.
3. **Profile** (`profile/patient_profile_screen.dart`) — view of the medical record tabs.
4. **Lost Wristband** (`loss_of_wristband_screen.dart`) — search for a patient by name/document.

**Editing Screens (sheets):**

- `add_consultation_screen.dart` / `add_vaccine_screen.dart` — add clinical entries.
- Sheets in `profile/sheets/` — inline editing of allergies, family history, vital signs, address, and guardian.

**Profile Tabs:**

| Tab | File | Content |
|---|---|---|
| Summary | `profile_tab_summary.dart` | Demographics, vital signs |
| Background | `profile_tab_background.dart` | Chronic conditions, family history |
| Allergies | `profile_tab_allergies.dart` | List of allergies with category and reaction |
| Vaccinations | `profile_tab_vaccines.dart` | Vaccination history |
| Consultations | `profile_tab_consultations.dart` | Medical consultation history |

## `home` — Home screen

`home_screen.dart` displays the actions available based on the user's role:

- **Doctor / Nurse:** Scan NFC, Register patient, Sync queue.
- **Org Admin:** Brigade statistics, Manage users/organizations.

Screens visible only to `orgAdmin` and `superadmin`:

- `brigade_stats_screen.dart` — Brigade KPIs and statistics.
- `manage_users_screen.dart` — User list and creation.
- `manage_organizations_screen.dart` — Organization management.

## `brigade` — Brigade history

`brigade_history_screen.dart` — List of patients seen by the current brigade.

## `sync` — Synchronization queue

`sync_queue_screen.dart` — Displays records pending synchronization with their status (`pending`, `synced`, `error`). Allows you to initiate a manual synchronization.