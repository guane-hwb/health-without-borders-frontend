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
import 'package:cryptography/cryptography.dart' as crypto;

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

  // ── AES-256-GCM REAL IMPLEMENTATION ────────────────────────────────────
  //
  // Wire format: [12-byte nonce][ciphertext][16-byte auth tag]

  Future<Uint8List> _encrypt(Uint8List plaintext) async {
    // Generar un nonce seguro y aleatorio de 12 bytes
    final nonce = _secureRandom(_kNonceLength);

    // Cifrado simétrico de alta seguridad utilizando el paquete oficial
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: crypto.SecretKey(_keyBytes),
      nonce: nonce,
    );

    // Empaquetar la estructura binaria final para el chip NFC
    final output = BytesBuilder(copy: false);
    output.add(nonce);
    output.add(secretBox.cipherText);
    output.add(
      secretBox.mac.bytes,
    ); // El tag de autenticación de 16 bytes (GCM)
    return output.toBytes();
  }

  Future<Uint8List?> _decrypt(Uint8List packed) async {
    if (packed.length < _kAesGcmOverhead) {
      throw FormatException(
        'Encrypted payload too short: ${packed.length} bytes '
        '(minimum $_kAesGcmOverhead)',
      );
    }

    // Desmenuzar el payload binario
    final nonce = Uint8List.sublistView(packed, 0, _kNonceLength);
    final tag = Uint8List.sublistView(packed, packed.length - _kTagLength);
    final ciphertext = Uint8List.sublistView(
      packed,
      _kNonceLength,
      packed.length - _kTagLength,
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
        secretKey: crypto.SecretKey(_keyBytes),
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
