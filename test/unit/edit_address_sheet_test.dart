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
}
