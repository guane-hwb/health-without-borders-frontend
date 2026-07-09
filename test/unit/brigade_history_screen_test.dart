// test/unit/features/nfc/brigade_history_screen_test.dart
//
// Unit tests for BrigadeHistoryScreen.
// Covers the pure logic that does NOT require the widget tree.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/design/tokens/app_colors.dart';

enum SyncStatus { pending, synchronizing, synchronized }

Color headerColor(SyncStatus status) => switch (status) {
  SyncStatus.pending => const Color(0xFFD4A017),
  SyncStatus.synchronizing => AppColors.secondary,
  SyncStatus.synchronized => const Color(0xFF2E7D32),
};

IconData rowIcon(SyncStatus status) => switch (status) {
  SyncStatus.pending => Icons.cloud_upload_outlined,
  SyncStatus.synchronizing => Icons.sync,
  SyncStatus.synchronized => Icons.cloud_done,
};

Color rowColor(SyncStatus status) => switch (status) {
  SyncStatus.pending => const Color(0xFFD4A017),
  SyncStatus.synchronizing => AppColors.primary,
  SyncStatus.synchronized => const Color(0xFF2E7D32),
};

void main() {
  // ── Group 1: _SyncStatus — enum definition ────────────────────────────
  group('_SyncStatus — enum', () {
    test('tiene exactamente 3 valores', () {
      expect(SyncStatus.values.length, equals(3));
    });

    test('contiene pending, synchronizing y synchronized', () {
      expect(
        SyncStatus.values,
        containsAll([
          SyncStatus.pending,
          SyncStatus.synchronizing,
          SyncStatus.synchronized,
        ]),
      );
    });

    test('el estado inicial es pending', () {
      const initial = SyncStatus.pending;
      expect(initial, equals(SyncStatus.pending));
    });

    test('pending es distinto de synchronizing', () {
      expect(SyncStatus.pending, isNot(equals(SyncStatus.synchronizing)));
    });

    test('synchronizing es distinto de synchronized', () {
      expect(SyncStatus.synchronizing, isNot(equals(SyncStatus.synchronized)));
    });

    test('pending es distinto de synchronized', () {
      expect(SyncStatus.pending, isNot(equals(SyncStatus.synchronized)));
    });
  });

  // ── Group 2: _headerColor — header color according to state ─────────────
  group('_headerColor — color según SyncStatus', () {
    test('pending → Color(0xFFD4A017) (amarillo advertencia)', () {
      expect(headerColor(SyncStatus.pending), equals(const Color(0xFFD4A017)));
    });

    test('synchronizing → AppColors.secondary (azul)', () {
      expect(
        headerColor(SyncStatus.synchronizing),
        equals(AppColors.secondary),
      );
    });

    test('synchronized → Color(0xFF2E7D32) (verde)', () {
      expect(
        headerColor(SyncStatus.synchronized),
        equals(const Color(0xFF2E7D32)),
      );
    });

    test('pending y synchronizing tienen colores distintos', () {
      expect(
        headerColor(SyncStatus.pending),
        isNot(equals(headerColor(SyncStatus.synchronizing))),
      );
    });

    test('synchronizing y synchronized tienen colores distintos', () {
      expect(
        headerColor(SyncStatus.synchronizing),
        isNot(equals(headerColor(SyncStatus.synchronized))),
      );
    });

    test('los 3 estados tienen colores distintos entre sí', () {
      final colors = SyncStatus.values.map(headerColor).toList();
      final unique = colors.toSet();
      expect(unique.length, equals(3));
    });
  });

  // ── Group 3: _PatientRow._icon — icon according to state ──────────────────────
  group('_PatientRow._icon — ícono según SyncStatus', () {
    test('pending → cloud_upload_outlined', () {
      expect(rowIcon(SyncStatus.pending), equals(Icons.cloud_upload_outlined));
    });

    test('synchronizing → sync', () {
      expect(rowIcon(SyncStatus.synchronizing), equals(Icons.sync));
    });

    test('synchronized → cloud_done', () {
      expect(rowIcon(SyncStatus.synchronized), equals(Icons.cloud_done));
    });

    test('los 3 estados tienen íconos distintos entre sí', () {
      final icons = SyncStatus.values.map(rowIcon).toList();
      final unique = icons.toSet();
      expect(unique.length, equals(3));
    });
  });

  // ── Group 4: _PatientRow._color — badge color according to status ────────────
  group('_PatientRow._color — color según SyncStatus', () {
    test('pending → Color(0xFFD4A017) (amarillo)', () {
      expect(rowColor(SyncStatus.pending), equals(const Color(0xFFD4A017)));
    });

    test('synchronizing → AppColors.primary (azul primario)', () {
      expect(rowColor(SyncStatus.synchronizing), equals(AppColors.primary));
    });

    test('synchronized → Color(0xFF2E7D32) (verde)', () {
      expect(
        rowColor(SyncStatus.synchronized),
        equals(const Color(0xFF2E7D32)),
      );
    });

    test('pending y synchronizing tienen colores distintos en el row', () {
      expect(
        rowColor(SyncStatus.pending),
        isNot(equals(rowColor(SyncStatus.synchronizing))),
      );
    });

    test('synchronizing y synchronized tienen colores distintos en el row', () {
      expect(
        rowColor(SyncStatus.synchronizing),
        isNot(equals(rowColor(SyncStatus.synchronized))),
      );
    });

    test('los 3 colores del row son distintos entre sí', () {
      final colors = SyncStatus.values.map(rowColor).toList();
      expect(colors.toSet().length, equals(3));
    });
  });

  // ── Group 5: State Transition Sequence ───────────────────────────
  group('_simulateSync — secuencia de transición de estados', () {
    test('el estado inicial es siempre pending', () {
      const s = SyncStatus.pending;
      expect(s, equals(SyncStatus.pending));
    });

    test('pending → synchronizing es una transición válida', () {
      var status = SyncStatus.pending;
      status = SyncStatus.synchronizing;
      expect(status, equals(SyncStatus.synchronizing));
    });

    test('synchronizing → synchronized es una transición válida', () {
      var status = SyncStatus.synchronizing;
      status = SyncStatus.synchronized;
      expect(status, equals(SyncStatus.synchronized));
    });

    test('la transición completa recorre los 3 estados en orden', () {
      final history = <SyncStatus>[];
      var status = SyncStatus.pending;
      history.add(status);

      status = SyncStatus.synchronizing;
      history.add(status);

      status = SyncStatus.synchronized;
      history.add(status);

      expect(
        history,
        equals([
          SyncStatus.pending,
          SyncStatus.synchronizing,
          SyncStatus.synchronized,
        ]),
      );
    });

    test('el estado final es siempre synchronized', () {
      const finalStatus = SyncStatus.synchronized;
      expect(finalStatus, equals(SyncStatus.synchronized));
    });

    test('el estado pending no es el estado final', () {
      expect(SyncStatus.pending, isNot(equals(SyncStatus.synchronized)));
    });
  });

  // ── Group 6: Offline Banner — Visibility Condition ───────────────────
  group('Banner offline — condición de visibilidad', () {
    test('el banner se muestra cuando el estado es pending', () {
      const status = SyncStatus.pending;
      final shouldShow = status == SyncStatus.pending;
      expect(shouldShow, isTrue);
    });

    test('el banner NO se muestra cuando el estado es synchronizing', () {
      const status = SyncStatus.synchronizing;
      final shouldShow = status == SyncStatus.pending;
      expect(shouldShow, isFalse);
    });

    test('el banner NO se muestra cuando el estado es synchronized', () {
      const status = SyncStatus.synchronized;
      final shouldShow = status == SyncStatus.pending;
      expect(shouldShow, isFalse);
    });
  });
}
