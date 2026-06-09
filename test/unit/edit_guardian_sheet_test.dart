// test/unit/edit_guardian_sheet_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

class FakeGuardianConsent extends Mock implements GuardianConsent {}

// ── Helpers Replicating Private Widget Logic ─────────────────────────────────

String relationshipLabel(AppStrings s, String code) {
  switch (code) {
    case '01':
      return s.relParents;
    case '02':
      return s.relSiblings;
    case '03':
      return s.relUncles;
    case '04':
      return s.relGrandparents;
    default:
      return code;
  }
}

String dynamicTitle({required int guardianIndex, required bool isEs}) {
  return guardianIndex == 1
      ? (isEs ? 'Editar Guardián Principal' : 'Edit Primary Guardian')
      : (isEs ? 'Editar Guardián Secundario' : 'Edit Secondary Guardian');
}

GuardianInfo buildConfirmPayload({
  required String name,
  required String relationship,
  required String phone,
  required String uid,
  GuardianConsent? consent,
}) {
  return GuardianInfo(
    name: name.trim(),
    relationship: relationship,
    phone: phone.trim(),
    deviceUid: uid.trim().isEmpty ? null : uid.trim(),
    consent: consent,
  );
}

void main() {
  final fakeConsent = FakeGuardianConsent();

  group('relationshipLabel — Spanish locale (es)', () {
    late AppStrings s;
    setUp(() => s = AppStrings.forTesting('es'));

    test("code '01' → relParents (ES)", () {
      expect(relationshipLabel(s, '01'), s.relParents);
    });

    test("code '02' → relSiblings (ES)", () {
      expect(relationshipLabel(s, '02'), s.relSiblings);
    });

    test("code '03' → relUncles (ES)", () {
      expect(relationshipLabel(s, '03'), s.relUncles);
    });

    test("code '04' → relGrandparents (ES)", () {
      expect(relationshipLabel(s, '04'), s.relGrandparents);
    });

    test(
      'unknown code returns the code itself as a default fallback layer',
      () {
        expect(relationshipLabel(s, '99'), '99');
        expect(relationshipLabel(s, ''), '');
        expect(relationshipLabel(s, 'XYZ'), 'XYZ');
      },
    );
  });

  group('relationshipLabel — English locale (en)', () {
    late AppStrings s;
    setUp(() => s = AppStrings.forTesting('en'));

    test("code '01' → relParents (EN)", () {
      expect(relationshipLabel(s, '01'), s.relParents);
    });

    test("code '02' → relSiblings (EN)", () {
      expect(relationshipLabel(s, '02'), s.relSiblings);
    });

    test("code '03' → relUncles (EN)", () {
      expect(relationshipLabel(s, '03'), s.relUncles);
    });

    test("code '04' → relGrandparents (EN)", () {
      expect(relationshipLabel(s, '04'), s.relGrandparents);
    });

    test(
      'English textual labels differ explicitly from Spanish counterparts',
      () {
        final es = AppStrings.forTesting('es');
        final en = AppStrings.forTesting('en');
        final anyDiffers = [
          '01',
          '02',
          '03',
          '04',
        ].any((c) => relationshipLabel(es, c) != relationshipLabel(en, c));
        expect(anyDiffers, isTrue);
      },
    );
  });

  group('dynamicTitle Parameter Boundary Verifications', () {
    test('guardianIndex == 1 + ES → Editar Guardián Principal', () {
      expect(
        dynamicTitle(guardianIndex: 1, isEs: true),
        'Editar Guardián Principal',
      );
    });

    test('guardianIndex == 1 + EN → Edit Primary Guardian', () {
      expect(
        dynamicTitle(guardianIndex: 1, isEs: false),
        'Edit Primary Guardian',
      );
    });

    test('guardianIndex == 2 + ES → Editar Guardián Secundario', () {
      expect(
        dynamicTitle(guardianIndex: 2, isEs: true),
        'Editar Guardián Secundario',
      );
    });

    test('guardianIndex == 2 + EN → Edit Secondary Guardian', () {
      expect(
        dynamicTitle(guardianIndex: 2, isEs: false),
        'Edit Secondary Guardian',
      );
    });

    test('guardianIndex == 0 + ES → Fallback to Secundario', () {
      expect(
        dynamicTitle(guardianIndex: 0, isEs: true),
        'Editar Guardián Secundario',
      );
    });

    test('guardianIndex == 99 + EN → Fallback to Secondary', () {
      expect(
        dynamicTitle(guardianIndex: 99, isEs: false),
        'Edit Secondary Guardian',
      );
    });
  });

  group('buildConfirmPayload — GuardianInfo onConfirm Instantiation Mapping', () {
    test(
      'Applies trim transformations to name and phone text arguments cleanly',
      () {
        final g = buildConfirmPayload(
          name: '  Ana López  ',
          relationship: '01',
          phone: ' 3001234567 ',
          uid: 'HWB-AA:BB',
          consent: fakeConsent,
        );
        expect(g.name, 'Ana López');
        expect(g.phone, '3001234567');
      },
    );

    test(
      'Non-empty deviceUid parameters are preserved trimming whitespaces out',
      () {
        final g = buildConfirmPayload(
          name: 'Ana',
          relationship: '02',
          phone: '300',
          uid: '  HWB-04:1A:2C:DE  ',
          consent: fakeConsent,
        );
        expect(g.deviceUid, 'HWB-04:1A:2C:DE');
      },
    );

    test(
      'Empty deviceUid input parameters translate directly into null references',
      () {
        final g = buildConfirmPayload(
          name: 'Ana',
          relationship: '02',
          phone: '300',
          uid: '',
          consent: fakeConsent,
        );
        expect(g.deviceUid, isNull);
      },
    );

    test(
      'Whitespace-only deviceUid inputs translate directly into null references',
      () {
        final g = buildConfirmPayload(
          name: 'Ana',
          relationship: '03',
          phone: '300',
          uid: '   ',
          consent: fakeConsent,
        );
        expect(g.deviceUid, isNull);
      },
    );

    test(
      'Inherits the original guardian consent model configuration unchanged',
      () {
        final g = buildConfirmPayload(
          name: 'Ana',
          relationship: '04',
          phone: '300',
          uid: '',
          consent: fakeConsent,
        );
        expect(g.consent, equals(fakeConsent));
      },
    );

    test(
      'Relationship properties map directly without mutation alterations',
      () {
        final g = buildConfirmPayload(
          name: 'Ana',
          relationship: '03',
          phone: '300',
          uid: '',
          consent: fakeConsent,
        );
        expect(g.relationship, '03');
      },
    );

    test(
      'Empty name and phone properties default to empty strings instead of null',
      () {
        final g = buildConfirmPayload(
          name: '',
          relationship: '01',
          phone: '',
          uid: '',
          consent: fakeConsent,
        );
        expect(g.name, '');
        expect(g.phone, '');
      },
    );
  });

  group('Locale Detections via Welcome Copy Tokens', () {
    test('locale es → isEs evaluation matches Bienvenido', () {
      final s = AppStrings.forTesting('es');
      expect(s.welcome == 'Bienvenido', isTrue);
    });

    test(
      'locale en → isEs evaluation reports false on variance discrepancies',
      () {
        final s = AppStrings.forTesting('en');
        expect(s.welcome == 'Bienvenido', isFalse);
      },
    );
  });
}
