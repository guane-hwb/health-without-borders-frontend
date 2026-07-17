// lib/src/features/auth/presentation/auth_gate.dart
//
// Startup gate. Decides the first screen based on whether a previous session
// can be restored from local storage — so a user is not sent back to login when
// the OS kills the app, even fully offline. While the (fast, storage-only)
// restore runs, a brief branded splash is shown to avoid a login-screen flash.

import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_logo.dart';
import '../../home/presentation/home_screen.dart';
import '../data/auth_repository.dart';
import '../domain/user_session.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Kick off the restore once. Held in a field so a rebuild does not re-run it
  // (FutureBuilder would otherwise restart the future on every build).
  late final Future<UserSession?> _restore = widget.authRepository
      .restoreSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserSession?>(
      future: _restore,
      builder: (BuildContext context, AsyncSnapshot<UserSession?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupSplash();
        }
        // A restored session (correct role) => straight to Home. Otherwise, or
        // on any restore error, fall through to login.
        return snapshot.data != null ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            HwbLogo.large(),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
