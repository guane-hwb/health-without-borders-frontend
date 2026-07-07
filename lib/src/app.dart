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

  // 🚀 Inicializa el estado global de la aplicación
  @override
  void initState() {
    super.initState();
    // Cablea el auto-refresh de tokens: ante un 401 en una ruta protegida, el
    // ApiClient renueva el access token con el refresh token y reintenta la
    // petición, de forma transparente para toda la app.
    _apiClient.tokenProvider = _authRepository;
    // Enciende el motor automático para escuchar cambios de red e iniciar sincronizaciones
    _syncEngine.start();
  }

  // 🧹 Limpia los recursos cuando la aplicación se destruye o se recarga
  @override
  void dispose() {
    // Apaga los listeners de conectividad para evitar fugas de memoria (memory leaks)
    _syncEngine.stop();
    super.dispose();
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
