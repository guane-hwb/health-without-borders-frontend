// test/widget/loss_of_wristband_screen_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

String formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Returns true when field validations pass (all non-optional values present).
bool validateFields({
  required String docNumber,
  required DateTime? dob,
  required String firstName,
  required String lastName,
}) {
  return docNumber.trim().isNotEmpty &&
      dob != null &&
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty;
}

/// Constructs query parameters map for target searchPatient backend endpoint execution.
Map<String, String> buildQueryParams({
  required String documentNumber,
  required DateTime dob,
  required String firstName,
  required String lastName,
  String? guardianName,
}) {
  final params = <String, String>{
    'document_number': documentNumber,
    'birth_date': formatDate(dob),
    'first_name': firstName,
    'last_name': lastName,
  };
  final guardian = guardianName?.trim();
  if (guardian != null && guardian.isNotEmpty) {
    params['guardian_name'] = guardian;
  }
  return params;
}

/// Public mock API response exception structure to prevent type leakage warnings.
class FakeApiException {
  const FakeApiException({required this.statusCode, required this.message});
  final int statusCode;
  final String message;
}

/// Formats network error response into localized screen messages.
String resolveApiError(FakeApiException e, {required String searchNoMatchMsg}) {
  return e.statusCode == 404 ? searchNoMatchMsg : e.message;
}

const String genericErrorMsg =
    'No se pudo completar la búsqueda. Inténtalo de nuevo.';

const _docTypes = {
  'TI': 'TI — Tarjeta de identidad',
  'CC': 'CC — Cédula de ciudadanía',
  'RC': 'RC — Registro civil',
  'CE': 'CE — Cédula de extranjería',
  'PA': 'PA — Pasaporte',
  'PE': 'PE — Permiso especial',
  'PT': 'PT — PPT',
  'MS': 'MS — Menor sin ID',
  'AS': 'AS — Adulto sin ID',
};

const _docTypesShort = {
  'TI': 'TI',
  'CC': 'CC',
  'RC': 'RC',
  'CE': 'CE',
  'PA': 'PA',
  'PE': 'PE',
  'PT': 'PT',
  'MS': 'MS',
  'AS': 'AS',
};

void main() {
  group('formatDate', () {
    test('formats day and month digits with padding zero', () {
      expect(formatDate(DateTime(2024, 3, 5)), '2024-03-05');
    });

    test('formats two-digit month and day without structural changes', () {
      expect(formatDate(DateTime(1990, 11, 25)), '1990-11-25');
    });

    test('formats january 1st successfully', () {
      expect(formatDate(DateTime(2000, 1, 1)), '2000-01-01');
    });

    test('formats december 31st successfully', () {
      expect(formatDate(DateTime(1999, 12, 31)), '1999-12-31');
    });

    test('retains 4 digit year representations completely', () {
      expect(formatDate(DateTime(2024, 6, 15)).startsWith('2024'), isTrue);
    });

    test(
      'string structure matches YYYY-MM-DD strict length size (10 chars)',
      () {
        final result = formatDate(DateTime(2024, 8, 9));
        expect(result.length, 10);
        expect(result[4], '-');
        expect(result[7], '-');
      },
    );
  });

  group('validateFields', () {
    final validDob = DateTime(1990, 3, 20);

    test('all valid data arguments → true', () {
      expect(
        validateFields(
          docNumber: '123456',
          dob: validDob,
          firstName: 'Ana',
          lastName: 'García',
        ),
        isTrue,
      );
    });

    test('empty docNumber → false', () {
      expect(
        validateFields(
          docNumber: '',
          dob: validDob,
          firstName: 'Ana',
          lastName: 'García',
        ),
        isFalse,
      );
    });

    test('whitespace-only docNumber → false', () {
      expect(
        validateFields(
          docNumber: '   ',
          dob: validDob,
          firstName: 'Ana',
          lastName: 'García',
        ),
        isFalse,
      );
    });

    test('null date of birth payload value → false', () {
      expect(
        validateFields(
          docNumber: '123',
          dob: null,
          firstName: 'Ana',
          lastName: 'García',
        ),
        isFalse,
      );
    });

    test('empty firstName → false', () {
      expect(
        validateFields(
          docNumber: '123',
          dob: validDob,
          firstName: '',
          lastName: 'García',
        ),
        isFalse,
      );
    });

    test('whitespace-only firstName → false', () {
      expect(
        validateFields(
          docNumber: '123',
          dob: validDob,
          firstName: '   ',
          lastName: 'García',
        ),
        isFalse,
      );
    });

    test('empty lastName → false', () {
      expect(
        validateFields(
          docNumber: '123',
          dob: validDob,
          firstName: 'Ana',
          lastName: '',
        ),
        isFalse,
      );
    });

    test('whitespace-only lastName → false', () {
      expect(
        validateFields(
          docNumber: '123',
          dob: validDob,
          firstName: 'Ana',
          lastName: '   ',
        ),
        isFalse,
      );
    });

    test('all parameter values missing/empty → false', () {
      expect(
        validateFields(docNumber: '', dob: null, firstName: '', lastName: ''),
        isFalse,
      );
    });

    test(
      'strings containing trailing spaces are trimmed automatically → true',
      () {
        expect(
          validateFields(
            docNumber: ' 123 ',
            dob: validDob,
            firstName: ' Ana ',
            lastName: ' García ',
          ),
          isTrue,
        );
      },
    );
  });

  group('buildQueryParams', () {
    final dob = DateTime(1990, 3, 20);

    test('populates all 4 required query map parameters', () {
      final params = buildQueryParams(
        documentNumber: '123456',
        dob: dob,
        firstName: 'Ana',
        lastName: 'García',
      );
      expect(params['document_number'], '123456');
      expect(params['birth_date'], '1990-03-20');
      expect(params['first_name'], 'Ana');
      expect(params['last_name'], 'García');
    });

    test(
      'birth_date output formatting maps to formatDate execution results',
      () {
        final params = buildQueryParams(
          documentNumber: '1',
          dob: DateTime(2005, 7, 4),
          firstName: 'X',
          lastName: 'Y',
        );
        expect(params['birth_date'], '2005-07-04');
      },
    );

    test('omits guardian_name key parameter when argument is null', () {
      final params = buildQueryParams(
        documentNumber: '1',
        dob: dob,
        firstName: 'X',
        lastName: 'Y',
      );
      expect(params.containsKey('guardian_name'), isFalse);
    });

    test(
      'omits guardian_name key parameter when string is completely empty',
      () {
        final params = buildQueryParams(
          documentNumber: '1',
          dob: dob,
          firstName: 'X',
          lastName: 'Y',
          guardianName: '',
        );
        expect(params.containsKey('guardian_name'), isFalse);
      },
    );

    test(
      'omits guardian_name key parameter when input values are just spaces',
      () {
        final params = buildQueryParams(
          documentNumber: '1',
          dob: dob,
          firstName: 'X',
          lastName: 'Y',
          guardianName: '   ',
        );
        expect(params.containsKey('guardian_name'), isFalse);
      },
    );

    test(
      'includes guardian_name property tracking when payload contents exist',
      () {
        final params = buildQueryParams(
          documentNumber: '1',
          dob: dob,
          firstName: 'X',
          lastName: 'Y',
          guardianName: 'Carlos García',
        );
        expect(params['guardian_name'], 'Carlos García');
      },
    );

    test(
      'guardian_name values are safely stripped of trailing white spaces',
      () {
        final params = buildQueryParams(
          documentNumber: '1',
          dob: dob,
          firstName: 'X',
          lastName: 'Y',
          guardianName: '  Carmen  ',
        );
        expect(params['guardian_name'], 'Carmen');
      },
    );

    test(
      'map tracking sizing structure scales correctly under optional constraints',
      () {
        final withoutGuardian = buildQueryParams(
          documentNumber: '1',
          dob: dob,
          firstName: 'X',
          lastName: 'Y',
        );
        final withGuardian = buildQueryParams(
          documentNumber: '1',
          dob: dob,
          firstName: 'X',
          lastName: 'Y',
          guardianName: 'Tutor',
        );
        expect(withoutGuardian.length, 4);
        expect(withGuardian.length, 5);
      },
    );
  });

  group('resolveApiError', () {
    const noMatchMsg = 'No se encontró ningún paciente con esos datos.';

    test(
      'statusCode 404 returns explicit missing query matching fallback string message',
      () {
        final e = const FakeApiException(statusCode: 404, message: 'Not found');
        expect(resolveApiError(e, searchNoMatchMsg: noMatchMsg), noMatchMsg);
      },
    );

    test(
      'statusCode 401 returns raw message details populated within standard exception instance',
      () {
        final e = const FakeApiException(
          statusCode: 401,
          message: 'Token expirado',
        );
        expect(
          resolveApiError(e, searchNoMatchMsg: noMatchMsg),
          'Token expirado',
        );
      },
    );

    test(
      'statusCode 403 returns original raw internal exception message string payload',
      () {
        final e = const FakeApiException(
          statusCode: 403,
          message: 'No autorizado',
        );
        expect(
          resolveApiError(e, searchNoMatchMsg: noMatchMsg),
          'No autorizado',
        );
      },
    );

    test('statusCode 422 yields validation exception content descriptions', () {
      final e = const FakeApiException(
        statusCode: 422,
        message: 'Validación fallida',
      );
      expect(
        resolveApiError(e, searchNoMatchMsg: noMatchMsg),
        'Validación fallida',
      );
    });

    test('statusCode 500 reports server anomaly trace messages cleanly', () {
      final e = const FakeApiException(
        statusCode: 500,
        message: 'Error interno',
      );
      expect(resolveApiError(e, searchNoMatchMsg: noMatchMsg), 'Error interno');
    });

    test(
      'generic fallback validation checks match hardcoded system expectations',
      () {
        expect(
          genericErrorMsg,
          'No se pudo completar la búsqueda. Inténtalo de nuevo.',
        );
      },
    );
  });

  group('_docTypes', () {
    test('contains all 9 expected structured identifier keys', () {
      expect(_docTypes.keys.toSet(), {
        'TI',
        'CC',
        'RC',
        'CE',
        'PA',
        'PE',
        'PT',
        'MS',
        'AS',
      });
    });

    test(
      'every data map definition entry contains a non-empty description value',
      () {
        for (final entry in _docTypes.entries) {
          expect(
            entry.value.isNotEmpty,
            isTrue,
            reason:
                '${entry.key} definition string tracking is missing value properties',
          );
        }
      },
    );

    test(
      'the expected default TI option exists inside target collection structures',
      () {
        expect(_docTypes.containsKey('TI'), isTrue);
      },
    );
  });

  group('_docTypesShort', () {
    test(
      'contains identical list signatures matching main dictionary index keys',
      () {
        expect(_docTypesShort.keys.toSet(), _docTypes.keys.toSet());
      },
    );

    test(
      'every shorthand token configuration correctly correlates to key value mapping',
      () {
        for (final entry in _docTypesShort.entries) {
          expect(
            entry.key,
            entry.value,
            reason:
                'Short form dictionary values must remain explicitly symmetrical to mapping indexes',
          );
        }
      },
    );
  });

  group(
    'AppStrings.forTesting — Spanish Layout Translation Keys Presence Assertion',
    () {
      late AppStrings s;
      setUp(() => s = AppStrings.forTesting('es'));

      test('searchPatientTitle tracking string value is populated', () {
        expect(s.searchPatientTitle.isNotEmpty, isTrue);
      });

      test('searchSubtitle tracking string value is populated', () {
        expect(s.searchSubtitle.isNotEmpty, isTrue);
      });

      test('searchPrivacyNotice tracking string value is populated', () {
        expect(s.searchPrivacyNotice.isNotEmpty, isTrue);
      });

      test('documentTypeLabel tracking string value is populated', () {
        expect(s.documentTypeLabel.isNotEmpty, isTrue);
      });

      test('documentNumberLabel tracking string value is populated', () {
        expect(s.documentNumberLabel.isNotEmpty, isTrue);
      });

      test('firstNameLabel tracking string value is populated', () {
        expect(s.firstNameLabel.isNotEmpty, isTrue);
      });

      test('lastNameLabel tracking string value is populated', () {
        expect(s.lastNameLabel.isNotEmpty, isTrue);
      });

      test('dobLabel tracking string value is populated', () {
        expect(s.dobLabel.isNotEmpty, isTrue);
      });

      test('guardianNameOptionalLabel tracking string value is populated', () {
        expect(s.guardianNameOptionalLabel.isNotEmpty, isTrue);
      });

      test('guardianHelper tracking string value is populated', () {
        expect(s.guardianHelper.isNotEmpty, isTrue);
      });

      test('minThreeChars tracking string value is populated', () {
        expect(s.minThreeChars.isNotEmpty, isTrue);
      });

      test('searchPatientButton tracking string value is populated', () {
        expect(s.searchPatientButton.isNotEmpty, isTrue);
      });

      test('searchFooterNote tracking string value is populated', () {
        expect(s.searchFooterNote.isNotEmpty, isTrue);
      });

      test('searchNoMatch tracking string value is populated', () {
        expect(s.searchNoMatch.isNotEmpty, isTrue);
      });

      test('searchFieldsRequired tracking string value is populated', () {
        expect(s.searchFieldsRequired.isNotEmpty, isTrue);
      });

      test('firstOrSecondLastName tracking string value is populated', () {
        expect(s.firstOrSecondLastName.isNotEmpty, isTrue);
      });
    },
  );

  group(
    'AppStrings.forTesting — English Layout Translation Keys Presence Assertion',
    () {
      late AppStrings s;
      setUp(() => s = AppStrings.forTesting('en'));

      test(
        'searchPatientTitle evaluates to non-empty parameters under English localization rules',
        () {
          expect(s.searchPatientTitle.isNotEmpty, isTrue);
        },
      );

      test(
        'searchNoMatch evaluates to non-empty parameters under English localization rules',
        () {
          expect(s.searchNoMatch.isNotEmpty, isTrue);
        },
      );

      test(
        'searchFieldsRequired evaluates to non-empty parameters under English localization rules',
        () {
          expect(s.searchFieldsRequired.isNotEmpty, isTrue);
        },
      );

      test(
        'searchPatientButton evaluates to non-empty parameters under English localization rules',
        () {
          expect(s.searchPatientButton.isNotEmpty, isTrue);
        },
      );
    },
  );

  group('AppStrings.forTesting — Multi-locale Discrepancy Validations', () {
    test(
      'searchPatientTitle structures populate valid data across target system configurations',
      () {
        final es = AppStrings.forTesting('es').searchPatientTitle;
        final en = AppStrings.forTesting('en').searchPatientTitle;
        expect(es.isNotEmpty, isTrue);
        expect(en.isNotEmpty, isTrue);
      },
    );

    test(
      'searchFieldsRequired tokens reflect localized dictionary variances',
      () {
        final es = AppStrings.forTesting('es').searchFieldsRequired;
        final en = AppStrings.forTesting('en').searchFieldsRequired;
        expect(es, isNot(equals(en)));
      },
    );

    test(
      'searchNoMatch descriptions reflect localized dictionary variances',
      () {
        final es = AppStrings.forTesting('es').searchNoMatch;
        final en = AppStrings.forTesting('en').searchNoMatch;
        expect(es, isNot(equals(en)));
      },
    );
  });
}
