// lib/src/core/nfc/retired_device_hash.dart

import 'dart:convert';

import 'package:cryptography/dart.dart';

import 'nfc_session_types.dart' show normalizeNfcUid;

/// Prefix the backend hashes retired devices with
/// (`GET /api/v1/patients/retired-devices`).
const String retiredDeviceHashPrefix = 'hwb-retired-device:v1:';

/// The hash under which the server lists a retired device:
/// sha256 hex of [retiredDeviceHashPrefix] + the UID with only its hex digits,
/// in upper case. `04:a1:b2` and `04A1B2` are one device.
///
/// Null when the UID has no hex digit: it cannot be told apart from others.
/// Must match the backend byte for byte; the test vectors are shared
/// (backend `tests/contract/fixtures/retired_device_hashes.json`).
String? retiredDeviceHash(String uid) {
  final String normalized = normalizeNfcUid(uid);
  if (normalized.isEmpty) return null;
  final List<int> digest = const DartSha256()
      .hashSync(utf8.encode('$retiredDeviceHashPrefix$normalized'))
      .bytes;
  return digest.map((int b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Whether [value] looks like a hash from the server: 64 lowercase hex digits.
bool isRetiredDeviceHash(String value) =>
    RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
