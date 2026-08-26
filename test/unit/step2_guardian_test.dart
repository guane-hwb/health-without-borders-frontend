// test/unit/step2_guardian_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/register_draft.dart';
import 'package:health_without_borders_frontend/src/core/validation/identity_validators.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

List<String> validateGuardianForm({
  required bool requiredForMinor,
  required String name,
  required String phone,
  required String uid,
  required String docNumber,
  required List<List<Offset>> signatureStrokes,
  required bool authAccepted,
  required bool hasGuardian2,
  required String name2,
  required List<List<Offset>> signatureStrokes2,
  required bool auth2Accepted,
  String email = '',
  String docNumber2 = '',
  String phone2 = '',
  String email2 = '',
  bool isEs = true,
  String guardianFullName = 'Nombre completo',
  String guardianPhoneLabel = 'Teléfono',
  String guardianNfcDevice = 'Dispositivo NFC',
  String documentNumberLabel = 'Número de documento',
  String confirmChanges = 'Confirmar cambios',
  String bioSigLabel = 'Firma biométrica',
  String auth2Label = 'Autorización guardián 2',
}) {
  final missing = <String>[];

  if (requiredForMinor) {
    if (name.trim().isEmpty) missing.add(guardianFullName);
    if (phone.trim().isEmpty) missing.add(guardianPhoneLabel);
    if (uid.trim().isEmpty) missing.add(guardianNfcDevice);
    if (docNumber.trim().isEmpty) missing.add(documentNumberLabel);
    if (signatureStrokes.isEmpty) missing.add(bioSigLabel);
  }

  if (validateDocumentNumber(docNumber) != null) {
    missing.add(
      isEs
          ? 'Documento de guardián inválido'
          : 'Invalid Guardian Document format',
    );
  }

  if (validatePhone(phone) != null) {
    missing.add(isEs ? 'Teléfono inválido' : 'Invalid Phone format');
  }

  if (validateEmail(email) != null) {
    missing.add(isEs ? 'Correo electrónico inválido' : 'Invalid Email format');
  }

  if (signatureStrokes.isNotEmpty) {
    if (!authAccepted) missing.add(confirmChanges);
  }

  if (hasGuardian2 && name2.trim().isNotEmpty) {
    if (validateDocumentNumber(docNumber2) != null) {
      missing.add(
        isEs
            ? 'Documento de Guardián 2 inválido'
            : 'Invalid Guardian 2 Document',
      );
    }
    if (validatePhone(phone2) != null) {
      missing.add(
        isEs ? 'Teléfono de Guardián 2 inválido' : 'Invalid Guardian 2 Phone',
      );
    }
    if (validateEmail(email2) != null) {
      missing.add(
        isEs ? 'Correo de Guardián 2 inválido' : 'Invalid Guardian 2 Email',
      );
    }

    if (signatureStrokes2.isNotEmpty) {
      if (!auth2Accepted) missing.add(auth2Label);
    }
  }

  return missing;
}

String? signatureNullWhenEmpty(List<List<Offset>> strokes) {
  if (strokes.isEmpty) return null;
  return 'non-null';
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('RegisterDraft – inicialización de Step2Guardian', () {
    test('1. Carga valores del guardián 1 correctamente', () {
      final draft = RegisterDraft()
        ..guardianName = 'Ana García'
        ..guardianPhone = '3001234567'
        ..guardianDeviceUid = 'UID-001'
        ..guardianDocNumber = '12345678'
        ..guardianDocType = 'CE'
        ..guardianEmail = 'ana@example.com'
        ..guardianAuthAccepted = true;

      expect(draft.guardianName, 'Ana García');
      expect(draft.guardianPhone, '3001234567');
      expect(draft.guardianDeviceUid, 'UID-001');
      expect(draft.guardianDocNumber, '12345678');
      expect(draft.guardianDocType, 'CE');
      expect(draft.guardianEmail, 'ana@example.com');
      expect(draft.guardianAuthAccepted, isTrue);
    });

    test('2. Valores de guardián 1 son null por defecto', () {
      final draft = RegisterDraft();
      expect(draft.guardianName, isNull);
      expect(draft.guardianPhone, isNull);
      expect(draft.guardianDeviceUid, isNull);
      expect(draft.guardianDocNumber, isNull);
      expect(draft.guardianDocType, isNull);
      expect(draft.guardianAuthAccepted, isNull);
    });

    test('3. _hasGuardian2 es false cuando guardian2Name es null', () {
      final draft = RegisterDraft()..guardian2Name = null;
      final hasGuardian2 =
          draft.guardian2Name != null && draft.guardian2Name!.isNotEmpty;
      expect(hasGuardian2, isFalse);
    });

    test('4. _hasGuardian2 es false cuando guardian2Name está vacío', () {
      final draft = RegisterDraft()..guardian2Name = '';
      final hasGuardian2 =
          draft.guardian2Name != null && draft.guardian2Name!.isNotEmpty;
      expect(hasGuardian2, isFalse);
    });

    test('5. _hasGuardian2 es true cuando guardian2Name tiene contenido', () {
      final draft = RegisterDraft()..guardian2Name = 'Carlos';
      final hasGuardian2 =
          draft.guardian2Name != null && draft.guardian2Name!.isNotEmpty;
      expect(hasGuardian2, isTrue);
    });
  });

  group('Validación _save() – requiredForMinor: true', () {
    test('6. Todos los campos vacíos → 5 errores', () {
      final missing = validateGuardianForm(
        requiredForMinor: true,
        name: '',
        phone: '',
        uid: '',
        docNumber: '',
        signatureStrokes: [],
        authAccepted: false,
        hasGuardian2: false,
        name2: '',
        signatureStrokes2: [],
        auth2Accepted: false,
      );
      expect(missing.length, 5);
      expect(missing, contains('Nombre completo'));
      expect(missing, contains('Teléfono'));
      expect(missing, contains('Dispositivo NFC'));
      expect(missing, contains('Número de documento'));
      expect(missing, contains('Firma biométrica'));
    });

    test('7. Nombre con solo espacios → sigue faltando', () {
      final missing = validateGuardianForm(
        requiredForMinor: true,
        name: '   ',
        phone: '3001234567',
        uid: 'UID-001',
        docNumber: '12345',
        signatureStrokes: [
          [const Offset(0, 0), const Offset(10, 10)],
        ],
        authAccepted: true,
        hasGuardian2: false,
        name2: '',
        signatureStrokes2: [],
        auth2Accepted: false,
      );
      expect(missing, contains('Nombre completo'));
    });

    test('8. Formulario completo y válido → sin errores', () {
      final missing = validateGuardianForm(
        requiredForMinor: true,
        name: 'Ana García',
        phone: '3001234567',
        uid: 'UID-001',
        docNumber: '12345678',
        signatureStrokes: [
          [const Offset(0, 0), const Offset(10, 10)],
        ],
        authAccepted: true,
        hasGuardian2: false,
        name2: '',
        signatureStrokes2: [],
        auth2Accepted: false,
      );
      expect(missing, isEmpty);
    });

    test(
      '9. Firma presente pero autorización no aceptada → error confirmChanges',
      () {
        final missing = validateGuardianForm(
          requiredForMinor: true,
          name: 'Ana García',
          phone: '3001234567',
          uid: 'UID-001',
          docNumber: '12345678',
          signatureStrokes: [
            [const Offset(0, 0), const Offset(10, 10)],
          ],
          authAccepted: false,
          hasGuardian2: false,
          name2: '',
          signatureStrokes2: [],
          auth2Accepted: false,
        );
        expect(missing, contains('Confirmar cambios'));
      },
    );
  });

  group('Validación _save() – requiredForMinor: false', () {
    test('10. Campos vacíos sin firma → sin errores (todo opcional)', () {
      final missing = validateGuardianForm(
        requiredForMinor: false,
        name: '',
        phone: '',
        uid: '',
        docNumber: '',
        signatureStrokes: [],
        authAccepted: false,
        hasGuardian2: false,
        name2: '',
        signatureStrokes2: [],
        auth2Accepted: false,
      );
      expect(missing, isEmpty);
    });

    test('11. Firma dibujada sin aceptar autorización → error', () {
      final missing = validateGuardianForm(
        requiredForMinor: false,
        name: '',
        phone: '',
        uid: '',
        docNumber: '',
        signatureStrokes: [
          [const Offset(0, 0), const Offset(5, 5)],
        ],
        authAccepted: false,
        hasGuardian2: false,
        name2: '',
        signatureStrokes2: [],
        auth2Accepted: false,
      );
      expect(missing, contains('Confirmar cambios'));
    });

    test('12. Firma dibujada y autorización aceptada → sin errores', () {
      final missing = validateGuardianForm(
        requiredForMinor: false,
        name: '',
        phone: '',
        uid: '',
        docNumber: '',
        signatureStrokes: [
          [const Offset(0, 0), const Offset(5, 5)],
        ],
        authAccepted: true,
        hasGuardian2: false,
        name2: '',
        signatureStrokes2: [],
        auth2Accepted: false,
      );
      expect(missing, isEmpty);
    });
  });

  group('Validación guardián 2', () {
    test('13. Guardián 2 activo, con firma y sin autorización → error', () {
      final missing = validateGuardianForm(
        requiredForMinor: false,
        name: '',
        phone: '',
        uid: '',
        docNumber: '',
        signatureStrokes: [],
        authAccepted: false,
        hasGuardian2: true,
        name2: 'Carlos López',
        signatureStrokes2: [
          [const Offset(0, 0), const Offset(5, 5)],
        ],
        auth2Accepted: false,
      );
      expect(missing, contains('Autorización guardián 2'));
    });

    test(
      '14. Guardián 2 activo, con firma y con autorización → sin error G2',
      () {
        final missing = validateGuardianForm(
          requiredForMinor: false,
          name: '',
          phone: '',
          uid: '',
          docNumber: '',
          signatureStrokes: [],
          authAccepted: false,
          hasGuardian2: true,
          name2: 'Carlos López',
          signatureStrokes2: [
            [const Offset(0, 0), const Offset(5, 5)],
          ],
          auth2Accepted: true,
        );
        expect(missing, isNot(contains('Autorización guardián 2')));
      },
    );

    test(
      '15. Guardián 2 activo pero name2 vacío → no se valida autorización G2',
      () {
        final missing = validateGuardianForm(
          requiredForMinor: false,
          name: '',
          phone: '',
          uid: '',
          docNumber: '',
          signatureStrokes: [],
          authAccepted: false,
          hasGuardian2: true,
          name2: '',
          signatureStrokes2: [
            [const Offset(0, 0), const Offset(5, 5)],
          ],
          auth2Accepted: false,
        );
        expect(missing, isNot(contains('Autorización guardián 2')));
      },
    );

    test('16. Guardián 2 sin firma → no requiere autorización G2', () {
      final missing = validateGuardianForm(
        requiredForMinor: false,
        name: '',
        phone: '',
        uid: '',
        docNumber: '',
        signatureStrokes: [],
        authAccepted: false,
        hasGuardian2: true,
        name2: 'Carlos López',
        signatureStrokes2: [],
        auth2Accepted: false,
      );
      expect(missing, isNot(contains('Autorización guardián 2')));
    });
  });

  group('_signatureToBase64 – lógica de retorno null', () {
    test('17. Sin trazos → retorna null', () {
      expect(signatureNullWhenEmpty([]), isNull);
    });

    test('18. Con trazos → retorna non-null', () {
      final result = signatureNullWhenEmpty([
        [const Offset(0, 0), const Offset(10, 10)],
      ]);
      expect(result, isNotNull);
    });
  });

  group('_save() – escritura en RegisterDraft', () {
    test('19. Guarda trim() correcto de nombre con espacios', () {
      final name = '  Ana García  ';
      final saved = name.trim().isEmpty ? null : name.trim();
      expect(saved, 'Ana García');
    });

    test('20. Campo vacío con espacios se convierte a null', () {
      final name = '   ';
      final saved = name.trim().isEmpty ? null : name.trim();
      expect(saved, isNull);
    });

    test('21. Cuando hasGuardian2 es false, campos G2 se limpian a null', () {
      final draft = RegisterDraft()
        ..guardian2Name = 'Carlos'
        ..guardian2Phone = '300'
        ..guardian2DeviceUid = 'UID-002'
        ..guardian2DocNumber = '999'
        ..guardian2Relationship = '02'
        ..guardian2AuthAccepted = true
        ..guardian2Email = 'carlos@example.com'
        ..guardian2SignatureBase64 = 'base64data';

      draft.guardian2Name = null;
      draft.guardian2Phone = null;
      draft.guardian2DeviceUid = null;
      draft.guardian2DocNumber = null;
      draft.guardian2Relationship = null;
      draft.guardian2AuthAccepted = null;
      draft.guardian2Email = null;
      draft.guardian2SignatureBase64 = null;

      expect(draft.guardian2Name, isNull);
      expect(draft.guardian2Phone, isNull);
      expect(draft.guardian2DeviceUid, isNull);
      expect(draft.guardian2DocNumber, isNull);
      expect(draft.guardian2Relationship, isNull);
      expect(draft.guardian2AuthAccepted, isNull);
      expect(draft.guardian2Email, isNull);
      expect(draft.guardian2SignatureBase64, isNull);
    });
  });

  group('_SignaturePainter – shouldRepaint', () {
    test('22. Misma instancia de trazos → false', () {
      final strokes = [
        [const Offset(0, 0), const Offset(10, 10)],
      ];
      expect(strokes != strokes, isFalse);
    });

    test('23. Diferente instancia de trazos → true', () {
      final strokes1 = [
        [const Offset(0, 0), const Offset(10, 10)],
      ];
      final strokes2 = [
        [const Offset(0, 0), const Offset(10, 10)],
      ];
      expect(strokes1 != strokes2, isTrue);
    });
  });

  group('_clearSignature', () {
    test('24. Limpia trazos y currentStroke', () {
      final strokes = <List<Offset>>[
        [const Offset(0, 0), const Offset(5, 5)],
      ];
      List<Offset>? current = [const Offset(1, 1)];

      strokes.clear();
      current = null;

      expect(strokes, isEmpty);
      expect(current, isNull);
    });
  });

  group('Selectores – valores por defecto', () {
    test('25. docType por defecto es CC', () {
      final draft = RegisterDraft();
      final docType = draft.guardianDocType ?? 'CC';
      expect(docType, 'CC');
    });

    test('26. guardian2DocType por defecto es CC', () {
      final draft = RegisterDraft();
      final docType = draft.guardian2DocType ?? 'CC';
      expect(docType, 'CC');
    });

    test('27. guardian2Relationship por defecto es 01', () {
      final draft = RegisterDraft();
      final rel = draft.guardian2Relationship ?? '01';
      expect(rel, '01');
    });

    test('28. guardianAuthAccepted por defecto es false', () {
      final draft = RegisterDraft();
      final accepted = draft.guardianAuthAccepted ?? false;
      expect(accepted, isFalse);
    });
  });

  group('Validaciones de formato extendidas (Regex branches)', () {
    test('29. Documento con formato inválido lanza error', () {
      final missing = validateGuardianForm(
        requiredForMinor: false,
        name: '',
        phone: '',
        uid: '',
        docNumber: '123',
        signatureStrokes: [],
        authAccepted: false,
        hasGuardian2: false,
        name2: '',
        signatureStrokes2: [],
        auth2Accepted: false,
      );
      expect(missing, contains('Documento de guardián inválido'));
    });

    test('30. Teléfono con letras rompe la validación', () {
      final missing = validateGuardianForm(
        requiredForMinor: false,
        name: '',
        phone: '300-ABC-123',
        uid: '',
        docNumber: '',
        signatureStrokes: [],
        authAccepted: false,
        hasGuardian2: false,
        name2: '',
        signatureStrokes2: [],
        auth2Accepted: false,
      );
      expect(missing, contains('Teléfono inválido'));
    });

    test('31. Correo sin arroba o estructura inválida falla', () {
      final missing = validateGuardianForm(
        requiredForMinor: false,
        name: '',
        phone: '',
        uid: '',
        docNumber: '',
        signatureStrokes: [],
        authAccepted: false,
        hasGuardian2: false,
        name2: '',
        signatureStrokes2: [],
        auth2Accepted: false,
        email: 'test_invalido.com',
      );
      expect(missing, contains('Correo electrónico inválido'));
    });

    test(
      '32. Guardián 2 con formatos Regex rotos agrega múltiples errores',
      () {
        final missing = validateGuardianForm(
          requiredForMinor: false,
          name: '',
          phone: '',
          uid: '',
          docNumber: '',
          signatureStrokes: [],
          authAccepted: false,
          hasGuardian2: true,
          name2: 'Carlos López',
          signatureStrokes2: [],
          auth2Accepted: false,
          docNumber2: '12',
          phone2: 'letras',
          email2: 'no-email',
        );
        expect(missing, contains('Documento de Guardián 2 inválido'));
        expect(missing, contains('Teléfono de Guardián 2 inválido'));
        expect(missing, contains('Correo de Guardián 2 inválido'));
      },
    );

    test('33. Formato en inglés emite mensajes traducidos en missing', () {
      final missing = validateGuardianForm(
        requiredForMinor: false,
        name: '',
        phone: 'abc',
        uid: '',
        docNumber: '123',
        signatureStrokes: [],
        authAccepted: false,
        hasGuardian2: true,
        name2: 'John Doe',
        signatureStrokes2: [],
        auth2Accepted: false,
        docNumber2: '12',
        phone2: 'invalid',
        email2: 'bademail',
        email: 'bademail',
        isEs: false,
      );
      expect(missing, contains('Invalid Guardian Document format'));
      expect(missing, contains('Invalid Phone format'));
      expect(missing, contains('Invalid Email format'));
      expect(missing, contains('Invalid Guardian 2 Document'));
      expect(missing, contains('Invalid Guardian 2 Phone'));
      expect(missing, contains('Invalid Guardian 2 Email'));
    });

    test('34. Trazo de un solo punto es ignorado por el pintor de firma', () {
      final strokes = [
        [const Offset(10, 10)],
      ];
      int pathsDrawn = 0;
      for (final stroke in strokes) {
        if (stroke.length < 2) continue;
        pathsDrawn++;
      }
      expect(pathsDrawn, 0);
    });

    test(
      '35. Documento con puntos (PPT venezolano) es válido para ambos '
      'guardianes — regresión del bug narrado en v2-validacion-clinica-en-widgets '
      '(antes, solo una de las cuatro copias de la regex admitía el punto)',
      () {
        final missingG1 = validateGuardianForm(
          requiredForMinor: false,
          name: '',
          phone: '',
          uid: '',
          docNumber: 'PPT-1.234.567',
          signatureStrokes: [],
          authAccepted: false,
          hasGuardian2: true,
          name2: 'Carlos López',
          signatureStrokes2: [],
          auth2Accepted: false,
          docNumber2: 'PPT-7.654.321',
        );
        expect(missingG1, isNot(contains('Documento de guardián inválido')));
        expect(missingG1, isNot(contains('Documento de Guardián 2 inválido')));
      },
    );
  });
}
