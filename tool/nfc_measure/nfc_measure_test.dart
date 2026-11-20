// tool/nfc_measure/nfc_measure_test.dart
//
// Measures what the app would write to NFC chips for a set of real records,
// with the app's own builders and codec, and prints aggregates only.
//
// Not part of the test suite: it lives outside test/, so `flutter test` in CI
// never runs it, and it skips itself unless HWB_NFC_RECORDS names an input
// file. See tool/nfc_measure/README.md before running it on real records.
//
//   HWB_NFC_RECORDS=/secure/records.jsonl \
//   HWB_NFC_MEASURE_OUT=/secure/summary.json \
//   fvm flutter test tool/nfc_measure/nfc_measure_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_alias.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_payload.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_triage_payload.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:nfc_manager/ndef_record.dart';

/// Fewer records than this and the tool refuses to print anything: a
/// percentile over a handful of records describes those records.
const int kMinimumRecords = 10;

/// NDEF capacities Android reports for the two supported chips (ADR 004).
const Map<String, int> kChips = <String, int>{'NTAG215': 492, 'NTAG216': 872};

/// Any 32-byte key: sizes do not depend on the key, only on its version, and
/// version 0 writes no header, as every chip in the field today.
const String _anyKey =
    '00000000000000000000000000000000000000000000000000000000000000ff';

int _messageBytes(String mimeType, int payloadBytes) =>
    NdefMessage(
      records: <NdefRecord>[
        NfcPayloadService.buildMimeRecord(mimeType, Uint8List(payloadBytes)),
      ],
    ).byteLength;

Map<String, num> _stats(List<num> values) {
  if (values.isEmpty) return <String, num>{'n': 0};
  final List<num> sorted = List<num>.of(values)..sort();
  final int n = sorted.length;
  final num median = n.isOdd
      ? sorted[n ~/ 2]
      : (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
  return <String, num>{
    'n': n,
    'median': median,
    'p90': sorted[(0.9 * (n - 1)).floor()],
    'max': sorted.last,
  };
}

double _share(int part, int whole) =>
    whole == 0 ? 0 : (1000 * part / whole).round() / 10;

double _mean(List<int> values) => values.isEmpty
    ? 0
    : (100 * values.reduce((int a, int b) => a + b) / values.length).round() /
          100;

void main() {
  final String? input = Platform.environment['HWB_NFC_RECORDS'];

  test(
    'measure NFC payloads of real records (aggregates only)',
    () {
      final List<PatientFullRecord> records = <PatientFullRecord>[];
      var unreadable = 0;
      for (final String line in File(input!).readAsLinesSync()) {
        if (line.trim().isEmpty) continue;
        try {
          records.add(
            PatientFullRecord.fromJson(jsonDecode(line) as Map<String, dynamic>),
          );
        } catch (_) {
          unreadable++;
        }
      }
      expect(
        records.length,
        greaterThanOrEqualTo(kMinimumRecords),
        reason:
            'Se necesitan al menos $kMinimumRecords registros legibles para '
            'publicar agregados; hay ${records.length}.',
      );

      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(_anyKey),
      );

      final List<int> triage = <int>[];
      final Map<int, List<int>> guardianUntrimmed = <int, List<int>>{
        0: <int>[],
        1: <int>[],
        3: <int>[],
      };
      final Map<String, List<GuardianPayloadFit>> fits =
          <String, List<GuardianPayloadFit>>{
            for (final String chip in kChips.keys) chip: <GuardianPayloadFit>[],
          };
      final List<int> consultations = <int>[];
      final List<int> vaccines = <int>[];
      final Map<String, List<int>> textLengths = <String, List<int>>{
        'historyOfCurrentIllness': <int>[],
        'generalPhysicalExamination': <int>[],
        'systemsExamination': <int>[],
        'treatmentPlanObservations': <int>[],
      };

      for (final PatientFullRecord record in records) {
        triage.add(
          _messageBytes(
            kHwbNdefMimeType,
            codec.estimateSize(
              NfcTriagePayload.buildPatientPayload(record: record),
            ),
          ),
        );
        for (final int k in guardianUntrimmed.keys) {
          final Map<String, dynamic> copy = aliasGuardianPayload(
            NfcGuardianPayload.buildGuardianPayload(
              record: record,
              maxConsultations: k,
              maxVaccines: k,
            ),
          );
          guardianUntrimmed[k]!.add(
            _messageBytes(kHwbGuardianMimeType, codec.estimateSize(copy)),
          );
        }
        for (final MapEntry<String, int> chip in kChips.entries) {
          fits[chip.key]!.add(
            NfcGuardianPayload.buildWithinCapacity(
              record: record,
              capacityBytes: guardianPayloadBudget(chip.value),
              estimateSize: codec.estimateSize,
            ),
          );
        }
        consultations.add(record.medicalHistory.length);
        vaccines.add(record.vaccinationRecord.length);
        for (final MedicalHistoryItem visit in record.medicalHistory) {
          final Map<String, dynamic> notes = visit.clinicalEvaluation.toJson();
          for (final String field in textLengths.keys) {
            final Object? text = notes[field];
            if (text is String && text.trim().isNotEmpty) {
              textLengths[field]!.add(text.trim().length);
            }
          }
        }
      }

      final Map<String, Object> summary = <String, Object>{
        'records': records.length,
        'unreadable_lines': unreadable,
        'note':
            'Sizes in bytes of the whole NDEF message (payload + 28 B of '
            'AES-GCM + record), key version 0, current format.',
        'triage_message_bytes': _stats(triage),
        'triage_fits': <String, double>{
          for (final MapEntry<String, int> chip in kChips.entries)
            chip.key: _share(
              triage.where((int b) => b <= chip.value).length,
              triage.length,
            ),
        },
        'guardian_message_bytes_untrimmed': <String, Map<String, num>>{
          for (final MapEntry<int, List<int>> e in guardianUntrimmed.entries)
            '${e.key}+${e.key}': _stats(e.value),
        },
        'guardian_fit': <String, Map<String, Object>>{
          for (final MapEntry<String, List<GuardianPayloadFit>> e
              in fits.entries)
            e.key: <String, Object>{
              'base_does_not_fit_pct': _share(
                e.value.where((GuardianPayloadFit f) => !f.fits).length,
                e.value.length,
              ),
              'consultations_kept_mean': _mean(
                e.value
                    .map((GuardianPayloadFit f) => f.includedConsultations)
                    .toList(),
              ),
              'consultations_available_mean': _mean(
                e.value
                    .map(
                      (GuardianPayloadFit f) => f.totalConsultations < 3
                          ? f.totalConsultations
                          : 3,
                    )
                    .toList(),
              ),
              'vaccines_kept_mean': _mean(
                e.value.map((GuardianPayloadFit f) => f.includedVaccines).toList(),
              ),
              'vaccines_available_mean': _mean(
                e.value
                    .map(
                      (GuardianPayloadFit f) =>
                          f.totalVaccines < 3 ? f.totalVaccines : 3,
                    )
                    .toList(),
              ),
              'with_a_consultation_pct': _share(
                e.value
                    .where(
                      (GuardianPayloadFit f) =>
                          f.fits && f.includedConsultations > 0,
                    )
                    .length,
                e.value.length,
              ),
              'partial_pct': _share(
                e.value.where((GuardianPayloadFit f) => f.isPartial).length,
                e.value.length,
              ),
            },
        },
        'history_per_record': <String, Map<String, num>>{
          'consultations': _stats(consultations),
          'vaccines': _stats(vaccines),
        },
        'clinical_text_chars': <String, Map<String, num>>{
          for (final MapEntry<String, List<int>> e in textLengths.entries)
            e.key: _stats(e.value),
        },
      };

      final String json = const JsonEncoder.withIndent('  ').convert(summary);
      stdout.writeln(json);
      final String? out = Platform.environment['HWB_NFC_MEASURE_OUT'];
      if (out != null && out.isNotEmpty) {
        File(out).writeAsStringSync('$json\n');
      }
    },
    skip: input == null || input.isEmpty
        ? 'Define HWB_NFC_RECORDS con un archivo JSONL de registros.'
        : false,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
