// lib/src/features/home/presentation/home_screen.dart

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_logo.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../auth/domain/user_session.dart';
import '../../../core/sync/sync_engine.dart';

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
        await Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final user = scope.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      });
      return const SizedBox.shrink();
    }

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
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.manageOrgs),
        ),
        const SizedBox(height: 14),
        _ActionCard(
          icon: Icons.bar_chart_rounded,
          iconBg: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF1565C0),
          title: s.brigadeStatsTitle,
          subtitle: s.brigadeStatsSubtitle,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.brigadeStats),
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
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.manageUsers),
        ),
        const SizedBox(height: 14),
        _ActionCard(
          icon: Icons.search_rounded,
          iconBg: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF1565C0),
          title: s.actionSearchPatient,
          subtitle: s.actionSearchPatientSubAdmin,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.lossWristband),
        ),
        const SizedBox(height: 14),
        _ActionCard(
          icon: Icons.bar_chart_rounded,
          iconBg: const Color(0xFFEDE7F6),
          iconColor: const Color(0xFF5E35B1),
          title: s.brigadeStatsTitle,
          subtitle: s.brigadeStatsSubtitle,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.brigadeStatsOrg),
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
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.readNfc),
        ),
        const SizedBox(height: 14),
        if (user.role.canRegisterPatient) ...[
          _ActionCard(
            icon: Icons.person_add_alt_1_rounded,
            iconBg: const Color(0xFFE5E7E8),
            iconColor: const Color(0xFF37474F),
            title: s.actionNewPatient,
            subtitle: s.actionNewPatientSub,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.registerNfc),
          ),
          const SizedBox(height: 14),
        ],
        _ActionCard(
          icon: Icons.search_rounded,
          iconBg: const Color(0xFFFCF4E1),
          iconColor: const Color(0xFFE6A817),
          title: s.actionSearchPatient,
          subtitle: s.actionSearchPatientSub,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.lossWristband),
        ),
        const SizedBox(height: 14),
        _SyncCard(
          onTap: () async {
            await Navigator.of(context).pushNamed(AppRoutes.syncQueue);
            if (context.mounted) {
              await AppScope.of(context).syncEngine.refreshPendingCount();
            }
          },
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

class _SyncCard extends StatefulWidget {
  const _SyncCard({required this.onTap});
  final Future<void> Function() onTap;

  @override
  State<_SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends State<_SyncCard> {
  int _pendingCount = 0;
  bool _initialized = false;
  SyncEngine? _engineRef;

  void Function(int)? _previousSyncStatusCallback;
  void Function(String, bool, String?)? _previousRecordSyncedCallback;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _setupListenersAndRefresh();
    }
  }

  void _setupListenersAndRefresh() {
    final scope = AppScope.of(context);
    _engineRef = scope.syncEngine;

    if (_engineRef == null) return;

    _previousSyncStatusCallback = _engineRef!.onSyncStatusChanged;
    _previousRecordSyncedCallback = _engineRef!.onRecordSynced;

    _engineRef!.onSyncStatusChanged = (int count) {
      _previousSyncStatusCallback?.call(count);
      _fetchCount();
    };

    _engineRef!.onRecordSynced = (String id, bool success, String? err) {
      _previousRecordSyncedCallback?.call(id, success, err);
      _fetchCount();
    };

    _engineRef!.pendingCount.addListener(_fetchCount);
    _fetchCount();
  }

  @override
  void dispose() {
    if (_engineRef != null) {
      _engineRef!.pendingCount.removeListener(_fetchCount);
      _engineRef!.onSyncStatusChanged = _previousSyncStatusCallback;
      _engineRef!.onRecordSynced = _previousRecordSyncedCallback;
    }
    super.dispose();
  }

  Future<void> _fetchCount() async {
    if (!mounted) return;
    final scope = AppScope.of(context);
    int count = scope.syncEngine.pendingCount.value;

    try {
      final dbCount = await scope.localDatabase.getUnsyncedCount();
      count = dbCount;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _pendingCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final s = AppStrings.of(context);
    final hasPending = _pendingCount > 0;
    final subtitle = hasPending
        ? s.actionPendingSyncCount(_pendingCount)
        : s.actionPendingSyncEmpty;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () async {
          await widget.onTap();

          if (mounted) {
            await scope.syncEngine.refreshPendingCount();
            await _fetchCount();
          }
        },
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
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasPending
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_done_outlined,
                  size: 24,
                  color: const Color(0xFF4CAF50),
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
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4A017),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_pendingCount',
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
