// lib/src/core/nfc/nfc_payload_codec.dart
//
// NFC Payload Codec for Health Without Borders
// Pipeline: JSON → CBOR → DEFLATE → AES-256-GCM  (encode)
//           AES-256-GCM → INFLATE → CBOR → JSON   (decode)
//
// The AES-256 keys are provided by the backend as a versioned keyring (see
// NfcKeyring). Encoded payloads carry a short header naming the key version
// they were encrypted with, so a reader can pick the right key out of the ring
// and old tags stay readable while a rotation is in progress.

import 'dart:io' show ZLibEncoder, ZLibDecoder;
import 'dart:math';
import 'dart:typed_data';

import 'package:cbor/cbor.dart' as cbor;
import 'package:cryptography/cryptography.dart' as crypto;

import '../utils/app_logger.dart';
import 'nfc_keyring.dart';

/// Overhead added by AES-256-GCM: 12-byte nonce + 16-byte auth tag = 28 bytes.
const int _kAesGcmOverhead = 28;
const int _kNonceLength = 12;
const int _kTagLength = 16;

/// Magic bytes that open a versioned payload: ASCII 'H','W'.
const int _kMagic0 = 0x48;
const int _kMagic1 = 0x57;

/// Versioned wire header: two magic bytes plus one key-version byte.
const int _kHeaderLength = 3;

/// Highest key version representable in the single-byte header.
const int kMaxNfcKeyVersion = 255;

/// A decoded payload together with the key version that actually opened it.
class NfcDecodeResult {
  const NfcDecodeResult({
    required this.data,
    required this.keyVersion,
    required this.hadHeader,
  });

  /// The decoded payload.
  final Map<String, dynamic> data;

  /// The version whose key decrypted this payload.
  final int keyVersion;

  /// Whether the payload carried a version header (version 1 or later).
  final bool hadHeader;
}

/// Internal outcome of a decryption attempt.
class _DecryptOutcome {
  const _DecryptOutcome(this.plaintext, this.keyVersion, this.hadHeader);
  final Uint8List plaintext;
  final int keyVersion;
  final bool hadHeader;
}

/// Encodes and decodes NFC payloads using the HWB pipeline:
///   JSON Map → CBOR → DEFLATE (zlib level 9) → AES-256-GCM
///
/// Wire format written by [encode]:
///   version 0 : [12-byte nonce][ciphertext][16-byte auth tag]
///   version 1+: ['H']['W'][version][nonce][ciphertext][tag], with the three
///               header bytes authenticated as associated data (AAD).
class NfcPayloadCodec {
  /// Single-key codec. Retained for the legacy call path and tests.
  NfcPayloadCodec({
    required String hexKey,
    int keyVersion = kLegacyNfcKeyVersion,
  }) : this.fromKeyring(
         keyring: NfcKeyring.single(hexKey, version: keyVersion),
       );

  /// Codec backed by every key the device holds.
  NfcPayloadCodec.fromKeyring({required NfcKeyring keyring})
    : _keys = _parseKeyring(keyring),
      _writeVersion = _resolveWriteVersion(keyring);

  /// Decoded keys by version.
  final Map<int, Uint8List> _keys;

  /// Version [encode] stamps into the header.
  final int? _writeVersion;

  static int? _resolveWriteVersion(NfcKeyring keyring) {
    final int? current = keyring.currentVersion;
    if (current == null) return null;
    final String? hex = keyring.keyFor(current);
    return (hex != null && _isUsableKey(current, hex)) ? current : null;
  }

  static bool _isUsableKey(int version, String hex) {
    if (version < 0 || version > kMaxNfcKeyVersion) return false;
    try {
      return _hexToBytes(hex).length == 32;
    } catch (_) {
      return false;
    }
  }

  static Map<int, Uint8List> _parseKeyring(NfcKeyring keyring) {
    if (keyring.isEmpty) {
      throw ArgumentError(
        'NFC keyring is empty: no key to encrypt or decrypt with.',
      );
    }

    final parsed = <int, Uint8List>{};
    final skipped = <int>[];
    for (final MapEntry<int, String> entry in keyring.keys.entries) {
      final int version = entry.key;
      if (!_isUsableKey(version, entry.value)) {
        skipped.add(version);
        continue;
      }
      parsed[version] = _hexToBytes(entry.value);
    }

    if (skipped.isNotEmpty) {
      AppLogger.e(
        'Versiones de llave NFC descartadas por formato inválido: '
        '${skipped.join(', ')}. Se continúa con las versiones válidas.',
      );
    }

    if (parsed.isEmpty) {
      throw ArgumentError(
        'No usable NFC key in the keyring (versions offered: '
        '${keyring.versions.join(', ')}).',
      );
    }
    return parsed;
  }

  int? get writeKeyVersion => _writeVersion;

  List<int> get knownKeyVersions => _keys.keys.toList()..sort();

  bool get _writesHeader =>
      _writeVersion != null && _writeVersion != kLegacyNfcKeyVersion;

  final _algorithm = crypto.AesGcm.with256bits();

  // ── Public API ──────────────────────────────────────────────────────────

  /// Encodes a JSON-serializable map into an encrypted byte array.
  ///
  /// Optionally accepts [extraAad] (e.g. chip UID or MIME type) to bind the
  /// ciphertext to a specific hardware device or context.
  Future<Uint8List> encode(
    Map<String, dynamic> data, {
    Uint8List? extraAad,
  }) async {
    final cborBytes = _jsonToCbor(data);
    final deflated = _deflate(cborBytes);
    final encrypted = await _encrypt(deflated, extraAad: extraAad);
    return encrypted;
  }

  /// Decodes an encrypted byte array back into a JSON map.
  Future<Map<String, dynamic>?> decode(
    Uint8List encrypted, {
    Uint8List? extraAad,
  }) async {
    return (await decodeDetailed(encrypted, extraAad: extraAad))?.data;
  }

  /// Like [decode], but also reports which key version opened the payload.
  Future<NfcDecodeResult?> decodeDetailed(
    Uint8List encrypted, {
    Uint8List? extraAad,
  }) async {
    try {
      final outcome = await _decrypt(encrypted, extraAad: extraAad);
      if (outcome == null) return null;

      final cborBytes = _inflate(outcome.plaintext);
      final data = _cborToJson(cborBytes);

      return NfcDecodeResult(
        data: data,
        keyVersion: outcome.keyVersion,
        hadHeader: outcome.hadHeader,
      );
    } catch (_) {
      return null;
    }
  }

  int estimateSize(Map<String, dynamic> data) {
    final cborBytes = _jsonToCbor(data);
    final deflated = _deflate(cborBytes);
    final int header = _writesHeader ? _kHeaderLength : 0;
    return deflated.length + _kAesGcmOverhead + header;
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
    final encoder = ZLibEncoder(level: 9, raw: true);
    return Uint8List.fromList(encoder.convert(data));
  }

  static Uint8List _inflate(Uint8List data) {
    final decoder = ZLibDecoder(raw: true);
    return Uint8List.fromList(decoder.convert(data));
  }

  // ── AES-256-GCM REAL IMPLEMENTATION ────────────────────────────────────

  Future<Uint8List> _encrypt(Uint8List plaintext, {Uint8List? extraAad}) async {
    final int? version = _writeVersion;
    final Uint8List? key = version == null ? null : _keys[version];
    if (version == null || key == null) {
      throw StateError(
        'No current NFC key version available for writing '
        '(versions held: ${knownKeyVersions.join(', ')}). '
        'Log in again to refresh the keyring.',
      );
    }

    final bool withHeader = version != kLegacyNfcKeyVersion;
    final Uint8List? header = withHeader
        ? Uint8List.fromList(<int>[_kMagic0, _kMagic1, version])
        : null;

    final aadList = <int>[...?header, ...?extraAad];

    final nonce = _secureRandom(_kNonceLength);

    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: crypto.SecretKey(key),
      nonce: nonce,
      aad: aadList,
    );

    final output = BytesBuilder(copy: false);
    if (header != null) output.add(header);
    output.add(nonce);
    output.add(secretBox.cipherText);
    output.add(secretBox.mac.bytes);
    return output.toBytes();
  }

  Future<_DecryptOutcome?> _decrypt(
    Uint8List packed, {
    Uint8List? extraAad,
  }) async {
    if (packed.length >= _kHeaderLength + _kAesGcmOverhead &&
        packed[0] == _kMagic0 &&
        packed[1] == _kMagic1) {
      final int version = packed[2];
      final Uint8List? key = _keys[version];
      if (key != null) {
        final headerAad = Uint8List.sublistView(packed, 0, _kHeaderLength);
        final fullAad = Uint8List.fromList(<int>[...headerAad, ...?extraAad]);
        final result = await _decryptWith(
          key,
          Uint8List.sublistView(packed, _kHeaderLength),
          aad: fullAad,
        );
        if (result != null) {
          return _DecryptOutcome(result, version, true);
        }
      }
    }

    for (final int version in knownKeyVersions) {
      final result = await _decryptWith(_keys[version]!, packed, aad: extraAad);
      if (result != null) return _DecryptOutcome(result, version, false);
    }

    return null;
  }

  Future<Uint8List?> _decryptWith(
    Uint8List key,
    Uint8List body, {
    Uint8List? aad,
  }) async {
    if (body.length < _kAesGcmOverhead) return null;

    final nonce = Uint8List.sublistView(body, 0, _kNonceLength);
    final tag = Uint8List.sublistView(body, body.length - _kTagLength);
    final ciphertext = Uint8List.sublistView(
      body,
      _kNonceLength,
      body.length - _kTagLength,
    );

    try {
      final secretBox = crypto.SecretBox(
        ciphertext,
        nonce: nonce,
        mac: crypto.Mac(tag),
      );

      final clearText = await _algorithm.decrypt(
        secretBox,
        secretKey: crypto.SecretKey(key),
        aad: aad ?? const <int>[],
      );

      return Uint8List.fromList(clearText);
    } catch (_) {
      return null;
    }
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
      throw const FormatException('Hex string must have even length');
    }
    return Uint8List.fromList([
      for (var i = 0; i < clean.length; i += 2)
        int.parse(clean.substring(i, i + 2), radix: 16),
    ]);
  }
}
