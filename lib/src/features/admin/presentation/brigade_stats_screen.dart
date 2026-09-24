// lib/src/features/admin/presentation/brigade_stats_screen.dart

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/country_display.dart';
import '../../../shared/widgets/hwb_async_state_view.dart';
import '../../../shared/widgets/hwb_screen_header.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../data/stats_repository.dart';
import '../domain/brigade_stats.dart';
import '../domain/stats_date_range.dart';

const String kAllOrgsFilterId = 'all';

class _OrgFilter {
  const _OrgFilter({required this.id, required this.name});
  final String id;
  final String name;
}

enum _Failure { forbidden, offline, other }

class BrigadeStatsScreen extends StatefulWidget {
  const BrigadeStatsScreen({super.key, this.scopeToOwnOrganization = false});

  final bool scopeToOwnOrganization;

  @override
  State<BrigadeStatsScreen> createState() => _BrigadeStatsScreenState();
}

class _BrigadeStatsScreenState extends State<BrigadeStatsScreen>
    with WidgetsBindingObserver {
  BrigadeStats? _stats;
  List<_OrgFilter> _orgs = const <_OrgFilter>[];
  String _selectedOrgId = kAllOrgsFilterId;
  StatsDateRange _range = StatsDateRange.all;
  bool _loading = true;
  _Failure? _failure;
  String? _errorDetail;
  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  bool get _showFilter => !widget.scopeToOwnOrganization;

  String? get _requestedOrgId {
    if (widget.scopeToOwnOrganization) return null;
    return _selectedOrgId == kAllOrgsFilterId ? null : _selectedOrgId;
  }

  StatsDateRange _reevaluateRange(StatsDateRange range) {
    return switch (range.kind) {
      StatsRangeKind.all => StatsDateRange.all,
      StatsRangeKind.thisMonth => StatsDateRange.thisMonth(),
      StatsRangeKind.last30Days => StatsDateRange.last30Days(),
      StatsRangeKind.custom => range,
    };
  }

  Future<void> _load() async {
    final int requestId = ++_loadRequestId;

    setState(() {
      _range = _reevaluateRange(_range);
      _loading = true;
      _failure = null;
      _errorDetail = null;
    });

    final scope = AppScope.of(context);
    try {
      if (_showFilter && _orgs.isEmpty) {
        final orgs = await scope.userRepository.listOrganizations();
        if (!mounted || requestId != _loadRequestId) return;
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
        dateFrom: _range.from,
        dateTo: _range.to,
      );

      if (!mounted || requestId != _loadRequestId) return;

      setState(() {
        _stats = stats;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _failure = e.statusCode == 403 ? _Failure.forbidden : _Failure.other;
        _errorDetail = e.message;
        _loading = false;
      });
    } on StatsUnavailableException catch (_) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _failure = _Failure.offline;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _failure = _Failure.other;
        _errorDetail = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onRangeSelected(StatsRangeKind kind) async {
    if (kind == StatsRangeKind.custom) {
      await _pickCustomRange();
      return;
    }

    final StatsDateRange next = switch (kind) {
      StatsRangeKind.all => StatsDateRange.all,
      StatsRangeKind.thisMonth => StatsDateRange.thisMonth(),
      StatsRangeKind.last30Days => StatsDateRange.last30Days(),
      StatsRangeKind.custom => _range,
    };

    if (next == _range) return;

    setState(() => _range = next);
    await _load();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _range.isBounded
          ? DateTimeRange(start: _range.from!, end: _range.to!)
          : null,
      helpText: AppStrings.of(context).statsRangeCustom,
    );
    if (picked == null || !mounted) return;

    setState(() => _range = StatsDateRange.custom(picked.start, picked.end));
    await _load();
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
                HwbScreenHeader(
                  title: widget.scopeToOwnOrganization
                      ? s.statsScreenTitleOrg
                      : s.statsScreenTitle,
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          if (_showFilter) ...[
            _OrgFilterDropdown(
              orgs: _orgs,
              selected: _selectedOrgId,
              onChanged: (id) {
                if (id == null || id == _selectedOrgId) return;
                setState(() => _selectedOrgId = id);
                _load();
              },
            ),
            const SizedBox(height: 16),
          ],
          _DateRangeBar(selected: _range.kind, onSelected: _onRangeSelected),
          if (_range.isBounded) ...[
            const SizedBox(height: 6),
            _ActiveRangeLabel(
              range: _range,
              windowFrom: _stats?.window.dateFrom,
              windowTo: _stats?.window.dateTo,
            ),
          ],
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_failure != null)
            _buildFailureView()
          else if (_stats!.isEmpty) ...[
            if (_stats?.generatedAt != null) ...[
              _GeneratedAtLabel(generatedAt: _stats!.generatedAt!),
              const SizedBox(height: 10),
            ],
            HwbEmptyStateView(message: s.statsEmpty),
          ] else ...[
            if (_stats?.generatedAt != null) ...[
              _GeneratedAtLabel(generatedAt: _stats!.generatedAt!),
              const SizedBox(height: 10),
            ],
            _SectionTitle(title: s.tabSummary),
            const SizedBox(height: 10),
            _KpiGrid(stats: _stats!),
            const SizedBox(height: 20),
            _SectionTitle(title: s.statsVaccineDistribution),
            const SizedBox(height: 10),
            _VaccineBarChart(stats: _stats!),
            const SizedBox(height: 20),
            _SectionTitle(title: s.statsAllergyDistribution),
            const SizedBox(height: 10),
            _AllergyChips(
              allergies: _stats!.allergies,
              others: _stats!.allergiesOthers,
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: s.statsNationalityDistribution),
            const SizedBox(height: 10),
            _NationalityList(
              nationalities: _stats!.nationalities,
              others: _stats!.nationalitiesOthers,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFailureView() {
    final s = AppStrings.of(context);
    final isEs = s.isEs;
    IconData icon = Icons.error_outline;

    String message =
        _errorDetail ??
        (isEs
            ? 'Ocurrió un error al cargar las estadísticas.'
            : 'An error occurred loading stats.');
    if (_failure == _Failure.forbidden) {
      icon = Icons.lock_outline;
      message = s.statsForbidden;
    } else if (_failure == _Failure.offline) {
      icon = Icons.cloud_off_rounded;
      message = s.statsOfflineHint;
    }

    return HwbAsyncErrorView(
      message: message,
      onRetry: _failure == _Failure.forbidden ? null : _load,
      icon: icon,
    );
  }
}

class _GeneratedAtLabel extends StatelessWidget {
  const _GeneratedAtLabel({required this.generatedAt});
  final DateTime generatedAt;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        s.statsGeneratedAt(formatGeneratedAt(generatedAt, s)),
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

String monthAbbrev(AppStrings s, int month) => switch (month) {
  1 => s.monEne,
  2 => s.monFeb,
  3 => s.monMar,
  4 => s.monAbr,
  5 => s.monMay,
  6 => s.monJun,
  7 => s.monJul,
  8 => s.monAgo,
  9 => s.monSep,
  10 => s.monOct,
  11 => s.monNov,
  _ => s.monDic,
};

String utcOffsetLabel(DateTime localDate) {
  final offset = localDate.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final abs = offset.abs();
  final hh = abs.inHours.toString().padLeft(2, '0');
  final mm = (abs.inMinutes % 60).toString().padLeft(2, '0');
  return 'UTC$sign$hh:$mm';
}

String formatGeneratedAt(DateTime generatedAt, AppStrings s) {
  final localDate = generatedAt.toLocal();
  final hh = localDate.hour.toString().padLeft(2, '0');
  final mm = localDate.minute.toString().padLeft(2, '0');
  final offset = utcOffsetLabel(localDate);
  return '${localDate.day} ${monthAbbrev(s, localDate.month)} '
      '${localDate.year}, $hh:$mm ($offset)';
}

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

class _OrgFilterDropdown extends StatefulWidget {
  const _OrgFilterDropdown({
    required this.orgs,
    required this.selected,
    required this.onChanged,
  });

  final List<_OrgFilter> orgs;
  final String selected;
  final ValueChanged<String?> onChanged;

  @override
  State<_OrgFilterDropdown> createState() => _OrgFilterDropdownState();
}

class _OrgFilterDropdownState extends State<_OrgFilterDropdown> {
  final MenuController _menuController = MenuController();

  String _getOrgName(BuildContext context, _OrgFilter org) {
    final s = AppStrings.of(context);
    return org.id == kAllOrgsFilterId ? s.statsFilterAll : org.name;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final selectedFilter = widget.orgs.firstWhere(
      (o) => o.id == widget.selected,
      orElse: () => _OrgFilter(
        id: widget.selected,
        name: widget.selected == kAllOrgsFilterId
            ? s.statsFilterAll
            : widget.selected,
      ),
    );

    final selectedName = _getOrgName(context, selectedFilter);

    return LayoutBuilder(
      builder: (context, constraints) {
        return MenuAnchor(
          controller: _menuController,
          style: MenuStyle(
            fixedSize: WidgetStateProperty.all(
              Size(constraints.maxWidth, double.nan),
            ),
            maximumSize: WidgetStateProperty.all(
              Size(constraints.maxWidth, 250),
            ),
            backgroundColor: WidgetStateProperty.all(AppColors.white),
            elevation: WidgetStateProperty.all(4),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          builder: (context, controller, child) {
            return InkWell(
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AppColors.white,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(
                      color: Color(0xFFB0B8C4),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(
                      color: Color(0xFFB0B8C4),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedName,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.expand_more,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            );
          },
          menuChildren: widget.orgs.map((org) {
            final displayName = _getOrgName(context, org);
            return SizedBox(
              width: constraints.maxWidth,
              child: MenuItemButton(
                onPressed: () {
                  widget.onChanged(org.id);
                  _menuController.close();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DateRangeBar extends StatelessWidget {
  const _DateRangeBar({required this.selected, required this.onSelected});

  final StatsRangeKind selected;
  final ValueChanged<StatsRangeKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final chips = <(StatsRangeKind, String, IconData?)>[
      (StatsRangeKind.all, s.statsRangeAll, null),
      (StatsRangeKind.thisMonth, s.statsRangeThisMonth, null),
      (StatsRangeKind.last30Days, s.statsRangeLast30, null),
      (StatsRangeKind.custom, s.statsRangeCustom, Icons.calendar_today_rounded),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (kind, label, icon) = chips[i];
          final sel = kind == selected;
          return GestureDetector(
            onTap: () => onSelected(kind),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 12,
                      color: sel ? AppColors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveRangeLabel extends StatelessWidget {
  const _ActiveRangeLabel({
    required this.range,
    this.windowFrom,
    this.windowTo,
  });

  final StatsDateRange range;
  final DateTime? windowFrom;
  final DateTime? windowTo;

  static String _month(AppStrings s, int month) => switch (month) {
    1 => s.monEne,
    2 => s.monFeb,
    3 => s.monMar,
    4 => s.monAbr,
    5 => s.monMay,
    6 => s.monJun,
    7 => s.monJul,
    8 => s.monAgo,
    9 => s.monSep,
    10 => s.monOct,
    11 => s.monNov,
    _ => s.monDic,
  };

  static String _fmt(DateTime d, AppStrings s) =>
      '${d.day} ${_month(s, d.month)} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final fromDate = windowFrom ?? range.from;
    final toDate = windowTo ?? range.to;

    if (fromDate == null || toDate == null) return const SizedBox.shrink();

    final baseline = range.comparisonBaseline;

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_fmt(fromDate, s)} – ${_fmt(toDate, s)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (baseline != null) ...[
            const SizedBox(height: 2),
            Text(
              s.statsComparedTo(_fmt(baseline.from, s), _fmt(baseline.to, s)),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
    final bool isEs = s.isEs;
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

    final int categories = stats.allergyCategoryCount;
    final String allergySub = isEs
        ? 'en $categories ${categories == 1 ? 'categoría' : 'categorías'}'
        : 'in $categories ${categories == 1 ? 'category' : 'categories'}';

    final int minors = stats.totals.minors;
    final bool hasActiveRange = stats.window.dateFrom != null;
    final String minorsCount = isEs
        ? '$minors ${minors == 1 ? 'paciente' : 'pacientes'}'
        : '$minors ${minors == 1 ? 'patient' : 'patients'}';
    final String minorsSub = hasActiveRange
        ? '$minorsCount · ${s.statsMinorsAsOfToday}'
        : minorsCount;

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
          sub: _TrendLabel.from(
            stats.trend.encounters,
            monthly: monthly,
            isEs: isEs,
          ).text,
          subColor: _TrendLabel.from(
            stats.trend.encounters,
            monthly: monthly,
            isEs: isEs,
          ).color,
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

  static const int maxRows = 8;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bool isEs = s.isEs;
    final int maxCount = stats.maxVaccineCount;
    final rows = stats.vaccines.take(maxRows).toList();

    if (rows.isEmpty) {
      return HwbEmptyStateView(message: s.statsEmpty);
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

  static Color bg(String category) => switch (category) {
    '01' => const Color(0xFFFAECE7),
    '02' => const Color(0xFFFAEEDA),
    '03' => const Color(0xFFE1F5EE),
    '04' => const Color(0xFFEDE7F6),
    '05' => const Color(0xFFFFF3E0),
    _ => const Color(0xFFF1EFE8),
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
    final bool isEs = s.isEs;

    if (allergies.isEmpty && others == 0) {
      return HwbEmptyStateView(message: s.statsEmpty);
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
    final bool isEs = s.isEs;

    if (nationalities.isEmpty && others == 0) {
      return HwbEmptyStateView(message: s.statsEmpty);
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
