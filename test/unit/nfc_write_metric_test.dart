// test/unit/nfc_write_metric_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart'
    show kLegacyNfcKeyVersion;
import 'package:health_without_borders_frontend/src/core/nfc/nfc_write_metric.dart';

void main() {
  final guardianWrite = NfcWriteMetric(
    deviceRole: 'guardian',
    payloadFormat: kCurrentNfcPayloadFormat,
    keyVersion: 0,
    payloadBytes: 700,
    messageBytes: 734,
    chipCapacity: 872,
    consultationsKept: 1,
    consultationsTotal: 4,
    vaccinesKept: 3,
    vaccinesTotal: 5,
    writtenAt: DateTime.utc(2026, 11, 17, 21, 5),
  );

  group('NfcWriteMetric', () {
    test('la fila guarda los tamaños, los conteos y la hora en UTC', () {
      expect(guardianWrite.toRow(), <String, Object?>{
        'device_role': 'guardian',
        'payload_format': 1,
        'key_version': 0,
        'payload_bytes': 700,
        'message_bytes': 734,
        'chip_capacity': 872,
        'consultations_kept': 1,
        'consultations_total': 4,
        'vaccines_kept': 3,
        'vaccines_total': 5,
        'written_at': '2026-11-17T21:05:00.000Z',
      });
    });

    test(
      'una escritura del dispositivo del paciente no lleva conteos de historial',
      () {
        final row = NfcWriteMetric(
          deviceRole: 'patient',
          payloadFormat: kCurrentNfcPayloadFormat,
          keyVersion: 0,
          payloadBytes: 144,
          messageBytes: 173,
          chipCapacity: 492,
          writtenAt: DateTime.utc(2026, 11, 17),
        ).toRow();

        expect(row['consultations_kept'], isNull);
        expect(row['consultations_total'], isNull);
        expect(row['vaccines_kept'], isNull);
        expect(row['vaccines_total'], isNull);
      },
    );

    test('al servidor sólo va lo que el endpoint recibe', () {
      final row = <String, Object?>{
        'id': 41,
        ...guardianWrite.toRow(),
        'is_synced': 0,
        'device_uid': 'NO DEBE SALIR',
      };

      final entry = NfcWriteMetric.apiEntryFromRow(row);

      expect(
        entry.keys,
        unorderedEquals(<String>[
          'device_role',
          'payload_format',
          'key_version',
          'payload_bytes',
          'message_bytes',
          'chip_capacity',
          'consultations_kept',
          'consultations_total',
          'vaccines_kept',
          'vaccines_total',
          'written_at',
        ]),
      );
      expect(entry['message_bytes'], 734);
    });

    test('la hora sale con desfase explícito aunque la fila no lo tenga', () {
      final entry = NfcWriteMetric.apiEntryFromRow(<String, Object?>{
        ...guardianWrite.toRow(),
        'written_at': '2026-11-17T16:05:00',
      });

      final String at = entry['written_at']! as String;
      expect(at.endsWith('Z'), isTrue);
      expect(DateTime.parse(at).isUtc, isTrue);
    });

    test('sin versión de escritura cuenta la versión heredada', () {
      expect(NfcWriteMetric.keyVersionOf(null), kLegacyNfcKeyVersion);
      expect(NfcWriteMetric.keyVersionOf(3), 3);
    });
  });
}
