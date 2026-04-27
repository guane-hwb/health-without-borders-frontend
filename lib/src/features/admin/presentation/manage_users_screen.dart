// lib/src/features/admin/presentation/manage_users_screen.dart
import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../auth/domain/user_session.dart';
import '../../nfc/presentation/shared_read_nfc_header.dart';

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
    setState(() { _loading = true; _error = null; });
    try {
      final users = await AppScope.of(context).userRepository.listUsers();
      if (mounted) setState(() { _users = users; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<UserSession> get _filtered {
    if (_filter == 'all') return _users;
    return _users.where((u) {
      switch (_filter) {
        case 'doctor': return u.role == UserRole.doctor;
        case 'nurse': return u.role == UserRole.nurse;
        case 'org_admin': return u.role == UserRole.orgAdmin;
        default: return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateUserSheet(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: AppColors.white),
      ),
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            SharedReadNfcHeader(
              title: 'Gestionar usuarios',
              onBack: () => Navigator.of(context).pop(),
            ),
            // Filter tabs
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _FilterChip(label: 'Todos (${_users.length})', value: 'all', current: _filter, onTap: (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Doctores (${_users.where((u) => u.role == UserRole.doctor).length})', value: 'doctor', current: _filter, onTap: (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Enfermería (${_users.where((u) => u.role == UserRole.nurse).length})', value: 'nurse', current: _filter, onTap: (v) => setState(() => _filter = v)),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Admin (${_users.where((u) => u.role == UserRole.orgAdmin).length})', value: 'org_admin', current: _filter, onTap: (v) => setState(() => _filter = v)),
                ]),
              ),
            ),
            Expanded(child: _buildContent()),
          ]),
          const Positioned(left: 116, right: 116, bottom: 14, child: ScreenBottomHandle()),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
      ]));
    }

    if (_filtered.isEmpty) {
      return const Center(child: Text('No hay usuarios en este filtro.',
          style: TextStyle(color: AppColors.textSecondary)));
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _UserFormSheet(
        title: 'Crear usuario',
        onSubmit: (email, name, role, password) async {
          await AppScope.of(context).userRepository.createUser(
            email: email, fullName: name, role: role, password: password,
          );
          if (mounted) { Navigator.of(context).pop(); _load(); }
        },
      ),
    );
  }

  // ── Edit user sheet (read-only for now — backend lacks PATCH /users/{id}) ─

  void _showEditUserSheet(UserSession user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _UserDetailSheet(user: user),
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
    final initials = user.fullName.split(' ')
        .where((p) => p.isNotEmpty).take(2)
        .map((p) => p[0].toUpperCase()).join();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(children: [
          // Avatar with initials
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _roleColor(user.role).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(initials,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: _roleColor(user.role)))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.fullName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text(user.email,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _RoleBadge(role: user.role),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: user.isActive
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.isActive ? 'Activo' : 'Suspendido',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: user.isActive ? const Color(0xFF2E7D32) : AppColors.error,
                ),
              ),
            ),
          ]),
        ]),
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
    final (label, color) = switch (role) {
      UserRole.doctor => ('Doctor', const Color(0xFF1565C0)),
      UserRole.nurse => ('Enfermería', const Color(0xFF2E7D32)),
      UserRole.orgAdmin => ('Admin', const Color(0xFF6A1B9A)),
      UserRole.superadmin => ('Superadmin', const Color(0xFFB71C1C)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.value, required this.current, required this.onTap});
  final String label, value, current;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final sel = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: sel ? AppColors.white : AppColors.textPrimary)),
      ),
    );
  }
}

// ── User detail sheet (read-only) ────────────────────────────────────────

class _UserDetailSheet extends StatelessWidget {
  const _UserDetailSheet({required this.user});
  final UserSession user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 60, height: 5,
            decoration: BoxDecoration(color: AppColors.disabled, borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 20),
        Text(user.fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(user.email,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        _RoleBadge(role: user.role),
        const SizedBox(height: 20),
        _row(Icons.business, 'Organización', user.organizationId),
        const SizedBox(height: 8),
        _row(Icons.check_circle_outline, 'Estado', user.isActive ? 'Activo' : 'Suspendido'),
        const SizedBox(height: 24),
        Text('Para editar permisos, use el panel web de administración.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.secondary), const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
    ]);
  }
}

// ── Create user form sheet ────────────────────────────────────────────────

class _UserFormSheet extends StatefulWidget {
  const _UserFormSheet({required this.title, required this.onSubmit});
  final String title;
  final Future<void> Function(String email, String name, String role, String password) onSubmit;

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'doctor';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 60, height: 5,
              decoration: BoxDecoration(color: AppColors.disabled, borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 16),
          Text(widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 16),
          _tf('Nombre completo *', _nameCtrl, icon: Icons.person),
          const SizedBox(height: 12),
          _tf('Correo electrónico *', _emailCtrl, icon: Icons.email, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _tf('Contraseña temporal *', _passCtrl, icon: Icons.lock, obscure: true),
          const SizedBox(height: 12),
          const Text('Rol *', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            _roleOption('Doctor', 'doctor'),
            const SizedBox(width: 10),
            _roleOption('Enfermería', 'nurse'),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.disabled,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                  : const Icon(Icons.person_add, size: 20, color: AppColors.white),
              label: Text(_saving ? 'Creando...' : 'Crear usuario',
                  style: const TextStyle(color: AppColors.white, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tf(String label, TextEditingController ctrl,
      {IconData? icon, TextInputType keyboard = TextInputType.text, bool obscure = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl, keyboardType: keyboard, obscureText: obscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.secondary) : null),
      ),
    ]);
  }

  Widget _roleOption(String label, String value) {
    final sel = _role == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? AppColors.primary : AppColors.divider),
        ),
        child: Center(child: Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: sel ? AppColors.white : AppColors.textPrimary))),
      ),
    ));
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || name.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Completa todos los campos requeridos.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.onSubmit(email, name, _role, pass);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _saving = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _saving = false; });
    }
  }
}