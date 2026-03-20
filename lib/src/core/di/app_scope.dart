import 'package:flutter/material.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/nfc/data/catalog_repository.dart';
import '../../features/nfc/data/patient_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.authRepository,
    required this.patientRepository,
    required this.catalogRepository,
    required super.child,
  });

  final AuthRepository authRepository;
  final PatientRepository patientRepository;
  final CatalogRepository catalogRepository;

  static AppScope of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw StateError('AppScope not found in widget tree.');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) {
    return oldWidget.authRepository != authRepository ||
        oldWidget.patientRepository != patientRepository ||
        oldWidget.catalogRepository != catalogRepository;
  }
}
