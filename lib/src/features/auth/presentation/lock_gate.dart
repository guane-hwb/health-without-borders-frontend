// lib/src/features/auth/presentation/lock_gate.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_logo.dart';
import '../data/auth_repository.dart';
import 'login_screen.dart';

class LockController extends ChangeNotifier with WidgetsBindingObserver {
  LockController({
    required AuthRepository authRepository,
    Duration foregroundTimeout = const Duration(minutes: 10),
    Duration backgroundTimeout = const Duration(minutes: 10),
  }) : _authRepo = authRepository,
       _foregroundTimeout = foregroundTimeout,
       _backgroundTimeout = backgroundTimeout {
    WidgetsBinding.instance.addObserver(this);
    _authRepo.isLocalLocked.addListener(_onRepoLockChanged);
  }

  final AuthRepository _authRepo;
  final Duration _foregroundTimeout;
  final Duration _backgroundTimeout;

  Timer? _inactivityTimer;
  DateTime? _pausedAt;

  bool get isLocked => _authRepo.isLocalLocked.value;
  ValueListenable<bool> get lockedListenable => _authRepo.isLocalLocked;

  void _onRepoLockChanged() {
    notifyListeners();
  }

  void recordUserActivity() {
    if (isLocked) return;
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_authRepo.currentUser == null) return;
    _inactivityTimer = Timer(_foregroundTimeout, () {
      lock();
    });
  }

  void lock() {
    _inactivityTimer?.cancel();
    if (_authRepo.currentUser != null) {
      _authRepo.setLocalLocked(true);
    }
  }

  void unlock() {
    _authRepo.setLocalLocked(false);
    _resetInactivityTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authRepo.currentUser == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now();
      _inactivityTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      final pausedTime = _pausedAt;
      _pausedAt = null;
      if (pausedTime != null &&
          DateTime.now().difference(pausedTime) >= _backgroundTimeout) {
        lock();
      } else if (!isLocked) {
        _resetInactivityTimer();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authRepo.isLocalLocked.removeListener(_onRepoLockChanged);
    _inactivityTimer?.cancel();
    super.dispose();
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.authRepository,
    required this.onUnlocked,
  });

  final AuthRepository authRepository;
  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  static const int _maxAttempts = 5;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    final s = AppStrings.of(context);
    final password = _passwordCtrl.text;
    if (password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final valid = await widget.authRepository.verifyLocalLockPassword(password);

    if (!mounted) return;

    if (valid) {
      widget.onUnlocked();
    } else {
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        // 5 intentos fallidos -> logout conservando pendientes
        await widget.authRepository.logout(wipeLocalData: false);
        if (!mounted) return;
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const LoginScreen(showSessionExpired: true),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
          final remaining = _maxAttempts - _failedAttempts;
          _errorMessage = s.unlockAttemptsRemaining(remaining);
        });
        _passwordCtrl.clear();
        _passwordFocus.requestFocus();
      }
    }
  }

  Future<void> _switchUser() async {
    await widget.authRepository.logout(wipeLocalData: false);
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final user = widget.authRepository.currentUser;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HwbLogo.large(),
                  const SizedBox(height: 20),
                  Text(
                    s.unlockTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user != null
                        ? '${user.fullName} (${user.email})'
                        : s.unlockSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _passwordCtrl,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _verifyPassword(),
                    decoration: InputDecoration(
                      hintText: s.unlockPasswordHint,
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      errorText: _errorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              s.unlockButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _switchUser,
                    child: Text(
                      s.switchUser,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
