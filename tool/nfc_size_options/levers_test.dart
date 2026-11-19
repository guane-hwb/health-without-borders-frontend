// tool/nfc_size_options/levers_test.dart
//
// Levers left on top of format 2 (ADR 005). Each lever transforms the guardian
// copy (already aliased) or the triage map, and the result is measured with
// format 2's own encoder and dictionary 1 (NfcPayloadV2.plaintextSize). The
// report adds the AES-GCM seal and the NDEF record around it.
//
// Not part of the test suite: it skips itself without HWB_CAP_CORPUS (the
// corpus gen_corpus.py writes) and HWB_CAP_OUT (the JSON to write).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_format.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_v2.dart';
import 'package:nfc_manager/ndef_record.dart';

import 'common.dart';

final String? kCorpus = Platform.environment['HWB_CAP_CORPUS'];
final String? kOut = Platform.environment['HWB_CAP_OUT'];

typedef Lever = void Function(Map<String, dynamic> copy);

final RegExp _notDigit = RegExp(r'[^0-9]');

String digitsOnly(String s) => s.replaceAll(_notDigit, '');

List<Map<dynamic, dynamic>> listOf(Object? value) => <Map<dynamic, dynamic>>[
  for (final dynamic e in (value as List<dynamic>?) ?? <dynamic>[])
    e as Map<dynamic, dynamic>,
];

Map<String, dynamic> edited(Map<String, dynamic> copy, List<Lever> levers) {
  final Map<String, dynamic> c = asMap(deep(copy));
  for (final Lever lever in levers) {
    lever(c);
  }
  return c;
}

/// Guardian phones stored as digits only, which format 2 types as integers.
void phones(Map<String, dynamic> c) {
  for (final String g in <String>['gi', 'gi2']) {
    final Map<dynamic, dynamic>? gi = c[g] as Map<dynamic, dynamic>?;
    if (gi != null && gi['ph'] is String) {
      gi['ph'] = digitsOnly(gi['ph'] as String);
    }
  }
}

/// Text the app could rebuild from catalogs it already ships: the vaccine name
/// from its code (add_vaccine_screen.dart) and the country names from their
/// codes (country_display.dart).
void appCatalogs(Map<String, dynamic> c) {
  for (final Map<dynamic, dynamic> v in listOf(c['vr'])) {
    if ((v['vc'] as String? ?? '').isNotEmpty) v.remove('vn');
  }
  final Map<dynamic, dynamic>? pi = c['pi'] as Map<dynamic, dynamic>?;
  pi?.remove('nn');
  (pi?['ad'] as Map<dynamic, dynamic>?)?.remove('con');
}

/// Text an ICD-10/ICD-11 catalog in the app would rebuild: diagnosis
/// descriptions and the coded displays of chronic and family conditions.
void icdCatalog(Map<String, dynamic> c) {
  for (final Map<dynamic, dynamic> e in listOf(c['mh'])) {
    for (final Map<dynamic, dynamic> d in listOf(e['dx'])) {
      d.remove('des');
    }
  }
  final Map<dynamic, dynamic>? bg = c['bg'] as Map<dynamic, dynamic>?;
  for (final Map<dynamic, dynamic> x in listOf(bg?['chc'])) {
    x.remove('chcd');
  }
  for (final Map<dynamic, dynamic> x in listOf(bg?['fh'])) {
    x.remove('ccd');
  }
}

/// Text a DANE municipality catalog would rebuild: city and department from
/// the city code.
void daneCatalog(Map<String, dynamic> c) {
  final Map<dynamic, dynamic>? ad =
      (c['pi'] as Map<dynamic, dynamic>?)?['ad'] as Map<dynamic, dynamic>?;
  if (ad != null && (ad['cyc'] as String? ?? '').isNotEmpty) {
    ad
      ..remove('cy')
      ..remove('st');
  }
}

/// Free clinical text kept only in the most recent consultation; the older
/// ones keep dates, diagnoses, prescriptions and the rest of their fields.
void textLatestOnly(Map<String, dynamic> c) {
  final List<Map<dynamic, dynamic>> cs = listOf(c['mh']);
  if (cs.isEmpty) return;
  String start(Map<dynamic, dynamic> e) => e['sd'] as String? ?? '';
  final String latest = cs
      .map(start)
      .reduce((String a, String b) => a.compareTo(b) >= 0 ? a : b);
  for (final Map<dynamic, dynamic> e in cs) {
    if (start(e) != latest) e.remove('ce');
  }
}

/// Each free clinical text field cut to [n] characters.
Lever capText(int n) => (Map<String, dynamic> c) {
  for (final Map<dynamic, dynamic> e in listOf(c['mh'])) {
    final Map<dynamic, dynamic>? ce = e['ce'] as Map<dynamic, dynamic>?;
    if (ce == null) continue;
    for (final dynamic k in ce.keys.toList()) {
      final Object? v = ce[k];
      if (v is String && v.length > n) ce[k] = v.substring(0, n);
    }
  }
};

/// No free clinical text at all: the ceiling of anything aimed at the text.
void noText(Map<String, dynamic> c) {
  for (final Map<dynamic, dynamic> e in listOf(c['mh'])) {
    e.remove('ce');
  }
}

/// ADR 006, option C (see common.dart).
void adr006(Map<String, dynamic> c) {
  final Map<String, dynamic> cut = stripAdr006(c);
  c
    ..clear()
    ..addAll(cut);
}

/// The levers and combinations measured, in report order.
final Map<String, List<Lever>> kLevers = <String, List<Lever>>{
  'base': <Lever>[],
  'phones': <Lever>[phones],
  'app_catalogs': <Lever>[appCatalogs],
  'icd_catalog': <Lever>[icdCatalog],
  'dane_catalog': <Lever>[daneCatalog],
  'derivable': <Lever>[appCatalogs, icdCatalog, daneCatalog],
  'text_latest_only': <Lever>[textLatestOnly],
  'text_cap_160': <Lever>[capText(160)],
  'no_text': <Lever>[noText],
  'adr006': <Lever>[adr006],
  'adr006+text_latest_only': <Lever>[adr006, textLatestOnly],
  'no_new_catalogs': <Lever>[phones, appCatalogs, adr006, textLatestOnly],
  'all': <Lever>[
    phones,
    appCatalogs,
    icdCatalog,
    daneCatalog,
    adr006,
    textLatestOnly,
  ],
};

void main() {
  test(
    'NFC size levers on top of format 2',
    () {
      final Corpus c = Corpus(kCorpus!);
      final List<Map<String, dynamic>> copies = <Map<String, dynamic>>[];
      for (int i = 0; i < c.patients.length; i++) {
        for (final String variant in <String>['normal', 'largo']) {
          final Map<String, dynamic> copy = copyOf(
            c.patient(i, variant: variant, k: 10),
            3,
            3,
          );
          copies.add(<String, dynamic>{
            'i': i,
            'texto': variant,
            for (final MapEntry<String, List<Lever>> e in kLevers.entries)
              e.key: NfcPayloadV2.plaintextSize(
                edited(copy, e.value),
                NfcPayloadKind.guardian,
              ),
          });
        }
      }

      // Triage: the guardian phone as digits; chronic conditions as ICD-10
      // codes, which an ICD catalog in the app would display.
      final List<Map<String, dynamic>> triage = <Map<String, dynamic>>[];
      for (int i = 0; i < c.patients.length; i++) {
        final Map<String, dynamic> j = c.patient(i, k: 1);
        final Map<String, dynamic> t = triageOf(j);
        final Map<String, dynamic> phone = asMap(deep(t));
        if (phone['gPh'] is String) {
          phone['gPh'] = digitsOnly(phone['gPh'] as String);
        }
        final Map<String, dynamic> codes = asMap(deep(phone));
        if (codes.containsKey('chr')) {
          codes['chr'] = listOf(
            (j['backgroundHistory']
                as Map<dynamic, dynamic>?)?['chronicConditions'],
          ).map((Map<dynamic, dynamic> x) => x['chronicCie10Code']).join(';');
        }
        triage.add(<String, dynamic>{
          'i': i,
          'base': NfcPayloadV2.plaintextSize(t, NfcPayloadKind.triage),
          'phone': NfcPayloadV2.plaintextSize(phone, NfcPayloadKind.triage),
          'phone+chronic_codes': NfcPayloadV2.plaintextSize(
            codes,
            NfcPayloadKind.triage,
          ),
        });
      }

      // What the app adds around a format 2 plaintext: the seal (AES-GCM and
      // the key header) and the external NDEF record, short and long.
      int record(String type, int payload) =>
          NdefMessage(
            records: <NdefRecord>[
              buildExternalRecord(type, Uint8List(payload)),
            ],
          ).byteLength -
          payload;

      File(kOut!).writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'seal': codec.sealedSize(0),
          'record': <String, int>{
            'triage_short': record(kHwbTriageV2Type, 100),
            'triage_long': record(kHwbTriageV2Type, 300),
            'guardian_short': record(kHwbGuardianV2Type, 100),
            'guardian_long': record(kHwbGuardianV2Type, 300),
          },
          'copies': copies,
          'triage': triage,
        }),
      );
    },
    skip: kCorpus == null || kOut == null
        ? 'Set HWB_CAP_CORPUS and HWB_CAP_OUT.'
        : false,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
