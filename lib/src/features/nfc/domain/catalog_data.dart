class DiagnosisCatalogItem {
  DiagnosisCatalogItem({
    required this.code,
    required this.description,
    required this.isCommon,
  });

  factory DiagnosisCatalogItem.fromJson(Map<String, dynamic> json) {
    return DiagnosisCatalogItem(
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isCommon: json['is_common'] == true,
    );
  }

  final String code;
  final String description;
  final bool isCommon;
}

class VaccineCatalogItem {
  VaccineCatalogItem({
    required this.code,
    required this.name,
    required this.isActive,
  });

  factory VaccineCatalogItem.fromJson(Map<String, dynamic> json) {
    return VaccineCatalogItem(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }

  final String code;
  final String name;
  final bool isActive;
}

class CatalogData {
  CatalogData({
    required this.diagnoses,
    required this.vaccines,
    required this.version,
  });

  factory CatalogData.fromJson(Map<String, dynamic> json) {
    return CatalogData(
      diagnoses: (json['diagnoses'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  DiagnosisCatalogItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      vaccines: (json['vaccines'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  VaccineCatalogItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      version: json['version']?.toString() ?? 'v1',
    );
  }

  final List<DiagnosisCatalogItem> diagnoses;
  final List<VaccineCatalogItem> vaccines;
  final String version;
}
