// lib/src/core/di/app_scope.dart
import 'package:flutter/material.dart';

import '../../features/admin/data/stats_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/domain/user_session.dart';
import '../../features/nfc/data/patient_repository.dart';
import '../storage/local_database.dart';
import '../sync/sync_engine.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.authRepository,
    required this.userRepository,
    required this.patientRepository,
    required this.statsRepository,
    required this.localDatabase,
    required this.syncEngine,
    required super.child,
  });

  final AuthRepository authRepository;
  final UserRepository userRepository;
  final PatientRepository patientRepository;
  final StatsRepository statsRepository;
  final LocalDatabase localDatabase;
  final SyncEngine syncEngine;

  /// Current user (set after login, nullable before auth).
  UserSession? get currentUser => authRepository.currentUser;

  static AppScope of(BuildContext context) {
    final AppScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) throw StateError('AppScope not found in widget tree.');
    return scope;
  }

  @override
  bool updateShouldNotify(covariant AppScope old) =>
      old.authRepository != authRepository ||
      old.patientRepository != patientRepository;
}