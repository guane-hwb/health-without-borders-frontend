# Format 2 dictionaries

`build_dictionaries_test.dart` writes
`lib/src/core/nfc/nfc_payload_v2_dictionaries.dart`: the preset dictionaries
NFC payload format 2 compresses with (ADR 005), one for the patient device's
triage and one for the guardian copy.

It is not part of the test suite: it lives outside `test/` and skips itself
unless `HWB_NFC_CORPUS` names the input.

## Rules

- **Synthetic input only.** The dictionaries ship inside a public app. Never
  build them from patient records, not even de-identified ones: fragments of
  them would be in every install.
- **Never change an id that was written with.** Once a build writes format 2
  with dictionary *n*, every later build must read dictionary *n*. A new
  dictionary takes a new id (and `kNfcV2…DictionaryId` moves to it); the old one
  stays in the file. `test/unit/nfc_payload_v2_test.dart` pins every dictionary
  by SHA-256 so a regeneration cannot replace one silently.
- **Dictionary 1 is frozen by phase 2 of ADR 005.** Builds write format 2 with
  it, so it is never rebuilt in place: a better one takes a new id.

## Input

The synthetic corpus of the NFC compression audit: one JSON object per line
with `split` (`train` or `test`), `triage` (the map `NfcTriagePayload` builds)
and `g` (the guardian copies, with `full` being the unaliased map of
`NfcGuardianPayload.buildGuardianPayload`). The audit's harness generates it
with the app's builders from invented records (seed 1 for the 400 training
records, seed 2 for the 200 test records). Only the training records are used.

## What it does

1. Encodes each training payload as format 2 does before compression
   (`NfcPayloadV2.typedCbor`; guardian copies are aliased first, as the app
   writes them).
2. Shuffles the samples with a fixed seed (7) and concatenates them up to 8 KB
   for the triage and 32 KB for the guardian copy, the sizes where each stops
   gaining (ADR 005).
3. Writes the Dart file with the base64 of each dictionary and its SHA-256.

The same input gives the same file, byte for byte.

## Running it

```bash
HWB_NFC_CORPUS=/path/corpus.jsonl \
fvm flutter test tool/nfc_payload_v2/build_dictionaries_test.dart
fvm dart format lib/src/core/nfc/nfc_payload_v2_dictionaries.dart
```

The SHA-256 the test expects lives in `test/unit/nfc_payload_v2_test.dart`, not
in the generated file, so a regeneration that changes a dictionary fails the
test. Update it there only for a dictionary no chip has been written with, and
say why in the pull request.
