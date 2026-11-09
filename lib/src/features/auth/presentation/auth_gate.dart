// lib/src/features/auth/presentation/auth_gate.dart

import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_logo.dart';
import '../../home/presentation/home_screen.dart';
import '../data/auth_repository.dart';
import '../domain/user_session.dart';
import 'lock_gate.dart';
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
            if (isLocked) {
              return LockScreen(
                authRepository: widget.authRepository,
                onUnlocked: () => widget.authRepository.setLocalLocked(false),
              );
            }
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
