// lib/src/core/nfc/nfc_keyring.dart
//
// The set of NFC encryption keys a device holds, addressed by version.
//
// Before key versioning there was a single global key and a tag carried no
// hint about which key encrypted it, so the key could never be rotated: with
// two keys in play a reader had no way to tell which one a given wristband
// needed, nor any way to know when a migration had finished.
//
// A keyring fixes that. The backend delivers every *live* key plus the version
// new writes should use. A device can therefore decrypt any tag still in
// circulation while offline (old versions stay in the ring) and encrypt with
// the current one. Rotation becomes: publish a new version, let tags migrate
// as they are rewritten, then drop the old version from the ring.

/// Version reserved for the pre-versioning global key (`NFC_MASTER_KEY`).
///
/// Tags written before key versioning carry no version header and are
/// decrypted with this version.
const int kLegacyNfcKeyVersion = 0;

/// An immutable map of `version -> hex AES-256 key`, plus the version that new
/// writes should be encrypted with.
///
/// [currentVersion] is null when the backend delivered keys but no usable
/// current version (a misconfigured deployment). Reads still work in that
/// case; writes are refused rather than silently using an arbitrary key.
class NfcKeyring {
  NfcKeyring({required Map<int, String> keys, this.currentVersion})
    : keys = Map<int, String>.unmodifiable(keys);

  /// A single-key ring, used by the legacy call path and by tests.
  factory NfcKeyring.single(String hexKey, {int version = kLegacyNfcKeyVersion}) {
    return NfcKeyring(
      keys: <int, String>{version: hexKey},
      currentVersion: version,
    );
  }

  /// Builds a keyring from a login, refresh, or `/users/me` response body.
  ///
  /// Reads `nfc_keyring` (`{"0": "<hex>", ...}` — JSON object keys are strings,
  /// so they are parsed back to ints) and `nfc_key_version`. Falls back to the
  /// legacy single `nfc_encryption_key` field when the keyring is absent, so a
  /// client keeps working against a backend that predates versioning.
  ///
  /// Returns null when the response carries no usable key material at all.
  static NfcKeyring? fromResponse(Map<String, dynamic> data) {
    final keys = <int, String>{};

    final Object? rawRing = data['nfc_keyring'];
    if (rawRing is Map<Object?, Object?>) {
      rawRing.forEach((Object? version, Object? hex) {
        final int? parsedVersion = int.tryParse(version.toString());
        final String hexKey = hex?.toString() ?? '';
        if (parsedVersion != null && hexKey.isNotEmpty) {
          keys[parsedVersion] = hexKey;
        }
      });
    }

    final String legacyKey = data['nfc_encryption_key']?.toString() ?? '';
    final int? declaredVersion = int.tryParse(
      data['nfc_key_version']?.toString() ?? '',
    );

    // Backend without versioning: the single key is version 0 by definition.
    if (keys.isEmpty) {
      if (legacyKey.isEmpty) return null;
      return NfcKeyring.single(legacyKey);
    }

    // Keep the legacy field as a safety net if it names a key the ring omitted.
    if (legacyKey.isNotEmpty &&
        declaredVersion != null &&
        !keys.containsKey(declaredVersion)) {
      keys[declaredVersion] = legacyKey;
    }

    // Only trust a declared version we actually hold a key for.
    final int? current = (declaredVersion != null &&
            keys.containsKey(declaredVersion))
        ? declaredVersion
        : null;

    return NfcKeyring(keys: keys, currentVersion: current);
  }

  /// Restores a keyring from [toJson].
  static NfcKeyring? fromJson(Map<String, dynamic> json) {
    return fromResponse(json);
  }

  final Map<int, String> keys;

  /// Version new writes use, or null when no usable current version exists.
  final int? currentVersion;

  bool get isEmpty => keys.isEmpty;

  bool get isNotEmpty => keys.isNotEmpty;

  /// Whether this ring can encrypt a new payload.
  bool get canWrite => currentVersion != null;

  /// The hex key for [version], or null when this device does not hold it.
  String? keyFor(int version) => keys[version];

  /// The hex key new writes should use, or null when there is none.
  String? get currentKey {
    final int? version = currentVersion;
    return version == null ? null : keys[version];
  }

  /// Versions held, ascending, with [kLegacyNfcKeyVersion] first when present.
  List<int> get versions {
    final sorted = keys.keys.toList()..sort();
    return sorted;
  }

  /// Serialises to the same shape the backend sends, so the value can be
  /// round-tripped through storage without a second format to maintain.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nfc_keyring': <String, String>{
        for (final MapEntry<int, String> e in keys.entries)
          e.key.toString(): e.value,
      },
      if (currentVersion != null) 'nfc_key_version': currentVersion,
    };
  }

  @override
  String toString() =>
      'NfcKeyring(versions: $versions, current: $currentVersion)';
}
