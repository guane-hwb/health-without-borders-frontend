# Project structure

```
health-without-borders-frontend/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml              # Quality gates (bmanual backup)
│   │   └── docs.yml            # Publica documentación en GitHub Pages
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   ├── CODEOWNERS
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/                       # Source of this documentation (MkDocs)
├── lib/
│   ├── main.dart               # Entry point — initializes DB, env and app
│   └── src/
│       ├── app.dart            # MaterialApp, routes, AppScope
│       ├── core/               # Cross-cutting infrastructure
│       │   ├── config/         # app_env.dart — load .env via flutter_dotenv
│       │   ├── di/             # app_scope.dart — DI InheritedWidget
│       │   ├── i18n/           # app_strings.dart — string literals UI
│       │   ├── network/        # api_client.dart, connectivity_service.dart
│       │   ├── nfc/            # nfc_service (stub / mobile)
│       │   ├── storage/        # local_database.dart — SQLite singleton
│       │   └── sync/           # sync_engine.dart — sync engine
│       ├── design/
│       │   ├── theme/          # app_theme.dart — ThemeData
│       │   └── tokens/         # app_colors.dart — color palette
│       ├── features/
│       │   ├── admin/          # Admin screens (org_admin, superadmin)
│       │   ├── auth/           # Login, auth and user repositories
│       │   ├── brigade/        # Brigade history
│       │   ├── home/           # Home screen
│       │   ├── nfc/            # Main feature — NFC, patients, profile
│       │   └── sync/           # Sync queue UI
│       └── shared/
│           └── widgets/        # Reusable widgets (HwbButton, HwbTextField…)
├── test/
│   ├── unit/                   # Pure logic tests
│   └── widget/                 # Widget tree tests
├── assets/
│   └── images/                 # Graphic resources (app-icon.png…)
├── .env.example                # Environment variable template
├── .fvmrc                      # Fixed Flutter version (3.41.5)
├── analysis_options.yaml       # Linting rules (extends flutter_lints)
├── mkdocs.yml                  # Configuration of this documentation
└── pubspec.yaml                # Project dependencies and assets
```

## Naming conventions

- **Files:** `snake_case` for everything (Dart files, directories, assets).
- **Clases:** `PascalCase`.
- **Features:** Each feature resides in its own directory with subfolders `data/`, `domain/`, and `presentation/` where applicable.
- **Screen widgets:** `_screen.dart` suffix for full screens, `_sheet.dart` for bottom sheets.

## Dependency Injection

The project uses `AppScope` (an `InheritedWidget`) instead of an external DI package. All dependencies are instantiated in `main.dart` and passed down through the widget tree:

```dart
AppScope(
  authRepository: authRepo,
  userRepository: userRepo,
  patientRepository: patientRepo,
  localDatabase: LocalDatabase.instance,
  syncEngine: syncEngine,
  child: const MyApp(),
)
```

To access a dependency from any widget:

```dart
final scope = AppScope.of(context);
final user = scope.currentUser;
```