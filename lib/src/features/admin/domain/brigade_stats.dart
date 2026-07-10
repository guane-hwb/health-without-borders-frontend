// lib/src/features/admin/domain/brigade_stats.dart
//
// Domain models for GET /api/v1/stats/overview.
//
// These are deliberately public. The previous version of the statistics screen
// kept them private and its tests had to re-implement the formatting helpers
// locally, so the assertions drifted away from the code they claimed to cover.

/// The organization the figures belong to.
///
/// Both fields are null for the system-wide aggregate a superadmin sees when
/// no organization filter is applied.
class StatsScope {
  const StatsScope({this.organizationId, this.organizationName});

  final String? organizationId;
  final String? organizationName;

  factory StatsScope.fromJson(Map<String, dynamic> j) => StatsScope(
    organizationId: j['organization_id'] as String?,
    organizationName: j['organization_name'] as String?,
  );
}

/// The inclusive date window the totals were computed over.
/// Both bounds are null when the totals cover the full history.
class StatsWindow {
  const StatsWindow({this.dateFrom, this.dateTo});

  final DateTime? dateFrom;
  final DateTime? dateTo;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  factory StatsWindow.fromJson(Map<String, dynamic> j) =>
      StatsWindow(dateFrom: _date(j['date_from']), dateTo: _date(j['date_to']));
}

/// Headline figures.
///
/// [minorsPct] divides by [patientsWithBirthDate], not by [patients]: the birth
/// date is nullable, and dividing by the full population would understate the
/// share of minors. Never reconstruct [minors] from the percentage — it is
/// reported directly.
class StatsTotals {
  const StatsTotals({
    required this.patients,
    required this.patientsWithBirthDate,
    required this.minors,
    required this.minorsPct,
    required this.vaccineDoses,
    required this.allergies,
    required this.encounters,
  });

  final int patients;
  final int patientsWithBirthDate;
  final int minors;
  final double minorsPct;
  final int vaccineDoses;
  final int allergies;
  final int encounters;

  static int _int(Object? v) => (v as num?)?.toInt() ?? 0;

  factory StatsTotals.fromJson(Map<String, dynamic> j) => StatsTotals(
    patients: _int(j['patients']),
    patientsWithBirthDate: _int(j['patients_with_birth_date']),
    minors: _int(j['minors']),
    minorsPct: (j['minors_pct'] as num?)?.toDouble() ?? 0.0,
    vaccineDoses: _int(j['vaccine_doses']),
    allergies: _int(j['allergies']),
    encounters: _int(j['encounters']),
  );
}

/// One metric against the immediately preceding period.
///
/// [deltaPct] is null — not zero — when [previous] is zero. Growth from nothing
/// is not a percentage, and rendering it as +100% would be a fabrication.
class TrendMetric {
  const TrendMetric({
    required this.current,
    required this.previous,
    this.deltaPct,
  });

  final int current;
  final int previous;
  final double? deltaPct;

  /// True when there is no baseline to compare against.
  bool get hasNoBaseline => deltaPct == null;

  factory TrendMetric.fromJson(Map<String, dynamic> j) => TrendMetric(
    current: (j['current'] as num?)?.toInt() ?? 0,
    previous: (j['previous'] as num?)?.toInt() ?? 0,
    deltaPct: (j['delta_pct'] as num?)?.toDouble(),
  );
}

/// Period-over-period comparison.
///
/// [period] is `"month"` (month-to-date against the same elapsed span of the
/// previous month) or `"custom"` (the requested window against the preceding
/// window of equal length). The client uses it to pick the sub-label copy.
class StatsTrend {
  const StatsTrend({
    required this.period,
    required this.patients,
    required this.vaccineDoses,
    required this.encounters,
  });

  final String period;
  final TrendMetric patients;
  final TrendMetric vaccineDoses;
  final TrendMetric encounters;

  bool get isMonthly => period == 'month';

  static TrendMetric _metric(Object? v) => v is Map<String, dynamic>
      ? TrendMetric.fromJson(v)
      : const TrendMetric(current: 0, previous: 0);

  factory StatsTrend.fromJson(Map<String, dynamic> j) => StatsTrend(
    period: (j['period'] as String?) ?? 'month',
    patients: _metric(j['patients']),
    vaccineDoses: _metric(j['vaccine_doses']),
    encounters: _metric(j['encounters']),
  );
}

/// Doses grouped by vaccine code. [name] is the most frequent spelling the
/// backend saw for that code; group on [code], display [name].
class VaccineStat {
  const VaccineStat({
    required this.code,
    required this.name,
    required this.count,
  });

  final String code;
  final String name;
  final int count;

  /// The backend buckets doses with no CVX code under this sentinel.
  static const String uncoded = 'UNCODED';

  bool get isUncoded => code == uncoded;

  factory VaccineStat.fromJson(Map<String, dynamic> j) => VaccineStat(
    code: (j['code'] as String?) ?? uncoded,
    name: (j['name'] as String?) ?? '',
    count: (j['count'] as num?)?.toInt() ?? 0,
  );
}

/// Allergy entries grouped by (category, allergen).
///
/// [category] is the canonical Res. 866/2021 code, `'01'`..`'06'`. Mapping it
/// to a colour is presentation, and lives in the screen.
class AllergyStat {
  const AllergyStat({
    required this.allergen,
    required this.category,
    required this.count,
  });

  final String allergen;
  final String category;
  final int count;

  factory AllergyStat.fromJson(Map<String, dynamic> j) => AllergyStat(
    allergen: (j['allergen'] as String?) ?? '',
    category: (j['category'] as String?) ?? '06',
    count: (j['count'] as num?)?.toInt() ?? 0,
  );
}

/// Patients grouped by nationality.
///
/// [code] is echoed back exactly as stored — in practice an ISO 3166-1 alpha-3
/// code such as `'COL'` — or [unknown] when the patient has none. (The FHIR
/// bundle converts to numeric at its own boundary; that does not reach here.)
class NationalityStat {
  const NationalityStat({required this.code, required this.count});

  final String code;
  final int count;

  /// The backend buckets patients with no nationality under this sentinel.
  static const String unknown = 'UNK';

  bool get isUnknown => code == unknown;

  factory NationalityStat.fromJson(Map<String, dynamic> j) => NationalityStat(
    code: (j['code'] as String?) ?? unknown,
    count: (j['count'] as num?)?.toInt() ?? 0,
  );
}

/// Full payload of `GET /api/v1/stats/overview`.
class BrigadeStats {
  const BrigadeStats({
    required this.scope,
    required this.generatedAt,
    required this.window,
    required this.totals,
    required this.trend,
    required this.vaccines,
    required this.allergies,
    required this.allergiesOthers,
    required this.nationalities,
    required this.nationalitiesOthers,
  });

  final StatsScope scope;
  final DateTime? generatedAt;
  final StatsWindow window;
  final StatsTotals totals;
  final StatsTrend trend;

  final List<VaccineStat> vaccines;

  final List<AllergyStat> allergies;

  /// Sum of the counts of allergens truncated from [allergies], not a count of
  /// distinct entries.
  final int allergiesOthers;

  final List<NationalityStat> nationalities;

  /// Sum of the counts of nationalities truncated from [nationalities].
  final int nationalitiesOthers;

  /// Nothing was recorded in this scope and window — render an empty state
  /// rather than a page of zeroed bars.
  bool get isEmpty =>
      totals.patients == 0 &&
      totals.vaccineDoses == 0 &&
      totals.encounters == 0 &&
      totals.allergies == 0;

  /// Largest dose count, used to scale the bar chart. Does not assume the
  /// backend sorted the list.
  int get maxVaccineCount =>
      vaccines.fold<int>(0, (m, v) => v.count > m ? v.count : m);

  /// Distinct allergy categories actually present in [allergies]. Allergens
  /// folded into [allergiesOthers] may belong to categories not counted here.
  int get allergyCategoryCount =>
      allergies.map((a) => a.category).toSet().length;

  static List<T> _list<T>(
    Object? raw,
    T Function(Map<String, dynamic>) parse,
  ) => raw is List
      ? raw.whereType<Map<String, dynamic>>().map(parse).toList()
      : <T>[];

  static Map<String, dynamic> _map(Object? raw) =>
      raw is Map<String, dynamic> ? raw : const <String, dynamic>{};

  factory BrigadeStats.fromJson(Map<String, dynamic> j) => BrigadeStats(
    scope: StatsScope.fromJson(_map(j['scope'])),
    generatedAt: j['generated_at'] is String
        ? DateTime.tryParse(j['generated_at'] as String)
        : null,
    window: StatsWindow.fromJson(_map(j['window'])),
    totals: StatsTotals.fromJson(_map(j['totals'])),
    trend: StatsTrend.fromJson(_map(j['trend'])),
    vaccines: _list(j['vaccines'], VaccineStat.fromJson),
    allergies: _list(j['allergies'], AllergyStat.fromJson),
    allergiesOthers: (j['allergies_others'] as num?)?.toInt() ?? 0,
    nationalities: _list(j['nationalities'], NationalityStat.fromJson),
    nationalitiesOthers: (j['nationalities_others'] as num?)?.toInt() ?? 0,
  );
}
