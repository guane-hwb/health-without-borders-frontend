# QA and PR Flow

## Local Quality Gates

Run the following commands before opening any PR. CI will run them automatically, but it's faster to detect issues locally.

```bash
# Static Dart Analysis
~/.pub-cache/bin/fvm flutter analyze

# Full Test Suite
~/.pub-cache/bin/fvm flutter test
```

Both should pass without errors or new warnings.

## Branch Policy

| Branch | Purpose |
|---|---|
| `main` | Production and stable code. PRs only from `develop`. |
| `develop` | Integration branch. Feature PRs go here. |
| `feat/<nombre>` | Individual feature branches. |

**Normal Flow:**

```
feat/my-feature → develop → main
```

Always open pull requests against `develop`. Only the lead team merges `develop` into `main`.

## Pull Request Template

Use the template in `.github/PULL_REQUEST_TEMPLATE.md`. Include:

- Description of the change and its motivation.
- Screenshots or video if there are visual changes.
- Testing checklist (unit, widget, manual on physical device).
- Reference to the Jira/Linear issue or task.

## CI/CD

The repository has two pipelines:

### `docs.yml` — Documentation Publish

This pipeline runs on every push to `main` or `develop`, and manually from Actions. Deploy this documentation to GitHub Pages using MkDocs Material.

### `ci.yml` — Quality gates (manual backup)

Backup pipeline that executes `flutter analyze` and `flutter test`. Currently, it is manually triggered (`workflow_dispatch`). The main CI/CD pipeline runs on **Cloud Build** (GCP).

## Test Coverage

The current suite covers:

- `test/unit/login_unit_test.dart` — login logic and session parsing.
- `test/unit/home_screen_test.dart` — initial state of the home screen.
- `test/unit/porfile_tab_summary_test.dart` — profile summary tab logic.
- `test/widget/login_widget_test.dart` — login form rendering.
- `test/widget/home_screen_widget_test.dart` — home widget tree.
- `test/widget/porfile_tab_summary_widget_test.dart` — Summary tab rendering.

To add tests, follow the existing structure and place the files in `test/unit/` or `test/widget/` as appropriate.

## Linting

Analysis rules are in `analysis_options.yaml`, which extends `flutter_lints`. Avoid silencing warnings with `// ignore:` without documented justification in the same comment.