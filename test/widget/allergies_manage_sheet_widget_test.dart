// test/widget/allergies_manage_sheet_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/sheets/allergies_manage_sheet.dart';

class _LocaleWrapper extends StatelessWidget {
  const _LocaleWrapper({required this.locale, required this.child});

  final String locale;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AppLocale(locale: locale, setLocale: (_) {}, child: child);
}

Widget _buildDirect({
  required List<AllergyInfo> allergies,
  required VoidCallback onAdd,
  required void Function(int) onRemove,
  String locale = 'es',
}) => _LocaleWrapper(
  locale: locale,
  child: MaterialApp(
    home: Scaffold(
      body: AllergiesManageSheet(
        allergies: allergies,
        onAdd: onAdd,
        onRemove: onRemove,
      ),
    ),
  ),
);

Widget _buildViaBottomSheet({
  required List<AllergyInfo> allergies,
  required VoidCallback onAdd,
  required void Function(int) onRemove,
  String locale = 'es',
}) => _LocaleWrapper(
  locale: locale,
  child: MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: ctx,
              isScrollControlled: true,
              builder: (_) => AllergiesManageSheet(
                allergies: allergies,
                onAdd: onAdd,
                onRemove: onRemove,
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

void main() {
  final sEs = AppStrings.forTesting('es');
  final sEn = AppStrings.forTesting('en');

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1600,
      1200,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('AllergiesManageSheet – Empty state rendering', () {
    testWidgets(
      'displays header counter with 0 and empty placeholder message in Spanish',
      (tester) async {
        await tester.pumpWidget(
          _buildDirect(allergies: [], onAdd: () {}, onRemove: (_) {}),
        );

        expect(find.text('${sEs.allergiesSheetTitle} · 0'), findsOneWidget);
        expect(find.text(sEs.noAllergiesRegistered), findsOneWidget);
        expect(find.text(sEs.addAllergyBtn), findsOneWidget);
      },
    );

    testWidgets(
      'displays header counter with 0 and empty placeholder message in English',
      (tester) async {
        await tester.pumpWidget(
          _buildDirect(
            allergies: [],
            onAdd: () {},
            onRemove: (_) {},
            locale: 'en',
          ),
        );

        expect(find.text('${sEn.allergiesSheetTitle} · 0'), findsOneWidget);
        expect(find.text(sEn.noAllergiesRegistered), findsOneWidget);
        expect(find.text(sEn.addAllergyBtn), findsOneWidget);
      },
    );
  });

  group('AllergiesManageSheet – Populated list & Category labels', () {
    testWidgets(
      'renders list of allergies with reactions and category labels',
      (tester) async {
        final sampleAllergies = [
          AllergyInfo(
            category: '01',
            allergen: 'Penicilina',
            reaction: 'Anafilaxia',
          ),
          AllergyInfo(category: '02', allergen: 'Maní', reaction: 'Urticaria'),
          AllergyInfo(category: '03', allergen: 'Polen', reaction: null),
          AllergyInfo(category: '04', allergen: 'Látex', reaction: ''),
          AllergyInfo(
            category: '05',
            allergen: 'Avispa',
            reaction: 'Inflamación',
          ),
          AllergyInfo(
            category: '06',
            allergen: 'Polvo',
            reaction: 'Estornudos',
          ),
          AllergyInfo(
            category: '99',
            allergen: 'Sustancia X',
            reaction: 'Leve',
          ),
        ];

        await tester.pumpWidget(
          _buildDirect(
            allergies: sampleAllergies,
            onAdd: () {},
            onRemove: (_) {},
          ),
        );

        expect(find.text('${sEs.allergiesSheetTitle} · 7'), findsOneWidget);

        expect(find.text('Penicilina'), findsOneWidget);
        expect(find.text(sEs.allergenMedication), findsOneWidget);
        expect(find.text('${sEs.reactionLabel}Anafilaxia'), findsOneWidget);

        expect(find.text('Maní'), findsOneWidget);
        expect(find.text(sEs.allergenFood), findsOneWidget);

        expect(find.text('Polen'), findsOneWidget);
        expect(find.text(sEs.allergenEnvironment), findsOneWidget);

        expect(find.textContaining('Reacción: null'), findsNothing);

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump();

        expect(find.text('Látex'), findsOneWidget);
        expect(find.text(sEs.allergenSkin), findsOneWidget);

        expect(find.text('Avispa'), findsOneWidget);
        expect(find.text(sEs.allergenInsect), findsOneWidget);

        expect(find.text('Polvo'), findsOneWidget);
        expect(find.text(sEs.allergenOther), findsOneWidget);

        expect(find.text('Sustancia X'), findsOneWidget);
        expect(find.text('99'), findsOneWidget);
      },
    );
  });

  group('AllergiesManageSheet – User Interactions & Callbacks', () {
    testWidgets('triggers onAdd callback when clicking Add button', (
      tester,
    ) async {
      var addCalled = false;

      await tester.pumpWidget(
        _buildDirect(
          allergies: [],
          onAdd: () => addCalled = true,
          onRemove: (_) {},
        ),
      );

      await tester.tap(find.text(sEs.addAllergyBtn));
      await tester.pump();

      expect(addCalled, isTrue);
    });

    testWidgets(
      'triggers onRemove callback with correct index when deleting item',
      (tester) async {
        int? removedIndex;

        final sampleAllergies = [
          AllergyInfo(
            category: '01',
            allergen: 'Aspirina',
            reaction: 'Sarpullido',
          ),
          AllergyInfo(category: '02', allergen: 'Camarones', reaction: 'Edema'),
        ];

        await tester.pumpWidget(
          _buildDirect(
            allergies: sampleAllergies,
            onAdd: () {},
            onRemove: (idx) => removedIndex = idx,
          ),
        );

        final deleteIcons = find.byIcon(Icons.delete_outline);
        expect(deleteIcons, findsNWidgets(2));

        await tester.tap(deleteIcons.at(1));
        await tester.pump();

        expect(removedIndex, equals(1));
      },
    );

    testWidgets('dismisses sheet when clicking top right close button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildViaBottomSheet(allergies: [], onAdd: () {}, onRemove: (_) {}),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(AllergiesManageSheet), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(AllergiesManageSheet), findsNothing);
    });
  });
}
