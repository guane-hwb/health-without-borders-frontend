// lib/src/features/auth/presentation/change_password_screen.dart

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error_codes.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_screen_header.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/password_policy.dart';

/// Changes the signed-in user's password.
///
/// [mandatory]: the password was set by an administrator. The user cannot go
/// back, only change it or sign out; on success the app continues to Home.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.mandatory = false});

  final bool mandatory;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bool isEs = AppStrings.of(context).isEs;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppScope.of(context).authRepository.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEs ? 'Contraseña actualizada.' : 'Password updated.'),
          backgroundColor: AppColors.success,
        ),
      );
      if (widget.mandatory) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _messageFor(e, isEs: isEs));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = isEs
              ? 'No se pudo cambiar la contraseña. Revise la conexión e '
                    'intente de nuevo.'
              : 'Could not change the password. Check the connection and '
                    'try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// The two 400s carry no code; the app already refused a new password
  /// equal to the current one, so a 400 means the current one is wrong.
  static String _messageFor(ApiException e, {required bool isEs}) =>
      switch (e.statusCode) {
        400 =>
          isEs
              ? 'La contraseña actual no es correcta.'
              : 'The current password is not correct.',
        422 =>
          isEs
              ? 'La nueva contraseña no cumple la política: al menos '
                    '${PasswordPolicy.minLength} caracteres, máximo '
                    '${PasswordPolicy.maxBytes} bytes y que no sea común.'
              : 'The new password breaks the policy: at least '
                    '${PasswordPolicy.minLength} characters, at most '
                    '${PasswordPolicy.maxBytes} bytes, not a common one.',
        429 => ApiErrorCode.tooManyAttempts(e.retryAfter, isEs: isEs),
        _ =>
          ApiErrorCode.describe(e.code, isEs: isEs) ??
              (isEs
                  ? 'No se pudo cambiar la contraseña.'
                  : 'Could not change the password.'),
      };

  @override
  Widget build(BuildContext context) {
    final bool isEs = AppStrings.of(context).isEs;

    return PopScope(
      canPop: !widget.mandatory,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              HwbScreenHeader(
                title: isEs ? 'Cambiar contraseña' : 'Change password',
                showBack: !widget.mandatory,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (widget.mandatory) ...<Widget>[
                          _Notice(
                            text: isEs
                                ? 'Un administrador le asignó esta contraseña. '
                                      'Elija una propia para seguir usando '
                                      'la app.'
                                : 'An administrator set this password. Choose '
                                      'your own to keep using the app.',
                          ),
                          const SizedBox(height: 20),
                        ],
                        _PasswordField(
                          key: const Key('change_password_current'),
                          controller: _currentCtrl,
                          label: isEs ? 'Contraseña actual' : 'Current password',
                          obscure: _obscure,
                          validator: (String? v) => (v ?? '').isEmpty
                              ? (isEs
                                    ? 'Escriba la contraseña actual.'
                                    : 'Enter the current password.')
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _PasswordField(
                          key: const Key('change_password_new'),
                          controller: _newCtrl,
                          label: isEs ? 'Nueva contraseña' : 'New password',
                          helper: isEs
                              ? 'Al menos ${PasswordPolicy.minLength} '
                                    'caracteres. Evite contraseñas comunes.'
                              : 'At least ${PasswordPolicy.minLength} '
                                    'characters. Avoid common passwords.',
                          obscure: _obscure,
                          validator: (String? v) => PasswordPolicy.problem(
                            v ?? '',
                            current: _currentCtrl.text,
                            isEs: isEs,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PasswordField(
                          key: const Key('change_password_confirm'),
                          controller: _confirmCtrl,
                          label: isEs
                              ? 'Repita la nueva contraseña'
                              : 'Repeat the new password',
                          obscure: _obscure,
                          validator: (String? v) => v != _newCtrl.text
                              ? (isEs
                                    ? 'Las contraseñas no coinciden.'
                                    : 'The passwords do not match.')
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                            ),
                            label: Text(
                              _obscure
                                  ? (isEs ? 'Mostrar' : 'Show')
                                  : (isEs ? 'Ocultar' : 'Hide'),
                            ),
                          ),
                        ),
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(
                                    isEs
                                        ? 'Guardar contraseña'
                                        : 'Save password',
                                  ),
                          ),
                        ),
                        if (widget.mandatory) ...<Widget>[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _saving
                                ? null
                                : () => HomeScreen.confirmLogout(context),
                            icon: const Icon(Icons.logout_rounded, size: 16),
                            label: Text(AppStrings.of(context).logout),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.lock_reset, size: 20, color: Color(0xFFB26A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7A4F00)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscure,
    required this.validator,
    this.helper,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final bool obscure;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        errorMaxLines: 3,
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
