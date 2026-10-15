// lib/src/core/utils/clinical_time.dart

/// Clinical timestamps (visit start/end, consent, emergency access) as the
/// backend expects them: local wall time plus its UTC offset,
/// e.g. `2026-09-22T10:30:00-05:00`.
///
/// `DateTime.toIso8601String()` on a local time has no offset. The backend
/// now reads such values as America/Bogota, but before that it declared them
/// UTC in the RDA — five hours off — and an offset keeps the value exact
/// wherever the device is. Local time (not UTC) keeps the date prefix and the
/// string order the app already relies on, so records written before and
/// after this change sort and display together. Seconds precision: the extra
/// digits bought nothing and cost bytes on the guardian's NFC card.
String toIso8601WithOffset(DateTime value) {
  final DateTime local = value.toLocal();
  final Duration offset = local.timeZoneOffset;
  final Duration abs = offset.abs();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-'
      '${two(local.day)}T${two(local.hour)}:${two(local.minute)}:'
      '${two(local.second)}${offset.isNegative ? '-' : '+'}'
      '${two(abs.inHours)}:${two(abs.inMinutes % 60)}';
}
