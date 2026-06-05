// test/unit/shared_read_nfc_header_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/shared_read_nfc_header.dart';

void main() {
  group('SharedReadNfcHeader — Pruebas Unitarias de Constructor', () {
    test('Los valores de inicialización por defecto deben ser correctos', () {
      const header = SharedReadNfcHeader();

      expect(header.title, equals('HWB'));
      expect(header.onBack, isNull);
      expect(header.stepText, isNull);
    });

    test(
      'Debe mapear los argumentos asignados en las propiedades inmutables',
      () {
        void dummyCallback() {}

        final header = SharedReadNfcHeader(
          title: 'Escanear',
          onBack: dummyCallback,
          stepText: 'Paso 2',
        );

        expect(header.title, equals('Escanear'));
        expect(header.onBack, equals(dummyCallback));
        expect(header.stepText, equals('Paso 2'));
      },
    );
  });
}
