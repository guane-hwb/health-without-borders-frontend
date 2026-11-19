# NFC Compression Audit

**Date:** 2026-11-17 · **Code audited:** frontend `develop` at `25ec698`;
backend `develop` at `d6fd83c` for the sync behaviour · **Benchmark:**
[`tool/nfc_compression_audit/`](https://github.com/guane-hwb/health-without-borders-frontend/tree/develop/tool/nfc_compression_audit) (full tables in its `results.md`)

## Question and short answer

*Does the app use the best available algorithms and methods to compress what it
writes to NFC chips?*

The algorithm, yes; the method around it, no.

- **Algorithm.** Without a dictionary, DEFLATE at level 9 is within 7 % of the
  best general-purpose compressor measured (zstd, brotli, LZMA2). Changing the
  compressor alone gains nothing.
- **Method.** What is missing is what works for payloads of 100 to 2,000
  bytes: a dictionary shared by writer and reader, an encoding without
  redundant fields or values stored as text, a short record type, and a fitting
  rule that does not leave out what fits.

With techniques the app already has, and no new dependency, today's NDEF
messages are **1.6 to 3.2 times** larger than they need to be:

| Whole NDEF message, median | Today | Best practical, optimistic | Best practical, pessimistic |
|---|---|---|---|
| Triage (patient device) | 178 B | 77 B | 90 B |
| Guardian copy, no history | 496 B | 202 B | 268 B |
| Guardian copy, 1 consultation + 1 vaccine | 1,112 B | 352 B | 645 B |
| Guardian copy, 3 + 3 | 1,773 B | 573 B | 1,076 B |

*Best practical* combines typed values without redundant keys, DEFLATE with a
preset dictionary (8 KB for the triage, 32 KB for the guardian copy) and an
external record type, with the same 28 B of AES-GCM. *Pessimistic* assumes the
dictionary does nothing for free clinical text and names (see
[Limits](#limits)).

Where it matters is the guardian copy. Today, on an NTAG215 (492 B), not even
the copy without history fits in 54 % of the records, and on an NTAG216
(872 B) a consultation fits in practically none.

Payload format 2 as implemented (ADR 005, recommendation 2) keeps the key
names, skips integer keys and default omission, which the dictionary makes
cheap, and uses a 17-character external type instead of the 8 characters
measured here. Measured with its own code, its medians are 89 B for the
triage and 375 B for the guardian copy with 1 + 1, against 77 B and 352 B
above.

## Scope

**Read:**

- the write and read paths of both chips: `NfcTriagePayload`,
  `NfcGuardianPayload`, `nfc_guardian_alias.dart`, `NfcPayloadCodec`,
  `NfcPayloadService`, the NDEF record, `guardianPayloadBudget`;
- the screens that write chips (registration, profile actions) and those that
  show what is read;
- the backend merge (`record_merger.py`, `patient_service.py`,
  `schemas/patient.py`), to know what a copy may leave out.

**Out of scope:**

- key management and the design of the encryption (ADR 003,
  `nfc-encryption.md`);
- the UI beyond which fields it shows.

## The pipeline as built

Paths and lines at `25ec698`.

1. **Payload maps.** Two builders produce them:
   - `NfcTriagePayload.buildPatientPayload` writes the triage with
     hand-shortened keys (`fn`, `dob`, `alg`…).
   - `NfcGuardianPayload.buildGuardianPayload` writes the whole
     `PatientFullRecord.toJson()`, minus the consent signature and the AI
     metadata of diagnoses, with at most the three most recent consultations
     and vaccines. `aliasGuardianPayload` then shortens 110 keys and adds a
     `$v: 2` marker.
2. **Encoding** (`nfc_payload_codec.dart`): CBOR (package `cbor` 6.5.1, which
   stores each float in its shortest lossless form), then raw DEFLATE level 9
   (line 236, no dictionary), then AES-256-GCM. The encryption adds a 12-byte
   nonce and a 16-byte tag; from key version 1 on, also a 3-byte `HW` +
   version header, and the chip binding of ADR 003.
3. **Record** (`nfc_payload_service.dart:81`, `:92`): one MIME record of type
   `application/vnd.hwb.triage` or `application/vnd.hwb.guardian`.
4. **Fit** (`nfc_guardian_payload.dart:117-129`): the guardian copy is
   trimmed to the capacity the chip reports, alternating the oldest
   consultation and vaccine and stopping at the first combination that fits.
   The triage is never trimmed.
5. **Read** (`readHwbChip`): find the MIME record, decrypt with the chip
   binding and then without it, inflate, decode the CBOR, rebuild the record.

## Method

**Corpus.** 600 invented records: 400 for training dictionaries and models,
200 for measuring. `corpus_test.dart` generates them with the app's own
builders.

- Fields are filled as the registration, consultation and vaccine screens fill
  them.
- Clinical text is Spanish, combined from phrase lists. Each list has entries
  that appear only in the test split, so dictionaries are not measured against
  their own training data.

**Validation.**

- The benchmark reproduces the app's CBOR byte for byte for all 3,000 payloads
  (triage and guardian copies with 0 to 3 consultations and vaccines).
- Every DEFLATE figure comes from the app's own `dart:io` zlib: Python's zlib
  1.2.12 gives other sizes for the same bytes (−10 to +29 B on a 1 KB payload).
- Every compressed payload with a dictionary was decompressed back and
  compared.

**Encodings measured.**

| | Triage | Guardian copy |
|---|---|---|
| Current | T0 | G0 (G0b: the alias table completed) |
| Without redundant keys: a key is dropped only if what the app reconstructs stays identical, checked record by record | T1 | G1 |
| + integer keys | T2 | G2 |
| + typed values (UUIDs and chip UIDs as bytes, dates as day counts, date-times as minutes and offset, digit strings as integers) | T3 | G3 |
| + catalog codes for closed or public lists | T4 | G4 |

**Compressors.**

- none;
- DEFLATE-9 as today;
- DEFLATE-9 with an 8 KB or 32 KB dictionary made of training payloads;
- zstd 1.5.7 at level 19, with or without a trained dictionary, without its
  4-byte magic number;
- brotli 1.2.0 at quality 11, with or without the same 32 KB dictionary;
- raw LZMA2;
- a context-model reference: bytes context of orders 0–3, Witten-Bell
  interpolation, trained on the training split, ideal arithmetic-coding
  length. A reference for what a trained statistical coder reaches, not a
  theoretical bound.

**Capacity.** The app's budgets, `guardianPayloadBudget`: 458 B on an NTAG215
and 838 B on an NTAG216 (capacity minus the MIME record overhead). Two
algorithms: the app's own, and a full search over (consultations, vaccines)
for what is achievable.

## Results

### Compressors, at equal encoding

Compressed payload, median (90th percentile), current encoding:

| | none | DEFLATE-9 (app) | + dict. 32 KB | zstd-19 | + dict. 32 KB | brotli-11 | + dict. 32 KB | LZMA2 | context model |
|---|---|---|---|---|---|---|---|---|---|
| Triage | 122 (167) | 120 (154) | 48 (61) | 124 (155) | 56 (68) | 121 (156) | 63 (76) | 124 (160) | 28 (36) |
| Guardian 1 + 1 | 1,556 (1,769) | 1,050 (1,175) | 392 (453) | 1,065 (1,192) | 324 (378) | 995 (1,111) | 388 (447) | 1,080 (1,201) | 286 (351) |
| Guardian 3 + 3 | 3,232 (3,799) | 1,711 (1,947) | 662 (779) | 1,719 (1,946) | 560 (657) | 1,590 (1,801) | 646 (758) | 1,708 (1,932) | 564 (682) |

- **Without a dictionary every compressor lands in the same place.** On the
  triage DEFLATE is even the smallest; on the guardian copy brotli saves 5 to
  7 %.
- **With a dictionary, every compressor drops to between 30 % and 52 % of
  its size without one.** zstd with a dictionary is 8 to 19 % smaller than
  DEFLATE with a dictionary on the guardian copy, and larger on the triage.
- **Typed values bring DEFLATE with a dictionary within reach of the context
  model.** With G3 encoding: 531 B against 544 B for 3 + 3, and 310 B against
  277 B for 1 + 1.

### Encodings, with and without a dictionary

DEFLATE-9 as the app runs it, compressed payload median:

| Encoding | Triage | + dict. | Guardian 1+1 | + dict. 32 KB | Guardian 3+3 | + dict. 32 KB |
|---|---|---|---|---|---|---|
| Current (T0/G0) | 120 | 48 | 1,050 | 392 | 1,711 | 662 |
| Complete alias (G0b) | — | — | 1,018 | 390 | 1,671 | 662 |
| No redundant keys (T1/G1) | 118 | 48 | 958 | 388 | 1,608 | 653 |
| + integer keys (T2/G2) | 94 | 46 | 906 | 378 | 1,552 | 634 |
| + typed values (T3/G3) | 72 | 35 | 850 | 310 | 1,452 | 531 |
| + catalog codes (T4/G4) | 70 | 35 | 740 | 293 | 1,248 | 512 |

Triage dictionary: 32 KB in this table; the 8 KB one gives 55, 55, 52, 38 and
37 B.

Without a dictionary, each encoding step saves 2 to 20 %. With one, only typed
values (−16 to −24 %) and, to a lesser degree, catalog codes (up to −6 %)
still count: the dictionary already makes repeated keys and default values
cheap.

### Capacity of the guardian copy

| | Chip | Consultations kept (mean) | Vaccines kept (mean) | With ≥ 1 consultation | Base does not fit |
|---|---|---|---|---|---|
| App today | NTAG215 | 0.00 | 0.01 | 0 % | 54 % |
| App today | NTAG216 | 0.01 | 1.03 | 0 % | 0 % |
| Current encoding, full search | NTAG216 | 0.01 | 2.35 | 0 % | 0 % |
| G3 + dictionary + external type, optimistic | NTAG215 | 1.29 | 2.22 | 88 % | 0 % |
| G3 + dictionary + external type, pessimistic | NTAG215 | 0.02 | 2.34 | 2 % | 0 % |
| G3 + dictionary + external type, optimistic | NTAG216 | 2.27 | 2.35 | 89 % | 0 % |
| G3 + dictionary + external type, pessimistic | NTAG216 | 1.15 | 2.23 | 88 % | 0 % |

At most this history allows 2.27 consultations and 2.35 vaccines on average,
and 89 % of the records have a consultation.

Marginal cost of a consultation and a vaccine, whole message, median:

| | Base, no history | First pair | Each further pair |
|---|---|---|---|
| Today | 500 B | 648 B | 390 B |
| Best practical, optimistic | 206 B | 153 B | 138 B |
| Best practical, pessimistic | 264 B | 391 B | 258 B |

### Where the bytes go

Current guardian copy with 3 + 3, after DEFLATE, share of the total that
removing each part saves:

| Part | Share |
|---|---|
| Consultations (`medicalHistory`) | 61 % |
| Free clinical text | 32 % |
| Vaccines | 12 % |
| UUIDs of visits and vaccines | 10 % |
| Patient info | 9 % |
| Guardian info | 6 % |
| Dates and date-times | 4 % |
| Key names | 3 % |

Removing a part saves less than its own size when it shares text with the
rest, so the shares do not add up to 100 %.

## Findings

**H1. No preset dictionary.**
- *Where:* `nfc_payload_codec.dart:236`, `ZLibEncoder(level: 9, raw: true)`.
- *Effect:* at these sizes DEFLATE has no history of its own. The triage goes
  from 122 B to 120 B; with an 8 KB dictionary, to 55 B, without changing
  anything else. This is the largest lever.

**H2. `dart:io` ignores a dictionary on raw streams.**
- *What happens:* `ZLibEncoder(raw: true, dictionary: d)` returns the same
  bytes as without it, and the decoder ignores it too, so a round-trip test
  passes while the dictionary does nothing.
- *What works:* a raw stream primed by compressing the dictionary and
  flushing with `Z_SYNC_FLUSH` (the stream `deflateSetDictionary` produces,
  readable by any zlib, with no extra bytes), or the zlib format with the
  dictionary (4 B more). The benchmark checked both on 18,060 payloads.

**H3. The fit leaves out what fits.**
- *Where:* `nfc_guardian_payload.dart:117-129`.
- *What happens:* the trim alternates consultations and vaccines and stops at
  the first combination that fits. A consultation is several times larger than
  a vaccine, so vaccines are dropped in step with consultations.
- *Effect:* on an NTAG216 the copy keeps 1.03 vaccines on average where 2.35
  fit.

**H4. Defaults are written.**
- *What:* keys whose absence leaves the reconstructed record identical are
  written to every chip. For example `type: "Consultation"`,
  `careModality: "01"`, `diagnosisType: "01"`, `status: "completed"`,
  `intent: "order"`, `country: "COL"`, `policyVersion: "v1.1"`, and empty lists
  (`riskFactors`, `prescriptions`, `allergies`…).
- *Effect:* 6 to 9 % after DEFLATE, almost nothing once there is a dictionary.

**H5. Values stored as text.**
- *What:* UUIDs of visits and vaccines, dates, date-times and digit strings
  are written as text.
- *Effect:* UUIDs are 10 % of a compressed guardian copy and dates 4 %. Typed
  values save 16 to 24 % even with a dictionary.
- *Alias table:* it misses 9 keys the copy carries (`prescriptions`,
  `frequency`, `duration`, `route`, `intent`, `weight`, `height`,
  `isBloodTypeCertified`, `baseVersion`); completing it saves 2 to 5 %.

**H6. A long record type.**
- *Where:* `nfc_payload_service.dart:81` and `:92`.
- *Effect:* the MIME types cost 29 to 34 B per chip; an 8-character external
  type costs 11 to 14 B.
- *Constraint:* nothing in the OS depends on the type (no NFC intent filters,
  `AndroidManifest.xml:36-45`), but from key version 1 the type is part of the
  chip binding's associated data.

**H7. `btC` is written and never read.**
- *Where:* the triage stores `btC: true` for a blood type confirmed by a test
  (`nfc_triage_payload.dart:40`), but `fromPayload` (`:90`) ignores it.
- *Effect:* a record rebuilt from the patient device alone always shows the
  blood type as reported.

**H8. Nothing measures real payloads.**
- *What:* the size of a write only shows when it does not fit
  (`nfc_guided_write.dart:382`).
- *Effect:* nothing calibrates the decisions above, and the length of real
  clinical notes, which decides most of the remaining uncertainty, is unknown.

**Already right.**
- Serialize, then compress, then encrypt: encrypted bytes do not compress.
- CBOR is about 20 % smaller than JSON.
- Raw DEFLATE carries no checksum of its own, which is correct because
  AES-GCM authenticates.
- Level 9.
- The 28 B of AES-GCM are the standard parameters and should stay.

## Recommendations and where they went

| # | Recommendation | Pull request |
|---|---|---|
| 1 | Fit: give back what still fits after the trim (H3) | guane-hwb/health-without-borders-frontend#182 |
| 2 | Payload format 2: typed values, preset dictionary, external record (H1, H2, H5, H6); phase 1 reads both formats and writes format 1 | guane-hwb/health-without-borders-frontend#185 (ADR 005) |
| 3 | Measure real payloads: write-size telemetry and a tool for existing records (H8) | guane-hwb/health-without-borders-frontend#186 and guane-hwb/health-without-borders#106 |
| 4 | Read `btC` (H7) | guane-hwb/health-without-borders-frontend#183 |
| 5 | Decide what the guardian copy carries offline | guane-hwb/health-without-borders-frontend#184 (ADR 006) |

**Not recommended:**

- **Moving to zstd or brotli:** a native dependency for a single-digit gain
  over DEFLATE with a dictionary.
- **Shortening the AES-GCM nonce or tag:** a security trade-off for 4 to 7 B.
- **Catalog codes for now:** 4 to 6 % with a dictionary, at the cost of
  shipping and maintaining catalogs in the app.

## Limits

- **The records are synthetic.** Relative results hold, because the structure
  of the payloads is the app's own. Absolute sizes, and capacity above all,
  depend on how long real clinical notes are. The marginal costs above let
  them be scaled.
- **Dictionary gains on free text are bounded, not known.** The synthetic text
  comes from closed phrase lists that the dictionary learns. The optimistic
  figure counts that; the pessimistic one gives the text no gain at all. Real
  notes fall in between. The tool of recommendation 3 measures them without
  any record leaving the authorised environment.
- **Chip capacities are those Android reports** (492 and 872 B). Nothing was
  written to a physical chip.
- **The context model is a reference, not a bound.** It is also trained on
  synthetic text.
- **The breakdown of where the bytes go uses Python's zlib.** Read its shares,
  not its byte counts.

## Reproducing it

See [`tool/nfc_compression_audit/README.md`](https://github.com/guane-hwb/health-without-borders-frontend/tree/develop/tool/nfc_compression_audit/README.md).
Every step is deterministic, and `results.md` in that directory is the report
this audit is based on.
