import 'package:flutter/material.dart';

import 'core/cache/form_draft_cache.dart';
import 'core/config/app_env.dart';
import 'core/di/app_scope.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'design/theme/app_theme.dart';
import 'features/nfc/data/catalog_repository.dart';
import 'features/nfc/data/patient_repository.dart';

class HealthWithoutBordersApp extends StatelessWidget {
  HealthWithoutBordersApp({super.key});

  final ApiClient _apiClient = ApiClient(baseUrl: AppEnv.apiBaseUrl);

  late final AuthRepository _authRepository = AuthRepository(
    apiClient: _apiClient,
  );

  late final PatientRepository _patientRepository = PatientRepository(
    apiClient: _apiClient,
    authRepository: _authRepository,
  );

  late final CatalogRepository _catalogRepository = CatalogRepository(
    apiClient: _apiClient,
    authRepository: _authRepository,
  );
  final FormDraftCache _formDraftCache = FormDraftCache();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      authRepository: _authRepository,
      patientRepository: _patientRepository,
      catalogRepository: _catalogRepository,
      formDraftCache: _formDraftCache,
      child: MaterialApp(
        title: 'Health Without Borders',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        home: const LoginScreen(),
      ),
    );
  }
}
