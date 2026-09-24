// lib/src/features/auth/presentation/session_window_banner.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../design/tokens/app_colors.dart';

/// Wraps the app and shows a persistent strip while the session window is
/// closed.
///
/// Without it a cold start with no connectivity looks like a perfectly healthy
/// session, and the only hint that anything is wrong arrives when someone taps
/// a wristband and the read is refused — which reads as a broken reader rather
/// than an expired session.
///
/// The strip is deliberately not dismissable: the condition does not go away
/// on its own, and the fix (reconnect) is not obvious from the refusal alone.
class SessionWindowBanner extends StatelessWidget {
  const SessionWindowBanner({
    super.key,
    required this.windowClosed,
    required this.child,
  });

  /// Raised while the refresh token's window has lapsed.
  final ValueListenable<bool> windowClosed;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: windowClosed,
      builder: (BuildContext context, bool closed, Widget? body) {
        if (!closed) return body!;
        return Column(
          children: <Widget>[
            _Strip(),
            // The strip already consumed the top inset; without this every
            // Scaffold below would add it again and leave a gap.
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: body!,
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

class _Strip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isEs = AppStrings.of(context).isEs;
    return Material(
      color: AppColors.error,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              const Icon(Icons.wifi_off, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEs
                      ? 'Su sesión venció. Conéctese para renovarla; mientras '
                            'tanto no puede leer ni grabar dispositivos NFC.'
                      : 'Your session expired. Reconnect to renew it; until '
                            'then NFC devices cannot be read or written.',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
