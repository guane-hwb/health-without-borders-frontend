// lib/src/core/network/connectivity_service.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps `connectivity_plus` and exposes:
///  - [isOnline] — synchronous current state (updated on every change)
///  - [statusStream] — broadcast stream of [ConnectivityStatus]
///
/// Use [ConnectivityService.instance] after calling [init()] in `main()`.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isOnline = true;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Whether the device currently has a network connection.
  bool get isOnline => _isOnline;

  /// Broadcast stream that emits [ConnectivityStatus.online] or [offline]
  /// whenever the network state changes.
  Stream<ConnectivityStatus> get statusStream => _controller.stream;

  /// Must be called once at app startup (before [runApp]).
  Future<void> init() async {
    // Read current state
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);

    // Subscribe to changes
    _sub = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final bool online = _hasConnection(results);
        if (online != _isOnline) {
          _isOnline = online;
          _controller.add(
            online ? ConnectivityStatus.online : ConnectivityStatus.offline,
          );
        }
      },
    );
  }

  /// Releases the connectivity subscription.
  void dispose() {
    _sub?.cancel();
    _controller.close();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((ConnectivityResult r) => r != ConnectivityResult.none);
  }
}

enum ConnectivityStatus { online, offline }