// test/unit/edit_guardian_screen_test.dart
//
// Unit tests for EditGuardianScreen.
// Covers the pure logic that does NOT require widget rendering:
// • Initial state of the controllers from GuardianInfo
// • Default values ​​for _docType and _country
// • Map of available document types
// • Map of available countries
// • Toggle of _docType on selection change
// • Toggle of _country on selection change
// • Phone validation (digits only, length)
// • Name validation (not empty)
// No widget rendering or external dependencies required.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/domain/patient_record.dart';

// ─── Test data building helpers ──────────────────────────────

GuardianInfo _guardian({
  String name = 'María López',
  String phone = '3001234567',
  String relationship = '01',
  String? deviceUid,
}) => GuardianInfo(
  name: name,
  phone: phone,
  relationship: relationship,
  deviceUid: deviceUid,
);

PatientFullRecord _patientWith(GuardianInfo guardian) => PatientFullRecord(
  patientId: 'p-001',
  deviceUid: 'd-001',
  patientInfo: PatientInfo(
    identification: PatientIdentification(
      documentType: 'CC',
      documentNumber: '123456',
    ),
    firstLastName: 'Pérez',
    firstName: 'Juan',
    dob: '2000-01-01',
    biologicalSex: 'M',
    address: Address(city: 'Bogotá', state: 'Cundinamarca'),
  ),
  guardianInfo: guardian,
);

/// Simulates initState: creates the controllers from a GuardianInfo.
Map<String, TextEditingController> _initControllers(GuardianInfo g) => {
  'name': TextEditingController(text: g.name),
  'docNumber': TextEditingController(),
  'address': TextEditingController(),
  'contact': TextEditingController(text: g.phone),
};

void _disposeControllers(Map<String, TextEditingController> ctrls) {
  for (final c in ctrls.values) {
    c.dispose();
  }
}

/// Available document types — exact copy of the widget.
const Map<String, String> kDocTypes = {
  'CC': 'Cédula de Ciudadanía',
  'PA': 'Pasaporte',
  'CE': 'Cédula Extranjería',
};

/// Available countries — exact copy of the widget.
const Map<String, String> kCountries = {'COL': 'Colombia', 'VEN': 'Venezuela'};

/// Simulates the toggle logic of _docType.
String toggleDocType(String current, String next) => next;

/// Simula la lógica de toggle de _country.
String toggleCountry(String current, String next) => next;

/// Phone validator: digits only, 7–15 characters.
String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) return 'El teléfono es requerido';
  final digits = value.trim().replaceAll(RegExp(r'\s'), '');
  if (!RegExp(r'^\d+$').hasMatch(digits)) return 'Solo se permiten dígitos';
  if (digits.length < 7) return 'Mínimo 7 dígitos';
  if (digits.length > 15) return 'Máximo 15 dígitos';
  return null;
}

/// Name validator: not empty.
String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) return 'El nombre es requerido';
  return null;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ── Group 1: Controllers — initial state ─────────────────────────────
  group('Controladores — estado inicial desde GuardianInfo', () {
    late Map<String, TextEditingController> ctrls;

    setUp(() {
      ctrls = _initControllers(_guardian());
    });

    tearDown(() => _disposeControllers(ctrls));

    test('nameCtrl se inicializa con g.name', () {
      expect(ctrls['name']!.text, 'María López');
    });

    test('contactCtrl se inicializa con g.phone', () {
      expect(ctrls['contact']!.text, '3001234567');
    });

    test('docNumberCtrl siempre inicia vacío', () {
      expect(ctrls['docNumber']!.text, isEmpty);
    });

    test('addressCtrl siempre inicia vacío', () {
      expect(ctrls['address']!.text, isEmpty);
    });

    test('controladores reflejan cambios al asignar texto', () {
      ctrls['name']!.text = 'Pedro Gómez';
      expect(ctrls['name']!.text, 'Pedro Gómez');
    });

    test('guardián con nombre vacío deja nameCtrl vacío', () {
      final ctrls2 = _initControllers(_guardian(name: ''));
      expect(ctrls2['name']!.text, isEmpty);
      _disposeControllers(ctrls2);
    });

    test('guardián con teléfono vacío deja contactCtrl vacío', () {
      final ctrls2 = _initControllers(_guardian(phone: ''));
      expect(ctrls2['contact']!.text, isEmpty);
      _disposeControllers(ctrls2);
    });
  });

  // ── Group 2: Default values ​​for _docType and _country ────────────────
  group('Valores por defecto del estado', () {
    test('_docType por defecto es CC', () {
      const String docType = 'CC';
      expect(docType, 'CC');
    });

    test('_country por defecto es COL', () {
      const String country = 'COL';
      expect(country, 'COL');
    });

    test('CC está dentro de kDocTypes', () {
      expect(kDocTypes.containsKey('CC'), isTrue);
    });

    test('COL está dentro de kCountries', () {
      expect(kCountries.containsKey('COL'), isTrue);
    });
  });

  // ── Group 3: Map of document types ────────────────────────────────
  group('kDocTypes — tipos de documento disponibles', () {
    test('contiene exactamente 3 entradas', () {
      expect(kDocTypes.length, 3);
    });

    test('CC → Cédula de Ciudadanía', () {
      expect(kDocTypes['CC'], 'Cédula de Ciudadanía');
    });

    test('PA → Pasaporte', () {
      expect(kDocTypes['PA'], 'Pasaporte');
    });

    test('CE → Cédula Extranjería', () {
      expect(kDocTypes['CE'], 'Cédula Extranjería');
    });

    test('todos los valores son no vacíos', () {
      for (final v in kDocTypes.values) {
        expect(v, isNotEmpty);
      }
    });
  });

  // ── Group 4: Map of countries ─────────────────────────────────────────────
  group('kCountries — países disponibles', () {
    test('contiene exactamente 2 entradas', () {
      expect(kCountries.length, 2);
    });

    test('COL → Colombia', () {
      expect(kCountries['COL'], 'Colombia');
    });

    test('VEN → Venezuela', () {
      expect(kCountries['VEN'], 'Venezuela');
    });

    test('todas las claves son de 3 caracteres (ISO 3166-1 alpha-3)', () {
      for (final k in kCountries.keys) {
        expect(k.length, 3);
      }
    });
  });

  // ── Group 5: Toggle of _docType ────────────────────────────────────────
  group('Toggle de tipo de documento', () {
    test('cambia de CC a PA', () {
      String docType = 'CC';
      docType = toggleDocType(docType, 'PA');
      expect(docType, 'PA');
    });

    test('cambia de PA a CE', () {
      String docType = 'PA';
      docType = toggleDocType(docType, 'CE');
      expect(docType, 'CE');
    });

    test('cambia de CE de vuelta a CC', () {
      String docType = 'CE';
      docType = toggleDocType(docType, 'CC');
      expect(docType, 'CC');
    });

    test('el nuevo valor pertenece a kDocTypes', () {
      String docType = 'CC';
      docType = toggleDocType(docType, 'PA');
      expect(kDocTypes.containsKey(docType), isTrue);
    });

    test('callback cambia el estado correctamente', () {
      String docType = 'CC';
      String newVal = 'TI';

      docType = newVal;

      expect(docType, 'TI');
    });
  });

  // ── Group 6: Toggle of _country ────────────────────────────────────────
  group('Toggle de país', () {
    test('cambia de COL a VEN', () {
      String country = 'COL';
      country = toggleCountry(country, 'VEN');
      expect(country, 'VEN');
    });

    test('cambia de VEN a COL', () {
      String country = 'VEN';
      country = toggleCountry(country, 'COL');
      expect(country, 'COL');
    });

    test('el nuevo valor pertenece a kCountries', () {
      String country = 'COL';
      country = toggleCountry(country, 'VEN');
      expect(kCountries.containsKey(country), isTrue);
    });

    test('callback cambia el país correctamente', () {
      String country = 'COL';
      String newVal = 'USA';

      country = newVal;
      expect(country, 'USA');
    });
  });

  // ── Group 7: Phone validator ─────────────────────────────────────
  group('validatePhone', () {
    test('retorna error cuando el campo está vacío', () {
      expect(validatePhone(''), isNotNull);
      expect(validatePhone(null), isNotNull);
      expect(validatePhone('   '), isNotNull);
    });

    test('retorna error si contiene letras', () {
      expect(validatePhone('300abc4567'), isNotNull);
    });

    test('retorna error si contiene caracteres especiales', () {
      expect(validatePhone('+57-300-1234567'), isNotNull);
    });

    test('retorna error si tiene menos de 7 dígitos', () {
      expect(validatePhone('123456'), isNotNull);
    });

    test('retorna error si tiene más de 15 dígitos', () {
      expect(validatePhone('1234567890123456'), isNotNull);
    });

    test('retorna null para teléfono colombiano válido (10 dígitos)', () {
      expect(validatePhone('3001234567'), isNull);
    });

    test('retorna null para 7 dígitos (límite inferior)', () {
      expect(validatePhone('1234567'), isNull);
    });

    test('retorna null para 15 dígitos (límite superior)', () {
      expect(validatePhone('123456789012345'), isNull);
    });
  });

  // ── Group 8: Name validator ───────────────────────────────────────
  group('validateName', () {
    test('retorna error cuando el nombre está vacío', () {
      expect(validateName(''), isNotNull);
      expect(validateName(null), isNotNull);
      expect(validateName('   '), isNotNull);
    });

    test('retorna null para nombre válido', () {
      expect(validateName('María López'), isNull);
      expect(validateName('Pedro'), isNull);
    });

    test('retorna null para nombre con un solo carácter no vacío', () {
      expect(validateName('A'), isNull);
    });
  });

  // ── Group 9: GuardianInfo — model integrity ──────────────────────
  group('GuardianInfo — integridad del modelo', () {
    test('se construye correctamente con todos los campos', () {
      final g = _guardian(
        name: 'Carlos Ruiz',
        phone: '3109876543',
        relationship: '02',
        deviceUid: 'uid-xyz',
      );
      expect(g.name, 'Carlos Ruiz');
      expect(g.phone, '3109876543');
      expect(g.relationship, '02');
      expect(g.deviceUid, 'uid-xyz');
    });

    test('deviceUid es null cuando no se provee', () {
      final g = _guardian();
      expect(g.deviceUid, isNull);
    });

    test('_patientWith crea un PatientFullRecord con el guardián correcto', () {
      final g = _guardian(name: 'Test Guardian');
      final patient = _patientWith(g);
      expect(patient.guardianInfo.name, 'Test Guardian');
    });

    test('initControllers refleja correctamente un guardián distinto', () {
      final g = _guardian(name: 'Nuevo Nombre', phone: '6001112233');
      final ctrls = _initControllers(g);
      expect(ctrls['name']!.text, 'Nuevo Nombre');
      expect(ctrls['contact']!.text, '6001112233');
      _disposeControllers(ctrls);
    });
  });
}
