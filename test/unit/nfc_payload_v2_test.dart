// test/unit/nfc_payload_v2_test.dart

import 'dart:io' show RawZLibFilter;
import 'dart:typed_data';

import 'package:cbor/cbor.dart' as cbor;
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_payload.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_v2.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_v2_dictionaries.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_triage_payload.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

const String kKey =
    'a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0';

MedicalHistoryItem _visit(int month) => MedicalHistoryItem(
  encounterIdentifier: '7f1c2a9e-0b4d-4c3e-9a51-2d6f8e0c1b${70 + month}',
  startDateTime: '2026-0$month-10T09:30:00-05:00',
  endDateTime: '2026-0$month-10T09:55:12-05:00',
  practitioner: PractitionerInfo(
    documentType: 'CC',
    documentNumber: '52000111',
    name: 'Laura Gómez',
  ),
  clinicalEvaluation: ClinicalEvaluation(
    historyOfCurrentIllness:
        'Cuadro de 3 días de fiebre, tos seca y congestión nasal.',
    generalPhysicalExamination:
        'Alerta, hidratado. FC 110 lpm, FR 24 rpm, T 38.2 °C.',
    treatmentPlanObservations:
        'Acetaminofén jarabe 150 mg/5 mL, 5 mL cada 6 horas por 3 días.',
  ),
);

VaccinationRecordItem _vaccine(int month) => VaccinationRecordItem(
  vaccinationId: 'c0ffee00-0b4d-4c3e-9a51-2d6f8e0c1b${10 + month}',
  date: '2025-0$month-15',
  vaccineName: 'Pentavalente',
  vaccineCode: '120',
  dose: month,
  administratedBy: 'Yenny Carvajal',
  administratedAt: 'Puesto de salud Villa del Rosario',
);

PatientFullRecord _record({int history = 2}) => PatientFullRecord(
  patientId: '3b2e1f00-aaaa-4bbb-8ccc-0123456789ab',
  deviceUid: '04:A1:B2:C3:D4:E5:80',
  patientInfo: PatientInfo(
    identification: PatientIdentification(
      documentType: 'PT',
      documentNumber: '1234567890',
    ),
    firstLastName: 'Rodríguez',
    firstName: 'Valentina',
    dob: '2019-03-14',
    biologicalSex: 'F',
    nationalityCode: '862',
    address: Address(city: 'Cúcuta', state: 'Norte de Santander'),
    bloodType: 'O+',
    isBloodTypeCertified: true,
    weight: 14.6,
  ),
  guardianInfo: GuardianInfo(
    name: 'María Fernanda Pérez',
    relationship: '01',
    phone: '3001234567',
    deviceUid: '04:11:22:33:44:55:80',
  ),
  allergies: <AllergyInfo>[
    AllergyInfo(category: '01', allergen: 'Penicilina', reaction: 'Urticaria'),
  ],
  medicalHistory: <MedicalHistoryItem>[
    for (int m = 1; m <= history; m++) _visit(m),
  ],
  vaccinationRecord: <VaccinationRecordItem>[
    for (int m = 1; m <= history; m++) _vaccine(m),
  ],
);

Map<String, dynamic> _guardianCopy(PatientFullRecord record) =>
    NfcGuardianPayload.buildWithinCapacity(
      record: record,
      capacityBytes: 1000000,
      estimateSize: (Map<String, dynamic> m) => 0,
    ).payload;

/// The typed CBOR of [payload] decoded as raw CBOR values, to look at what a
/// value became before compression.
cbor.CborMap _raw(Map<String, dynamic> payload, NfcPayloadKind kind) =>
    cbor.cborDecode(NfcPayloadV2.typedCbor(payload, kind)) as cbor.CborMap;

cbor.CborValue? _rawValue(cbor.CborMap map, String key) =>
    map[cbor.CborString(key)];

List<int> _drain(RawZLibFilter filter, {required bool end}) {
  final List<int> out = <int>[];
  List<int>? chunk;
  while ((chunk = filter.processed(flush: true, end: end)) != null) {
    out.addAll(chunk!);
  }
  return out;
}

void main() {
  group('ida y vuelta', () {
    test('el triaje vuelve idéntico', () {
      final payload = NfcTriagePayload.buildPatientPayload(record: _record());

      final back = NfcPayloadV2.decode(
        NfcPayloadV2.encode(payload, NfcPayloadKind.triage),
        NfcPayloadKind.triage,
      );

      expect(back, payload);
    });

    test(
      'la copia del dispositivo del cuidador vuelve idéntica y se reconstruye',
      () {
        final record = _record(history: 3);
        final copy = _guardianCopy(record);

        final back = NfcPayloadV2.decode(
          NfcPayloadV2.encode(copy, NfcPayloadKind.guardian),
          NfcPayloadKind.guardian,
        );

        expect(back, copy);
        final rebuilt = NfcGuardianPayload.reconstructFromGuardian(back);
        expect(rebuilt.patientId, record.patientId);
        expect(rebuilt.medicalHistory.first.startDateTime, isNotEmpty);
        expect(rebuilt.patientInfo.weight, 14.6);
      },
    );

    test('ocupa menos que el formato 1', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(kKey),
      );
      final triage = NfcTriagePayload.buildPatientPayload(record: _record());
      final copy = _guardianCopy(_record(history: 3));

      final int v1Triage = codec.estimateSize(triage);
      final int v2Triage = codec.sealedSize(
        NfcPayloadV2.encode(triage, NfcPayloadKind.triage).length,
      );
      final int v1Copy = codec.estimateSize(copy);
      final int v2Copy = codec.sealedSize(
        NfcPayloadV2.encode(copy, NfcPayloadKind.guardian).length,
      );

      expect(v2Triage, lessThan(v1Triage));
      expect(v2Copy, lessThan(v1Copy));
    });

    test('lo cifrado con el códec se abre y se decodifica', () async {
      final codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(kKey),
      );
      final copy = _guardianCopy(_record());
      final sealed = await codec.seal(
        NfcPayloadV2.encode(copy, NfcPayloadKind.guardian),
      );

      final opened = await codec.open(sealed);

      expect(opened, isNotNull);
      expect(
        NfcPayloadV2.decode(opened!.plaintext, NfcPayloadKind.guardian),
        copy,
      );
    });
  });

  group('valores tipados', () {
    test('UUID, UID, fecha, fecha-hora y dígitos dejan de ser texto', () {
      final copy = _guardianCopy(_record());
      final root = _raw(copy, NfcPayloadKind.guardian);

      expect(_rawValue(root, 'pid'), isA<cbor.CborBytes>());
      expect((_rawValue(root, 'pid')! as cbor.CborBytes).bytes, hasLength(16));
      expect(_rawValue(root, 'dug'), isA<cbor.CborBytes>());
      final pi = _rawValue(root, 'pi')! as cbor.CborMap;
      expect(_rawValue(pi, 'dob'), isA<cbor.CborSmallInt>());
      expect(_rawValue(pi, 'nc'), isA<cbor.CborSmallInt>());
      final visit =
          (_rawValue(root, 'mh')! as cbor.CborList).first as cbor.CborMap;
      expect(_rawValue(visit, 'sd'), isA<cbor.CborList>());
      expect(_rawValue(visit, 'ei'), isA<cbor.CborBytes>());
    });

    test('un valor fuera de la forma canónica se queda como texto', () {
      final payload = <String, dynamic>{
        'dob': '2019-3-14',
        'gUid': '04:a1:b2',
        'g2Uid': '04A1B2',
        'docN': '0123',
        'gPh': '+57 300 123 4567',
      };
      final root = _raw(payload, NfcPayloadKind.triage);

      for (final String key in payload.keys) {
        expect(_rawValue(root, key), isA<cbor.CborString>(), reason: key);
      }
      expect(
        NfcPayloadV2.decode(
          NfcPayloadV2.encode(payload, NfcPayloadKind.triage),
          NfcPayloadKind.triage,
        ),
        payload,
      );
    });

    test(
      'fechas y fechas-hora imposibles o sin forma exacta siguen en texto',
      () {
        final payload = <String, dynamic>{
          'pi': <String, dynamic>{'dob': '2026-02-30'},
          'mh': <dynamic>[
            <String, dynamic>{
              'sd': '2026-06-10T09:30:00Z',
              'ed': '2026-06-10T09:30:00.000-05:00',
            },
            <String, dynamic>{'sd': '2026-06-10T09:30:00+05:07'},
          ],
        };
        final root = _raw(payload, NfcPayloadKind.guardian);

        final pi = _rawValue(root, 'pi')! as cbor.CborMap;
        expect(_rawValue(pi, 'dob'), isA<cbor.CborString>());
        final visits = _rawValue(root, 'mh')! as cbor.CborList;
        for (final cbor.CborValue v in visits) {
          for (final cbor.CborValue value in (v as cbor.CborMap).values) {
            expect(value, isA<cbor.CborString>());
          }
        }
        expect(
          NfcPayloadV2.decode(
            NfcPayloadV2.encode(payload, NfcPayloadKind.guardian),
            NfcPayloadKind.guardian,
          ),
          payload,
        );
      },
    );

    test(
      'fechas-hora con segundos y con desfases positivos vuelven exactas',
      () {
        final payload = <String, dynamic>{
          'mh': <dynamic>[
            <String, dynamic>{
              'sd': '2026-11-17T23:59:59+05:30',
              'ed': '1999-12-31T00:00:01-12:00',
            },
          ],
          'gi': <String, dynamic>{
            'cs': <String, dynamic>{'aat': '2026-01-01T00:00:00+00:00'},
          },
        };
        final root = _raw(payload, NfcPayloadKind.guardian);
        final visit =
            (_rawValue(root, 'mh')! as cbor.CborList).first as cbor.CborMap;
        expect(_rawValue(visit, 'sd'), isA<cbor.CborList>());
        expect(_rawValue(visit, 'ed'), isA<cbor.CborList>());

        expect(
          NfcPayloadV2.decode(
            NfcPayloadV2.encode(payload, NfcPayloadKind.guardian),
            NfcPayloadKind.guardian,
          ),
          payload,
        );
      },
    );

    test('las claves tipadas sólo cuentan en su tipo de carga', () {
      // En el triaje, 'vid' es el código VIDA (texto); en la copia del
      // dispositivo del cuidador es el id de una vacuna (UUID).
      const String uuid = '3b2e1f00-aaaa-4bbb-8ccc-0123456789ab';
      final triage = _raw(<String, dynamic>{
        'vid': uuid,
      }, NfcPayloadKind.triage);
      final copy = _raw(<String, dynamic>{
        'vid': uuid,
      }, NfcPayloadKind.guardian);

      expect(_rawValue(triage, 'vid'), isA<cbor.CborString>());
      expect(_rawValue(copy, 'vid'), isA<cbor.CborBytes>());
    });
  });

  group('lo que no se escribe', () {
    test('un payload que no volvería idéntico no se codifica', () {
      // Un número de documento que ya es entero volvería como texto.
      expect(
        () => NfcPayloadV2.encode(<String, dynamic>{
          'docN': 123,
        }, NfcPayloadKind.triage),
        throwsA(isA<NfcPayloadV2Exception>()),
      );
    });

    test('un valor que no es JSON no se codifica', () {
      expect(
        () => NfcPayloadV2.encode(<String, dynamic>{
          'fn': DateTime(2026),
        }, NfcPayloadKind.triage),
        throwsA(isA<NfcPayloadV2Exception>()),
      );
    });
  });

  group('lo que no se lee', () {
    final Uint8List good = NfcPayloadV2.encode(
      NfcTriagePayload.buildPatientPayload(record: _record()),
      NfcPayloadKind.triage,
    );

    test('otro formato', () {
      final Uint8List other = Uint8List.fromList(good)..[0] = 1;
      expect(
        () => NfcPayloadV2.decode(other, NfcPayloadKind.triage),
        throwsFormatException,
      );
    });

    test('un diccionario que esta build no tiene', () {
      final Uint8List other = Uint8List.fromList(good)..[1] = 99;
      expect(
        () => NfcPayloadV2.decode(other, NfcPayloadKind.triage),
        throwsFormatException,
      );
    });

    test('un flujo truncado o dañado', () {
      expect(
        () => NfcPayloadV2.decode(
          Uint8List.sublistView(good, 0, good.length ~/ 2),
          NfcPayloadKind.triage,
        ),
        throwsFormatException,
      );
      expect(
        () => NfcPayloadV2.decode(
          Uint8List.fromList(<int>[2, 1]),
          NfcPayloadKind.triage,
        ),
        throwsFormatException,
      );
    });
  });

  group('diccionarios', () {
    test('los bytes de cada diccionario no cambian', () {
      // Fijados aquí, no en el archivo generado: regenerarlo no puede cambiar
      // un diccionario sin que esta prueba falle. Cambiarlos sólo mientras
      // ningún chip se haya escrito con él (ADR 005).
      const String triage1 =
          '830f3798327f06ab5eac75220cfebc4f797687ab9347cbc67ca92c568d8a1c97';
      const String guardian1 =
          '54dfb79957665a2bf1fac572fe7d8f40c39ea72517107cf908c406f95b645347';
      expect(
        crypto.sha256.convert(nfcV2TriageDictionary(1)!).toString(),
        triage1,
      );
      expect(
        crypto.sha256.convert(nfcV2GuardianDictionary(1)!).toString(),
        guardian1,
      );
      expect(kNfcV2TriageDictionary1Sha256, triage1);
      expect(kNfcV2GuardianDictionary1Sha256, guardian1);
    });

    test('caben en la ventana de DEFLATE y se escribe con el 1', () {
      expect(nfcV2TriageDictionary(1)!.length, lessThanOrEqualTo(32 * 1024));
      expect(nfcV2GuardianDictionary(1)!.length, lessThanOrEqualTo(32 * 1024));
      expect(NfcPayloadV2.writeDictionaryId(NfcPayloadKind.triage), 1);
      expect(NfcPayloadV2.writeDictionaryId(NfcPayloadKind.guardian), 1);
      expect(nfcV2TriageDictionary(2), isNull);
      expect(nfcV2GuardianDictionary(0), isNull);
    });

    test('el flujo sólo depende del contenido del diccionario', () {
      // Un lector que comprime el diccionario a otro nivel, y por tanto con
      // otros bytes, lee igual: el flujo es DEFLATE con diccionario
      // predefinido, como el de inflateSetDictionary.
      final payload = NfcTriagePayload.buildPatientPayload(record: _record());
      final Uint8List plaintext = NfcPayloadV2.encode(
        payload,
        NfcPayloadKind.triage,
      );
      final Uint8List dictionary = nfcV2TriageDictionary(1)!;
      final RawZLibFilter primer = RawZLibFilter.deflateFilter(
        level: 1,
        raw: true,
      );
      primer.process(dictionary, 0, dictionary.length);
      final List<int> input = <int>[
        ..._drain(primer, end: false),
        ...plaintext.sublist(2),
      ];
      final RawZLibFilter inflater = RawZLibFilter.inflateFilter(raw: true);
      inflater.process(input, 0, input.length);
      final List<int> out = _drain(inflater, end: true);

      expect(
        out.sublist(dictionary.length),
        NfcPayloadV2.typedCbor(payload, NfcPayloadKind.triage),
      );
    });
  });
}
