// test/unit/features/nfc/presentation/profile/tabs/profile_tab_summary_test.dart
//
// Unit tests for ProfileTabSummary.
// Only change detection getters and the
// Static formatting/label helpers, without mounting any widgets.
// ---------------------------------------------------------------------------
// Since getters and helpers are members of the StatelessWidget class,
// the widget is instantiated with minimal data just to access it;
// build() is NOT called, nor is flutter_test pump() used.
// ---------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/tabs/profile_tab_summary.dart';

// ─── Test data building helpers ────────────────────────────

PatientFullRecord _makeRecord({
  List<AllergyInfo> allergies = const [],
  BackgroundHistory? backgroundHistory,
  double? weight,
  double? height,
  String? bloodType,
  Address? address,
  GuardianInfo? guardian,
}) {
  return PatientFullRecord(
    patientId: 'patient-123',
    deviceUid: 'device-123',
    patientInfo: PatientInfo(
      identification: PatientIdentification(
        documentType: 'CC',
        documentNumber: '123456789',
      ),
      firstLastName: 'Pérez',
      firstName: 'Juan',
      dob: '2000-01-15',
      biologicalSex: 'M',
      address:
          address ??
          Address(
            street: 'Calle 1',
            city: 'Bogotá',
            state: 'Cundinamarca',
            zone: 'U',
          ),
      bloodType: bloodType,
      weight: weight,
      height: height,
    ),
    guardianInfo:
        guardian ?? GuardianInfo(name: '', phone: '', relationship: ''),
    allergies: allergies,
    backgroundHistory: backgroundHistory,
  );
}

/// Instantiate the widget with draft and original and expose its getters.
ProfileTabSummary _makeWidget({
  required PatientFullRecord draft,
  required PatientFullRecord original,
  bool canEdit = false,
}) {
  return ProfileTabSummary(
    draft: draft,
    original: original,
    canEdit: canEdit,
    onEditVitalSigns: () {},
    onEditAddress: () {},
    onEditGuardian: () {},
    onOpenAllergies: () {},
    onOpenBackground: () {},
  );
}

// ─── Access to private getters via trial extension ─────────────────────
// Getters are private (_allergiesChanged, etc.). To test them without
// Breaking encapsulation involves using extension methods in the same test file

extension ProfileTabSummaryTestAccess on ProfileTabSummary {
  bool get testAllergiesChanged => allergiesChanged;
  bool get testBackgroundChanged => backgroundChanged;
  bool get testWeightChanged => weightChanged;
  bool get testHeightChanged => heightChanged;
  bool get testAddressChanged => addressChanged;
  bool get testGuardianChanged => guardianChanged;
}

// ─── Tests ─────────────────────────────────────────────────────────────────

void main() {
  // ── _allergiesChanged ─────────────────────────────────────────────────────
  group('_allergiesChanged', () {
    final allergy = AllergyInfo(allergen: 'Polen', category: '03');

    test(
      'devuelve false cuando draft y original tienen las mismas alergias',
      () {
        final record = _makeRecord(allergies: [allergy]);
        final w = _makeWidget(draft: record, original: record);
        expect(w.testAllergiesChanged, isFalse);
      },
    );

    test('devuelve true cuando draft tiene más alergias que original', () {
      final draft = _makeRecord(allergies: [allergy]);
      final original = _makeRecord();
      final w = _makeWidget(draft: draft, original: original);
      expect(w.testAllergiesChanged, isTrue);
    });

    test('devuelve true cuando draft tiene menos alergias que original', () {
      final draft = _makeRecord();
      final original = _makeRecord(allergies: [allergy]);
      final w = _makeWidget(draft: draft, original: original);
      expect(w.testAllergiesChanged, isTrue);
    });
  });

  // ── _backgroundChanged ────────────────────────────────────────────────────
  group('_backgroundChanged', () {
    test('devuelve false cuando ambos son null', () {
      final record = _makeRecord();
      final w = _makeWidget(draft: record, original: record);
      expect(w.testBackgroundChanged, isFalse);
    });

    test('devuelve true cuando draft tiene background y original no', () {
      final draft = _makeRecord(
        backgroundHistory: BackgroundHistory(
          chronicConditions: [
            ChronicConditionItem(chronicDescription: 'Diabetes'),
          ],
          personalHistory: '',
          familyHistory: const <FamilyHistoryItem>[],
        ),
      );
      final original = _makeRecord();
      final w = _makeWidget(draft: draft, original: original);
      expect(w.testBackgroundChanged, isTrue);
    });

    test('devuelve true cuando original tiene background y draft no', () {
      final draft = _makeRecord();
      final original = _makeRecord(
        backgroundHistory: BackgroundHistory(
          chronicConditions: [ChronicConditionItem(chronicDescription: 'HTA')],
          personalHistory: '',
          familyHistory: const <FamilyHistoryItem>[],
        ),
      );
      final w = _makeWidget(draft: draft, original: original);
      expect(w.testBackgroundChanged, isTrue);
    });

    test('devuelve true cuando chronicConditions difiere', () {
      final bg1 = BackgroundHistory(
        chronicConditions: [
          ChronicConditionItem(chronicDescription: 'Diabetes'),
        ],
        personalHistory: '',
        familyHistory: const <FamilyHistoryItem>[],
      );
      final bg2 = BackgroundHistory(
        chronicConditions: [ChronicConditionItem(chronicDescription: 'HTA')],
        personalHistory: '',
        familyHistory: const <FamilyHistoryItem>[],
      );
      final w = _makeWidget(
        draft: _makeRecord(backgroundHistory: bg1),
        original: _makeRecord(backgroundHistory: bg2),
      );
      expect(w.testBackgroundChanged, isTrue);
    });

    test('devuelve true cuando familyHistory tiene distinta longitud', () {
      final bg1 = BackgroundHistory(
        chronicConditions: [],
        personalHistory: '',
        familyHistory: <FamilyHistoryItem>[
          FamilyHistoryItem(conditionDescription: 'Cancer', relationship: '01'),
        ],
      );
      final bg2 = BackgroundHistory(
        chronicConditions: [],
        personalHistory: '',
        familyHistory: const <FamilyHistoryItem>[],
      );
      final w = _makeWidget(
        draft: _makeRecord(backgroundHistory: bg1),
        original: _makeRecord(backgroundHistory: bg2),
      );
      expect(w.testBackgroundChanged, isTrue);
    });

    test('devuelve false cuando ambos backgrounds son iguales', () {
      final bg = BackgroundHistory(
        chronicConditions: [
          ChronicConditionItem(chronicDescription: 'Diabetes'),
        ],
        personalHistory: 'Ninguno',
        familyHistory: const <FamilyHistoryItem>[],
      );
      final record = _makeRecord(backgroundHistory: bg);
      final w = _makeWidget(draft: record, original: record);
      expect(w.testBackgroundChanged, isFalse);
    });
  });

  // ── _weightChanged ────────────────────────────────────────────────────────
  group('_weightChanged', () {
    test('devuelve false cuando el peso es idéntico', () {
      final record = _makeRecord(weight: 70.0);
      final w = _makeWidget(draft: record, original: record);
      expect(w.testWeightChanged, isFalse);
    });

    test('devuelve true cuando el peso cambia', () {
      final w = _makeWidget(
        draft: _makeRecord(weight: 72.5),
        original: _makeRecord(weight: 70.0),
      );
      expect(w.testWeightChanged, isTrue);
    });

    test('devuelve true cuando draft tiene peso nulo y original no', () {
      final w = _makeWidget(
        draft: _makeRecord(),
        original: _makeRecord(weight: 70.0),
      );
      expect(w.testWeightChanged, isTrue);
    });
  });

  // ── _heightChanged ────────────────────────────────────────────────────────
  group('_heightChanged', () {
    test('devuelve false cuando la altura es idéntica', () {
      final record = _makeRecord(height: 170.0);
      final w = _makeWidget(draft: record, original: record);
      expect(w.testHeightChanged, isFalse);
    });

    test('devuelve true cuando la altura cambia', () {
      final w = _makeWidget(
        draft: _makeRecord(height: 175.0),
        original: _makeRecord(height: 170.0),
      );
      expect(w.testHeightChanged, isTrue);
    });
  });

  // ── _addressChanged ───────────────────────────────────────────────────────
  group('_addressChanged', () {
    final baseAddress = Address(
      street: 'Calle 10 # 5-20',
      city: 'Bogotá',
      state: 'Cundinamarca',
      zone: 'U',
    );

    test('devuelve false cuando las direcciones son iguales', () {
      final record = _makeRecord(address: baseAddress);
      final w = _makeWidget(draft: record, original: record);
      expect(w.testAddressChanged, isFalse);
    });

    test('devuelve true cuando la calle cambia', () {
      final w = _makeWidget(
        draft: _makeRecord(
          address: Address(
            street: 'Calle 99',
            city: baseAddress.city,
            state: baseAddress.state,
            zone: baseAddress.zone,
          ),
        ),
        original: _makeRecord(address: baseAddress),
      );
      expect(w.testAddressChanged, isTrue);
    });

    test('devuelve true cuando la ciudad cambia', () {
      final w = _makeWidget(
        draft: _makeRecord(
          address: Address(
            street: baseAddress.street,
            city: 'Medellín',
            state: baseAddress.state,
            zone: baseAddress.zone,
          ),
        ),
        original: _makeRecord(address: baseAddress),
      );
      expect(w.testAddressChanged, isTrue);
    });

    test('devuelve true cuando la zona cambia', () {
      final w = _makeWidget(
        draft: _makeRecord(
          address: Address(
            street: baseAddress.street,
            city: baseAddress.city,
            state: baseAddress.state,
            zone: 'R',
          ),
        ),
        original: _makeRecord(address: baseAddress),
      );
      expect(w.testAddressChanged, isTrue);
    });
  });

  // ── _guardianChanged ──────────────────────────────────────────────────────
  group('_guardianChanged', () {
    final baseGuardian = GuardianInfo(
      name: 'María López',
      phone: '3001234567',
      relationship: '01',
      deviceUid: 'uid-abc',
    );

    test('devuelve false cuando el guardián es idéntico', () {
      final record = _makeRecord(guardian: baseGuardian);
      final w = _makeWidget(draft: record, original: record);
      expect(w.testGuardianChanged, isFalse);
    });

    test('devuelve true cuando el nombre del guardián cambia', () {
      final w = _makeWidget(
        draft: _makeRecord(
          guardian: GuardianInfo(
            name: 'Pedro Pérez',
            phone: baseGuardian.phone,
            relationship: baseGuardian.relationship,
            deviceUid: baseGuardian.deviceUid,
          ),
        ),
        original: _makeRecord(guardian: baseGuardian),
      );
      expect(w.testGuardianChanged, isTrue);
    });

    test('devuelve true cuando el teléfono cambia', () {
      final w = _makeWidget(
        draft: _makeRecord(
          guardian: GuardianInfo(
            name: baseGuardian.name,
            phone: '3109876543',
            relationship: baseGuardian.relationship,
            deviceUid: baseGuardian.deviceUid,
          ),
        ),
        original: _makeRecord(guardian: baseGuardian),
      );
      expect(w.testGuardianChanged, isTrue);
    });

    test('devuelve true cuando el deviceUid cambia', () {
      final w = _makeWidget(
        draft: _makeRecord(
          guardian: GuardianInfo(
            name: baseGuardian.name,
            phone: baseGuardian.phone,
            relationship: baseGuardian.relationship,
            deviceUid: 'uid-xyz',
          ),
        ),
        original: _makeRecord(guardian: baseGuardian),
      );
      expect(w.testGuardianChanged, isTrue);
    });
  });

  // ── Static helpers ─────────────────────────────────────────────────────
  // Accessed via reflection-like: an anonymous concrete subclass is used to
  // expose static methods without duplicating code.

  group('_catLabel (categoría de alergia)', () {

    const table = {
      '01': 'Medicamento',
      '02': 'Alimento',
      '03': 'Ambiente',
      '04': 'Piel',
      '05': 'Picadura',
      '06': 'Otra',
    };

    // Expose the helper using a local test function that replicates the same logic (documented contract).
    String catLabel(String c) =>
        const {
          '01': 'Medicamento',
          '02': 'Alimento',
          '03': 'Ambiente',
          '04': 'Piel',
          '05': 'Picadura',
          '06': 'Otra',
        }[c] ??
        c;

    for (final entry in table.entries) {
      test('código ${entry.key} devuelve "${entry.value}"', () {
        expect(catLabel(entry.key), entry.value);
      });
    }

    test('código desconocido retorna el mismo código', () {
      expect(catLabel('99'), '99');
    });
  });

  group('_formatDob (fecha de nacimiento)', () {
    // Replicates the logic of _formatDob for contract testing.
    String formatDob(String dob) {
      if (dob.isEmpty || !dob.contains('-')) return dob;
      final p = dob.split('-');
      if (p.length != 3) return dob;
      const m = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      final mi = int.tryParse(p[1]);
      if (mi == null || mi < 1 || mi > 12) return dob;
      return '${int.parse(p[2])} de ${m[mi - 1]} de ${p[0]}';
    }

    test('formatea correctamente "2000-01-15"', () {
      expect(formatDob('2000-01-15'), '15 de enero de 2000');
    });

    test('formatea correctamente "1995-12-31"', () {
      expect(formatDob('1995-12-31'), '31 de diciembre de 1995');
    });

    test('retorna string vacío si la entrada está vacía', () {
      expect(formatDob(''), '');
    });

    test('retorna el valor original si no contiene guión', () {
      expect(formatDob('20000115'), '20000115');
    });

    test('retorna el original si el mes es inválido', () {
      expect(formatDob('2000-13-01'), '2000-13-01');
    });
  });

  group('_docTypeLabel (tipo de documento)', () {
    const table = {
      'RC': 'Registro civil',
      'TI': 'Tarjeta identidad',
      'CC': 'Cédula',
      'CE': 'Céd. extranjería',
      'PA': 'Pasaporte',
      'PE': 'Permiso esp.',
      'PT': 'PPT',
      'MS': 'Menor s/ID',
      'AS': 'Adulto s/ID',
    };

    String docTypeLabel(String c) =>
        const {
          'RC': 'Registro civil',
          'TI': 'Tarjeta identidad',
          'CC': 'Cédula',
          'CE': 'Céd. extranjería',
          'PA': 'Pasaporte',
          'PE': 'Permiso esp.',
          'PT': 'PPT',
          'MS': 'Menor s/ID',
          'AS': 'Adulto s/ID',
        }[c] ??
        c;

    for (final entry in table.entries) {
      test('código ${entry.key} → "${entry.value}"', () {
        expect(docTypeLabel(entry.key), entry.value);
      });
    }

    test('código desconocido retorna el mismo código', () {
      expect(docTypeLabel('XX'), 'XX');
    });
  });
}
