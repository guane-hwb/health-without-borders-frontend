// lib/src/features/admin/presentation/manage_users_screen.dart
import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../auth/domain/user_session.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<UserSession> _users = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // 'all' | 'doctor' | 'nurse' | 'org_admin'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await AppScope.of(context).userRepository.listUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<UserSession> get _filtered {
    if (_filter == 'all') return _users;
    return _users.where((u) {
      switch (_filter) {
        case 'doctor':
          return u.role == UserRole.doctor;
        case 'nurse':
          return u.role == UserRole.nurse;
        case 'org_admin':
          return u.role == UserRole.orgAdmin;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateUserSheet(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: AppColors.white),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.manageUsersTitle,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _LocaleSwitcher(),
                    ],
                  ),
                ),
                // Barra de filtros optimizada con navegación en ambos sentidos (< y >)
                _FilterBar(
                  filter: _filter,
                  users: _users,
                  strings: s,
                  onFilterChanged: (v) => setState(() => _filter = v),
                ),
                Expanded(child: _buildContent(s)),
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

  Widget _buildContent(AppStrings s) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(s.retry),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          s.noUsersInFilter,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _UserCard(
          user: _filtered[i],
          onTap: () => _showEditUserSheet(_filtered[i]),
        ),
      ),
    );
  }

  // ── Create user sheet ─────────────────────────────────────────────────────

  void _showCreateUserSheet() {
    final s = AppStrings.of(context);
    final currentRole =
        AppScope.of(context).authRepository.currentUser?.role ??
        UserRole.orgAdmin;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserFormSheet(
        title: s.createUserTitle,
        creatorRole: currentRole,
        onSubmit: (email, name, role, password) async {
          await AppScope.of(context).userRepository.createUser(
            email: email,
            fullName: name,
            role: role,
            password: password,
          );
          if (mounted) {
            Navigator.of(context).pop();
            await _load();
          }
        },
      ),
    );
  }

  void _showEditUserSheet(UserSession user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserDetailSheet(
        user: user,
        onDelete: () async {
          await AppScope.of(context).userRepository.deleteUser(user.id);
          if (mounted) {
            Navigator.of(context).pop();
            await _load();
          }
        },
        onToggleActive: (isActive) async {
          await AppScope.of(
            context,
          ).userRepository.setUserActive(user.id, isActive);
          if (mounted) await _load();
        },
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

class _FilterBar extends StatefulWidget {
  const _FilterBar({
    required this.filter,
    required this.users,
    required this.strings,
    required this.onFilterChanged,
  });

  final String filter;
  final List<UserSession> users;
  final AppStrings strings;
  final ValueChanged<String> onFilterChanged;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollPosition());
  }

  @override
  void didUpdateWidget(covariant _FilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollPosition());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    final shouldShowLeft = currentScroll > 10;
    final shouldShowRight = maxScroll > 0 && (maxScroll - currentScroll) > 10;

    if (_showLeftArrow != shouldShowLeft ||
        _showRightArrow != shouldShowRight) {
      setState(() {
        _showLeftArrow = shouldShowLeft;
        _showRightArrow = shouldShowRight;
      });
    }
  }

  void _scrollToRight() {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.offset + 140.0;
    final maxExtent = _scrollController.position.maxScrollExtent;

    _scrollController.animateTo(
      target > maxExtent ? maxExtent : target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToLeft() {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.offset - 140.0;

    _scrollController.animateTo(
      target < 0 ? 0 : target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      color: AppColors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 44, right: 44),
              child: Row(
                children: [
                  _FilterChip(
                    label:
                        '${widget.strings.filterAll} (${widget.users.length})',
                    value: 'all',
                    current: widget.filter,
                    onTap: widget.onFilterChanged,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label:
                        '${widget.strings.filterDoctors} (${widget.users.where((u) => u.role == UserRole.doctor).length})',
                    value: 'doctor',
                    current: widget.filter,
                    onTap: widget.onFilterChanged,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label:
                        '${widget.strings.filterNurse} (${widget.users.where((u) => u.role == UserRole.nurse).length})',
                    value: 'nurse',
                    current: widget.filter,
                    onTap: widget.onFilterChanged,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label:
                        '${widget.strings.filterCoord} (${widget.users.where((u) => u.role == UserRole.orgAdmin).length})',
                    value: 'org_admin',
                    current: widget.filter,
                    onTap: widget.onFilterChanged,
                  ),
                ],
              ),
            ),
          ),

          if (_showLeftArrow)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Row(
                children: [
                  Container(
                    height: double.infinity,
                    color: AppColors.white,
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _scrollToLeft,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4F8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          AppColors.white.withValues(alpha: 0.0),
                          AppColors.white,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_showRightArrow)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.white.withValues(alpha: 0.0),
                          AppColors.white,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: double.infinity,
                    color: AppColors.white,
                    padding: const EdgeInsets.only(right: 12, left: 4),
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _scrollToRight,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4F8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              size: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
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

// ── Filter chip ───────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final sel = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: sel ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});
  final UserSession user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final initials = user.fullName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _roleColor(user.role).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _roleColor(user.role),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _RoleBadge(role: user.role),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.isActive ? s.userStatusActive : s.userStatusSuspended,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: user.isActive
                          ? const Color(0xFF2E7D32)
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _roleColor(UserRole r) => switch (r) {
    UserRole.doctor => const Color(0xFF1565C0),
    UserRole.nurse => const Color(0xFF2E7D32),
    UserRole.orgAdmin => const Color(0xFF6A1B9A),
    UserRole.superadmin => const Color(0xFFB71C1C),
  };
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final (label, color) = switch (role) {
      UserRole.doctor => (s.roleDoctor, const Color(0xFF1565C0)),
      UserRole.nurse => (s.roleNurse, const Color(0xFF2E7D32)),
      UserRole.orgAdmin => (s.roleOrgAdmin, const Color(0xFF6A1B9A)),
      UserRole.superadmin => (s.roleSuperadmin, const Color(0xFFB71C1C)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── User detail sheet (read-only) ────────────────────────────────────────

class _UserDetailSheet extends StatefulWidget {
  const _UserDetailSheet({
    required this.user,
    required this.onDelete,
    required this.onToggleActive,
  });

  final UserSession user;
  final Future<void> Function() onDelete;
  final Future<void> Function(bool isActive) onToggleActive;

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  late bool _isActive = widget.user.isActive;
  bool _isDeleting = false;
  bool _isToggling = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.save == 'Guardar';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.disabled,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.user.fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.user.email,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _RoleBadge(role: widget.user.role),
          const SizedBox(height: 20),
          _row(
            Icons.business,
            s.userDetailOrganization,
            widget.user.organizationId,
          ),
          const SizedBox(height: 8),
          _row(
            Icons.check_circle_outline,
            s.userDetailStatus,
            _isActive ? s.userStatusActive : s.userStatusSuspended,
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),

          // Soft state — deactivate / reactivate
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: (_isDeleting || _isToggling) ? null : _toggleActive,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isToggling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      _isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 20,
                    ),
              label: Text(
                _isActive
                    ? (isEs ? 'Desactivar' : 'Deactivate')
                    : (isEs ? 'Reactivar' : 'Reactivate'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: (_isDeleting || _isToggling)
                  ? null
                  : _confirmAndDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : const Icon(Icons.delete_outline, size: 20),
              label: Text(
                _isDeleting ? s.deleting : s.deletUser,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Future<void> _toggleActive() async {
    setState(() {
      _isToggling = true;
      _error = null;
    });
    try {
      await widget.onToggleActive(!_isActive);
      if (!mounted) return;
      setState(() {
        _isActive = !_isActive;
        _isToggling = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : e.toString();
          _isToggling = false;
        });
      }
    }
  }

  Future<void> _confirmAndDelete() async {
    final s = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿${s.deletUser}?'),
        content: Text('${s.permanentlyDelete} ${widget.user.fullName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      await widget.onDelete();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : e.toString();
          _isDeleting = false;
        });
      }
    }
  }
}

// ── Create user form sheet ────────────────────────────────────────────────

class _UserFormSheet extends StatefulWidget {
  const _UserFormSheet({
    required this.title,
    required this.creatorRole,
    required this.onSubmit,
  });
  final String title;
  final UserRole creatorRole;
  final Future<void> Function(
    String email,
    String name,
    String role,
    String password,
  )
  onSubmit;

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late String _role;
  bool _saving = false;
  bool _obscurePass = true;
  String? _error;

  List<MapEntry<String, String>> _getRoleOptions(AppStrings s) {
    if (widget.creatorRole == UserRole.superadmin) {
      return [MapEntry('org_admin', s.roleOrgAdmin)];
    }
    return [MapEntry('doctor', s.roleDoctor), MapEntry('nurse', s.roleNurse)];
  }

  @override
  void initState() {
    super.initState();
    _role = widget.creatorRole == UserRole.superadmin ? 'org_admin' : 'doctor';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final roleOptions = _getRoleOptions(s);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            _tf(s.userFormFullNameLabel, _nameCtrl, icon: Icons.person),
            const SizedBox(height: 12),
            _tf(
              s.userFormEmailLabel,
              _emailCtrl,
              icon: Icons.email,
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _tf(
              s.userFormPasswordLabel,
              _passCtrl,
              icon: Icons.lock,
              obscure: _obscurePass,
              onToggleObscure: () =>
                  setState(() => _obscurePass = !_obscurePass),
            ),
            const SizedBox(height: 12),
            Text(s.userFormRoleLabel, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < roleOptions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _roleOption(roleOptions[i].value, roleOptions[i].key),
                ],
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () => _submit(s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.disabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(
                        Icons.person_add,
                        size: 20,
                        color: AppColors.white,
                      ),
                label: Text(
                  _saving ? s.userFormCreatingStatus : s.userFormCreateButton,
                  style: const TextStyle(color: AppColors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: AppColors.secondary)
                : null,
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _roleOption(String label, String value) {
    final sel = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AppStrings s) async {
    final email = _emailCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || name.isEmpty || pass.isEmpty) {
      setState(() => _error = s.userFormRequiredFieldsError);
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = s.passwordTooShort.replaceAll('6', '8'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(email, name, _role, pass);
    } on ApiException catch (_) {
      if (mounted) {
        setState(() {
          _error = s.userFormValidationError;
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = s.userFormValidationError;
          _saving = false;
        });
      }
    }
  }
}
