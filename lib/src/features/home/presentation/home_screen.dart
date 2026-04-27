// lib/src/features/home/presentation/home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../admin/presentation/manage_users_screen.dart';
import '../../auth/domain/user_session.dart';
import '../../auth/presentation/login_screen.dart';
import '../../brigade/presentation/brigade_history_screen.dart';
import '../../nfc/presentation/loss_of_wristband_screen.dart';
import '../../nfc/presentation/read_nfc_screen.dart';
import '../../nfc/presentation/register_nfc_screen.dart';
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
    // Capture before any awaits
    final scope = AppScope.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: Text(
          '¿Seguro que deseas cerrar la sesión, ${_user?.shortName ?? ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    scope.syncEngine.stop();
    await scope.authRepository.clearSession();
    if (!mounted) {
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _user?.role ?? UserRole.doctor;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  user: _user,
                  unsyncedCount: _unsyncedCount,
                  isOnline: _isOnline,
                  onToggleLanguage: _toggleLanguage,
                  onLogout: _logout,
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
          ],
        ),
      ),
    );
  }

  Widget _buildBody(UserRole role) {
    if (role.isAdmin) {
      return _AdminHome(user: _user);
    }
    if (role == UserRole.nurse) {
      return _NurseHome(
        unsyncedCount: _unsyncedCount,
        onRefresh: _refreshCount,
      );
    }
    return _DoctorHome(unsyncedCount: _unsyncedCount, onRefresh: _refreshCount);
  }
}

// ═══════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    this.user,
    required this.unsyncedCount,
    required this.isOnline,
    required this.onToggleLanguage,
    required this.onLogout,
  });

  final UserSession? user;
  final int unsyncedCount;
  final bool isOnline;
  final VoidCallback onToggleLanguage;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final locale = AppLocale.of(context).locale.toUpperCase();
    final role = user?.role ?? UserRole.doctor;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días,'
        : hour < 18
        ? 'Buenas tardes,'
        : 'Buenas noches,';

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                role.isAdmin ? 'Admin' : s.home,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!role.isAdmin && unsyncedCount > 0)
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SyncQueueScreen()),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          size: 13,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$unsyncedCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              GestureDetector(
                onTap: onToggleLanguage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.language,
                        size: 13,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        locale,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.white,
                  size: 22,
                ),
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    onLogout();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: AppColors.error),
                        SizedBox(width: 10),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            greeting,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            user?.shortName ?? '...',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _RoleChip(role: user?.role ?? UserRole.doctor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFFFF5252),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? 'En línea' : 'Sin conexión',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (user?.organizationName != null)
                Text(
                  user!.organizationName!,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      UserRole.doctor => ('● Doctor', const Color(0xFF90CAF9)),
      UserRole.nurse => ('● Nurse', const Color(0xFFA5D6A7)),
      UserRole.orgAdmin => ('● Org Admin', const Color(0xFFCE93D8)),
      UserRole.superadmin => ('● Superadmin', const Color(0xFFEF9A9A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DOCTOR HOME
// ═══════════════════════════════════════════════════════════════════

class _DoctorHome extends StatelessWidget {
  const _DoctorHome({required this.unsyncedCount, required this.onRefresh});
  final int unsyncedCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        if (unsyncedCount > 0) _SyncBanner(count: unsyncedCount),
        const _UniCefBanner(),
        const SizedBox(height: 16),
        _ActionCard(
          icon: Icons.nfc_rounded,
          iconColor: AppColors.primary,
          title: s.readNfc,
          subtitle: s.readNfcSub,
          onTap: () => _push(context, const ReadNfcScreen()),
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.person_add_alt_1_rounded,
          iconColor: const Color(0xFF37474F),
          title: s.registerNfc,
          subtitle: s.registerNfcSub,
          onTap: () async {
            await _push(context, const RegisterNfcScreen());
            onRefresh();
          },
        ),
        const SizedBox(height: 24),
        _HomeBottomRow(unsyncedCount: unsyncedCount, onRefresh: onRefresh),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// NURSE HOME
// ═══════════════════════════════════════════════════════════════════

class _NurseHome extends StatelessWidget {
  const _NurseHome({required this.unsyncedCount, required this.onRefresh});
  final int unsyncedCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF9800).withValues(alpha: 0.5),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFFE65100)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Puede escanear, buscar y registrar pacientes. '
                  'Para agregar vacunas o consultas, complete primero el registro del paciente.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (unsyncedCount > 0) _SyncBanner(count: unsyncedCount),
        const _UniCefBanner(),
        const SizedBox(height: 16),
        _ActionCard(
          icon: Icons.nfc_rounded,
          iconColor: AppColors.primary,
          title: s.readNfc,
          subtitle: s.readNfcSub,
          onTap: () => _push(context, const ReadNfcScreen()),
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.person_add_alt_1_rounded,
          iconColor: const Color(0xFF37474F),
          title: s.registerNfc,
          subtitle: s.registerNfcSub,
          onTap: () async {
            await _push(context, const RegisterNfcScreen());
            onRefresh();
          },
        ),
        const SizedBox(height: 24),
        _HomeBottomRow(unsyncedCount: unsyncedCount, onRefresh: onRefresh),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ADMIN HOME
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
      final totalLocal = await scope.localDatabase.getAllRecords();
      final synced = totalLocal.where((r) => r.isSynced).length;
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Row(
          children: [
            _KpiCard(
              label: 'Usuarios',
              value: _kpiLoaded ? '$_userCount' : '…',
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            _KpiCard(
              label: 'Sync OK',
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
        const SizedBox(height: 20),
        const Text(
          'Acciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
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
                title: 'Gestionar usuarios',
                subtitle: 'Doctores y enfermeros',
                onTap: () => _push(context, const ManageUsersScreen()),
              ),
              const _Divider(),
              _AdminRow(
                icon: Icons.person_search_outlined,
                title: 'Ver pacientes',
                subtitle: 'Solo lectura (scan / search)',
                onTap: () => _push(context, const LossOfWristbandScreen()),
              ),
              const _Divider(),
              _AdminRow(
                icon: Icons.favorite_border,
                title: 'Historial de brigadas',
                subtitle: '$_syncedCount pacientes sincronizados',
                onTap: () => _push(context, const BrigadeHistoryScreen()),
              ),
              const _Divider(),
              _AdminRow(
                icon: Icons.security_outlined,
                title: 'Auditoría de accesos',
                subtitle: 'Logs de la organización',
                onTap: () {},
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

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _push(context, const SyncQueueScreen()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF9800).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 20,
              color: Color(0xFFFF9800),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count registro${count == 1 ? '' : 's'} pendiente${count == 1 ? '' : 's'} — se sincronizarán al detectar conexión',
                style: const TextStyle(fontSize: 13, color: Color(0xFFE65100)),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFFFF9800),
            ),
          ],
        ),
      ),
    );
  }
}

class _UniCefBanner extends StatelessWidget {
  const _UniCefBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety, size: 40, color: AppColors.primary),
            SizedBox(height: 6),
            Text(
              'Health Without Borders',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Salud sin fronteras para población migrante',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 72,
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 26, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
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
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.disabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBottomRow extends StatelessWidget {
  const _HomeBottomRow({required this.unsyncedCount, required this.onRefresh});
  final int unsyncedCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
      child: Row(
        children: [
          _BottomBtn(
            icon: Icons.person_search_outlined,
            label: 'Buscar',
            onTap: () => _push(context, const LossOfWristbandScreen()),
          ),
          _BottomBtn(
            icon: Icons.sync,
            label: 'Sync',
            badge: unsyncedCount > 0 ? unsyncedCount : null,
            onTap: () async {
              await _push(context, const SyncQueueScreen());
              onRefresh();
            },
          ),
          _BottomBtn(
            icon: Icons.history_edu_outlined,
            label: 'Brigadas',
            onTap: () => _push(context, const BrigadeHistoryScreen()),
          ),
        ],
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  const _BottomBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 26, color: AppColors.secondary),
                if (badge != null && badge! > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$badge',
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
            const SizedBox(height: 4),
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

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 56, endIndent: 16);
}
