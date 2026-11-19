// tool/nfc_size_options/calibration_test.dart
//
// Format 1 as the app writes it today, measured on the synthetic corpus: the
// figures the report sets against those of the 21 Oct capacity analysis, to
// show how close the corpus is to the one that analysis used. Format 1's path
// (CBOR, raw DEFLATE level 9, AES-256-GCM, MIME record, and the fit to the
// chip) is the same here as on develop.
//
// Not part of the test suite: it skips itself without HWB_CAP_CORPUS and
// HWB_CAP_OUT.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_payload.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_format.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

import 'common.dart';

final String? kCorpus = Platform.environment['HWB_CAP_CORPUS'];
final String? kOut = Platform.environment['HWB_CAP_OUT'];

void main() {
  test(
    'NFC size calibration: format 1 as written today',
    () async {
      final Corpus c = Corpus(kCorpus!);
      const NfcPayloadFormat v1 = NfcPayloadFormat.v1;
      final Fmt f1 = Fmt(
        name: 'f1',
        triageSealed: codec.estimateSize,
        guardianSealed: codec.estimateSize,
        message: (bool triage, int payload) => mimeMessage(
          triage ? kHwbNdefMimeType : kHwbGuardianMimeType,
          payload,
        ),
        fit: (PatientFullRecord r, int cap, bool adr006) => adr006
            ? NfcGuardianPayload.buildWithinCapacity(
                record: r,
                capacityBytes: guardianPayloadBudget(cap, format: v1),
                estimateSize: (Map<String, dynamic> a) =>
                    codec.estimateSize(stripAdr006(a)),
              )
            : guardianFitBuilder(record: r, codec: codec, format: v1)(
                guardianPayloadBudget(cap, format: v1),
              ),
        body: (Map<String, dynamic> m, bool triage) => v1Cbor(m).length,
        plaintext: (Map<String, dynamic> m, bool triage) =>
            rawDeflate(v1Cbor(m)).length,
        sharedSealed: (List<Map<String, dynamic>> cps) =>
            rawDeflate(v1Cbor(cps)).length + 31,
      );

      // The codec's estimate is the length of what it actually encrypts.
      for (int i = 0; i < 10; i++) {
        final Map<String, dynamic> j = c.patient(i, k: 3);
        final Map<String, dynamic> t = triageOf(j);
        expect((await codec.encode(t)).length, codec.estimateSize(t));
        final Map<String, dynamic> a = copyOf(j, 3, 3);
        expect((await codec.encode(a)).length, codec.estimateSize(a));
        expect(rawDeflate(v1Cbor(a)).length + 31, codec.estimateSize(a));
      }

      File(
        kOut!,
      ).writeAsStringSync(jsonEncode(measure(c, <Fmt>[f1], 'format 1')));
    },
    skip: kCorpus == null || kOut == null
        ? 'Set HWB_CAP_CORPUS and HWB_CAP_OUT.'
        : false,
    timeout: const Timeout(Duration(minutes: 60)),
  );
}
