// test/unit/patient_profile_helpers_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/core/storage/local_database.dart';
import 'package:health_without_borders_frontend/src/features/auth/domain/user_session.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/patient_profile_helpers.dart';

class _RecordingDb extends LocalDatabase {
  factory _RecordingDb({bool failSave = false}) {
    final Map<String, String> store = <String, String>{};
    return _RecordingDb._(store, failSave);
  }

  _RecordingDb._(Map<String, String> store, this.failSave)
    : super.forTesting(
        forceWeb: true,
        webGet: (String key) async => store[key],
        webSet: (String key, String value) async {
          store[key] = value;
        },
        webRemove: (String key) async {
          store.remove(key);
        },
        webList: (String prefix) async => store.entries
            .where((MapEntry<String, String> e) => e.key.startsWith(prefix))
            .toList(growable: false),
      );

  final bool failSave;
  int saveCalls = 0;
  String? lastOwnerUserId;
  String? lastOrganizationId;

  @override
  Future<void> savePatient(
    PatientFullRecord record, {
    bool isSynced = false,
    String? ownerUserId,
    String? organizationId,
    String? retiredDeviceReason,
  }) async {
    saveCalls++;
    lastOwnerUserId = ownerUserId;
    lastOrganizationId = organizationId;
    if (failSave) throw Exception('Simulated savePatient failure');
  }
}

PatientFullRecord _draft() => PatientFullRecord(
  patientId: 'p-1',
  deviceUid: 'P-UID',
  patientInfo: PatientInfo(
    identification: PatientIdentification(
      documentType: 'CC',
      documentNumber: '123',
    ),
    firstName: 'Juan',
    firstLastName: 'Pérez',
    dob: '2000-01-01',
    biologicalSex: 'M',
    address: Address(city: 'Bogotá', state: 'Bogotá'),
  ),
  guardianInfo: GuardianInfo(name: 'G1', relationship: '01', phone: '123'),
);

void main() {
  group('resavePendingDraft', () {
    test(
      'guarda el borrador con el dueño y la organización del usuario',
      () async {
        final _RecordingDb db = _RecordingDb();
        final UserSession user = UserSession(
          id: 'u-1',
          fullName: 'Doctor Test',
          email: 'doc@test.com',
          role: UserRole.doctor,
          isActive: true,
          organizationId: 'org-1',
        );

        await resavePendingDraft(db, user, _draft());

        expect(db.saveCalls, 1);
        expect(db.lastOwnerUserId, 'u-1');
        expect(db.lastOrganizationId, 'org-1');
      },
    );

    test('sin usuario guarda con dueño y organización nulos', () async {
      final _RecordingDb db = _RecordingDb();

      await resavePendingDraft(db, null, _draft());

      expect(db.saveCalls, 1);
      expect(db.lastOwnerUserId, isNull);
      expect(db.lastOrganizationId, isNull);
    });

    test('si savePatient falla registra el error y no lo propaga', () async {
      final _RecordingDb db = _RecordingDb(failSave: true);

      await expectLater(resavePendingDraft(db, null, _draft()), completes);

      expect(db.saveCalls, 1);
    });
  });
}
