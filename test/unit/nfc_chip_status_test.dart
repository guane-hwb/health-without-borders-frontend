// test/unit/nfc_chip_status_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';

void main() {
  group('NfcChipStatus.clean', () {
    test('starts with nothing dirty', () {
      final s = NfcChipStatus.clean('p1');
      expect(s.patientChipDirty, isFalse);
      expect(s.guardianChipDirty, isFalse);
      expect(s.anyDirty, isFalse);
    });
  });

  group('markDirty', () {
    test('marks only the requested chip', () {
      final s = NfcChipStatus.clean('p1').markDirty(guardian: true);
      expect(s.guardianChipDirty, isTrue);
      expect(s.patientChipDirty, isFalse);
      expect(s.anyDirty, isTrue);
    });

    test('ORs with existing flags, never clearing them', () {
      final s = NfcChipStatus.clean('p1')
          .markDirty(patient: true)
          .markDirty(guardian: true);
      expect(s.patientChipDirty, isTrue);
      expect(s.guardianChipDirty, isTrue);
    });

    test('marking an already-dirty chip keeps it dirty', () {
      final s = NfcChipStatus.clean('p1')
          .markDirty(guardian: true)
          .markDirty(guardian: true);
      expect(s.guardianChipDirty, isTrue);
    });

    test('marking nothing leaves the status unchanged', () {
      final s = NfcChipStatus.clean('p1').markDirty();
      expect(s.anyDirty, isFalse);
    });
  });

  group('clearDirty', () {
    test('clears only the requested chip', () {
      final s = const NfcChipStatus(
        patientId: 'p1',
        patientChipDirty: true,
        guardianChipDirty: true,
      ).clearDirty(guardian: true);
      expect(s.guardianChipDirty, isFalse);
      expect(s.patientChipDirty, isTrue);
      expect(s.anyDirty, isTrue);
    });

    test('clearing both leaves nothing dirty', () {
      final s = const NfcChipStatus(
        patientId: 'p1',
        patientChipDirty: true,
        guardianChipDirty: true,
      ).clearDirty(patient: true, guardian: true);
      expect(s.anyDirty, isFalse);
    });

    test('clearing a clean chip is a no-op', () {
      final s = NfcChipStatus.clean('p1').clearDirty(patient: true);
      expect(s.anyDirty, isFalse);
    });
  });

  group('row serialization', () {
    test('toRow / fromRow round-trip preserves flags', () {
      const original = NfcChipStatus(
        patientId: 'p1',
        patientChipDirty: true,
        guardianChipDirty: false,
      );
      final row = original.toRow();
      expect(row['patient_chip_dirty'], 1);
      expect(row['guardian_chip_dirty'], 0);

      final restored = NfcChipStatus.fromRow(row);
      expect(restored.patientId, 'p1');
      expect(restored.patientChipDirty, isTrue);
      expect(restored.guardianChipDirty, isFalse);
    });

    test('fromRow tolerates missing dirty columns as not dirty', () {
      final s = NfcChipStatus.fromRow(<String, dynamic>{'patient_id': 'p1'});
      expect(s.anyDirty, isFalse);
    });
  });
}
