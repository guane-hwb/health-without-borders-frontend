# NFC encryption and the key ring

How the app encrypts what it writes to NFC chips, which key it uses, and why a
reader sometimes refuses a chip it can physically see.

The operational side — generating keys, rotating, retiring, and the rules that
silently destroy chip readability if broken — lives in the backend runbook:
**[NFC Key Management](https://github.com/guane-hwb/health-without-borders/blob/develop/docs/infrastructure/nfc-key-management.md)**.
Read it before touching anything to do with keys in a deployed environment.

---

## What is on the chip

Every HWB chip — a patient bracelet or a guardian card — carries its clinical
payload through this pipeline:

```
JSON map → CBOR → DEFLATE → AES-256-GCM
```

`lib/src/core/nfc/nfc_payload_codec.dart` owns all of it. Both chip types go
through the **same** `NfcPayloadService` and therefore the same key.

The chip's hardware UID is **not** encrypted and is always readable. That
matters: a device with connectivity can resolve the patient from the UID alone
through `/patients/scan`, even when it cannot decrypt the payload. The chip is a
cache for offline use; the backend is the source of truth.

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

---

## The key ring, not a key

The backend delivers a **ring** — `version -> key` — at login, refresh and
`/users/me`. `NfcKeyring` (`lib/src/core/nfc/nfc_keyring.dart`) holds it;
`AuthRepository.getNfcKeyring()` is the single accessor.

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
without leaving chips unreadable offline?** A chip carries no readable hint of
its version, so measuring is the only way to know how far a rotation has
drained.

`observed_at` is stored and sent in **UTC**. A naive local timestamp is read by
the server as UTC and shifts every sighting by the device's offset.

The whole path is best-effort: every failure is caught and logged. A lost
observation delays a rotation decision; a broken read leaves a clinician with no
history in front of a patient. Those are not comparable, and the code treats
them accordingly.

---

## Updating the fleet

The build compatibility rule that matters, in both directions:

| Chip written by | Read by older build | Read by current build |
|---|---|---|
| Older build (no versioning) | ✅ | ✅ |
| Current build, version 0 | ✅ | ✅ |
| Current build, version 1+ | ❌ | ✅ |

So while `NFC_CURRENT_KEY_VERSION` is `0`, builds are interchangeable in both
directions and a partial rollout is safe.

!!! warning "Before any rotation"
    `NFC_CURRENT_KEY_VERSION` must stay at `0` until **every** device runs a
    build that understands the ring. An older build takes the current key,
    ignores the ring, and loses the ability to read everything written under
    version 0. Confirm the fleet first; the backend runbook has the procedure.

As of the current build, no rotation has occurred: every chip in the field is
version 0, headerless.
