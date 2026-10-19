# ADR 004: NFC Chip Model for Patient Devices

## Status
Proposed — covers the temporary test batch only; the official chip model and quantity are still to be evaluated

## Date
2026-10-16

## Context
Audit finding `fe-oct26-triaje-no-cabe-en-ntag213`. The triage NDEF message measures 193 B with no allergies and 332 B with 6 allergies and 4 chronic conditions. Usable NDEF capacity by chip:

| Chip | Usable NDEF capacity | Fits the triage message |
|---|---|---|
| NTAG213 | about 137 B | No (not even the empty triage) |
| NTAG215 | about 492 B | Yes |
| NTAG216 | about 872 B | Yes |

## Decision
Patient devices require **NTAG215 or NTAG216**. NTAG213 is not supported.

- Model purchased: NTAG215 (K LAKEY, 50 pcs, black round PVC tags, 25 mm, 504 B total memory) — supplier / order reference: none; label code X0032K29BT. Temporary test batch only: 22 units in use for field and lab testing, the rest kept as spare.
- Existing NTAG213 stock: none. No NTAG213 tag is in use or in stock; if any is found, it is withdrawn and not issued.
- date: 2026-10-19 — approval covers the test batch only. The official chip model and quantity are still to be evaluated before the project goes live.

## What the app already does
- `nfc_triage_payload.dart` documents the NTAG215/216 requirement.
- `NfcPayloadService` measures the whole NDEF message against the capacity the chip reports and throws `NfcPayloadTooLargeException` with the sizes; on a chip of 180 B or less the message says that an NTAG213 was detected and that NTAG215/216 must be used.
- Guardian cards are fitted to the chip's real capacity (`buildWithinCapacity`); the triage payload is not trimmed, by design.

## Consequences
- A tap with an NTAG213 fails with a clear message instead of a write error halfway.
- Any future triage field has to be checked against the 492 B of NTAG215, the smaller of the two supported chips.