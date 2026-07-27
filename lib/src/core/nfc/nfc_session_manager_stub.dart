// lib/src/core/nfc/nfc_session_manager_stub.dart

import 'package:flutter/foundation.dart';

import 'nfc_session_types.dart';

/// Web build of the radio owner: there is no radio.
///
/// Kept API-identical to the mobile implementation so presentation code can
/// depend on it unconditionally and simply render [NfcRadioState.unsupported].
class NfcSessionManager implements NfcTagSource {
  NfcSessionManager._();

  static final NfcSessionManager instance = NfcSessionManager._();

  static const Duration defaultTimeout = Duration(seconds: 20);
  static const Duration presenceWindow = Duration(seconds: 4);

  final ValueNotifier<NfcRadioState> radioState = ValueNotifier<NfcRadioState>(
    NfcRadioState.unsupported,
  );

  Future<void> attach() async {}

  @visibleForTesting
  Future<void> detach() async {}

  void cancelPending() {}

  @override
  Future<T> withTag<T>(
    Future<T> Function(HwbTag tag) action, {
    Duration timeout = defaultTimeout,
    NfcCancelToken? cancel,
    String? alertMessage,
  }) async {
    throw NfcNotAvailableException();
  }
}
