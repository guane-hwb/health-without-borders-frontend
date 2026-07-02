// lib/src/features/home/presentation/home_screen.dart
//
// Home screen — restores the original visual design (logo + brand name in header,
// white action cards with distinct colored icons) while keeping current functionality
// (logout at bottom, superadmin/org_admin/clinical role-based bodies).

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_logo.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../admin/presentation/brigade_stats_screen.dart';
import '../../admin/presentation/manage_organizations_screen.dart';
import '../../admin/presentation/manage_users_screen.dart';
import '../../auth/domain/user_session.dart';
import '../../auth/presentation/login_screen.dart';
import '../../nfc/presentation/loss_of_wristband_screen.dart';
import '../../nfc/presentation/read_nfc_screen.dart';
import '../../nfc/presentation/register/register_nfc_screen.dart';
import '../../sync/presentation/sync_queue_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _greeting(AppStrings s) {
    final hour = DateTime.now().hour;
    if (hour < 12) return s.goodMorning;
    if (hour < 18) return s.goodAfternoon;
    return s.goodEvening;
  }

  Future<void> _logout(BuildContext context) async {
    final s = AppStrings.of(context);
    final scope = AppScope.of(context);
    final name = scope.currentUser?.fullName ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.logoutTitle),
        content: Text(s.logoutConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              s.logout,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await scope.authRepository.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final user = scope.currentUser;
    if (user == null) return const LoginScreen();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  user: user,
                  greeting: _greeting(AppStrings.of(context)),
                ),
                Expanded(child: _buildBody(context, user)),
              ],
            ),
            const Positioned(
              left: 116,
              right: 116,
              bottom: 14,
              child: ScreenBottomHandle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserSession user) {
    return switch (user.role) {
      UserRole.superadmin => _buildSuperadminBody(context),
      UserRole.orgAdmin => _buildOrgAdminBody(context),
      UserRole.doctor || UserRole.nurse => _buildClinicalBody(context, user),
    };
  }

  // ── SUPERADMIN ────────────────────────────────────────────────────────────

  Widget _buildSuperadminBody(BuildContext context) {
    final s = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
      children: [
        _ActionCard(
          icon: Icons.business_outlined,
          iconBg: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF2E7D32),
          title: s.manageOrgsTitle,
          subtitle: s.manageOrgsSubtitle,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ManageOrganizationsScreen(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _ActionCard(
          icon: Icons.bar_chart_rounded,
          iconBg: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF1565C0),
          title: s.brigadeStatsTitle,
          subtitle: s.brigadeStatsSubtitle,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BrigadeStatsScreen())),
        ),
        const SizedBox(height: 28),
        _LogoutButton(onTap: () => _logout(context)),
      ],
    );
  }

  // ── ORG ADMIN ─────────────────────────────────────────────────────────────

  Widget _buildOrgAdminBody(BuildContext context) {
    final s = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
      children: [
        _ActionCard(
          icon: Icons.people_alt_outlined,
          iconBg: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF2E7D32),
          title: s.adminManageUsers,
          subtitle: s.adminManageUsersSub,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
        ),
        const SizedBox(height: 14),
        _ActionCard(
          icon: Icons.search_rounded,
          iconBg: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF1565C0),
          title: s.actionSearchPatient,
          subtitle: s.actionSearchPatientSubAdmin,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LossOfWristbandScreen()),
          ),
        ),
        const SizedBox(height: 28),
        _LogoutButton(onTap: () => _logout(context)),
      ],
    );
  }

  // ── DOCTOR / NURSE ────────────────────────────────────────────────────────

  Widget _buildClinicalBody(BuildContext context, UserSession user) {
    final s = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
      children: [
        _ActionCard(
          icon: Icons.nfc_rounded,
          iconBg: const Color(0xFFE2F4FB),
          iconColor: const Color(0xFF1CABE2),
          title: s.actionReadNfc,
          subtitle: s.actionReadNfcSub,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ReadNfcScreen())),
        ),
        const SizedBox(height: 14),
        if (user.role.canRegisterPatient) ...[
          _ActionCard(
            icon: Icons.person_add_alt_1_rounded,
            iconBg: const Color(0xFFE5E7E8),
            iconColor: const Color(0xFF37474F),
            title: s.actionNewPatient,
            subtitle: s.actionNewPatientSub,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegisterNfcScreen()),
            ),
          ),
          const SizedBox(height: 14),
        ],
        _ActionCard(
          icon: Icons.search_rounded,
          iconBg: const Color(0xFFFCF4E1),
          iconColor: const Color(0xFFE6A817),
          title: s.actionSearchPatient,
          subtitle: s.actionSearchPatientSub,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LossOfWristbandScreen()),
          ),
        ),
        const SizedBox(height: 14),
        _SyncCard(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SyncQueueScreen())),
        ),
        const SizedBox(height: 28),
        _LogoutButton(onTap: () => _logout(context)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.greeting});
  final UserSession user;
  final String greeting;

  String _roleLabel(BuildContext context, UserRole r) {
    final s = AppStrings.of(context);
    return switch (r) {
      UserRole.superadmin => s.roleSuperadmin,
      UserRole.orgAdmin => s.roleOrgAdmin,
      UserRole.doctor => s.roleDoctor,
      UserRole.nurse => s.roleNurse,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: logo + brand name + language switcher ──
          Row(
            children: [
              const HwbLogo(size: 38, onDark: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.of(context).appName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              _LocaleSwitcher(),
            ],
          ),
          const SizedBox(height: 16),
          // ── Greeting + name ──
          Text(
            '$greeting,',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            user.fullName,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // ── Role badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 13,
                  color: AppColors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _roleLabel(context, user.role),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocaleSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context).locale;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['es', 'en'].map((lang) {
          final selected = locale == lang;
          return GestureDetector(
            onTap: () => AppLocale.of(context).setLocale(lang),
            child: Container(
              margin: const EdgeInsets.only(left: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                lang.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Generic action card (white background, colored icon) ────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF0), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: subtitle != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sync card (special: shows pending count + amber state) ──────────────────

class _SyncCard extends StatefulWidget {
  const _SyncCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends State<_SyncCard> {
  @override
  void initState() {
    super.initState();
    // Pull a fresh count whenever the home screen is shown. The actual value
    // is rendered reactively from the sync engine's notifier below, so a
    // background sync that finishes while we're on another screen is reflected
    // here automatically.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AppScope.of(context).syncEngine.refreshPendingCount(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: AppScope.of(context).syncEngine.pendingCount,
      builder: (context, pending, _) {
        final subtitle = pending == 0
            ? s.actionPendingSyncEmpty
            : s.actionPendingSyncCount(pending);

        final hasPending = pending > 0;
        const cardBg = AppColors.white;
        const iBg = Color(0xFFE8F5E8);
        const iColor = Color(0xFF4CAF50);

        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECF0), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      hasPending
                          ? Icons.cloud_upload_outlined
                          : Icons.cloud_done_outlined,
                      size: 24,
                      color: iColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.actionPendingSync,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasPending
                                ? const Color(0xFFB8860B)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasPending)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A017),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pending',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Logout button ───────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.logout_rounded,
          size: 16,
          color: AppColors.textSecondary,
        ),
        label: Text(
          AppStrings.of(context).logout,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }
}
