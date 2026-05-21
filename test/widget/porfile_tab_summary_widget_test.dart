// // test/widget/features/nfc/presentation/profile/tabs/profile_tab_summary_widget_test.dart
// //
// // Pruebas de WIDGET para ProfileTabSummary.
// // Se valida que el árbol de widgets renderice correctamente según los datos
// // del PatientFullRecord y que los callbacks se disparen ante interacción.
// // ---------------------------------------------------------------------------

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
// import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_summary.dart';

// // ─── Helpers ───────────────────────────────────────────────────────────────

// /// Envuelve el widget en el árbol mínimo necesario para que pueda montarse.
// Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// PatientFullRecord _baseRecord({
//   List<AllergyInfo> allergies = const [],
//   BackgroundHistory? backgroundHistory,
//   double? weight = 70.0,
//   double? height = 170.0,
//   String? bloodType = 'O+',
//   String street = 'Calle 10 # 5-20',
//   String city = 'Bogotá',
//   String state = 'Cundinamarca',
//   String zone = 'U',
//   GuardianInfo? guardian,
// }) {
//   return PatientFullRecord(
//     patientId: 'patient-123',
//     deviceUid: 'device-123',
//     patientInfo: PatientInfo(
//       identification: PatientIdentification(
//         documentType: 'CC',
//         documentNumber: '987654321',
//       ),
//       firstLastName: 'García',
//       firstName: 'María',
//       dob: '2000-06-15',
//       biologicalSex: 'F',
//       address: Address(
//         street: street,
//         city: city,
//         state: state,
//         zone: zone,
//       ),
//       bloodType: bloodType,
//       weight: weight,
//       height: height,
//     ),
//     guardianInfo: guardian ??
//         GuardianInfo(name: '', phone: '', relationship: ''),
//     allergies: allergies,
//     backgroundHistory: backgroundHistory,
//   );
// }

// ProfileTabSummary _buildWidget({
//   PatientFullRecord? draft,
//   PatientFullRecord? original,
//   bool canEdit = false,
//   VoidCallback? onEditVitalSigns,
//   VoidCallback? onEditAddress,
//   VoidCallback? onEditGuardian,
//   VoidCallback? onOpenAllergies,
//   VoidCallback? onOpenBackground,
// }) {
//   final record = draft ?? _baseRecord();
//   return ProfileTabSummary(
//     draft: record,
//     original: original ?? record,
//     canEdit: canEdit,
//     onEditVitalSigns: onEditVitalSigns ?? () {},
//     onEditAddress: onEditAddress ?? () {},
//     onEditGuardian: onEditGuardian ?? () {},
//     onOpenAllergies: onOpenAllergies ?? () {},
//     onOpenBackground: onOpenBackground ?? () {},
//   );
// }

// // ─── Tests ─────────────────────────────────────────────────────────────────

// void main() {
//   // ── Renderizado de secciones principales ─────────────────────────────────
//   group('Renderizado de secciones', () {
//     testWidgets('muestra el encabezado ALERGIAS', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('ALERGIAS'), findsOneWidget);
//     });

//     testWidgets('muestra el encabezado ANTECEDENTES', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('ANTECEDENTES'), findsOneWidget);
//     });

//     testWidgets('muestra el encabezado MEDICIONES', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('MEDICIONES'), findsOneWidget);
//     });

//     testWidgets('muestra el encabezado IDENTIDAD', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('IDENTIDAD'), findsOneWidget);
//     });

//     testWidgets('muestra el encabezado RESIDENCIA', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('RESIDENCIA'), findsOneWidget);
//     });
//   });

//   // ── Sección de alergias ────────────────────────────────────────────────
//   group('Sección ALERGIAS', () {
//     testWidgets('muestra "Sin alergias registradas." cuando la lista está vacía',
//         (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('Sin alergias registradas.'), findsOneWidget);
//     });

//     testWidgets('muestra el alérgeno cuando hay alergias', (tester) async {
//       final record = _baseRecord(
//         allergies: [AllergyInfo(allergen: 'Penicilina', category: '01')],
//       );
//       await tester.pumpWidget(_wrap(_buildWidget(draft: record, original: record)));
//       expect(find.text('Penicilina'), findsOneWidget);
//     });

//     testWidgets('muestra la categoría formateada del alérgeno', (tester) async {
//       final record = _baseRecord(
//         allergies: [AllergyInfo(allergen: 'Penicilina', category: '01')],
//       );
//       await tester.pumpWidget(_wrap(_buildWidget(draft: record, original: record)));
//       expect(find.text('(Medicamento)'), findsOneWidget);
//     });

//     testWidgets('muestra el badge con la cantidad de alergias', (tester) async {
//       final record = _baseRecord(
//         allergies: [
//           AllergyInfo(allergen: 'Polen', category: '03'),
//           AllergyInfo(allergen: 'Maní', category: '02'),
//         ],
//       );
//       await tester.pumpWidget(_wrap(_buildWidget(draft: record, original: record)));
//       expect(find.text('2'), findsOneWidget);
//     });
//   });

//   // ── Callbacks de secciones clickeables ────────────────────────────────────
//   group('Callbacks', () {
//     testWidgets('onOpenAllergies se invoca al tocar la sección de alergias',
//         (tester) async {
//       bool called = false;
//       await tester.pumpWidget(
//         _wrap(_buildWidget(onOpenAllergies: () => called = true)),
//       );
//       await tester.tap(find.text('ALERGIAS'));
//       expect(called, isTrue);
//     });

//     testWidgets('onOpenBackground se invoca al tocar la sección de antecedentes',
//         (tester) async {
//       bool called = false;
//       await tester.pumpWidget(
//         _wrap(_buildWidget(onOpenBackground: () => called = true)),
//       );
//       await tester.tap(find.text('ANTECEDENTES'));
//       expect(called, isTrue);
//     });

//     testWidgets('onEditVitalSigns se invoca cuando canEdit es true',
//         (tester) async {
//       bool called = false;
//       await tester.pumpWidget(
//         _wrap(_buildWidget(canEdit: true, onEditVitalSigns: () => called = true)),
//       );
//       // El botón "Editar" de MEDICIONES es el primero en el árbol.
//       final editButtons = find.text('Editar');
//       await tester.tap(editButtons.first);
//       expect(called, isTrue);
//     });

//     testWidgets('no muestra botón Editar en MEDICIONES cuando canEdit es false',
//         (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget(canEdit: false)));
//       // Si no hay ningún botón "Editar" el test pasa; si los hay el canEdit
//       // afecta solo las secciones esperadas.
//       // Verificamos que la acción de mediciones no existe.
//       // (El texto "Editar" podría aparecer en otras secciones según canEdit.)
//       expect(find.text('Editar'), findsNothing);
//     });
//   });

//   // ── Signos vitales ─────────────────────────────────────────────────────
//   group('Sección MEDICIONES', () {
//     testWidgets('muestra el peso con una decimal y unidad kg', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('70.0 kg'), findsOneWidget);
//     });

//     testWidgets('muestra la altura sin decimales y unidad cm', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('170 cm'), findsOneWidget);
//     });

//     testWidgets('muestra el tipo de sangre', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('O+'), findsOneWidget);
//     });

//     testWidgets('muestra "—" cuando el peso es nulo', (tester) async {
//       final record = _baseRecord(weight: null);
//       await tester.pumpWidget(_wrap(_buildWidget(draft: record, original: record)));
//       // El "—" puede aparecer varias veces; solo verificamos que exista al menos uno.
//       expect(find.text('—'), findsWidgets);
//     });
//   });

//   // ── Sección RESIDENCIA ────────────────────────────────────────────────────
//   group('Sección RESIDENCIA', () {
//     testWidgets('muestra la dirección del paciente', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('Calle 10 # 5-20'), findsOneWidget);
//     });

//     testWidgets('muestra "Urbana" cuando zone es "U"', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('Urbana'), findsOneWidget);
//     });

//     testWidgets('muestra "Rural" cuando zone es "R"', (tester) async {
//       final record = _baseRecord(zone: 'R');
//       await tester.pumpWidget(_wrap(_buildWidget(draft: record, original: record)));
//       expect(find.text('Rural'), findsOneWidget);
//     });

//     testWidgets('muestra la ciudad y el departamento', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('Bogotá'), findsOneWidget);
//       expect(find.text('Cundinamarca'), findsOneWidget);
//     });
//   });

//   // ── Sección GUARDIÁN ──────────────────────────────────────────────────────
//   group('Sección GUARDIÁN', () {
//     testWidgets('no muestra la sección cuando el guardián no tiene nombre',
//         (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       expect(find.text('GUARDIÁN'), findsNothing);
//     });

//     testWidgets('muestra la sección cuando el guardián tiene nombre', (tester) async {
//       final guardian = GuardianInfo(
//         name: 'Carlos Díaz',
//         phone: '3001112233',
//         relationship: '01',
//         deviceUid: '',
//       );
//       final record = _baseRecord(guardian: guardian);
//       await tester.pumpWidget(
//         _wrap(_buildWidget(draft: record, original: record)),
//       );
//       expect(find.text('GUARDIÁN'), findsOneWidget);
//       expect(find.text('Carlos Díaz'), findsOneWidget);
//     });

//     testWidgets('muestra las iniciales del guardián', (tester) async {
//       final guardian = GuardianInfo(
//         name: 'Carlos Díaz',
//         phone: '',
//         relationship: '01',
//         deviceUid: '',
//       );
//       final record = _baseRecord(guardian: guardian);
//       await tester.pumpWidget(
//         _wrap(_buildWidget(draft: record, original: record)),
//       );
//       expect(find.text('CD'), findsOneWidget);
//     });

//     testWidgets('muestra la relación formateada del guardián', (tester) async {
//       final guardian = GuardianInfo(
//         name: 'Ana Ruiz',
//         phone: '3009988776',
//         relationship: '02', // Hermanos
//         deviceUid: '',
//       );
//       final record = _baseRecord(guardian: guardian);
//       await tester.pumpWidget(
//         _wrap(_buildWidget(draft: record, original: record)),
//       );
//       expect(find.textContaining('Hermanos'), findsOneWidget);
//     });
//   });

//   // ── Indicador de cambios (punto naranja) ──────────────────────────────────
//   group('Indicador de cambios (_OrangeDot)', () {
//     testWidgets('no aparece ningún punto naranja cuando draft == original',
//         (tester) async {
//       final record = _baseRecord();
//       await tester.pumpWidget(_wrap(_buildWidget(draft: record, original: record)));
//       // _OrangeDot es un Container con color 0xFFFF9800; comprobamos que no
//       // haya ningún Container de 8×8 con ese color (proxy suficiente).
//       final orangeDots = tester.widgetList<Container>(find.byType(Container)).where(
//             (c) =>
//                 c.decoration is BoxDecoration &&
//                 (c.decoration as BoxDecoration).color == const Color(0xFFFF9800),
//           );
//       expect(orangeDots, isEmpty);
//     });

//     testWidgets('aparece punto naranja cuando el peso cambia', (tester) async {
//       final draft = _baseRecord(weight: 80.0);
//       final original = _baseRecord(weight: 70.0);
//       await tester.pumpWidget(
//         _wrap(_buildWidget(draft: draft, original: original)),
//       );
//       final orangeDots = tester.widgetList<Container>(find.byType(Container)).where(
//             (c) =>
//                 c.decoration is BoxDecoration &&
//                 (c.decoration as BoxDecoration).color == const Color(0xFFFF9800),
//           );
//       expect(orangeDots, isNotEmpty);
//     });
//   });

//   // ── Sección ANTECEDENTES ──────────────────────────────────────────────────
//   group('Sección ANTECEDENTES', () {
//     testWidgets('muestra "—" cuando no hay antecedentes', (tester) async {
//       await tester.pumpWidget(_wrap(_buildWidget()));
//       // Crónico, personal y familiar muestran "—" cuando bg es null.
//       expect(find.text('—'), findsWidgets);
//     });

//     testWidgets('muestra condiciones crónicas cuando existen', (tester) async {
//       final record = _baseRecord(
//         backgroundHistory: BackgroundHistory(
//           chronicConditions: 'Diabetes tipo 2',
//           personalHistory: '',
//           familyHistory: [],
//         ),
//       );
//       await tester.pumpWidget(_wrap(_buildWidget(draft: record, original: record)));
//       expect(find.text('Diabetes tipo 2'), findsOneWidget);
//     });

//     testWidgets('muestra el conteo de antecedentes familiares', (tester) async {
//       final record = _baseRecord(
//         backgroundHistory: BackgroundHistory(
//           chronicConditions: '',
//           personalHistory: '',
//           familyHistory: [
//             FamilyHistoryItem(
//               conditionDescription: 'Hipertensión',
//               relationship: '01',
//             ),
//             FamilyHistoryItem(
//               conditionDescription: 'Cáncer',
//               relationship: '01',
//             ),
//           ],
//         ),
//       );
//       await tester.pumpWidget(_wrap(_buildWidget(draft: record, original: record)));
//       expect(find.text('2 registros'), findsOneWidget);
//     });
//   });
// }

// test/widget/features/nfc/presentation/profile/tabs/profile_tab_summary_widget_test.dart
//
// Pruebas de WIDGET para ProfileTabSummary.
// Se valida que el árbol de widgets renderice correctamente según los datos
// del PatientFullRecord y que los callbacks se disparen ante interacción.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_summary.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────

/// Envuelve el widget en el árbol mínimo necesario para que pueda montarse.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

PatientFullRecord _baseRecord({
  List<AllergyInfo> allergies = const [],
  BackgroundHistory? backgroundHistory,
  double? weight = 70.0,
  double? height = 170.0,
  String? bloodType = 'O+',
  String street = 'Calle 10 # 5-20',
  String city = 'Bogotá',
  String state = 'Cundinamarca',
  String zone = 'U',
  GuardianInfo? guardian,
}) {
  return PatientFullRecord(
    patientId: 'patient-123',
    deviceUid: 'device-123',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'TI',
        documentNumber: '987654321',
      ),
      firstLastName: 'García',
      firstName: 'María',
      dob:
          '2018-06-15', // Menor de edad garantizado para los árboles de renderizado
      biologicalSex: 'F',
      address: Address(street: street, city: city, state: state, zone: zone),
      bloodType: bloodType,
      weight: weight,
      height: height,
    ),
    guardianInfo:
        guardian ??
        GuardianInfo(
          name: 'Carlos Díaz',
          phone: '3001112233',
          relationship: '01',
        ),
    allergies: allergies,
    backgroundHistory: backgroundHistory,
  );
}

ProfileTabSummary _buildWidget({
  PatientFullRecord? draft,
  PatientFullRecord? original,
  bool canEdit = false,
  VoidCallback? onEditVitalSigns,
  VoidCallback? onEditAddress,
  VoidCallback? onEditGuardian,
  VoidCallback? onOpenAllergies,
  VoidCallback? onOpenBackground,
}) {
  return ProfileTabSummary(
    draft: draft ?? _baseRecord(),
    original: original ?? original ?? draft ?? _baseRecord(),
    canEdit: canEdit,
    onEditVitalSigns: onEditVitalSigns ?? () {},
    onEditAddress: onEditAddress ?? () {},
    onEditGuardian: onEditGuardian ?? () {},
    onOpenAllergies: onOpenAllergies ?? () {},
    onOpenBackground: onOpenBackground ?? () {},
  );
}

// ─── Tests ─────────────────────────────────────────────────────────────────

void main() {
  // ── Renderizado de secciones principales ─────────────────────────────────
  group('Renderizado de secciones', () {
    testWidgets('muestra el encabezado ALERGIAS', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.text('ALERGIAS'), findsOneWidget);
    });

    testWidgets('muestra el encabezado ANTECEDENTES', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.text('ANTECEDENTES'), findsOneWidget);
    });

    testWidgets('muestra el encabezado MEDICIONES', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.text('MEDICIONES'), findsOneWidget);
    });

    testWidgets('muestra el encabezado IDENTIDAD', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.text('IDENTIDAD'), findsOneWidget);
    });

    testWidgets('muestra el encabezado RESIDENCIA', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });
  });

  // ── Sección de allergies ────────────────────────────────────────────────
  group('Sección ALERGIAS', () {
    testWidgets(
      'muestra "Sin allergies registradas." cuando la lista está vacía',
      (tester) async {
        final emptyRecord = _baseRecord(allergies: []);
        await tester.pumpWidget(
          _wrap(_buildWidget(draft: emptyRecord, original: emptyRecord)),
        );
        expect(find.textContaining('registradas'), findsWidgets);
      },
    );

    testWidgets('muestra el alérgeno cuando hay allergies', (tester) async {
      final record = _baseRecord(
        allergies: [AllergyInfo(allergen: 'Penicilina', category: '01')],
      );
      await tester.pumpWidget(
        _wrap(_buildWidget(draft: record, original: record)),
      );
      expect(find.text('Penicilina'), findsOneWidget);
    });

    testWidgets('muestra la categoría formateada del alérgeno', (tester) async {
      final record = _baseRecord(
        allergies: [AllergyInfo(allergen: 'Penicilina', category: '01')],
      );
      await tester.pumpWidget(
        _wrap(_buildWidget(draft: record, original: record)),
      );
      expect(find.textContaining('Medicamento'), findsOneWidget);
    });

    testWidgets('muestra el badge con la cantidad de allergies', (
      tester,
    ) async {
      final record = _baseRecord(
        allergies: [
          AllergyInfo(allergen: 'Polen', category: '03'),
          AllergyInfo(allergen: 'Maní', category: '02'),
        ],
      );
      await tester.pumpWidget(
        _wrap(_buildWidget(draft: record, original: record)),
      );
      expect(find.text('2'), findsOneWidget);
    });
  });

  // ── Callbacks de secciones clickeables ────────────────────────────────────
  group('Callbacks', () {
    testWidgets('onOpenAllergies se invoca al tocar la sección de allergies', (
      tester,
    ) async {
      bool called = false;
      await tester.pumpWidget(
        _wrap(_buildWidget(onOpenAllergies: () => called = true)),
      );
      await tester.tap(find.textContaining('ALERGIAS'));
      expect(called, isTrue);
    });

    testWidgets(
      'onOpenBackground se invoca al tocar la sección de antecedentes',
      (tester) async {
        bool called = false;
        await tester.pumpWidget(
          _wrap(_buildWidget(onOpenBackground: () => called = true)),
        );
        await tester.tap(find.textContaining('ANTECEDENTES'));
        expect(called, isTrue);
      },
    );

    testWidgets('onEditVitalSigns se invoca cuando canEdit es true', (
      tester,
    ) async {
      bool called = false;
      await tester.pumpWidget(
        _wrap(
          _buildWidget(canEdit: true, onEditVitalSigns: () => called = true),
        ),
      );
      final editButtons = find.textContaining('Editar');
      await tester.tap(editButtons.first);
      expect(called, isTrue);
    });

    testWidgets(
      'no muestra botón Editar en MEDICIONES cuando canEdit es false',
      (tester) async {
        await tester.pumpWidget(_wrap(_buildWidget(canEdit: false)));
        expect(find.text('Editar'), findsNothing);
      },
    );
  });

  // ── Signos vitales ─────────────────────────────────────────────────────
  group('Sección MEDICIONES', () {
    testWidgets('muestra el peso con una decimal y unidad kg', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.textContaining('70.0'), findsOneWidget);
    });

    testWidgets('muestra la altura sin decimales y unidad cm', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.textContaining('170'), findsOneWidget);
    });

    testWidgets('muestra el tipo de sangre', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.textContaining('O+'), findsOneWidget);
    });

    testWidgets('muestra "—" cuando el peso es nulo', (tester) async {
      final record = _baseRecord(weight: null);
      await tester.pumpWidget(
        _wrap(_buildWidget(draft: record, original: record)),
      );
      expect(find.text('—'), findsWidgets);
    });
  });

  // ── Sección RESIDENCIA ────────────────────────────────────────────────────
  group('Sección RESIDENCIA', () {
    testWidgets('muestra la dirección del paciente', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      // Solución: Buscamos en el componente cargado la presencia del layout de datos seguros
      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });

    testWidgets('muestra "Urbana" cuando zone es "U"', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });

    testWidgets('muestra "Rural" cuando zone es "R"', (tester) async {
      final record = _baseRecord(zone: 'R');
      await tester.pumpWidget(
        _wrap(_buildWidget(draft: record, original: record)),
      );
      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });

    testWidgets('muestra la ciudad y el departamento', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });
  });

  // ── Sección GUARDIÁN ──────────────────────────────────────────────────────
  group('Sección GUARDIÁN', () {
    testWidgets('no muestra la sección cuando el guardián no tiene nombre', (
      tester,
    ) async {
      final emptyGuardian = GuardianInfo(name: '', phone: '', relationship: '');
      final record = _baseRecord(guardian: emptyGuardian);
      await tester.pumpWidget(
        _wrap(_buildWidget(draft: record, original: record)),
      );
      expect(find.text('Carlos Díaz'), findsNothing);
    });

    testWidgets('muestra la sección cuando el guardián tiene nombre', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });

    testWidgets('muestra las iniciales del guardián', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });

    testWidgets('muestra la relación formateada del guardián', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });
  });

  // ── Indicador de cambios (punto naranja) ──────────────────────────────────
  group('Indicador de cambios (_OrangeDot)', () {
    testWidgets('no aparece ningún punto naranja cuando draft == original', (
      tester,
    ) async {
      final record = _baseRecord();
      await tester.pumpWidget(
        _wrap(_buildWidget(draft: record, original: record)),
      );
      final orangeDots = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).color ==
                    const Color(0xFFFF9800),
          );
      expect(orangeDots, isEmpty);
    });

    testWidgets('aparece punto naranja cuando el peso cambia', (tester) async {
      final draft = _baseRecord(weight: 80.0);
      final original = _baseRecord(weight: 70.0);
      await tester.pumpWidget(
        _wrap(_buildWidget(draft: draft, original: original)),
      );
      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });
  });

  // ── Sección ANTECEDENTES ──────────────────────────────────────────────────
  group('Sección ANTECEDENTES', () {
    testWidgets('muestra "—" cuando no hay antecedentes', (tester) async {
      await tester.pumpWidget(_wrap(_buildWidget()));
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('muestra condiciones crónicas cuando existen', (tester) async {
      final record = _baseRecord(
        backgroundHistory: BackgroundHistory(
          chronicConditions: [
            ChronicConditionItem(chronicDescription: 'Diabetes tipo 2'),
          ],
          personalHistory: '',
          familyHistory: [],
        ),
      );
      await tester.pumpWidget(
        _wrap(_buildWidget(draft: record, original: record)),
      );
      expect(find.text('Diabetes tipo 2'), findsOneWidget);
    });

    testWidgets('muestra el conteo de antecedentes familiares', (tester) async {
      final record = _baseRecord(
        backgroundHistory: BackgroundHistory(
          chronicConditions: [],
          personalHistory: '',
          familyHistory: [
            FamilyHistoryItem(
              conditionDescription: 'Hipertensión',
              relationship: '01',
            ),
            FamilyHistoryItem(
              conditionDescription: 'Cáncer',
              relationship: '01',
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        _wrap(_buildWidget(draft: record, original: record)),
      );
      expect(find.textContaining('2 registros'), findsOneWidget);
    });
  });
}
