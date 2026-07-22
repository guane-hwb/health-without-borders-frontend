import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

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

/// Reads the factory UID from NFC wristbands.
///
/// The UID is the immutable serial number burned into every NFC chip.
/// It becomes the `device_uid` field in the backend.
///
/// This is a thin facade over [NfcSessionManager], which owns the radio. It
/// exists so the eight screens that scan a UID keep a one-line call site.
class NfcService {
  NfcService._();

  static Future<String> Function()? overrideReadDeviceUid;

  /// Seam for tests: supply a fake [NfcTagSource] instead of the real radio.
  @visibleForTesting
  static NfcTagSource tagSource = NfcSessionManager.instance;

  /// Seam for tests: the platform availability probe.
  ///
  /// Without this the only way to exercise [isAvailable] would be to mock the
  /// plugin's pigeon channels, which is the coupling this whole migration is
  /// getting rid of.
  @visibleForTesting
  static Future<NfcAvailability> Function() availabilityProbe = () =>
      NfcManager.instance.checkAvailability();

  @visibleForTesting
  static void resetForTest() {
    overrideReadDeviceUid = null;
    tagSource = NfcSessionManager.instance;
    availabilityProbe = () => NfcManager.instance.checkAvailability();
  }

  /// Whether NFC hardware is present and switched on.
  ///
  /// Asks the platform rather than reading [NfcSessionManager.state]: that
  /// state only ever reports `off` when reader mode could not be enabled, which
  /// is not the same as "this phone has no NFC".
  static Future<bool> get isAvailable async {
    try {
      return await availabilityProbe() == NfcAvailability.enabled;
    } catch (_) {
      return false;
    }
  }

  /// Waits for a chip and returns its factory UID.
  ///
  /// Returns the UID as a colon-separated hex string (e.g. "04:A1:B2:C3").
  ///
  /// Always resolves. Throws [NfcNotAvailableException] when the device lacks
  /// NFC hardware, [NfcDisabledException] when NFC is switched off,
  /// [NfcTimeoutException] when no chip arrives, [NfcTagAlreadyPresentException]
  /// when a chip is already parked on the antenna (Android will not re-poll it),
  /// [NfcCancelledException] on [stopSession] or [cancel], or
  /// [NfcSessionException] when the chip has no readable identifier.
  static Future<String> readDeviceUid({
    Duration timeout = NfcSessionManager.defaultTimeout,
    NfcCancelToken? cancel,
  }) async {
    if (overrideReadDeviceUid != null) {
      return overrideReadDeviceUid!();
    }
    return tagSource.withTag<String>(
      (HwbTag tag) async {
        if (tag.uid.isEmpty) {
          throw NfcSessionException('Could not read tag identifier.');
        }
        return tag.uid;
      },
      timeout: timeout,
      cancel: cancel,
    );
  }

  /// Aborts a pending scan. Safe to call from `dispose()`.
  ///
  /// The radio is not released — it belongs to the app for as long as the app
  /// is in the foreground, which is what keeps the OS tag viewer off the screen.
  /// Only the pending caller is released.
  static Future<void> stopSession() async {
    NfcSessionManager.instance.cancelPending();
  }
}

// ── Exceptions ──────────────────────────────────────────────────────────────
//
// NfcNotAvailableException now lives in nfc_session_types.dart and is
// re-exported above, so that the whole app catches one class rather than the
// three same-named-but-unrelated ones it used to declare.

