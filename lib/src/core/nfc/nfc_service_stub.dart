class NfcService {
  NfcService._();

  static Future<String> Function()? overrideReadDeviceUid;

  static Future<bool> get isAvailable async => false;

  static Future<String> readDeviceUid() async {
    if (overrideReadDeviceUid != null) {
      return overrideReadDeviceUid!();
    }
    throw NfcNotAvailableException();
  }

  static Future<void> stopSession() async {}
}

class NfcNotAvailableException implements Exception {
  @override
  String toString() => 'NFC is not available on this device.';
}

class NfcSessionException implements Exception {
  NfcSessionException(this.message);
  final String message;
  @override
  String toString() => message;
}