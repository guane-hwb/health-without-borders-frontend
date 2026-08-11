// lib/src/features/admin/domain/stats_date_range.dart

/// Which reporting window the statistics screen is showing.
enum StatsRangeKind { all, thisMonth, last30Days, custom }

/// A selected reporting window: a [kind] plus, for the bounded kinds, the
/// concrete [from]/[to] dates sent to the backend.
class StatsDateRange {
  const StatsDateRange._(this.kind, this.from, this.to);

  final StatsRangeKind kind;

  /// Inclusive lower bound, or null for [StatsRangeKind.all].
  final DateTime? from;

  /// Inclusive upper bound, or null for [StatsRangeKind.all].
  final DateTime? to;

  static const StatsDateRange all = StatsDateRange._(
    StatsRangeKind.all,
    null,
    null,
  );

  bool get isBounded => from != null;

  /// From the first of the current month through today, inclusive.
  factory StatsDateRange.thisMonth({DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    return StatsDateRange._(
      StatsRangeKind.thisMonth,
      DateTime(today.year, today.month, 1),
      today,
    );
  }

  factory StatsDateRange.last30Days({DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    return StatsDateRange._(
      StatsRangeKind.last30Days,
      DateTime(today.year, today.month, today.day - 29),
      today,
    );
  }

  factory StatsDateRange.custom(DateTime from, DateTime to) {
    final a = _dateOnly(from);
    final b = _dateOnly(to);
    final ordered = a.isAfter(b);
    return StatsDateRange._(
      StatsRangeKind.custom,
      ordered ? b : a,
      ordered ? a : b,
    );
  }

  ({DateTime from, DateTime to})? get comparisonBaseline {
    final DateTime? start = from;
    final DateTime? end = to;
    if (start == null || end == null) return null;

    final int spanDays = end.difference(start).inDays;
    final DateTime previousEnd = DateTime(
      start.year,
      start.month,
      start.day - 1,
    );
    final DateTime previousStart = DateTime(
      previousEnd.year,
      previousEnd.month,
      previousEnd.day - spanDays,
    );
    return (from: previousStart, to: previousEnd);
  }

  @override
  bool operator ==(Object other) =>
      other is StatsDateRange &&
      other.kind == kind &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(kind, from, to);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
