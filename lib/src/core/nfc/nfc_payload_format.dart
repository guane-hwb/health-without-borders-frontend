// lib/src/core/nfc/nfc_payload_format.dart
//
// Which NFC payload format a build writes, and the NDEF record each one uses.
// Every build reads both (see ADR 005 for the rollout).

import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

/// Payload formats this build knows.
enum NfcPayloadFormat {
  /// CBOR → DEFLATE → AES-256-GCM in a MIME record. Every chip in the field.
  v1,

  /// Typed CBOR → DEFLATE with a preset dictionary → AES-256-GCM in an NFC
  /// Forum external record (`nfc_payload_v2.dart`).
  v2,
}

const bool _writesV2 = String.fromEnvironment('HWB_NFC_PAYLOAD_FORMAT') == '2';

/// The format this build writes. Format 1 unless the build was made with
/// `--dart-define=HWB_NFC_PAYLOAD_FORMAT=2`, which is for field tests only:
/// builds older than the one that reads format 2 see such a chip as blank.
/// Switching the default is phase 2 of ADR 005 and needs the fleet check first.
const NfcPayloadFormat kNfcWriteFormat = _writesV2
    ? NfcPayloadFormat.v2
    : NfcPayloadFormat.v1;

/// External type (NFC Forum RTD, `domain:type`) of a format 2 triage record.
const String kHwbTriageV2Type = 'guane.com.co:hwbt';

/// External type of a format 2 guardian-copy record.
const String kHwbGuardianV2Type = 'guane.com.co:hwbg';

/// The single NDEF record a format 2 payload is written in.
NdefRecord buildExternalRecord(String type, Uint8List payload) {
  return NdefRecord(
    typeNameFormat: TypeNameFormat.external,
    type: Uint8List.fromList(ascii.encode(type)),
    identifier: Uint8List(0),
    payload: payload,
  );
}
