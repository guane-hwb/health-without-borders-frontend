// lib/src/features/nfc/domain/muac.dart

/// Mid-upper arm circumference (circunferencia media de brazo, CMB) in cm.
///
/// From the Ministry's «Orientaciones para la toma de la circunferencia media
/// de brazo»: for children older than 6 months and younger than 60 months the
/// measure classifies the risk of death associated with malnutrition.
library;

/// Risk level of a measure, as in the Ministry's table.
enum MuacRisk {
  /// ≤ 11.5 cm: high risk. Immediate referral to health services.
  red,

  /// 11.6 – 13.5 cm: risk. Confirm with weight and height and refer.
  yellow,

  /// ≥ 13.6 cm: negative for risk.
  green,
}

/// The range the app accepts. The backend accepts a wider one (0, 50] so a
/// value typed here is never a permanent 422 in the sync queue.
const double muacMinCm = 5.0;
const double muacMaxCm = 30.0;

/// The measure as stored: the tape reads millimetres, so one decimal.
double roundMuac(double cm) => (cm * 10).round() / 10;

/// The risk level of [cm]. The table's bounds are on one decimal (11.5 /
/// 11.6, 13.5 / 13.6), so the value is rounded first and nothing falls in
/// between.
MuacRisk classifyMuac(double cm) {
  final rounded = roundMuac(cm);
  if (rounded <= 11.5) return MuacRisk.red;
  if (rounded <= 13.5) return MuacRisk.yellow;
  return MuacRisk.green;
}

bool isMuacInRange(double cm) => cm >= muacMinCm && cm <= muacMaxCm;

double? parseMuac(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value == null ? null : roundMuac(value);
}

/// Completed months between [dob] and [now], or null if [dob] is later.
int? ageInCompletedMonths(DateTime dob, DateTime now) {
  var months = (now.year - dob.year) * 12 + now.month - dob.month;
  if (now.day < dob.day) months--;
  return months >= 0 ? months : null;
}

/// Whether the table applies: from 6 completed months to 59 completed months.
bool muacApplies(DateTime? dob, DateTime now) {
  if (dob == null) return false;
  final months = ageInCompletedMonths(dob, now);
  return months != null && months >= 6 && months < 60;
}
