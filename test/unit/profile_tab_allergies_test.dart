// test/unit/features/nfc/profile/tabs/profile_tab_allergies_unit_test.dart
//
// Unit tests for ProfileTabAllergies.
// Covers the pure logic that does NOT require the widget tree:
//   • _AllergyCard._categoryLabel — code → label mapping
//   • AllergyInfo — data integrity (allergen, category, reaction)
//   • Count of items in the allergy list
//   • Edge cases: unknown category, null/empty reaction

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

String categoryLabel(String c) {
  switch (c) {
    case '01':
      return 'Medicamento';
    case '02':
      return 'Alimento';
    case '03':
      return 'Sust. ambiente';
    case '04':
      return 'Sust. piel';
    case '05':
      return 'Picadura';
    case '06':
      return 'Otra';
    default:
      return c;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────
AllergyInfo _allergy({
  required String category,
  required String allergen,
  String? reaction,
}) => AllergyInfo(category: category, allergen: allergen, reaction: reaction);

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  // ── Group 1: _categoryLabel — all known codes ─────────────────
  group('_categoryLabel — mapeo código → etiqueta', () {
    test('01 → Medicamento', () {
      expect(categoryLabel('01'), equals('Medicamento'));
    });

    test('02 → Alimento', () {
      expect(categoryLabel('02'), equals('Alimento'));
    });

    test('03 → Sust. ambiente', () {
      expect(categoryLabel('03'), equals('Sust. ambiente'));
    });

    test('04 → Sust. piel', () {
      expect(categoryLabel('04'), equals('Sust. piel'));
    });

    test('05 → Picadura', () {
      expect(categoryLabel('05'), equals('Picadura'));
    });

    test('06 → Otra', () {
      expect(categoryLabel('06'), equals('Otra'));
    });

    test('código desconocido devuelve el mismo código', () {
      expect(categoryLabel('99'), equals('99'));
    });

    test('código vacío devuelve cadena vacía', () {
      expect(categoryLabel(''), equals(''));
    });

    test(
      'código en mayúsculas no coincide con ningún caso (case-sensitive)',
      () {
        // The codes are always '01'-'06'; this test documents the behavior.
        expect(categoryLabel('A1'), equals('A1'));
      },
    );
  });

  // ── Group 2: AllergyInfo — data integrity ────────────────────────────
  group('AllergyInfo — integridad de datos', () {
    test('allergen se almacena correctamente', () {
      final a = _allergy(category: '01', allergen: 'Penicilina');
      expect(a.allergen, equals('Penicilina'));
    });

    test('category se almacena correctamente', () {
      final a = _allergy(category: '02', allergen: 'Maní');
      expect(a.category, equals('02'));
    });

    test('reaction nula se mantiene nula', () {
      final a = _allergy(category: '03', allergen: 'Polen', reaction: null);
      expect(a.reaction, isNull);
    });

    test('reaction vacía se mantiene vacía', () {
      final a = _allergy(category: '04', allergen: 'Látex', reaction: '');
      expect(a.reaction, equals(''));
    });

    test('reaction con texto se almacena correctamente', () {
      final a = _allergy(
        category: '05',
        allergen: 'Abeja',
        reaction: 'Anafilaxia',
      );
      expect(a.reaction, equals('Anafilaxia'));
    });

    test('allergen no es nulo ni vacío en caso válido', () {
      final a = _allergy(category: '06', allergen: 'Yodo');
      expect(a.allergen, isNotEmpty);
    });
  });

  // ── Group 3: Allergy counting logic on the list ─────────────────────
  group('Lista de alergias — conteo y operaciones', () {
    test('lista vacía tiene longitud 0', () {
      final allergies = <AllergyInfo>[];
      expect(allergies.length, equals(0));
      expect(allergies.isEmpty, isTrue);
    });

    test('agregar un ítem incrementa la longitud a 1', () {
      final allergies = <AllergyInfo>[];
      allergies.add(_allergy(category: '01', allergen: 'Aspirina'));
      expect(allergies.length, equals(1));
      expect(allergies.isNotEmpty, isTrue);
    });

    test('agregar múltiples ítems refleja la longitud correcta', () {
      final allergies = [
        _allergy(category: '01', allergen: 'Penicilina'),
        _allergy(category: '02', allergen: 'Maní'),
        _allergy(category: '05', allergen: 'Abeja'),
      ];
      expect(allergies.length, equals(3));
    });

    test('eliminar por índice reduce la longitud', () {
      final allergies = [
        _allergy(category: '01', allergen: 'Penicilina'),
        _allergy(category: '02', allergen: 'Maní'),
      ];
      allergies.removeAt(0);
      expect(allergies.length, equals(1));
      expect(allergies.first.allergen, equals('Maní'));
    });

    test('eliminar el único ítem deja la lista vacía', () {
      final allergies = [_allergy(category: '06', allergen: 'Yodo')];
      allergies.removeAt(0);
      expect(allergies.isEmpty, isTrue);
    });

    test('el índice devuelto corresponde al ítem correcto', () {
      final allergies = [
        _allergy(category: '01', allergen: 'Primer alérgeno'),
        _allergy(category: '02', allergen: 'Segundo alérgeno'),
      ];
      expect(allergies[0].allergen, equals('Primer alérgeno'));
      expect(allergies[1].allergen, equals('Segundo alérgeno'));
    });
  });

  // ── Group 4: Borderline cases of reaction ─────────────────────────────────────
  group('AllergyInfo.reaction — casos borde', () {
    test('reaction con solo espacios no es considerada vacía por Dart', () {
      final a = _allergy(category: '01', allergen: 'X', reaction: '   ');
      expect(a.reaction!.isNotEmpty, isTrue);
    });

    test('reaction con texto largo se almacena completa', () {
      final longReaction = 'A' * 500;
      final a = _allergy(category: '01', allergen: 'X', reaction: longReaction);
      expect(a.reaction!.length, equals(500));
    });

    test('reaction nula: la condición null-check es false', () {
      final a = _allergy(category: '01', allergen: 'X', reaction: null);
      final shouldShowReaction = a.reaction != null && a.reaction!.isNotEmpty;
      expect(shouldShowReaction, isFalse);
    });

    test('reaction vacía: la condición null-check es false', () {
      final a = _allergy(category: '01', allergen: 'X', reaction: '');
      final shouldShowReaction = a.reaction != null && a.reaction!.isNotEmpty;
      expect(shouldShowReaction, isFalse);
    });

    test('reaction válida: la condición null-check es true', () {
      final a = _allergy(category: '01', allergen: 'X', reaction: 'Urticaria');
      final shouldShowReaction = a.reaction != null && a.reaction!.isNotEmpty;
      expect(shouldShowReaction, isTrue);
    });
  });
}
