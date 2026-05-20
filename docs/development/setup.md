# Local Configuration

## Prerequisites

| Tool | Required Version | Notes |
|---|---|---|
| Flutter (via FVM) | 3.41.5 | Do not install Flutter directly — use FVM |
| Dart SDK | 3.8.0 | Included with Flutter 3.41.5 |
| Xcode | 15+ | For iOS/macOS builds only |
| Android Studio | Ladybug+ | For Android builds and the emulator |
| Android SDK | API 21+ | Minimum supported level |

## Install FVM and Flutter

[FVM (Flutter Version Management)](https://fvm.app) allows you to fix the SDK version per project, ensuring that all team members use the exact same version.

```bash
# Activate FVM globally
dart pub global activate fvm

# Install the project version
~/.pub-cache/bin/fvm install 3.41.5

# Set the version in the repository directory
~/.pub-cache/bin/fvm use 3.41.5
```

The `.fvmrc` file in the repository root already contains the correct version. FVM will automatically read it from the project directory.

## Environment Variables

The app uses `flutter_dotenv` to load runtime configuration.

```bash
cp .env.example .env
```

Edit `.env` with the values ​​corresponding to your environment:

```dotenv
# Base URL of the backend (without trailing slash)
API_BASE_URL=http://localhost:8000

# Production example
# API_BASE_URL=https://api.healthwithoutborders.org
```

!!! warning ".env files and assets"
    The `.env` and `.env.production` files are declared as assets in `pubspec.yaml`. **Do not delete them** — the app loads them in `main.dart` via `flutter_dotenv`.

## Install dependencies

```bash
~/.pub-cache/bin/fvm flutter pub get
```

## Run the application

=== "macOS"

    ```bash
    ~/.pub-cache/bin/fvm flutter run -d macos
    ```

=== "Android"

    ```bash
    # List available devices/emulators
    ~/.pub-cache/bin/fvm flutter devices

    ~/.pub-cache/bin/fvm flutter run -d <device-id>
    ```

=== "iOS"

    ```bash
    # Requires Xcode and a simulator or physical device
    ~/.pub-cache/bin/fvm flutter run -d iPhone
    ```

=== "Web (Chrome)"

    ```bash
    ~/.pub-cache/bin/fvm flutter run -d chrome
    ```

    !!! note "NFC on web"
        NFC reading is not available in browsers. On the web, the `NfcService` uses the stub (`nfc_service_stub.dart`) that simulates the operation.

## Verify the configuration

```bash
~/.pub-cache/bin/fvm flutter doctor
~/.pub-cache/bin/fvm flutter analyze
~/.pub-cache/bin/fvm flutter test
```

All three commands must complete without errors before opening a pull request.

## Editor Configuration (VS Code)

Add the following to `.vscode/settings.json`:

```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk"
}
```

This makes VS Code use the FVM-managed SDK instead of the global SDK.