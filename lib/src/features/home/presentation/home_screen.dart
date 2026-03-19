import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../brigade/presentation/brigade_history_screen.dart';
import '../../nfc/presentation/loss_of_wristband_screen.dart';
import '../../nfc/presentation/read_nfc_screen.dart';
import '../../nfc/presentation/register_nfc_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _language = 'ES';
  bool _showAltLanguage = false;

  void _toggleLanguage() {
    setState(() {
      _language = _language == 'ES' ? 'EN' : 'ES';
      _showAltLanguage = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _showAltLanguage = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3DBE0),
      body: Stack(
        children: [
          const _HomeBackground(),
          SafeArea(
            child: Column(
              children: [
                _HomeHeader(
                  language: _language,
                  showAltLanguage: _showAltLanguage,
                  onToggleLanguage: _toggleLanguage,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 18, 0, 44),
                    child: Column(
                      children: [
                        _HomeActionCard(
                          icon: Icons.sync_alt_rounded,
                          title: 'Read NFC',
                          subtitle:
                              'Previously filled-out information\nis stored',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ReadNfcScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _HomeActionCard(
                          icon: Icons.edit_note_rounded,
                          title: 'Register NFC',
                          subtitle: 'Fill out the form',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterNfcScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _HomeActionCard(
                          icon: Icons.perm_identity_outlined,
                          title: 'Loss of wristband',
                          subtitle: 'The patient lost the wristband.',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const LossOfWristbandScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _HomeActionCard(
                          icon: Icons.format_list_numbered_rounded,
                          title: 'Brigade History',
                          subtitle: "View the patients' status.",
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const BrigadeHistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 116,
            right: 116,
            bottom: 14,
            child: ScreenBottomHandle(),
          ),
        ],
      ),
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          Container(
            height: 214,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, Color(0xFF45B4E5)],
              ),
            ),
            child: Stack(
              children: const [
                Positioned(
                  left: 26,
                  top: 82,
                  child: _BlurBubble(diameter: 42),
                ),
                Positioned(
                  right: 14,
                  top: 34,
                  child: _BlurBubble(diameter: 60),
                ),
                Positioned(
                  right: 70,
                  bottom: 10,
                  child: _BlurBubble(diameter: 120),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFD3DBE0),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurBubble extends StatelessWidget {
  const _BlurBubble({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.language,
    required this.showAltLanguage,
    required this.onToggleLanguage,
  });

  final String language;
  final bool showAltLanguage;
  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 103,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppColors.primary,
            ),
          ),
          const Positioned(
            left: 35,
            top: 12,
            child: Text(
              '10:15',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const Positioned(
            left: 14,
            top: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x2221ABE2),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.health_and_safety, color: AppColors.white),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 58,
            child: Center(
              child: Text(
                'Home',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 34 / 1.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            right: 58,
            top: 59,
            child: InkWell(
              onTap: onToggleLanguage,
              borderRadius: BorderRadius.circular(5),
              child: Container(
                width: 42,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.language, size: 13, color: AppColors.secondary),
                    const SizedBox(width: 2),
                    Text(
                      language,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showAltLanguage)
            Positioned(
              right: 56,
              top: 86,
              child: Container(
                width: 49,
                height: 21,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF2F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  language == 'ES' ? 'EN' : 'ES',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          const Positioned(
            right: 14,
            top: 52,
            child: SizedBox(
              width: 37,
              height: 37,
              child: Icon(Icons.account_circle_outlined, color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 329,
        height: 114,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 10,
              offset: Offset(1, 7),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Icon(icon, size: 50, color: AppColors.primary),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 24 / 1.05,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

