// lib/src/features/auth/presentation/login_screen.dart

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_logo.dart';
import '../../home/presentation/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.showSessionExpired = false});

  /// When true, shows a one-time "session expired — sign in again" notice on the
  /// first frame. Set when a forced sign-out (rejected refresh token) routed the
  /// user back to login.
  final bool showSessionExpired;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberSession = true;

  @override
  void initState() {
    super.initState();
    if (widget.showSessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).sessionExpired),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    final loc = AppLocale.of(context);
    loc.setLocale(loc.locale == 'es' ? 'en' : 'es');
  }

  void _showForgotPasswordDialog() {
    final s = AppStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          s.forgotPassword,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          s.forgotPasswordMessage,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.ok,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: _LanguageToggle(onTap: _toggleLanguage),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      HwbLogo.large(),
                      const SizedBox(height: 18),
                      Text(
                        s.appName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.appSubtitleShort,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _LabeledField(
                              label: s.emailLabel,
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              hint: s.emailHint,
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return s.emailRequired;
                                }
                                final emailRegex = RegExp(
                                  r'^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(v.trim())) {
                                  return s.emailInvalid;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            _LabeledField(
                              label: s.passwordLabel,
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _login(),
                              suffix: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return s.passwordRequired;
                                }
                                if (v.length < 6) {
                                  return s.passwordTooShort;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          _RememberCheckbox(
                            value: _rememberSession,
                            onChanged: (v) =>
                                setState(() => _rememberSession = v ?? true),
                            label: s.rememberSession,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              s.forgotPassword,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.disabled,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              s.login,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        s.sessionEncryptedFooter,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    _emailFocus.unfocus();
    _passwordFocus.unfocus();
    final s = AppStrings.of(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AppScope.of(context).authRepository.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.loginFailed),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Logo ────────────────────────────────────────────────────────────────────

// ── Labeled field ───────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.suffix,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE3E5EA),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
            ),
            errorStyle: TextStyle(
              fontSize: 11,
              color: Colors.red.shade600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Remember checkbox ───────────────────────────────────────────────────────

class _RememberCheckbox extends StatelessWidget {
  const _RememberCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language toggle (ES / EN pill) ──────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEs = AppLocale.of(context).locale == 'es';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangPill(label: 'ES', selected: isEs, onTap: onTap),
          _LangPill(label: 'EN', selected: !isEs, onTap: onTap),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
