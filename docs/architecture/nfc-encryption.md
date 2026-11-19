# NFC encryption and the key ring

How the app encrypts what it writes to NFC chips, which key it uses, and why a
reader sometimes refuses a chip it can physically see.

The operational side — generating keys, rotating, retiring, and the rules that
silently destroy chip readability if broken — lives in the backend runbook:
**[NFC Key Management](https://github.com/guane-hwb/health-without-borders/blob/develop/docs/infrastructure/nfc-key-management.md)**.
Read it before touching anything to do with keys in a deployed environment.

---

## What is on the chip

Every HWB chip — a patient device or a guardian card — carries its clinical
payload in one of two formats, and every build since ADR 005 reads both:

```
format 1: JSON map → CBOR → DEFLATE → AES-256-GCM, in a MIME record
format 2: JSON map → typed CBOR → DEFLATE with a preset dictionary
          → AES-256-GCM, in an NFC Forum external record
```

`lib/src/core/nfc/nfc_payload_codec.dart` owns format 1 and the encryption of
both; `nfc_payload_v2.dart` builds the format 2 plaintext. A build writes format
1 unless it was made with `--dart-define=HWB_NFC_PAYLOAD_FORMAT=2`
(`kNfcWriteFormat`; see ADR 005 before changing it). Both chip types go through
the **same** `NfcPayloadService` and therefore the same key.

The chip's hardware UID is **not** encrypted and is always readable. That
matters: a device with connectivity can resolve the patient from the UID alone
through `/patients/scan`, even when it cannot decrypt the payload. The chip is a
cache for offline use; the backend is the source of truth.

A guardian device holds the bounded record of **one** patient, so every minor
needs a guardian device of their own. `writeGuardianRecord(patientId: ...)`
refuses a chip that is a patient device or holds another patient's copy
(`NfcDeviceInUseException`); registration checks the same when the guardian
device is scanned. Offline, the reader uses the guardian copy only when its
`device_uid` is the patient device just scanned; otherwise it shows the triage,
read-only.

### How the guardian copy is fitted to the chip

The guardian copy carries at most the three most recent consultations and the
three most recent vaccines. `NfcGuardianPayload.buildWithinCapacity` fits it to
the capacity the chip reports, inside the tap, in two steps:

1. **Trim.** While the encoded copy does not fit, drop the oldest entry of one
   history at a time, alternating between consultations and vaccines (a
   consultation first when both hold the same number).
2. **Give back.** Once it fits, return to the history that was not cut last the
   entries it lost, one at a time, while they still fit.

The result leaves no entry out while there is room for it: adding the next
consultation or the next vaccine would not fit. Without the second step the
alternation dropped vaccines in step with consultations, and since a
consultation is several times larger than a vaccine, a card with room for three
vaccines was written with one. Each history keeps its most recent entries, so the
partial-device notice ("the most recent entries were saved") stays accurate.

---

## Wire format

```
version 0 : [12-byte nonce][ciphertext][16-byte auth tag]
version 1+: ['H']['W'][version][nonce][ciphertext][tag]
```

For version 1 and above, the three header bytes are passed to AES-GCM as
**associated data**, so the version byte cannot be stripped or edited without
failing authentication.

**Version 0 deliberately writes no header.** This is not an oversight. A build
that predates key versioning reads the first bytes as the nonce, so a header
there would make everything written by a newer build unreadable to an older one
— during any partial rollout, which is the normal state of a device fleet. A
header only ever appears once a deployment rotates to version 1.

`decode()` reads both layouts. For a headerless payload it reports the version
whose key succeeded, which is the version the chip is effectively on.

The envelope is the same in both payload formats. What it encloses differs:

| Payload format | Record | Plaintext inside the envelope |
|---|---|---|
| 1 | MIME `application/vnd.hwb.triage` / `…guardian` | DEFLATE of CBOR |
| 2 | external `guane.com.co:hwbt` / `…:hwbg` | `[2][dictionary id]` + DEFLATE, primed with that dictionary, of typed CBOR |

The chip binding of ADR 003 puts the record type in the associated data, so a
payload cannot be moved between formats either.

---

## The key ring, not a key

The backend delivers a **ring** — `version -> key` — at login, refresh and
`/users/me`. `NfcKeyring` (`lib/src/core/nfc/nfc_keyring.dart`) holds it;
`AuthRepository.getNfcKeyring()` is the single accessor.

A device that holds a ring sends `X-NFC-Keyring-Fingerprint` on refresh and
`/users/me`: a SHA-256 over the keys and the current version it holds. If it
matches, the backend does not send the ring again, and the response without keys
leaves the held ring in place. Any change to the ring changes the fingerprint,
so the next refresh delivers it. Login and the password change always deliver
it. The web build holds no ring: the backend does not deliver keys to a browser.

Reads resolve whichever version the chip names. Writes use the ring's current
version.

!!! danger "Always build the codec from the ring"
    `NfcPayloadCodec(hexKey: ...)` stamps **version 0** into the header while
    encrypting with whatever key it was handed. After a rotation that produces a
    chip no reader can decrypt — silently and permanently. This is not
    hypothetical: it is a defect that reached `develop` once and had to be
    fixed. Use `NfcPayloadCodec.fromKeyring(keyring: ...)`.

A malformed key in the ring is dropped with a log line rather than rejected
wholesale, so one bad key delivered by the backend degrades that version instead
of disabling NFC entirely. If the dropped version happens to be the current one,
the codec becomes read-only: it refuses to write rather than encrypt with a
guessed key.

---

## The session window

The ring is only served while the **refresh token's `exp` is still in the
future**. The claim is read locally from the JWT, so the check works with no
connectivity — which is the point.

Outside the window the ring is wiped from memory and from disk, and NFC reads
and writes are refused. The session itself is still restored, because the device
may hold unsynced records the health worker needs to see; what appears is the
persistent `SessionWindowBanner` telling them to reconnect.

The window slides forward on every successful refresh, so someone using the app
normally never meets it. Reaching it requires roughly a week with no
connectivity at all.

### Clock handling

The window is judged against the device clock, so a stored high-water mark
(`hwb_clock_mark`) detects the clock being moved backwards: more than 24 hours
behind the mark closes the window. The tolerance absorbs NTP corrections and
timezone changes.

The mark is **re-anchored to the server's clock** — the refresh token's `iat` —
on every successful login and refresh. Without that, a device whose clock ran
ahead even briefly would keep a mark in the future and refuse NFC until real
time caught up, with no way out but clearing app storage, which destroys pending
records.

---

## Key version telemetry

Every chip read records which key version opened it, keyed by device UID in
`nfc_key_version_observations`, with a `patient` / `guardian` role. `SyncEngine`
ships pending observations and marks them reported only after the server
confirms.

This exists for one operational question: **can a key version be retired
without leaving chips unreadable offline?** A version 0 chip carries no hint of
its version at all (from version 1 on, the version byte is in the clear header),
and either way only a device that reads the chip learns it, so measuring is the
only way to know how far a rotation has drained.

The UID stays on the phone. The backend stores an HMAC of it, not the UID, keeps
each sighting for 730 days, and drops sightings of versions that do not exist
(backend `docs/infrastructure/nfc-key-management.md`, "Telemetry storage").

`observed_at` is stored and sent in **UTC**. A naive local timestamp is read by
the server as UTC and shifts every sighting by the device's offset.

The whole path is best-effort: every failure is caught and logged. A lost
observation delays a rotation decision; a broken read leaves a clinician with no
history in front of a patient. Those are not comparable, and the code treats
them accordingly.

---

## Write-size telemetry

Every successful chip write records its sizes in `nfc_write_metrics`, and
`SyncEngine` reports them to `POST /api/v1/patients/nfc-write-metrics`. The
question they answer is how the payload format and the guardian copy should
change: how close each write comes to the chip's capacity, and how often the
guardian copy had to leave history out.

| Field | Patient device | Guardian device |
|---|---|---|
| `device_role` | `patient` | `guardian` |
| `payload_format`, `key_version` | format of the payload (1 today) and key version | same |
| `payload_bytes`, `message_bytes`, `chip_capacity` | encrypted payload, whole NDEF message, capacity the chip reported | same |
| `consultations_kept/total`, `vaccines_kept/total` | null | what the copy kept, of what it would carry on a chip with room for everything (the most recent, at most 3): `kept < total` means the chip's capacity left history out |
| `written_at` | UTC | UTC |

No UID, no patient, no record content: a row cannot be traced back to a person.
`NfcPayloadService` builds the metric after `write()` returns and hands it to the
`onWritten` observer without awaiting it; a failure is logged and the write is
unaffected. The table keeps at most `LocalDatabase.maxPendingNfcWriteMetrics`
rows (the newest), and rows are deleted as soon as the server accepts them. The
web build writes no chips and stores nothing.

The same sizes for records that already exist, before any build reports them,
come from `tool/nfc_measure/` (aggregates only; read its README before running
it on real records).

---

## Updating the fleet

The build compatibility rule that matters, in both directions:

| Chip written by | Read by older build | Read by current build |
|---|---|---|
| Older build (no versioning) | ✅ | ✅ |
| Current build, version 0 | ✅ | ✅ |
| Current build, version 1+ | ❌ | ✅ |

So while the current version is `0`, builds are interchangeable in both
directions and a partial rollout is safe.

The payload format follows the same rule. A build before ADR 005 does not know
format 2 and sees such a chip as blank, so format 2 is written only after every
device runs a build that reads it (phase 2 of ADR 005):

| Chip written in | Read by a build before ADR 005 | Read by a build with it |
|---|---|---|
| Format 1 | ✅ | ✅ |
| Format 2 | ❌ (blank) | ✅ |

!!! warning "Before any rotation"
    The current version must stay at `0` until **every** device runs a build
    that understands the ring. An older build takes the current key, ignores
    the ring, and loses the ability to read everything written under version 0.
    Confirm the fleet first; the backend runbook has the procedure.

    Where the current version is set depends on the backend's mode. The pilot
    keeps the ring in its database under a KEK: there the current version only
    changes through `POST /api/v1/patients/nfc-keys/rotate` (or `/revoke` of the
    current version) and automatic rotation (`NFC_AUTO_ROTATE`), and
    `NFC_CURRENT_KEY_VERSION` is ignored. That variable only applies to a
    deployment without a KEK, which serves the ring from its environment.

As of the current build, no rotation has occurred: every chip in the field is
version 0, headerless.

---

## Offline Guardian Factor & Threat Model Considerations

When operating without connectivity, the requirement for a guardian card before opening a minor's profile is enforced locally by the application interface (`read_nfc_screen.dart`):

1. **Local Decryption:** The patient wristband payload (triage) is encrypted with the fleet-wide keyring. Once scanned, the client decrypts the payload in memory to inspect demographic fields (`dob`, `isMinor`) and identity linkages (`gUid`, `g2Uid`).
2. **Access Control Enforcement:** If the patient is determined to be a minor (`isMinor == true`), the UI transitions to the second factor step demanding a scan of the guardian card matching `gUid` or `g2Uid`. If absent, only the read-only emergency triage flow (logged via `logEmergencyAccess`) is permitted.
3. **Accepted Risk:** In an offline architecture utilizing a shared symmetric keyring, cryptographic enforcement of guardian presence cannot be guaranteed against a maliciously modified client application, because the client already holds the decrypted triage data in memory. This risk is accepted by design:
   - Encrypting the guardian payload separately under a secret key held exclusively on the physical guardian card would prevent multi-brigade read-only triage in emergency situations.
   - Genuine offline operations prioritize life-saving clinical triage (`break-glass`) while recording audit events locally for deferred backend synchronization.
