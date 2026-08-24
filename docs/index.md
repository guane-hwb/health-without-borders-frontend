# Health Without Borders — Frontend

**Flutter cross-platform client for the Health Without Borders initiative.**

[![Flutter](https://img.shields.io/badge/Flutter-3.41.5-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8.0-0175C2.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green)](https://github.com/guanes/health-without-borders-frontend/blob/main/LICENSE)

---

## What is this project?

Health Without Borders is a mobile and web application designed for vulnerable populations (migrants, rural communities) operating in environments with limited connectivity. The frontend captures medical records in the field using NFC wristbands, stores them locally in SQLite, and automatically synchronizes them with the backend when a connection is available.

## Design Principles

- **Offline-first:** The synchronization engine runs in the background when a network connection is detected.
- **NFC como identificador:** Each patient is linked to an NFC wristband (unique UID). Read/write operations use `nfc_manager`.
- **Contrato de API estricto:** The domain models in `lib/src/features/nfc/domain/patient_record.dart` are a 1:1 mirror of the backend schemas (FastAPI).
- **Roles y permisos:** Access to functionalities is controlled by `UserRole` (doctor, nurse, org_admin, superadmin).

## Technology Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.41.5 (via FVM) |
| Language | Dart 3.8.0 |
| Local Database | sqflite (SQLite) |
| NFC | nfc_manager 3.5.0 |
| Network | HTTP 1.6.0, connectivity_plus |
| Security | flutter_secure_storage |
| Voice | speech_to_text |
| Platforms | iOS, Android, macOS, Web |

## Quick start

```bash
# 1. Install the Flutter SDK via FVM
dart pub global activate fvm
~/.pub-cache/bin/fvm install 3.41.5
~/.pub-cache/bin/fvm use 3.41.5

# 2. Install dependencies
~/.pub-cache/bin/fvm flutter pub get

# 3. Copy environment variables
cp .env.example .env
# Editar .env con la URL del backend

# 4. Run the app
~/.pub-cache/bin/fvm flutter run -d macos   # macOS
~/.pub-cache/bin/fvm flutter run -d android # Android
~/.pub-cache/bin/fvm flutter run -d chrome  # Web
```

## Documentation navigation

- **[Development](development/index.md)** — local configuration, quality gates, Figma integration.
- **[Architecture](architecture/index.md)** — project structure, features, offline-first workflow.
- **[API & Domain](api/index.md)** — data models, HTTP client, authentication.
- **[Testing](testing.md)** — unit and widget tests.

## Contribution

1. Open pull requests against `develop`.
2. Use the template in `.github/PULL_REQUEST_TEMPLATE.md`.
3. Run `flutter analyze` and `flutter test` before requesting a review.
4. See [QA & PR Flow](development/qa-plan.md) for more details.