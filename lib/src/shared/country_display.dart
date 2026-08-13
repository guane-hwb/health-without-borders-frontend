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
  'PER': CountryDisplay('🇵🇪', 'Perú', 'Peru'),
  'HTI': CountryDisplay('🇭🇹', 'Haití', 'Haiti'),
  'CUB': CountryDisplay('🇨🇺', 'Cuba', 'Cuba'),
  'BRA': CountryDisplay('🇧🇷', 'Brasil', 'Brazil'),
  'ARG': CountryDisplay('🇦🇷', 'Argentina', 'Argentina'),
  'CHL': CountryDisplay('🇨🇱', 'Chile', 'Chile'),
  'BOL': CountryDisplay('🇧🇴', 'Bolivia', 'Bolivia'),
  'PAN': CountryDisplay('🇵🇦', 'Panamá', 'Panama'),
  'MEX': CountryDisplay('🇲🇽', 'México', 'Mexico'),
  'DOM': CountryDisplay('🇩🇴', 'República Dominicana', 'Dominican Republic'),
  'NIC': CountryDisplay('🇳🇮', 'Nicaragua', 'Nicaragua'),
  'USA': CountryDisplay('🇺🇸', 'Estados Unidos', 'United States'),
  'ESP': CountryDisplay('🇪🇸', 'España', 'Spain'),
  'UNK': CountryDisplay('🌍', 'Sin registrar', 'Not recorded'),
};

const List<String> kSupportedNationalityCodes = <String>[
  'COL',
  'VEN',
  'ECU',
  'PER',
  'HTI',
  'CUB',
  'BRA',
  'ARG',
  'CHL',
  'BOL',
  'PAN',
  'MEX',
  'DOM',
  'NIC',
  'USA',
  'ESP',
  'UNK',
];

CountryDisplay countryDisplay(String code) => countryDisplayFor(code);

CountryDisplay countryDisplayFor(String code) {
  final String key = code.trim().toUpperCase();
  if (key == 'UNK' || key == 'OTHER' || key.isEmpty) return _unknown;
  return _catalog[key] ?? _globe;
}

CountryDisplay get othersDisplay => _globe;

bool isKnownCountry(String code) =>
    _catalog.containsKey(code.trim().toUpperCase());
