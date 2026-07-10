// lib/src/features/admin/domain/stats_date_range.dart

/// Which reporting window the statistics screen is showing.
enum StatsRangeKind { all, thisMonth, last30Days, custom }

/// A selected reporting window: a [kind] plus, for the bounded kinds, the
/// concrete [from]/[to] dates sent to the backend.
///
/// The date arithmetic lives here rather than inline in the widget so it can be
/// tested against an injected `now` instead of the wall clock — the same reason
/// the backend's aggregation service takes an explicit `now`.
///
/// **Time zone.** These are local calendar dates. The backend interprets
/// `date_from` / `date_to` in `America/Bogota`, and a device used in the field
/// is already in that zone, so `DateTime.now()` lines up. Running the app from
/// another zone could shift "today" by a few hours relative to the backend's
/// day boundary; that is not worth solving while every user is in Colombia, but
/// it is the thing to revisit if that ever changes.
class StatsDateRange {
  const StatsDateRange._(this.kind, this.from, this.to);

  final StatsRangeKind kind;

  /// Inclusive lower bound, or null for [StatsRangeKind.all].
  final DateTime? from;

  /// Inclusive upper bound, or null for [StatsRangeKind.all].
  final DateTime? to;

  /// The default: no window, so the backend reports the full history and a
  /// month-over-month trend.
  static const StatsDateRange all = StatsDateRange._(
    StatsRangeKind.all,
    null,
    null,
  );

  /// Whether a bounded window is active. False only for [StatsRangeKind.all].
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

  /// The 30 days ending today, inclusive on both ends — so today minus 29.
  factory StatsDateRange.last30Days({DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    return StatsDateRange._(
      StatsRangeKind.last30Days,
      today.subtract(const Duration(days: 29)),
      today,
    );
  }

  /// A user-picked window. [from] and [to] are normalised to date-only, and
  /// swapped if they arrive reversed, so the backend never receives
  /// `date_from > date_to` (which it rejects with a 400).
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

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
