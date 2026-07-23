// lib/src/core/nfc/nfc_guardian_alias.dart
//
// Key aliasing for the guardian NFC payload.
//
// The guardian card carries the full PatientFullRecord JSON shape so that
// reconstruction is a plain, forward-compatible `fromJson`. That shape uses
// long, descriptive keys ("treatmentPlanObservations", "historyOfCurrentIllness"
// …) which, repeated across every consultation, dominate the compressed size —
// on a realistic 2-consultation record, aliasing the keys takes the encrypted
// payload from ~562 B to ~379 B, enough to fit even an NTAG215 (~457 B usable)
// and leaving comfortable room on an NTAG216 (~833 B).
//
// Design constraints that shaped this:
//
//   * The alias must be REVERSIBLE and LOSSLESS. Reconstruction expands the
//     short keys back to the full shape before `PatientFullRecord.fromJson`,
//     which is left untouched — the header of nfc_guardian_payload.dart promises
//     fromJson stays authoritative and evolves on its own.
//
//   * A key NOT in the table passes through UNCHANGED. This is deliberate: when
//     someone adds a field to the model and forgets to alias it, the field is
//     still written and read correctly — it just costs a few more bytes. Silent
//     data loss is never acceptable on a clinical record; a slightly larger
//     payload is.
//
//   * Aliasing is applied ONLY to the guardian payload, in dedicated build /
//     reconstruct steps — never inside NfcPayloadCodec. The codec stays a dumb
//     byte pipeline, and the patient triage payload (which has its own short
//     keys and its own path) is completely unaffected.
//
//   * A schema version marker (`kAliasSchemaKey` = kAliasSchemaVersion) is added
//     at the root. A decoded map WITHOUT it is a pre-alias (v1) card and is
//     expanded with the identity mapping, so no chip already written in the
//     field ever stops reading.

/// Root key holding the payload schema version. Never itself aliased.
const String kAliasSchemaKey = r'$v';

/// Current guardian payload schema version. v1 = full keys (no marker);
/// v2 = aliased keys (this file).
const int kAliasSchemaVersion = 2;

/// Full key → short key. Applied recursively to every map in the guardian
/// payload. Any key absent here is left as-is.
///
/// Keys are chosen for frequency × length: the ones that repeat inside
/// medicalHistory / vaccinationRecord entries matter most, because those lists
/// are where the payload grows.
const Map<String, String> _fullToShort = <String, String>{
  // Root
  'patientId': 'pid',
  'deviceUid': 'du',
  'organizationId': 'oid',
  'patientInfo': 'pi',
  'guardianInfo': 'gi',
  'guardian2Info': 'gi2',
  'allergies': 'alg',
  'backgroundHistory': 'bg',
  'medicalHistory': 'mh',
  'vaccinationRecord': 'vr',

  // Identification / demographics
  'identification': 'idn',
  'documentType': 'dt',
  'documentNumber': 'dn',
  'firstName': 'fn',
  'secondName': 'sn',
  'firstLastName': 'ln',
  'secondLastName': 'sln',
  'dob': 'dob',
  'biologicalSex': 'bs',
  'genderIdentity': 'gid',
  'nationalityCode': 'nc',
  'nationalityName': 'nn',
  'bloodType': 'bt',
  'ethnicity': 'eth',
  'ethnicCommunity': 'ec',
  'disabilityCategory': 'dc',

  // Address
  'address': 'ad',
  'city': 'cy',
  'cityCode': 'cyc',
  'state': 'st',
  'street': 'str',
  'country': 'co',
  'countryName': 'con',
  'zone': 'zn',
  'zipCode': 'zip',

  // Guardian
  'name': 'nm',
  'relationship': 'rel',
  'phone': 'ph',
  'consent': 'cs',
  'accepted': 'ac',
  'acceptedAt': 'aat',
  'email': 'em',

  // Allergy
  'category': 'cat',
  'allergen': 'alr',
  'reaction': 'rx',

  // Background history
  'chronicConditions': 'chc',
  'chronicDescription': 'chd',
  'chronicCie10Code': 'ch10',
  'chronicCie11Code': 'ch11',
  'personalHistory': 'ph2',
  'familyHistory': 'fh',
  'familyHistoryNotes': 'fhn',
  'medications': 'med',
  'medicationName': 'mn',
  'dosage': 'dsg',

  // Medical history (consultations) — highest-volume keys
  'startDateTime': 'sd',
  'endDateTime': 'ed',
  'encounterIdentifier': 'ei',
  'historyOfCurrentIllness': 'hci',
  'clinicalEvaluation': 'ce',
  'generalPhysicalExamination': 'gpe',
  'systemsExamination': 'se',
  'diagnosis': 'dx',
  'diagnosisType': 'dxt',
  'conditionDescription': 'cd',
  'conditionCie10Code': 'c10',
  'conditionCie11Code': 'c11',
  'icd10Code': 'i10',
  'icd11Code': 'i11',
  'treatmentPlanObservations': 'tpo',
  'historyOfCurrentIllnessNotes': 'hcin',
  'physician': 'phy',
  'practitioner': 'prc',
  'provider': 'prv',
  'careEnvironment': 'cae',
  'careModality': 'cam',
  'entryRoute': 'er',
  'externalCause': 'exc',
  'dischargeDisposition': 'dd',
  'riskFactors': 'rf',
  'incapacity': 'inc',
  'days': 'dys',
  'maternityLeaveDays': 'mld',
  'serviceGroup': 'sg',
  'scope': 'scp',
  'location': 'loc',
  'locationSeatCode': 'lsc',
  'payer': 'pay',
  'nitNumber': 'nit',
  'repsCode': 'rc',
  'notes': 'nt',

  // Vaccination
  'vaccinationId': 'vid',
  'vaccineName': 'vn',
  'vaccineCode': 'vc',
  'dciCode': 'dci',
  'dose': 'ds',
  'date': 'dte',
  'administratedAt': 'aa',
  'administratedBy': 'ab',
  'entryRouteVaccine': 'erv',

  // Generic shared
  'code': 'cde',
  'description': 'des',
  'type': 'ty',
  'status': 'sts',
};

/// Short key → full key, derived from [_fullToShort]. Built once.
final Map<String, String> _shortToFull = <String, String>{
  for (final MapEntry<String, String> e in _fullToShort.entries) e.value: e.key,
};

/// Applies the alias to a guardian payload: recursively shortens every known
/// key and stamps the schema version at the root. The input is not mutated.
///
/// Signature values (base64 PNGs) are expected to already be stripped by the
/// caller; this only renames keys.
Map<String, dynamic> aliasGuardianPayload(Map<String, dynamic> full) {
  final aliased = _renameKeys(full, _fullToShort) as Map<String, dynamic>;
  aliased[kAliasSchemaKey] = kAliasSchemaVersion;
  return aliased;
}

/// Reverses [aliasGuardianPayload]. A map without [kAliasSchemaKey] is treated
/// as a pre-alias (v1) card and returned with keys unchanged, so older chips
/// keep reading. The input is not mutated.
Map<String, dynamic> unaliasGuardianPayload(Map<String, dynamic> decoded) {
  final version = decoded[kAliasSchemaKey];
  if (version == null) {
    // v1 card: full keys already. Nothing to expand.
    return decoded;
  }
  final stripped = Map<String, dynamic>.from(decoded)..remove(kAliasSchemaKey);
  return _renameKeys(stripped, _shortToFull) as Map<String, dynamic>;
}

/// Recursively rewrites map keys through [table], leaving unmapped keys and all
/// values intact. Lists are walked so nested maps inside history arrays are
/// covered.
Object? _renameKeys(Object? node, Map<String, String> table) {
  if (node is Map) {
    return <String, dynamic>{
      for (final MapEntry<dynamic, dynamic> e in node.entries)
        (table[e.key.toString()] ?? e.key.toString()): _renameKeys(
          e.value,
          table,
        ),
    };
  }
  if (node is List) {
    return node.map((Object? e) => _renameKeys(e, table)).toList();
  }
  return node;
}
