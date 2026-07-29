/// Lightweight i18n for Health Without Borders.
///
/// Usage in any widget:
///   final s = AppStrings.of(context);
///   Text(s.login)       // → "Iniciar sesión" or "Sign in"
///   Text(s.readNfc)     // → "Leer NFC" or "Read NFC"
///
/// To change locale, call AppLocale.of(context).setLocale('en') from any widget.
library;

// import 'package:flutter/foundation.dart';
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

  @visibleForTesting
  static AppStrings forTesting(String locale) => AppStrings._(locale);

  String _get(String key) => (_locale == 'en' ? _en : _es)[key] ?? key;

  // ── Auth ────────────────────────────────────────────────────────────────
  String get appName => _get('appName');
  String get appSubtitle => _get('appSubtitle');
  String get signIn => _get('signIn');
  String get welcome => _get('welcome');
  String get welcomeSub => _get('welcomeSub');
  String get email => _get('email');
  String get emailHint => _get('emailHint');
  String get emailRequired => _get('emailRequired');
  String get emailInvalid => _get('emailInvalid');
  String get password => _get('password');
  String get passwordRequired => _get('passwordRequired');
  String get passwordTooShort => _get('passwordTooShort');
  String get login => _get('login');
  String get loginFailed => _get('loginFailed');
  String get enterEmailPassword => _get('enterEmailPassword');
  String get forgotPassword => _get('forgotPassword');
  String get forgotPasswordMessage => _get('forgotPasswordMessage');
  String get ok => _get('ok');
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
  String get confirmChanges => _get('confirmChanges');
  String get loading => _get('loading');
  String get error => _get('error');
  String get success => _get('success');
  String get noData => _get('noData');
  String get searchError => _get('searchError');

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
  // New
  String get newPatient => _get('newPatient');
  String get consultationSaved => _get('consultationSaved');
  String get vaccineSaved => _get('vaccineSaved');
  String get today => _get('today');
  // Step 1
  String get patientNfcDevice => _get('patientNfcDevice');
  String get patientNfcDeviceSub => _get('patientNfcDeviceSub');
  String get nfcUidRequired => _get('nfcUidRequired');

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
  String get guardianDocType => _get('guardianDocType');
  String get guardianDocNumber => _get('guardianDocNumber');
  String get guardianAuthAccepted => _get('guardianAuthAccepted');
  String get guardianEmail => _get('guardianEmail');
  // Edit guardian sheet
  String get editGuardianTitle => _get('editGuardianTitle');
  String get guardianFullName => _get('guardianFullName');
  String get guardianFullNameHint => _get('guardianFullNameHint');
  String get guardianRelationship => _get('guardianRelationship');
  String get guardianPhoneLabel => _get('guardianPhoneLabel');
  String get guardianPhoneHint => _get('guardianPhoneHint');
  String get guardianNfcDevice => _get('guardianNfcDevice');
  String get guardianNfcUidHint => _get('guardianNfcUidHint');
  String get guardianNfcUnavailable => _get('guardianNfcUnavailable');
  String get guardianNfcError => _get('guardianNfcError');
  String get relParents => _get('relParents');
  String get relSiblings => _get('relSiblings');
  String get relUncles => _get('relUncles');
  String get relGrandparents => _get('relGrandparents');

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

  // ── Edit address sheet ──────────────────────────────────────────────────
  String get editResidence => _get('editResidence');
  String get addressZoneSubtitle => _get('addressZoneSubtitle');
  String get municipality => _get('municipality');
  String get department => _get('department');
  String get zone => _get('zone');
  String get streetHint => _get('streetHint');
  String get cityHint => _get('cityHint');
  String get stateHint => _get('stateHint');
  String get zoneUrban => _get('zoneUrban');
  String get zoneRural => _get('zoneRural');

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

  // ── Vital signs sheet ──────────────────────────────────────────────────
  String get editMeasurements => _get('editMeasurements');
  String get weightKg => _get('weightKg');
  String get heightCm => _get('heightCm');
  String get previous => _get('previous');
  String get bloodTypeReadOnly => _get('bloodTypeReadOnly');

  // ── Allergen categories ─────────────────────────────────────────────────
  String get allergenMedication => _get('allergenMedication');
  String get allergenFood => _get('allergenFood');
  String get allergenEnvironment => _get('allergenEnvironment');
  String get allergenSkin => _get('allergenSkin');
  String get allergenInsect => _get('allergenInsect');
  String get allergenOther => _get('allergenOther');

  // ── Login screen v2 / Home v2 ──────────────────────────────────────
  String get appSubtitleShort => _get('appSubtitleShort');
  String get emailLabel => _get('emailLabel');
  String get passwordLabel => _get('passwordLabel');
  String get rememberSession => _get('rememberSession');
  String get sessionEncryptedFooter => _get('sessionEncryptedFooter');
  String get goodMorning => _get('goodMorning');
  String get goodAfternoon => _get('goodAfternoon');
  String get goodEvening => _get('goodEvening');
  String get logout => _get('logout');
  String get logoutTitle => _get('logoutTitle');
  String logoutConfirm(String name) =>
      _get('logoutConfirm').replaceAll('{name}', name);
  String get roleDoctor => _get('roleDoctor');
  String get roleNurse => _get('roleNurse');
  String get roleOrgAdmin => _get('roleOrgAdmin');
  String get roleSuperadmin => _get('roleSuperadmin');
  String get offline => _get('offline');

  // Home actions v2 ─────────────────────────────────────────────────────
  String get actionReadNfc => _get('actionReadNfc');
  String get actionReadNfcSub => _get('actionReadNfcSub');
  String get actionNewPatient => _get('actionNewPatient');
  String get actionNewPatientSub => _get('actionNewPatientSub');
  String get actionSearchPatient => _get('actionSearchPatient');
  String get actionSearchPatientSub => _get('actionSearchPatientSub');
  String get actionSearchPatientSubAdmin => _get('actionSearchPatientSubAdmin');
  String get actionPendingSync => _get('actionPendingSync');
  String get actionPendingSyncEmpty => _get('actionPendingSyncEmpty');
  String actionPendingSyncCount(int n) =>
      _get('actionPendingSyncCount').replaceAll('{n}', '$n');
  // Admin v2 ─────────────────────────────────────────────────────────────
  String get kpiUsers => _get('kpiUsers');
  String get kpiSyncedOk => _get('kpiSyncedOk');
  String get adminManageUsers => _get('adminManageUsers');
  String get adminManageUsersSub => _get('adminManageUsersSub');
  String get adminViewPatients => _get('adminViewPatients');
  String get adminViewPatientsSub => _get('adminViewPatientsSub');
  String adminBrigadeHistorySub(int n) =>
      _get('adminBrigadeHistorySub').replaceAll('{n}', '$n');

  // Read NFC v2────────────────────────────────────────────────────────────
  String get readWristbandTitle => _get('readWristbandTitle');
  String get scanGuardianTitle => _get('scanGuardianTitle');
  String get scanPatientHeadline => _get('scanPatientHeadline');
  String get scanPatientHint => _get('scanPatientHint');
  String get scanGuardianHeadline => _get('scanGuardianHeadline');
  String get patientWristbandReady => _get('patientWristbandReady');
  String get nfcNotAvailableHint => _get('nfcNotAvailableHint');
  String get manualPatientUidLabel => _get('manualPatientUidLabel');
  String get manualPatientUidHint => _get('manualPatientUidHint');
  String get manualGuardianUidLabel => _get('manualGuardianUidLabel');
  String get manualGuardianUidHint => _get('manualGuardianUidHint');
  String get useManualUid => _get('useManualUid');

  // Search v2 ──────────────────────────────────────────────────────────────
  String get searchPatientTitle => _get('searchPatientTitle');
  String get searchSubtitle => _get('searchSubtitle');
  String get searchPrivacyNotice => _get('searchPrivacyNotice');
  String get documentTypeLabel => _get('documentTypeLabel');
  String get documentNumberLabel => _get('documentNumberLabel');
  String get firstNameLabel => _get('firstNameLabel');
  String get lastNameLabel => _get('lastNameLabel');
  String get firstOrSecondLastName => _get('firstOrSecondLastName');
  String get dobLabel => _get('dobLabel');
  String get guardianNameOptionalLabel => _get('guardianNameOptionalLabel');
  String get guardianHelper => _get('guardianHelper');
  String get minThreeChars => _get('minThreeChars');
  String get searchPatientButton => _get('searchPatientButton');
  String get searchFooterNote => _get('searchFooterNote');
  String get searchNoMatch => _get('searchNoMatch');

  // ── Patient profile screen ──────────────────────────────────────────────
  String get unsyncedChanges => _get('unsyncedChanges');
  String get synced => _get('synced');
  String get syncedAt => _get('syncedAt');
  String get syncingBtn => _get('syncingBtn');
  String get syncBtn => _get('syncBtn');
  String get savedChangesMsg => _get('savedChangesMsg');
  String get notAuthorizedConsultations => _get('notAuthorizedConsultations');
  String get unsyncedChangesTitle => _get('unsyncedChangesTitle');
  String get exitWithoutSyncMsg => _get('exitWithoutSyncMsg');
  String get exit => _get('exit');
  String get tabSummary => _get('tabSummary');
  String get yearsOldSuffix => _get('yearsOldSuffix');
  String get noAllergiesRegistered => _get('noAllergiesRegistered');
  String get addAllergyBtn => _get('addAllergyBtn');

  // Add allergy sheet ─────────────────────────────────────────────────────
  String get allergyCategoryLabel => _get('allergyCategoryLabel');
  String get allergenLabel => _get('allergenLabel');
  String get allergenHint => _get('allergenHint');
  String get reactionOptionalLabel => _get('reactionOptionalLabel');
  String get reactionHint => _get('reactionHint');
  String get allergiesSheetTitle => _get('allergiesSheetTitle');
  String get backgroundSheetTitle => _get('backgroundSheetTitle');
  String get noChronicConditions => _get('noChronicConditions');

  // Add chronic condition sheet ───────────────────────────────────────────
  String get addChronicConditionTitle => _get('addChronicConditionTitle');
  String get chronicConditionHint => _get('chronicConditionHint');
  String get noMedications => _get('noMedications');
  String get medications => _get('medications');
  String get personalHistoryTitle => _get('personalHistoryTitle');
  String get noFamilyHistoryEntries => _get('noFamilyHistoryEntries');
  String get reactionLabel => _get('reactionLabel');
  String get sexMale => _get('sexMale');
  String get sexFemale => _get('sexFemale');
  String get sexIndeterminate => _get('sexIndeterminate');
  String get docTypeRC => _get('docTypeRC');
  String get docTypeTI => _get('docTypeTI');
  String get docTypeCC => _get('docTypeCC');
  String get docTypeCE => _get('docTypeCE');
  String get docTypePA => _get('docTypePA');
  String get docTypePE => _get('docTypePE');
  String get docTypePT => _get('docTypePT');
  String get docTypeMS => _get('docTypeMS');
  String get docTypeAS => _get('docTypeAS');
  String get medStatusActive => _get('medStatusActive');
  String get medStatusCompleted => _get('medStatusCompleted');
  String get medStatusStopped => _get('medStatusStopped');
  String get medStatusUnknown => _get('medStatusUnknown');
  String get cie10Label => _get('cie10Label');

  // ── Add medication sheet ─────────────────────────────────────────────────
  String get addMedicationTitle => _get('addMedicationTitle');
  String get addMedicationSubtitle => _get('addMedicationSubtitle');
  String get medicationLabel => _get('medicationLabel');
  String get medicationHint => _get('medicationHint');
  String get statusLabel => _get('statusLabel');
  String get dosageLabel => _get('dosageLabel');
  String get dosageHint => _get('dosageHint');
  String get notesLabel => _get('notesLabel');
  String get notesHint => _get('notesHint');

  // ── Edit chronic / personal sheet ────────────────────────────────────────
  String get editChronicPersonalHint => _get('editChronicPersonalHint');

  // ── Allergies tab ────────────────────────────────────────────────────────
  String allergiesHeader(int n) =>
      _get('allergiesHeader').replaceAll('{n}', '$n');
  String get reactionHeader => _get('reactionHeader');
  String get allergyShortMedication => _get('allergyShortMedication');
  String get allergyShortFood => _get('allergyShortFood');
  String get allergyShortEnvironment => _get('allergyShortEnvironment');
  String get allergyShortSkin => _get('allergyShortSkin');
  String get allergyShortInsect => _get('allergyShortInsect');
  String get allergyShortOther => _get('allergyShortOther');

  // ── Summary tab ────────────────────────────────────────────────────────
  String get personalTitle => _get('personalTitle');
  String get chronic => _get('chronic');
  String get family => _get('family');
  String get recordsLabel => _get('recordsLabel');

  // ── Consultations View & Detail ─────────────────────────────────────────
  String get consultationsTabTitle => _get('consultationsTabTitle');
  String get noConsultationsRegistered => _get('noConsultationsRegistered');
  String get addConsultationButton => _get('addConsultationButton');
  String get viewDetailHint => _get('viewDetailHint');
  String get consultationDetailTitle => _get('consultationDetailTitle');
  String get careContextSection => _get('careContextSection');
  String get startDateLabel => _get('startDateLabel');
  String get endDateLabel => _get('endDateLabel');
  String get serviceGroupLabel => _get('serviceGroupLabel');
  String get environmentLabel => _get('environmentLabel');
  String get entryRouteLabel => _get('entryRouteLabel');
  String get externalCauseLabel => _get('externalCauseLabel');
  String get docLabelShort => _get('docLabelShort');
  String get diagnosisTitle => _get('diagnosisTitle');
  String get dischargeSection => _get('dischargeSection');
  String get riskFactorsSection => _get('riskFactorsSection');
  String get incapacitySection => _get('incapacitySection');
  String get incapacityScope => _get('incapacityScope');
  String get incapacityDays => _get('incapacityDays');
  String get payerSection => _get('payerSection');
  String get codeLabel => _get('codeLabel');

  // Days & Months Short ─────────────────────────────────────────────────
  String get dayLun => _get('dayLun');
  String get dayMar => _get('dayMar');
  String get dayMie => _get('dayMie');
  String get dayJue => _get('dayJue');
  String get dayVie => _get('dayVie');
  String get daySab => _get('daySab');
  String get dayDom => _get('dayDom');
  String get monEne => _get('monEne');
  String get monFeb => _get('monFeb');
  String get monMarString => _get('monMar');
  String get monMar => _get('monMar');
  String get monAbr => _get('monAbr');
  String get monMay => _get('monMay');
  String get monJun => _get('monJun');
  String get monJul => _get('monJul');
  String get monAgo => _get('monAgo');
  String get monSep => _get('monSep');
  String get monOct => _get('monOct');
  String get monNov => _get('monNov');
  String get monDic => _get('monDic');
  String get timeAm => _get('timeAm');
  String get timePm => _get('timePm');

  // Care Modality Labels ─────────────────────────────────────────────────
  String get modIntramural => _get('modIntramural');
  String get modExtramuralMobil => _get('modExtramuralMobil');
  String get modDomiciliaria => _get('modDomiciliaria');
  String get modJornada => _get('modJornada');
  String get modPrehospitalaria => _get('modPrehospitalaria');
  String get modTelemedicinaInteractiva => _get('modTelemedicinaInteractiva');
  String get modNoInteractiva => _get('modNoInteractiva');
  String get modTelexperticia => _get('modTelexperticia');
  String get modTelemonitoreo => _get('modTelemonitoreo');

  // Service Group Labels
  String get sgConsultaExterna => _get('sgConsultaExterna');
  String get sgApoyoDiagnostico => _get('sgApoyoDiagnostico');
  String get sgInternacion => _get('sgInternacion');
  String get sgQuirurgico => _get('sgQuirurgico');
  String get sgAtencionInmediata => _get('sgAtencionInmediata');

  // Care Environment Labels ─────────────────────────────────────────────────
  String get ceHogar => _get('ceHogar');
  String get ceComunitario => _get('ceComunitario');
  String get ceEscolar => _get('ceEscolar');
  String get ceLaboral => _get('ceLaboral');
  String get ceInstitucional => _get('ceInstitucional');

  // Diagnosis Type Labels ────────────────────────────────────────────────────
  String get dtImpresion => _get('dtImpresion');
  String get dtConfirmadoNuevo => _get('dtConfirmadoNuevo');
  String get dtConfirmadoRepetido => _get('dtConfirmadoRepetido');

  // Discharge Disposition Labels ─────────────────────────────────────────────
  String get ddAltaVoluntaria => _get('ddAltaVoluntaria');
  String get ddFallecido => _get('ddFallecido');
  String get ddRemitido => _get('ddRemitido');
  String get ddAltaMedica => _get('ddAltaMedica');

  // ── Vaccines tab ────────────────────────────────────────────────────────
  String get vaccineSchemeTitle => _get('vaccineSchemeTitle');
  String get vaccineLabelSingle => _get('vaccineLabelSingle');
  String get vaccineLabelPlural => _get('vaccineLabelPlural');
  String get noVaccinesRegistered => _get('noVaccinesRegistered');
  String get addVaccineButton => _get('addVaccineButton');
  String get doseLabel => _get('doseLabel');

  // ── Admin Manage Users ──────────────────────────────────────────────────
  String get manageUsersTitle => _get('manageUsersTitle');
  String get filterAll => _get('filterAll');
  String get filterDoctors => _get('filterDoctors');
  String get filterNurse => _get('filterNurse');
  String get filterCoord => _get('filterCoord');
  String get noUsersInFilter => _get('noUsersInFilter');
  String get createUserTitle => _get('createUserTitle');
  String get userStatusActive => _get('userStatusActive');
  String get userStatusSuspended => _get('userStatusSuspended');
  String get userDetailOrganization => _get('userDetailOrganization');
  String get userDetailStatus => _get('userDetailStatus');
  String get userFormFullNameLabel => _get('userFormFullNameLabel');
  String get userFormEmailLabel => _get('userFormEmailLabel');
  String get userFormPasswordLabel => _get('userFormPasswordLabel');
  String get userFormRoleLabel => _get('userFormRoleLabel');
  String get userFormRequiredFieldsError => _get('userFormRequiredFieldsError');
  String get userFormCreatingStatus => _get('userFormCreatingStatus');
  String get userFormCreateButton => _get('userFormCreateButton');
  String get deletUser => _get('deletUser');
  String get deleting => _get('deleting');
  String get permanentlyDelete => _get('permanentlyDelete');
  String get userFormValidationError => _get('userFormValidationError');

  // ── Super Admin User ──────────────────────────────────────────────────
  String get manageOrgsTitle => _get('manageOrgsTitle');
  String get manageOrgsSubtitle => _get('manageOrgsSubtitle');
  String get brigadeStatsTitle => _get('brigadeStatsTitle');
  String get brigadeStatsSubtitle => _get('brigadeStatsSubtitle');
  String get statsScreenTitle => _get('statsScreenTitle');
  String get statsTotalPatients => _get('statsTotalPatients');
  String get statsTotalVaccines => _get('statsTotalVaccines');
  String get statsTotalAllergies => _get('statsTotalAllergies');
  String get statsMinorsPercentage => _get('statsMinorsPercentage');
  String get statsVaccineDistribution => _get('statsVaccineDistribution');
  String get statsAllergyDistribution => _get('statsAllergyDistribution');
  String get statsNationalityDistribution =>
      _get('statsNationalityDistribution');
  String get statsScreenTitleOrg => _get('statsScreenTitleOrg');
  String get statsFilterAll => _get('statsFilterAll');
  String get statsTotalEncounters => _get('statsTotalEncounters');
  String get statsEmpty => _get('statsEmpty');
  String get statsOfflineHint => _get('statsOfflineHint');
  String get statsForbidden => _get('statsForbidden');
  String get statsRangeAll => _get('statsRangeAll');
  String get statsRangeThisMonth => _get('statsRangeThisMonth');
  String get statsRangeLast30 => _get('statsRangeLast30');
  String get statsRangeCustom => _get('statsRangeCustom');
  String get manageOrgsScreenTitle => _get('manageOrgsScreenTitle');
  String get orgsNoOrganizations => _get('orgsNoOrganizations');
  String get orgsCreateOrgTitle => _get('orgsCreateOrgTitle');
  String get orgsStepBasicData => _get('orgsStepBasicData');
  String get orgsStepAdminUser => _get('orgsStepAdminUser');
  String get orgsStepSummary => _get('orgsStepSummary');
  String get orgsFieldNameLabel => _get('orgsFieldNameLabel');
  String get orgsFieldEmailLabel => _get('orgsFieldEmailLabel');
  String get orgsFieldAdminNameLabel => _get('orgsFieldAdminNameLabel');
  String get orgsFieldAdminEmailLabel => _get('orgsFieldAdminEmailLabel');
  String get orgsFieldAdminPassLabel => _get('orgsFieldAdminPassLabel');
  String get orgsSummarySubtitle => _get('orgsSummarySubtitle');
  String get orgsLabelOrganization => _get('orgsLabelOrganization');
  String get orgsLabelOfficialEmail => _get('orgsLabelOfficialEmail');
  String get orgsLabelAdministrator => _get('orgsLabelAdministrator');
  String get orgsLabelAdminEmail => _get('orgsLabelAdminEmail');
  String get orgsLabelProvisionalPass => _get('orgsLabelProvisionalPass');
  String get step => _get('step');
  String get labelNameAdmin => _get('labelNameAdmin');
  String get orgDetailTitle => _get('orgDetailTitle');
  String get orgDetailId => _get('orgDetailId');
  String get orgDeleteButton => _get('orgDeleteButton');
  String get orgDeleteDialogTitle => _get('orgDeleteDialogTitle');
  String get orgDeleteDialogContent => _get('orgDeleteDialogContent');

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
    'emailRequired': 'Ingresa tu correo electrónico',
    'emailInvalid': 'Correo electrónico no válido',
    'password': 'Contraseña',
    'passwordRequired': 'Ingresa tu contraseña',
    'passwordTooShort': 'La contraseña debe tener al menos 6 caracteres',
    'login': 'Iniciar sesión',
    'loginFailed': 'Error al iniciar sesión',
    'enterEmailPassword': 'Ingresa correo y contraseña.',
    'forgotPassword': '¿Olvidó su contraseña?',
    'forgotPasswordMessage':
        'Contacta al administrador del sistema para restablecer tu contraseña.',
    'ok': 'Entendido',
    'noAccount': '¿No tiene cuenta?',
    'contactAdmin': 'Contacte a su administrador',
    'sessionExpired': 'Sesión expirada. Inicie sesión nuevamente.',

    // Home
    'home': 'Inicio',
    'readNfc': 'Leer NFC',
    'readNfcSub': 'Escanear dispositivo NFC',
    'registerNfc': 'Registrar NFC',
    'registerNfcSub': 'Registrar nuevo paciente',
    'syncQueue': 'Sincronización',
    'allRecordsSynced': 'Todo sincronizado',
    'lossOfWristband': 'Pérdida de dispositivo NFC',
    'lossOfWristbandSub': 'El paciente perdió el dispositivo NFC.',
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
    'confirmChanges': 'Confirmar cambios',
    'loading': 'Cargando...',
    'error': 'Error',
    'success': 'Éxito',
    'noData': 'Sin datos',
    'searchError': 'No se pudo completar la búsqueda. Inténtalo de nuevo.',

    // Register NFC
    'registerTitle': 'Registrar NFC',
    'scanNewWristband': 'Acerque un dispositivo NFC nuevo',
    'scanNewWristbandSub': 'El sistema verificará que no esté asignada',
    'wristbandReady': 'lista — nueva',
    'nfcNotAvailable': 'NFC no disponible. Use entrada manual.',
    'manualUidHint': 'UID manual (testing)',
    'validWristbands':
        'dispositivo NFCs válidas: NTAG213/215 con prefijo HWB- *',
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
    'newPatient': 'Nuevo paciente',
    'consultationSaved': 'Consulta guardada exitosamente',
    'vaccineSaved': 'Vacuna guardada exitosamente',
    'today': 'Hoy',
    'patientNfcDevice': 'Dispositivo NFC del paciente',
    'patientNfcDeviceSub':
        'Acerque el dispositivo NFC o ingrese el UID manualmente.',
    'nfcUidRequired': 'Debe escanear o ingresar el UID del dispositivo NFC.',

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
    'scanWristband': 'Acerque el dispositivo NFC',
    'holdWristband': 'Mantenga contacto 2 segundos',
    'scanning': 'Buscando señal NFC...',
    'scanSuccess': '¡Datos leídos correctamente!',
    'scanFailed': 'Lectura fallida',
    'guardianRequired': 'Verificación de guardián requerida',
    'guardianRequiredSub':
        'Este paciente es menor de edad. Escanee el dispositivo NFC del guardián para acceder al registro.',
    'scanGuardianWristband': 'Escanear el dispositivo NFC del guardián',
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
    'fieldsProtected':
        'Nombre, fecha de nacimiento, sexo, tipo de sangre y documento están protegidos por el backend.',
    'editableInfo': 'Información editable',
    'address': 'Dirección',
    'street': 'Dirección',
    'city': 'Ciudad',
    'state': 'Departamento',
    'name': 'Nombre',

    // Edit address sheet
    'editResidence': 'Editar residencia',
    'addressZoneSubtitle': 'Dirección y zona del paciente',
    'municipality': 'Municipio',
    'department': 'Departamento',
    'zone': 'Zona',
    'streetHint': 'ej: Cra. 18 #27-43',
    'cityHint': 'ej: Riohacha',
    'stateHint': 'ej: La Guajira',
    'zoneUrban': 'Urbana',
    'zoneRural': 'Rural',

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
    'searchFieldsRequired':
        'Número de documento, fecha de nacimiento, nombre y apellido son requeridos.',

    // Sync
    'syncTitle': 'Pendientes por sincronizar',
    'syncAll': 'Sincronizar todo',
    'syncNow': 'Sync ahora',
    'review': 'Revisar',
    'syncedSuccessfully': 'Sincronizado correctamente',
    'syncFailedRetry': 'Sincronización fallida — se reintentará',
    'allSynced': 'Todo sincronizado',
    'noRecordsPending': 'No hay registros pendientes.',
    'deleteRecord': '¿Eliminar registro?',
    'deleteRecordConfirm':
        'Esto eliminará permanentemente el registro local. Si no ha sido sincronizado, los datos se perderán.',
    'pending': 'Pendiente',

    // Brigade
    'brigadeOffline': 'Modo brigada — Sin conexión',
    'patientsAppearHere': 'Los pacientes aparecerán aquí al sincronizarse',
    'synchronized': 'Sincronizado',
    'synchronizing': 'Sincronizando',

    // NFC Save Flow
    'putOnWristband': 'Coloque el dispositivo NFC',
    'placeWristband': 'Acerque el dispositivo NFC para cargar la información.',
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
    // ── Login v2 / Home v2 ──
    'appSubtitleShort': 'Historia clínica móvil para brigadas',
    'emailLabel': 'CORREO ELECTRÓNICO',
    'passwordLabel': 'CONTRASEÑA',
    'rememberSession': 'Recordar sesión',
    'sessionEncryptedFooter': 'Sesión cifrada · Cumple Ley 1581/2012',
    'goodMorning': 'Buenos días',
    'goodAfternoon': 'Buenas tardes',
    'goodEvening': 'Buenas noches',
    'logout': 'Cerrar sesión',
    'logoutTitle': 'Cerrar sesión',
    'logoutConfirm': '¿Seguro que deseas cerrar la sesión, {name}?',
    'roleDoctor': 'Médico',
    'roleNurse': 'Enfermero/a',
    'roleOrgAdmin': 'Administrador',
    'roleSuperadmin': 'Superadmin',
    'offline': 'Sin conexión',
    // Home actions v2
    'actionReadNfc': 'Leer NFC',
    'actionReadNfcSub': 'Escanear dispositivo NFC',
    'actionNewPatient': 'Nuevo paciente',
    'actionNewPatientSub': 'Primer ingreso del paciente',
    'actionSearchPatient': 'Buscar paciente',
    'actionSearchPatientSub': 'Dispositivo NFC perdido o dañado',
    'actionSearchPatientSubAdmin': 'Solo lectura',
    'actionPendingSync': 'Pendientes por sincronizar',
    'actionPendingSyncEmpty': 'Todos los registros sincronizados',
    'actionPendingSyncCount': '{n} registros sin enviar',
    // Admin v2
    'kpiUsers': 'Usuarios',
    'kpiSyncedOk': 'Sync OK',
    'adminManageUsers': 'Gestionar usuarios',
    'adminManageUsersSub': 'Doctores y enfermeros',
    'adminViewPatients': 'Ver pacientes',
    'adminViewPatientsSub': 'Solo lectura',
    'adminBrigadeHistorySub': '{n} pacientes sincronizados',
    // Read NFC v2
    'readWristbandTitle': 'Leer dispositivo NFC',
    'scanGuardianTitle': 'Leer dispositivo NFC del guardián',
    'scanPatientHeadline': 'Acerque el dispositivo NFC',
    'scanPatientHint': 'Acerque el dispositivo NFC del paciente',
    'scanGuardianHeadline': 'Acerque el dispositivo NFC del guardián',
    'patientWristbandReady': 'dispositivo NFC del paciente leída',
    'nfcNotAvailableHint': 'NFC no disponible. Use el campo manual debajo.',
    'manualPatientUidLabel': 'UID manual del paciente (testing)',
    'manualPatientUidHint': 'Ej. HWB-04:1A:2C:DE',
    'manualGuardianUidLabel': 'UID manual del guardián (testing)',
    'manualGuardianUidHint': 'Ej. HWB-04:8E:7F:11',
    'useManualUid': 'Usar UID manual',
    // Search v2
    'searchPatientTitle': 'Buscar paciente',
    'searchSubtitle': 'Identificación estricta · Ley 1581/2012',
    'searchPrivacyNotice':
        'Use esta búsqueda solo cuando el paciente no tiene su dispositivo NFC. Todos los campos son obligatorios.',
    'documentTypeLabel': 'Tipo doc.',
    'documentNumberLabel': 'Número de documento',
    'firstNameLabel': 'Primer nombre',
    'lastNameLabel': 'Apellido',
    'firstOrSecondLastName': 'Primer o segundo apellido',
    'dobLabel': 'Fecha de nacimiento',
    'guardianNameOptionalLabel': 'Nombre del guardián (si es menor)',
    'guardianHelper': 'Verificación adicional · coincidencia parcial permitida',
    'minThreeChars': 'Mínimo 3 caracteres',
    'searchPatientButton': 'Buscar paciente',
    'searchFooterNote':
        'Se devolverá exactamente un registro o ninguno.\nPor privacidad, no se exponen listas.',
    'searchNoMatch':
        'No se encontró ningún paciente con esos datos. Verifique los campos.',

    // Vital signs sheet
    'editMeasurements': 'Editar mediciones',
    'weightKg': 'Peso (KG)',
    'heightCm': 'Altura (CM)',
    'previous': 'Anterior',
    'bloodTypeReadOnly': 'Tipo de sangre',

    // Patient profile screen
    'unsyncedChanges': 'Cambios sin sincronizar',
    'synced': 'Sincronizado',
    'syncedAt': 'Sincronizado · {time}',
    'syncingBtn': 'Sincronizando...',
    'syncBtn': 'Sincronizar',
    'savedChangesMsg': 'Cambios guardados. Se sincronizarán automáticamente.',
    'notAuthorizedConsultations':
        'No autorizado: solo doctores pueden agregar consultas.',
    'unsyncedChangesTitle': 'Cambios sin sincronizar',
    'exitWithoutSyncMsg': 'Tienes cambios pendientes. ¿Salir sin sincronizar?',
    'exit': 'Salir',
    'tabSummary': 'Resumen',
    'yearsOldSuffix': 'años',
    'noAllergiesRegistered': 'Sin alergias registradas.',
    'addAllergyBtn': 'Agregar alergia',
    'allergyCategoryLabel': 'Categoría',
    'allergenLabel': 'Alérgeno',
    'allergenHint': 'ej: Penicilina, Maní, Polen...',
    'reactionOptionalLabel': 'Reacción (opcional)',
    'reactionHint': 'ej: Erupción cutánea generalizada, Edema labial...',
    'allergiesSheetTitle': 'Alergias',
    'backgroundSheetTitle': 'Antecedentes',
    'noChronicConditions': 'Sin condiciones crónicas.',
    'addChronicConditionTitle': 'Agregar condición crónica',
    'chronicConditionHint':
        'ej: Diabetes mellitus tipo 2, Hipertensión arterial...',
    'noMedications': 'Sin medicamentos registrados.',
    'medications': 'Medicamentos',
    'personalHistoryTitle': 'Historial personal',
    'noFamilyHistoryEntries': 'Sin antecedentes familiares.',
    'reactionLabel': 'Reacción: ',
    'sexMale': 'Masculino',
    'sexFemale': 'Femenino',
    'sexIndeterminate': 'Indeterminado',
    'docTypeRC': 'Reg. civil',
    'docTypeTI': 'Tarjeta identidad',
    'docTypeCC': 'Cédula',
    'docTypeCE': 'Céd. extranjería',
    'docTypePA': 'Pasaporte',
    'docTypePE': 'Permiso esp.',
    'docTypePT': 'PPT',
    'docTypeMS': 'Menor s/ID',
    'docTypeAS': 'Adulto s/ID',
    'editGuardianTitle': 'Editar guardián',
    'guardianFullName': 'Nombre completo',
    'guardianFullNameHint': 'ej: Carmen Vargas Pinto',
    'guardianRelationship': 'Parentesco',
    'guardianPhoneLabel': 'Teléfono',
    'guardianPhoneHint': 'ej: +57 310 482 9914',
    'guardianNfcDevice': 'Dispositivo NFC del guardán',
    'guardianNfcUidHint': 'UID del dispositivo NFC',
    'guardianNfcUnavailable': 'NFC no disponible. Ingrese el UID manualmente.',
    'guardianNfcError': 'No se pudo leer el dispositivo. Inténtalo de nuevo.',
    'relParents': 'Padres',
    'relSiblings': 'Hermanos',
    'relUncles': 'Tíos',
    'relGrandparents': 'Abuelos',
    'medStatusActive': 'Activo',
    'medStatusCompleted': 'Completado',
    'medStatusStopped': 'Suspendido',
    'medStatusUnknown': 'Desconocido',
    'cie10Label': 'CIE-10: ',

    // Add medication sheet
    'addMedicationTitle': 'Agregar medicamento',
    'addMedicationSubtitle': 'Registrar medicamento actual del paciente',
    'medicationLabel': 'Medicamento *',
    'medicationHint': 'ej: Metformina 850mg',
    'statusLabel': 'Estado',
    'dosageLabel': 'Posología',
    'dosageHint': 'ej: 1 tableta cada 12 horas',
    'notesLabel': 'Notas',
    'notesHint': 'Observaciones adicionales',

    // Edit chronic / personal sheet
    'editChronicPersonalHint': 'Describa la información en texto libre...',

    // Allergies tab
    'allergiesHeader': 'ALERGIAS · {n}',
    'reactionHeader': 'REACCIÓN',
    'allergyShortMedication': 'Medicamento',
    'allergyShortFood': 'Alimento',
    'allergyShortEnvironment': 'Sust. ambiente',
    'allergyShortSkin': 'Sust. piel',
    'allergyShortInsect': 'Picadura',
    'allergyShortOther': 'Otra',

    // Summary tab
    'personalTitle': 'Personal',
    'chronic': 'Crónicos',
    'family': 'Familiares',
    'recordsLabel': 'registros',

    // Consultations & Detail Detail
    'consultationsTabTitle': 'Consultas',
    'noConsultationsRegistered': 'Sin consultas registradas.',
    'addConsultationButton': 'Agregar consulta',
    'viewDetailHint': 'Ver detalle',
    'consultationDetailTitle': 'Detalle de consulta',
    'careContextSection': 'Contexto de atención',
    'startDateLabel': 'Fecha inicio',
    'endDateLabel': 'Fecha fin',
    'serviceGroupLabel': 'Grupo servicio',
    'environmentLabel': 'Entorno',
    'entryRouteLabel': 'Vía ingreso',
    'externalCauseLabel': 'Causa externa',
    'docLabelShort': 'Doc.',
    'diagnosisTitle': 'Diagnósticos',
    'dischargeSection': 'Egreso',
    'riskFactorsSection': 'Factores de riesgo',
    'incapacitySection': 'Incapacidad',
    'incapacityScope': 'Alcance',
    'incapacityDays': 'Días',
    'payerSection': 'Pagador',
    'codeLabel': 'Código',
    'dayLun': 'lun',
    'dayMar': 'mar',
    'dayMie': 'mié',
    'dayJue': 'jue',
    'dayVie': 'vie',
    'daySab': 'sáb',
    'dayDom': 'dom',
    'monEne': 'ene',
    'monFeb': 'feb',
    'monMar': 'mar',
    'monAbr': 'abr',
    'monMay': 'may',
    'monJun': 'jun',
    'monJul': 'jul',
    'monAgo': 'ago',
    'monSep': 'sep',
    'monOct': 'oct',
    'monNov': 'nov',
    'monDic': 'dic',
    'timeAm': 'a.m.', 'timePm': 'p.m.',
    'modIntramural': 'Intramural',
    'modExtramuralMobil': 'Extramural móvil',
    'modDomiciliaria': 'Domiciliaria',
    'modJornada': 'Jornada',
    'modPrehospitalaria': 'Prehospitalaria',
    'modTelemedicinaInteractiva': 'Telemedicina interactiva',
    'modNoInteractiva': 'No interactiva',
    'modTelexperticia': 'Telexperticia',
    'modTelemonitoreo': 'Telemonitoreo',
    'sgConsultaExterna': 'Consulta externa',
    'sgApoyoDiagnostico': 'Apoyo diagnóstico',
    'sgInternacion': 'Internación',
    'sgQuirurgico': 'Quirúrgico',
    'sgAtencionInmediata': 'Atención inmediata',
    'ceHogar': 'Hogar',
    'ceComunitario': 'Comunitario',
    'ceEscolar': 'Escolar',
    'ceLaboral': 'Laboral',
    'ceInstitucional': 'Institucional',
    'dtImpresion': 'Impresión diagnóstica',
    'dtConfirmadoNuevo': 'Confirmado nuevo',
    'dtConfirmadoRepetido': 'Confirmado repetido',
    'ddAltaVoluntaria': 'Alta voluntaria',
    'ddFallecido': 'Paciente fallecido',
    'ddRemitido': 'Remitido',
    'ddAltaMedica': 'Alta médica',

    // vaccine tab
    'vaccineSchemeTitle': 'Esquema',
    'vaccineLabelSingle': 'Vacuna',
    'vaccineLabelPlural': 'Vacunas',
    'noVaccinesRegistered': 'No hay vacunas registradas.',
    'addVaccineButton': 'Agregar vacuna',
    'doseLabel': 'Dosis',

    // Admin Manage Users
    'manageUsersTitle': 'Gestionar usuarios',
    'filterAll': 'Todos',
    'filterDoctors': 'Doctores',
    'filterNurse': 'Enfermería',
    'filterCoord': 'Coord',
    'noUsersInFilter': 'No hay usuarios en este filtro.',
    'createUserTitle': 'Crear usuario',
    'userStatusActive': 'Activo',
    'userStatusSuspended': 'Suspendido',
    'userDetailOrganization': 'Organización',
    'userDetailStatus': 'Estado',
    'userFormFullNameLabel': 'Nombre completo *',
    'userFormEmailLabel': 'Correo electrónico *',
    'userFormPasswordLabel': 'Contraseña temporal *',
    'userFormRoleLabel': 'Rol *',
    'userFormRequiredFieldsError': 'Completa todos los campos requeridos.',
    'userFormCreatingStatus': 'Creando...',
    'userFormCreateButton': 'Crear usuario',
    'deletUser': 'Eliminar usuario',
    'deleting': 'Eliminando...',
    'permanentlyDelete': 'Esta acción eliminará permanentemente a',
    'userFormValidationError':
        'Revise por favor que los datos estén bien diligenciados',

    // Super Admin
    'manageOrgsTitle': 'Organizaciones',
    'manageOrgsSubtitle': 'Crear y gentionar organizaciones',
    'brigadeStatsTitle': 'Estadísticas de brigadas',
    'brigadeStatsSubtitle': 'Ver métricas consolidadas',
    'statsScreenTitle': 'Estadísticas Globales',
    'statsTotalPatients': 'Pacientes Totales',
    'statsTotalVaccines': 'Vacunas Aplicadas',
    'statsTotalAllergies': 'Alergias Detectadas',
    'statsMinorsPercentage': 'Porcentaje Menores',
    'statsVaccineDistribution': 'Distribución de Vacunas',
    'statsAllergyDistribution': 'Distribución de Alergias',
    'statsNationalityDistribution': 'Distribución por Nacionalidad',
    'statsScreenTitleOrg': 'Estadísticas de mi Organización',
    'statsFilterAll': 'Todas',
    'statsTotalEncounters': 'Consultas Médicas',
    'statsEmpty': 'Aún no hay datos para este período.',
    'statsOfflineHint':
        'Las estadísticas requieren conexión. Revisa tu red e inténtalo de nuevo.',
    'statsForbidden': 'Tu rol no tiene acceso a las estadísticas.',
    'statsRangeAll': 'Todo',
    'statsRangeThisMonth': 'Este mes',
    'statsRangeLast30': 'Últimos 30 días',
    'statsRangeCustom': 'Personalizado',
    'manageOrgsScreenTitle': 'Organizaciones',
    'orgsNoOrganizations': 'No hay organizaciones registradas.',
    'orgsCreateOrgTitle': 'Crear organización',
    'orgsStepBasicData': 'Datos básicos',
    'orgsStepAdminUser': 'Usuario Administrador',
    'orgsStepSummary': 'Resumen',
    'orgsFieldNameLabel': 'Nombre de la organización *',
    'orgsFieldEmailLabel': 'Correo electrónico oficial *',
    'orgsFieldAdminNameLabel': 'Nombre del administrador *',
    'orgsFieldAdminEmailLabel': 'Correo del administrador *',
    'orgsFieldAdminPassLabel': 'Contraseña provisional *',
    'orgsSummarySubtitle':
        'Confirma los datos antes de proceder a la creación.',
    'orgsLabelOrganization': 'Organización',
    'orgsLabelOfficialEmail': 'Email Oficial',
    'orgsLabelAdministrator': 'Administrador',
    'orgsLabelAdminEmail': 'Email Admin',
    'orgsLabelProvisionalPass': 'Contraseña prov.',
    'step': 'Paso',
    'labelNameAdmin': 'Nombre del administrador',
    'orgDetailTitle': 'Detalle de la Organización',
    'orgDetailId': 'ID de Organización',
    'orgDeleteButton': 'Eliminar Organización',
    'orgDeleteDialogTitle': '¿Eliminar organización?',
    'orgDeleteDialogContent':
        'Esta acción eliminará permanentemente la organización {name} y todos sus datos asociados.',
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
    'emailRequired': 'Enter your email address',
    'emailInvalid': 'Invalid email address',
    'password': 'Password',
    'passwordRequired': 'Enter your password',
    'passwordTooShort': 'Password must be at least 6 characters long',
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
    'readNfcSub': 'Scan patient device',
    'registerNfc': 'Register NFC',
    'registerNfcSub': 'Register new patient',
    'syncQueue': 'Sync Queue',
    'allRecordsSynced': 'All records synced',
    'lossOfWristband': 'Loss of device',
    'lossOfWristbandSub': 'The patient lost the device.',
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
    'confirmChanges': 'Confirm changes',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'noData': 'No data',
    'searchError': 'The search could not be completed. Please try again.',

    // Register NFC
    'registerTitle': 'Register NFC',
    'scanNewWristband': 'Bring a new device close',
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
    'newPatient': 'New patient',
    'consultationSaved': 'Consultation saved successfully',
    'vaccineSaved': 'Vaccine saved successfully',
    'today': 'Today',
    'patientNfcDevice': 'Patient NFC device',
    'patientNfcDeviceSub': 'Tap the NFC device or enter the UID manually.',
    'nfcUidRequired': 'You must scan or enter the NFC device UID.',

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
    'editGuardianTitle': 'Edit guardian',
    'guardianFullName': 'Full name',
    'guardianFullNameHint': 'e.g. Carmen Vargas Pinto',
    'guardianRelationship': 'Relationship',
    'guardianPhoneLabel': 'Phone',
    'guardianPhoneHint': 'e.g. +1 310 482 9914',
    'guardianNfcDevice': 'Guardian NFC device',
    'guardianNfcUidHint': 'NFC device UID',
    'guardianNfcUnavailable': 'NFC not available. Enter UID manually.',
    'guardianNfcError': 'Could not read the device. Please try again.',
    'relParents': 'Parents',
    'relSiblings': 'Siblings',
    'relUncles': 'Uncles',
    'relGrandparents': 'Grandparents',

    // Read NFC
    'scanWristband': 'Bring the device close',
    'holdWristband': 'Hold contact for 2 seconds',
    'scanning': 'Searching NFC signal...',
    'scanSuccess': 'Data read successfully!',
    'scanFailed': 'Scan failed',
    'guardianRequired': 'Guardian verification required',
    'guardianRequiredSub':
        "This patient is a minor. Please scan the guardian's device to access the record.",
    'scanGuardianWristband': 'Scan guardian device',
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
    'fieldsProtected':
        'Name, DOB, sex, blood type and document are protected by the backend.',
    'editableInfo': 'Editable information',
    'address': 'Address',
    'street': 'Street',
    'city': 'City',
    'state': 'State / Department',
    'name': 'Name',

    // Edit address sheet
    'editResidence': 'Edit residence',
    'addressZoneSubtitle': 'Patient address and zone',
    'municipality': 'Municipality',
    'department': 'Department',
    'zone': 'Zone',
    'streetHint': 'e.g. 123 Main St',
    'cityHint': 'e.g. Riohacha',
    'stateHint': 'e.g. La Guajira',
    'zoneUrban': 'Urban',
    'zoneRural': 'Rural',

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
    'searchFieldsRequired':
        'Document number, DOB, first name, and last name are required.',

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
    'deleteRecordConfirm':
        'This will permanently delete the local record. If it hasn\'t been synced, the data will be lost.',
    'pending': 'Pending',

    // Brigade
    'brigadeOffline': 'Brigade Mode — Offline',
    'patientsAppearHere': 'Patients will appear here as they are synced',
    'synchronized': 'Synchronized',
    'synchronizing': 'Synchronizing',

    // NFC Save Flow
    'putOnWristband': 'Put on the device',
    'placeWristband': 'Please place the device to load the information.',
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
    // ── Login v2 / Home v2 ──
    'appSubtitleShort': 'Mobile clinical history for brigades',
    'emailLabel': 'EMAIL',
    'passwordLabel': 'PASSWORD',
    'rememberSession': 'Remember me',
    'sessionEncryptedFooter': 'Encrypted session · Complies Law 1581/2012',
    'goodMorning': 'Good morning',
    'goodAfternoon': 'Good afternoon',
    'goodEvening': 'Good evening',
    'logout': 'Sign out',
    'logoutTitle': 'Sign out',
    'logoutConfirm': 'Are you sure you want to sign out, {name}?',
    'roleDoctor': 'Doctor',
    'roleNurse': 'Nurse',
    'roleOrgAdmin': 'Administrator',
    'roleSuperadmin': 'Superadmin',
    'offline': 'Offline',
    // Home actions v2
    'actionReadNfc': 'Read NFC',
    'actionReadNfcSub': "Scan patient's device",
    'actionNewPatient': 'New patient',
    'actionNewPatientSub': 'First patient registration',
    'actionSearchPatient': 'Search patient',
    'actionSearchPatientSub': 'Lost or damaged device',
    'actionSearchPatientSubAdmin': 'Read-only access',
    'actionPendingSync': 'Pending sync',
    'actionPendingSyncEmpty': 'All records synced',
    'actionPendingSyncCount': '{n} records not sent',
    // Admin v2
    'kpiUsers': 'Users',
    'kpiSyncedOk': 'Sync OK',
    'adminManageUsers': 'Manage users',
    'adminManageUsersSub': 'Doctors and nurses',
    'adminViewPatients': 'View patients',
    'adminViewPatientsSub': 'Read-only',
    'adminBrigadeHistorySub': '{n} synced patients',
    // Read NFC v2
    'readWristbandTitle': 'Read device',
    'scanGuardianTitle': "Read guardian's device",
    'scanPatientHeadline': 'Tap to scan the device',
    'scanPatientHint': "Hold the device close to the patient's NFC device",
    'scanGuardianHeadline': "Tap to scan the guardian's device",
    'patientWristbandReady': 'Patient device ready',
    'nfcNotAvailableHint': 'NFC unavailable. Use manual entry below.',
    'manualPatientUidLabel': 'Manual patient UID (testing)',
    'manualPatientUidHint': 'E.g. HWB-04:1A:2C:DE',
    'manualGuardianUidLabel': 'Manual guardian UID (testing)',
    'manualGuardianUidHint': 'E.g. HWB-04:8E:7F:11',
    'useManualUid': 'Use manual UID',
    // Search v2
    'searchPatientTitle': 'Search patient',
    'searchSubtitle': 'Strict identification · Law 1581/2012',
    'searchPrivacyNotice':
        'Use this search only when the patient does not have their device. All fields are required.',
    'documentTypeLabel': 'Doc. type',
    'documentNumberLabel': 'Document number',
    'firstNameLabel': 'First name',
    'lastNameLabel': 'Last name',
    'firstOrSecondLastName': 'First or second last name',
    'dobLabel': 'Date of birth',
    'guardianNameOptionalLabel': "Guardian's name (if minor)",
    'guardianHelper': 'Extra verification · partial match allowed',
    'minThreeChars': '3 characters minimum',
    'searchPatientButton': 'Search patient',
    'searchFooterNote':
        'Exactly one record or none will be returned.\nFor privacy, no list is exposed.',
    'searchNoMatch':
        'No patient found with these details. Please check the fields.',

    // Vital signs sheet
    'editMeasurements': 'Edit measurements',
    'weightKg': 'Weight (KG)',
    'heightCm': 'Height (CM)',
    'previous': 'Previous',
    'bloodTypeReadOnly': 'Blood type',

    // Patient profile screen
    'unsyncedChanges': 'Unsynced changes',
    'synced': 'Synced',
    'syncedAt': 'Synced · {time}',
    'syncingBtn': 'Syncing...',
    'syncBtn': 'Sync',
    'savedChangesMsg': 'Changes saved. They will sync automatically.',
    'notAuthorizedConsultations':
        'Not authorized: only doctors can add consultations.',
    'unsyncedChangesTitle': 'Unsynchronized changes',
    'exitWithoutSyncMsg': 'You have pending changes. Exit without syncing?',
    'exit': 'Exit',
    'tabSummary': 'Summary',
    'yearsOldSuffix': 'yrs',
    'noAllergiesRegistered': 'No allergies registered.',
    'addAllergyBtn': 'Add allergy',
    'allergyCategoryLabel': 'Category',
    'allergenLabel': 'Allergen',
    'allergenHint': 'e.g. Penicillin, Peanut, Pollen...',
    'reactionOptionalLabel': 'Reaction (optional)',
    'reactionHint': 'e.g. Generalized rash, Lip swelling...',
    'allergiesSheetTitle': 'Allergies',
    'backgroundSheetTitle': 'Background',
    'noChronicConditions': 'No chronic conditions.',
    'addChronicConditionTitle': 'Add chronic condition',
    'chronicConditionHint': 'e.g. Type 2 diabetes mellitus, Hypertension...',
    'noMedications': 'No medications registered.',
    'medications': 'Medications',
    'personalHistoryTitle': 'Personal history',
    'noFamilyHistoryEntries': 'No family history entries.',
    'reactionLabel': 'Reaction: ',
    'sexMale': 'Male',
    'sexFemale': 'Female',
    'sexIndeterminate': 'Indeterminate',
    'docTypeRC': 'Civil reg.',
    'docTypeTI': 'ID card',
    'docTypeCC': 'National ID',
    'docTypeCE': 'Foreign ID',
    'docTypePA': 'Passport',
    'docTypePE': 'Special permit',
    'docTypePT': 'PPT',
    'docTypeMS': 'Minor w/o ID',
    'docTypeAS': 'Adult w/o ID',
    'medStatusActive': 'Active',
    'medStatusCompleted': 'Completed',
    'medStatusStopped': 'Stopped',
    'medStatusUnknown': 'Unknown',
    'cie10Label': 'ICD-10: ',

    // Add medication sheet
    'addMedicationTitle': 'Add medication',
    'addMedicationSubtitle': 'Register the patient\'s current medication',
    'medicationLabel': 'Medication *',
    'medicationHint': 'e.g. Metformin 850mg',
    'statusLabel': 'Status',
    'dosageLabel': 'Dosage',
    'dosageHint': 'e.g. 1 tablet every 12 hours',
    'notesLabel': 'Notes',
    'notesHint': 'Additional observations',

    // Edit chronic / personal sheet
    'editChronicPersonalHint': 'Describe the information in free text...',

    // Allergies tab
    'allergiesHeader': 'ALLERGIES · {n}',
    'reactionHeader': 'REACTION',
    'allergyShortMedication': 'Medication',
    'allergyShortFood': 'Food',
    'allergyShortEnvironment': 'Env. substance',
    'allergyShortSkin': 'Skin substance',
    'allergyShortInsect': 'Insect sting',
    'allergyShortOther': 'Other',

    // Summary tab
    'personalTitle': 'Personal',
    'chronic': 'Chronic',
    'family': 'Family',
    'recordsLabel': 'records',

    // Consultations & Detail Detail
    'consultationsTabTitle': 'Consultations',
    'noConsultationsRegistered': 'No consultations registered.',
    'addConsultationButton': 'Add consultation',
    'viewDetailHint': 'View detail',
    'consultationDetailTitle': 'Consultation Detail',
    'careContextSection': 'Care Context',
    'startDateLabel': 'Start date',
    'endDateLabel': 'End date',
    'serviceGroupLabel': 'Service group',
    'environmentLabel': 'Environment',
    'entryRouteLabel': 'Entry route',
    'externalCauseLabel': 'External cause',
    'docLabelShort': 'ID Doc.',
    'diagnosisTitle': 'Diagnoses',
    'dischargeSection': 'Discharge',
    'riskFactorsSection': 'Risk factors',
    'incapacitySection': 'Incapacity',
    'incapacityScope': 'Scope',
    'incapacityDays': 'Days',
    'payerSection': 'Payer',
    'codeLabel': 'Code',
    'dayLun': 'Mon',
    'dayMar': 'Tue',
    'dayMie': 'Wed',
    'dayJue': 'Thu',
    'dayVie': 'Fri',
    'daySab': 'Sat',
    'dayDom': 'Sun',
    'monEne': 'Jan',
    'monFeb': 'Feb',
    'monMar': 'Mar',
    'monAbr': 'Apr',
    'monMay': 'May',
    'monJun': 'Jun',
    'monJul': 'Jul',
    'monAgo': 'Aug',
    'monSep': 'Sep',
    'monOct': 'Oct',
    'monNov': 'Nov',
    'monDic': 'Dec',
    'timeAm': 'AM', 'timePm': 'PM',
    'modIntramural': 'Intramural',
    'modExtramuralMobil': 'Mobile extramural',
    'modDomiciliaria': 'Home care',
    'modJornada': 'Health campaign',
    'modPrehospitalaria': 'Pre-hospital',
    'modTelemedicinaInteractiva': 'Interactive telemedicine',
    'modNoInteractiva': 'Non-interactive',
    'modTelexperticia': 'Tele-expertise',
    'modTelemonitoreo': 'Tele-monitoring',
    'sgConsultaExterna': 'Outpatient care',
    'sgApoyoDiagnostico': 'Diagnostic support',
    'sgInternacion': 'Inpatient care',
    'sgQuirurgico': 'Surgical care',
    'sgAtencionInmediata': 'Immediate care',
    'ceHogar': 'Home',
    'ceComunitario': 'Community',
    'ceEscolar': 'School',
    'ceLaboral': 'Workplace',
    'ceInstitucional': 'Institutional',
    'dtImpresion': 'Diagnostic impression',
    'dtConfirmadoNuevo': 'Confirmed new',
    'dtConfirmadoRepetido': 'Confirmed repeated',
    'ddAltaVoluntaria': 'Voluntary discharge',
    'ddFallecido': 'Deceased patient',
    'ddRemitido': 'Referred',
    'ddAltaMedica': 'Medical discharge',

    // vaccine tab
    'vaccineSchemeTitle': 'Scheme',
    'vaccineLabelSingle': 'Vaccine',
    'vaccineLabelPlural': 'Vaccines',
    'noVaccinesRegistered': 'No vaccines registered.',
    'addVaccineButton': 'Add vaccine',
    'doseLabel': 'Dose',

    // Admin Manage Users
    'manageUsersTitle': 'Manage users',
    'filterAll': 'All',
    'filterDoctors': 'Doctors',
    'filterNurse': 'Nursing',
    'filterCoord': 'Coord',
    'noUsersInFilter': 'No users found in this filter.',
    'createUserTitle': 'Create user',
    'userStatusActive': 'Active',
    'userStatusSuspended': 'Suspended',
    'userDetailOrganization': 'Organization',
    'userDetailStatus': 'Status',
    'userFormFullNameLabel': 'Full name *',
    'userFormEmailLabel': 'Email *',
    'userFormPasswordLabel': 'Temporary password *',
    'userFormRoleLabel': 'Role *',
    'userFormRequiredFieldsError': 'Please fill in all required fields.',
    'userFormCreatingStatus': 'Creating...',
    'userFormCreateButton': 'Create user',
    'deletUser': 'Delete user',
    'deleting': 'Deleting ...',
    'permanentlyDelete': 'This action will permanently delete',
    'userFormValidationError':
        'Please check that the fields are properly filled out',

    // Super Admin
    'manageOrgsTitle': 'Organizations',
    'manageOrgsSubtitle': 'Create and manage organizations',
    'brigadeStatsTitle': 'Brigade statistics',
    'brigadeStatsSubtitle': 'View consolidated metrics',
    'statsScreenTitle': 'Global Statistics',
    'statsTotalPatients': 'Total Patients',
    'statsTotalVaccines': 'Vaccines Administered',
    'statsTotalAllergies': 'Detected Allergies',
    'statsMinorsPercentage': 'Minors Percentage',
    'statsVaccineDistribution': 'Vaccine Distribution',
    'statsAllergyDistribution': 'Allergy Distribution',
    'statsNationalityDistribution': 'Nationality Distribution',
    'statsScreenTitleOrg': "My Organization's Statistics",
    'statsFilterAll': 'All',
    'statsTotalEncounters': 'Clinical Encounters',
    'statsEmpty': 'No data yet for this period.',
    'statsOfflineHint':
        'Statistics require a connection. Check your network and try again.',
    'statsForbidden': 'Your role does not have access to statistics.',
    'statsRangeAll': 'All time',
    'statsRangeThisMonth': 'This month',
    'statsRangeLast30': 'Last 30 days',
    'statsRangeCustom': 'Custom',
    'manageOrgsScreenTitle': 'Organizations',
    'orgsNoOrganizations': 'No organizations registered.',
    'orgsCreateOrgTitle': 'Create organization',
    'orgsStepBasicData': 'Basic data',
    'orgsStepAdminUser': 'Admin User',
    'orgsStepSummary': 'Summary',
    'orgsFieldNameLabel': 'Organization name *',
    'orgsFieldEmailLabel': 'Official email *',
    'orgsFieldAdminNameLabel': 'Admin name *',
    'orgsFieldAdminEmailLabel': 'Admin email *',
    'orgsFieldAdminPassLabel': 'Provisional password *',
    'orgsSummarySubtitle':
        'Confirm the data before proceeding with the creation.',
    'orgsLabelOrganization': 'Organization',
    'orgsLabelOfficialEmail': 'Official Email',
    'orgsLabelAdministrator': 'Administrator',
    'orgsLabelAdminEmail': 'Admin Email',
    'orgsLabelProvisionalPass': 'Prov. Password',
    'step': 'Step',
    'labelNameAdmin': 'Administrator name',
    'orgDetailTitle': 'Organization Detail',
    'orgDetailId': 'Organization ID',
    'orgDeleteButton': 'Delete Organization',
    'orgDeleteDialogTitle': 'Delete organization?',
    'orgDeleteDialogContent':
        'This action will permanently delete the organization {name} and all its associated data.',
  };
}
