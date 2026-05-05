// lib/src/features/home/presentation/home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/hwb_logo.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../admin/presentation/manage_users_screen.dart';
import '../../auth/domain/user_session.dart';
import '../../auth/presentation/login_screen.dart';
import '../../brigade/presentation/brigade_history_screen.dart';
import '../../nfc/presentation/loss_of_wristband_screen.dart';
import '../../nfc/presentation/read_nfc_screen.dart';
import '../../nfc/presentation/register/register_nfc_screen.dart';
import '../../sync/presentation/sync_queue_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserSession? _user;
  int _unsyncedCount = 0;
  bool _isOnline = ConnectivityService.instance.isOnline;
  StreamSubscription<ConnectivityStatus>? _connSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    _connSub = ConnectivityService.instance.statusStream.listen((status) {
      if (mounted) {
        setState(() => _isOnline = status == ConnectivityStatus.online);
      }
    });
  }

  Future<void> _init() async {
    final scope = AppScope.of(context);
    _user = await scope.authRepository.getCurrentUser();
    scope.syncEngine.onSyncStatusChanged = (int n) {
      if (mounted) {
        setState(() => _unsyncedCount = n);
      }
    };
    scope.syncEngine.start();
    final count = await scope.localDatabase.getUnsyncedCount();
    if (mounted) {
      setState(() => _unsyncedCount = count);
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshCount() async {
    final n = await AppScope.of(context).localDatabase.getUnsyncedCount();
    if (mounted) {
      setState(() => _unsyncedCount = n);
    }
  }

  void _toggleLanguage() {
    final loc = AppLocale.of(context);
    loc.setLocale(loc.locale == 'es' ? 'en' : 'es');
  }

  Future<void> _logout() async {
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.logoutTitle),
        content: Text(s.logoutConfirm(_user?.shortName ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              s.logout,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final scope = AppScope.of(context);
    final navigator = Navigator.of(context);
    scope.syncEngine.stop();
    await scope.authRepository.clearSession();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.disabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                AppStrings.of(context).logout,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _user?.role ?? UserRole.doctor;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _HomeHeader(
                  user: _user,
                  onToggleLanguage: _toggleLanguage,
                  onMenu: _openMenu,
                ),
                Expanded(child: _buildBody(role)),
              ],
            ),
            const Positioned(
              left: 116,
              right: 116,
              bottom: 14,
              child: ScreenBottomHandle(),
            ),
            // Quiet offline indicator (small chip in corner, optional context)
            if (!_isOnline)
              Positioned(top: 12, left: 16, child: _OfflineChip()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(UserRole role) {
    // _ClinicalHome now handles all roles — it shows/hides actions
    // based on the role's permissions. Admins see manage users + search.
    // Superadmin sees only manage users (zero clinical access via canScanNfc etc).
    return _ClinicalHome(
      role: role,
      unsyncedCount: _unsyncedCount,
      onRefresh: _refreshCount,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════════

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.user,
    required this.onToggleLanguage,
    required this.onMenu,
  });

  final UserSession? user;
  final VoidCallback onToggleLanguage;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = AppLocale.of(context).locale == 'es';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? s.goodMorning
        : hour < 19
        ? s.goodAfternoon
        : s.goodEvening;
    final role = user?.role ?? UserRole.doctor;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: logo + actions ──────────────────────────
          Row(
            children: [
              const _HeaderLogo(),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Health Without Borders',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _HeaderLangToggle(isEs: isEs, onTap: onToggleLanguage),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.menu, color: AppColors.white),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Greeting + name + role ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.shortName ?? '...',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(_roleIcon(role), size: 14, color: Colors.white70),
                    const SizedBox(width: 5),
                    Text(
                      _roleLabel(role, s),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _roleIcon(UserRole r) {
    switch (r) {
      case UserRole.doctor:
        return Icons.local_hospital;
      case UserRole.nurse:
        return Icons.health_and_safety;
      case UserRole.orgAdmin:
        return Icons.admin_panel_settings;
      case UserRole.superadmin:
        return Icons.shield;
    }
  }

  static String _roleLabel(UserRole r, AppStrings s) {
    switch (r) {
      case UserRole.doctor:
        return s.roleDoctor;
      case UserRole.nurse:
        return s.roleNurse;
      case UserRole.orgAdmin:
        return s.roleOrgAdmin;
      case UserRole.superadmin:
        return s.roleSuperadmin;
    }
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo();

  @override
  Widget build(BuildContext context) {
    return const HwbLogo(size: 36, onDark: true);
  }
}

class _HeaderLangToggle extends StatelessWidget {
  const _HeaderLangToggle({required this.isEs, required this.onTap});
  final bool isEs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(label: 'ES', selected: isEs, onTap: onTap),
          _LangChip(label: 'EN', selected: !isEs, onTap: onTap),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.white,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CLINICAL HOME (Doctor / Nurse) — 4 vertical action rows
// ═══════════════════════════════════════════════════════════════════

class _ClinicalHome extends StatelessWidget {
  const _ClinicalHome({
    required this.role,
    required this.unsyncedCount,
    required this.onRefresh,
  });
  final UserRole role;
  final int unsyncedCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
      children: [
        // Leer NFC — doctor, nurse only
        if (role.canScanNfc) ...[
          _ActionCardWide(
            icon: Icons.nfc_rounded,
            iconColor: AppColors.primary,
            title: s.actionReadNfc,
            subtitle: s.actionReadNfcSub,
            onTap: () => _push(context, const ReadNfcScreen()),
          ),
          const SizedBox(height: 12),
        ],

        // Nuevo paciente — doctor, nurse only
        if (role.canRegisterPatient) ...[
          _ActionCardWide(
            icon: Icons.person_add_alt_1_rounded,
            iconColor: const Color(0xFF37474F),
            title: s.actionNewPatient,
            subtitle: s.actionNewPatientSub,
            onTap: () async {
              await _push(context, const RegisterNfcScreen());
              onRefresh();
            },
          ),
          const SizedBox(height: 12),
        ],

        // Buscar paciente — doctor, nurse, org_admin
        if (role.canSearchPatient) ...[
          _ActionCardWide(
            icon: Icons.search_rounded,
            iconColor: const Color(0xFFE6A817),
            title: s.actionSearchPatient,
            subtitle: role == UserRole.orgAdmin
                ? s.actionSearchPatientSubAdmin
                : s.actionSearchPatientSub,
            onTap: () => _push(context, const LossOfWristbandScreen()),
          ),
          const SizedBox(height: 12),
        ],

        // Pendientes por sincronizar — doctor, nurse only
        if (role.canSyncPatient) ...[
          _ActionCardWide(
            icon: Icons.cloud_upload_outlined,
            iconColor: unsyncedCount > 0
                ? const Color(0xFFFB8C00)
                : AppColors.success,
            title: s.actionPendingSync,
            subtitle: unsyncedCount == 0
                ? s.actionPendingSyncEmpty
                : s.actionPendingSyncCount(unsyncedCount),
            badgeCount: unsyncedCount,
            onTap: () async {
              await _push(context, const SyncQueueScreen());
              onRefresh();
            },
          ),
          const SizedBox(height: 12),
        ],

        // Admin: manage users
        if (role.canManageUsers) ...[
          _ActionCardWide(
            icon: Icons.group_outlined,
            iconColor: AppColors.secondary,
            title: s.adminManageUsers,
            subtitle: s.adminManageUsersSub,
            onTap: () => _push(context, const ManageUsersScreen()),
          ),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 4),
        // Brigade history → secondary row, low emphasis
        Center(
          child: TextButton.icon(
            onPressed: () => _push(context, const BrigadeHistoryScreen()),
            icon: const Icon(
              Icons.history_edu_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            label: Text(
              s.brigadeHistory,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ADMIN HOME — kept simple, 3 KPIs + admin actions
// ═══════════════════════════════════════════════════════════════════

class _AdminHome extends StatefulWidget {
  const _AdminHome({this.user});
  final UserSession? user;
  @override
  State<_AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<_AdminHome> {
  int _userCount = 0;
  int _syncedCount = 0;
  bool _kpiLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadKpis());
  }

  Future<void> _loadKpis() async {
    try {
      final scope = AppScope.of(context);
      final users = await scope.userRepository.listUsers();
      final localRecords = await scope.localDatabase.getAllRecords();
      final synced = localRecords.where((r) => r.isSynced).length;
      if (mounted) {
        setState(() {
          _userCount = users.length;
          _syncedCount = synced;
          _kpiLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _kpiLoaded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
      children: [
        Row(
          children: [
            _KpiCard(
              label: s.kpiUsers,
              value: _kpiLoaded ? '$_userCount' : '…',
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            _KpiCard(
              label: s.kpiSyncedOk,
              value: _kpiLoaded ? '$_syncedCount' : '…',
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 10),
            _KpiCard(
              label: 'Org',
              value: widget.user?.organizationName?.split(' ').first ?? '—',
              color: AppColors.secondary,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _AdminRow(
                icon: Icons.group_outlined,
                title: s.adminManageUsers,
                subtitle: s.adminManageUsersSub,
                onTap: () => _push(context, const ManageUsersScreen()),
              ),
              const _AdminDivider(),
              _AdminRow(
                icon: Icons.person_search_outlined,
                title: s.adminViewPatients,
                subtitle: s.adminViewPatientsSub,
                onTap: () => _push(context, const LossOfWristbandScreen()),
              ),
              const _AdminDivider(),
              _AdminRow(
                icon: Icons.favorite_border,
                title: s.brigadeHistory,
                subtitle: s.adminBrigadeHistorySub(_syncedCount),
                onTap: () => _push(context, const BrigadeHistoryScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════

Future<T?> _push<T>(BuildContext ctx, Widget screen) =>
    Navigator.of(ctx).push<T>(MaterialPageRoute(builder: (_) => screen));

class _ActionCardWide extends StatelessWidget {
  const _ActionCardWide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 26, color: iconColor),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFB8C00),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
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
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.disabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            AppStrings.of(context).offline,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  const _AdminRow({
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.disabled,
      ),
      onTap: onTap,
    );
  }
}

class _AdminDivider extends StatelessWidget {
  const _AdminDivider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 56, endIndent: 16);
}
