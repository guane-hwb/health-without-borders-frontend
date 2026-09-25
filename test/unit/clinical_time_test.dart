// test/unit/clinical_time_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/utils/clinical_time.dart';

void main() {
  // These run in whatever zone the machine or CI uses, so expectations are
  // derived from DateTime's own local conversion rather than hard-coded.
  final RegExp shape = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$',
  );

  group('toIso8601WithOffset', () {
    test('lleva desfase y precisión de segundos', () {
      final String value = toIso8601WithOffset(
        DateTime(2026, 9, 22, 10, 30, 15, 123, 456),
      );
      expect(value, matches(shape));
    });

    test('conserva la hora local del dispositivo', () {
      final DateTime local = DateTime(2026, 9, 22, 10, 30, 15);
      expect(toIso8601WithOffset(local), startsWith('2026-09-22T10:30:15'));
    });

    test('representa el mismo instante', () {
      final DateTime local = DateTime(2026, 9, 22, 21, 5, 9);
      final DateTime parsed = DateTime.parse(toIso8601WithOffset(local));
      expect(parsed.isAtSameMomentAs(local), isTrue);
    });

    test('un instante UTC se expresa en la hora local', () {
      final DateTime utc = DateTime.utc(2026, 9, 22, 15, 30);
      final DateTime local = utc.toLocal();
      final String value = toIso8601WithOffset(utc);
      expect(
        value,
        startsWith(
          '${local.year}-${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}T'
          '${local.hour.toString().padLeft(2, '0')}:30:00',
        ),
      );
      expect(DateTime.parse(value).isAtSameMomentAs(utc), isTrue);
    });

    test('el desfase es el de la zona local en esa fecha', () {
      final DateTime local = DateTime(2026, 1, 15, 8);
      final Duration offset = local.timeZoneOffset;
      final String sign = offset.isNegative ? '-' : '+';
      final String hh = offset.abs().inHours.toString().padLeft(2, '0');
      final String mm = (offset.abs().inMinutes % 60).toString().padLeft(
        2,
        '0',
      );
      expect(toIso8601WithOffset(local), endsWith('$sign$hh:$mm'));
    });

    test('ordena igual que las marcas sin zona de registros anteriores', () {
      // Stored strings are compared as text (profile list, guardian card):
      // a local wall time keeps old and new values in chronological order.
      const String legacy = '2026-09-22T09:00:00.000';
      final String next = toIso8601WithOffset(DateTime(2026, 9, 22, 10));
      expect(next.compareTo(legacy), greaterThan(0));
    });
  });
}
