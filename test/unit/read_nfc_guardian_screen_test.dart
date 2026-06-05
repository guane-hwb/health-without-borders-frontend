// test/unit/read_nfc_guardian_screen_test.dart

import 'package:flutter_test/flutter_test.dart';

class PractitionerInfo {
  final String documentType;
  final String documentNumber;
  final String name;
  PractitionerInfo({
    required this.documentType,
    required this.documentNumber,
    required this.name,
  });
}

class ProviderInfo {
  final String repsCode;
  final String name;
  ProviderInfo({required this.repsCode, required this.name});
}

class MedicalHistoryItem {
  final String startDateTime;
  final String type;
  final PractitionerInfo? practitioner;
  final String? physician;
  final ProviderInfo? provider;
  final String? location;

  MedicalHistoryItem({
    required this.startDateTime,
    this.type = 'Consultation',
    this.practitioner,
    this.physician,
    this.provider,
    this.location,
  });
}

String vDate(dynamic input) {
  String? d;
  if (input is MedicalHistoryItem) {
    d = input.startDateTime;
  } else if (input is String?) {
    d = input;
  }

  if (d == null || d.isEmpty) return 'N/A';
  return d.contains('T') ? d.split('T').first : d;
}

String practitionerName(MedicalHistoryItem? v) {
  if (v == null) return 'N/A';
  if (v.practitioner != null && v.practitioner!.name.isNotEmpty) {
    return v.practitioner!.name;
  }
  if (v.practitioner != null &&
      v.practitioner!.name.isEmpty &&
      v.physician == null) {
    return '';
  }
  return v.physician ?? 'N/A';
}

String provName(MedicalHistoryItem? v) {
  if (v == null) return 'N/A';
  if (v.provider != null) return v.provider!.name;
  return v.location ?? 'N/A';
}

void main() {
  group('ReadNfcGuardianScreen — Clinical Formatting Helpers', () {
    test(
      'vDate should correctly extract only the date by truncating the ISO T timestamp',
      () {
        const timestamp = '2026-06-04T10:31:44Z';
        expect(vDate(timestamp), equals('2026-06-04'));
      },
    );

    test(
      'vDate should return the original string if it does not contain a T separator',
      () {
        const cleanDate = '2025-12-25';
        expect(vDate(cleanDate), equals('2025-12-25'));
      },
    );

    test('vDate should return N/A if the input date is null or empty', () {
      expect(vDate(null), equals('N/A'));
      expect(vDate(''), equals('N/A'));
    });
  });

  MedicalHistoryItem createItem({
    String? practitionerNameValue,
    String? physician,
    String? providerName,
    String? location,
    String? startDateTime,
    String type = 'Consultation',
  }) => MedicalHistoryItem(
    startDateTime: startDateTime ?? '',
    type: type,
    practitioner: practitionerNameValue != null
        ? PractitionerInfo(
            documentType: 'CC',
            documentNumber: '000',
            name: practitionerNameValue,
          )
        : null,
    physician: physician,
    provider: providerName != null
        ? ProviderInfo(repsCode: 'R1', name: providerName)
        : null,
    location: location,
  );

  group('practitionerName', () {
    test('returns "N/A" when the item is null', () {
      expect(practitionerName(null), 'N/A');
    });

    test('returns "N/A" when both practitioner and physician are null', () {
      expect(practitionerName(createItem()), 'N/A');
    });

    test('returns the practitioner name when present', () {
      expect(
        practitionerName(createItem(practitionerNameValue: 'Dr. García')),
        'Dr. García',
      );
    });

    test('returns physician as fallback when practitioner is null', () {
      expect(practitionerName(createItem(physician: 'Dr. Pérez')), 'Dr. Pérez');
    });

    test('prefers practitioner.name over physician when both exist', () {
      expect(
        practitionerName(
          createItem(practitionerNameValue: 'Dr. López', physician: 'Dr. Otro'),
        ),
        'Dr. López',
      );
    });

    test(
      'returns empty string when practitioner.name is empty and physician is null',
      () {
        final item = MedicalHistoryItem(
          startDateTime: '2024-01-01T08:00:00',
          practitioner: PractitionerInfo(
            documentType: 'CC',
            documentNumber: '111',
            name: '',
          ),
        );
        expect(practitionerName(item), '');
      },
    );
  });

  group('_provName', () {
    test('returns "N/A" when the item is null', () {
      expect(provName(null), 'N/A');
    });

    test('returns "N/A" when both provider and location are null', () {
      expect(provName(createItem()), 'N/A');
    });

    test('returns the provider name when present', () {
      expect(
        provName(createItem(providerName: 'Hospital Central')),
        'Hospital Central',
      );
    });

    test('returns location as fallback when provider is null', () {
      expect(provName(createItem(location: 'Clínica Norte')), 'Clínica Norte');
    });

    test('prefers provider.name over location when both exist', () {
      expect(
        provName(createItem(providerName: 'HUV', location: 'Otro')),
        'HUV',
      );
    });
  });

  group('_vDate', () {
    test('returns "N/A" when the item is null', () {
      expect(vDate(null), 'N/A');
    });

    test('returns "N/A" when startDateTime is null', () {
      final item = MedicalHistoryItem(startDateTime: '');
      expect(vDate(item), 'N/A');
    });

    test('returns "N/A" when startDateTime is an empty string', () {
      expect(vDate(createItem(startDateTime: '')), 'N/A');
    });

    test(
      'extracts the date component from an ISO 8601 string containing T',
      () {
        expect(
          vDate(createItem(startDateTime: '2024-06-15T10:30:00')),
          '2024-06-15',
        );
      },
    );

    test(
      'returns the complete string when it does not contain a T separator',
      () {
        expect(vDate(createItem(startDateTime: '2024-06-15')), '2024-06-15');
      },
    );

    test('handles formats containing timezone modifiers after T', () {
      expect(
        vDate(createItem(startDateTime: '2024-03-01T00:00:00+05:00')),
        '2024-03-01',
      );
    });

    test(
      'handles startDateTime strings containing multiple T separators by shifting to the first split',
      () {
        expect(
          vDate(createItem(startDateTime: '2024-01-01T08:00:00T')),
          '2024-01-01',
        );
      },
    );
  });
}
