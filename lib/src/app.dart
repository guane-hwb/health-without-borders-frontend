// lib/src/app.dart
import 'package:flutter/material.dart';

import 'core/config/app_env.dart';
import 'core/di/app_scope.dart';
import 'core/i18n/app_strings.dart';
import 'core/network/api_client.dart';
import 'core/storage/local_database.dart';
import 'core/sync/sync_engine.dart';
import 'design/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/user_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/nfc/data/patient_repository.dart';

class HealthWithoutBordersApp extends StatefulWidget {
  const HealthWithoutBordersApp({super.key});
  @override
  State<HealthWithoutBordersApp> createState() =>
      _HealthWithoutBordersAppState();
}

class _HealthWithoutBordersAppState extends State<HealthWithoutBordersApp> {
  final ApiClient _apiClient = ApiClient(baseUrl: AppEnv.apiBaseUrl);
  String _locale = 'es';

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
  late final LocalDatabase _localDatabase = LocalDatabase.instance;
  late final SyncEngine _syncEngine = SyncEngine(
    patientRepository: _patientRepository,
    localDatabase: _localDatabase,
  );

  @override
  Widget build(BuildContext context) {
    return AppLocale(
      locale: _locale,
      setLocale: (String l) => setState(() => _locale = l),
      child: AppScope(
        authRepository: _authRepository,
        userRepository: _userRepository,
        patientRepository: _patientRepository,
        localDatabase: _localDatabase,
        syncEngine: _syncEngine,
        child: MaterialApp(
          title: 'Health Without Borders',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: const LoginScreen(),
        ),
      ),
    );
  }
}