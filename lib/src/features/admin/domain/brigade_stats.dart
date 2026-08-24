// lib/src/features/admin/domain/brigade_stats.dart

class StatsScope {
  const StatsScope({this.organizationId, this.organizationName});

  final String? organizationId;
  final String? organizationName;

  factory StatsScope.fromJson(Map<String, dynamic> j) => StatsScope(
    organizationId: j['organization_id'] as String?,
    organizationName: j['organization_name'] as String?,
  );
}

class StatsWindow {
  const StatsWindow({this.dateFrom, this.dateTo});

  final DateTime? dateFrom;
  final DateTime? dateTo;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  factory StatsWindow.fromJson(Map<String, dynamic> j) =>
      StatsWindow(dateFrom: _date(j['date_from']), dateTo: _date(j['date_to']));
}

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

class TrendMetric {
  const TrendMetric({
    required this.current,
    required this.previous,
    this.deltaPct,
  });

  final int current;
  final int previous;
  final double? deltaPct;

  bool get hasNoBaseline => deltaPct == null;

  factory TrendMetric.fromJson(Map<String, dynamic> j) => TrendMetric(
    current: (j['current'] as num?)?.toInt() ?? 0,
    previous: (j['previous'] as num?)?.toInt() ?? 0,
    deltaPct: (j['delta_pct'] as num?)?.toDouble(),
  );
}

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

class VaccineStat {
  const VaccineStat({
    required this.code,
    required this.name,
    required this.count,
  });

  final String code;
  final String name;
  final int count;

  static const String uncoded = 'UNCODED';

  bool get isUncoded => code == uncoded;

  factory VaccineStat.fromJson(Map<String, dynamic> j) => VaccineStat(
    code: (j['code'] as String?) ?? uncoded,
    name: (j['name'] as String?) ?? '',
    count: (j['count'] as num?)?.toInt() ?? 0,
  );
}

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

class NationalityStat {
  const NationalityStat({required this.code, required this.count});

  final String code;
  final int count;

  static const String unknown = 'UNK';

  bool get isUnknown => code == unknown;

  factory NationalityStat.fromJson(Map<String, dynamic> j) => NationalityStat(
    code: (j['code'] as String?) ?? unknown,
    count: (j['count'] as num?)?.toInt() ?? 0,
  );
}

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
  final int allergiesOthers;
  final List<NationalityStat> nationalities;
  final int nationalitiesOthers;

  bool get isEmpty =>
      totals.patients == 0 &&
      totals.vaccineDoses == 0 &&
      totals.encounters == 0 &&
      totals.allergies == 0;

  int get maxVaccineCount =>
      vaccines.fold<int>(0, (m, v) => v.count > m ? v.count : m);

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
