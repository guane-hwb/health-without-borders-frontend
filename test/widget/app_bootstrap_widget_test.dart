// test/widget/app_bootstrap_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/bootstrap/app_bootstrap.dart';

void main() {
  late ValueNotifier<Object?> session;
  late int starts;
  late int stops;
  late AppBootstrap bootstrap;
  Object? restored;

  setUp(() {
    session = ValueNotifier<Object?>(null);
    starts = 0;
    stops = 0;
    restored = null;
    bootstrap = AppBootstrap(
      session: session,
      startSync: () => starts++,
      stopSync: () => stops++,
      restoreSession: () async {
        session.value = restored;
        return restored;
      },
    );
  });

  test('arranque sin sesión no inicia el motor', () async {
    bootstrap.attach();
    await Future<void>.delayed(Duration.zero);
    expect(starts, 0);
  });

  test('arranque con sesión restaurada inicia el motor', () async {
    restored = Object();
    bootstrap.attach();
    await Future<void>.delayed(Duration.zero);
    expect(starts, 1);
  });

  test('la sincronización reacciona a la red tras un segundo login', () async {
    bootstrap.attach();
    await Future<void>.delayed(Duration.zero);

    session.value = Object();
    expect(starts, 1);

    session.value = null;
    expect(stops, 1);

    session.value = Object();
    expect(
      starts,
      2,
      reason: 'el motor debe re-arrancar con cada sesión nueva',
    );
  });

  test('dispose quita el listener y detiene el motor', () async {
    bootstrap.attach();
    await Future<void>.delayed(Duration.zero);
    bootstrap.dispose();
    final int stopsAfterDispose = stops;
    session.value = Object();
    expect(starts, 0);
    expect(stops, stopsAfterDispose);
  });
}
