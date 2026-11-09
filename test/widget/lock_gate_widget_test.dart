import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/auth/data/auth_repository.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/auth_gate.dart';
import 'package:health_without_borders_frontend/src/features/auth/presentation/lock_gate.dart';
import 'package:health_without_borders_frontend/src/features/home/presentation/home_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepo;
  final ValueNotifier<bool> localLockedNotifier = ValueNotifier<bool>(true);

  setUp(() {
    authRepo = MockAuthRepository();
    localLockedNotifier.value = true;
    when(() => authRepo.isLocalLocked).thenReturn(localLockedNotifier);
    when(() => authRepo.setLocalLocked(any())).thenAnswer((invocation) {
      localLockedNotifier.value = invocation.positionalArguments.first as bool;
    });
    when(() => authRepo.currentUser).thenReturn(
      UserSession(
        id: '1',
        email: 'nurse@hwb.org',
        fullName: 'Enfermera Ana',
        role: UserRole.nurse,
        organizationId: 'org-1',
      ),
    );
  });

  Widget wrapWidget(Widget child) {
    return AppLocale(
      locale: 'es',
      setLocale: (_) {},
      child: MaterialApp(home: child),
    );
  }

  testWidgets(
    'restaurar sesión muestra LockScreen (pantalla de bloqueo), no HomeScreen directo',
    (tester) async {
      when(() => authRepo.restoreSession()).thenAnswer(
        (_) async => UserSession(
          id: '1',
          email: 'nurse@hwb.org',
          fullName: 'Enfermera Ana',
          role: UserRole.nurse,
          organizationId: 'org-1',
        ),
      );

      await tester.pumpWidget(wrapWidget(AuthGate(authRepository: authRepo)));
      await tester.pump();
      await tester.pump();

      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Sesión bloqueada'), findsOneWidget);
    },
  );

  test('con la app bloqueada, getNfcKeyring() devuelve null', () async {
    when(() => authRepo.isLocalLocked).thenReturn(ValueNotifier<bool>(true));
    when(() => authRepo.getNfcKeyring()).thenAnswer((_) async => null);

    final keyring = await authRepo.getNfcKeyring();
    expect(keyring, isNull);
  });

  test('tras 10 minutos de inactividad, LockController activa el bloqueo', () {
    fakeAsync((async) {
      localLockedNotifier.value = false;
      final controller = LockController(
        authRepository: authRepo,
        foregroundTimeout: const Duration(minutes: 10),
      );

      controller.recordUserActivity();
      async.elapse(const Duration(minutes: 9));
      expect(localLockedNotifier.value, isFalse);

      async.elapse(const Duration(minutes: 2));
      expect(localLockedNotifier.value, isTrue);

      controller.dispose();
    });
  });
}
