// lib/src/features/nfc/presentation/profile/patient_profile_helpers.dart

import 'package:connectivity_plus/connectivity_plus.dart';

bool hasInternetConnection(List<ConnectivityResult> results) {
  return !results.contains(ConnectivityResult.none);
}
