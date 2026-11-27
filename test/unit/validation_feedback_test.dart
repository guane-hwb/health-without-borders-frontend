// test/unit/validation_feedback_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/register/widgets/validation_feedback.dart';

enum _TestField { name, phone, email }

void main() {
  group('validationSummary', () {
    test('devuelve null cuando missing e invalid están vacíos', () {
      final s = AppStrings.forTesting('es');
      expect(
        validationSummary(s, missing: const [], invalid: const []),
        isNull,
      );
    });

    test('formatea solo missing con prefijo y coma en ES y EN', () {
      final es = AppStrings.forTesting('es');
      final en = AppStrings.forTesting('en');

      expect(
        validationSummary(
          es,
          missing: const ['Nombre', 'Teléfono'],
          invalid: const [],
        ),
        '${es.formMissingPrefix}: Nombre, Teléfono',
      );
      expect(
        validationSummary(
          en,
          missing: const ['Name', 'Phone'],
          invalid: const [],
        ),
        '${en.formMissingPrefix}: Name, Phone',
      );
    });

    test('formatea solo invalid con prefijo y punto y coma', () {
      final es = AppStrings.forTesting('es');
      expect(
        validationSummary(
          es,
          missing: const [],
          invalid: const ['Correo inválido', 'Teléfono inválido'],
        ),
        '${es.formFixPrefix}: Correo inválido; Teléfono inválido',
      );
    });

    test('combina missing en la primera línea e invalid en la segunda', () {
      final es = AppStrings.forTesting('es');
      expect(
        validationSummary(
          es,
          missing: const ['Nombre'],
          invalid: const ['Correo inválido'],
        ),
        '${es.formMissingPrefix}: Nombre\n${es.formFixPrefix}: Correo inválido',
      );
    });
  });

  group('openSummary & SummaryEntry', () {
    test(
      'mantiene entradas abiertas mientras su error coincida o field sea null',
      () {
        final s = AppStrings.forTesting('es');
        final entries = <SummaryEntry<_TestField>>[
          const SummaryEntry(
            'Nombre',
            field: _TestField.name,
            fieldError: 'Requerido',
          ),
          const SummaryEntry(
            'Correo inválido',
            field: _TestField.email,
            fieldError: 'Formato inválido',
            invalid: true,
          ),
          const SummaryEntry('Elemento sin campo asociado'),
        ];

        final fieldErrors = <_TestField, String>{
          _TestField.name: 'Requerido',
          _TestField.email: 'Formato inválido',
        };

        expect(
          openSummary(s, entries, fieldErrors),
          '${s.formMissingPrefix}: Nombre, Elemento sin campo asociado\n'
          '${s.formFixPrefix}: Correo inválido',
        );
      },
    );

    test(
      'cierra las entradas cuyo campo ya no tiene el error registrado y devuelve null al corregir todo',
      () {
        final s = AppStrings.forTesting('es');
        final entries = <SummaryEntry<_TestField>>[
          const SummaryEntry(
            'Nombre',
            field: _TestField.name,
            fieldError: 'Requerido',
          ),
          const SummaryEntry(
            'Teléfono inválido',
            field: _TestField.phone,
            fieldError: 'Inválido',
            invalid: true,
          ),
        ];

        final partialErrors = <_TestField, String>{
          _TestField.phone: 'Inválido',
        };
        expect(
          openSummary(s, entries, partialErrors),
          '${s.formFixPrefix}: Teléfono inválido',
        );

        expect(openSummary(s, entries, const <_TestField, String>{}), isNull);
      },
    );
  });
}
