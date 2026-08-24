# Contributing to Health Without Borders — Frontend

First off, thank you for considering contributing to Health Without Borders! It's people like you that make open source tools for humanitarian aid possible.

We welcome contributions of all kinds: bug reports, feature requests, documentation improvements, and code patches.

## 1. Where do I go from here?

If you've noticed a bug or have a feature request, please open an issue on our GitHub repository. If you want to contribute code, check our issues board for issues labeled `good first issue` or `help wanted`.

## 2. Local Setup

To start contributing, you'll need to set up your local environment. We use Flutter (pinned via FVM) for the mobile and web client.

Please refer to our **[Local Setup Guide](docs/development/setup.md)** for step-by-step instructions on installing the pinned Flutter SDK, configuring environment variables, and running the app on your target platform.

## 3. Pull Request & QA Workflow

We take code quality seriously, especially because this app handles sensitive medical data for vulnerable populations.

Before you write any code, please read our **[Quality Assurance and PR Workflow](docs/development/qa-plan.md)**. Key takeaways from the QA plan:

- **Branching:** Always branch off and open your Pull Requests against the `develop` branch.
- **Testing:** Ensure all local tests pass (`fvm flutter test`) and static analysis is clean (`fvm flutter analyze`) before opening a PR.
- **Design:** Align with the Figma source of truth before implementing new screens or modifying existing UI. Implementation guidance lives in `docs/development/figma-to-flutter.md`.

## 4. Code of Conduct

This project and everyone participating in it is governed by the **[Health Without Borders Code of Conduct](CODE_OF_CONDUCT.md)**. By participating, you are expected to uphold this code.
