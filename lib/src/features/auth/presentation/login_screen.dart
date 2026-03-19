import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
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
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Prefill with backend-integrated local credentials for fast testing.
    _emailCtrl.text = 'doctor@hwb.org';
    _passwordCtrl.text = 'Doctor123!';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _LoginBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          const _StatusBarMock(),
                          const SizedBox(height: 32),
                          _buildAppIcon(),
                          const SizedBox(height: 20),
                          const Text(
                            'Sign in',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 56,
                              height: 1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 56),
                          _buildGoogleButton(),
                          const SizedBox(height: 26),
                          _buildOrUseEmail(),
                          const SizedBox(height: 26),
                          _buildInput(
                            controller: _emailCtrl,
                            hint: 'Input your email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildInput(
                            controller: _passwordCtrl,
                            hint: 'Password',
                            icon: Icons.password,
                            obscureText: _obscurePassword,
                            suffix: IconButton(
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildLoginButton(),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Not have account, create on here',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 18,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.secondary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const ScreenBottomHandle(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 152,
      height: 152,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(34),
      ),
      child: const Icon(
        Icons.health_and_safety,
        size: 88,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: 321,
      height: 41,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _loginWithBackendToken,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          disabledBackgroundColor: AppColors.disabled,
        ),
        icon: const Icon(Icons.g_mobiledata, size: 24, color: AppColors.white),
        label: const Text(
          'Sign with google',
          style: TextStyle(color: AppColors.white, fontSize: 32 / 1.8),
        ),
      ),
    );
  }

  Widget _buildOrUseEmail() {
    return SizedBox(
      width: 321,
      child: Row(
        children: const [
          Expanded(child: Divider(color: AppColors.secondary, thickness: 1.2)),
          SizedBox(width: 10),
          Text(
            'Or use email',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 10),
          Expanded(child: Divider(color: AppColors.secondary, thickness: 1.2)),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      width: 321,
      height: 41,
      decoration: BoxDecoration(
        color: const Color(0x99FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF424242), width: 1.5),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
          prefixIcon: Icon(icon, size: 20, color: AppColors.secondary),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 10),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: 321,
      height: 41,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _loginWithBackendToken,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          disabledBackgroundColor: AppColors.disabled,
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Icon(Icons.login, color: AppColors.white, size: 22),
        label: const Text(
          'Login',
          style: TextStyle(color: AppColors.white, fontSize: 30 / 1.7),
        ),
      ),
    );
  }

  Future<void> _loginWithBackendToken() async {
    setState(() => _isLoading = true);
    try {
      // Auth repository currently logs in against backend env credentials.
      await AppScope.of(context).authRepository.getAccessToken(forceRefresh: true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _StatusBarMock extends StatelessWidget {
  const _StatusBarMock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: const [
          Text('10:15', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
          Spacer(),
          Icon(Icons.signal_cellular_alt, size: 18, color: AppColors.textPrimary),
          SizedBox(width: 4),
          Icon(Icons.wifi, size: 18, color: AppColors.textPrimary),
          SizedBox(width: 4),
          Icon(Icons.battery_std, size: 18, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE4ECF4), Color(0xFFBDD7EC)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -90,
            bottom: -140,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            right: -35,
            top: -10,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 240,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.09),
              ),
            ),
          ),
          Positioned(
            right: 70,
            top: 285,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: 168,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
