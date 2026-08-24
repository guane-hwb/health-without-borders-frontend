// test/unit/nfc_guardian_alias_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_alias.dart';

void main() {
  // The one property that must never break: aliasing then un-aliasing returns
  // the original data unchanged. If this ever fails, guardian records reconstruct
  // wrong offline — silent clinical data corruption.
  group('round trip', () {
    test('a full guardian-shaped map survives alias → unalias unchanged', () {
      final original = <String, dynamic>{
        'patientId': 'p-1',
        'deviceUid': '04:AA:BB',
        'patientInfo': {
          'identification': {'documentType': 'TI', 'documentNumber': '123'},
          'firstName': 'Martha',
          'firstLastName': 'Vega',
          'dob': '2009-01-01',
          'biologicalSex': 'F',
          'nationalityCode': '170',
          'address': {'city': 'Bucaramanga', 'state': 'Santander'},
          'bloodType': 'O+',
        },
        'guardianInfo': {
          'name': 'Carmen',
          'relationship': 'Madre',
          'phone': '300',
          'deviceUid': '04:CC:DD',
        },
        'allergies': [
          {'category': '06', 'allergen': 'maní', 'reaction': 'Urticaria'},
        ],
        'medicalHistory': [
          {
            'startDateTime': '2026-07-16T09:00:00-05:00',
            'historyOfCurrentIllness': 'Cefalea',
            'diagnosis': 'Viral',
            'icd10Code': 'B349',
            'treatmentPlanObservations': 'Acetaminofén',
          },
        ],
        'vaccinationRecord': [
          {'vaccineName': 'Influenza', 'date': '2026-03-14', 'dose': 1},
        ],
      };

      final restored = unaliasGuardianPayload(aliasGuardianPayload(original));
      expect(restored, equals(original));
    });

    test('nested lists of maps are recursed into', () {
      final original = <String, dynamic>{
        'medicalHistory': [
          {'diagnosis': 'a', 'icd10Code': 'A1'},
          {'diagnosis': 'b', 'icd10Code': 'B2'},
        ],
      };
      final restored = unaliasGuardianPayload(aliasGuardianPayload(original));
      expect(restored, equals(original));
    });

    test('deeply nested maps round-trip', () {
      final original = <String, dynamic>{
        'patientInfo': {
          'address': {'city': 'X', 'state': 'Y', 'country': 'Z'},
        },
      };
      final restored = unaliasGuardianPayload(aliasGuardianPayload(original));
      expect(restored, equals(original));
    });
  });

  group('aliasing actually shortens', () {
    test('known keys are replaced with shorter ones', () {
      final aliased = aliasGuardianPayload(<String, dynamic>{
        'treatmentPlanObservations': 'x',
        'historyOfCurrentIllness': 'y',
      });
      expect(aliased.containsKey('treatmentPlanObservations'), isFalse);
      expect(aliased.containsKey('historyOfCurrentIllness'), isFalse);
      expect(aliased['tpo'], 'x');
      expect(aliased['hci'], 'y');
    });

    test('the aliased map has a schema version marker', () {
      final aliased = aliasGuardianPayload(<String, dynamic>{'a': 1});
      expect(aliased[kAliasSchemaKey], kAliasSchemaVersion);
    });
  });

  group('unknown keys pass through', () {
    // A field added to the model but not to the alias table must still survive —
    // a few extra bytes is fine, silent loss is not.
    test('an unmapped key is kept as-is on the way out', () {
      final aliased = aliasGuardianPayload(<String, dynamic>{
        'someBrandNewField': 'value',
      });
      expect(aliased['someBrandNewField'], 'value');
    });

    test('an unmapped key round-trips', () {
      final original = <String, dynamic>{'someBrandNewField': 'value'};
      final restored = unaliasGuardianPayload(aliasGuardianPayload(original));
      expect(restored, equals(original));
    });
  });

  group('backward compatibility', () {
    // A card written before aliasing has no schema marker and full keys. It must
    // read back unchanged, or every wristband already in the field breaks.
    test('a v1 map (no marker) is returned unchanged by unalias', () {
      final v1 = <String, dynamic>{
        'patientId': 'p-1',
        'treatmentPlanObservations': 'full key, no marker',
      };
      expect(unaliasGuardianPayload(v1), equals(v1));
    });

    test('unalias does not mutate its input', () {
      final aliased = aliasGuardianPayload(<String, dynamic>{'diagnosis': 'x'});
      final before = Map<String, dynamic>.from(aliased);
      unaliasGuardianPayload(aliased);
      expect(aliased, equals(before));
    });

    test('alias does not mutate its input', () {
      final original = <String, dynamic>{'diagnosis': 'x'};
      final before = Map<String, dynamic>.from(original);
      aliasGuardianPayload(original);
      expect(original, equals(before));
    });
  });

  group('the alias table is injective', () {
    // Two long keys mapping to the same short key would corrupt data silently.
    // This exercises a representative sample through the round trip; the real
    // guarantee is checked structurally in the table itself, but this catches
    // an accidental duplicate that happens to appear together in one map.
    test('a map using many distinct keys round-trips without loss', () {
      final original = <String, dynamic>{
        'patientId': '1',
        'deviceUid': '2',
        'firstName': '3',
        'firstLastName': '4',
        'documentType': '5',
        'documentNumber': '6',
        'startDateTime': '7',
        'endDateTime': '8',
        'diagnosis': '9',
        'icd10Code': '10',
        'treatmentPlanObservations': '11',
        'vaccineName': '12',
        'vaccineCode': '13',
        'category': '14',
        'allergen': '15',
        'reaction': '16',
      };
      final restored = unaliasGuardianPayload(aliasGuardianPayload(original));
      expect(restored, equals(original));
      // If any two of these collided, the restored map would be missing keys.
      expect(restored.keys.length, original.keys.length);
    });
  });

  group('the schema key is never itself aliased', () {
    test(r'$v is not a mappable key', () {
      // Guard against a future table entry colliding with the marker.
      final aliased = aliasGuardianPayload(<String, dynamic>{'a': 1});
      final restored = unaliasGuardianPayload(aliased);
      expect(restored.containsKey(kAliasSchemaKey), isFalse);
    });
  });
}
