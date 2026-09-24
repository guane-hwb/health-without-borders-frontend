// test/widget/profile_banners_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/profile_banners.dart';

Widget _wrap(Widget child, {String locale = 'es'}) {
  return AppLocale(
    locale: locale,
    setLocale: (_) {},
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
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

  group('EmergencyBanner — Widget Tests', () {
    testWidgets('renders correctly in Spanish (es)', (tester) async {
      await tester.pumpWidget(_wrap(const EmergencyBanner(), locale: 'es'));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.text(
          'Acceso de emergencia · sin autorización del guardián · registrado',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders correctly in English (en)', (tester) async {
      await tester.pumpWidget(_wrap(const EmergencyBanner(), locale: 'en'));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.text('Emergency access · without guardian authorisation · logged'),
        findsOneWidget,
      );
    });
  });

  group('OfflineBanner — Widget Tests', () {
    testWidgets('renders default offline view label in Spanish (es)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const OfflineBanner(isDynamicDisconnect: false), locale: 'es'),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(
        find.text('Vista sin conexión · datos leídos del chip'),
        findsOneWidget,
      );
    });

    testWidgets('renders default offline view label in English (en)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const OfflineBanner(isDynamicDisconnect: false), locale: 'en'),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(
        find.text('Offline view · data read from the chip'),
        findsOneWidget,
      );
    });

    testWidgets('renders dynamic disconnect label in Spanish (es)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const OfflineBanner(isDynamicDisconnect: true), locale: 'es'),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(
        find.text(
          'Sin conexión a Internet · Los cambios se guardarán localmente',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders dynamic disconnect label in English (en)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const OfflineBanner(isDynamicDisconnect: true), locale: 'en'),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(
        find.text('No internet connection · Changes will be saved locally'),
        findsOneWidget,
      );
    });
  });

  group('NfcStaleBanner — Widget Tests', () {
    testWidgets(
      'renders stale notice with update button in Spanish (es) and triggers callback',
      (tester) async {
        var updateCalled = false;

        await tester.pumpWidget(
          _wrap(
            NfcStaleBanner(
              isUpdating: false,
              onUpdate: () => updateCalled = true,
            ),
            locale: 'es',
          ),
        );

        expect(find.byIcon(Icons.sync_problem), findsOneWidget);
        expect(find.text('Respaldo NFC desactualizado'), findsOneWidget);
        expect(find.text('Actualizar'), findsOneWidget);

        await tester.tap(find.text('Actualizar'));
        await tester.pump();

        expect(updateCalled, isTrue);
      },
    );

    testWidgets('renders stale notice with update button in English (en)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(NfcStaleBanner(isUpdating: false, onUpdate: () {}), locale: 'en'),
      );

      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
      expect(find.text('NFC backup out of date'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('renders CircularProgressIndicator when isUpdating is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(NfcStaleBanner(isUpdating: true, onUpdate: () {}), locale: 'es'),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Actualizar'), findsNothing);
    });
  });
}
