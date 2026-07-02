// lib/src/features/admin/presentation/manage_organizations_screen.dart

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../auth/data/user_repository.dart';
import '../../nfc/presentation/shared_read_nfc_header.dart';

class ManageOrganizationsScreen extends StatefulWidget {
  const ManageOrganizationsScreen({super.key});

  @override
  State<ManageOrganizationsScreen> createState() =>
      _ManageOrganizationsScreenState();
}

class _ManageOrganizationsScreenState extends State<ManageOrganizationsScreen> {
  List<OrgSummary> _orgs = [];
  bool _loading = true;
  String? _error;

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
      final orgs = await AppScope.of(
        context,
      ).userRepository.listOrganizations();
      if (mounted) {
        setState(() {
          _orgs = orgs;
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

  void _showCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateOrgSheet(
        onCreated: (org) => setState(() => _orgs.insert(0, org)),
      ),
    );
  }

  void _showOrgDetailSheet(OrgSummary org) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OrgDetailSheet(
        org: org,
        onUpdated: (updated) {
          if (!mounted) return;
          setState(() {
            final i = _orgs.indexWhere((o) => o.id == updated.id);
            if (i != -1) _orgs[i] = updated;
          });
        },
        onDeleted: () {
          if (!mounted) return;
          setState(() => _orgs.removeWhere((o) => o.id == org.id));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: AppColors.primary,
        tooltip: s.orgsCreateOrgTitle,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SharedReadNfcHeader(
                  title: s.manageOrgsScreenTitle,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(child: _buildBody()),
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

  Widget _buildBody() {
    final s = AppStrings.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
    if (_orgs.isEmpty) {
      return Center(
        child: Text(
          s.orgsNoOrganizations,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _orgs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) =>
            _OrgCard(org: _orgs[i], onTap: () => _showOrgDetailSheet(_orgs[i])),
      ),
    );
  }
}

// ── Org card ──────────────────────────────────────────────────────────────

class _OrgCard extends StatelessWidget {
  const _OrgCard({required this.org, required this.onTap});

  final OrgSummary org;
  final VoidCallback onTap;

  static const _bgColors = [
    Color(0xFF9FE1CB),
    Color(0xFFB5D4F4),
    Color(0xFFFAC775),
    Color(0xFFF5C4B3),
    Color(0xFFCECBF6),
  ];
  static const _fgColors = [
    Color(0xFF085041),
    Color(0xFF0C447C),
    Color(0xFF633806),
    Color(0xFF712B13),
    Color(0xFF3C3489),
  ];

  int get _ci => org.name.codeUnitAt(0) % _bgColors.length;

  String get _initials {
    final words = org.name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return org.name.substring(0, org.name.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _bgColors[_ci],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _fgColors[_ci],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                org.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: org.isActive
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                org.isActive ? s.userStatusActive : s.userStatusSuspended,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: org.isActive
                      ? const Color(0xFF2E7D32)
                      : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Org detail sheet ──────────────────────────────────────────────────────

class _OrgDetailSheet extends StatefulWidget {
  const _OrgDetailSheet({
    required this.org,
    required this.onUpdated,
    required this.onDeleted,
  });

  final OrgSummary org;
  final void Function(OrgSummary org) onUpdated;
  final VoidCallback onDeleted;

  @override
  State<_OrgDetailSheet> createState() => _OrgDetailSheetState();
}

class _OrgDetailSheetState extends State<_OrgDetailSheet> {
  late OrgSummary _org = widget.org;
  bool _isDeleting = false;
  bool _isToggling = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEs = s.save == 'Guardar';
    // Clinical records are irreversible: an org is deletable only when it has no
    // patients. Its users (admin + staff) are cascaded by the backend on delete.
    final canDelete = _org.patientCount == 0;

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
            _org.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          _row(Icons.fingerprint, s.orgDetailId, _org.id),
          const SizedBox(height: 8),
          _row(
            Icons.check_circle_outline,
            s.userDetailStatus,
            _org.isActive ? s.userStatusActive : s.userStatusSuspended,
          ),
          const SizedBox(height: 8),
          _row(
            Icons.people_alt_outlined,
            isEs ? 'Usuarios' : 'Users',
            '${_org.userCount}',
          ),
          const SizedBox(height: 8),
          _row(
            Icons.medical_information_outlined,
            isEs ? 'Pacientes' : 'Patients',
            '${_org.patientCount}',
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
                      _org.isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 20,
                    ),
              label: Text(
                _org.isActive
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

          // Hard delete — only when the organization is empty
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: (_isDeleting || _isToggling || !canDelete)
                  ? null
                  : _confirmAndDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: canDelete ? AppColors.error : AppColors.divider,
                ),
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
                _isDeleting ? s.deleting : s.orgDeleteButton,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!canDelete) ...[
            const SizedBox(height: 8),
            Text(
              isEs
                  ? 'No puedes eliminar organizaciones con pacientes. Desactívala para retirarla.'
                  : 'You cannot delete organizations that have patients. Deactivate it to retire it.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
      final updated = await AppScope.of(
        context,
      ).userRepository.setOrganizationActive(_org.id, !_org.isActive);
      if (!mounted) return;
      setState(() {
        _org = updated;
        _isToggling = false;
      });
      widget.onUpdated(updated);
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
    final isEs = s.save == 'Guardar';
    final cascadeNote = _org.userCount > 0
        ? (isEs
              ? '\n\nSe eliminarán también sus usuarios.'
              : '\n\nIts users will also be deleted.')
        : '';
    final contentMessage =
        s.orgDeleteDialogContent.replaceAll('{name}', _org.name) + cascadeNote;

    // Capture before the first async gap (showDialog) so no BuildContext is used
    // across an await further down.
    final navigator = Navigator.of(context);
    final repository = AppScope.of(context).userRepository;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.orgDeleteDialogTitle),
        content: Text(contentMessage),
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
      await repository.deleteOrganization(_org.id);
      widget.onDeleted();
      if (mounted) navigator.pop();
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

// ── 2-step create sheet ───────────────────────────────────────────────────

class _CreateOrgSheet extends StatefulWidget {
  const _CreateOrgSheet({required this.onCreated});
  final void Function(OrgSummary org) onCreated;

  @override
  State<_CreateOrgSheet> createState() => _CreateOrgSheetState();
}

class _CreateOrgSheetState extends State<_CreateOrgSheet> {
  int _step = 1;

  final _orgNameCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPassCtrl = TextEditingController();
  bool _obscurePass = true;

  bool _saving = false;
  String? _error;
  OrgSummary? _createdOrg;

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPassCtrl.dispose();
    super.dispose();
  }

  void _submitStep1() {
    final name = _orgNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(
        () => _error = AppStrings.of(context).userFormRequiredFieldsError,
      );
      return;
    }
    setState(() {
      _error = null;
      _step = 2;
    });
  }

  Future<void> _submitStep2() async {
    final orgName = _orgNameCtrl.text.trim();
    final adminName = _adminNameCtrl.text.trim();
    final email = _adminEmailCtrl.text.trim();
    final pass = _adminPassCtrl.text;

    if (adminName.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(
        () => _error = AppStrings.of(context).userFormRequiredFieldsError,
      );
      return;
    }
    if (pass.length < 8) {
      setState(
        () => _error = AppStrings.of(
          context,
        ).passwordTooShort.replaceAll('6', '8'),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final userRepo = AppScope.of(context).userRepository;

      final org = await userRepo.createOrganizationWithAdmin(
        name: orgName,
        adminFullName: adminName,
        adminEmail: email,
        adminPassword: pass,
      );
      _createdOrg = org;

      if (mounted) {
        widget.onCreated(org);
        setState(() {
          _step = 3;
          _saving = false;
        });
      }
    } on ApiException {
      if (mounted) {
        setState(() {
          _error = AppStrings.of(context).userFormValidationError;
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppStrings.of(context).userFormValidationError;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_step < 3) ...[
              Text(
                s.orgsCreateOrgTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              _StepIndicator(current: _step, total: 2),
              const SizedBox(height: 18),
            ],
            if (_step == 1) _buildStep1(),
            if (_step == 2) _buildStep2(),
            if (_step == 3) _buildSuccess(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${s.step} 1 — ${s.orgsFieldNameLabel.replaceAll(" *", "")}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        _fieldLabel(s.orgsFieldNameLabel),
        TextField(
          controller: _orgNameCtrl,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 14),
          decoration: _inputDeco(
            hint: 'Ej. Cruz Roja Seccional Norte',
            icon: Icons.business,
          ),
        ),
        if (_error != null) _errorWidget(_error!),
        const SizedBox(height: 20),
        _primaryBtn(
          label: 'Continue',
          icon: Icons.arrow_forward,
          onTap: _saving ? null : _submitStep1,
          loading: _saving,
        ),
        const SizedBox(height: 8),
        _secondaryBtn(
          label: s.cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${s.step} 2 — ${s.roleOrgAdmin}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        _fieldLabel(s.orgsFieldAdminNameLabel),
        TextField(
          controller: _adminNameCtrl,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 14),
          decoration: _inputDeco(hint: s.labelNameAdmin, icon: Icons.person),
        ),
        const SizedBox(height: 12),
        _fieldLabel(s.orgsFieldAdminEmailLabel),
        TextField(
          controller: _adminEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 14),
          decoration: _inputDeco(
            hint: 'admin@organizacion.com',
            icon: Icons.email,
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel(s.orgsFieldAdminPassLabel),
        TextField(
          controller: _adminPassCtrl,
          obscureText: _obscurePass,
          style: const TextStyle(fontSize: 14),
          decoration: _inputDeco(hint: '••••••••', icon: Icons.lock).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        if (_error != null) _errorWidget(_error!),
        const SizedBox(height: 20),
        _primaryBtn(
          label: s.orgsCreateOrgTitle,
          icon: Icons.check,
          onTap: _saving ? null : _submitStep2,
          loading: _saving,
        ),
        const SizedBox(height: 8),
        _secondaryBtn(
          label: s.back,
          onTap: _saving
              ? null
              : () => setState(() {
                  _step = 1;
                  _error = null;
                }),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final s = AppStrings.of(context);
    final isEs = s.save == 'Guardar';
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE1F5EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 30,
              color: Color(0xFF0F6E56),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isEs ? '¡Organización creada!' : 'Organization created!',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          _createdOrg?.name ?? '',
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          isEs
              ? 'El administrador ya puede iniciar sesión\ncon las credenciales proporcionadas.'
              : 'The administrator can now sign in\nwith the provided credentials.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        _primaryBtn(
          label: s.save,
          icon: Icons.check,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
  );

  InputDecoration _inputDeco({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: Icon(icon, size: 18, color: AppColors.secondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      );

  Widget _errorWidget(String msg) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      msg,
      style: const TextStyle(color: AppColors.error, fontSize: 13),
    ),
  );

  Widget _primaryBtn({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool loading = false,
  }) => SizedBox(
    width: double.infinity,
    height: 44,
    child: ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.disabled,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
          : Icon(icon, size: 18, color: AppColors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _secondaryBtn({required String label, VoidCallback? onTap}) =>
      SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: const BorderSide(color: AppColors.divider),
          ),
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
}

// ── Step indicator ────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final stepNum = i + 1;
        final isDone = stepNum < current;
        final isActive = stepNum == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF9FE1CB)
                : isActive
                ? AppColors.primary
                : AppColors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
