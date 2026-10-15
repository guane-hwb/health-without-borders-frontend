// lib/src/features/nfc/domain/guardian_identity.dart

import 'patient_record.dart';

/// Separators that may or may not be typed inside a document number
/// ("VZ-9876543", "vz 987.6543"). Same set as the backend's
/// `DOCUMENT_SEPARATORS`.
final RegExp _documentSeparators = RegExp(r'[-\s./_]');

String _documentKey(GuardianInfo g) => (g.documentNumber ?? g.docNumber ?? '')
    .toLowerCase()
    .replaceAll(_documentSeparators, '');

String _nameKey(String name) =>
    name.trim().split(RegExp(r'\s+')).join(' ').toLowerCase();

/// Whether two guardian blocks describe the same person.
///
/// Mirrors the backend's `record_merger._same_guardian`: the strongest
/// identifier both sides carry decides — the document, else the NFC card UID,
/// else the name. Used to decide whether a guardian's consent may stay on an
/// edited guardian: a consent belongs to the person who gave it.
bool isSameGuardian(GuardianInfo a, GuardianInfo b) {
  final String docA = _documentKey(a);
  final String docB = _documentKey(b);
  if (docA.isNotEmpty && docB.isNotEmpty) return docA == docB;

  final String uidA = (a.deviceUid ?? '').trim();
  final String uidB = (b.deviceUid ?? '').trim();
  if (uidA.isNotEmpty && uidB.isNotEmpty) return uidA == uidB;

  final String nameA = _nameKey(a.name);
  return nameA.isNotEmpty && nameA == _nameKey(b.name);
}
