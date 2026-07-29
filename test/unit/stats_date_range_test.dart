// test/unit/stats_date_range_test.dart
//
// The date arithmetic is driven through an injected `now` so month-boundary and
// "last 30 days" behaviour is deterministic, not dependent on the wall clock.

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/admin/domain/stats_date_range.dart';

void main() {
  group('StatsDateRange.all', () {
    test('is unbounded', () {
      expect(StatsDateRange.all.kind, StatsRangeKind.all);
      expect(StatsDateRange.all.from, isNull);
      expect(StatsDateRange.all.to, isNull);
      expect(StatsDateRange.all.isBounded, isFalse);
    });
  });

  group('StatsDateRange.thisMonth', () {
    test('runs from the first of the month through today', () {
      final r = StatsDateRange.thisMonth(now: DateTime(2026, 7, 9, 14, 30));
      expect(r.kind, StatsRangeKind.thisMonth);
      expect(r.from, DateTime(2026, 7, 1));
      expect(r.to, DateTime(2026, 7, 9));
      expect(r.isBounded, isTrue);
    });

    test('drops the time component from today', () {
      final r = StatsDateRange.thisMonth(now: DateTime(2026, 7, 9, 23, 59, 59));
      expect(r.to, DateTime(2026, 7, 9));
    });

    test('on the first of the month, from and to are the same day', () {
      final r = StatsDateRange.thisMonth(now: DateTime(2026, 3, 1, 8));
      expect(r.from, DateTime(2026, 3, 1));
      expect(r.to, DateTime(2026, 3, 1));
    });
  });

  group('StatsDateRange.last30Days', () {
    test('is 30 inclusive days ending today, so today minus 29', () {
      final r = StatsDateRange.last30Days(now: DateTime(2026, 7, 9, 10));
      expect(r.kind, StatsRangeKind.last30Days);
      expect(r.from, DateTime(2026, 6, 10));
      expect(r.to, DateTime(2026, 7, 9));
      // Inclusive span really is 30 days.
      expect(r.to!.difference(r.from!).inDays, 29);
    });

    test('crosses a month boundary correctly', () {
      final r = StatsDateRange.last30Days(now: DateTime(2026, 1, 15));
      expect(r.from, DateTime(2025, 12, 17));
      expect(r.to, DateTime(2026, 1, 15));
    });
  });

  group('StatsDateRange.custom', () {
    test('normalises both ends to date-only', () {
      final r = StatsDateRange.custom(
        DateTime(2026, 6, 1, 9, 15),
        DateTime(2026, 6, 15, 18, 45),
      );
      expect(r.kind, StatsRangeKind.custom);
      expect(r.from, DateTime(2026, 6, 1));
      expect(r.to, DateTime(2026, 6, 15));
    });

    test('swaps reversed bounds so from is never after to', () {
      final r = StatsDateRange.custom(
        DateTime(2026, 6, 30),
        DateTime(2026, 6, 1),
      );
      expect(r.from, DateTime(2026, 6, 1));
      expect(r.to, DateTime(2026, 6, 30));
    });

    test('accepts a single-day range', () {
      final r = StatsDateRange.custom(DateTime(2026, 6, 5), DateTime(2026, 6, 5));
      expect(r.from, DateTime(2026, 6, 5));
      expect(r.to, DateTime(2026, 6, 5));
      expect(r.isBounded, isTrue);
    });
  });
}
