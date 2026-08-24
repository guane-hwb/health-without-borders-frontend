// test/features/nfc/presentation/profile/tabs/profile_tab_background_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_background.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps the widget under test in the minimal boilerplate Flutter needs.
Widget _buildSubject({
  required PatientFullRecord draft,
  VoidCallback? onAddChronic,
  void Function(int)? onRemoveChronic,
  VoidCallback? onEditPersonal,
  VoidCallback? onAddFamilyHistory,
  void Function(int)? onRemoveFamilyHistory,
  VoidCallback? onAddMedication,
  void Function(int)? onRemoveMedication,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ProfileTabBackground(
        draft: draft,
        onAddChronic: onAddChronic ?? () {},
        onRemoveChronic: onRemoveChronic ?? (_) {},
        onEditPersonal: onEditPersonal ?? () {},
        onAddFamilyHistory: onAddFamilyHistory ?? () {},
        onRemoveFamilyHistory: onRemoveFamilyHistory ?? (_) {},
        onAddMedication: onAddMedication ?? () {},
        onRemoveMedication: onRemoveMedication ?? (_) {},
      ),
    ),
  );
}

/// Builds a [PatientFullRecord] with sensible defaults so each test only
/// overrides what it cares about.
PatientFullRecord _record({BackgroundHistory? backgroundHistory}) {
  return PatientFullRecord(
    patientId: 'patient-123',
    deviceUid: 'device-123',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '123456789',
      ),
      firstLastName: 'Test',
      firstName: 'Paciente',
      dob: '1990-01-01',
      biologicalSex: 'M',
      address: Address(city: 'Bogotá', state: 'Cundinamarca'),
    ),
    guardianInfo: GuardianInfo(name: '', relationship: '', phone: ''),
    backgroundHistory: backgroundHistory,
  );
}

// ---------------------------------------------------------------------------
// Unit tests – pure logic (_FamilyHistoryCard._relationshipLabel)
// ---------------------------------------------------------------------------

const _relationshipCases = <String, String>{
  '01': 'Padres',
  '02': 'Hermanos',
  '03': 'Tíos',
  '04': 'Abuelos',
  'XX': 'XX', // unknown code → returns the raw value
};

// ---------------------------------------------------------------------------
// Widget tests
// ---------------------------------------------------------------------------

void main() {
  // ── Unit: relationship label mapping ─────────────────────────────────────

  group('_relationshipLabel (unit)', () {
    for (final entry in _relationshipCases.entries) {
      testWidgets('code "${entry.key}" renders label "${entry.value}"', (
        tester,
      ) async {
        final record = _record(
          backgroundHistory: BackgroundHistory(
            familyHistory: [
              FamilyHistoryItem(
                relationship: entry.key,
                conditionDescription: 'Test condition',
                conditionCie10Code: null,
              ),
            ],
          ),
        );

        await tester.pumpWidget(_buildSubject(draft: record));

        expect(find.textContaining(entry.value), findsOneWidget);
      });
    }
  });

  // ── Widget: empty states ──────────────────────────────────────────────────

  group('Empty state messages', () {
    testWidgets('shows placeholder when chronicConditions is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(draft: _record(backgroundHistory: BackgroundHistory())),
      );

      expect(
        find.text('Sin condiciones crónicas registradas.'),
        findsOneWidget,
      );
    });

    testWidgets('shows placeholder when chronicConditions list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(chronicConditions: const []),
          ),
        ),
      );

      expect(
        find.text('Sin condiciones crónicas registradas.'),
        findsOneWidget,
      );
    });

    testWidgets('shows placeholder when personalHistory is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(draft: _record(backgroundHistory: BackgroundHistory())),
      );

      expect(find.text('Sin historial personal registrado.'), findsOneWidget);
    });

    testWidgets('shows placeholder when personalHistory is empty string', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(personalHistory: ''),
          ),
        ),
      );

      expect(find.text('Sin historial personal registrado.'), findsOneWidget);
    });

    testWidgets('shows placeholder when familyHistory list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(familyHistory: []),
          ),
        ),
      );

      expect(
        find.text('Sin antecedentes familiares registrados.'),
        findsOneWidget,
      );
    });

    testWidgets('shows placeholder when backgroundHistory is null', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(draft: _record()));

      expect(
        find.text('Sin condiciones crónicas registradas.'),
        findsOneWidget,
      );
      expect(find.text('Sin historial personal registrado.'), findsOneWidget);
      expect(
        find.text('Sin antecedentes familiares registrados.'),
        findsOneWidget,
      );
      expect(find.text('Sin medicamentos registrados.'), findsOneWidget);
    });

    testWidgets('shows placeholder when medications is empty', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(medications: const []),
          ),
        ),
      );

      expect(find.text('Sin medicamentos registrados.'), findsOneWidget);
    });
  });

  // ── Widget: populated states ──────────────────────────────────────────────

  group('Populated state', () {
    testWidgets('renders chronicConditions text when present', (tester) async {
      const value = 'Diabetes tipo 2, Hipertensión';
      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(
              chronicConditions: [
                ChronicConditionItem(chronicDescription: value),
              ],
            ),
          ),
        ),
      );

      expect(find.text(value), findsOneWidget);
      expect(find.text('Sin condiciones crónicas registradas.'), findsNothing);
    });

    testWidgets(
      'renders CIE-10 and CIE-11 in chronicConditions when both are present',
      (tester) async {
        await tester.pumpWidget(
          _buildSubject(
            draft: _record(
              backgroundHistory: BackgroundHistory(
                chronicConditions: [
                  ChronicConditionItem(
                    chronicDescription: 'Diabetes',
                    chronicCie10Code: 'E11',
                    chronicCie11Code: '5A11',
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.textContaining('CIE-10: E11'), findsOneWidget);
        expect(find.textContaining('CIE-11: 5A11'), findsOneWidget);
      },
    );

    testWidgets('renders personalHistory text when present', (tester) async {
      const value = 'Apendicectomía 2010';
      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(personalHistory: value),
          ),
        ),
      );

      expect(find.text(value), findsOneWidget);
      expect(find.text('Sin historial personal registrado.'), findsNothing);
    });

    testWidgets('renders one card per family-history item', (tester) async {
      final items = [
        FamilyHistoryItem(
          relationship: '01',
          conditionDescription: 'Hipertensión',
          conditionCie10Code: 'I10',
        ),
        FamilyHistoryItem(
          relationship: '02',
          conditionDescription: 'Asma',
          conditionCie10Code: null,
        ),
      ];

      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(familyHistory: items),
          ),
        ),
      );

      expect(find.text('Hipertensión'), findsOneWidget);
      expect(find.text('Asma'), findsOneWidget);
      expect(
        find.text('Sin antecedentes familiares registrados.'),
        findsNothing,
      );
    });

    testWidgets('shows CIE-10 code inline when provided', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(
              familyHistory: [
                FamilyHistoryItem(
                  relationship: '04',
                  conditionDescription: 'Cáncer de colon',
                  conditionCie10Code: 'C18',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining('CIE-10 C18'), findsOneWidget);
    });

    testWidgets('does NOT show CIE-10 segment when code is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(
              familyHistory: [
                FamilyHistoryItem(
                  relationship: '01',
                  conditionDescription: 'Diabetes',
                  conditionCie10Code: null,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining('CIE-10'), findsNothing);
    });
  });

  // ── Widget: Medications translation & formatting ──────────────────────────

  group('Medication translation & formatting', () {
    final statusTranslationCases = <String, String>{
      'active': 'Activo',
      'completed': 'Completado',
      'stopped': 'Suspendido',
      'unknown': 'Desconocido',
      'custom_status': 'custom_status', // unknown raw string fallback
    };

    for (final entry in statusTranslationCases.entries) {
      testWidgets(
        'status "${entry.key}" translates correctly to "${entry.value}"',
        (tester) async {
          await tester.pumpWidget(
            _buildSubject(
              draft: _record(
                backgroundHistory: BackgroundHistory(
                  medications: [
                    MedicationStatementItem(
                      medicationName: 'Metformina',
                      status: entry.key,
                    ),
                  ],
                ),
              ),
            ),
          );

          expect(find.textContaining(entry.value), findsOneWidget);
        },
      );
    }

    testWidgets('shows dosage alongside translated status when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(
              medications: [
                MedicationStatementItem(
                  medicationName: 'Losartán',
                  status: 'active',
                  dosage: '50mg cada 12 horas',
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.textContaining('Activo · 50mg cada 12 horas'),
        findsOneWidget,
      );
    });

    testWidgets('does not show dosage separator when dosage is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(
              medications: [
                MedicationStatementItem(
                  medicationName: 'Metformina',
                  status: 'active',
                  dosage: null,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining('Activo ·'), findsNothing);
    });
  });

  // ── Widget: section headers & icons ──────────────────────────────────────

  group('Section headers', () {
    testWidgets('renders CONDICIONES CRÓNICAS header', (tester) async {
      await tester.pumpWidget(_buildSubject(draft: _record()));

      expect(find.text('CONDICIONES CRÓNICAS'), findsOneWidget);
    });

    testWidgets('renders HISTORIAL PERSONAL header', (tester) async {
      await tester.pumpWidget(_buildSubject(draft: _record()));

      expect(find.text('HISTORIAL PERSONAL'), findsOneWidget);
    });

    testWidgets('renders ANTECEDENTES FAMILIARES header', (tester) async {
      await tester.pumpWidget(_buildSubject(draft: _record()));

      expect(find.text('ANTECEDENTES FAMILIARES'), findsOneWidget);
    });

    testWidgets('renders MEDICAMENTOS header', (tester) async {
      await tester.pumpWidget(_buildSubject(draft: _record()));

      expect(find.text('MEDICAMENTOS'), findsOneWidget);
    });
  });

  // ── Widget: callbacks ─────────────────────────────────────────────────────

  group('Callbacks', () {
    testWidgets('onAddChronic fires when Agregar (chronic) is tapped', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        _buildSubject(draft: _record(), onAddChronic: () => called = true),
      );

      final agregarButtons = find.text('Agregar');
      await tester.tap(agregarButtons.first);
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('onRemoveChronic fires when delete button is tapped', (
      tester,
    ) async {
      int? removedIndex;
      await tester.pumpWidget(
        _buildSubject(
          draft: _record(
            backgroundHistory: BackgroundHistory(
              chronicConditions: [
                ChronicConditionItem(chronicDescription: 'Asma'),
                ChronicConditionItem(chronicDescription: 'Diabetes'),
              ],
            ),
          ),
          onRemoveChronic: (i) => removedIndex = i,
        ),
      );

      final deleteButtons = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteButtons.at(1));
      await tester.pump();

      expect(removedIndex, equals(1));
    });

    testWidgets('onEditPersonal fires when Editar (personal) is tapped', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        _buildSubject(draft: _record(), onEditPersonal: () => called = true),
      );

      final editarButtons = find.text('Editar');
      await tester.tap(editarButtons.first);
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('onAddMedication fires when Agregar (medication) is tapped', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        _buildSubject(draft: _record(), onAddMedication: () => called = true),
      );

      final agregarButtons = find.text('Agregar');
      await tester.tap(agregarButtons.at(1));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets(
      'onRemoveMedication fires when medication delete button is tapped',
      (tester) async {
        int? removedIndex;
        await tester.pumpWidget(
          _buildSubject(
            draft: _record(
              backgroundHistory: BackgroundHistory(
                medications: [
                  MedicationStatementItem(
                    medicationName: 'Med A',
                    status: 'active',
                  ),
                  MedicationStatementItem(
                    medicationName: 'Med B',
                    status: 'completed',
                  ),
                ],
              ),
            ),
            onRemoveMedication: (i) => removedIndex = i,
          ),
        );

        final deleteButtons = find.byIcon(Icons.delete_outline);
        await tester.tap(deleteButtons.at(1));
        await tester.pump();

        expect(removedIndex, equals(1));
      },
    );

    testWidgets(
      'onAddFamilyHistory fires when Agregar (family history) is tapped',
      (tester) async {
        var called = false;
        await tester.pumpWidget(
          _buildSubject(
            draft: _record(),
            onAddFamilyHistory: () => called = true,
          ),
        );

        final agregarButtons = find.text('Agregar');
        await tester.tap(agregarButtons.at(2));
        await tester.pump();

        expect(called, isTrue);
      },
    );

    testWidgets(
      'onRemoveFamilyHistory fires with the correct index on delete tap',
      (tester) async {
        int? removedIndex;
        final items = [
          FamilyHistoryItem(
            relationship: '01',
            conditionDescription: 'Diabetes',
            conditionCie10Code: null,
          ),
          FamilyHistoryItem(
            relationship: '02',
            conditionDescription: 'Asma',
            conditionCie10Code: null,
          ),
        ];

        await tester.pumpWidget(
          _buildSubject(
            draft: _record(
              backgroundHistory: BackgroundHistory(familyHistory: items),
            ),
            onRemoveFamilyHistory: (i) => removedIndex = i,
          ),
        );

        final deleteButtons = find.byIcon(Icons.delete_outline);
        await tester.tap(deleteButtons.at(1));
        await tester.pump();

        expect(removedIndex, equals(1));
      },
    );
  });
}
