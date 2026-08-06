// lib/src/app.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/app_env.dart';
import 'core/di/app_scope.dart';
import 'core/i18n/app_strings.dart';
import 'core/network/api_client.dart';
import 'core/network/reachability.dart';
import 'core/nfc/nfc_session_manager.dart';
import 'core/storage/local_database.dart';
import 'core/sync/sync_engine.dart';
import 'design/theme/app_theme.dart';
import 'features/admin/data/stats_repository.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/user_repository.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/nfc/data/patient_repository.dart';

class HealthWithoutBordersApp extends StatefulWidget {
  const HealthWithoutBordersApp({super.key});
  @override
  State<HealthWithoutBordersApp> createState() =>
      _HealthWithoutBordersAppState();
}

class _HealthWithoutBordersAppState extends State<HealthWithoutBordersApp>
    with WidgetsBindingObserver {
  final ApiClient _apiClient = ApiClient(baseUrl: AppEnv.apiBaseUrl);
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _locale = 'es';

  late final Reachability _reachability = Reachability(
    baseUrl: AppEnv.apiBaseUrl,
  );

  late final AuthRepository _authRepository = AuthRepository(
    apiClient: _apiClient,
  );
  late final UserRepository _userRepository = UserRepository(
    apiClient: _apiClient,
    authRepository: _authRepository,
  );
  late final PatientRepository _patientRepository = PatientRepository(
    apiClient: _apiClient,
    authRepository: _authRepository,
  );
  late final StatsRepository _statsRepository = StatsRepository(
    apiClient: _apiClient,
    authRepository: _authRepository,
  );
  late final LocalDatabase _localDatabase = LocalDatabase.instance;
  late final SyncEngine _syncEngine = SyncEngine(
    patientRepository: _patientRepository,
    localDatabase: _localDatabase,
    reachability: _reachability,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _apiClient.tokenProvider = _authRepository;
    _authRepository.sessionExpired.addListener(_onSessionExpired);
    _syncEngine.start();
    unawaited(NfcSessionManager.instance.attach());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authRepository.sessionExpired.removeListener(_onSessionExpired);
    _syncEngine.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncEngine.syncAll());
    }
  }

  void _onSessionExpired() {
    if (!_authRepository.sessionExpired.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(showSessionExpired: true),
        ),
        (Route<dynamic> route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLocale(
      locale: _locale,
      setLocale: (String l) => setState(() => _locale = l),
      child: AppScope(
        authRepository: _authRepository,
        userRepository: _userRepository,
        patientRepository: _patientRepository,
        statsRepository: _statsRepository,
        localDatabase: _localDatabase,
        syncEngine: _syncEngine,
        reachability: _reachability,
        child: MaterialApp(
          title: 'Health Without Borders',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,

          locale: Locale(_locale),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'CO'), Locale('en', 'US')],

          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: AuthGate(authRepository: _authRepository),
        ),
      ),
    );
  }
}
