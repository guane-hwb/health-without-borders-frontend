// tool/nfc_size_options/common.dart
//
// Shared part of the NFC size measurements (see README.md). Everything is
// measured with the app's own code: the payload builders, the codec and the
// record builders; each payload format comes in as an [Fmt].
//
// Not part of the test suite: it lives outside test/, and the tests that use
// it skip themselves without HWB_CAP_CORPUS.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cbor/cbor.dart' as cbor;
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_alias.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_payload.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_triage_payload.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:nfc_manager/ndef_record.dart';

const String kKey =
    '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';

/// Key version 1: the payload carries the 3-byte header ("HW" + version), as it
/// will after the first key rotation. The 21 Oct capacity analysis measured so.
final NfcPayloadCodec codec = NfcPayloadCodec(hexKey: kKey, keyVersion: 1);

/// Largest NDEF message of each chip (bytes), as in the 21 Oct analysis.
const Map<String, int> kChips = <String, int>{
  'NTAG213': 137,
  'NTAG215': 492,
  'NTAG216': 868,
  'DESFire EV3 2K': 1900,
  'DESFire EV3 4K': 3800,
  'DESFire EV3 8K': 7600,
};

/// Guardian-copy shapes measured: (consultations, vaccines).
const List<List<int>> kShapes = <List<int>>[
  <int>[0, 0],
  <int>[0, 3],
  <int>[1, 1],
  <int>[3, 3],
  <int>[10, 3],
];

dynamic deep(dynamic x) => jsonDecode(jsonEncode(x));

Map<String, dynamic> asMap(dynamic x) =>
    (x as Map<dynamic, dynamic>).cast<String, dynamic>();

/// A payload format, with the app functions that write it.
class Fmt {
  Fmt({
    required this.name,
    required this.triageSealed,
    required this.guardianSealed,
    required this.message,
    required this.fit,
    required this.body,
    required this.plaintext,
    required this.sharedSealed,
  });

  final String name;

  /// Bytes of the encrypted triage payload.
  final int Function(Map<String, dynamic> triage) triageSealed;

  /// Bytes of the encrypted payload of an already aliased guardian copy.
  final int Function(Map<String, dynamic> aliased) guardianSealed;

  /// NDEF message (bytes) holding a payload of [payload] bytes.
  final int Function(bool triage, int payload) message;

  /// What the app writes on a chip whose NDEF message holds [chipCapacity] B.
  final GuardianPayloadFit Function(
    PatientFullRecord record,
    int chipCapacity,
    bool adr006,
  )
  fit;

  /// Body before compression (the format's CBOR).
  final int Function(Map<String, dynamic> map, bool triage) body;

  /// Payload before encryption (compressed, with its prefix if any).
  final int Function(Map<String, dynamic> map, bool triage) plaintext;

  /// Encrypted payload of a device shared by several copies (emulated).
  final int Function(List<Map<String, dynamic>> aliasedCopies) sharedSealed;
}

class Corpus {
  Corpus(String path) : data = asMap(jsonDecode(File(path).readAsStringSync()));

  final Map<String, dynamic> data;

  List<dynamic> get patients => data['pacientes'] as List<dynamic>;
  List<dynamic> get extremes => data['extremos'] as List<dynamic>;
  List<dynamic> get families => data['familias'] as List<dynamic>;

  /// The backend's contract fixtures, when the corpus was built with them.
  Map<String, dynamic>? get fixtures =>
      data['fixtures'] == null ? null : asMap(data['fixtures']);

  Map<String, dynamic> patient(int i, {String variant = 'normal', int k = 3}) {
    final Map<String, dynamic> j = asMap(deep(patients[i]));
    final List<dynamic> h =
        ((data['historiales'] as Map<dynamic, dynamic>)[variant]
                as List<dynamic>)[i]
            as List<dynamic>;
    j['medicalHistory'] = deep(h.sublist(0, k));
    return j;
  }
}

PatientFullRecord record(Map<String, dynamic> j) =>
    PatientFullRecord.fromJson(asMap(deep(j)));

Map<String, dynamic> triageOf(Map<String, dynamic> j) =>
    NfcTriagePayload.buildPatientPayload(record: record(j));

/// The guardian copy as it is written: bounded to [k] consultations and [m]
/// vaccines, without signatures, aliased.
Map<String, dynamic> copyOf(Map<String, dynamic> j, int k, int m) =>
    aliasGuardianPayload(
      NfcGuardianPayload.buildGuardianPayload(
        record: record(j),
        maxConsultations: k,
        maxVaccines: m,
      ),
    );

/// Points 1 to 3 of ADR 006 (its option C) on an aliased copy: no
/// prescriptions, practitioner, provider or payer in the consultations, and no
/// vaccinator or site in the vaccines.
Map<String, dynamic> stripAdr006(Map<String, dynamic> aliased) {
  final Map<String, dynamic> c = asMap(deep(aliased));
  for (final dynamic e in (c['mh'] as List<dynamic>? ?? <dynamic>[])) {
    (e as Map<dynamic, dynamic>)
      ..remove('prescriptions')
      ..remove('prc')
      ..remove('prv')
      ..remove('pay');
  }
  for (final dynamic e in (c['vr'] as List<dynamic>? ?? <dynamic>[])) {
    (e as Map<dynamic, dynamic>)
      ..remove('ab')
      ..remove('aa');
  }
  return c;
}

/// CBOR as format 1's codec builds it.
Uint8List v1Cbor(Object value) =>
    Uint8List.fromList(cbor.cborEncode(cbor.CborValue(value)));

/// Raw DEFLATE at level 9, as the codec runs it.
Uint8List rawDeflate(List<int> data) =>
    Uint8List.fromList(ZLibEncoder(level: 9, raw: true).convert(data));

int mimeMessage(String type, int payload) => NdefMessage(
  records: <NdefRecord>[
    NfcPayloadService.buildMimeRecord(type, Uint8List(payload)),
  ],
).byteLength;

// ── Contract fixtures ───────────────────────────────────────────────────────

final RegExp _fraction = RegExp(r'\.\d+(?=[+-]\d{2}:\d{2}$)');

String _shiftDate(String iso, int days) {
  final DateTime d = DateTime.parse(iso.substring(0, 10));
  final DateTime s = d.add(Duration(days: days));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${s.year}-${two(s.month)}-${two(s.day)}${iso.substring(10)}';
}

String _uuidN(String uuid, int n) =>
    uuid.substring(0, uuid.length - 2) + n.toRadixString(16).padLeft(2, '0');

/// The `register_minor` fixture with [consultations] copies of `consultation`
/// and [vaccines] of `vaccine` (each with its own id and date). [minimal]
/// drops background and allergies; [canonical] drops fractional seconds, as
/// the app writes timestamps today.
Map<String, dynamic> fixtureRecord(
  Corpus c, {
  int consultations = 0,
  int vaccines = 0,
  bool minimal = false,
  bool canonical = false,
}) {
  final Map<String, dynamic> fx = c.fixtures!;
  final Map<String, dynamic> j = asMap(deep(fx['register_minor']));
  final Map<String, dynamic> cons = asMap(fx['consultation']);
  final Map<String, dynamic> vac = asMap(fx['vaccine']);
  j['medicalHistory'] = <dynamic>[
    for (int n = 0; n < consultations; n++)
      asMap(deep(cons))
        ..['encounterIdentifier'] = _uuidN(
          cons['encounterIdentifier'] as String,
          n,
        )
        ..['startDateTime'] = _shiftDate(
          cons['startDateTime'] as String,
          -14 * n,
        )
        ..['endDateTime'] = _shiftDate(cons['endDateTime'] as String, -14 * n),
  ];
  j['vaccinationRecord'] = <dynamic>[
    for (int n = 0; n < vaccines; n++)
      asMap(deep(vac))
        ..['vaccinationId'] = _uuidN(vac['vaccinationId'] as String, n)
        ..['date'] = _shiftDate(vac['date'] as String, -30 * n),
  ];
  if (minimal) {
    j.remove('backgroundHistory');
    j['allergies'] = <dynamic>[];
  }
  if (canonical) {
    for (final dynamic e in j['medicalHistory'] as List<dynamic>) {
      final Map<dynamic, dynamic> m = e as Map<dynamic, dynamic>;
      for (final String k in <String>['startDateTime', 'endDateTime']) {
        if (m[k] is String) m[k] = (m[k] as String).replaceFirst(_fraction, '');
      }
    }
    for (final String g in <String>['guardianInfo', 'guardian2Info']) {
      final Map<dynamic, dynamic>? gi = j[g] as Map<dynamic, dynamic>?;
      final Map<dynamic, dynamic>? cs =
          gi?['consent'] as Map<dynamic, dynamic>?;
      if (cs != null && cs['acceptedAt'] is String) {
        cs['acceptedAt'] = (cs['acceptedAt'] as String).replaceFirst(
          _fraction,
          '',
        );
      }
    }
  }
  return j;
}

// ── Measurement ─────────────────────────────────────────────────────────────

Map<String, dynamic> fitRow(GuardianPayloadFit f) => <String, dynamic>{
  'fits': f.fits,
  'n': f.includedConsultations,
  'm': f.includedVaccines,
  'bytes': f.estimatedBytes,
};

Map<String, dynamic> measure(Corpus c, List<Fmt> fmts, String version) {
  final Map<String, dynamic> res = <String, dynamic>{'version': version};
  final int nPatients = c.patients.length;

  // 1. Record overhead: message minus payload, for payloads of 100 and 300 B.
  res['overhead'] = <String, dynamic>{
    for (final Fmt f in fmts)
      f.name: <String, int>{
        'triage_sr': f.message(true, 100) - 100,
        'triage_lr': f.message(true, 300) - 300,
        'guardian_sr': f.message(false, 100) - 100,
        'guardian_lr': f.message(false, 300) - 300,
      },
  };

  // 2. Triage of the 100 patients and of the extreme cases.
  Map<String, dynamic> triageRow(Map<String, dynamic> j) {
    final Map<String, dynamic> t = triageOf(j);
    return <String, dynamic>{
      'alergias': (j['allergies'] as List<dynamic>).length,
      'cronicas':
          ((j['backgroundHistory']
                          as Map<dynamic, dynamic>?)?['chronicConditions']
                      as List<dynamic>? ??
                  <dynamic>[])
              .length,
      'g2': j.containsKey('guardian2Info'),
      for (final Fmt f in fmts)
        f.name: <String, int>{
          'mensaje': f.message(true, f.triageSealed(t)),
          'cuerpo': f.body(t, true),
          'plano': f.plaintext(t, true),
        },
    };
  }

  res['triaje'] = <dynamic>[
    for (int i = 0; i < nPatients; i++)
      triageRow(c.patient(i, k: 1))..['i'] = i,
  ];
  res['extremos'] = <dynamic>[
    for (final dynamic e in c.extremes)
      triageRow(asMap((e as Map<dynamic, dynamic>)['record'])),
  ];

  // 3. Guardian copy per shape, with normal and long text; and ablations of
  //    the fixed part (0 consultations, 3 vaccines).
  final List<dynamic> copies = <dynamic>[];
  for (int i = 0; i < nPatients; i++) {
    for (final String variant in <String>['normal', 'largo']) {
      final Map<String, dynamic> j = c.patient(i, variant: variant, k: 10);
      for (final List<int> s in kShapes) {
        final Map<String, dynamic> a = copyOf(j, s[0], s[1]);
        copies.add(<String, dynamic>{
          'i': i,
          'texto': variant,
          'k': s[0],
          'm': s[1],
          for (final Fmt f in fmts)
            f.name: <String, int>{
              'mensaje': f.message(false, f.guardianSealed(a)),
              'adr006': f.message(false, f.guardianSealed(stripAdr006(a))),
              'cuerpo': f.body(a, false),
              'plano': f.plaintext(a, false),
            },
        });
      }
    }
    final Map<String, dynamic> base = c.patient(i, k: 0);
    Map<String, dynamic> without(void Function(Map<String, dynamic>) edit) {
      final Map<String, dynamic> j = asMap(deep(base));
      edit(j);
      return j;
    }

    final Map<String, Map<String, dynamic>> abl =
        <String, Map<String, dynamic>>{
          'completa': base,
          'sin_vacunas': without((j) => j['vaccinationRecord'] = <dynamic>[]),
          'sin_antecedentes': without((j) => j.remove('backgroundHistory')),
          'sin_alergias': without((j) => j['allergies'] = <dynamic>[]),
          'sin_cuidador2': without((j) => j.remove('guardian2Info')),
        };
    copies.add(<String, dynamic>{
      'i': i,
      'ablacion': true,
      for (final MapEntry<String, Map<String, dynamic>> e in abl.entries)
        e.key: <String, int>{
          for (final Fmt f in fmts)
            f.name: f.message(false, f.guardianSealed(copyOf(e.value, 0, 3))),
        },
    });
  }
  res['copias'] = copies;

  // 4. What the app writes on each chip (with and without ADR 006's cuts).
  final List<dynamic> fits = <dynamic>[];
  for (int i = 0; i < nPatients; i++) {
    for (final String variant in <String>['normal', 'largo']) {
      final PatientFullRecord r = record(c.patient(i, variant: variant, k: 10));
      for (final MapEntry<String, int> chip in kChips.entries) {
        if (chip.key == 'NTAG213') continue;
        fits.add(<String, dynamic>{
          'i': i,
          'texto': variant,
          'chip': chip.key,
          for (final Fmt f in fmts) ...<String, dynamic>{
            f.name: fitRow(f.fit(r, chip.value, false)),
            '${f.name}+adr006': fitRow(f.fit(r, chip.value, true)),
          },
        });
      }
    }
  }
  res['ajuste'] = fits;

  // 5. Contract fixtures (exact anchors of the 21 Oct analysis), if present.
  final List<dynamic> fx = <dynamic>[];
  for (final bool canonical
      in c.fixtures == null ? <bool>[] : <bool>[false, true]) {
    for (final bool minimal in <bool>[false, true]) {
      for (final List<int> s in <List<int>>[
        <int>[0, 0],
        <int>[1, 0],
        <int>[0, 3],
        <int>[1, 3],
        <int>[3, 3],
      ]) {
        final Map<String, dynamic> j = fixtureRecord(
          c,
          consultations: s[0],
          vaccines: s[1],
          minimal: minimal,
          canonical: canonical,
        );
        final Map<String, dynamic> a = copyOf(j, s[0], s[1]);
        fx.add(<String, dynamic>{
          'canonica': canonical,
          'minima': minimal,
          'k': s[0],
          'm': s[1],
          for (final Fmt f in fmts)
            f.name: f.message(false, f.guardianSealed(a)),
        });
      }
      final PatientFullRecord r = record(
        fixtureRecord(
          c,
          consultations: 3,
          vaccines: 3,
          minimal: minimal,
          canonical: canonical,
        ),
      );
      for (final String chip in <String>['NTAG215', 'NTAG216']) {
        fx.add(<String, dynamic>{
          'canonica': canonical,
          'minima': minimal,
          'chip': chip,
          for (final Fmt f in fmts)
            f.name: fitRow(f.fit(r, kChips[chip]!, false)),
        });
      }
    }
  }
  res['fixtures'] = fx;

  // 6. Siblings: separate devices against one shared device (emulated).
  final List<dynamic> fam = <dynamic>[];
  for (int fi = 0; fi < c.families.length; fi++) {
    final List<dynamic> sibs = c.families[fi] as List<dynamic>;
    final List<Map<String, dynamic>> cps = <Map<String, dynamic>>[
      for (final dynamic s in sibs) copyOf(asMap(s), 3, 3),
    ];
    for (int n = 1; n <= cps.length; n++) {
      fam.add(<String, dynamic>{
        'familia': fi,
        'hermanos': n,
        for (final Fmt f in fmts)
          f.name: <String, int>{
            'separados': <int>[
              for (final Map<String, dynamic> a in cps.sublist(0, n))
                f.message(false, f.guardianSealed(a)),
            ].reduce((int x, int y) => x + y),
            'compartido': f.message(false, f.sharedSealed(cps.sublist(0, n))),
          },
      });
    }
  }
  res['familias'] = fam;
  return res;
}
