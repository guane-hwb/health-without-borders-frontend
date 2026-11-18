// lib/src/core/nfc/nfc_payload_v2.dart
//
// NFC payload format 2 (ADR 005): the same map format 1 writes, in fewer bytes.
//
//   map → typed CBOR → DEFLATE with a preset dictionary → AES-256-GCM
//
// Typed: a value format 1 stores as text in a fixed shape is stored as what it
// is. A UUID or a chip UID becomes bytes, a date a day count, a date-time
// seconds plus a time-zone offset, a string of digits an integer. Only values
// in exactly the canonical shape are converted, so the reader prints them back
// character for character; anything else stays text. Which keys are typed is
// fixed per kind of payload (`_typing`).
//
// Dictionary: payloads of a few hundred bytes give DEFLATE no history of its
// own, and most of what they hold (keys, codes, frequent values) repeats from
// one patient to the next. A dictionary shared by writer and reader supplies
// that history. See `nfc_payload_v2_dictionaries.dart` for what it may hold.
//
// Plaintext, inside the AES-GCM envelope and therefore authenticated:
//
//   [format = 2][dictionary id][raw DEFLATE stream primed with the dictionary]
//
// The stream is what zlib produces after `deflateSetDictionary`, so any zlib
// reads it with `inflateSetDictionary`. dart:io ignores a dictionary on raw
// streams, so this file primes the stream itself: it compresses the
// dictionary, flushes to a byte boundary and keeps only what follows; to read,
// it inflates the dictionary's own compressed form first and keeps only what
// follows the dictionary.

import 'dart:io' show RawZLibFilter;
import 'dart:typed_data';

import 'package:cbor/cbor.dart' as cbor;

import 'nfc_payload_v2_dictionaries.dart';

/// First plaintext byte of every format 2 payload.
const int kNfcPayloadV2FormatByte = 2;

/// What a payload is.
enum NfcPayloadKind {
  /// The triage on the patient device (`NfcTriagePayload`).
  triage,

  /// The bounded copy on a guardian device, already aliased
  /// (`NfcGuardianPayload.buildWithinCapacity`).
  guardian,
}

/// A payload format 2 cannot write or read.
class NfcPayloadV2Exception implements Exception {
  NfcPayloadV2Exception(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Keys whose values are converted when they have the canonical shape.
class _Typing {
  const _Typing({
    this.uuid = const <String>{},
    this.uid = const <String>{},
    this.date = const <String>{},
    this.dateTime = const <String>{},
    this.digits = const <String>{},
  });

  /// Lower-case UUID `8-4-4-4-12` → 16 bytes.
  final Set<String> uuid;

  /// Chip UID as the app formats a read (`04:A1:…`, upper case) → bytes.
  final Set<String> uid;

  /// `YYYY-MM-DD` → days since 1900-01-01.
  final Set<String> date;

  /// `YYYY-MM-DDTHH:MM:SS±HH:MM` → [seconds since 2020-01-01, offset / 15 min].
  final Set<String> dateTime;

  /// Digits without a leading zero, up to 18 → integer.
  final Set<String> digits;
}

/// The guardian copy is aliased before it is encoded, so its keys are the short
/// ones of `nfc_guardian_alias.dart`. Changing this table changes the format:
/// it can only grow, together with a new format byte.
const Map<NfcPayloadKind, _Typing> _typing = <NfcPayloadKind, _Typing>{
  NfcPayloadKind.triage: _Typing(
    uid: <String>{'gUid', 'g2Uid'},
    date: <String>{'dob'},
    digits: <String>{'docN', 'gPh'},
  ),
  NfcPayloadKind.guardian: _Typing(
    // patientId, encounterIdentifier, vaccinationId.
    uuid: <String>{'pid', 'ei', 'vid'},
    // device_uid of the patient and of each guardian.
    uid: <String>{'dug'},
    // dob, vaccination date.
    date: <String>{'dob', 'dte'},
    // startDateTime, endDateTime, consent acceptedAt.
    dateTime: <String>{'sd', 'ed', 'aat'},
    // documentNumber, phone, repsCode, nitNumber, cityCode, nationalityCode.
    digits: <String>{'dn', 'ph', 'rc', 'nit', 'cyc', 'nc'},
  ),
};

final RegExp _uuidShape = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);
final RegExp _uidShape = RegExp(r'^[0-9A-F]{2}(:[0-9A-F]{2}){0,31}$');
final RegExp _dateShape = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final RegExp _dateTimeShape = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})([+-])(\d{2}):(\d{2})$',
);
final RegExp _digitsShape = RegExp(r'^[1-9][0-9]{0,17}$');

final DateTime _dateEpoch = DateTime.utc(1900);
final DateTime _dateTimeEpoch = DateTime.utc(2020);

String _two(int n) => n.toString().padLeft(2, '0');

String _formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

String _formatDateTime(DateTime wall, int offsetMinutes) {
  final int abs = offsetMinutes.abs();
  return '${_formatDate(wall)}T${_two(wall.hour)}:${_two(wall.minute)}:'
      '${_two(wall.second)}${offsetMinutes < 0 ? '-' : '+'}'
      '${_two(abs ~/ 60)}:${_two(abs % 60)}';
}

String _hex(List<int> bytes) =>
    bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List _bytesOfHex(String hex) => Uint8List.fromList(<int>[
  for (int i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

/// The typed form of [value] under [key], or null when it stays text.
cbor.CborValue? _typed(String value, String key, _Typing t) {
  if (t.uuid.contains(key) && _uuidShape.hasMatch(value)) {
    return cbor.CborBytes(_bytesOfHex(value.replaceAll('-', '')));
  }
  if (t.uid.contains(key) && _uidShape.hasMatch(value)) {
    return cbor.CborBytes(_bytesOfHex(value.replaceAll(':', '')));
  }
  if (t.date.contains(key)) {
    final RegExpMatch? m = _dateShape.firstMatch(value);
    if (m != null) {
      final DateTime d = DateTime.utc(
        int.parse(m[1]!),
        int.parse(m[2]!),
        int.parse(m[3]!),
      );
      // Only a real date in canonical form: 2026-02-30 stays text.
      if (_formatDate(d) == value) {
        return cbor.CborSmallInt(d.difference(_dateEpoch).inDays);
      }
    }
  }
  if (t.dateTime.contains(key)) {
    final RegExpMatch? m = _dateTimeShape.firstMatch(value);
    if (m != null) {
      final DateTime wall = DateTime.utc(
        int.parse(m[1]!),
        int.parse(m[2]!),
        int.parse(m[3]!),
        int.parse(m[4]!),
        int.parse(m[5]!),
        int.parse(m[6]!),
      );
      final int offset =
          (m[7] == '-' ? -1 : 1) * (int.parse(m[8]!) * 60 + int.parse(m[9]!));
      if (offset % 15 == 0 && _formatDateTime(wall, offset) == value) {
        return cbor.CborList(<cbor.CborValue>[
          cbor.CborSmallInt(wall.difference(_dateTimeEpoch).inSeconds),
          cbor.CborSmallInt(offset ~/ 15),
        ]);
      }
    }
  }
  if (t.digits.contains(key) && _digitsShape.hasMatch(value)) {
    return cbor.CborSmallInt(int.parse(value));
  }
  return null;
}

cbor.CborValue _encodeValue(Object? value, String? key, _Typing t) {
  if (value == null) return const cbor.CborNull();
  if (value is bool) return cbor.CborBool(value);
  if (value is int) return cbor.CborSmallInt(value);
  if (value is double) return cbor.CborFloat(value);
  if (value is String) {
    return (key == null ? null : _typed(value, key, t)) ??
        cbor.CborString(value);
  }
  if (value is List<Object?>) {
    return cbor.CborList(<cbor.CborValue>[
      for (final Object? item in value) _encodeValue(item, null, t),
    ]);
  }
  if (value is Map<Object?, Object?>) {
    return cbor.CborMap.fromEntries(
      value.entries.map((MapEntry<Object?, Object?> e) {
        final String k = e.key.toString();
        return MapEntry<cbor.CborValue, cbor.CborValue>(
          cbor.CborString(k),
          _encodeValue(e.value, k, t),
        );
      }),
    );
  }
  throw NfcPayloadV2Exception(
    'Unsupported value in an NFC payload: ${value.runtimeType}',
  );
}

Object? _decodeValue(cbor.CborValue value, String? key, _Typing t) {
  if (value is cbor.CborNull || value is cbor.CborUndefined) return null;
  if (value is cbor.CborBool) return value.value;
  if (value is cbor.CborFloat) return value.value;
  if (value is cbor.CborInt) {
    final int n = value.toInt();
    if (key != null && t.date.contains(key)) {
      return _formatDate(_dateEpoch.add(Duration(days: n)));
    }
    if (key != null && t.digits.contains(key)) return n.toString();
    return n;
  }
  if (value is cbor.CborBytes) {
    final List<int> b = value.bytes;
    if (key != null && t.uuid.contains(key) && b.length == 16) {
      final String h = _hex(b);
      return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
          '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
    }
    if (key != null && t.uid.contains(key) && b.isNotEmpty) {
      return <String>[
        for (final int x in b) x.toRadixString(16).padLeft(2, '0'),
      ].join(':').toUpperCase();
    }
    throw const FormatException('Unexpected bytes in an NFC payload');
  }
  if (value is cbor.CborString) return value.toString();
  if (value is cbor.CborList) {
    if (key != null &&
        t.dateTime.contains(key) &&
        value.length == 2 &&
        value[0] is cbor.CborInt &&
        value[1] is cbor.CborInt) {
      final int seconds = (value[0] as cbor.CborInt).toInt();
      final int quarters = (value[1] as cbor.CborInt).toInt();
      return _formatDateTime(
        _dateTimeEpoch.add(Duration(seconds: seconds)),
        quarters * 15,
      );
    }
    return <dynamic>[
      for (final cbor.CborValue item in value) _decodeValue(item, null, t),
    ];
  }
  if (value is cbor.CborMap) {
    return <String, dynamic>{
      for (final MapEntry<cbor.CborValue, cbor.CborValue> e in value.entries)
        e.key.toString(): _decodeValue(e.value, e.key.toString(), t),
    };
  }
  throw FormatException('Unexpected CBOR value: ${value.runtimeType}');
}

/// Structural equality, strict on types: an int is not the double it equals.
bool _deepEquals(Object? a, Object? b) {
  if (a is Map<Object?, Object?> && b is Map<Object?, Object?>) {
    if (a.length != b.length) return false;
    for (final MapEntry<Object?, Object?> e in a.entries) {
      if (!b.containsKey(e.key) || !_deepEquals(e.value, b[e.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a.runtimeType == b.runtimeType && a == b;
}

List<int> _drain(RawZLibFilter filter, {required bool end}) {
  final List<int> out = <int>[];
  List<int>? chunk;
  while ((chunk = filter.processed(flush: true, end: end)) != null) {
    out.addAll(chunk!);
  }
  return out;
}

/// The dictionary's own compressed form, ending at a sync flush: what the
/// reader inflates before a payload. Any valid form works; this one is cached.
final Map<String, List<int>> _primers = <String, List<int>>{};

/// Encodes and decodes format 2 plaintexts.
abstract final class NfcPayloadV2 {
  /// Dictionary this build writes with, per kind.
  static int writeDictionaryId(NfcPayloadKind kind) =>
      kind == NfcPayloadKind.triage
      ? kNfcV2TriageDictionaryId
      : kNfcV2GuardianDictionaryId;

  static Uint8List _dictionary(NfcPayloadKind kind, int id) {
    final Uint8List? dictionary = kind == NfcPayloadKind.triage
        ? nfcV2TriageDictionary(id)
        : nfcV2GuardianDictionary(id);
    if (dictionary == null) {
      throw FormatException('Unknown ${kind.name} dictionary: $id');
    }
    return dictionary;
  }

  /// The typed CBOR of [payload], before compression. Also what the
  /// dictionaries are built from (`tool/nfc_payload_v2/`).
  static Uint8List typedCbor(
    Map<String, dynamic> payload,
    NfcPayloadKind kind,
  ) {
    return Uint8List.fromList(
      cbor.cborEncode(_encodeValue(payload, null, _typing[kind]!)),
    );
  }

  static Uint8List _encodeUnchecked(
    Map<String, dynamic> payload,
    NfcPayloadKind kind,
  ) {
    final int id = writeDictionaryId(kind);
    final Uint8List dictionary = _dictionary(kind, id);
    final Uint8List body = typedCbor(payload, kind);
    final RawZLibFilter deflater = RawZLibFilter.deflateFilter(
      level: 9,
      raw: true,
    );
    deflater.process(dictionary, 0, dictionary.length);
    _drain(deflater, end: false);
    deflater.process(body, 0, body.length);
    final List<int> stream = _drain(deflater, end: true);
    return Uint8List.fromList(<int>[kNfcPayloadV2FormatByte, id, ...stream]);
  }

  /// The plaintext of [payload] in format 2. Decoding it is checked to give
  /// back exactly [payload] before it is returned; otherwise this throws
  /// [NfcPayloadV2Exception] and nothing should be written.
  static Uint8List encode(Map<String, dynamic> payload, NfcPayloadKind kind) {
    final Uint8List plaintext = _encodeUnchecked(payload, kind);
    final Map<String, dynamic> back = decode(plaintext, kind);
    if (!_deepEquals(back, payload)) {
      throw NfcPayloadV2Exception(
        'Format 2 would not give back the same ${kind.name} payload.',
      );
    }
    return plaintext;
  }

  /// Length of [encode]'s result, without the round-trip check. For fitting a
  /// guardian copy to a chip, where it is called once per combination tried.
  static int plaintextSize(Map<String, dynamic> payload, NfcPayloadKind kind) =>
      _encodeUnchecked(payload, kind).length;

  /// The payload a format 2 plaintext holds. Throws [FormatException] for
  /// anything that is not one (another format, an unknown dictionary, a
  /// damaged stream).
  static Map<String, dynamic> decode(Uint8List plaintext, NfcPayloadKind kind) {
    if (plaintext.length < 3 || plaintext[0] != kNfcPayloadV2FormatByte) {
      throw const FormatException('Not a format 2 NFC payload');
    }
    final int id = plaintext[1];
    final Uint8List dictionary = _dictionary(kind, id);
    final List<int> primer = _primers.putIfAbsent('${kind.name}:$id', () {
      final RawZLibFilter deflater = RawZLibFilter.deflateFilter(
        level: 9,
        raw: true,
      );
      deflater.process(dictionary, 0, dictionary.length);
      return _drain(deflater, end: false);
    });
    final List<int> input = <int>[...primer, ...plaintext.sublist(2)];
    final List<int> inflated;
    try {
      final RawZLibFilter inflater = RawZLibFilter.inflateFilter(raw: true);
      inflater.process(input, 0, input.length);
      inflated = _drain(inflater, end: true);
    } catch (e) {
      throw FormatException('Damaged format 2 NFC payload: $e');
    }
    if (inflated.length < dictionary.length) {
      throw const FormatException('Truncated format 2 NFC payload');
    }
    final Object? root = _decodeValue(
      cbor.cborDecode(inflated.sublist(dictionary.length)),
      null,
      _typing[kind]!,
    );
    if (root is! Map<String, dynamic>) {
      throw const FormatException('A format 2 NFC payload must be a map');
    }
    return root;
  }
}
