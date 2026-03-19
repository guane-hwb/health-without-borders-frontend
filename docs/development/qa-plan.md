# QA and Pull Request Workflow

## Local Quality Gates

Run before opening a PR:

```bash
~/.pub-cache/bin/fvm flutter analyze
~/.pub-cache/bin/fvm flutter test
```

## PR Policy

- Open PRs against `develop`
- Use `.github/PULL_REQUEST_TEMPLATE.md`
- Include test evidence

## CI/CD Policy

- Primary quality gates run in **Cloud Build**
- GitHub Actions remains a **manual backup**
