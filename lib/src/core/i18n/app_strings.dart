/// Lightweight i18n for Health Without Borders.
///
/// Usage in any widget:
///   final s = AppStrings.of(context);
///   Text(s.login)       // → "Iniciar sesión" or "Sign in"
///   Text(s.readNfc)     // → "Leer NFC" or "Read NFC"
///
/// To change locale, call AppLocale.of(context).setLocale('en') from any widget.
library;

import 'package:flutter/material.dart';

// ─── Locale state ───────────────────────────────────────────────────────────

class AppLocale extends InheritedWidget {
  const AppLocale({
    super.key,
    required this.locale,
    required this.setLocale,
    required super.child,
  });

  final String locale; // "es" or "en"
  final void Function(String) setLocale;

  static AppLocale of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppLocale>();
    if (result == null) throw StateError('AppLocale not found');
    return result;
  }

  @override
  bool updateShouldNotify(AppLocale old) => old.locale != locale;
}

// ─── String access ──────────────────────────────────────────────────────────

class AppStrings {
  AppStrings._(this._locale);

  final String _locale;

  static AppStrings of(BuildContext context) {
    return AppStrings._(AppLocale.of(context).locale);
  }

  String _get(String key) => (_locale == 'en' ? _en : _es)[key] ?? key;

  // ── Auth ────────────────────────────────────────────────────────────────
  String get appName => _get('appName');
  String get appSubtitle => _get('appSubtitle');
  String get signIn => _get('signIn');
  String get welcome => _get('welcome');
  String get welcomeSub => _get('welcomeSub');
  String get email => _get('email');
  String get emailHint => _get('emailHint');
  String get password => _get('password');
  String get login => _get('login');
  String get loginFailed => _get('loginFailed');
  String get enterEmailPassword => _get('enterEmailPassword');
  String get forgotPassword => _get('forgotPassword');
  String get noAccount => _get('noAccount');
  String get contactAdmin => _get('contactAdmin');
  String get sessionExpired => _get('sessionExpired');

  // ── Home ────────────────────────────────────────────────────────────────
  String get home => _get('home');
  String get readNfc => _get('readNfc');
  String get readNfcSub => _get('readNfcSub');
  String get registerNfc => _get('registerNfc');
  String get registerNfcSub => _get('registerNfcSub');
  String get syncQueue => _get('syncQueue');
  String get allRecordsSynced => _get('allRecordsSynced');
  String get lossOfWristband => _get('lossOfWristband');
  String get lossOfWristbandSub => _get('lossOfWristbandSub');
  String get brigadeHistory => _get('brigadeHistory');
  String get brigadeHistorySub => _get('brigadeHistorySub');
  String pendingSync(int n) => _get('pendingSync').replaceAll('{n}', '$n');

  // ── Common ──────────────────────────────────────────────────────────────
  String get back => _get('back');
  String get next => _get('next');
  String get continueBtn => _get('continueBtn');
  String get cancel => _get('cancel');
  String get save => _get('save');
  String get search => _get('search');
  String get retry => _get('retry');
  String get delete => _get('delete');
  String get confirm => _get('confirm');
  String get loading => _get('loading');
  String get error => _get('error');
  String get success => _get('success');
  String get noData => _get('noData');

  // ── Register NFC ────────────────────────────────────────────────────────
  String get registerTitle => _get('registerTitle');
  String get scanNewWristband => _get('scanNewWristband');
  String get scanNewWristbandSub => _get('scanNewWristbandSub');
  String get wristbandReady => _get('wristbandReady');
  String get nfcNotAvailable => _get('nfcNotAvailable');
  String get manualUidHint => _get('manualUidHint');
  String get validWristbands => _get('validWristbands');
  String get patientData => _get('patientData');
  String get registrationComplete => _get('registrationComplete');
  String get patientRegistered => _get('patientRegistered');
  String get dataSavedLocally => _get('dataSavedLocally');
  String get wristbandWritten => _get('wristbandWritten');
  String get syncPending => _get('syncPending');
  String get confirmRegistration => _get('confirmRegistration');
  String get reviewData => _get('reviewData');
  String get addConsultation => _get('addConsultation');
  String get addVaccine => _get('addVaccine');
  String get goHome => _get('goHome');
  String get saving => _get('saving');
  String get saveError => _get('saveError');

  // ── Patient form fields ─────────────────────────────────────────────────
  String get identification => _get('identification');
  String get documentType => _get('documentType');
  String get documentNumber => _get('documentNumber');
  String get firstNames => _get('firstNames');
  String get secondName => _get('secondName');
  String get firstLastName => _get('firstLastName');
  String get secondLastName => _get('secondLastName');
  String get gender => _get('gender');
  String get dateOfBirth => _get('dateOfBirth');
  String get nationality => _get('nationality');
  String get origin => _get('origin');
  String get cityRegion => _get('cityRegion');
  String get stateDepartment => _get('stateDepartment');
  String get clinicalData => _get('clinicalData');
  String get bloodType => _get('bloodType');
  String get weight => _get('weight');
  String get height => _get('height');

  // ── Guardian ────────────────────────────────────────────────────────────
  String get guardianSection => _get('guardianSection');
  String get guardianName => _get('guardianName');
  String get relationship => _get('relationship');
  String get guardianPhone => _get('guardianPhone');
  String get guardianPin => _get('guardianPin');

  // ── Read NFC ────────────────────────────────────────────────────────────
  String get scanWristband => _get('scanWristband');
  String get holdWristband => _get('holdWristband');
  String get scanning => _get('scanning');
  String get scanSuccess => _get('scanSuccess');
  String get scanFailed => _get('scanFailed');
  String get guardianRequired => _get('guardianRequired');
  String get guardianRequiredSub => _get('guardianRequiredSub');
  String get scanGuardianWristband => _get('scanGuardianWristband');
  String get continueToRead => _get('continueToRead');
  String get readyToScan => _get('readyToScan');

  // ── Patient detail ──────────────────────────────────────────────────────
  String get patient => _get('patient');
  String get guardian => _get('guardian');
  String get medicalHistory => _get('medicalHistory');
  String get medicalStaff => _get('medicalStaff');
  String get consultations => _get('consultations');
  String get vaccines => _get('vaccines');
  String get allergens => _get('allergens');
  String get showVaccines => _get('showVaccines');
  String get moreDetails => _get('moreDetails');
  String get updatePatient => _get('updatePatient');
  String get lastUpdated => _get('lastUpdated');
  String get chronicCondition => _get('chronicCondition');

  // ── Edit screens ────────────────────────────────────────────────────────
  String get editUpdate => _get('editUpdate');
  String get patientInfoReadOnly => _get('patientInfoReadOnly');
  String get fieldsProtected => _get('fieldsProtected');
  String get editableInfo => _get('editableInfo');
  String get address => _get('address');
  String get street => _get('street');
  String get city => _get('city');
  String get state => _get('state');
  String get name => _get('name');

  // ── Medical history edit ────────────────────────────────────────────────
  String get clinicalEvaluation => _get('clinicalEvaluation');
  String get historyCurrentIllness => _get('historyCurrentIllness');
  String get treatmentPlan => _get('treatmentPlan');
  String get backgroundHistory => _get('backgroundHistory');
  String get chronicConditions => _get('chronicConditions');
  String get personalHistory => _get('personalHistory');
  String get familyHistory => _get('familyHistory');
  String get familyHistoryNotes => _get('familyHistoryNotes');
  String get addFamilyHistory => _get('addFamilyHistory');
  String get condition => _get('condition');
  String get noFamilyHistory => _get('noFamilyHistory');
  String get physicalExam => _get('physicalExam');
  String get generalExam => _get('generalExam');
  String get systemsExam => _get('systemsExam');
  String get add => _get('add');

  // ── Medical staff edit ──────────────────────────────────────────────────
  String get practitioner => _get('practitioner');
  String get healthcareProvider => _get('healthcareProvider');
  String get providerName => _get('providerName');
  String get repsCode => _get('repsCode');
  String get encounter => _get('encounter');
  String get dateTime => _get('dateTime');
  String get diagnosisType => _get('diagnosisType');
  String get careModality => _get('careModality');
  String get dischargeDisposition => _get('dischargeDisposition');

  // ── Loss of wristband ──────────────────────────────────────────────────
  String get searchPatient => _get('searchPatient');
  String get searchRequiredFields => _get('searchRequiredFields');
  String get searchFieldsRequired => _get('searchFieldsRequired');

  // ── Sync ────────────────────────────────────────────────────────────────
  String get syncTitle => _get('syncTitle');
  String get syncAll => _get('syncAll');
  String get syncNow => _get('syncNow');
  String get review => _get('review');
  String get syncedSuccessfully => _get('syncedSuccessfully');
  String get syncFailedRetry => _get('syncFailedRetry');
  String get allSynced => _get('allSynced');
  String get noRecordsPending => _get('noRecordsPending');
  String get deleteRecord => _get('deleteRecord');
  String get deleteRecordConfirm => _get('deleteRecordConfirm');
  String get pending => _get('pending');

  // ── Brigade ─────────────────────────────────────────────────────────────
  String get brigadeOffline => _get('brigadeOffline');
  String get patientsAppearHere => _get('patientsAppearHere');
  String get synchronized => _get('synchronized');
  String get synchronizing => _get('synchronizing');

  // ── NFC Save Flow ──────────────────────────────────────────────────────
  String get putOnWristband => _get('putOnWristband');
  String get placeWristband => _get('placeWristband');
  String get startWriting => _get('startWriting');
  String get syncingServer => _get('syncingServer');
  String get pleaseWait => _get('pleaseWait');
  String get successRegistration => _get('successRegistration');
  String get patientSavedSynced => _get('patientSavedSynced');
  String get syncFailed => _get('syncFailed');

  // ── Vaccine sheet ──────────────────────────────────────────────────────
  String get vaccine => _get('vaccine');
  String get vaccineName => _get('vaccineName');
  String get cvxCode => _get('cvxCode');
  String get dose => _get('dose');
  String get date => _get('date');
  String get administeredBy => _get('administeredBy');
  String get administeredAt => _get('administeredAt');

  // ── Allergen categories ─────────────────────────────────────────────────
  String get allergenMedication => _get('allergenMedication');
  String get allergenFood => _get('allergenFood');
  String get allergenEnvironment => _get('allergenEnvironment');
  String get allergenSkin => _get('allergenSkin');
  String get allergenInsect => _get('allergenInsect');
  String get allergenOther => _get('allergenOther');

  // ══════════════════════════════════════════════════════════════════════════
  // TRANSLATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static const Map<String, String> _es = {
    // Auth
    'appName': 'Health Without Borders',
    'appSubtitle': 'Historia clínica interoperable\npara población migrante',
    'signIn': 'Iniciar sesión',
    'welcome': 'Bienvenido',
    'welcomeSub': 'Accede con tu cuenta institucional',
    'email': 'Correo electrónico',
    'emailHint': 'Ingresa tu correo',
    'password': 'Contraseña',
    'login': 'Iniciar sesión',
    'loginFailed': 'Error al iniciar sesión',
    'enterEmailPassword': 'Ingresa correo y contraseña.',
    'forgotPassword': '¿Olvidó su contraseña?',
    'noAccount': '¿No tiene cuenta?',
    'contactAdmin': 'Contacte a su administrador',
    'sessionExpired': 'Sesión expirada. Inicie sesión nuevamente.',

    // Home
    'home': 'Inicio',
    'readNfc': 'Leer NFC',
    'readNfcSub': 'Escanear manilla del paciente',
    'registerNfc': 'Registrar NFC',
    'registerNfcSub': 'Registrar nuevo paciente',
    'syncQueue': 'Sincronización',
    'allRecordsSynced': 'Todo sincronizado',
    'lossOfWristband': 'Pérdida de manilla',
    'lossOfWristbandSub': 'El paciente perdió la manilla.',
    'brigadeHistory': 'Historial de brigadas',
    'brigadeHistorySub': 'Ver el estado de los pacientes.',
    'pendingSync': '{n} registro(s) pendiente(s)',

    // Common
    'back': 'Atrás',
    'next': 'Siguiente',
    'continueBtn': 'Continuar',
    'cancel': 'Cancelar',
    'save': 'Guardar',
    'search': 'Buscar',
    'retry': 'Reintentar',
    'delete': 'Eliminar',
    'confirm': 'Confirmar',
    'loading': 'Cargando...',
    'error': 'Error',
    'success': 'Éxito',
    'noData': 'Sin datos',

    // Register NFC
    'registerTitle': 'Registrar NFC',
    'scanNewWristband': 'Acerque una manilla nueva',
    'scanNewWristbandSub': 'El sistema verificará que no esté asignada',
    'wristbandReady': 'lista — nueva',
    'nfcNotAvailable': 'NFC no disponible. Use entrada manual.',
    'manualUidHint': 'UID manual (testing)',
    'validWristbands': 'Manillas válidas: NTAG213/215 con prefijo HWB- *',
    'patientData': 'Datos del paciente',
    'registrationComplete': 'Registro completo',
    'patientRegistered': 'Paciente registrado',
    'dataSavedLocally': 'Guardados localmente',
    'wristbandWritten': 'Escrita y sellada',
    'syncPending': 'Pendiente (1 registro)',
    'confirmRegistration': 'Confirmar registro',
    'reviewData': 'Revisar datos',
    'addConsultation': 'Añadir consulta',
    'addVaccine': 'Añadir vacuna',
    'goHome': 'Volver al inicio',
    'saving': 'Guardando...',
    'saveError': 'Error al guardar',

    // Patient form
    'identification': 'Identificación',
    'documentType': 'Tipo de documento',
    'documentNumber': 'Número de documento',
    'firstNames': 'Nombres *',
    'secondName': 'Segundo nombre',
    'firstLastName': 'Primer apellido *',
    'secondLastName': 'Segundo apellido',
    'gender': 'Género *',
    'dateOfBirth': 'Fecha de nacimiento *',
    'nationality': 'Nacionalidad *',
    'origin': 'Procedencia',
    'cityRegion': 'Ciudad / región',
    'stateDepartment': 'Departamento / estado',
    'clinicalData': 'Datos clínicos',
    'bloodType': 'Tipo de sangre',
    'weight': 'Peso (Kg)',
    'height': 'Estatura (cm)',

    // Guardian
    'guardianSection': 'Guardián (menores de 18)',
    'guardianName': 'Nombre del guardián *',
    'relationship': 'Parentesco',
    'guardianPhone': 'Teléfono del guardián *',
    'guardianPin': 'PIN de 4 dígitos del guardián *',

    // Read NFC
    'scanWristband': 'Acerque la manilla al dispositivo',
    'holdWristband': 'Mantenga contacto 2 segundos',
    'scanning': 'Buscando señal NFC...',
    'scanSuccess': '¡Datos leídos correctamente!',
    'scanFailed': 'Lectura fallida',
    'guardianRequired': 'Verificación de guardián requerida',
    'guardianRequiredSub': 'Este paciente es menor de edad. Escanee la manilla del guardián para acceder al registro.',
    'scanGuardianWristband': 'Escanear manilla del guardián',
    'continueToRead': 'Continuar a Leer NFC',
    'readyToScan': 'Listo para escanear',

    // Patient detail
    'patient': 'Paciente',
    'guardian': 'Guardián',
    'medicalHistory': 'Historial médico',
    'medicalStaff': 'Personal médico',
    'consultations': 'Consultas',
    'vaccines': 'Vacunas',
    'allergens': 'Alérgenos',
    'showVaccines': 'Ver vacunas',
    'moreDetails': 'Más detalles',
    'updatePatient': 'Actualizar paciente',
    'lastUpdated': 'Última actualización',
    'chronicCondition': 'Condición crónica',

    // Edit screens
    'editUpdate': 'Editar / actualizar',
    'patientInfoReadOnly': 'Información del paciente (solo lectura)',
    'fieldsProtected': 'Nombre, fecha de nacimiento, sexo, tipo de sangre y documento están protegidos por el backend.',
    'editableInfo': 'Información editable',
    'address': 'Dirección',
    'street': 'Dirección',
    'city': 'Ciudad',
    'state': 'Departamento',
    'name': 'Nombre',

    // Medical history
    'clinicalEvaluation': 'Evaluación clínica',
    'historyCurrentIllness': 'Enfermedad actual',
    'treatmentPlan': 'Plan de tratamiento / observaciones',
    'backgroundHistory': 'Antecedentes',
    'chronicConditions': 'Condiciones crónicas',
    'personalHistory': 'Antecedentes personales',
    'familyHistory': 'Antecedentes familiares',
    'familyHistoryNotes': 'Notas de antecedentes familiares (texto libre)',
    'addFamilyHistory': 'Agregar antecedente familiar',
    'condition': 'Condición',
    'noFamilyHistory': 'Sin antecedentes familiares registrados.',
    'physicalExam': 'Examen físico',
    'generalExam': 'Examen físico general',
    'systemsExam': 'Revisión por sistemas',
    'add': 'Agregar',

    // Medical staff
    'practitioner': 'Profesional de salud',
    'healthcareProvider': 'Prestador de servicios',
    'providerName': 'Nombre del prestador',
    'repsCode': 'Código REPS',
    'encounter': 'Encuentro',
    'dateTime': 'Fecha y hora (ISO 8601)',
    'diagnosisType': 'Tipo de diagnóstico',
    'careModality': 'Modalidad de atención',
    'dischargeDisposition': 'Condición al egreso',

    // Loss of wristband
    'searchPatient': 'Buscar paciente',
    'searchRequiredFields': 'Los cuatro campos son requeridos para buscar.',
    'searchFieldsRequired': 'Número de documento, fecha de nacimiento, nombre y apellido son requeridos.',

    // Sync
    'syncTitle': 'Cola de sincronización',
    'syncAll': 'Sincronizar todo',
    'syncNow': 'Sync ahora',
    'review': 'Revisar',
    'syncedSuccessfully': 'Sincronizado correctamente',
    'syncFailedRetry': 'Sincronización fallida — se reintentará',
    'allSynced': 'Todo sincronizado',
    'noRecordsPending': 'No hay registros pendientes.',
    'deleteRecord': '¿Eliminar registro?',
    'deleteRecordConfirm': 'Esto eliminará permanentemente el registro local. Si no ha sido sincronizado, los datos se perderán.',
    'pending': 'Pendiente',

    // Brigade
    'brigadeOffline': 'Modo brigada — Sin conexión',
    'patientsAppearHere': 'Los pacientes aparecerán aquí al sincronizarse',
    'synchronized': 'Sincronizado',
    'synchronizing': 'Sincronizando',

    // NFC Save Flow
    'putOnWristband': 'Coloque la manilla',
    'placeWristband': 'Acerque la manilla para cargar la información.',
    'startWriting': 'Iniciar escritura',
    'syncingServer': 'Sincronizando con el servidor...',
    'pleaseWait': 'Espere un momento mientras se carga la información.',
    'successRegistration': 'Registro exitoso',
    'patientSavedSynced': 'Paciente guardado localmente y sincronizado',
    'syncFailed': 'Sincronización fallida',

    // Vaccine
    'vaccine': 'Vacuna',
    'vaccineName': 'Nombre de la vacuna',
    'cvxCode': 'Código CVX',
    'dose': 'Dosis',
    'date': 'Fecha',
    'administeredBy': 'Administrada por',
    'administeredAt': 'Administrada en',

    // Allergen categories
    'allergenMedication': 'Medicamento',
    'allergenFood': 'Alimento',
    'allergenEnvironment': 'Sustancia ambiental',
    'allergenSkin': 'Sustancia en piel',
    'allergenInsect': 'Picadura insectos',
    'allergenOther': 'Otra',
  };

  static const Map<String, String> _en = {
    // Auth
    'appName': 'Health Without Borders',
    'appSubtitle': 'Interoperable clinical history\nfor migrant population',
    'signIn': 'Sign in',
    'welcome': 'Welcome',
    'welcomeSub': 'Access with your institutional account',
    'email': 'Email',
    'emailHint': 'Enter your email',
    'password': 'Password',
    'login': 'Login',
    'loginFailed': 'Login failed',
    'enterEmailPassword': 'Please enter email and password.',
    'forgotPassword': 'Forgot your password?',
    'noAccount': "Don't have an account?",
    'contactAdmin': 'Contact your administrator',
    'sessionExpired': 'Session expired. Please log in again.',

    // Home
    'home': 'Home',
    'readNfc': 'Read NFC',
    'readNfcSub': 'Scan patient wristband',
    'registerNfc': 'Register NFC',
    'registerNfcSub': 'Register new patient',
    'syncQueue': 'Sync Queue',
    'allRecordsSynced': 'All records synced',
    'lossOfWristband': 'Loss of wristband',
    'lossOfWristbandSub': 'The patient lost the wristband.',
    'brigadeHistory': 'Brigade History',
    'brigadeHistorySub': "View the patients' status.",
    'pendingSync': '{n} record(s) pending sync',

    // Common
    'back': 'Back',
    'next': 'Next',
    'continueBtn': 'Continue',
    'cancel': 'Cancel',
    'save': 'Save',
    'search': 'Search',
    'retry': 'Retry',
    'delete': 'Delete',
    'confirm': 'Confirm',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'noData': 'No data',

    // Register NFC
    'registerTitle': 'Register NFC',
    'scanNewWristband': 'Bring a new wristband close',
    'scanNewWristbandSub': 'The system will verify it is not assigned',
    'wristbandReady': 'ready — new',
    'nfcNotAvailable': 'NFC not available. Use manual entry.',
    'manualUidHint': 'Manual UID (testing)',
    'validWristbands': 'Valid wristbands: NTAG213/215 with HWB- prefix *',
    'patientData': 'Patient data',
    'registrationComplete': 'Registration complete',
    'patientRegistered': 'Patient registered',
    'dataSavedLocally': 'Saved locally',
    'wristbandWritten': 'Written and sealed',
    'syncPending': 'Pending (1 record)',
    'confirmRegistration': 'Confirm registration',
    'reviewData': 'Review data',
    'addConsultation': 'Add consultation',
    'addVaccine': 'Add vaccine',
    'goHome': 'Go to home',
    'saving': 'Saving...',
    'saveError': 'Error saving',

    // Patient form
    'identification': 'Identification',
    'documentType': 'Document type',
    'documentNumber': 'Document number',
    'firstNames': 'First name *',
    'secondName': 'Second name',
    'firstLastName': 'First last name *',
    'secondLastName': 'Second last name',
    'gender': 'Gender *',
    'dateOfBirth': 'Date of birth *',
    'nationality': 'Nationality *',
    'origin': 'Origin',
    'cityRegion': 'City / region',
    'stateDepartment': 'State / department',
    'clinicalData': 'Clinical data',
    'bloodType': 'Blood type',
    'weight': 'Weight (Kg)',
    'height': 'Height (cm)',

    // Guardian
    'guardianSection': 'Guardian (under 18)',
    'guardianName': 'Guardian name *',
    'relationship': 'Relationship',
    'guardianPhone': 'Guardian phone *',
    'guardianPin': "Guardian's 4-digit PIN *",

    // Read NFC
    'scanWristband': 'Bring the wristband close',
    'holdWristband': 'Hold contact for 2 seconds',
    'scanning': 'Searching NFC signal...',
    'scanSuccess': 'Data read successfully!',
    'scanFailed': 'Scan failed',
    'guardianRequired': 'Guardian verification required',
    'guardianRequiredSub': "This patient is a minor. Please scan the guardian's wristband to access the record.",
    'scanGuardianWristband': 'Scan guardian wristband',
    'continueToRead': 'Continue to Read NFC',
    'readyToScan': 'Ready to scan',

    // Patient detail
    'patient': 'Patient',
    'guardian': 'Guardian',
    'medicalHistory': 'Medical history',
    'medicalStaff': 'Medical staff',
    'consultations': 'Consultations',
    'vaccines': 'Vaccines',
    'allergens': 'Allergens',
    'showVaccines': 'Show vaccines',
    'moreDetails': 'More details',
    'updatePatient': 'Update patient',
    'lastUpdated': 'Last updated',
    'chronicCondition': 'Chronic condition',

    // Edit screens
    'editUpdate': 'Edit / update',
    'patientInfoReadOnly': 'Patient information (read-only)',
    'fieldsProtected': 'Name, DOB, sex, blood type and document are protected by the backend.',
    'editableInfo': 'Editable information',
    'address': 'Address',
    'street': 'Street',
    'city': 'City',
    'state': 'State / Department',
    'name': 'Name',

    // Medical history
    'clinicalEvaluation': 'Clinical evaluation',
    'historyCurrentIllness': 'History of current illness',
    'treatmentPlan': 'Treatment plan / observations',
    'backgroundHistory': 'Background history',
    'chronicConditions': 'Chronic conditions',
    'personalHistory': 'Personal history',
    'familyHistory': 'Family history',
    'familyHistoryNotes': 'Family history notes (free text)',
    'addFamilyHistory': 'Add family history',
    'condition': 'Condition',
    'noFamilyHistory': 'No family history entries yet.',
    'physicalExam': 'Physical examination',
    'generalExam': 'General physical examination',
    'systemsExam': 'Systems examination',
    'add': 'Add',

    // Medical staff
    'practitioner': 'Practitioner',
    'healthcareProvider': 'Healthcare provider',
    'providerName': 'Provider name',
    'repsCode': 'REPS Code',
    'encounter': 'Encounter',
    'dateTime': 'Date & Time (ISO 8601)',
    'diagnosisType': 'Diagnosis type',
    'careModality': 'Care modality',
    'dischargeDisposition': 'Discharge disposition',

    // Loss of wristband
    'searchPatient': 'Search patient',
    'searchRequiredFields': 'All four fields are required to find the patient.',
    'searchFieldsRequired': 'Document number, DOB, first name, and last name are required.',

    // Sync
    'syncTitle': 'Sync Queue',
    'syncAll': 'Sync All',
    'syncNow': 'Sync Now',
    'review': 'Review',
    'syncedSuccessfully': 'Synced successfully',
    'syncFailedRetry': 'Sync failed — will retry',
    'allSynced': 'All records synced',
    'noRecordsPending': 'No pending records to upload.',
    'deleteRecord': 'Delete record?',
    'deleteRecordConfirm': 'This will permanently delete the local record. If it hasn\'t been synced, the data will be lost.',
    'pending': 'Pending',

    // Brigade
    'brigadeOffline': 'Brigade Mode — Offline',
    'patientsAppearHere': 'Patients will appear here as they are synced',
    'synchronized': 'Synchronized',
    'synchronizing': 'Synchronizing',

    // NFC Save Flow
    'putOnWristband': 'Put on the wristband',
    'placeWristband': 'Please place the wristband to load the information.',
    'startWriting': 'Start writing',
    'syncingServer': 'Syncing with server...',
    'pleaseWait': 'Please wait a moment while the information loads.',
    'successRegistration': 'Successful Registration',
    'patientSavedSynced': 'Patient saved locally and synced to cloud',
    'syncFailed': 'Sync Failed',

    // Vaccine
    'vaccine': 'Vaccine',
    'vaccineName': 'Vaccine name',
    'cvxCode': 'CVX Code',
    'dose': 'Dose',
    'date': 'Date',
    'administeredBy': 'Administered by',
    'administeredAt': 'Administered at',

    // Allergen categories
    'allergenMedication': 'Medication',
    'allergenFood': 'Food',
    'allergenEnvironment': 'Environmental substance',
    'allergenSkin': 'Skin substance',
    'allergenInsect': 'Insect sting',
    'allergenOther': 'Other',
  };
}