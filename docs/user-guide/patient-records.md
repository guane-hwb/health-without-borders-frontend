# Finding & Viewing a Patient

This page explains how to find an existing patient and how to read a patient's clinical record from their device.

---

## 1. Search for a patient

1. From the home screen, tap **Search patients**.
2. Enter the patient's identifying details (for example, document number or name).
3. Tap **Search**.

If no match is found, the app shows the message:
*"No patient found with these details. Please check the fields."*
Review the values you entered and try again.

---

## 2. Read a patient by scanning the device

At the point of care, the fastest way to open a record is to **scan the patient's device**:

1. Choose the read option and tap **Start**.
2. Hold the patient's device (or the guardian card) against the back of the phone.
3. The patient's record opens once the device is read.

**Note:** The device identifier is unambiguous, so scanning always opens the correct patient. Manual search is best when the device is unavailable.

**Guardian device of another minor:** offline, the record opens from the guardian device only if that device holds this patient's record. If it holds another minor's record (or one from before the patient device was reassigned), the app shows only the data on the patient device, read-only, and says so. Online, the server always returns the right record.

**Retired devices:** a patient or guardian device that was retired (lost, damaged or replaced) shows *"This device was retired and no longer belongs to HWB."* and does not open the record, online or offline. Offline, the phone checks a list of retired devices that it downloads each time it syncs with a connection. If it has never synced, the record opens with a warning that the device could not be checked.

---

## 3. Read the clinical record

When a record is open, the information is organized into tabs:

- **Summary** — the patient's key information at a glance.
- **Consultations** — the list of recorded consultations.
- **Vaccines** — the vaccines registered for the patient.
- **Consultation details** — the full detail of a selected consultation.

Dates are shown in the format that matches the selected language (**ES / EN**).

---

## 4. Emergency access

In urgent situations, the app provides an **emergency ("break-glass") access** path so that care is never blocked. Every emergency access is **recorded in an audit log** (who accessed the record and when). Use it only when clinically necessary.

---

## 5. Reassign a device

When a patient device or a guardian device is lost or damaged, go to **Loss of device**, open the patient's record and tap **Reassign device** to write a new, blank device in its place. The old device stops working online, and offline once this phone knows about it: right away on the phone that made the reassignment, and on other phones after their next sync with a connection.

The patient's other devices still name the old one: the patient device lists the guardian devices, and each guardian device holds the patient device and both guardian devices. After the reassignment the app asks to **update the other devices**:

- **Write now** — write them right away, in the same visit.
- **Later** — the record shows **"NFC backup out of date"** until you write them.

Write them before the patient leaves. If a guardian device was reassigned, until the patient device is written the new guardian device does not open the record offline, and the old one still does.
