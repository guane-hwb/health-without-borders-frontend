// lib/src/features/auth/presentation/auth_gate.dart

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
  late final Future<UserSession?> _restore = widget.authRepository
      .restoreSession();

  /// The lock screen is painted by the app above its Navigator (`LockLayer`),
  /// not here. Until the first unlock this route only holds a blank page
  /// under it (no spinner turning behind the lock), so a restored session
  /// builds nothing of the user's before the password; from then on it keeps
  /// [HomeScreen], and later locks leave it where it is, with its state.
  bool _unlockedOnce = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserSession?>(
      future: _restore,
      builder: (BuildContext context, AsyncSnapshot<UserSession?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupSplash();
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        return ValueListenableBuilder<bool>(
          valueListenable: widget.authRepository.isLocalLocked,
          builder: (context, isLocked, _) {
            if (isLocked && !_unlockedOnce) {
              return const ColoredBox(color: AppColors.background);
            }
            _unlockedOnce = true;
            return const HomeScreen();
          },
        );
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
