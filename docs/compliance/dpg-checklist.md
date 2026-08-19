# DPG Compliance Checklist — Health Without Borders (Frontend / Flutter client)

Health Without Borders ships as two repositories — a FastAPI backend and this Flutter client —
that are assessed against the [Digital Public Goods Standard](https://digitalpublicgoods.net/standard/)
separately, because several indicators land on one side only (e.g. the API is what exposes
non-PII data; the client is what encrypts data at rest on the device). This checklist scores
each of the nine indicators **as they apply to this repository specifically**; where the
underlying mechanism actually lives in the backend, the note says so and points there instead of
this repo claiming credit for work it doesn't do.

- **Status legend:** ✅ Met · 🟡 Partial · 🔴 Gap

| #  | DPG Standard indicator | Status | What this repo actually does |
|----|------------------------|--------|-------------------------------|
| 1  | Relevance to the SDGs (SDG 3 — Health) | ✅ Met | This is the field tool brigades use: NFC-based patient registration, offline consultations/vaccines, and guardian consent capture for migrant and pediatric populations. |
| 2  | Use of an approved open license | ✅ Met | MIT (`LICENSE`), independent of the backend's own licensing. |
| 3  | Clear ownership | ✅ Met | `PROJECT_CHARTER.md` names guane emerging technologies as owner and lays out the trademark policy for "Health Without Borders" / "HWB" separately from the code license. |
| 4  | Platform independence | ✅ Met | One Flutter codebase ships to iOS, Android, macOS, Linux, Windows and Web (`pubspec.yaml`, per-platform runners in the repo). The only hard platform dependency is NFC hardware itself, which is inherent to the feature, not a vendor lock-in — the web build falls back to a no-op NFC stub (`nfc_service_stub.dart`) rather than failing. |
| 5  | Documentation | ✅ Met | MkDocs site (`mkdocs.yml`) covers local setup, project structure, offline-sync design, and the domain-model contract with the backend — published from `docs/`. |
| 6  | Mechanism for extracting non-PII data | 🟡 Partial | The actual extraction mechanism (the aggregated stats API) lives in the backend repo, not here. This repo only surfaces it: `StatsRepository` calls it and the brigade-metrics screen renders it. Marked Partial rather than Met because this repository, on its own, doesn't expose the data — it depends on the backend being deployed and reachable. |
| 7  | Adherence to privacy & applicable laws | ✅ Met | Guardian consent is captured and stored per Ley 1581/2012 (`GuardianConsent`, signature capture); Android's `data_extraction_rules.xml` explicitly excludes app data from cloud backup and device-transfer so PHI never leaves the device outside the app's own sync path. |
| 8  | Adherence to standards & best practices | ✅ Met | `patient_record.dart` mirrors the backend's FHIR R4 / RDA schemas field-for-field so the two repos can't silently drift; `flutter analyze` + `flutter test` + coverage gate every PR (`ci.yml`, `cloudbuild.pr.yaml`). |
| 9a | Do No Harm — Data Privacy & Security | ✅ Met | This is where the client carries the most weight: local SQLite is AES-256-GCM encrypted at rest (`LocalDatabase`), NFC wristband/card payloads are separately AES-256-GCM encrypted with per-org keys (`NfcPayloadCodec`), auth tokens sit in OS-level secure storage, UI is gated by role (`UserRole`), and any guardian-absent "emergency access" view is logged locally and synced for audit (`logEmergencyAccess`). |
| 9b | Do No Harm — Inappropriate & Illegal Content | 🟡 Partial | There's no open posting surface — the only free-text is clinician-entered clinical notes (optionally via speech-to-text). Still open: a one-line statement in the docs saying this explicitly, so it's not just implicit from reading the code. |
| 9c | Do No Harm — Protection from Harassment | ✅ Met | Same `CODE_OF_CONDUCT.md` and enforcement contact as the backend; this repo has no separate community space, so nothing extra to moderate here. |

## Action plan for open gaps
- [ ] Add a short "no user-generated content" note to `docs/` covering the clinical free-text/voice-dictation fields. *(indicator 9b)*
- [ ] Cross-link this checklist and the backend's checklist for indicator 6, so a reader of either one knows the extraction mechanism itself is documented on the backend side.
- [ ] Have the privacy & security mentor review indicator 7 and 9a specifically against `data_extraction_rules.xml`, `NfcPayloadCodec`, and `LocalDatabase`'s key-handling.