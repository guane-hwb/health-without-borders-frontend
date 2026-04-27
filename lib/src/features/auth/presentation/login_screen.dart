// lib/src/features/auth/presentation/login_screen.dart

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../home/presentation/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus   = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background (never intercepts events) ──────────────────────
            const IgnorePointer(child: _LoginBackground()),

            // ── Foreground ────────────────────────────────────────────────
            Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _appIcon(),
                      const SizedBox(height: 20),
                      Text(s.signIn,
                          style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 48,
                              height: 1.1,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 48),

                      // ── Email ──────────────────────────────────────────
                      _InputField(
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        hint: s.emailHint,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: 16),

                      // ── Password ───────────────────────────────────────
                      _InputField(
                        controller: _passwordCtrl,
                        focusNode: _passwordFocus,
                        hint: s.password,
                        icon: Icons.password,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        suffix: IconButton(
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 20,
                              color: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Login button ───────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.disabled,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white))
                              : const Icon(Icons.login,
                                  color: AppColors.white, size: 22),
                          label: Text(s.login,
                              style: const TextStyle(
                                  color: AppColors.white, fontSize: 17)),
                        ),
                      ),

                      const SizedBox(height: 32),
                      const ScreenBottomHandle(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
            ),
          ],
        ),
    );
  }

  Widget _appIcon() => Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(32)),
        child: const Icon(Icons.health_and_safety,
            size: 82, color: AppColors.white),
      );

  Future<void> _login() async {
    _emailFocus.unfocus();
    _passwordFocus.unfocus();

    final s        = AppStrings.of(context);
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.enterEmailPassword)));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AppScope.of(context)
          .authRepository
          .login(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${s.loginFailed}: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Standalone input widget ─────────────────────────────────────────────────
// Extracted to a StatelessWidget so it has its own render object and hit-test
// area — avoids the focus/pointer issue that occurs when TextFields are
// built inline inside a parent StatefulWidget's build() method on Flutter Web.

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText  = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final FocusNode             focusNode;
  final String                hint;
  final IconData              icon;
  final TextInputType         keyboardType;
  final bool                  obscureText;
  final TextInputAction       textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget?               suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:      controller,
      focusNode:       focusNode,
      keyboardType:    keyboardType,
      obscureText:     obscureText,
      textInputAction: textInputAction,
      onSubmitted:     onSubmitted,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: const TextStyle(
            fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: AppColors.secondary),
        suffixIcon: suffix,
        filled:    true,
        fillColor: const Color(0xCCFFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFFB0BEC5), width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

// ── Background ──────────────────────────────────────────────────────────────

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE4ECF4), Color(0xFFBDD7EC)])),
        child: Stack(children: [
          Positioned(
              left: -90, bottom: -140,
              child: Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.14)))),
          Positioned(
              right: -35, top: -10,
              child: Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.08)))),
          Positioned(
              left: 20, top: 240,
              child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.09)))),
        ]),
      );
}