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

const CountryDisplay _unknown = CountryDisplay(
  '🌍',
  'Sin registrar',
  'Not recorded',
);

const Map<String, CountryDisplay> _catalog = <String, CountryDisplay>{
  'COL': CountryDisplay('🇨🇴', 'Colombia', 'Colombia'),
  'VEN': CountryDisplay('🇻🇪', 'Venezuela', 'Venezuela'),
  'ECU': CountryDisplay('🇪🇨', 'Ecuador', 'Ecuador'),
  'HTI': CountryDisplay('🇭🇹', 'Haití', 'Haiti'),
  'PER': CountryDisplay('🇵🇪', 'Perú', 'Peru'),
  'NIC': CountryDisplay('🇳🇮', 'Nicaragua', 'Nicaragua'),
  'CUB': CountryDisplay('🇨🇺', 'Cuba', 'Cuba'),
  'OTHER': CountryDisplay('🌍', 'Otro', 'Other'),
  'UNK': CountryDisplay('🌍', 'Sin registrar', 'Not recorded'),
};

const List<String> kSupportedNationalityCodes = <String>[
  'COL',
  'VEN',
  'ECU',
  'HTI',
  'PER',
  'NIC',
  'CUB',
  'OTHER',
];

CountryDisplay countryDisplay(String code) => countryDisplayFor(code);

CountryDisplay countryDisplayFor(String code) {
  final String key = code.trim().toUpperCase();
  if (key == 'UNK' || key.isEmpty) return _unknown;
  return _catalog[key] ?? _globe;
}

CountryDisplay get othersDisplay => _globe;

bool isKnownCountry(String code) =>
    _catalog.containsKey(code.trim().toUpperCase());
