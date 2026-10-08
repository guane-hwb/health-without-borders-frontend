// lib/src/core/bootstrap/app_bootstrap.dart

import 'dart:async';

import 'package:flutter/foundation.dart';

class AppBootstrap {
  AppBootstrap({
    required ValueListenable<Object?> session,
    required VoidCallback startSync,
    required VoidCallback stopSync,
    required Future<Object?> Function() restoreSession,
  }) : _session = session,
       _startSync = startSync,
       _stopSync = stopSync,
       _restoreSession = restoreSession;

  final ValueListenable<Object?> _session;
  final VoidCallback _startSync;
  final VoidCallback _stopSync;
  final Future<Object?> Function() _restoreSession;

  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    _session.addListener(_onSessionChanged);
    unawaited(_restoreSession());
  }

  void _onSessionChanged() {
    if (_session.value != null) {
      _startSync();
    } else {
      _stopSync();
    }
  }

  void dispose() {
    if (!_attached) return;
    _attached = false;
    _session.removeListener(_onSessionChanged);
    _stopSync();
  }
}
