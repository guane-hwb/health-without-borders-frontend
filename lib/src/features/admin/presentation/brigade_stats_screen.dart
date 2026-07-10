// lib/src/features/admin/presentation/brigade_stats_screen.dart

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/country_display.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../nfc/presentation/shared_read_nfc_header.dart';
import '../data/stats_repository.dart';
import '../domain/brigade_stats.dart';

/// Sentinel for "no organization filter", distinct from any real organization id.
const String kAllOrgsFilterId = 'all';

class _OrgFilter {
  const _OrgFilter({required this.id, required this.name});
  final String id;
  final String name;
}

enum _Failure { forbidden, offline, other }

// ── Screen ────────────────────────────────────────────────────────────────

class BrigadeStatsScreen extends StatefulWidget {
  const BrigadeStatsScreen({super.key, this.scopeToOwnOrganization = false});

  /// When true the screen renders for an org_admin: the organization filter is
  /// hidden and, crucially, `listOrganizations()` is never called — that
  /// endpoint is superadmin-only and would answer 403.
  ///
  /// Passed explicitly by the caller rather than derived from the session role,
  /// so the screen stays testable without standing up an authenticated scope.
  final bool scopeToOwnOrganization;

  @override
  State<BrigadeStatsScreen> createState() => _BrigadeStatsScreenState();
}

class _BrigadeStatsScreenState extends State<BrigadeStatsScreen> {
  BrigadeStats? _stats;
  List<_OrgFilter> _orgs = const <_OrgFilter>[];
  String _selectedOrgId = kAllOrgsFilterId;
  bool _loading = true;
  _Failure? _failure;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  bool get _showFilter => !widget.scopeToOwnOrganization;

  /// The organization id sent to the backend. An org_admin sends nothing: the
  /// backend pins the scope to their own tenant regardless of what is passed.
  String? get _requestedOrgId {
    if (widget.scopeToOwnOrganization) return null;
    return _selectedOrgId == kAllOrgsFilterId ? null : _selectedOrgId;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
      _errorDetail = null;
    });

    final scope = AppScope.of(context);
    try {
      // Only a superadmin may enumerate organizations, and only the superadmin
      // view shows the filter. Fetched once, then reused across refetches.
      if (_showFilter && _orgs.isEmpty) {
        final orgs = await scope.userRepository.listOrganizations();
        if (!mounted) return;
        _orgs = <_OrgFilter>[
          _OrgFilter(
            id: kAllOrgsFilterId,
            name: AppStrings.of(context).statsFilterAll,
          ),
          ...orgs.map((o) => _OrgFilter(id: o.id, name: o.name)),
        ];
      }

      final stats = await scope.statsRepository.fetchOverview(
        organizationId: _requestedOrgId,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _failure = e.statusCode == 403 ? _Failure.forbidden : _Failure.other;
        _errorDetail = e.message;
        _loading = false;
      });
    } on StatsUnavailableException catch (_) {
      if (!mounted) return;
      setState(() {
        _failure = _Failure.offline;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failure = _Failure.other;
        _errorDetail = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SharedReadNfcHeader(
                  title: widget.scopeToOwnOrganization
                      ? s.statsScreenTitleOrg
                      : s.statsScreenTitle,
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failure != null) {
      return _FailureView(
        failure: _failure!,
        detail: _errorDetail,
        onRetry: _load,
      );
    }

    final s = AppStrings.of(context);
    final stats = _stats!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          if (_showFilter) ...[
            _OrgFilterBar(
              orgs: _orgs,
              selected: _selectedOrgId,
              onChanged: (id) {
                if (id == _selectedOrgId) return;
                setState(() => _selectedOrgId = id);
                _load();
              },
            ),
            const SizedBox(height: 16),
          ],
          if (stats.isEmpty)
            _EmptyView(message: s.statsEmpty)
          else ...[
            _SectionTitle(title: s.tabSummary),
            const SizedBox(height: 10),
            _KpiGrid(stats: stats),
            const SizedBox(height: 20),
            _SectionTitle(title: s.statsVaccineDistribution),
            const SizedBox(height: 10),
            _VaccineBarChart(stats: stats),
            const SizedBox(height: 20),
            _SectionTitle(title: s.statsAllergyDistribution),
            const SizedBox(height: 10),
            _AllergyChips(
              allergies: stats.allergies,
              others: stats.allergiesOthers,
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: s.statsNationalityDistribution),
            const SizedBox(height: 10),
            _NationalityList(
              nationalities: stats.nationalities,
              others: stats.nationalitiesOthers,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.6,
    ),
  );
}

class _FailureView extends StatelessWidget {
  const _FailureView({
    required this.failure,
    required this.onRetry,
    this.detail,
  });

  final _Failure failure;
  final String? detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    IconData icon = Icons.error_outline;
    String message = detail ?? s.statsEmpty;
    if (failure == _Failure.forbidden) {
      icon = Icons.lock_outline;
      message = s.statsForbidden;
    } else if (failure == _Failure.offline) {
      icon = Icons.cloud_off_rounded;
      message = s.statsOfflineHint;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            // A 403 will not resolve on retry: the role is what it is.
            if (failure != _Failure.forbidden)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(s.retry),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    child: Column(
      children: [
        const Icon(
          Icons.insights_outlined,
          size: 48,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );
}

class _OrgFilterBar extends StatelessWidget {
  const _OrgFilterBar({
    required this.orgs,
    required this.selected,
    required this.onChanged,
  });
  final List<_OrgFilter> orgs;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: orgs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final org = orgs[i];
          final sel = org.id == selected;
          return GestureDetector(
            onTap: () => onChanged(org.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                org.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Formats a [TrendMetric] as a signed percentage against the previous period.
///
/// A null `deltaPct` means the previous period was empty. It renders as an em
/// dash in a neutral colour: there is genuinely nothing to compare against, and
/// showing "+100%" would invent a baseline that never existed.
class _TrendLabel {
  const _TrendLabel(this.text, this.color);
  final String text;
  final Color color;

  static const Color up = Color(0xFF2E7D32);
  static const Color down = Color(0xFFC62828);

  factory _TrendLabel.from(
    TrendMetric metric, {
    required bool monthly,
    required bool isEs,
  }) {
    final String period = monthly
        ? (isEs ? 'vs. mes anterior' : 'vs. last month')
        : (isEs ? 'vs. período anterior' : 'vs. previous period');

    final double? delta = metric.deltaPct;
    if (delta == null) {
      return _TrendLabel(
        isEs ? '— sin referencia previa' : '— no prior data',
        AppColors.textSecondary,
      );
    }
    if (delta == 0) {
      return _TrendLabel('→ 0% $period', AppColors.textSecondary);
    }
    final String arrow = delta > 0 ? '↑' : '↓';
    final String magnitude = delta.abs().toStringAsFixed(1);
    return _TrendLabel('$arrow $magnitude% $period', delta > 0 ? up : down);
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});
  final BrigadeStats stats;

  static String fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bool isEs = s.save == 'Guardar';
    final bool monthly = stats.trend.isMonthly;

    final patientsTrend = _TrendLabel.from(
      stats.trend.patients,
      monthly: monthly,
      isEs: isEs,
    );
    final vaccinesTrend = _TrendLabel.from(
      stats.trend.vaccineDoses,
      monthly: monthly,
      isEs: isEs,
    );
    final encountersTrend = _TrendLabel.from(
      stats.trend.encounters,
      monthly: monthly,
      isEs: isEs,
    );

    final int categories = stats.allergyCategoryCount;
    final String allergySub = isEs
        ? 'en $categories ${categories == 1 ? 'categoría' : 'categorías'}'
        : 'in $categories ${categories == 1 ? 'category' : 'categories'}';

    final int minors = stats.totals.minors;
    final String minorsSub = isEs
        ? '$minors ${minors == 1 ? 'paciente' : 'pacientes'}'
        : '$minors ${minors == 1 ? 'patient' : 'patients'}';

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            _KpiCard(
              icon: Icons.people_outline,
              label: s.statsTotalPatients,
              value: fmt(stats.totals.patients),
              sub: patientsTrend.text,
              subColor: patientsTrend.color,
              iconColor: AppColors.primary,
            ),
            _KpiCard(
              icon: Icons.vaccines,
              label: s.statsTotalVaccines,
              value: fmt(stats.totals.vaccineDoses),
              sub: vaccinesTrend.text,
              subColor: vaccinesTrend.color,
              iconColor: const Color(0xFF1565C0),
            ),
            _KpiCard(
              icon: Icons.warning_amber_rounded,
              label: s.statsTotalAllergies,
              value: fmt(stats.totals.allergies),
              sub: allergySub,
              iconColor: const Color(0xFFD84315),
            ),
            _KpiCard(
              icon: Icons.child_care,
              label: s.statsMinorsPercentage,
              // The backend divides by the patients that actually have a birth
              // date on file, so never rebuild this from patients x pct.
              value: '${stats.totals.minorsPct.toStringAsFixed(0)}%',
              sub: minorsSub,
              iconColor: const Color(0xFF6A1B9A),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _KpiCard(
          icon: Icons.medical_information_outlined,
          label: s.statsTotalEncounters,
          value: fmt(stats.totals.encounters),
          sub: encountersTrend.text,
          subColor: encountersTrend.color,
          iconColor: const Color(0xFF00695C),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.iconColor,
    this.subColor,
  });
  final IconData icon;
  final String label, value, sub;
  final Color iconColor;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: subColor ?? AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VaccineBarChart extends StatelessWidget {
  const _VaccineBarChart({required this.stats});
  final BrigadeStats stats;

  /// The endpoint returns every code it saw. A brigade with a broad catalogue
  /// would otherwise push the rest of the page off screen.
  static const int maxRows = 8;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bool isEs = s.save == 'Guardar';
    final int maxCount = stats.maxVaccineCount;
    final rows = stats.vaccines.take(maxRows).toList();

    if (rows.isEmpty) {
      return _EmptyView(message: s.statsEmpty);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: rows.map((v) {
          final ratio = maxCount > 0 ? v.count / maxCount : 0.0;
          final String label = v.name.isNotEmpty
              ? v.name
              : (v.isUncoded ? (isEs ? 'Sin código' : 'Uncoded') : v.code);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEBF2F8),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${v.count}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AllergyChips extends StatelessWidget {
  const _AllergyChips({required this.allergies, required this.others});
  final List<AllergyStat> allergies;
  final int others;

  /// Res. 866/2021 Elem. 47.1 defines six categories. The previous palette had
  /// four, so skin substances and insect bites both fell through to grey.
  static Color bg(String category) => switch (category) {
    '01' => const Color(0xFFFAECE7), // Medicamento
    '02' => const Color(0xFFFAEEDA), // Alimento
    '03' => const Color(0xFFE1F5EE), // Sustancia ambiente
    '04' => const Color(0xFFEDE7F6), // Sustancia piel
    '05' => const Color(0xFFFFF3E0), // Picadura de insectos
    _ => const Color(0xFFF1EFE8), // Otra
  };

  static Color fg(String category) => switch (category) {
    '01' => const Color(0xFF712B13),
    '02' => const Color(0xFF633806),
    '03' => const Color(0xFF085041),
    '04' => const Color(0xFF3F2A6B),
    '05' => const Color(0xFF6D3B00),
    _ => const Color(0xFF5F5E5A),
  };

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bool isEs = s.save == 'Guardar';

    if (allergies.isEmpty && others == 0) {
      return _EmptyView(message: s.statsEmpty);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...allergies.map(
          (a) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bg(a.category),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${a.allergen} (${a.count})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fg(a.category),
              ),
            ),
          ),
        ),
        if (others > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1EFE8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isEs ? '+$others más' : '+$others more',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5F5E5A),
              ),
            ),
          ),
      ],
    );
  }
}

class _NationalityRow {
  const _NationalityRow(this.flag, this.name, this.count);
  final String flag;
  final String name;
  final int count;
}

class _NationalityList extends StatelessWidget {
  const _NationalityList({required this.nationalities, required this.others});
  final List<NationalityStat> nationalities;
  final int others;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bool isEs = s.save == 'Guardar';

    if (nationalities.isEmpty && others == 0) {
      return _EmptyView(message: s.statsEmpty);
    }

    final rows = <_NationalityRow>[
      ...nationalities.map((n) {
        final display = countryDisplay(n.code);
        return _NationalityRow(display.flag, display.name(isEs: isEs), n.count);
      }),
      if (others > 0)
        _NationalityRow(
          othersDisplay.flag,
          othersDisplay.name(isEs: isEs),
          others,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final row = entry.value;
          final isLast = entry.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(row.flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        row.name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${row.count}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
