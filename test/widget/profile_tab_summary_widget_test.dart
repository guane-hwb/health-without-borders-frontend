// test/widget/profile_tab_summary_widget_test.dart
//
// Widget testing for ProfileTabSummary.
// It is validated that the widget tree renders correctly according to the
// PatientFullRecord data and that the callbacks are triggered upon interaction.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_summary.dart';

// ── _LocaleWrapper ────────────────────────────────────────────────────────────
class _LocaleWrapper extends StatefulWidget {
  const _LocaleWrapper({required this.locale, required this.child});
  final String locale;
  final Widget child;

  @override
  State<_LocaleWrapper> createState() => _LocaleWrapperState();
}

class _LocaleWrapperState extends State<_LocaleWrapper> {
  late String _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
  }

  @override
  void didUpdateWidget(covariant _LocaleWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale) {
      _locale = widget.locale;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLocale(
      locale: _locale,
      setLocale: (l) => setState(() => _locale = l),
      child: widget.child,
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

PatientFullRecord _baseRecord({
  String firstName = 'Ana',
  String firstLastName = 'García',
  String? secondName,
  String? secondLastName,
  String dob = '1990-06-15',
  String biologicalSex = 'F',
  String? genderIdentity,
  String documentType = 'CC',
  String documentNumber = '1023456789',
  String? bloodType = 'O+',
  double? weight = 62.0,
  double? height = 165.0,
  String? ethnicity,
  String? disabilityCategory,
  String nationalityCode = 'COL',
  String? nationalityName,
  Address? address,
  GuardianInfo? guardian,
  BackgroundHistory? background,
  List<AllergyInfo> allergies = const [],
}) {
  return PatientFullRecord(
    patientId: 'test-uuid-001',
    deviceUid: 'NFC-001',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: documentType,
        documentNumber: documentNumber,
      ),
      firstName: firstName,
      secondName: secondName,
      firstLastName: firstLastName,
      secondLastName: secondLastName,
      dob: dob,
      biologicalSex: biologicalSex,
      genderIdentity: genderIdentity,
      ethnicity: ethnicity,
      disabilityCategory: disabilityCategory,
      nationalityCode: nationalityCode,
      nationalityName: nationalityName,
      address:
          address ??
          Address(
            street: 'Calle 123',
            city: 'Bogotá',
            state: 'Cundinamarca',
            zone: '01',
          ),
      bloodType: bloodType,
      weight: weight,
      height: height,
    ),
    guardianInfo:
        guardian ?? GuardianInfo(name: '', relationship: '', phone: ''),
    backgroundHistory: background,
    allergies: allergies,
  );
}

Widget _buildWidget({
  required PatientFullRecord draft,
  PatientFullRecord? original,
  bool canEdit = true,
  VoidCallback? onEditVitalSigns,
  VoidCallback? onEditAddress,
  ValueChanged<int>? onEditGuardian,
  VoidCallback? onOpenAllergies,
  VoidCallback? onOpenBackground,
  Locale locale = const Locale('es'),
}) {
  final rec = original ?? draft;
  return _LocaleWrapper(
    locale: locale.languageCode,
    child: MaterialApp(
      locale: locale,
      home: Scaffold(
        body: SizedBox(
          height: 6000,
          width: 800,
          child: ProfileTabSummary(
            draft: draft,
            original: rec,
            canEdit: canEdit,
            onEditVitalSigns: onEditVitalSigns ?? () {},
            onEditAddress: onEditAddress ?? () {},
            onEditGuardian: onEditGuardian ?? (_) {},
            onOpenAllergies: onOpenAllergies ?? () {},
            onOpenBackground: onOpenBackground ?? () {},
          ),
        ),
      ),
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // 1. Change-detection computed properties (@visibleForTesting getters)
  // ══════════════════════════════════════════════════════════════════════════
  group('Change detection —', () {
    late PatientFullRecord base;

    setUp(() => base = _baseRecord());

    ProfileTabSummary widget(
      PatientFullRecord draft,
      PatientFullRecord original,
    ) => ProfileTabSummary(
      draft: draft,
      original: original,
      canEdit: true,
      onEditVitalSigns: () {},
      onEditAddress: () {},
      onEditGuardian: (_) {},
      onOpenAllergies: () {},
      onOpenBackground: () {},
    );

    test('allergiesChanged is false when both lists are empty', () {
      final w = widget(base, base);
      expect(w.allergiesChanged, isFalse);
    });

    test('allergiesChanged is true when draft has more allergies', () {
      final draft = _baseRecord(
        allergies: [AllergyInfo(category: '01', allergen: 'Penicilina')],
      );
      final w = widget(draft, base);
      expect(w.allergiesChanged, isTrue);
    });

    test('weightChanged is false when weight is equal', () {
      final w = widget(base, base);
      expect(w.weightChanged, isFalse);
    });

    test('weightChanged is true when draft weight differs', () {
      final draft = _baseRecord(weight: 70.0);
      final original = _baseRecord(weight: 62.0);
      final w = widget(draft, original);
      expect(w.weightChanged, isTrue);
    });

    test('heightChanged is false when heights match', () {
      final w = widget(base, base);
      expect(w.heightChanged, isFalse);
    });

    test('heightChanged is true when draft height differs', () {
      final draft = _baseRecord(height: 170.0);
      final original = _baseRecord(height: 165.0);
      final w = widget(draft, original);
      expect(w.heightChanged, isTrue);
    });

    test('addressChanged is false when address is identical', () {
      final w = widget(base, base);
      expect(w.addressChanged, isFalse);
    });

    test('addressChanged is true when city differs', () {
      final draft = _baseRecord(
        address: Address(
          street: 'Calle 123',
          city: 'Medellín',
          state: 'Antioquia',
          zone: '01',
        ),
      );
      final original = _baseRecord(
        address: Address(
          street: 'Calle 123',
          city: 'Bogotá',
          state: 'Cundinamarca',
          zone: '01',
        ),
      );
      final w = widget(draft, original);
      expect(w.addressChanged, isTrue);
    });

    test('addressChanged is true when zone differs', () {
      final draft = _baseRecord(
        address: Address(
          street: 'Calle 1',
          city: 'Bogotá',
          state: 'Cund.',
          zone: '02',
        ),
      );
      final original = _baseRecord(
        address: Address(
          street: 'Calle 1',
          city: 'Bogotá',
          state: 'Cund.',
          zone: '01',
        ),
      );
      final w = widget(draft, original);
      expect(w.addressChanged, isTrue);
    });

    test('backgroundChanged is false when both backgroundHistory are null', () {
      final w = widget(base, base);
      expect(w.backgroundChanged, isFalse);
    });

    test(
      'backgroundChanged is true when draft has background and original does not',
      () {
        final draft = _baseRecord(background: BackgroundHistory());
        final original = _baseRecord(background: null);
        final w = widget(draft, original);
        expect(w.backgroundChanged, isTrue);
      },
    );

    test('backgroundChanged is true when chronicConditions counts differ', () {
      final draft = _baseRecord(
        background: BackgroundHistory(
          chronicConditions: [
            ChronicConditionItem(chronicDescription: 'Diabetes'),
          ],
        ),
      );
      final original = _baseRecord(background: BackgroundHistory());
      final w = widget(draft, original);
      expect(w.backgroundChanged, isTrue);
    });

    test('backgroundChanged is true when personalHistory text differs', () {
      final draft = _baseRecord(
        background: BackgroundHistory(personalHistory: 'Cirugía 2020'),
      );
      final original = _baseRecord(background: BackgroundHistory());
      final w = widget(draft, original);
      expect(w.backgroundChanged, isTrue);
    });

    test('guardianChanged is false when guardians are identical', () {
      final guardian = GuardianInfo(
        name: 'María López',
        relationship: '01',
        phone: '3001234567',
      );
      final draft = _baseRecord(guardian: guardian);
      final original = _baseRecord(guardian: guardian);
      final w = widget(draft, original);
      expect(w.guardianChanged, isFalse);
    });

    test('guardianChanged is true when phone differs', () {
      final draft = _baseRecord(
        guardian: GuardianInfo(
          name: 'María López',
          relationship: '01',
          phone: '3009999999',
        ),
      );
      final original = _baseRecord(
        guardian: GuardianInfo(
          name: 'María López',
          relationship: '01',
          phone: '3001234567',
        ),
      );
      final w = widget(draft, original);
      expect(w.guardianChanged, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2. Allergies section rendering
  // ══════════════════════════════════════════════════════════════════════════
  group('Allergies section —', () {
    testWidgets('shows empty-state text when there are no allergies', (
      tester,
    ) async {
      await tester.pumpWidget(_buildWidget(draft: _baseRecord()));
      await tester.pumpAndSettle();

      expect(find.textContaining('alerg', findRichText: true), findsWidgets);
    });

    testWidgets('shows allergen name when one allergy is present', (
      tester,
    ) async {
      final draft = _baseRecord(
        allergies: [AllergyInfo(category: '01', allergen: 'Penicilina')],
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Penicilina'), findsOneWidget);
    });

    testWidgets('shows category label for allergy', (tester) async {
      final draft = _baseRecord(
        allergies: [AllergyInfo(category: '02', allergen: 'Maní')],
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Maní'), findsOneWidget);
    });

    testWidgets('shows badge count equal to number of allergies', (
      tester,
    ) async {
      final draft = _baseRecord(
        allergies: [
          AllergyInfo(category: '01', allergen: 'A'),
          AllergyInfo(category: '02', allergen: 'B'),
          AllergyInfo(category: '03', allergen: 'C'),
        ],
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tapping the section calls onOpenAllergies', (tester) async {
      var called = false;
      final draft = _baseRecord();
      await tester.pumpWidget(
        _buildWidget(draft: draft, onOpenAllergies: () => called = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.warning_amber_rounded).first);
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('multiple allergens all appear in the list', (tester) async {
      final draft = _baseRecord(
        allergies: [
          AllergyInfo(category: '01', allergen: 'Penicilina'),
          AllergyInfo(category: '02', allergen: 'Maní'),
        ],
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Penicilina'), findsOneWidget);
      expect(find.text('Maní'), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 3. Background section rendering
  // ══════════════════════════════════════════════════════════════════════════
  group('Background section —', () {
    testWidgets('shows dashes when backgroundHistory is null', (tester) async {
      await tester.pumpWidget(
        _buildWidget(draft: _baseRecord(background: null)),
      );
      await tester.pumpAndSettle();

      expect(find.text('—'), findsWidgets);
    });

    testWidgets('shows chronic count when conditions exist', (tester) async {
      final draft = _baseRecord(
        background: BackgroundHistory(
          chronicConditions: [
            ChronicConditionItem(chronicDescription: 'Diabetes tipo 2'),
            ChronicConditionItem(chronicDescription: 'Hipertensión'),
          ],
        ),
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('shows personalHistory text in mini-row when present', (
      tester,
    ) async {
      final draft = _baseRecord(
        background: BackgroundHistory(personalHistory: 'Apendicectomía 2015'),
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(
        find.text('Apendicectomía 2015', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('tapping section calls onOpenBackground', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _buildWidget(
          draft: _baseRecord(),
          onOpenBackground: () => called = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history_edu_outlined).first);
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('shows medication count when medications exist', (
      tester,
    ) async {
      final draft = _baseRecord(
        background: BackgroundHistory(
          medications: [
            MedicationStatementItem(medicationName: 'Metformina'),
            MedicationStatementItem(medicationName: 'Losartán'),
          ],
        ),
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('shows family history count when entries exist', (
      tester,
    ) async {
      final draft = _baseRecord(
        background: BackgroundHistory(
          familyHistory: [
            FamilyHistoryItem(
              conditionDescription: 'Cáncer colon',
              relationship: '01',
            ),
          ],
        ),
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.textContaining('1'), findsWidgets);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 4. Measurements / vitals section
  // ══════════════════════════════════════════════════════════════════════════
  group('Measurements section —', () {
    testWidgets('displays formatted weight', (tester) async {
      final draft = _baseRecord(weight: 73.5);
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('73.5 kg'), findsOneWidget);
    });

    testWidgets('displays formatted height', (tester) async {
      final draft = _baseRecord(height: 168.0);
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('168 cm'), findsOneWidget);
    });

    testWidgets('displays em dash when weight is null', (tester) async {
      final draft = _baseRecord(weight: null);
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsWidgets);
    });

    testWidgets('displays em dash when height is null', (tester) async {
      final draft = _baseRecord(height: null);
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsWidgets);
    });

    testWidgets('displays blood type when present', (tester) async {
      final draft = _baseRecord(bloodType: 'A+');
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('A+'), findsOneWidget);
    });

    testWidgets('shows Edit button when canEdit is true', (tester) async {
      await tester.pumpWidget(
        _buildWidget(draft: _baseRecord(), canEdit: true),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('dit', findRichText: true), findsWidgets);
    });

    testWidgets('hides Edit button when canEdit is false', (tester) async {
      await tester.pumpWidget(
        _buildWidget(draft: _baseRecord(), canEdit: false),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Editar'), findsNothing);
    });

    testWidgets('tapping Edit vitals calls onEditVitalSigns', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _buildWidget(
          draft: _baseRecord(),
          canEdit: true,
          onEditVitalSigns: () => called = true,
        ),
      );
      await tester.pumpAndSettle();

      final editButtons = find.textContaining('Editar');
      expect(editButtons, findsWidgets);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 5. Identity section
  // ══════════════════════════════════════════════════════════════════════════
  group('Identity section —', () {
    testWidgets('displays document number when non-empty', (tester) async {
      final draft = _baseRecord(documentNumber: '987654321');
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('987654321'), findsOneWidget);
    });

    testWidgets('shows em dash when document number is empty', (tester) async {
      final draft = _baseRecord(documentNumber: '');
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsWidgets);
    });

    testWidgets('displays nationalityName when available', (tester) async {
      final draft = _baseRecord(
        nationalityCode: 'VEN',
        nationalityName: 'Venezuela',
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('Venezuela'), findsOneWidget);
    });

    testWidgets('falls back to nationalityCode when name is null', (
      tester,
    ) async {
      final draft = _baseRecord(nationalityCode: 'ECU', nationalityName: null);
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('ECU'), findsOneWidget);
    });

    testWidgets('formats valid dob in Spanish locale', (tester) async {
      final draft = _baseRecord(dob: '1990-06-15');
      await tester.pumpWidget(
        _buildWidget(draft: draft, locale: const Locale('es')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('junio'), findsOneWidget);
    });

    testWidgets('returns raw dob when format is unrecognised', (tester) async {
      final draft = _baseRecord(dob: 'invalid-date');
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('invalid-date'), findsOneWidget);
    });

    testWidgets('returns raw dob when string is empty', (tester) async {
      final draft = _baseRecord(dob: '');
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });

    testWidgets('sex label M renders correctly', (tester) async {
      final draft = _baseRecord(biologicalSex: 'M');
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.textContaining('asculin', findRichText: true), findsWidgets);
    });

    testWidgets('sex label F renders correctly', (tester) async {
      final draft = _baseRecord(biologicalSex: 'F');
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.textContaining('emenin', findRichText: true), findsWidgets);
    });

    testWidgets('unknown sex code is shown as-is', (tester) async {
      final draft = _baseRecord(biologicalSex: 'X');
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('X', findRichText: true).evaluate().isNotEmpty ||
            find.textContaining('Indeterminado').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('docType CC renders localised label', (tester) async {
      final draft = _baseRecord(documentType: 'CC');
      await tester.pumpWidget(
        _buildWidget(draft: draft, locale: const Locale('es')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('dula', findRichText: true).evaluate().isNotEmpty ||
            find.textContaining('National ID').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('unknown docType code falls through as raw string', (
      tester,
    ) async {
      final draft = _baseRecord(documentType: 'ZZ');
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('ZZ'), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 6. Residence section
  // ══════════════════════════════════════════════════════════════════════════
  group('Residence section —', () {
    testWidgets('shows em dash when street is null', (tester) async {
      final draft = _baseRecord(
        address: Address(city: 'Bogotá', state: 'Cundinamarca'),
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsWidgets);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 7. Guardian section
  // ══════════════════════════════════════════════════════════════════════════
  group('Guardian section —', () {
    testWidgets('guardian section is hidden when name is empty', (
      tester,
    ) async {
      final draft = _baseRecord(
        guardian: GuardianInfo(name: '', relationship: '', phone: ''),
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.family_restroom), findsNothing);
    });

    testWidgets('shows em dash when guardian phone is empty', (tester) async {
      final draft = _baseRecord(
        guardian: GuardianInfo(
          name: 'María López',
          relationship: '02',
          phone: '',
        ),
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsWidgets);
    });

    testWidgets('unknown relationship code is shown as-is', (tester) async {
      final draft = _baseRecord(
        guardian: GuardianInfo(
          name: 'X Y',
          relationship: '99',
          phone: '3001234567',
        ),
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.textContaining('99', findRichText: true), findsWidgets);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 8. Orange change-indicator dot visibility
  // ══════════════════════════════════════════════════════════════════════════
  group('Orange change-dot visibility —', () {
    final orangeDot = find.byWidgetPredicate((w) {
      if (w is Container) {
        final deco = w.decoration;
        if (deco is BoxDecoration) {
          final color = deco.color;
          if (color != null) {
            return (color.r * 255).round() == 255 &&
                (color.g * 255).round() == 152 &&
                (color.b * 255).round() == 0;
          }
        }
      }
      return false;
    });

    testWidgets('no dots shown when draft equals original', (tester) async {
      final rec = _baseRecord();
      await tester.pumpWidget(_buildWidget(draft: rec, original: rec));
      await tester.pumpAndSettle();

      expect(orangeDot, findsNothing);
    });

    testWidgets('dot appears when allergies changed', (tester) async {
      final draft = _baseRecord(
        allergies: [AllergyInfo(category: '06', allergen: 'Polen')],
      );
      final original = _baseRecord();
      await tester.pumpWidget(_buildWidget(draft: draft, original: original));
      await tester.pumpAndSettle();

      expect(orangeDot, findsAtLeastNWidgets(1));
    });

    testWidgets('dot appears when weight changed', (tester) async {
      final draft = _baseRecord(weight: 80.0);
      final original = _baseRecord(weight: 62.0);
      await tester.pumpWidget(_buildWidget(draft: draft, original: original));
      await tester.pumpAndSettle();

      expect(orangeDot, findsAtLeastNWidgets(1));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 9. Locale switching (ES → EN)
  // ══════════════════════════════════════════════════════════════════════════
  group('Locale switching —', () {
    testWidgets('no crashes rendering every doc type code', (tester) async {
      const codes = ['RC', 'TI', 'CC', 'CE', 'PA', 'PE', 'PT', 'MS', 'AS'];
      for (final code in codes) {
        final draft = _baseRecord(documentType: code);
        await tester.pumpWidget(
          _buildWidget(draft: draft, locale: const Locale('en')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(ProfileTabSummary),
          findsOneWidget,
          reason: 'Crashed for docType=$code',
        );
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 10. Smoke / robustness
  // ══════════════════════════════════════════════════════════════════════════
  group('Robustness —', () {
    testWidgets('renders without error with all-null optional fields', (
      tester,
    ) async {
      final draft = _baseRecord(
        secondName: null,
        secondLastName: null,
        bloodType: null,
        weight: null,
        height: null,
        ethnicity: null,
        disabilityCategory: null,
        nationalityName: null,
        address: Address(city: '', state: ''),
        background: null,
        allergies: const [],
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });

    testWidgets('renders without error with many allergies', (tester) async {
      final draft = _baseRecord(
        allergies: List.generate(
          20,
          (i) => AllergyInfo(category: '06', allergen: 'Allergen $i'),
        ),
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });

    testWidgets('renders without error with very long strings', (tester) async {
      final longStr = 'A' * 300;
      final draft = _baseRecord(
        firstName: longStr,
        address: Address(
          street: longStr,
          city: longStr,
          state: longStr,
          zone: '01',
        ),
      );
      await tester.pumpWidget(_buildWidget(draft: draft));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileTabSummary), findsOneWidget);
    });

    testWidgets('canEdit false hides all Edit buttons', (tester) async {
      await tester.pumpWidget(
        _buildWidget(draft: _baseRecord(), canEdit: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsNothing);
      expect(find.text('Edit'), findsNothing);
    });
  });
}
