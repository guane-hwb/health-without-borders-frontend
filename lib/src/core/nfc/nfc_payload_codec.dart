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

/// Encodes and decodes NFC payloads using the HWB pipeline:
///   JSON Map → CBOR → DEFLATE (zlib level 9) → AES-256-GCM
///
/// Wire format written by [encode]:
///   version 0 : [12-byte nonce][ciphertext][16-byte auth tag]
///   version 1+: ['H']['W'][version][nonce][ciphertext][tag], with the three
///               header bytes authenticated as associated data.
///
/// Version 0 deliberately writes the pre-versioning layout so that a device
/// running an older build can still read tags written by this one while a
/// fleet is only partly updated. The header appears only once a deployment
/// rotates to version 1 or beyond.
///
/// [decode] reads both layouts.
///
/// Usage:
/// ```dart
/// final codec = NfcPayloadCodec.fromKeyring(keyring: keyring);
/// final encrypted = await codec.encode(patientTriageMap);
/// final decrypted = await codec.decode(encrypted);
/// ```
class NfcPayloadCodec {
  /// Single-key codec. Retained for the legacy call path and tests; equivalent
  /// to a keyring holding just [keyVersion].
  NfcPayloadCodec({
    required String hexKey,
    int keyVersion = kLegacyNfcKeyVersion,
  }) : this.fromKeyring(
         keyring: NfcKeyring.single(hexKey, version: keyVersion),
       );

  /// Codec backed by every key the device holds.
  ///
  /// Writes use [NfcKeyring.currentVersion]; reads resolve the version named in
  /// the payload header.
  ///
  /// Malformed entries in the ring are dropped rather than rejected wholesale,
  /// so one bad key delivered by the backend degrades this device instead of
  /// disabling NFC entirely. Throws [ArgumentError] only when nothing usable is
  /// left. If the current version is the one dropped, the codec is read-only.
  NfcPayloadCodec.fromKeyring({required NfcKeyring keyring})
    : _keys = _parseKeyring(keyring),
      _writeVersion = _resolveWriteVersion(keyring);

  /// Decoded keys by version.
  final Map<int, Uint8List> _keys;

  /// Version [encode] stamps into the header, or null when the keyring named
  /// no usable current version (reads still work; writes are refused).
  final int? _writeVersion;

  /// The current version, but only if its key survived parsing.
  static int? _resolveWriteVersion(NfcKeyring keyring) {
    final int? current = keyring.currentVersion;
    if (current == null) return null;
    final String? hex = keyring.keyFor(current);
    return (hex != null && _isUsableKey(current, hex)) ? current : null;
  }

  /// Whether [hex] is a well-formed AES-256 key for a representable version.
  static bool _isUsableKey(int version, String hex) {
    if (version < 0 || version > kMaxNfcKeyVersion) return false;
    try {
      return _hexToBytes(hex).length == 32;
    } catch (_) {
      return false;
    }
  }

  /// Decodes every usable key in [keyring], skipping the rest.
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
      // Never log key material, only which versions were unusable.
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

  /// Key version new writes are stamped with, or null when writes are refused.
  int? get writeKeyVersion => _writeVersion;

  /// Key versions this codec can decrypt with, ascending.
  List<int> get knownKeyVersions => _keys.keys.toList()..sort();

  /// Whether [encode] will prepend a version header. False for version 0,
  /// which is written in the pre-versioning format for fleet compatibility.
  bool get _writesHeader =>
      _writeVersion != null && _writeVersion != kLegacyNfcKeyVersion;

  // Primitiva algorítmica estándar de la industria (AES-GCM con llaves de 256 bits)
  final _algorithm = crypto.AesGcm.with256bits();

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

    // Step 3: DEFLATE → AES-256-GCM (Asíncrono real)
    final encrypted = await _encrypt(deflated);

    return encrypted;
  }

  /// Decodes an encrypted byte array (read from NFC) back into a JSON map.
  ///
  /// Returns null if decryption fails (wrong key, tampered data).
  Future<Map<String, dynamic>?> decode(Uint8List encrypted) async {
    try {
      // Step 1: AES-256-GCM → DEFLATE (Asíncrono real)
      final deflated = await _decrypt(encrypted);
      if (deflated == null) return null;

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
    // Includes the version header when one will be written, since it comes out
    // of the same chip capacity budget the guardian fit is computed from.
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

  // ── AES-256-GCM REAL IMPLEMENTATION ────────────────────────────────────
  //
  // Wire format v1+: ['H']['W'][version][nonce][ciphertext][tag], header as AAD
  // Wire format v0 / legacy:                       [nonce][ciphertext][tag]

  Future<Uint8List> _encrypt(Uint8List plaintext) async {
    final int? version = _writeVersion;
    final Uint8List? key = version == null ? null : _keys[version];
    if (version == null || key == null) {
      throw StateError(
        'No current NFC key version available for writing '
        '(versions held: ${knownKeyVersions.join(', ')}). '
        'Log in again to refresh the keyring.',
      );
    }

    // Version 0 is written in the pre-versioning format, with no header at
    // all, so a device running an older build can still read what this one
    // writes while a fleet is only partly updated. A header only ever appears
    // from version 1 on, which no deployment reaches until it rotates.
    final bool withHeader = version != kLegacyNfcKeyVersion;
    final Uint8List? header = withHeader
        ? Uint8List.fromList(<int>[_kMagic0, _kMagic1, version])
        : null;

    // Generar un nonce seguro y aleatorio de 12 bytes
    final nonce = _secureRandom(_kNonceLength);

    // Cifrado simétrico de alta seguridad utilizando el paquete oficial.
    // The header is authenticated as associated data, so the version byte
    // cannot be stripped or edited without failing the tag.
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: crypto.SecretKey(key),
      nonce: nonce,
      aad: header ?? const <int>[],
    );

    // Empaquetar la estructura binaria final para el chip NFC
    final output = BytesBuilder(copy: false);
    if (header != null) output.add(header);
    output.add(nonce);
    output.add(secretBox.cipherText);
    output.add(
      secretBox.mac.bytes,
    ); // El tag de autenticación de 16 bytes (GCM)
    return output.toBytes();
  }

  /// Decrypts [packed], resolving which key to use from its header.
  ///
  /// Order of attempts:
  ///   1. If [packed] opens with the magic bytes and names a version this
  ///      device holds, decrypt the body with that key. This is the normal
  ///      path and is deterministic — no guessing.
  ///   2. Otherwise (or if step 1 failed), treat [packed] as a pre-versioning
  ///      payload and try each key held, version 0 first.
  ///
  /// Step 2 is not only for the rollout. A headerless payload begins with a
  /// random nonce, which has a 1-in-65536 chance of starting with the magic
  /// bytes, so the fallback is what keeps that case correct rather than
  /// silently unreadable. Trial decryption is safe here because AES-GCM
  /// authenticates: a wrong key fails the tag rather than returning wrong
  /// plaintext.
  ///
  /// Because a v1+ payload is encrypted with its header as associated data,
  /// stripping the header does not turn it into a readable step-2 payload.
  Future<Uint8List?> _decrypt(Uint8List packed) async {
    // 1. Versioned payload (version 1 and up).
    if (packed.length >= _kHeaderLength + _kAesGcmOverhead &&
        packed[0] == _kMagic0 &&
        packed[1] == _kMagic1) {
      final Uint8List? key = _keys[packed[2]];
      if (key != null) {
        final result = await _decryptWith(
          key,
          Uint8List.sublistView(packed, _kHeaderLength),
          aad: Uint8List.sublistView(packed, 0, _kHeaderLength),
        );
        if (result != null) return result;
      }
    }

    // 2. Headerless payload: everything written as version 0, plus every tag
    //    written before key versioning existed. No associated data.
    for (final int version in knownKeyVersions) {
      final result = await _decryptWith(_keys[version]!, packed);
      if (result != null) return result;
    }

    return null;
  }

  /// One AES-256-GCM attempt over [body] laid out as
  /// `[nonce][ciphertext][tag]`. Returns null on any failure — a short body, a
  /// wrong key, or tampered data — so callers can try the next candidate.
  Future<Uint8List?> _decryptWith(
    Uint8List key,
    Uint8List body, {
    Uint8List? aad,
  }) async {
    if (body.length < _kAesGcmOverhead) return null;

    // Desmenuzar el payload binario
    final nonce = Uint8List.sublistView(body, 0, _kNonceLength);
    final tag = Uint8List.sublistView(body, body.length - _kTagLength);
    final ciphertext = Uint8List.sublistView(
      body,
      _kNonceLength,
      body.length - _kTagLength,
    );

    try {
      // Reconstruir la caja criptográfica estructurada
      final secretBox = crypto.SecretBox(
        ciphertext,
        nonce: nonce,
        mac: crypto.Mac(tag),
      );

      // Desencriptado. Si los datos fueron alterados o la clave está mal,
      // el algoritmo arrojará una excepción matemática inmediatamente.
      final clearText = await _algorithm.decrypt(
        secretBox,
        secretKey: crypto.SecretKey(key),
        aad: aad ?? const <int>[],
      );

      return Uint8List.fromList(clearText);
    } catch (_) {
      // Retornar nulo si la firma o autenticidad fallaron (datos manipulados)
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
