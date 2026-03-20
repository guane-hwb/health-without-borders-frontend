import 'package:flutter/material.dart';

import '../cache/form_draft_cache.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/nfc/data/catalog_repository.dart';
import '../../features/nfc/data/patient_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.authRepository,
    required this.patientRepository,
    required this.catalogRepository,
    required this.formDraftCache,
    required super.child,
  });

  final AuthRepository authRepository;
  final PatientRepository patientRepository;
  final CatalogRepository catalogRepository;
  final FormDraftCache formDraftCache;

  static AppScope of(BuildContext context) {
    final AppScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw StateError('AppScope not found in widget tree.');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) {
    return oldWidget.authRepository != authRepository ||
        oldWidget.patientRepository != patientRepository ||
        oldWidget.catalogRepository != catalogRepository ||
        oldWidget.formDraftCache != formDraftCache;
  }
}
