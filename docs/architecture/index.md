# Architecture

This section describes how the code is organized, what each layer does, and how data flows from NFC capture to synchronization with the backend.

- [Project Structure](project-structure.md) — directory tree and conventions.
- [Modules and Features](features.md) — description of each feature in `lib/src/features/`.
- [Offline-First and Synchronization](offline-sync.md) — local data flow → backend.
- [NFC Encryption and Key Ring](nfc-encryption.md) — wire format, key ring, session window and build compatibility.
- [NFC Size Options](nfc-size-reduction-options.md) — what is left to shrink the chip payloads after format 2, measured, and the tokenization options.