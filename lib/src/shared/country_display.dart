// lib/src/shared/country_display.dart

/// How one country is rendered.
class CountryDisplay {
  const CountryDisplay(this.flag, this.nameEs, this.nameEn);

  final String flag;
  final String nameEs;
  final String nameEn;

  String name({required bool isEs}) => isEs ? nameEs : nameEn;
}

const CountryDisplay _globe = CountryDisplay('🌍', 'Otros', 'Other');

/// Reserved nationality code for "another nationality, or unknown".
///
/// The backend stores it as-is and maps what older builds sent for "Otro"
/// (`OTHER`) and an empty code to it: `OTHER` does not fit the 3-character
/// column and made the first sync of such a patient fail with a 500.
const String kUnknownNationalityCode = 'UNK';

const CountryDisplay _unknown = CountryDisplay(
  '🌍',
  'Otra / desconocida',
  'Other / unknown',
);

/// The code to store and send for [code]: `OTHER` and blanks become
/// [kUnknownNationalityCode]; anything else is returned trimmed and
/// upper-cased.
String normalizeNationalityCode(String code) {
  final String key = code.trim().toUpperCase();
  if (key.isEmpty || key == 'OTHER') return kUnknownNationalityCode;
  return key;
}

const Map<String, CountryDisplay> _catalog = <String, CountryDisplay>{
  'COL': CountryDisplay('🇨🇴', 'Colombia', 'Colombia'),
  'VEN': CountryDisplay('🇻🇪', 'Venezuela', 'Venezuela'),
  'ECU': CountryDisplay('🇪🇨', 'Ecuador', 'Ecuador'),
  'HTI': CountryDisplay('🇭🇹', 'Haití', 'Haiti'),
  'PER': CountryDisplay('🇵🇪', 'Perú', 'Peru'),
  'NIC': CountryDisplay('🇳🇮', 'Nicaragua', 'Nicaragua'),
  'CUB': CountryDisplay('🇨🇺', 'Cuba', 'Cuba'),
  kUnknownNationalityCode: _unknown,
};

const List<String> kSupportedNationalityCodes = <String>[
  'COL',
  'VEN',
  'ECU',
  'HTI',
  'PER',
  'NIC',
  'CUB',
  kUnknownNationalityCode,
];

CountryDisplay countryDisplay(String code) => countryDisplayFor(code);

CountryDisplay countryDisplayFor(String code) {
  final String key = normalizeNationalityCode(code);
  if (key == kUnknownNationalityCode) return _unknown;
  return _catalog[key] ?? _globe;
}

CountryDisplay get othersDisplay => _globe;

bool isKnownCountry(String code) =>
    _catalog.containsKey(normalizeNationalityCode(code));
