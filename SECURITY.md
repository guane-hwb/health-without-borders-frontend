# Security Policy

## Supported Versions

Only the latest `develop` and current production release branch are supported.

## Reporting a Vulnerability

Please report vulnerabilities privately to `support@guane.com.co`.
Do not open public GitHub issues for sensitive vulnerabilities.

## Frontend Security Baseline

- Do not hardcode secrets, API keys, or credentials in source control.
- Keep environment-specific values outside the repository.
- Use secure storage for local tokens where applicable.
- Avoid logging PII/PHI in debug logs and analytics events.
- Keep dependencies updated and review advisories regularly.
