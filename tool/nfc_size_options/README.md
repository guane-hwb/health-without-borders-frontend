# NFC size options: the measurements

Everything needed to reproduce `docs/architecture/nfc-size-reduction-options.md`,
from a synthetic corpus to `results.md`. All data is invented; nothing here
reads or needs patient records.

| File | What it does |
|---|---|
| `gen_corpus.py` | Writes the synthetic corpus: 100 patients with every field of the app's model filled in, histories of 10 consultations in two text variants (normal and long), extreme triage cases and families of siblings; optionally, the backend's contract fixtures. |
| `common.dart` | Shared helpers: corpus access, the app's builders (triage, guardian copy), ADR 006's option C, and the per-format measurement. |
| `calibration_test.dart` | Format 1 as the app writes it today (codec, fit and MIME record): the figures set against the NFC capacity analysis of 21 Oct 2026. |
| `levers_test.dart` | Each lever on top of format 2, measured with format 2's encoder and dictionary 1, plus the seal and record overheads. |
| `report.py` | Writes `results.md` from the two outputs and the corpus. |
| `results.md` | The report this benchmark produced. |

The Dart steps are not part of the test suite: they live outside `test/` and
skip themselves unless `HWB_CAP_CORPUS` and `HWB_CAP_OUT` are set. They need
format 2 (ADR 005, `lib/src/core/nfc/nfc_payload_v2.dart`).

## Requirements

- Flutter as pinned in `.fvmrc` (`fvm flutter …`), and `.env` /
  `.env.production` present as for any local test run.
- Python 3, standard library only.
- Optional: a clone of `guane-hwb/health-without-borders`, for the contract
  fixtures. The report does not use them; the calibration output gains the
  fixture rows.

## Running it

From the repository root, with an empty output directory:

```bash
export OUT=/tmp/nfc-size && mkdir -p "$OUT"
D=tool/nfc_size_options

# 1. Corpus (add --backend PATH for the contract fixtures)
python3 -I $D/gen_corpus.py "$OUT/corpus.json"

# 2. Format 1 as written today, and the levers on format 2
HWB_CAP_CORPUS="$OUT/corpus.json" HWB_CAP_OUT="$OUT/calibration.json" \
  fvm flutter test $D/calibration_test.dart
HWB_CAP_CORPUS="$OUT/corpus.json" HWB_CAP_OUT="$OUT/levers.json" \
  fvm flutter test $D/levers_test.dart

# 3. Report
python3 -I $D/report.py "$OUT/corpus.json" "$OUT/calibration.json" \
  "$OUT/levers.json" "$OUT/results.md"
```

`$OUT/results.md` is the report. Every step is deterministic: the same seed and
text scale give the same corpus byte for byte, and sizes do not depend on the
AES-GCM nonce. A difference from the committed `results.md` means the app's
builders, codec, format 2 or its dictionary changed. The whole run takes well
under a minute.

## What the corpus is

- **Its model.** The 21 Oct 2026 analysis measured 100 synthetic patients that
  are not versioned anywhere. The corpus follows its description: 49 patients
  with two guardians; 0, 1, 2 and 3 allergies in 34, 23, 31 and 12 of them; one
  consultation each with no diagnosis; histories of 10 consultations taken from
  other patients with 1 or 2 diagnoses; and a long-text variant that joins each
  clinical field with those of two other consultations.
- **Its calibration.** `--escala-texto 0.3` (the default) is the text scale at
  which format 1 lands closest to that analysis; section 1 of `results.md`
  sets the figures side by side.
- **Its vocabulary.** It is Spanish, as the app's users write, and it was
  written apart from the audit's generator, which is what format 2's dictionary
  1 was built from. What the app takes from a catalog (vaccines,
  relationships, document types, allergy categories) comes from the app's
  catalog.
- **Its shapes.** Dates follow `toIso8601WithOffset` (seconds and offset), and
  phones are stored as typed, with spaces and a `+` prefix in about half of
  them. Nationality codes are numeric where the app uses ISO alpha-3 codes; the
  difference is at most 1 B per record.
