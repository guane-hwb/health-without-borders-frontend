# ADR 003: Binding NFC Payloads to the Chip

## Status
Proposed

## Date
2026-10-16

## Context
Audit finding `fe-oct26-payload-nfc-no-ligado-al-chip`: the AES-256-GCM payload is authenticated only with its version header (and with an empty AAD for version 0). It does not include the chip UID, the record type or the time it was written, and chips stay writable. A payload copied to another chip still decrypts, and an old payload put back over a newer one hides what was added since.

Constraint from `docs/architecture/nfc-encryption.md`: every chip in the field is **version 0, headerless**, and no rotation has happened. Builds that predate versioning read version 0 with an empty AAD, so version 0 cannot change until the whole fleet understands a new format. A version 1+ payload is unreadable by older builds already, so no chip of that kind exists in the field.

## Decision
1. **Version 1+ payloads are sealed with the chip UID and the record MIME type as extra AAD** (`chipBindingAad` in `nfc_payload_service.dart`). On read, the service tries that AAD first and then a plain decode, which is what keeps version 0 chips readable. A v1+ payload moved to another chip, or relabelled with another MIME type, fails authentication on both attempts.
2. **Version 0 stays unbound.** The residual risk (cloning a v0 chip to another chip) remains until the deployment rotates to version 1, following the existing fleet rule: keep the current key version at `0` until every device runs a build that understands the ring and the binding. With the backend's ring in its database (KEK mode, as on the pilot) that means not calling `/patients/nfc-keys/rotate` and leaving `NFC_AUTO_ROTATE` off; `NFC_CURRENT_KEY_VERSION` applies only without a KEK.
3. **Writing a bound payload needs the UID.** When `expectedUid` is given the payload is encoded before the tap (the tap is refused on any other chip). Otherwise it is encoded inside the tap, with the chip's real UID.

## Not decided here (needs product / backend input)
- `writtenAt` in the payload. A timestamp alone cannot reveal a replay offline: it only helps when compared with a trusted value (the last version the device synced). Define that comparison before adding the field.
- NTAG21x password protection against malicious erasure. It requires a platform-level write sequence that the current `nfc_manager` wrapper does not expose and has to be validated on real chips.

## Consequences
- Pros: from the first rotation, cloned or relabelled payloads are rejected; version 0 chips keep working; builds can be mixed during the rollout because nothing written today changes.
- Cons: until rotation, the protection does not apply to the chips already in the field. A chip written with binding is read by one more decrypt attempt on failure (negligible). When rotation happens, tests with real chips are required.

## Acceptance
- `test/unit/nfc_chip_binding_test.dart` passes: a v1+ payload does not decrypt with another UID, another MIME type or no AAD; a v0 payload still reads without AAD.
- Before any rotation, run the checklist in the backend NFC key-management runbook and confirm the fleet.