// test/unit/guardian_identity_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/features/nfc/domain/guardian_identity.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

GuardianInfo _g({
  String name = 'María Pérez',
  String? documentNumber,
  String? docNumber,
  String? deviceUid,
}) => GuardianInfo(
  name: name,
  relationship: '01',
  phone: '3000000000',
  documentNumber: documentNumber,
  docNumber: docNumber,
  deviceUid: deviceUid,
);

void main() {
  group('isSameGuardian (mismo criterio que el backend)', () {
    test('el documento decide cuando ambos lo tienen, sin separadores', () {
      expect(
        isSameGuardian(
          _g(documentNumber: 'VZ-9876543'),
          _g(name: 'Otra Persona', docNumber: 'vz 987.6543'),
        ),
        isTrue,
      );
      expect(
        isSameGuardian(
          _g(documentNumber: '1001', deviceUid: 'CARD-1'),
          _g(documentNumber: '1002', deviceUid: 'CARD-1'),
        ),
        isFalse,
      );
    });

    test('sin documento en un lado decide el UID de la tarjeta', () {
      expect(
        isSameGuardian(
          _g(deviceUid: 'CARD-1'),
          _g(name: 'Otro', deviceUid: 'CARD-1'),
        ),
        isTrue,
      );
      expect(
        isSameGuardian(_g(deviceUid: 'CARD-1'), _g(deviceUid: 'CARD-2')),
        isFalse,
      );
    });

    test('sin documento ni tarjeta decide el nombre', () {
      expect(
        isSameGuardian(_g(name: 'María  Pérez '), _g(name: 'maría pérez')),
        isTrue,
      );
      expect(isSameGuardian(_g(name: 'María'), _g(name: 'Carlos')), isFalse);
    });

    test('dos nombres vacíos no son la misma persona', () {
      expect(isSameGuardian(_g(name: ''), _g(name: '  ')), isFalse);
    });
  });
}
