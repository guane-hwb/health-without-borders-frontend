import 'package:flutter/foundation.dart';

import 'nfc_session_manager.dart';

export 'nfc_session_manager.dart'
    show
        NfcBusyException,
        NfcCancelToken,
        NfcCancelledException,
        NfcDisabledException,
        NfcInterruptedException,
        NfcNotAvailableException,
        NfcSessionException,
        NfcTagAlreadyPresentException,
        NfcTimeoutException;

/// Web build: there is no radio. Kept API-identical to the mobile facade.
class NfcService {
  NfcService._();

  static Future<String> Function()? overrideReadDeviceUid;

  @visibleForTesting
  static NfcTagSource tagSource = NfcSessionManager.instance;

  @visibleForTesting
  static void resetForTest() {
    overrideReadDeviceUid = null;
    tagSource = NfcSessionManager.instance;
  }

  static Future<bool> get isAvailable async => false;

  static Future<String> readDeviceUid({
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
  }) async {
    if (overrideReadDeviceUid != null) {
      return overrideReadDeviceUid!();
    }
    throw NfcNotAvailableException();
  }

  static Future<void> stopSession() async {
    NfcSessionManager.instance.cancelPending();
  }
}
