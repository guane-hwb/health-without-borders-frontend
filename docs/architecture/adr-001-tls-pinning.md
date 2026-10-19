# ADR 001: Decision on TLS Certificate Pinning

## Status
Approved

## Date
2026-10-02

## Context
The Health Without Borders mobile application communicates with the backend API over HTTPS. 
An audit finding (`fe-oct26-sin-pinning-tls`) highlighted that the `ApiClient` currently relies on standard system trust stores rather than implementing strict TLS Certificate Pinning.

## Decision
We decided to rely on standard system CA trust stores combined with active client-side transport security controls, while deferring strict Certificate Pinning unless required by enterprise MDM / policy mandates.

The app enforces transport security using the following active mechanisms:
1. **Enforced HTTPS in Release Mode**: `ApiClient` and `AppEnv` reject any `http://` API base URL during release builds, failing closed immediately.
2. **Disabled Redirect Following**: `ApiClient` executes HTTP requests with `followRedirects = false`. Any `3xx` response triggers an `ApiException` regarding untrusted redirects, avoiding portal interception.
3. **Captive Portal Probing**: `Reachability.probe` validates that connection responses yield expected 2xx status codes and JSON headers before attempting sync operations.

## Consequences
- **Pros**:
  - Avoids app bricking during backend SSL certificate rotations or domain migrations in offline/intermittent field environments.
  - Allows field devices managed by enterprise MDM solutions to use private internal CAs when necessary.
- **Cons / Risks**:
  - High-privilege attackers with compromise over a device's root CA store could theoretically intercept traffic.
- **Mitigation**:
  - Sensitive PHI stored on chips and offline database remains independently encrypted with AES-256-GCM.