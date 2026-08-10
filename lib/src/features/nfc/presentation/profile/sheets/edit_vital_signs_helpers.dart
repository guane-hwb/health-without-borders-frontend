// lib/src/features/nfc/presentation/profile/sheets/edit_vital_signs_helpers.dart

String weightInitText(double? weight) =>
    weight != null ? weight.toStringAsFixed(1) : '';

String heightInitText(double? height) =>
    height != null ? height.toStringAsFixed(0) : '';

double? parseWeight(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

double? parseHeight(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

bool isWeightInRange(double weight) => weight > 0.2 && weight <= 350.0;

bool isHeightInRange(double height) => height > 20.0 && height <= 250.0;

bool showPreviousWeight(double? previousWeight) => previousWeight != null;

bool showPreviousHeight(double? previousHeight) => previousHeight != null;

String previousWeightText(String previousLabel, double previousWeight) =>
    '$previousLabel: ${previousWeight.toStringAsFixed(1)} kg';

String previousHeightText(String previousLabel, double previousHeight) =>
    '$previousLabel: ${previousHeight.toStringAsFixed(0)} cm';

String weightErrorMessage({required bool isEs}) => isEs
    ? 'El peso debe estar entre 0.2 kg y 350 kg'
    : 'Weight must be between 0.2 kg and 350 kg';

String heightErrorMessage({required bool isEs}) => isEs
    ? 'La altura debe estar entre 20 cm y 250 cm'
    : 'Height must be between 20 cm and 250 cm';
