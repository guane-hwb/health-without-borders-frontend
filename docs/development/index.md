# Development

This section covers everything you need to contribute to the frontend: from setting up your local environment to successfully opening a pull request.

## Development Stack

| Tool | Version | Purpose |
|---|---|---|
| Flutter | 3.41.5 | Cross-platform UI framework |
| Dart SDK | ^3.11.3 | Language (included with Flutter) |
| flutter_lints | ^6.0.0 | Linting rules |
| flutter_test | SDK | Testing suite |

Production dependencies (NFC, SQLite, HTTP, etc.) are declared in `pubspec.yaml`. Do not install versions other than those specified there—the app is sensitive to API changes between minor versions of `nfc_manager` and `sqflite`.

## Standard Workflow

```
1. Clone the repository and start the environment → setup.md
2. Create the feat/<name> branch from develop
3. Develop with Flutter Analyze running in watch mode
4. Write or update tests in test/unit/ or test/widget/
5. Implement local quality gates → qa-plan.md
6. Open a pull request against develop using the template → qa-plan.md
```

## Recommended Environment

**VS Code** with the following extensions:

- [Flutter](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter) — autocompletion, hot reload, debugging.
- [Dart](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code) — real-time static analysis.

Add this to `.vscode/settings.json` so that VS Code uses the correct Flutter SDK:

```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk"
}
```

**Android Studio / IntelliJ** also work with the official Flutter plugin.

## Everyday Commands

```bash
# Install dependencies after a git pull
flutter pub get

# Hot reload (within a session `flutter run`)
r

# Static analysis
flutter analyze

# Run all tests
flutter test

# Run a specific test
flutter test test/unit/login_unit_test.dart

# View available devices
flutter devices

# Clean up build artifacts (useful when there are unusual errors)
flutter clean && flutter pub get
```

## Detailed Guides

- [Local Configuration](setup.md) — prerequisites, Flutter installation, environment variables, and platform-specific configuration.
- [QA and PR Flow](qa-plan.md) — quality gates, branch policy, PR template, and CI pipeline descriptions.
- [Figma to Flutter](figma-to-flutter.md) — how to translate layouts to widgets, layout tokens, and existing shared widgets.