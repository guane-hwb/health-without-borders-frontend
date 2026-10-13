# Syncing Pending Records

Because the app is **offline-first**, records you create in the field are first saved on the device and then uploaded to the server. This page explains how to review and clear those pending records.

---

## 1. Why records are pending

When there is no connection — or when a bracelet still needs to be written — new patients and updates are stored **locally** and queued for synchronization. The home screen shows a **gold badge** with the number of records still pending (including any duplicates or records with errors).

---

## 2. The sync queue

Open **Pending to sync** from the home screen. Each record is shown as a card with a clear status:

- **Pending** — waiting to be uploaded.
- **Error** — the upload did not complete; the card explains, in plain language, what to do.
- **Duplicate** — the record matches one already on the server.

---

## 3. Synchronize

- Tap **Sync now** on a single record, or **Sync all** to upload the whole queue.
- Tap **Review** to inspect a record before syncing.

When a record uploads successfully, it leaves the queue and the home badge count goes down.

---

## 4. Notices: changes the server did not apply

Sometimes the server accepts an upload but keeps its own version of part of the
record — for example when another device updated the patient first, or when the
copy came from a wristband or card that was already replaced. The rest of the
record is saved. The queue then shows a notice for that patient that says what
was not applied, and the home screen counts it next to the pending records.

Scan the patient's wristband again to see the server's version, then update the
wristband and the guardian card from the profile. Tap **Got it** to dismiss the
notice. The same notice appears on the patient's profile.

**Note:** Technical system-error details are intentionally hidden from this screen to keep it clear. When you sign out, the app warns you if records are still pending — sync them first whenever possible so nothing is left only on the device.