# ADR 006: What the Guardian Copy Carries

## Status
Proposed — needs a product decision on each group below

## Date
2026-11-17

## Context

The guardian device holds a bounded copy of one patient's record
(`NfcGuardianPayload.buildGuardianPayload`): the shape of
`PatientFullRecord.toJson()` without the consent signature and without the AI
metadata of diagnoses, with at most the three most recent consultations and the
three most recent vaccines. Offline, the app opens that copy **editable** when it
belongs to the patient device just scanned (`read_nfc_screen.dart`), and what is
edited there syncs later through the backend merge
(`app/services/record_merger.py` in the backend repository).

Guardian devices are NTAG215 (492 B of NDEF) or NTAG216 (872 B) (ADR 004). The
NFC compression audit measured the copy on a synthetic corpus built with the
app's own builders (200 test records, the app's DEFLATE, the app's capacity
budgets of 458 B and 838 B):

- without any history the copy needs 496 B (median, whole NDEF message), so on an
  NTAG215 not even that fits in 54 % of the records;
- one consultation and one vaccine need 1,112 B (median), so an NTAG216 holds a
  consultation in practically no record;
- with three consultations and three vaccines, after DEFLATE, consultations are
  61 % of the bytes, free clinical text 32 % and the identifiers of visits and
  vaccines 10 %.

The audit's main lever is the encoding (ADR 005, proposed in its own pull
request: dictionary, typed values and a shorter record type). This ADR covers the other lever, which only product can
pull: **what the copy needs to carry for offline care**. Every field it carries
costs space on a device that is already short of it, and data minimization is a
goal of its own for a record held on a device the guardian keeps.

## What each group costs and what removing it would do

Cost: bytes saved by leaving the group out, after DEFLATE, median over the
records that have it (from the audit's harness, current encoding).

| Group | Fields | Shown by the app | If the copy omits it, the sync… | Cost, 1 + 1 | Cost, 3 + 3 |
|---|---|---|---|---|---|
| Item identifiers | `medicalHistory[].encounterIdentifier`, `vaccinationRecord[].vaccinationId` | Nowhere; sync identity only | Derives a deterministic id (`hwb-derived-`, UUIDv5 of patient and item) and adopts the stored id when exactly one stored item matches: same `startDateTime` for a visit, same date, vaccine code and dose for a vaccine (`adopt_stored_item_ids`). An ambiguous match is appended as a new item. | 29 B + 29 B | 83 B + 83 B |
| Prescriptions | `medicalHistory[].prescriptions` | **Nowhere**: captured in `add_consultation_screen.dart`, never displayed | Keeps the stored visit; a top-level field the device leaves empty is not an edit (`_edited_fields`). Safe. | 80 B | 112 B |
| Practitioner | `medicalHistory[].practitioner` | Consultations tab | Same as prescriptions. Safe. | 30 B | 62 B |
| Provider | `medicalHistory[].provider` | Consultations tab | Same. Safe. | 39 B | 49 B |
| Payer | `medicalHistory[].payer` | Consultations tab | Same. Safe. | 14 B | 18 B |
| Vaccinator and site | `vaccinationRecord[].administratedBy`, `administratedAt` | Site in the vaccines tab; **vaccinator nowhere** | Keeps the stored vaccine. Safe. | 29 B | 60 B |
| Consent details | `guardianInfo.consent`, `guardian2Info.consent` | Summary tab, edit-guardian sheet | Restores the stored consent when the guardian is the same person, the copy carries none **and the stored consent has a signature** (`_preserve_consent_signature`). An unsigned stored consent is erased. | 28 B | 27 B |
| Guardian documents | `documentType`, `documentNumber` of each guardian | Summary tab, edit-guardian sheet | **Erases them on the server**: `guardianInfo` is taken from the incoming payload. Needs a preservation rule in the backend first. | 13 B | 12 B |
| Address detail | `patientInfo.address.street`, `cityCode`, `zone` | Summary tab, edit-address sheet | **Erases them on the server**: `patientInfo` is taken from the incoming payload. Needs a preservation rule in the backend first. | 13 B | 12 B |
| Diagnoses (reference) | `medicalHistory[].diagnosis` | Consultations tab | Keeps the stored visit. | 45 B | 87 B |
| Clinical text (reference) | `medicalHistory[].clinicalEvaluation` | Consultations tab | All or nothing: inside `clinicalEvaluation` every difference counts as an edit, so dropping one note would report `visit_edit_not_applied` on every sync. | 295 B | 582 B |

"Safe" means the server cannot lose data: the stored item wins on a key match
and an omitted top-level field is not counted as an edit. It does not mean the
offline profile is unchanged: whatever the copy omits, the offline profile does
not show.

## Options

Measured capacity of each option with the current encoding and the fitting rule
that gives back entries that still fit (PR #182). Consultations and vaccines are
averages over the 200 records; the most this history allows is 2.27 and 2.35.

| Option | Removes | NTAG215: base does not fit | NTAG215: vaccines | NTAG216: records with ≥ 1 consultation | NTAG216: consultations |
|---|---|---|---|---|---|
| A. As today | — | 54 % | 0.01 | 0 % | 0.01 |
| B. Identifiers | item identifiers | 54 % | 0.08 | 2 % | 0.02 |
| C. History fields | B + practitioner, provider, payer, vaccinator and site | 54 % | 0.35 | 8 % | 0.08 |
| D. Declarative | consent details, guardian documents, address detail | 4 % | 0.24 | 2 % | 0.02 |
| E. C + D | all of the above | 4 % | 1.31 | 22 % | 0.22 |

Content alone does not make a consultation fit in an NTAG215, and it moves an
NTAG216 from 0 % to at most 22 % of records with a consultation. Clinical text is
what fills the device, and it can only be kept or dropped whole. The encoding of
ADR 005 shrinks every row of the first table; the two decisions add up and the
combination should be measured once both are taken.

## Proposal (for decision)

1. **Prescriptions.** No screen shows them today. Either the offline profile
   shows them (a UI change, then they stay) or the copy stops carrying them
   (safe for the sync, 80–112 B).
2. **Vaccinator.** Not shown anywhere: stop carrying `administratedBy` (safe).
3. **Practitioner, provider, payer, vaccination site.** Shown offline but
   administrative rather than clinical. Product decides whether offline care
   needs them; removing them is safe for the sync.
4. **Item identifiers.** Keep for now. Removing them saves about 10 % but makes
   the sync depend on matching by start time or by date, vaccine and dose, and on
   the app's in-place edit of the last visit doing the same. Revisit only if the
   device is still short after ADR 005, with tests on both sides first.
5. **Consent details.** The backend restores them only when the stored consent is
   signed. Before dropping them, either confirm that every stored consent has a
   signature or extend that rule to unsigned consents; then product decides
   whether the offline profile needs to show the consent.
6. **Guardian documents and address detail.** Only after the backend preserves
   them when the copy omits them, as it already does for the consent signature.
7. **Clinical text and diagnoses.** Keep, whole.

## Consequences

- The on-chip format does not change: an omitted field is absent, and every
  build already reads an absent field as its default. Old and new builds can be
  mixed.
- Every removal changes what the offline profile shows, for every patient, and
  the user guide has to say so.
- A field removed today cannot be restored offline later: the copy only holds
  what it was written with. Choices that favor clinical content over
  administrative content are the reversible ones.
- The numbers come from synthetic records. Before deciding on the identifiers or
  on the clinical text, measure the real distribution of sizes with the
  measurement tooling of the audit's recommendation 3.

## How the numbers were measured

The NFC compression audit's harness (published in its own PR) generates 600
synthetic records with the app's builders, keeps 200 for measurement, removes
each group from the guardian copy, encodes it exactly as the app does (alias,
CBOR) and compresses it with the app's `ZLibEncoder` in Dart. Capacity uses the
app's budgets (`guardianPayloadBudget`: 458 B and 838 B) and the AES-GCM
overhead of 28 B. The fields each screen uses come from the presentation code
(`lib/src/features/nfc/presentation/`); the sync behavior, from the backend's
`record_merger.py` and `app/schemas/patient.py`.
