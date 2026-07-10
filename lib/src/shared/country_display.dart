// lib/src/shared/country_display.dart
//
// Flag and localized name for an ISO 3166-1 alpha-3 country code.
//
// The patient record stores nationality as alpha-3 ('COL', 'VEN'); the FHIR
// bundle converts to numeric at its own boundary, which never reaches the UI.
// The statistics endpoint echoes the stored code back verbatim, so this is the
// representation the screen has to resolve.
//
// `step3_patient_data.dart` and `edit_patient_screen.dart` each carry their own
// partial copy of this mapping. Unifying them is worthwhile but out of scope
// here; this catalog is a superset of both.

/// How one country is rendered.
class CountryDisplay {
  const CountryDisplay(this.flag, this.nameEs, this.nameEn);

  final String flag;
  final String nameEs;
  final String nameEn;

  String name({required bool isEs}) => isEs ? nameEs : nameEn;
}

/// Shown for a code the catalog does not know, and for the backend's
/// `'UNK'` bucket. The globe deliberately reads as "not a specific country"
/// rather than as a real place.
const CountryDisplay _globe = CountryDisplay('🌍', 'Otros', 'Other');

const CountryDisplay _unknown = CountryDisplay(
  '🌍',
  'Sin registrar',
  'Not recorded',
);

/// Keyed by ISO 3166-1 alpha-3. Covers the nationalities the registration form
/// offers plus the region's other likely origins, so a new dropdown entry does
/// not immediately fall through to the globe.
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
};

/// Resolves an alpha-3 code to its flag and name.
///
/// `'UNK'` — the backend's bucket for patients with no nationality on file —
/// resolves to "not recorded", which is a different statement from "some other
/// country". An unrecognised code falls back to the globe rather than being
/// hidden, so bad data stays visible.
CountryDisplay countryDisplay(String code) {
  final String key = code.trim().toUpperCase();
  if (key == 'UNK' || key.isEmpty) return _unknown;
  return _catalog[key] ?? _globe;
}

/// The row rendered for the `nationalities_others` bucket, which the backend
/// reports as a single truncated count rather than as named countries.
CountryDisplay get othersDisplay => _globe;

/// Whether the catalog knows this code, for callers that want to show the raw
/// value alongside the globe.
bool isKnownCountry(String code) =>
    _catalog.containsKey(code.trim().toUpperCase());
