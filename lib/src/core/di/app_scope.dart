import 'package:flutter/material.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/nfc/data/patient_repository.dart';
import '../storage/local_database.dart';
import '../sync/sync_engine.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.authRepository,
    required this.patientRepository,
    required this.localDatabase,
    required this.syncEngine,
    required super.child,
  });

  final AuthRepository authRepository;
  final PatientRepository patientRepository;
  final LocalDatabase localDatabase;
  final SyncEngine syncEngine;

  static AppScope of(BuildContext context) {
    final AppScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw StateError('AppScope not found in widget tree.');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) {
    return oldWidget.authRepository != authRepository ||
        oldWidget.patientRepository != patientRepository;
  }
}