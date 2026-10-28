// test/unit/code_source_label_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/shared/code_source_label.dart';

void main() {
  late AppStrings stringsEs;
  late AppStrings stringsEn;

  Future<void> setUpWidgets(WidgetTester tester) async {
    await tester.pumpWidget(
      AppLocale(
        locale: 'es',
        setLocale: (_) {},
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              stringsEs = AppStrings.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      AppLocale(
        locale: 'en',
        setLocale: (_) {},
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              stringsEn = AppStrings.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  group('diagnosisSourceLabel — Cobertura 100%', () {
    testWidgets('retorna null cuando la fuente es CodeSource.clinician', (
      tester,
    ) async {
      await setUpWidgets(tester);
      final result = diagnosisSourceLabel(stringsEs, CodeSource.clinician);
      expect(result, isNull);
    });

    testWidgets('retorna etiqueta de IA sugerido para CodeSource.aiSuggested', (
      tester,
    ) async {
      await setUpWidgets(tester);
      final resultEs = diagnosisSourceLabel(stringsEs, CodeSource.aiSuggested);
      final resultEn = diagnosisSourceLabel(stringsEn, CodeSource.aiSuggested);

      expect(resultEs, equals(stringsEs.sourceAiSuggested));
      expect(resultEn, equals(stringsEn.sourceAiSuggested));
    });

    testWidgets('retorna etiqueta de IA fallback para CodeSource.aiFallback', (
      tester,
    ) async {
      await setUpWidgets(tester);
      final resultEs = diagnosisSourceLabel(stringsEs, CodeSource.aiFallback);
      final resultEn = diagnosisSourceLabel(stringsEn, CodeSource.aiFallback);

      expect(resultEs, equals(stringsEs.sourceAiFallback));
      expect(resultEn, equals(stringsEn.sourceAiFallback));
    });

    testWidgets(
      'retorna etiqueta no registrada para fuentes desconocidas o nulas',
      (tester) async {
        await setUpWidgets(tester);
        expect(
          diagnosisSourceLabel(stringsEs, null),
          equals(stringsEs.sourceUnrecorded),
        );
        expect(
          diagnosisSourceLabel(stringsEs, 'fuente_desconocida'),
          equals(stringsEs.sourceUnrecorded),
        );
      },
    );
  });

  group('backgroundCodeLine — Cobertura 100%', () {
    testWidgets('construye la línea únicamente con el código CIE-10 básico', (
      tester,
    ) async {
      await setUpWidgets(tester);
      final line = backgroundCodeLine(stringsEs, cie10Code: 'J45.9');

      expect(line, equals('${stringsEs.cie10Label}J45.9'));
    });

    testWidgets(
      'incluye el nombre codificado (codedDisplay) cuando no está vacío',
      (tester) async {
        await setUpWidgets(tester);
        final line = backgroundCodeLine(
          stringsEs,
          cie10Code: 'J45.9',
          codedDisplay: 'Asma no especificada',
        );

        expect(
          line,
          equals('${stringsEs.cie10Label}J45.9 — Asma no especificada'),
        );
      },
    );

    testWidgets('omite codedDisplay si es nulo o cadena vacía', (tester) async {
      await setUpWidgets(tester);
      final lineNull = backgroundCodeLine(
        stringsEs,
        cie10Code: 'J45.9',
        codedDisplay: null,
      );
      final lineEmpty = backgroundCodeLine(
        stringsEs,
        cie10Code: 'J45.9',
        codedDisplay: '',
      );

      expect(lineNull, equals('${stringsEs.cie10Label}J45.9'));
      expect(lineEmpty, equals('${stringsEs.cie10Label}J45.9'));
    });

    testWidgets('incluye el código CIE-11 si está presente', (tester) async {
      await setUpWidgets(tester);
      final line = backgroundCodeLine(
        stringsEs,
        cie10Code: 'J45.9',
        cie11Code: 'CA23',
      );

      expect(line, equals('${stringsEs.cie10Label}J45.9 · CIE-11: CA23'));
    });

    testWidgets(
      'agrega el indicador de sugerido por IA cuando la fuente es IA',
      (tester) async {
        await setUpWidgets(tester);
        final lineSuggested = backgroundCodeLine(
          stringsEs,
          cie10Code: 'J45.9',
          codingSource: CodeSource.aiSuggested,
        );
        final lineFallback = backgroundCodeLine(
          stringsEs,
          cie10Code: 'J45.9',
          codingSource: CodeSource.aiFallback,
        );

        expect(
          lineSuggested,
          equals(
            '${stringsEs.cie10Label}J45.9 · ${stringsEs.codeSuggestedByAi}',
          ),
        );
        expect(
          lineFallback,
          equals(
            '${stringsEs.cie10Label}J45.9 · ${stringsEs.codeSuggestedByAi}',
          ),
        );
      },
    );

    testWidgets(
      'NO agrega el indicador de IA si la fuente es clinician o nula',
      (tester) async {
        await setUpWidgets(tester);
        final lineClinician = backgroundCodeLine(
          stringsEs,
          cie10Code: 'J45.9',
          codingSource: CodeSource.clinician,
        );
        final lineNullSource = backgroundCodeLine(
          stringsEs,
          cie10Code: 'J45.9',
          codingSource: null,
        );

        expect(lineClinician, equals('${stringsEs.cie10Label}J45.9'));
        expect(lineNullSource, equals('${stringsEs.cie10Label}J45.9'));
      },
    );

    testWidgets('combina todos los parámetros opcionales de forma correcta', (
      tester,
    ) async {
      await setUpWidgets(tester);
      final line = backgroundCodeLine(
        stringsEs,
        cie10Code: 'J45.9',
        cie11Code: 'CA23',
        codedDisplay: 'Asma no especificada',
        codingSource: CodeSource.aiSuggested,
      );

      final expected =
          '${stringsEs.cie10Label}J45.9 — Asma no especificada · CIE-11: CA23 · ${stringsEs.codeSuggestedByAi}';

      expect(line, equals(expected));
    });
  });
}
