// test/unit/sync_conflicts_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/sync/sync_conflicts.dart';

void main() {
  group('SyncConflictCode.describe', () {
    test('una línea por cada código conocido, en su orden', () {
      final lines = SyncConflictCode.describe(const <String>[
        'stale_payload_retired_device_uid',
        'stale_payload_base_version',
        'guardians_not_changed_by_tag_resolved_sync',
      ], isEs: true);

      expect(lines, hasLength(3));
      expect(lines[0], contains('pulsera o tarjeta ya retirada'));
      expect(lines[1], contains('ya había cambiado en el servidor'));
      expect(lines[2], contains('Los acudientes no se cambiaron'));
    });

    test('las ediciones de consultas y vacunas se cuentan, no se listan', () {
      final lines = SyncConflictCode.describe(const <String>[
        'visit_edit_not_applied:enc-1',
        'visit_edit_not_applied:enc-2',
        'vaccination_edit_not_applied:vac-1',
      ], isEs: true);

      expect(lines, <String>[
        'Las correcciones de 2 consultas ya registradas NO se guardaron en '
            'el servidor: conservan su versión anterior.',
        'La corrección de una vacuna ya registrada NO se guardó en el '
            'servidor: conserva su versión anterior.',
      ]);
    });

    test('en inglés', () {
      final lines = SyncConflictCode.describe(const <String>[
        'stale_payload_base_version',
        'visit_edit_not_applied:enc-1',
        'vaccination_edit_not_applied:vac-1',
        'vaccination_edit_not_applied:vac-2',
      ], isEs: false);

      expect(lines[0], contains('had already changed on the server'));
      expect(lines[1], contains('The correction to a visit'));
      expect(lines[2], contains('The corrections to 2 vaccines'));
    });

    test('un código desconocido da una sola línea genérica', () {
      final lines = SyncConflictCode.describe(const <String>[
        'something_new',
        'something_else:42',
      ], isEs: true);

      expect(lines, <String>[
        'El servidor no aplicó parte de los cambios; el resto se guardó.',
      ]);
    });

    test('sin códigos no hay líneas', () {
      expect(SyncConflictCode.describe(const <String>[], isEs: true), isEmpty);
    });
  });

  group('SyncConflictCode.nextStep', () {
    test('con la versión del servidor en pantalla, pide actualizar chips', () {
      expect(
        SyncConflictCode.nextStep(serverCopyShown: true, isEs: true),
        startsWith('Lo que ve es la versión del servidor'),
      );
      expect(
        SyncConflictCode.nextStep(serverCopyShown: true, isEs: false),
        startsWith("What you see is the server's version"),
      );
    });

    test('sin ella, pide escanear de nuevo la pulsera', () {
      expect(
        SyncConflictCode.nextStep(serverCopyShown: false, isEs: true),
        startsWith('Escanee de nuevo la pulsera'),
      );
      expect(
        SyncConflictCode.nextStep(serverCopyShown: false, isEs: false),
        startsWith('Scan the wristband again'),
      );
    });
  });
}
