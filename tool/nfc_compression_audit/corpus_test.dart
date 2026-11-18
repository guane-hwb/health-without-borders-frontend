// tool/nfc_compression_audit/corpus_test.dart
//
// Step 1 of the NFC compression audit (docs/architecture/nfc-compression-audit.md).
// Generates a synthetic corpus with the app's own builders
// (PatientFullRecord.fromJson, NfcTriagePayload, NfcGuardianPayload,
// aliasGuardianPayload, NfcPayloadCodec) and writes, per record:
//   - the triage map and the guardian-copy maps (k = 0..3 consultations and
//     vaccines),
//   - the CBOR bytes the current codec produces (the bench checks it
//     reproduces them byte for byte),
//   - a version without redundant keys, each removed only if what the app
//     reconstructs when it reads the chip stays identical,
//   - what buildWithinCapacity keeps today on an NTAG215 and an NTAG216.
// Invented data only: no real record.
//
// Not part of the test suite (it lives outside test/); it skips itself unless
// HWB_AUDIT_OUT names the output directory. See README.md in this directory.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cbor/cbor.dart' as cbor;
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_alias.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_payload.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_keyring.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_codec.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_payload_service.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_triage_payload.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

final String? kOut = Platform.environment['HWB_AUDIT_OUT'];
const String kKey =
    '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';

// ── Vocabulary (Spanish, as the app's users write) ──────────────────────────
// Each list has a shared part and a part that only appears in the test split,
// so that dictionaries are not measured against their own training data.

const _nombres = [
  'Valentina',
  'Sofía',
  'Isabella',
  'Camila',
  'Mariana',
  'Daniela',
  'Luciana',
  'Victoria',
  'Gabriela',
  'Sara',
  'Antonella',
  'Salomé',
  'Emily',
  'Ashley',
  'Santiago',
  'Samuel',
  'Matías',
  'Sebastián',
  'Alejandro',
  'Thiago',
  'Emmanuel',
  'Jesús',
  'José',
  'Luis',
  'Carlos',
  'Miguel',
  'Ángel',
  'Dylan',
  'Josué',
  'Jhon',
  'Yorgelis',
  'Yusmary',
  'Dayana',
  'Génesis',
  'Rosángela',
  'Wilmer',
  'Yonaiker',
  'Brayan',
  'Keiner',
  'Yeferson',
];
const _nombresPrueba = ['Oriana', 'Yuleidy', 'Anderson', 'Deiver', 'Milagros'];
const _apellidos = [
  'Rodríguez',
  'González',
  'Pérez',
  'Hernández',
  'García',
  'Martínez',
  'López',
  'Sánchez',
  'Ramírez',
  'Torres',
  'Díaz',
  'Rojas',
  'Moreno',
  'Contreras',
  'Mendoza',
  'Chacón',
  'Guerrero',
  'Rivas',
  'Salazar',
  'Villamizar',
  'Jaimes',
  'Peña',
  'Parra',
  'Suárez',
  'Carrillo',
  'Ortega',
  'Briceño',
  'Colmenares',
  'Linares',
  'Uzcátegui',
];
const _apellidosPrueba = ['Quintero', 'Albarrán', 'Zambrano', 'Montilla'];
const _ciudades = [
  ['Cúcuta', 'Norte de Santander', '54001'],
  ['Villa del Rosario', 'Norte de Santander', '54874'],
  ['Maicao', 'La Guajira', '44430'],
  ['Riohacha', 'La Guajira', '44001'],
  ['Arauca', 'Arauca', '81001'],
  ['Bogotá D.C.', 'Bogotá D.C.', '11001'],
  ['Barranquilla', 'Atlántico', '08001'],
  ['Bucaramanga', 'Santander', '68001'],
  ['Medellín', 'Antioquia', '05001'],
  ['Ipiales', 'Nariño', '52356'],
];
const _ciudadesPrueba = [
  ['Pamplona', 'Norte de Santander', '54518'],
  ['Saravena', 'Arauca', '81736'],
];

const _sintomas = [
  'fiebre no cuantificada',
  'fiebre cuantificada en 38,5 °C',
  'tos seca',
  'tos húmeda',
  'rinorrea hialina',
  'congestión nasal',
  'deposiciones líquidas sin moco ni sangre',
  'vómito postprandial',
  'dolor abdominal difuso',
  'inapetencia',
  'lesiones pruriginosas en piel',
  'prurito nocturno',
  'otalgia derecha',
  'odinofagia',
  'disuria',
  'decaimiento',
  'sibilancias',
  'dificultad respiratoria leve',
  'pérdida de peso',
  'cefalea frontal',
];
const _sintomasPrueba = [
  'hiporexia marcada',
  'epistaxis escasa',
  'lesiones costrosas en cuero cabelludo',
];
const _negaciones = [
  'dificultad respiratoria',
  'sangrado',
  'convulsiones',
  'alergias conocidas',
  'vómito',
  'fiebre',
];
const _hallazgos = [
  'Faringe eritematosa sin exudados.',
  'Ruidos cardíacos rítmicos sin soplos.',
  'Pulmones bien ventilados, sin ruidos agregados.',
  'Abdomen blando, depresible, no doloroso, ruidos intestinales presentes.',
  'Piel con pápulas eritematosas en tronco y extremidades.',
  'Membrana timpánica derecha abombada y eritematosa.',
  'Mucosas semihúmedas, llenado capilar menor de 2 segundos.',
  'Sibilancias espiratorias bilaterales, sin tirajes.',
  'Palidez mucocutánea leve.',
];
const _hallazgosPrueba = [
  'Adenopatías cervicales móviles no dolorosas.',
  'Lesiones vesiculares agrupadas en región perioral.',
];
const _sistemas = [
  'Cardiopulmonar',
  'Abdomen',
  'Piel',
  'Orofaringe',
  'Otoscopia',
  'Neurológico',
  'Genitourinario',
];
const _recomendaciones = [
  'Abundantes líquidos.',
  'Lavado nasal con solución salina.',
  'Continuar lactancia materna.',
  'Se explican signos de alarma a la madre.',
  'Medidas de higiene en casa.',
  'Suplemento nutricional según guía.',
  'Se entrega desparasitante.',
  'Se remite a valoración por nutrición.',
];
const _medicamentos = [
  ['Acetaminofén jarabe 150 mg/5 mL', '5 mL', 'cada 6 horas', '3 días', 'oral'],
  [
    'Amoxicilina suspensión 250 mg/5 mL',
    '7 mL',
    'cada 8 horas',
    '7 días',
    'oral',
  ],
  ['Albendazol 400 mg', '1 tableta', 'dosis única', '1 día', 'oral'],
  [
    'Sales de rehidratación oral',
    '1 sobre',
    'tras cada deposición',
    '3 días',
    'oral',
  ],
  [
    'Sulfato ferroso gotas 25 mg/mL',
    '15 gotas',
    'cada 24 horas',
    '3 meses',
    'oral',
  ],
  [
    'Ibuprofeno suspensión 100 mg/5 mL',
    '5 mL',
    'cada 8 horas',
    '3 días',
    'oral',
  ],
  ['Loratadina jarabe 5 mg/5 mL', '5 mL', 'cada 24 horas', '5 días', 'oral'],
  [
    'Salbutamol inhalador 100 mcg',
    '2 puff',
    'cada 6 horas',
    '5 días',
    'inhalada',
  ],
  ['Permetrina loción 5 %', 'aplicar', 'noche', '2 noches', 'tópica'],
  ['Zinc jarabe 20 mg/5 mL', '5 mL', 'cada 24 horas', '14 días', 'oral'],
];
const _medicamentosPrueba = [
  [
    'Nistatina suspensión 100.000 UI/mL',
    '1 mL',
    'cada 6 horas',
    '7 días',
    'oral',
  ],
];
const _diagnosticos = [
  ['J00', 'Rinofaringitis aguda [resfriado común]'],
  [
    'J06.9',
    'Infección aguda de las vías respiratorias superiores, no especificada',
  ],
  ['A09', 'Diarrea y gastroenteritis de presunto origen infeccioso'],
  ['E44.0', 'Desnutrición proteicocalórica moderada'],
  ['D50.9', 'Anemia por deficiencia de hierro sin otra especificación'],
  ['B82.9', 'Parasitosis intestinal, sin otra especificación'],
  ['L20.9', 'Dermatitis atópica, no especificada'],
  ['H66.9', 'Otitis media, no especificada'],
  ['J45.9', 'Asma, no especificada'],
  ['N39.0', 'Infección de vías urinarias, sitio no especificado'],
  ['B86', 'Escabiosis'],
  ['L01.0', 'Impétigo [cualquier sitio anatómico] [cualquier organismo]'],
  ['Z00.1', 'Control de salud de rutina del niño'],
  ['E46', 'Desnutrición proteicocalórica, no especificada'],
];
const _diagnosticosPrueba = [
  ['B35.0', 'Tiña de la barba y del cuero cabelludo'],
  ['J20.9', 'Bronquitis aguda, no especificada'],
];
const _cronicas = [
  ['Asma bronquial', 'J45.9'],
  ['Desnutrición crónica', 'E45'],
  ['Anemia ferropénica', 'D50.9'],
  ['Dermatitis atópica', 'L20.9'],
  ['Epilepsia', 'G40.9'],
  ['Cardiopatía congénita', 'Q24.9'],
];
const _alergenos = [
  ['01', 'Penicilina'],
  ['01', 'Amoxicilina'],
  ['01', 'Ibuprofeno'],
  ['02', 'Maní'],
  ['02', 'Huevo'],
  ['02', 'Leche de vaca'],
  ['03', 'Polvo doméstico'],
  ['04', 'Picadura de abeja'],
  ['05', 'Látex'],
];
const _reacciones = [
  'Urticaria generalizada',
  'Edema palpebral',
  'Dificultad respiratoria',
  'Erupción cutánea',
  'Vómito',
];
const _vacunas = [
  ['BCG', '19'],
  ['Hepatitis B', '08'],
  ['Pentavalente', '120'],
  ['Polio inactivada (VIP)', '10'],
  ['Rotavirus', '119'],
  ['Neumococo conjugada', '133'],
  ['Influenza pediátrica', '140'],
  ['Triple viral (SRP)', '03'],
  ['Fiebre amarilla', '37'],
  ['Hepatitis A', '83'],
  ['Varicela', '21'],
  ['DPT', '01'],
];
const _vacunasPrueba = [
  ['VPH', '62'],
];
const _profesionales = [
  'Laura Gómez',
  'Andrés Felipe Rincón',
  'María José Duarte',
  'Carlos Peña',
  'Diana Marcela Ruiz',
  'Jorge Iván Castro',
  'Paola Andrea Vargas',
];
const _prestadores = [
  ['540010012301', 'ESE Hospital Universitario Erasmo Meoz'],
  ['548740031501', 'ESE Hospital Jorge Cristo Sahium'],
  ['444300059801', 'Hospital San José de Maicao'],
  ['110010998801', 'Brigada de salud extramural'],
];
const _pagadores = [
  'Sin afiliación',
  'Nueva EPS',
  'Coosalud',
  'Población migrante no asegurada',
  'Cajacopi',
];
const _vacunadores = [
  'Yenny Carvajal',
  'Luis Mora',
  'Ana Beltrán',
  'Pedro Sierra',
];
const _sitiosVacuna = [
  'Puesto de salud Villa del Rosario',
  'IPS Comuneros',
  'Centro de salud Maicao',
  'Brigada extramural Cúcuta',
];

class Gen {
  Gen(int seed, {required this.test}) : r = Random(seed);
  final Random r;
  final bool test;

  T pick<T>(List<T> base, [List<T> extra = const []]) {
    final List<T> xs = test ? [...base, ...extra] : base;
    return xs[r.nextInt(xs.length)];
  }

  bool p(double x) => r.nextDouble() < x;
  int between(int a, int b) => a + r.nextInt(b - a + 1);
  String two(int n) => n.toString().padLeft(2, '0');

  String hex(int bytes) => List<String>.generate(
    bytes,
    (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  String uuid() {
    final List<String> h = hex(16).split('');
    h[12] = '4';
    h[16] = '89ab'[r.nextInt(4)];
    final String s = h.join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-'
        '${s.substring(16, 20)}-${s.substring(20)}';
  }

  String uid() => <String>[
    '04',
    for (int i = 0; i < 6; i++)
      r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join(':').toUpperCase();

  String digits(int n) => List<String>.generate(
    n,
    (int i) => i == 0 ? '${1 + r.nextInt(9)}' : '${r.nextInt(10)}',
  ).join();

  DateTime day(DateTime from, DateTime to) =>
      from.add(Duration(days: r.nextInt(to.difference(from).inDays + 1)));

  String ymd(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  String isoWithOffset(DateTime d) =>
      '${d.year}-${two(d.month)}-${two(d.day)}T${two(d.hour)}:${two(d.minute)}:'
      '${two(d.second)}-05:00';

  String nombre() => pick(_nombres, _nombresPrueba);
  String apellido() => pick(_apellidos, _apellidosPrueba);

  String enfermedadActual() {
    final List<String> s = <String>[
      for (int i = 0; i < between(1, 3); i++) pick(_sintomas, _sintomasPrueba),
    ];
    final String sx = s.length == 1
        ? s[0]
        : '${s.sublist(0, s.length - 1).join(', ')} y ${s.last}';
    final int n = between(1, 10);
    final String base = pick(<String>[
      'Cuadro clínico de $n días de evolución consistente en $sx.',
      'Madre refiere $sx desde hace $n días.',
      'Consulta por $sx de $n días de evolución.',
      'Acudiente refiere que el menor presenta $sx desde hace $n días.',
    ]);
    final StringBuffer b = StringBuffer(base);
    if (p(0.5)) b.write(' Niega ${pick(_negaciones)}.');
    if (p(0.3)) {
      b.write(
        ' Recibió ${pick(_medicamentos, _medicamentosPrueba)[0].split(' ').first.toLowerCase()} en casa sin mejoría.',
      );
    }
    if (p(0.25)) b.write(' Llegó al país hace ${between(1, 20)} semanas.');
    return b.toString();
  }

  String examenFisico(double peso) {
    final String estado = pick(<String>[
      'alerta',
      'activo',
      'irritable',
      'decaído',
    ]);
    final String hidra = pick(<String>[
      'hidratado',
      'deshidratado leve',
      'bien perfundido',
    ]);
    final StringBuffer b = StringBuffer(
      'Paciente $estado, $hidra. FC ${between(80, 150)} lpm, '
      'FR ${between(18, 45)} rpm, T ${between(360, 395) / 10} °C, '
      'SatO2 ${between(90, 99)} %, peso ${peso.toStringAsFixed(1)} kg.',
    );
    for (int i = 0; i < between(0, 2); i++) {
      b.write(' ${pick(_hallazgos, _hallazgosPrueba)}');
    }
    return b.toString();
  }

  String sistemas() => <String>[
    for (int i = 0; i < between(1, 3); i++)
      '${pick(_sistemas)}: ${pick(_hallazgos, _hallazgosPrueba).toLowerCase()}',
  ].join(' ');

  String plan() {
    final List<String> m = pick(_medicamentos, _medicamentosPrueba);
    final StringBuffer b = StringBuffer(
      '${m[0]}, ${m[1]} ${m[2]} por ${m[3]}.',
    );
    for (int i = 0; i < between(1, 2); i++) {
      b.write(' ${pick(_recomendaciones)}');
    }
    b.write(
      ' Control en ${between(2, 30)} días o antes si hay signos de alarma.',
    );
    return b.toString();
  }

  Map<String, dynamic> consulta(DateTime cuando, double peso) {
    final DateTime ini = cuando.add(
      Duration(hours: between(7, 16), minutes: between(0, 59)),
    );
    final DateTime fin = ini.add(Duration(minutes: between(10, 40)));
    final List<List<String>> dx = <List<String>>[
      for (int i = 0; i < between(0, 2); i++)
        pick(_diagnosticos, _diagnosticosPrueba),
    ];
    return <String, dynamic>{
      'encounterIdentifier': uuid(),
      'type': 'Consultation',
      'startDateTime': isoWithOffset(ini),
      if (p(0.8)) 'endDateTime': isoWithOffset(fin),
      'careModality': '01',
      'serviceGroup': pick(<String>['01', '01', '02']),
      'careEnvironment': pick(<String>['05', '05', '01']),
      if (p(0.6))
        'provider': () {
          final List<String> pr = pick(_prestadores);
          return <String, dynamic>{'repsCode': pr[0], 'name': pr[1]};
        }(),
      if (p(0.9))
        'practitioner': <String, dynamic>{
          'documentType': 'CC',
          'documentNumber': digits(between(8, 10)),
          'name': pick(_profesionales),
        },
      'clinicalEvaluation': <String, dynamic>{
        'historyOfCurrentIllness': p(0.95) ? enfermedadActual() : null,
        'generalPhysicalExamination': p(0.9) ? examenFisico(peso) : null,
        if (p(0.5)) 'systemsExamination': sistemas(),
        'treatmentPlanObservations': p(0.9) ? plan() : null,
      },
      'diagnosis': <Map<String, dynamic>>[
        for (final List<String> d in dx)
          <String, dynamic>{
            'icd10Code': d[0],
            'description': d[1],
            'source': p(0.7) ? 'ai' : 'clinician',
            'model': 'gemini-3.8-flash',
            'generatedAt': isoWithOffset(fin),
          },
      ],
      'diagnosisType': '01',
      if (p(0.3)) 'dischargeDisposition': '01',
      'riskFactors': <dynamic>[],
      if (p(0.4)) 'payer': <String, dynamic>{'name': pick(_pagadores)},
      'prescriptions': <Map<String, dynamic>>[
        for (int i = 0; i < between(0, 2); i++)
          () {
            final List<String> m = pick(_medicamentos, _medicamentosPrueba);
            return <String, dynamic>{
              'medicationName': m[0],
              'dosage': m[1],
              'frequency': m[2],
              'duration': m[3],
              'route': m[4],
              'status': 'active',
              'intent': 'order',
            };
          }(),
      ],
    };
  }

  Map<String, dynamic> registro() {
    final DateTime hoy = DateTime(2026, 11, 1);
    final double u = r.nextDouble();
    final int edad = u < 0.65
        ? between(0, 5)
        : (u < 0.9 ? between(6, 17) : between(18, 40));
    final DateTime nac = day(
      DateTime(hoy.year - edad - 1, hoy.month, 1),
      DateTime(hoy.year - edad, hoy.month, 1),
    );
    final double peso = edad < 18
        ? 3.2 + edad * 2.6 + r.nextDouble() * 3
        : 50 + r.nextDouble() * 25;
    final List<String> ciudad = pick(_ciudades, _ciudadesPrueba);
    final String docTipo = pick(<String>[
      'RC',
      'RC',
      'TI',
      'PT',
      'PT',
      'PE',
      'MS',
      'MS',
      'PA',
      'CE',
      'CC',
    ]);
    final int nCons = between(0, 6);
    final int nVac = between(0, 10);
    final DateTime primera = day(DateTime(2026, 6, 1), DateTime(2026, 8, 1));

    Map<String, dynamic> acudiente({
      required bool conChip,
    }) => <String, dynamic>{
      'name':
          '${nombre()} ${p(0.4) ? '${nombre()} ' : ''}${apellido()} ${apellido()}',
      'relationship': pick(<String>['01', '01', '01', '02', '03', '04', '05']),
      'relationshipOther': '',
      'phone': p(0.7) ? '3${digits(9)}' : '+58 4${digits(9)}',
      if (conChip) 'device_uid': uid(),
      'documentType': pick(<String>['CC', 'PT', 'PE', 'PA', 'CE']),
      'documentNumber': digits(between(7, 10)),
      'consent': <String, dynamic>{
        'accepted': true,
        'acceptedAt': isoWithOffset(primera),
        if (p(0.3))
          'email': '${apellido().toLowerCase()}${between(1, 99)}@gmail.com',
        'signatureBase64': 'iVBORw0KGgoAAAANSUhEUgAA',
        'policyVersion': 'v1.1',
      },
    };

    return <String, dynamic>{
      'patientId': uuid(),
      'device_uid': uid(),
      'patientInfo': <String, dynamic>{
        'identification': <String, dynamic>{
          'documentType': docTipo,
          'documentNumber': docTipo == 'MS'
              ? 'MS${digits(8)}'
              : digits(between(7, 11)),
        },
        'firstLastName': apellido(),
        if (p(0.8)) 'secondLastName': apellido(),
        'firstName': nombre(),
        if (p(0.5)) 'secondName': nombre(),
        'dob': ymd(nac),
        'nationalityCode': pick(<String>['862', '862', '862', '170', '218']),
        if (p(0.5)) 'nationalityName': 'Venezuela',
        'biologicalSex': pick(<String>['M', 'F']),
        if (p(0.2)) 'ethnicity': pick(<String>['01', '05', '06']),
        'address': <String, dynamic>{
          if (p(0.4))
            'street':
                'Calle ${between(1, 40)} # ${between(1, 30)}-${between(1, 99)}',
          'city': ciudad[0],
          if (p(0.5)) 'cityCode': ciudad[2],
          'state': ciudad[1],
          'country': 'COL',
          if (p(0.5)) 'zone': pick(<String>['01', '02']),
        },
        if (p(0.5))
          'bloodType': pick(<String>['O+', 'O+', 'A+', 'B+', 'AB+', 'O-']),
        'isBloodTypeCertified': p(0.15),
        if (p(0.6)) 'weight': double.parse(peso.toStringAsFixed(1)),
        if (p(0.5))
          'height': double.parse(
            (50 + edad * 6.5 + r.nextDouble() * 5).toStringAsFixed(1),
          ),
      },
      'guardianInfo': acudiente(conChip: edad < 18 || p(0.2)),
      if (p(0.25)) 'guardian2Info': acudiente(conChip: p(0.6)),
      if (p(0.8))
        'backgroundHistory': <String, dynamic>{
          'chronicConditions': <Map<String, dynamic>>[
            for (int i = 0; i < (p(0.2) ? between(1, 2) : 0); i++)
              () {
                final List<String> c = pick(_cronicas);
                return <String, dynamic>{
                  'chronicDescription': c[0],
                  if (p(0.6)) 'chronicCie10Code': c[1],
                };
              }(),
          ],
          if (p(0.3))
            'personalHistory':
                'Nacido a término, parto ${pick(<String>['vaginal', 'por cesárea'])}, peso al nacer ${between(2400, 3900)} g.',
          'familyHistory': <Map<String, dynamic>>[
            for (int i = 0; i < (p(0.25) ? between(1, 2) : 0); i++)
              <String, dynamic>{
                'conditionDescription': pick(<String>[
                  'Hipertensión arterial',
                  'Diabetes mellitus tipo 2',
                  'Asma',
                  'Tuberculosis',
                ]),
                'relationship': pick(<String>['01', '02', '03', '04']),
                'conditionCodedDisplay': '',
              },
          ],
          'medications': <Map<String, dynamic>>[
            for (int i = 0; i < (p(0.15) ? 1 : 0); i++)
              <String, dynamic>{
                'medicationName': pick(_medicamentos)[0],
                'status': 'active',
                if (p(0.5)) 'dosage': '5 mL cada 24 horas',
              },
          ],
        },
      'allergies': <Map<String, dynamic>>[
        for (int i = 0; i < (p(0.25) ? between(1, 3) : 0); i++)
          () {
            final List<String> a = pick(_alergenos);
            return <String, dynamic>{
              'category': a[0],
              'allergen': a[1],
              if (p(0.7)) 'reaction': pick(_reacciones),
            };
          }(),
      ],
      'medicalHistory': <Map<String, dynamic>>[
        for (int i = 0; i < nCons; i++)
          consulta(primera.add(Duration(days: i * between(7, 30))), peso),
      ],
      'vaccinationRecord': <Map<String, dynamic>>[
        for (int i = 0; i < nVac; i++)
          () {
            final List<String> v = pick(_vacunas, _vacunasPrueba);
            return <String, dynamic>{
              'vaccinationId': uuid(),
              'date': ymd(nac.add(Duration(days: 30 * i + between(0, 20)))),
              'vaccineName': v[0],
              'vaccineCode': p(0.6) ? v[1] : '',
              'dose': between(1, 3),
              'administratedBy': pick(_vacunadores),
              'administratedAt': pick(_sitiosVacuna),
              'status': 'completed',
            };
          }(),
      ],
      'baseVersion': between(1, 20),
    };
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

dynamic deep(dynamic x) => jsonDecode(jsonEncode(x));

String hexOf(List<int> b) =>
    b.map((int x) => x.toRadixString(16).padLeft(2, '0')).join();

Uint8List cborOf(Map<String, dynamic> m) =>
    Uint8List.fromList(cbor.cborEncode(cbor.CborValue(m)));

/// What the app reconstructs when it reads a guardian device.
String reconGuardian(Map<String, dynamic> full) => jsonEncode(
  PatientFullRecord.fromJson(deep(full) as Map<String, dynamic>).toJson(),
);

/// What the app reconstructs when it reads a patient device.
String reconTriage(Map<String, dynamic> m) {
  final TriageSummary t = NfcTriagePayload.fromPayload(
    deep(m) as Map<String, dynamic>,
  );
  return jsonEncode(<Object?>[
    t.firstName,
    t.lastName,
    t.dob,
    t.biologicalSex,
    t.bloodType,
    t.documentType,
    t.documentNumber,
    t.guardianPhone,
    t.guardianDeviceUid,
    t.guardian2DeviceUid,
    t.chronicConditions,
    <Object>[
      for (final TriageAllergy a in t.allergies)
        <String>[a.category, a.allergen, a.reaction],
    ],
    t.vidaCode,
  ]);
}

/// Removes every key whose absence leaves the reconstruction identical,
/// leaves first, keeping the order of the keys that stay. Also returns the
/// removed paths, so the bench can count them.
Map<String, dynamic> stripRedundant(
  Map<String, dynamic> original,
  String Function(Map<String, dynamic>) recon,
  List<String> removed,
) {
  final Map<String, dynamic> root = deep(original) as Map<String, dynamic>;
  final String ref = recon(root);

  void visit(dynamic node, String path) {
    if (node is Map<String, dynamic>) {
      for (final String k in node.keys.toList()) {
        visit(node[k], '$path/$k');
      }
      for (final String k in node.keys.toList()) {
        final List<MapEntry<String, dynamic>> before = node.entries.toList();
        node.remove(k);
        if (recon(root) != ref) {
          node
            ..clear()
            ..addEntries(before);
        } else {
          removed.add('$path/$k');
        }
      }
    } else if (node is List) {
      for (int i = 0; i < node.length; i++) {
        visit(node[i], '$path[]');
      }
    }
  }

  visit(root, '');
  return root;
}

void main() {
  test(
    'NFC compression audit: synthetic corpus',
    () async {
      final NfcPayloadCodec codec = NfcPayloadCodec.fromKeyring(
        keyring: NfcKeyring.single(kKey),
      );
      final int budget215 = guardianPayloadBudget(492);
      final int budget216 = guardianPayloadBudget(872);
      final IOSink out = File('${kOut!}/corpus.jsonl').openWrite();
      int failures = 0;

      for (final (String split, int seed, int n) in <(String, int, int)>[
        ('train', 1, 400),
        ('test', 2, 200),
      ]) {
        final Gen g = Gen(seed, test: split == 'test');
        for (int i = 0; i < n; i++) {
          final Map<String, dynamic> raw = g.registro();
          final PatientFullRecord rec = PatientFullRecord.fromJson(
            deep(raw) as Map<String, dynamic>,
          );

          final Map<String, dynamic> triage =
              deep(NfcTriagePayload.buildPatientPayload(record: rec))
                  as Map<String, dynamic>;
          final List<String> quitTri = <String>[];
          final Map<String, dynamic> triageStrip = stripRedundant(
            triage,
            reconTriage,
            quitTri,
          );

          final List<Map<String, dynamic>> gs = <Map<String, dynamic>>[];
          for (int k = 0; k <= 3; k++) {
            final Map<String, dynamic> full =
                deep(
                      NfcGuardianPayload.buildGuardianPayload(
                        record: rec,
                        maxConsultations: k,
                        maxVaccines: k,
                      ),
                    )
                    as Map<String, dynamic>;
            final Map<String, dynamic> aliased = aliasGuardianPayload(full);
            final List<String> quit = <String>[];
            final Map<String, dynamic> strip = stripRedundant(
              full,
              reconGuardian,
              quit,
            );
            // Independent check: what was removed does not change what is read.
            if (reconGuardian(strip) != reconGuardian(full)) failures++;
            final String viaAlias = reconGuardian(
              unaliasGuardianPayload(aliasGuardianPayload(strip)),
            );
            if (viaAlias != reconGuardian(full)) failures++;
            gs.add(<String, dynamic>{
              'k': k,
              'full': full,
              'strip': strip,
              'removed': quit,
              'dart_cbor_alias': hexOf(cborOf(aliased)),
              'dart_est': codec.estimateSize(aliased),
              'dart_enc_len': (await codec.encode(aliased)).length,
            });
          }

          GuardianPayloadFit fit(int b) =>
              NfcGuardianPayload.buildWithinCapacity(
                record: rec,
                capacityBytes: b,
                estimateSize: codec.estimateSize,
              );
          final GuardianPayloadFit f215 = fit(budget215);
          final GuardianPayloadFit f216 = fit(budget216);

          out.writeln(
            jsonEncode(<String, dynamic>{
              'split': split,
              'id': '$split-$i',
              'nCons': rec.medicalHistory.length,
              'nVac': rec.vaccinationRecord.length,
              'triage': triage,
              'triage_strip': triageStrip,
              'triage_removed': quitTri,
              'dart_cbor_triage': hexOf(cborOf(triage)),
              'dart_triage_enc_len': (await codec.encode(triage)).length,
              'g': gs,
              'fit_now': <String, dynamic>{
                '215': <int>[
                  f215.includedConsultations,
                  f215.includedVaccines,
                  f215.estimatedBytes,
                  f215.fits ? 1 : 0,
                ],
                '216': <int>[
                  f216.includedConsultations,
                  f216.includedVaccines,
                  f216.estimatedBytes,
                  f216.fits ? 1 : 0,
                ],
              },
            }),
          );
        }
      }
      await out.close();
      File('${kOut!}/meta.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'budget215': budget215,
          'budget216': budget216,
          'ndef_overhead_triage_sr':
              NdefMessage(
                records: [
                  NfcPayloadService.buildMimeRecord(
                    kHwbNdefMimeType,
                    Uint8List(100),
                  ),
                ],
              ).byteLength -
              100,
          'ndef_overhead_triage_lr':
              NdefMessage(
                records: [
                  NfcPayloadService.buildMimeRecord(
                    kHwbNdefMimeType,
                    Uint8List(300),
                  ),
                ],
              ).byteLength -
              300,
          'ndef_overhead_guardian_sr':
              NdefMessage(
                records: [
                  NfcPayloadService.buildMimeRecord(
                    kHwbGuardianMimeType,
                    Uint8List(100),
                  ),
                ],
              ).byteLength -
              100,
          'ndef_overhead_guardian_lr':
              NdefMessage(
                records: [
                  NfcPayloadService.buildMimeRecord(
                    kHwbGuardianMimeType,
                    Uint8List(300),
                  ),
                ],
              ).byteLength -
              300,
          'ndef_overhead_ext8_sr':
              NdefMessage(
                records: [
                  NdefRecord(
                    typeNameFormat: TypeNameFormat.external,
                    type: Uint8List.fromList(ascii.encode('hwb.co:t')),
                    identifier: Uint8List(0),
                    payload: Uint8List(100),
                  ),
                ],
              ).byteLength -
              100,
          'ndef_overhead_ext8_lr':
              NdefMessage(
                records: [
                  NdefRecord(
                    typeNameFormat: TypeNameFormat.external,
                    type: Uint8List.fromList(ascii.encode('hwb.co:t')),
                    identifier: Uint8List(0),
                    payload: Uint8List(300),
                  ),
                ],
              ).byteLength -
              300,
          'reconstruction_failures': failures,
        }),
      );
      expect(failures, 0);
    },
    skip: kOut == null || kOut!.isEmpty
        ? 'Set HWB_AUDIT_OUT to the output directory.'
        : false,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
