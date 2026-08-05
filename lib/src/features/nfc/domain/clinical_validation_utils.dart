// lib/src/features/nfc/domain/clinical_validation_utils.dart

class ClinicalValidationUtils {
  static String? validateWeight(double? weight, {bool isEs = true}) {
    if (weight == null) return null;
    if (weight <= 0.2 || weight > 350.0) {
      return isEs
          ? 'El peso debe estar entre 0.2 kg y 350 kg'
          : 'Weight must be between 0.2 kg and 350 kg';
    }
    return null;
  }

  static String? validateHeight(double? height, {bool isEs = true}) {
    if (height == null) return null;
    if (height <= 20.0 || height > 250.0) {
      return isEs
          ? 'La altura debe estar entre 20 cm y 250 cm'
          : 'Height must be between 20 cm and 250 cm';
    }
    return null;
  }
}
