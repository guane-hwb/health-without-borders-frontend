# NFC size options: results

Synthetic corpus of 100 patients (seed 20261117, text scale 0.3), written by `gen_corpus.py`; every size is measured with the app's own code. Sizes are bytes of the NDEF message (payload, AES-GCM seal with the key header, and the NDEF record) unless a table says otherwise. "Normal" and "long" are the two text variants of the corpus; a full copy is 3 consultations and 3 vaccines.

## 1. Calibration: format 1 as written today, against the 21 Oct 2026 analysis

| Measure | 21 Oct 2026 (its corpus, develop `e6f31b5`) | This corpus (format 1 as written today) |
|---|---|---|
| Triage message, median (B) | 263 | 253 |
| Triage with 0, 1, 2 and 3 allergies, min–max (B) | 171–306 · 211–296 · 248–344 · 289–339 | 168–290 · 211–339 · 227–333 · 292–365 |
| Constructed cases with 3, 5 and 8 allergies, 4 chronic conditions and 2 guardians (B) | 362 · 412 · 472 | 356 · 410 · 496 |
| Full copy, CBOR before compression, median (B) | 4,164 | 4,802.5 |
| Full copy, compressed, median (B) | 2,212 | 2,435.5 |
| Full copy with long text, maximum (B) | 3,318 | 3,614 |
| 10 consultations with long text, maximum (B) | 5,715 | 6,023 |
| NTAG216: copies that fit at all (of 100) | 2 | 57 |
| DESFire EV3 2K: median kept, normal · long text (consultations+vaccines) | 1+2 · 0+1 | 1+2 · 0+1 |
| DESFire EV3 4K: full copies, normal and long text (of 100) | 100 | 100 and 100 |

The 21 Oct figures are quoted as that analysis gives them; its copy sizes may be encrypted payloads (34 B less than the message).

## 2. Format 2 as built, and how much of it is free text

| Measure | Normal text | Long text |
|---|---|---|
| Full copy, median (B) | 1,852.5 | 2,550 |
| Full copies within the NTAG216 message, 868 B (of 100) | 0 | 0 |
| Full copies within the DESFire EV3 2K message, 1,900 B (of 100) | 63 | 0 |
| Share of the copy that is free clinical text (%) | 29.4 | 48.7 |
| Characters of free clinical text per copy, median | 1,440.5 | 4,258.5 |
| What format 2 spends on that text (bits per character) | 3.00 | 2.34 |
| The same, per word (bits) | 17.1 | 13.4 |

## 3. Levers on the guardian copy (format 2 with dictionary 1)

| Lever | Normal, median (B) | Change (%) | Within 2K (of 100) | Long, median (B) | Change (%) | Within 2K (of 100) | Long, maximum (B) |
|---|---|---|---|---|---|---|---|
| Format 2 as built | 1,852.5 | — | 63 | 2,550 | — | 0 | 2,853 |
| Phones stored as digits only | 1,842.5 | -0.5 | 67 | 2,548.5 | -0.1 | 0 | 2,847 |
| Text rebuilt from catalogs the app ships (vaccine, country) | 1,822 | -1.6 | 71 | 2,513 | -1.5 | 0 | 2,829 |
| Text rebuilt from an ICD-10/ICD-11 catalog (diagnosis, coded conditions) | 1,742.5 | -5.9 | 90 | 2,453.5 | -3.8 | 0 | 2,715 |
| Text rebuilt from a DANE catalog (city, department) | 1,839 | -0.7 | 67 | 2,540 | -0.4 | 0 | 2,847 |
| All derivable text (the three catalogs) | 1,699.5 | -8.3 | 95 | 2,412.5 | -5.4 | 0 | 2,687 |
| Free clinical text only in the most recent consultation | 1,529 | -17.5 | 100 | 1,827.5 | -28.3 | 70 | 2,144 |
| Each free clinical text field cut to 160 characters | 1,811.5 | -2.2 | 75 | 1,884.5 | -26.1 | 55 | 2,178 |
| No free clinical text at all (ceiling) | 1,308.5 | -29.4 | 100 | 1,308.5 | -48.7 | 100 | 1,576 |
| ADR 006, option C | 1,621 | -12.5 | 100 | 2,304.5 | -9.6 | 0 | 2,641 |
| ADR 006 (C) + text only in the latest consultation | 1,261 | -31.9 | 100 | 1,571.5 | -38.4 | 100 | 1,880 |
| Phones + app catalogs + ADR 006 (C) + text only in the latest | 1,222 | -34.0 | 100 | 1,533.5 | -39.9 | 100 | 1,835 |
| Everything above except the text cap and the ceiling | 1,119 | -39.6 | 100 | 1,413 | -44.6 | 100 | 1,693 |

"Within 2K" counts full copies whose message fits the ~1,900 B of a DESFire EV3 2K.

## 4. What surrounds the payload

Measured with the app's code: the seal adds 31 B (AES-GCM nonce and tag, and the 3-byte key header); format 2's external record adds 20 B to a payload of up to 255 B and 23 B to a longer one. An NDEF record with no type (TNF unknown) adds 3 and 6 B, and merging the key header with the format and dictionary bytes would save 3 B more.

| Wrapping | Full copy, normal, median (B) | Triage, median (B) | Triage within NTAG213 (of 100) |
|---|---|---|---|
| Format 2 as built (external type) | 1,852.5 | 183.5 | 19 |
| Record with no type | 1,835.5 | 166.5 | 25 |
| Record with no type, merged header | 1,832.5 | 163.5 | 28 |

## 5. Levers on the triage (patient device)

| Lever | Median (B) | Maximum (B) | Within NTAG213, 137 B (of 100) |
|---|---|---|---|
| Format 2 as built | 183.5 | 297 | 19 |
| Guardian phone as digits | 178.5 | 289 | 21 |
| + chronic conditions as ICD-10 codes | 157 | 234 | 37 |
| + record with no type and merged header | 137 | 214 | 50 |
