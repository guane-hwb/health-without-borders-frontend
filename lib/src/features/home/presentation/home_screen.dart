// lib/src/features/home/presentation/home_screen.dart
//
// CAMBIOS vs versión anterior:
//   - _buildSuperadminBody: "Gestionar organizaciones" ya no muestra subtitle
//   - _logout: reemplaza la llamada de logout con el método correcto del proyecto
//     ⚠️  Busca el comentario TODO_LOGOUT y reemplaza con el método real de AuthRepository

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
import '../../nfc/presentation/brigade_history_screen.dart';
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
      await scope.authRepository.clearSession();
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
      backgroundColor: const Color(0xFFEBF2F8),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      children: [
        _AdminNavCard(
          icon: Icons.business_outlined,
          iconBg: const Color(0xFFE1F5EE),
          iconColor: const Color(0xFF0F6E56),
          title: 'Gestionar organizaciones',
          subtitle: null, // sin descripción
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ManageOrganizationsScreen(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AdminNavCard(
          icon: Icons.bar_chart_rounded,
          iconBg: const Color(0xFFE6F1FB),
          iconColor: const Color(0xFF185FA5),
          title: 'Estadísticas de brigadas',
          subtitle: null, // sin descripción
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BrigadeStatsScreen())),
        ),
        const SizedBox(height: 24),
        _LogoutButton(onTap: () => _logout(context)),
      ],
    );
  }

  // ── ORG ADMIN ─────────────────────────────────────────────────────────────

  Widget _buildOrgAdminBody(BuildContext context) {
    final s = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      children: [
        _AdminNavCard(
          icon: Icons.people_alt_outlined,
          iconBg: const Color(0xFFE1F5EE),
          iconColor: AppColors.primary,
          title: s.adminManageUsers,
          subtitle: s.adminManageUsersSub,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
        ),
        const SizedBox(height: 12),
        _AdminNavCard(
          icon: Icons.manage_search_rounded,
          iconBg: const Color(0xFFE6F1FB),
          iconColor: const Color(0xFF185FA5),
          title: s.adminViewPatients,
          subtitle: s.adminViewPatientsSub,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LossOfWristbandScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _AdminNavCard(
          icon: Icons.format_list_bulleted_rounded,
          iconBg: const Color(0xFFFAEEDA),
          iconColor: const Color(0xFF633806),
          title: s.brigadeHistory,
          subtitle: s.brigadeHistorySub,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BrigadeHistoryScreen()),
          ),
        ),
        const SizedBox(height: 24),
        _LogoutButton(onTap: () => _logout(context)),
      ],
    );
  }

  // ── CLINICAL STAFF ────────────────────────────────────────────────────────

  Widget _buildClinicalBody(BuildContext context, UserSession user) {
    final s = AppStrings.of(context);
    final canRegister = user.role == UserRole.doctor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      children: [
        _ActionCard(
          icon: Icons.nfc_rounded,
          title: s.actionReadNfc,
          subtitle: s.actionReadNfcSub,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ReadNfcScreen())),
        ),
        const SizedBox(height: 12),
        if (canRegister) ...[
          _ActionCard(
            icon: Icons.person_add_alt_1_rounded,
            title: s.actionNewPatient,
            subtitle: s.actionNewPatientSub,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegisterNfcScreen()),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _ActionCard(
          icon: Icons.search_rounded,
          title: s.actionSearchPatient,
          subtitle: s.actionSearchPatientSub,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LossOfWristbandScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _SyncCard(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SyncQueueScreen())),
        ),
        const SizedBox(height: 24),
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
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HwbLogo(size: 30, onDark: true),
              const Spacer(),
              _LocaleSwitcher(),
            ],
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['es', 'en'].map((lang) {
        final selected = locale == lang;
        return GestureDetector(
          onTap: () => AppLocale.of(context).setLocale(lang),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.2),
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
    );
  }
}

// ── Admin/superadmin nav card — subtitle es opcional ──────────────────────

class _AdminNavCard extends StatelessWidget {
  const _AdminNavCard({
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
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
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncCard extends StatefulWidget {
  const _SyncCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends State<_SyncCard> {
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _countPending());
  }

  Future<void> _countPending() async {
    try {
      final count = await AppScope.of(context).localDatabase.getUnsyncedCount();
      if (mounted) setState(() => _pending = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final subtitle = _pending == 0
        ? s.actionPendingSyncEmpty
        : s.actionPendingSyncCount(_pending);

    return Material(
      color: _pending > 0 ? const Color(0xFFFFF8E1) : AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _pending > 0
                      ? const Color(0xFFFFF3CD)
                      : const Color(0xFFE1F5EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _pending > 0
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_done_outlined,
                  size: 24,
                  color: _pending > 0
                      ? const Color(0xFFD4A017)
                      : AppColors.primary,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _pending > 0
                            ? const Color(0xFFB8860B)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_pending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A017),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_pending',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.logout,
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
