# NFC compression audit: the benchmark

Everything needed to reproduce the figures of
`docs/architecture/nfc-compression-audit.md`,
from a synthetic corpus to `results.md`. All data is invented; nothing here
reads or needs patient records.

| File | Step | What it does |
|---|---|---|
| `corpus_test.dart` | 1 | Generates 600 synthetic records (400 training, 200 test) with the app's own builders and writes the payload maps, the app's CBOR bytes and what `buildWithinCapacity` keeps today. |
| `bench.py` | 2, 4, 5 | Reproduces the app's CBOR byte for byte, builds the alternative encodings and dictionaries, measures zstd, brotli, LZMA2 and a context-model reference, prepares the DEFLATE jobs and writes the report. |
| `deflate_jobs_test.dart` | 3 | Compresses every prepared payload with the app's own `dart:io` zlib, with and without a dictionary, round-tripping each one. |
| `results.md` | — | The report this benchmark produced for the audit (step 5). |

The Dart steps are not part of the test suite: they live outside `test/` and
skip themselves unless `HWB_AUDIT_OUT` is set.

## Requirements

- Flutter as pinned in `.fvmrc` (`fvm flutter …`), and `.env` / `.env.production`
  present as for any local test run.
- Python 3.14 or later (`compression.zstd`); no packages beyond the standard
  library.
- The `brotli` command-line tool (`brew install brotli`).

## Running it

From the repository root, with an empty output directory:

```bash
export HWB_AUDIT_OUT=/tmp/nfc-audit && mkdir -p "$HWB_AUDIT_OUT"
ALIAS=lib/src/core/nfc/nfc_guardian_alias.dart

# 1. Corpus
fvm flutter test tool/nfc_compression_audit/corpus_test.dart

# 2. Encodings, dictionaries, non-DEFLATE compressors, DEFLATE jobs
python3 -I tool/nfc_compression_audit/bench.py prep  "$HWB_AUDIT_OUT" $ALIAS
python3 -I tool/nfc_compression_audit/bench.py prep2 "$HWB_AUDIT_OUT" $ALIAS
python3 -I tool/nfc_compression_audit/bench.py prep3 "$HWB_AUDIT_OUT" $ALIAS

# 3. DEFLATE with the app's zlib
for j in jobs jobs2 jobs3; do
  HWB_AUDIT_JOBS=$j fvm flutter test tool/nfc_compression_audit/deflate_jobs_test.dart
done

# 4–5. Report
python3 -I tool/nfc_compression_audit/bench.py report "$HWB_AUDIT_OUT" $ALIAS
```

`$HWB_AUDIT_OUT/results.md` is the report. Every step is deterministic (fixed
seeds, no clock), so the same code gives the same numbers; a difference from
the committed `results.md` means the app's builders, codec or alias table
changed. The whole run takes about five minutes on a laptop, most of it in
step 2 (brotli runs once per payload and the context model is pure Python).

## What the steps measure

- **Validation.** `bench.py` aborts unless its CBOR equals the app's for all
  3,000 payloads, and `deflate_jobs_test.dart` fails on any round trip that does
  not give back the input.
- **Encodings.** T0/G0 are the app's payloads. T1/G1 drop keys whose absence
  leaves what the app reconstructs identical (checked record by record in step
  1). T2/G2 replace key names with integers. T3/G3 store UUIDs, chip UIDs,
  dates, date-times and digit strings as typed values. T4/G4 also replace
  catalog values with codes.
- **Dictionaries.** Built from the training split only (shuffled training
  payloads concatenated, or zstd's trained dictionaries) and measured on the
  test split. Since the synthetic text comes from closed phrase lists, the
  report also gives a *pessimistic* figure in which free text and names get
  nothing from the dictionary.
- **DEFLATE with a dictionary.** `ZLibEncoder(raw: true, dictionary: d)`
  ignores the dictionary, which step 3 records. The figures use a raw stream
  primed with the dictionary (no extra bytes), and step 3 also reports the zlib
  format with the dictionary (4 B more).
