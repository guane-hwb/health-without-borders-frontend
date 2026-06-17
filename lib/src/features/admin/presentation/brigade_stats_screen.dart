// lib/src/features/admin/presentation/brigade_stats_screen.dart
//
// ⚠️  NOTA: /api/v1/stats/brigades no existe aún en el backend.
//     La pantalla usa datos mock automáticamente hasta que sea implementado.
//     Para activar el endpoint real, descomenta las líneas marcadas en _load().

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../nfc/presentation/shared_read_nfc_header.dart';

// ── Domain models ─────────────────────────────────────────────────────────

class _BrigadeStats {
  const _BrigadeStats({
    required this.totalPatients,
    required this.totalVaccines,
    required this.totalAllergies,
    required this.minorsPct,
    required this.vaccineBreakdown,
    required this.allergyBreakdown,
    required this.nationalityBreakdown,
  });

  final int totalPatients;
  final int totalVaccines;
  final int totalAllergies;
  final double minorsPct;
  final List<_VaccineStat> vaccineBreakdown;
  final List<_AllergyStat> allergyBreakdown;
  final List<_NationalityStat> nationalityBreakdown;

  factory _BrigadeStats.mock() => const _BrigadeStats(
    totalPatients: 1284,
    totalVaccines: 847,
    totalAllergies: 203,
    minorsPct: 31.0,
    vaccineBreakdown: [
      _VaccineStat(name: 'Influenza Trivalente', count: 312, maxCount: 312),
      _VaccineStat(name: 'COVID-19 (ARNm)', count: 228, maxCount: 312),
      _VaccineStat(name: 'Hepatitis B', count: 147, maxCount: 312),
      _VaccineStat(name: 'Sarampión (MMR)', count: 98, maxCount: 312),
      _VaccineStat(name: 'Fiebre Amarilla', count: 62, maxCount: 312),
    ],
    allergyBreakdown: [
      _AllergyStat(name: 'Ibuprofeno', count: 41, category: 'med'),
      _AllergyStat(name: 'Penicilina', count: 38, category: 'med'),
      _AllergyStat(name: 'Mariscos', count: 29, category: 'food'),
      _AllergyStat(name: 'Maní', count: 24, category: 'food'),
      _AllergyStat(name: 'Polen', count: 18, category: 'env'),
      _AllergyStat(name: 'Polvo', count: 15, category: 'env'),
      _AllergyStat(name: 'Látex', count: 12, category: 'other'),
      _AllergyStat(name: 'Picadura insecto', count: 9, category: 'other'),
    ],
    nationalityBreakdown: [
      _NationalityStat(flag: '🇨🇴', country: 'Colombia', count: 542),
      _NationalityStat(flag: '🇻🇪', country: 'Venezuela', count: 489),
      _NationalityStat(flag: '🇪🇨', country: 'Ecuador', count: 134),
      _NationalityStat(flag: '🇵🇪', country: 'Perú', count: 87),
      _NationalityStat(flag: '🌍', country: 'Otros', count: 32),
    ],
  );
}

class _VaccineStat {
  const _VaccineStat({
    required this.name,
    required this.count,
    required this.maxCount,
  });
  final String name;
  final int count;
  final int maxCount;
}

class _AllergyStat {
  const _AllergyStat({
    required this.name,
    required this.count,
    required this.category,
  });
  final String name;
  final int count;
  final String category;
}

class _NationalityStat {
  const _NationalityStat({
    required this.flag,
    required this.country,
    required this.count,
  });
  final String flag;
  final String country;
  final int count;
}

class _OrgFilter {
  const _OrgFilter({required this.id, required this.name});
  final String id;
  final String name;
}

// ── Screen ────────────────────────────────────────────────────────────────

class BrigadeStatsScreen extends StatefulWidget {
  const BrigadeStatsScreen({super.key});

  @override
  State<BrigadeStatsScreen> createState() => _BrigadeStatsScreenState();
}

class _BrigadeStatsScreenState extends State<BrigadeStatsScreen> {
  _BrigadeStats? _stats;
  List<_OrgFilter> _orgs = [const _OrgFilter(id: 'all', name: 'Todas')];
  String _selectedOrgId = 'all';
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
      // Cargar lista de orgs para los chips de filtro
      final orgList = await AppScope.of(
        context,
      ).userRepository.listOrganizations();
      final filters = <_OrgFilter>[
        const _OrgFilter(id: 'all', name: 'Todas'),
        ...orgList.map((o) => _OrgFilter(id: o.id, name: o.name)),
      ];

      final stats = _BrigadeStats.mock();

      if (mounted) {
        setState(() {
          _orgs = filters;
          _stats = stats;
          _loading = false;
        });
      }
    } on ApiException catch (_) {
      if (mounted) {
        setState(() {
          _stats = _BrigadeStats.mock();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SharedReadNfcHeader(
                  title: AppStrings.of(context).statsScreenTitle,
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
    final sStrings = AppStrings.of(context);
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
              label: Text(sStrings.retry),
            ),
          ],
        ),
      );
    }

    final s = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          _OrgFilterBar(
            orgs: _orgs,
            selected: _selectedOrgId,
            onChanged: (id) {
              setState(() => _selectedOrgId = id);
              _load();
            },
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: sStrings.tabSummary),
          const SizedBox(height: 10),
          _KpiGrid(stats: s),
          const SizedBox(height: 20),
          _SectionTitle(title: sStrings.statsVaccineDistribution),
          const SizedBox(height: 10),
          _VaccineBarChart(vaccines: s.vaccineBreakdown),
          const SizedBox(height: 20),
          _SectionTitle(title: sStrings.statsAllergyDistribution),
          const SizedBox(height: 10),
          _AllergyChips(allergies: s.allergyBreakdown),
          const SizedBox(height: 20),
          _SectionTitle(title: sStrings.statsNationalityDistribution),
          const SizedBox(height: 10),
          _NationalityList(nationalities: s.nationalityBreakdown),
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

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});
  final _BrigadeStats stats;

  static String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    final sStrings = AppStrings.of(context);
    final minorCount = (stats.totalPatients * stats.minorsPct / 100).round();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _KpiCard(
          icon: Icons.people_outline,
          label: sStrings.statsTotalPatients,
          value: _fmt(stats.totalPatients),
          sub: '↑ 12% este mes',
          iconColor: AppColors.primary,
        ),
        _KpiCard(
          icon: Icons.vaccines,
          label: sStrings.statsTotalVaccines,
          value: _fmt(stats.totalVaccines),
          sub: 'en ${stats.vaccineBreakdown.length} tipos',
          iconColor: const Color(0xFF1565C0),
        ),
        _KpiCard(
          icon: Icons.warning_amber_rounded,
          label: sStrings.statsTotalAllergies,
          value: _fmt(stats.totalAllergies),
          sub: 'en 3 categorías',
          iconColor: const Color(0xFFD84315),
        ),
        _KpiCard(
          icon: Icons.child_care,
          label: sStrings.statsMinorsPercentage,
          value: '${stats.minorsPct.toStringAsFixed(0)}%',
          sub: '$minorCount pacientes',
          iconColor: const Color(0xFF6A1B9A),
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
  });
  final IconData icon;
  final String label, value, sub;
  final Color iconColor;

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
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VaccineBarChart extends StatelessWidget {
  const _VaccineBarChart({required this.vaccines});
  final List<_VaccineStat> vaccines;

  @override
  Widget build(BuildContext context) {
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
        children: vaccines.map((v) {
          final ratio = v.maxCount > 0 ? v.count / v.maxCount : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    v.name,
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
                  width: 28,
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
  const _AllergyChips({required this.allergies});
  final List<_AllergyStat> allergies;

  static Color _bg(String cat) => switch (cat) {
    'med' => const Color(0xFFFAECE7),
    'food' => const Color(0xFFFAEEDA),
    'env' => const Color(0xFFE1F5EE),
    _ => const Color(0xFFF1EFE8),
  };

  static Color _fg(String cat) => switch (cat) {
    'med' => const Color(0xFF712B13),
    'food' => const Color(0xFF633806),
    'env' => const Color(0xFF085041),
    _ => const Color(0xFF5F5E5A),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allergies
          .map(
            (a) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _bg(a.category),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${a.name} (${a.count})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _fg(a.category),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NationalityList extends StatelessWidget {
  const _NationalityList({required this.nationalities});
  final List<_NationalityStat> nationalities;

  @override
  Widget build(BuildContext context) {
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
        children: nationalities.asMap().entries.map((entry) {
          final n = entry.value;
          final isLast = entry.key == nationalities.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(n.flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        n.country,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${n.count}',
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
