# ADR 005: NFC Payload Format 2

## Status
Proposed. Phase 1 (every build reads format 2, writes format 1) is implemented;
phase 2 (writing format 2) needs the fleet check below and its own change.

## Date
2026-11-17

## Context

The NFC compression audit measured the current pipeline (`JSON map → CBOR →
DEFLATE → AES-256-GCM` in a MIME record) on 600 synthetic records built with the
app's own builders. DEFLATE itself is close to the best general-purpose
compressor at these sizes: zstd, brotli and LZMA2 do not beat it by more than
7 %. What makes the payload large is the method around it:

- **No preset dictionary.** Payloads of 100 to 2,000 bytes give DEFLATE no
  history to draw on: the triage compresses from 122 B to 120 B. Most of what a
  payload holds (keys, codes, frequent values) repeats from one patient to the
  next, which is what a dictionary shared by writer and reader supplies.
- **Values stored as text.** UUIDs of visits and vaccines are 10 % of a
  compressed guardian copy and dates 4 %: as text they are close to
  incompressible.
- **A long record type.** `application/vnd.hwb.triage` and
  `application/vnd.hwb.guardian` cost 29 to 34 bytes per chip.

The guardian copy is where this hurts. Median message sizes: 496 B with no
history, 1,112 B with one consultation and one vaccine. On an NTAG215 (492 B)
not even the base fits in 54 % of the records, and an NTAG216 (872 B) holds a
consultation in practically none (ADR 004, ADR 006).

`dart:io` adds a trap: `ZLibEncoder(raw: true, dictionary: d)` ignores the
dictionary and produces the same bytes as without it. A round-trip test still
passes, because the decoder ignores it too.

## Decision

### Record

One NFC Forum external record (TNF 0x04) per chip:

| Payload | Format 1 (MIME) | Format 2 (external) |
|---|---|---|
| Patient device | `application/vnd.hwb.triage` | `guane.com.co:hwbt` |
| Guardian device | `application/vnd.hwb.guardian` | `guane.com.co:hwbg` |

The record type is also what tells a reader which format it has, and it is the
type string the chip binding of ADR 003 puts in the associated data. The record
overhead drops from 29–34 B to 20–23 B. The domain is Guane's; another owned
domain can replace it before phase 2, never after.

### Payload

The encryption is exactly that of format 1 (`NfcPayloadCodec.seal`/`open`): key
ring, version header from version 1, chip binding, nonce and tag. Only the
plaintext changes:

```
[format = 2][dictionary id][raw DEFLATE stream primed with the dictionary]
```

1. **Map.** The same map format 1 writes: the triage of `NfcTriagePayload`, the
   aliased guardian copy of `NfcGuardianPayload.buildWithinCapacity`. Builders,
   fitting and reconstruction do not change.
2. **Typed CBOR.** For a fixed set of keys per kind of payload
   (`nfc_payload_v2.dart`, `_typing`), a value in exactly the canonical shape is
   stored as what it is. Anything else stays text, so nothing is lost:

   | Shape | Stored as | Triage keys | Guardian-copy keys |
   |---|---|---|---|
   | lower-case UUID | 16-byte string | — | `pid`, `ei`, `vid` |
   | chip UID as read (`04:A1:…`) | byte string | `gUid`, `g2Uid` | `dug` |
   | `YYYY-MM-DD` | days since 1900-01-01 | `dob` | `dob`, `dte` |
   | `YYYY-MM-DDTHH:MM:SS±HH:MM` | [seconds since 2020-01-01, offset / 15 min] | — | `sd`, `ed`, `aat` |
   | digits, no leading zero, ≤ 18 | integer | `docN`, `gPh` | `dn`, `ph`, `rc`, `nit`, `cyc`, `nc` |

3. **DEFLATE with a preset dictionary**, level 9, raw: the stream zlib produces
   after `deflateSetDictionary`, readable by any zlib with
   `inflateSetDictionary` (checked against Python's zlib). Since `dart:io` will
   not prime a raw stream, the writer compresses the dictionary, flushes to a
   byte boundary (`Z_SYNC_FLUSH`) and keeps only what follows; the reader
   inflates its own compressed form of the dictionary first. The stream depends
   only on the dictionary's content, not on how either side compressed it (a
   test reads it after priming at another level).

**Nothing is written that does not read back.** `NfcPayloadV2.encode` decodes
its own output and compares it with the input, strictly on types; when they
differ it throws and the write fails with `NfcWriteException`. Every payload of
the audit corpus (3,000, triage and guardian copies with 0 to 3 consultations
and vaccines) reads back exactly.

### Dictionaries

`nfc_payload_v2_dictionaries.dart` holds them: 8,165 B for the triage and
30,704 B for the guardian copy, the size where each stops gaining (the guardian
copy gains up to the 32 KB DEFLATE window, the triage barely past 8 KB).
`tool/nfc_payload_v2/build_dictionaries_test.dart` builds them, reproducibly,
from the typed CBOR of 400 **synthetic** training records of the audit corpus.

- **No patient data, ever.** The repository and the app are public, and a
  dictionary built from real records would ship fragments of them in every
  install. A dictionary is built from synthetic records, public catalogs (ICD-10,
  vaccines, DIVIPOLA, EPS) and text written for the purpose.
- **A dictionary is part of the format.** Once a build has written with
  dictionary *n*, every later build reads it. A better dictionary gets a new id;
  the bytes of an id never change. Tests pin each one by SHA-256.
- **Dictionary 1 is a candidate until phase 2.** The audit measured it on
  synthetic text. Before it is frozen, measure real note lengths with
  `tool/nfc_measure` (audit recommendation 3) and decide whether to rebuild it.

### What was left out, and why

| Option | Measured effect | Why not now |
|---|---|---|
| zstd or brotli with a dictionary | 8–19 % smaller guardian copy, worse triage | Native library on Android and iOS for a single-digit gain over DEFLATE with a dictionary |
| Integer keys and default omission | 2–4 % once there is a dictionary | The dictionary already makes repeated keys and defaults cheap |
| Catalog codes for vaccines, diagnoses, places | 4–6 % once there is a dictionary (13–15 % without one) | The app would have to ship and maintain the catalogs |
| Shorter AES-GCM nonce or tag | 4–7 B | Security trade-off; the 28 B are the standard parameters |

## Measured effect

Median / 90th percentile / maximum of the whole NDEF message, in bytes, on the
200 test records of the audit corpus, measured with this code. *Pessimistic*
assumes the dictionary does nothing for free clinical text and names: they are
measured apart and charged what they cost with no dictionary.

| Payload | Format 1 | Format 2 | Format 2, pessimistic |
|---|---|---|---|
| Triage | 178 / 211 / 242 | 89 / 99 / 130 | 104 / 113 / 136 |
| Guardian copy, no history | 496 / 550 / 652 | 215 / 250 / 286 | 244 / 291 / 344 |
| Guardian copy, 1 + 1 | 1,112 / 1,237 / 1,356 | 375 / 427 / 513 | 618 / 711 / 825 |
| Guardian copy, 3 + 3 | 1,775 / 2,009 / 2,167 | 636 / 736 / 798 | 1,047 / 1,232 / 1,382 |

Guardian copy fitted by the app (`guardianFitBuilder`, `guardianPayloadBudget`),
format 1 → format 2:

| Chip | Base does not fit | Records with ≥ 1 consultation | Consultations kept | Vaccines kept |
|---|---|---|---|---|
| NTAG215 | 54 % → 0 % | 0 % → 88 % | 0.00 → 1.01 | 0.01 → 1.80 |
| NTAG216 | 0 % → 0 % | 1 % → 89 % (all that have one) | 0.01 → 2.27 (all) | 1.03 → 2.35 (all) |

The records are synthetic and their text comes from closed phrase lists, which
the dictionary knows: the real figure for free text lies between the two
columns, and real note lengths decide where.

## Rollout

| Chip written by | Read by builds before this ADR | Read by builds with it |
|---|---|---|
| Format 1 | ✅ | ✅ |
| Format 2 | ❌ (seen as a blank chip) | ✅ |

1. **Phase 1, this change.** Every build reads both formats and writes format 1.
   `--dart-define=HWB_NFC_PAYLOAD_FORMAT=2` makes a build write format 2, for
   field tests with chips that only those test devices read.
2. **Fleet check.** The backend logs `X-App-Version` on login and refresh: wait
   until every device in use runs a build with phase 1. The write-size telemetry
   (`nfc_write_metrics`, payload format 1) shows which chips are written and how
   full they get.
3. **Phase 2, its own change.** Switch the default of `kNfcWriteFormat` to
   format 2. Chips change format as they are rewritten.

Going back to writing format 1 is always possible; dropping the reading of
format 2 is not, while any chip may hold it. The same rule as key rotation
(`nfc-encryption.md`, "Updating the fleet") applies, for the same reason: a build
that cannot read a chip treats it as blank.

## Consequences

- Phase 1 changes nothing on the chips: builds can be mixed.
- A build before phase 1 that meets a format 2 chip sees it as blank. That is
  why phase 2 waits for the fleet check.
- The app carries 38 KB of dictionaries (58 KB of source).
- Each write and each fit estimate compresses the dictionary first: about
  0.2 ms per estimate on a laptop, a few ms on a phone, inside the tap.

## Acceptance

- `test/unit/nfc_payload_v2_test.dart`: exact round trip of triage and guardian
  copies, typed values, values left as text, payloads refused, damaged or
  foreign plaintexts rejected, dictionaries pinned, stream independent of the
  priming.
- `test/unit/nfc_payload_service_test.dart`, group "formato 2": external record
  written and read, a format 1 build reads it, a format 2 build reads format 1,
  the budget of the external record, chip binding with key version 1, devices of
  another patient refused, a damaged record read as blank.
