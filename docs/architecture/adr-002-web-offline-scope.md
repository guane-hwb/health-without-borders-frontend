# ADR 002: Decision on Web Offline Capability and Architecture Scope

## Status
Approved — amended 2026-10-16 (see "Amendment")

## Date
2026-10-02

## Context
Audit finding `fe-oct26-web-no-funciona-offline` noted that the Flutter Web build uses default service worker behavior (unregistering self) and fetches CanvasKit resources from Google CDN (`www.gstatic.com`). Consequently, the Web application shell cannot bootstrap without an initial network connection.

## Decision
We decided to define Flutter Web strictly as an **Online Administrative Console**, while reserving full **Offline-First Field Capabilities** exclusively for the native Android and iOS mobile applications.

### Key Guidelines
1. **Web Scope**: The Web target is intended for organization administrators (`superadmin`, `org_admin`) and web-connected clinical staff conducting online searches, analytics reviews, and user/organization management.
2. **Mobile Scope**: Native mobile applications (Android/iOS) remain the sole offline-first targets equipped with SQLite local storage, encrypted offline queues, and background synchronization drivers.
3. **Service Worker & CDN**: We retain standard online bootstrap mechanics for Web builds rather than bundling self-hosted CanvasKit assets and offline service worker caching in the Web bundle.

## Amendment (2026-10-16): what the Web build still stores locally
The original text said Web eliminates local browser PHI persistence. The code does not support that claim: `LocalDatabase` keeps a Web branch backed by IndexedDB (`hwb_local_store`, via `web_storage_js.dart`), the sync engine starts on every platform, and `web_storage_js.dart` documents that it persists the offline queue and the emergency audit trail on Web.

What is true, and is now the documented behaviour:
- The **application shell** is online-only (guideline 3 is unchanged): without a first connection the Web app does not start.
- Once running, a Web session that loses connectivity **can still queue edits** in IndexedDB. Those records are encrypted with AES-256-GCM before they are stored, and are removed when they sync.
- On Web the AES key that protects that queue lives in the browser (`flutter_secure_storage` on Web keeps it in `localStorage`; tracked separately as a session-storage finding). Encryption at rest on Web therefore protects against casual inspection of IndexedDB, not against script running in the same origin.
- Shared workstations: logout must wipe the queue and the key. This is a release criterion for the Web build, not an assumption.

### Consequences (replaces the original "Pros")
- Simpler deployment, CSP and asset distribution (unchanged).
- Prevents stale web application shells from executing outdated offline logic (unchanged).
- Web does **not** remove PHI persistence in the browser; it limits it to an encrypted, short-lived queue. If that is not acceptable for shared terminals, the alternative is to remove the Web branch of `LocalDatabase` and make Web saves online-only (a code change, to be decided separately).