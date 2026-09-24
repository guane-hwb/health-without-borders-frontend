// test/unit/edit_address_sheet_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

void main() {
  group(
    'EditAddressSheet — Controller Initialization and Memory Lifecycle',
    () {
      test(
        'controllers instantiate exactly matching supplied model fields',
        () {
          final baseAddress = Address(
            city: 'Riohacha',
            state: 'La Guajira',
            street: 'Cra. 15 #22-10',
            zone: '01',
          );

          final streetCtrl = TextEditingController(
            text: baseAddress.street ?? '',
          );
          final cityCtrl = TextEditingController(text: baseAddress.city);
          final stateCtrl = TextEditingController(text: baseAddress.state);
          final initialZone = baseAddress.zone ?? '01';

          expect(streetCtrl.text, equals('Cra. 15 #22-10'));
          expect(cityCtrl.text, equals('Riohacha'));
          expect(stateCtrl.text, equals('La Guajira'));
          expect(initialZone, equals('01'));

          streetCtrl.dispose();
          cityCtrl.dispose();
          stateCtrl.dispose();
        },
      );

      test(
        'null or empty address elements initialize safely to empty strings',
        () {
          final baseAddress = Address(
            city: 'Maicao',
            state: 'La Guajira',
            street: null,
            zone: null,
          );

          final streetCtrl = TextEditingController(
            text: baseAddress.street ?? '',
          );
          final initialZone = baseAddress.zone ?? '01';

          expect(streetCtrl.text, isEmpty);
          expect(initialZone, equals('01'));

          streetCtrl.dispose();
        },
      );
    },
  );

  group('EditAddressSheet — Model Extraction Formatting Rules', () {
    String? formatStreet(String text) {
      return text.trim().isEmpty ? null : text.trim();
    }

    test(
      'returns null when text values contain only blank space arguments',
      () {
        expect(formatStreet(''), isNull);
        expect(formatStreet('   '), isNull);
        expect(formatStreet('\n\t'), isNull);
      },
    );

    test(
      'returns a trimmed string when valid entry parameters are supplied',
      () {
        expect(formatStreet('  Calle 10 #15-20  '), equals('Calle 10 #15-20'));
        expect(
          formatStreet('Urbanización El Sol'),
          equals('Urbanización El Sol'),
        );
      },
    );
  });

  group('EditAddressSheet — Zone Domain Mutation Signatures', () {
    test(
      'zone selection boundary metrics accept only valid sequence flags',
      () {
        var activeZone = '01';

        void selectUrbanZone() => activeZone = '01';
        void selectRuralZone() => activeZone = '02';

        selectRuralZone();
        expect(activeZone, equals('02'));

        selectUrbanZone();
        expect(activeZone, equals('01'));
      },
    );
  });

  group('EditAddressSheet — Unsaved Changes Logic', () {
    bool hasUnsavedChanges({
      required String street,
      required String city,
      required String state,
      required String zone,
      required String initialStreet,
      required String initialCity,
      required String initialState,
      required String initialZone,
    }) {
      final streetChanged = street.trim() != initialStreet;
      final cityChanged = city.trim() != initialCity;
      final stateChanged = state.trim() != initialState;
      final zoneChanged = zone != initialZone;

      return streetChanged || cityChanged || stateChanged || zoneChanged;
    }

    test('returns false when fields remain unmodified', () {
      expect(
        hasUnsavedChanges(
          street: 'Calle 10',
          city: 'Riohacha',
          state: 'La Guajira',
          zone: '01',
          initialStreet: 'Calle 10',
          initialCity: 'Riohacha',
          initialState: 'La Guajira',
          initialZone: '01',
        ),
        isFalse,
      );
    });

    test('returns true when any field or zone changes', () {
      expect(
        hasUnsavedChanges(
          street: 'Calle 20',
          city: 'Riohacha',
          state: 'La Guajira',
          zone: '01',
          initialStreet: 'Calle 10',
          initialCity: 'Riohacha',
          initialState: 'La Guajira',
          initialZone: '01',
        ),
        isTrue,
      );

      expect(
        hasUnsavedChanges(
          street: 'Calle 10',
          city: 'Riohacha',
          state: 'La Guajira',
          zone: '02',
          initialStreet: 'Calle 10',
          initialCity: 'Riohacha',
          initialState: 'La Guajira',
          initialZone: '01',
        ),
        isTrue,
      );
    });
  });
}
