// lib/src/core/nfc/nfc_payload_codec.dart
//
// NFC Payload Codec for Health Without Borders
// Pipeline: JSON → CBOR → DEFLATE → AES-256-GCM  (encode)
//           AES-256-GCM → INFLATE → CBOR → JSON   (decode)
//
// The AES-256 key is provided by the backend (per-organization)
// and stored in FlutterSecureStorage on the device.

import 'dart:io' show ZLibEncoder, ZLibDecoder;
import 'dart:math';
import 'dart:typed_data';

import 'package:cbor/cbor.dart' as cbor;

/// Overhead added by AES-256-GCM: 12-byte nonce + 16-byte auth tag = 28 bytes.
const int _kAesGcmOverhead = 28;
const int _kNonceLength = 12;
const int _kTagLength = 16;

/// Encodes and decodes NFC payloads using the HWB pipeline:
///   JSON Map → CBOR → DEFLATE (zlib level 9) → AES-256-GCM
///
/// Usage:
/// ```dart
/// final codec = NfcPayloadCodec(hexKey: 'abcdef0123456789...');
/// final encrypted = await codec.encode(patientTriageMap);
/// final decrypted = await codec.decode(encrypted);
/// ```
class NfcPayloadCodec {
  NfcPayloadCodec({required String hexKey}) : _keyBytes = _hexToBytes(hexKey) {
    if (_keyBytes.length != 32) {
      throw ArgumentError(
        'AES-256 key must be exactly 32 bytes (64 hex chars). '
        'Got ${_keyBytes.length} bytes.',
      );
    }
  }

  final Uint8List _keyBytes;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Encodes a JSON-serializable map into an encrypted byte array
  /// ready to be written to an NFC chip as an NDEF payload.
  ///
  /// Returns the final encrypted bytes including nonce and auth tag.
  /// Throws if the data cannot be serialized.
  Future<Uint8List> encode(Map<String, dynamic> data) async {
    // Step 1: JSON map → CBOR bytes
    final cborBytes = _jsonToCbor(data);

    // Step 2: CBOR → DEFLATE (zlib level 9)
    final deflated = _deflate(cborBytes);

    // Step 3: DEFLATE → AES-256-GCM
    final encrypted = _encrypt(deflated);

    return encrypted;
  }

  /// Decodes an encrypted byte array (read from NFC) back into a JSON map.
  ///
  /// Returns null if decryption fails (wrong key, tampered data).
  Future<Map<String, dynamic>?> decode(Uint8List encrypted) async {
    try {
      // Step 1: AES-256-GCM → DEFLATE
      final deflated = _decrypt(encrypted);

      // Step 2: INFLATE → CBOR
      final cborBytes = _inflate(deflated);

      // Step 3: CBOR → JSON map
      final data = _cborToJson(cborBytes);

      return data;
    } catch (_) {
      return null; // Decryption or parsing failed
    }
  }

  /// Returns the estimated size of the encoded payload without actually
  /// encrypting (useful for capacity checks before writing).
  int estimateSize(Map<String, dynamic> data) {
    final cborBytes = _jsonToCbor(data);
    final deflated = _deflate(cborBytes);
    return deflated.length + _kAesGcmOverhead;
  }

  // ── CBOR ────────────────────────────────────────────────────────────────

  static Uint8List _jsonToCbor(Map<String, dynamic> data) {
    final cborValue = cbor.CborValue(data);
    return Uint8List.fromList(cbor.cborEncode(cborValue));
  }

  static Map<String, dynamic> _cborToJson(Uint8List bytes) {
    final decoded = cbor.cborDecode(bytes);
    return _cborValueToMap(decoded);
  }

  /// Recursively converts a CborValue tree into native Dart types.
  static dynamic _cborValueToNative(dynamic value) {
    if (value is cbor.CborValue) {
      return _cborValueToNative(value.toObject());
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _cborValueToNative(v)));
    }
    if (value is List) {
      return value.map(_cborValueToNative).toList();
    }
    return value;
  }

  static Map<String, dynamic> _cborValueToMap(dynamic value) {
    final result = _cborValueToNative(value);
    if (result is Map<String, dynamic>) return result;
    throw FormatException('CBOR root must be a map, got ${result.runtimeType}');
  }

  // ── DEFLATE / INFLATE ──────────────────────────────────────────────────

  static Uint8List _deflate(Uint8List data) {
    // Raw DEFLATE (no zlib header) at max compression
    final encoder = ZLibEncoder(level: 9, raw: true);
    return Uint8List.fromList(encoder.convert(data));
  }

  static Uint8List _inflate(Uint8List data) {
    final decoder = ZLibDecoder(raw: true);
    return Uint8List.fromList(decoder.convert(data));
  }

  // ── AES-256-GCM ───────────────────────────────────────────────────────
  //
  // We use a pure-Dart AES-GCM implementation to avoid native plugin
  // dependencies. The `pointycastle` package is heavy; instead we use
  // the `cryptography` package which is already a transitive dependency
  // of flutter_secure_storage on some platforms.
  //
  // However, to keep this self-contained and avoid import conflicts,
  // we implement AES-GCM using dart:typed_data and the `encrypt` package.
  //
  // For the MVP/testing phase, we use a simplified approach:
  // We rely on the `encrypt` package (already in pubspec or to be added).
  //
  // Wire format: [12-byte nonce][ciphertext][16-byte auth tag]

  Uint8List _encrypt(Uint8List plaintext) {
    // Generate random 12-byte nonce
    final nonce = _secureRandom(_kNonceLength);

    // AES-GCM encrypt
    final result = _aesGcmEncrypt(
      key: _keyBytes,
      nonce: nonce,
      plaintext: plaintext,
    );

    // Pack: nonce + ciphertext + tag
    final output = BytesBuilder(copy: false);
    output.add(nonce);
    output.add(result.ciphertext);
    output.add(result.tag);
    return output.toBytes();
  }

  Uint8List _decrypt(Uint8List packed) {
    if (packed.length < _kAesGcmOverhead) {
      throw FormatException(
        'Encrypted payload too short: ${packed.length} bytes '
        '(minimum $_kAesGcmOverhead)',
      );
    }

    final nonce = Uint8List.sublistView(packed, 0, _kNonceLength);
    final tag = Uint8List.sublistView(packed, packed.length - _kTagLength);
    final ciphertext = Uint8List.sublistView(
      packed,
      _kNonceLength,
      packed.length - _kTagLength,
    );

    return _aesGcmDecrypt(
      key: _keyBytes,
      nonce: nonce,
      ciphertext: ciphertext,
      tag: tag,
    );
  }

  // ── AES-GCM core (using pointycastle-compatible logic) ────────────────
  //
  // NOTE: This is a placeholder that will be replaced by the actual
  // cryptography implementation. For the initial testing phase with
  // NTAG 215, we use a lightweight approach.
  //
  // In production, this should use:
  //   import 'package:cryptography/cryptography.dart';
  //   final algorithm = AesGcm.with256bits();

  static _AesGcmResult _aesGcmEncrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List plaintext,
  }) {
    // TODO: Replace with real AES-GCM from `cryptography` package.
    // For now, XOR with key-derived stream + HMAC tag for testing.
    // This allows the full pipeline to be tested end-to-end on real NFC
    // chips while the crypto is swapped in later.
    final stream = _deriveStream(key, nonce, plaintext.length);
    final ciphertext = Uint8List(plaintext.length);
    for (var i = 0; i < plaintext.length; i++) {
      ciphertext[i] = plaintext[i] ^ stream[i];
    }
    final tag = _computeTag(key, nonce, ciphertext);
    return _AesGcmResult(ciphertext: ciphertext, tag: tag);
  }

  static Uint8List _aesGcmDecrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List ciphertext,
    required Uint8List tag,
  }) {
    // Verify tag
    final expectedTag = _computeTag(key, nonce, ciphertext);
    if (!_constantTimeEquals(tag, expectedTag)) {
      throw FormatException('AES-GCM authentication failed — data tampered');
    }
    final stream = _deriveStream(key, nonce, ciphertext.length);
    final plaintext = Uint8List(ciphertext.length);
    for (var i = 0; i < ciphertext.length; i++) {
      plaintext[i] = ciphertext[i] ^ stream[i];
    }
    return plaintext;
  }

  /// Derives a pseudo-random byte stream from key + nonce.
  /// This is a TESTING placeholder — NOT real AES-GCM.
  static Uint8List _deriveStream(Uint8List key, Uint8List nonce, int length) {
    final result = Uint8List(length);
    var counter = 0;
    var offset = 0;
    while (offset < length) {
      // Simple block derivation: hash(key + nonce + counter)
      final block = _simpleHash(key, nonce, counter);
      for (var i = 0; i < block.length && offset < length; i++, offset++) {
        result[offset] = block[i];
      }
      counter++;
    }
    return result;
  }

  /// Simple keyed hash for testing. NOT cryptographically secure.
  static Uint8List _simpleHash(Uint8List key, Uint8List nonce, int counter) {
    // Use a basic mixing function for testing purposes
    final input = BytesBuilder();
    input.add(key);
    input.add(nonce);
    input.addByte((counter >> 24) & 0xFF);
    input.addByte((counter >> 16) & 0xFF);
    input.addByte((counter >> 8) & 0xFF);
    input.addByte(counter & 0xFF);
    final bytes = input.toBytes();

    // Simple 32-byte hash via repeated XOR-fold
    final hash = Uint8List(32);
    for (var i = 0; i < bytes.length; i++) {
      hash[i % 32] ^= bytes[i];
      hash[i % 32] = (hash[i % 32] * 31 + 17) & 0xFF;
    }
    return hash;
  }

  /// Computes a 16-byte authentication tag.
  static Uint8List _computeTag(
    Uint8List key,
    Uint8List nonce,
    Uint8List ciphertext,
  ) {
    final input = BytesBuilder();
    input.add(key);
    input.add(nonce);
    input.add(ciphertext);
    final bytes = input.toBytes();

    final tag = Uint8List(_kTagLength);
    for (var i = 0; i < bytes.length; i++) {
      tag[i % _kTagLength] ^= bytes[i];
      tag[i % _kTagLength] = (tag[i % _kTagLength] * 37 + 23) & 0xFF;
    }
    return tag;
  }

  /// Constant-time comparison to prevent timing attacks.
  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  // ── Utilities ──────────────────────────────────────────────────────────

  static Uint8List _secureRandom(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List _hexToBytes(String hex) {
    final clean = hex.replaceAll(RegExp(r'[\s:-]'), '');
    if (clean.length % 2 != 0) {
      throw FormatException('Hex string must have even length');
    }
    return Uint8List.fromList([
      for (var i = 0; i < clean.length; i += 2)
        int.parse(clean.substring(i, i + 2), radix: 16),
    ]);
  }
}

class _AesGcmResult {
  _AesGcmResult({required this.ciphertext, required this.tag});
  final Uint8List ciphertext;
  final Uint8List tag;
}
