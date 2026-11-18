# NFC Payload Size: Options Beyond Format 2

**Date:** 17 November 2026. **Builds on:** [ADR 005](adr-005-nfc-payload-format-v2.md) (format 2), the [NFC compression audit](https://github.com/guane-hwb/health-without-borders-frontend/pull/187) and [ADR 006](https://github.com/guane-hwb/health-without-borders-frontend/pull/184) (what the guardian copy carries). **Measurements:** `tool/nfc_size_options/`, whose report is `tool/nfc_size_options/results.md`.

## Summary

Format 2 brings the guardian copy (3 consultations and 3 vaccines) to a median NDEF message of 1,852.5 B with normal clinical text and 2,550 B with long text. What is left is mostly free clinical text: 29 % of the copy with normal text and 49 % with long text, stored at 3.0 and 2.3 bits per character.

- **Content decisions can still move the chip; encoding no longer can.** Keeping free clinical text only in the most recent consultation, together with ADR 006 option C, takes the copy down 31.9 % (normal text) and 38.4 % (long text). Every full copy in the corpus then fits a DESFire EV3 2K, long text included: the largest is 1,880 B of ~1,900 B. Neither needs a format change.
- **Encoding levers are small.** Digit-only phones save 0.5 %, an NDEF record without type and a merged header 1.1 %, and text rebuilt from catalogs the app already ships 1.6 %. An ICD-10/ICD-11 catalog in the app would save 5.9 %, but the app does not ship one.
- **Tokenization pays only with entropy coding.** A subword vocabulary with fixed probabilities and an arithmetic coder could take the copy down an estimated 8 to 14 % with normal text; this is not measured. Bare token ids, an LLM tokenizer and neural compression do not fit the app.
- **The patient device stays on NTAG215.** Even with every lever, the triage fits an NTAG213 for 50 of 100 patients.

All figures come from the app's own code on a synthetic corpus calibrated against the NFC capacity analysis of 21 October 2026; see [Limits](#limits).

## Where format 2 leaves the bytes

| Measure | Normal text | Long text |
|---|---|---|
| Full copy, median NDEF message (B) | 1,852.5 | 2,550 |
| Full copies within a DESFire EV3 2K, ~1,900 B (of 100) | 63 | 0 |
| Free clinical text, share of the copy (%) | 29.4 | 48.7 |
| Free clinical text per copy, median (characters) | 1,440.5 | 4,258.5 |
| Cost of that text in format 2 (bits per character) | 3.00 | 2.34 |
| The same, per word (bits) | 17.1 | 13.4 |

The rest of the copy is the fixed part (patient, guardians, background, allergies), identifiers and dates (already typed by format 2), codes, and 54 B of wrapping: 31 B of AES-GCM seal with the key header and 23 B of NDEF record.

## Levers measured

Each lever is applied on top of format 2 as built and measured with format 2's own encoder and dictionary 1 (NDEF message, median of 100 patients). The full table, with the long-text maxima, is in `tool/nfc_size_options/results.md`.

| Lever | Kind | Normal text (%) | Long text (%) | Full copies within 2K, normal · long (of 100) |
|---|---|---|---|---|
| Format 2 as built | — | 1,852.5 B | 2,550 B | 63 · 0 |
| Free clinical text only in the most recent consultation | Content | −17.5 | −28.3 | 100 · 70 |
| ADR 006, option C | Content | −12.5 | −9.6 | 100 · 0 |
| Each clinical text field cut to 160 characters | Content (drops text) | −2.2 | −26.1 | 75 · 55 |
| Text rebuilt from an ICD-10/ICD-11 catalog | Encoding, new catalog | −5.9 | −3.8 | 90 · 0 |
| Text rebuilt from catalogs the app ships (vaccine, country) | Encoding | −1.6 | −1.5 | 71 · 0 |
| Text rebuilt from a DANE catalog (city, department) | Encoding, new catalog | −0.7 | −0.4 | 67 · 0 |
| Phones stored as digits only | App input | −0.5 | −0.1 | 67 · 0 |
| NDEF record without type, merged header | Encoding | −1.1 | −0.8 | — |
| **ADR 006 (C) and text only in the latest consultation** | **Content** | **−31.9** | **−38.4** | **100 · 100** |
| The same, with digit phones and the catalogs the app ships | Content, encoding | −34.0 | −39.9 | 100 · 100 |
| The same, with ICD and DANE catalogs too | Content, encoding, new catalogs | −39.6 | −44.6 | 100 · 100 |
| No free clinical text at all (ceiling of any text lever) | — | −29.4 | −48.7 | 100 · 100 |

The audit measured three more levers on its own corpus, which are not repeated here. Integer keys and catalog codes stored as integers save 3 to 4 % each with a dictionary, and up to 14 % without one. zstd with a dictionary saves 6 to 8 % against DEFLATE with a dictionary, at the cost of a native library on Android, iOS and web.

## What each lever needs

- **Free text only in the latest consultation (content).** Older consultations keep every other field: dates, diagnoses and prescriptions. Offline, the profile would show them without notes. It changes what `NfcGuardianPayload.buildGuardianPayload` puts in, not the format: `PatientFullRecord.fromJson` gives every field a default, so readers already accept a consultation without `clinicalEvaluation`. On sync, the server keeps its own version of a consultation it already holds (merged by `encounterIdentifier`), so a copy without older notes should not erase them. As with ADR 006, a backend test must confirm it before this ships.
- **ADR 006, option C (content).** The decision is open in [#184](https://github.com/guane-hwb/health-without-borders-frontend/pull/184).
- **Text rebuilt from catalogs (encoding).** Readers must rebuild what writers leave out, so this is a format change: a new format byte or dictionary id, with the two-phase rollout of ADR 005. It is lossless only if the copy keeps the text whenever it differs from the catalog's, and if the catalog version travels with the payload.
    - The app ships the vaccine catalog (`add_vaccine_screen.dart`) and the country catalog (`country_display.dart`).
    - The app does not ship an ICD catalog. The backend loads the WHO ICD-10 (~12,600 entries, displays mostly in English) and ICD-11 MMS (~34,700 entries) catalogs; the app would need at least the codes in use.
    - A DANE catalog of municipalities is small, but it gains only 0.7 %.
- **Digit-only phones (app input).** The registration form stores the number as typed (its hint is `+57 310 482 9914`). Normalizing it when saving lets format 2 store it as an integer; formatting it for display becomes the app's job.
- **NDEF record without type (encoding).** It saves 17 B per chip, plus 3 B from merging the key header with the format and dictionary bytes. The type is what lets the platform route a tag to the app and tells an HWB chip from other NDEF content, so it is worth it only where 20 B matter: the triage.
- **Text cap (content).** It drops text. On long text it gains as much as dropping older notes, but the reader cannot tell what was cut.

## Tokenization

A tokenizer helps only if each token is coded by its probability, not by its id. Format 2 already works like one: each string its dictionary matches costs 2 to 3 B, which pays for long phrases and not for short words.

| Option | How it works | What it would save | What it costs |
|---|---|---|---|
| 1. Catalog codes ("tokens with meaning") | Store the ICD, ATC/CUM, vaccine or DANE code instead of its text; the app rebuilds the text | Measured above: up to 8.3 % of the copy | Versioned catalogs in the app; works only for text that came from a catalog |
| 2. Fixed vocabulary with ids | Each frequent word becomes a 1- or 2-byte id; the rest is spelled out | Little or nothing: 8 to 16 bits per word against 17 today, and the long phrases the dictionary already covers are lost | Simple, but does not pay |
| 3. Subwords with fixed probabilities | A vocabulary of 4,000 to 8,000 pieces (BPE or Unigram, as in SentencePiece) trained on public Spanish clinical text; an arithmetic coder stores each piece in −log₂ p bits, with a fallback to single characters | Estimated, not measured: 8 to 14 % of the copy with normal text, if the text drops from 3.0 to 1.6–2.2 bits per character | A codec of our own in Dart with integer arithmetic; a 50 to 150 KB model versioned like the dictionary; a new format |
| 4. An LLM's tokenizer | A vocabulary of 32,000 to 200,000 tokens; each id takes 15 to 18 bits | Worse than today without a model to give probabilities: about 4 to 5 bits per character | Vocabulary files of several MB, and their licences |
| 5. Compression with a language model | A network predicts each token and the arithmetic coder stores only the surprise | The best ratio, about 1 bit per character | A model of tens to hundreds of MB, slow on a phone; decoding needs bit-identical results on Android, iOS and web, which floating point does not guarantee |

Any of them must keep the conditions format 2 keeps:

- **No patient data in the vocabulary or the model.** They ship inside a public app, so they come from public sources (ICD descriptions, the medication catalog, public clinical guidelines) or synthetic text.
- **Versioned for good.** A payload says which model wrote it, and a model written in the field is readable forever.
- **Deterministic, and checked before writing.** The same input gives the same bits on every device, and the payload is decoded back before it is written.
- **Bounded by the text.** Even free text would leave the copy at most 29 % (normal) or 49 % (long) smaller.

## Patient device

| Lever on the triage (format 2) | Median (B) | Maximum (B) | Within an NTAG213, 137 B (of 100) |
|---|---|---|---|
| Format 2 as built | 183.5 | 297 | 19 |
| Guardian phone as digits | 178.5 | 289 | 21 |
| And chronic conditions as ICD-10 codes | 157 | 234 | 37 |
| And an NDEF record without type, with the merged header | 137 | 214 | 50 |

The NTAG215 stays for the patient device. What still weighs most in the triage is the allergies, whose reactions are free text.

## Recommendation

1. **Decide the content levers first.** ADR 006 option C and keeping notes only for the latest consultation need no format change, and together they let a DESFire EV3 2K hold every full copy of this corpus. They are product decisions; the second one would extend ADR 006.
2. **Measure real sizes before buying chips or building a codec.** [#186](https://github.com/guane-hwb/health-without-borders-frontend/pull/186) and the backend's [#106](https://github.com/guane-hwb/health-without-borders/pull/106) report the size of every write, with no clinical content.
3. **If more is needed afterwards, ship an ICD catalog subset** with a format change (5.9 %), keeping the text whenever it differs from the catalog's.
4. **Prototype the subword coder offline** only if real notes turn out to be text-heavy, and compare it with DEFLATE and dictionary 1 on the same text.
5. **Not recommended:** an LLM's tokenizer or neural compression; shortening the AES-GCM tag or nonce (4 to 12 B for weaker authentication); dropping the record type of the guardian copy.

## Method

- **Code.** The branch of [#185](https://github.com/guane-hwb/health-without-borders-frontend/pull/185) (`a30f711`): format 2's encoder, dictionary 1 and record builder; format 1's codec and fit, which are develop's.
- **Corpus.** `gen_corpus.py` rebuilds the corpus the 21 October analysis described (that corpus is not versioned): 100 patients, 49 with two guardians, 0 to 3 allergies in its proportions, every field of the model filled in, and histories of 10 consultations taken from other patients with 1 or 2 diagnoses. The long-text variant joins each clinical field with those of two other consultations. Its vocabulary was written apart from the audit's generator, which is what dictionary 1 was built from.
- **Calibration.** On format 1 as written today the corpus lands close to the 21 October figures: median triage 253 B against 263 B, and a compressed full copy 10 % larger. Section 1 of `results.md` sets every figure side by side.
- **Levers.** `levers_test.dart` applies each lever to the aliased copy or the triage and measures it with `NfcPayloadV2.plaintextSize`; `report.py` adds the seal and the record, both measured with the app's code.
- **Reproducing it.** `tool/nfc_size_options/README.md` has the commands. Every step is deterministic; a fresh run gives the same `results.md`.

## Limits

- The data is synthetic. How well dictionary 1 and any tokenizer do on real clinical notes is not known.
- The tokenization figures are an estimate from an assumed 1.6 to 2.2 bits per character, not a measurement.
- The DESFire capacities are those of the 21 October analysis: ~1,900 B for the 2K comes from a vendor; the 4K and 8K figures are assumptions.
- The sync safety of dropping older notes rests on the merge rule for stored consultations and still needs a backend test.
- The corpus stores nationality codes as numbers where the app uses ISO alpha-3 codes; the difference is at most 1 B per record.
