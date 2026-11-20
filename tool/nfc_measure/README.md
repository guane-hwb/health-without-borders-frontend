# NFC payload measurement on real records

`nfc_measure_test.dart` takes a set of patient records and reports, with the
app's own builders and codec, what the app would write to NFC chips for them:
the size of the patient device's triage, the size of the guardian copy, how much
history the guardian copy keeps on an NTAG215 and on an NTAG216, and how long the
clinical notes are. It prints **aggregates only**.

It exists because the decisions on the NFC payload format (ADR 005) and on what
the guardian copy carries (ADR 006) were sized on synthetic records. The real
distribution of sizes, and above all of clinical text length, is what those
decisions need before anything changes on the chips.

It is not part of the test suite: it lives outside `test/`, so CI never runs it,
and it skips itself unless `HWB_NFC_RECORDS` names an input file.

## Privacy rules

The input is health data. The output is not.

- Run it **only where the records already are allowed to be**: a machine and an
  account authorised for patient data. Do not copy the input anywhere else, and
  delete it when you are done.
- The tool never prints or writes a record, a field value, an identifier or a
  per-record number. Every figure is a count, a share, a mean, a median, a 90th
  percentile or a maximum over all records.
- It refuses to run on fewer than 10 readable records, since a percentile over a
  handful of records describes those records.
- What may leave the authorised environment is the summary JSON.

## Input

A JSON Lines file: one `PatientFullRecord` JSON per line, in the shape the
backend returns from `/api/v1/patients/scan` and the app syncs (the same map
`PatientFullRecord.fromJson` reads). Lines that do not parse are counted as
`unreadable_lines` and skipped.

`sample_records.jsonl` holds 12 **synthetic** records (invented, generated with
the app's builders for the NFC compression audit) to check that the tool runs.

## Running it

```bash
HWB_NFC_RECORDS=/path/authorised/records.jsonl \
HWB_NFC_MEASURE_OUT=/path/authorised/nfc-summary.json \
fvm flutter test tool/nfc_measure/nfc_measure_test.dart
```

With the synthetic sample:

```bash
HWB_NFC_RECORDS=$PWD/tool/nfc_measure/sample_records.jsonl \
fvm flutter test tool/nfc_measure/nfc_measure_test.dart
```

## Output

Sizes are bytes of the whole NDEF message: encrypted payload, the 28 B of
AES-GCM and the MIME record around it, with key version 0 and the current
payload format, which is what every chip in the field holds today.

| Field | Meaning |
|---|---|
| `records`, `unreadable_lines` | Records measured, lines skipped |
| `triage_message_bytes` | Patient device: `n`, `median`, `p90`, `max` |
| `triage_fits` | Share of records whose triage fits each chip, % |
| `guardian_message_bytes_untrimmed` | Guardian copy with 0, 1 and 3 consultations and vaccines, before any trimming |
| `guardian_fit.<chip>` | What `buildWithinCapacity` keeps on each chip, with the app's budget: share of records where not even the base fits, mean consultations and vaccines kept and available (at most 3 each), share with at least one consultation, share partial |
| `history_per_record` | Consultations and vaccines per record |
| `clinical_text_chars` | Length of each clinical note that is not empty, in characters |

## How it feeds the decisions

- **ADR 006** (what the guardian copy carries): `guardian_fit` says how often
  history is left out today, and `clinical_text_chars` how much of the copy is
  free text, the one group that can only be kept or dropped whole.
- **ADR 005** (payload format v2): the audit measured the gain of a shared
  dictionary on synthetic text, between an optimistic and a pessimistic bound.
  Real note lengths and their spread decide where in that range the field is.
  Once the v2 codec is merged, this tool should measure it next to the current
  format.

The field telemetry added in the same pull request (`nfc_write_metrics`) answers
the complementary question: what the app actually wrote, on which chips, since
the build that carries it.
