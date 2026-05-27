# Health Without Borders - Frontend

![Flutter](https://img.shields.io/badge/Flutter-3.41.5-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.8.0-0175C2.svg)
![License](https://img.shields.io/badge/license-MIT-green)
[![codecov](https://codecov.io/gh/guane-hwb/health-without-borders-frontend/graph/badge.svg)](https://codecov.io/gh/guane-hwb/health-without-borders-frontend)

Cross-platform mobile and web client for the Health Without Borders initiative.

## Core Principles

- Offline-first UX for constrained connectivity environments.
- Strong API contract discipline with `health-without-borders` backend.
- Open-source governance and review standards aligned with backend repo policy.

## Tech Stack

- Flutter 3.41.5 (via FVM)
- Dart 3.8.0
- Target platforms: iOS, Android, macOS, Web

## Repository Structure

```
health-without-borders-frontend/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   └── docs.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/
│   ├── index.md
│   └── development/
│       ├── setup.md
│       ├── qa-plan.md
│       └── figma-to-flutter.md
├── lib/
├── test/
├── cloudbuild.pr.yaml
├── cloudbuild.yaml
├── mkdocs.yml
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
└── LICENSE
```

## Quick Start

```bash
# 1) Install pinned Flutter SDK
dart pub global activate fvm
~/.pub-cache/bin/fvm install 3.41.5
~/.pub-cache/bin/fvm use 3.41.5

# 2) Install dependencies
~/.pub-cache/bin/fvm flutter pub get

# 3) Run app (example: macOS)
~/.pub-cache/bin/fvm flutter run -d macos
```

## QA and Contribution Policy

- Open PRs against `develop`.
- Use the PR template in `.github/PULL_REQUEST_TEMPLATE.md`.
- Follow `docs/development/qa-plan.md` before requesting review.

## Design Source of Truth

Design work is maintained in Figma.
Implementation guidance lives in `docs/development/figma-to-flutter.md`.

## License

This project is licensed under the MIT License.
