// test/unit/app_strings_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/i18n/app_strings.dart';

void main() {
  group('AppStrings - Spanish locale (es)', () {
    final es = AppStrings.forTesting('es');

    test('every getter returns a non-empty String', () {
      // ── Auth ──
      expect(es.appName, isA<String>(), reason: 'appName (es)');
      expect(
        es.appName.isNotEmpty,
        isTrue,
        reason: 'appName (es) should not be empty',
      );
      expect(es.appSubtitle, isA<String>(), reason: 'appSubtitle (es)');
      expect(
        es.appSubtitle.isNotEmpty,
        isTrue,
        reason: 'appSubtitle (es) should not be empty',
      );
      expect(es.signIn, isA<String>(), reason: 'signIn (es)');
      expect(
        es.signIn.isNotEmpty,
        isTrue,
        reason: 'signIn (es) should not be empty',
      );
      expect(es.welcome, isA<String>(), reason: 'welcome (es)');
      expect(
        es.welcome.isNotEmpty,
        isTrue,
        reason: 'welcome (es) should not be empty',
      );
      expect(es.welcomeSub, isA<String>(), reason: 'welcomeSub (es)');
      expect(
        es.welcomeSub.isNotEmpty,
        isTrue,
        reason: 'welcomeSub (es) should not be empty',
      );
      expect(es.email, isA<String>(), reason: 'email (es)');
      expect(
        es.email.isNotEmpty,
        isTrue,
        reason: 'email (es) should not be empty',
      );
      expect(es.emailHint, isA<String>(), reason: 'emailHint (es)');
      expect(
        es.emailHint.isNotEmpty,
        isTrue,
        reason: 'emailHint (es) should not be empty',
      );
      expect(es.emailRequired, isA<String>(), reason: 'emailRequired (es)');
      expect(
        es.emailRequired.isNotEmpty,
        isTrue,
        reason: 'emailRequired (es) should not be empty',
      );
      expect(es.emailInvalid, isA<String>(), reason: 'emailInvalid (es)');
      expect(
        es.emailInvalid.isNotEmpty,
        isTrue,
        reason: 'emailInvalid (es) should not be empty',
      );
      expect(es.password, isA<String>(), reason: 'password (es)');
      expect(
        es.password.isNotEmpty,
        isTrue,
        reason: 'password (es) should not be empty',
      );
      expect(
        es.passwordRequired,
        isA<String>(),
        reason: 'passwordRequired (es)',
      );
      expect(
        es.passwordRequired.isNotEmpty,
        isTrue,
        reason: 'passwordRequired (es) should not be empty',
      );
      expect(
        es.passwordTooShort,
        isA<String>(),
        reason: 'passwordTooShort (es)',
      );
      expect(
        es.passwordTooShort.isNotEmpty,
        isTrue,
        reason: 'passwordTooShort (es) should not be empty',
      );
      expect(es.login, isA<String>(), reason: 'login (es)');
      expect(
        es.login.isNotEmpty,
        isTrue,
        reason: 'login (es) should not be empty',
      );
      expect(es.loginFailed, isA<String>(), reason: 'loginFailed (es)');
      expect(
        es.loginFailed.isNotEmpty,
        isTrue,
        reason: 'loginFailed (es) should not be empty',
      );
      expect(
        es.enterEmailPassword,
        isA<String>(),
        reason: 'enterEmailPassword (es)',
      );
      expect(
        es.enterEmailPassword.isNotEmpty,
        isTrue,
        reason: 'enterEmailPassword (es) should not be empty',
      );
      expect(es.forgotPassword, isA<String>(), reason: 'forgotPassword (es)');
      expect(
        es.forgotPassword.isNotEmpty,
        isTrue,
        reason: 'forgotPassword (es) should not be empty',
      );
      expect(
        es.forgotPasswordMessage,
        isA<String>(),
        reason: 'forgotPasswordMessage (es)',
      );
      expect(
        es.forgotPasswordMessage.isNotEmpty,
        isTrue,
        reason: 'forgotPasswordMessage (es) should not be empty',
      );
      expect(es.ok, isA<String>(), reason: 'ok (es)');
      expect(es.ok.isNotEmpty, isTrue, reason: 'ok (es) should not be empty');
      expect(es.noAccount, isA<String>(), reason: 'noAccount (es)');
      expect(
        es.noAccount.isNotEmpty,
        isTrue,
        reason: 'noAccount (es) should not be empty',
      );
      expect(es.contactAdmin, isA<String>(), reason: 'contactAdmin (es)');
      expect(
        es.contactAdmin.isNotEmpty,
        isTrue,
        reason: 'contactAdmin (es) should not be empty',
      );
      expect(es.sessionExpired, isA<String>(), reason: 'sessionExpired (es)');
      expect(
        es.sessionExpired.isNotEmpty,
        isTrue,
        reason: 'sessionExpired (es) should not be empty',
      );

      // ── Home ──
      expect(es.home, isA<String>(), reason: 'home (es)');
      expect(
        es.home.isNotEmpty,
        isTrue,
        reason: 'home (es) should not be empty',
      );
      expect(es.readNfc, isA<String>(), reason: 'readNfc (es)');
      expect(
        es.readNfc.isNotEmpty,
        isTrue,
        reason: 'readNfc (es) should not be empty',
      );
      expect(es.readNfcSub, isA<String>(), reason: 'readNfcSub (es)');
      expect(
        es.readNfcSub.isNotEmpty,
        isTrue,
        reason: 'readNfcSub (es) should not be empty',
      );
      expect(es.registerNfc, isA<String>(), reason: 'registerNfc (es)');
      expect(
        es.registerNfc.isNotEmpty,
        isTrue,
        reason: 'registerNfc (es) should not be empty',
      );
      expect(es.registerNfcSub, isA<String>(), reason: 'registerNfcSub (es)');
      expect(
        es.registerNfcSub.isNotEmpty,
        isTrue,
        reason: 'registerNfcSub (es) should not be empty',
      );
      expect(es.syncQueue, isA<String>(), reason: 'syncQueue (es)');
      expect(
        es.syncQueue.isNotEmpty,
        isTrue,
        reason: 'syncQueue (es) should not be empty',
      );
      expect(
        es.allRecordsSynced,
        isA<String>(),
        reason: 'allRecordsSynced (es)',
      );
      expect(
        es.allRecordsSynced.isNotEmpty,
        isTrue,
        reason: 'allRecordsSynced (es) should not be empty',
      );
      expect(es.lossOfWristband, isA<String>(), reason: 'lossOfWristband (es)');
      expect(
        es.lossOfWristband.isNotEmpty,
        isTrue,
        reason: 'lossOfWristband (es) should not be empty',
      );
      expect(
        es.lossOfWristbandSub,
        isA<String>(),
        reason: 'lossOfWristbandSub (es)',
      );
      expect(
        es.lossOfWristbandSub.isNotEmpty,
        isTrue,
        reason: 'lossOfWristbandSub (es) should not be empty',
      );
      expect(es.brigadeHistory, isA<String>(), reason: 'brigadeHistory (es)');
      expect(
        es.brigadeHistory.isNotEmpty,
        isTrue,
        reason: 'brigadeHistory (es) should not be empty',
      );
      expect(
        es.brigadeHistorySub,
        isA<String>(),
        reason: 'brigadeHistorySub (es)',
      );
      expect(
        es.brigadeHistorySub.isNotEmpty,
        isTrue,
        reason: 'brigadeHistorySub (es) should not be empty',
      );

      // ── Common ──
      expect(es.back, isA<String>(), reason: 'back (es)');
      expect(
        es.back.isNotEmpty,
        isTrue,
        reason: 'back (es) should not be empty',
      );
      expect(es.next, isA<String>(), reason: 'next (es)');
      expect(
        es.next.isNotEmpty,
        isTrue,
        reason: 'next (es) should not be empty',
      );
      expect(es.continueBtn, isA<String>(), reason: 'continueBtn (es)');
      expect(
        es.continueBtn.isNotEmpty,
        isTrue,
        reason: 'continueBtn (es) should not be empty',
      );
      expect(es.cancel, isA<String>(), reason: 'cancel (es)');
      expect(
        es.cancel.isNotEmpty,
        isTrue,
        reason: 'cancel (es) should not be empty',
      );
      expect(es.save, isA<String>(), reason: 'save (es)');
      expect(
        es.save.isNotEmpty,
        isTrue,
        reason: 'save (es) should not be empty',
      );
      expect(es.search, isA<String>(), reason: 'search (es)');
      expect(
        es.search.isNotEmpty,
        isTrue,
        reason: 'search (es) should not be empty',
      );
      expect(es.retry, isA<String>(), reason: 'retry (es)');
      expect(
        es.retry.isNotEmpty,
        isTrue,
        reason: 'retry (es) should not be empty',
      );
      expect(es.delete, isA<String>(), reason: 'delete (es)');
      expect(
        es.delete.isNotEmpty,
        isTrue,
        reason: 'delete (es) should not be empty',
      );
      expect(es.confirm, isA<String>(), reason: 'confirm (es)');
      expect(
        es.confirm.isNotEmpty,
        isTrue,
        reason: 'confirm (es) should not be empty',
      );
      expect(es.confirmChanges, isA<String>(), reason: 'confirmChanges (es)');
      expect(
        es.confirmChanges.isNotEmpty,
        isTrue,
        reason: 'confirmChanges (es) should not be empty',
      );
      expect(es.loading, isA<String>(), reason: 'loading (es)');
      expect(
        es.loading.isNotEmpty,
        isTrue,
        reason: 'loading (es) should not be empty',
      );
      expect(es.error, isA<String>(), reason: 'error (es)');
      expect(
        es.error.isNotEmpty,
        isTrue,
        reason: 'error (es) should not be empty',
      );
      expect(es.success, isA<String>(), reason: 'success (es)');
      expect(
        es.success.isNotEmpty,
        isTrue,
        reason: 'success (es) should not be empty',
      );
      expect(es.noData, isA<String>(), reason: 'noData (es)');
      expect(
        es.noData.isNotEmpty,
        isTrue,
        reason: 'noData (es) should not be empty',
      );
      expect(es.searchError, isA<String>(), reason: 'searchError (es)');
      expect(
        es.searchError.isNotEmpty,
        isTrue,
        reason: 'searchError (es) should not be empty',
      );

      // ── Register NFC ──
      expect(es.registerTitle, isA<String>(), reason: 'registerTitle (es)');
      expect(
        es.registerTitle.isNotEmpty,
        isTrue,
        reason: 'registerTitle (es) should not be empty',
      );
      expect(
        es.scanNewWristband,
        isA<String>(),
        reason: 'scanNewWristband (es)',
      );
      expect(
        es.scanNewWristband.isNotEmpty,
        isTrue,
        reason: 'scanNewWristband (es) should not be empty',
      );
      expect(
        es.scanNewWristbandSub,
        isA<String>(),
        reason: 'scanNewWristbandSub (es)',
      );
      expect(
        es.scanNewWristbandSub.isNotEmpty,
        isTrue,
        reason: 'scanNewWristbandSub (es) should not be empty',
      );
      expect(es.wristbandReady, isA<String>(), reason: 'wristbandReady (es)');
      expect(
        es.wristbandReady.isNotEmpty,
        isTrue,
        reason: 'wristbandReady (es) should not be empty',
      );
      expect(es.nfcNotAvailable, isA<String>(), reason: 'nfcNotAvailable (es)');
      expect(
        es.nfcNotAvailable.isNotEmpty,
        isTrue,
        reason: 'nfcNotAvailable (es) should not be empty',
      );
      expect(es.manualUidHint, isA<String>(), reason: 'manualUidHint (es)');
      expect(
        es.manualUidHint.isNotEmpty,
        isTrue,
        reason: 'manualUidHint (es) should not be empty',
      );
      expect(es.validWristbands, isA<String>(), reason: 'validWristbands (es)');
      expect(
        es.validWristbands.isNotEmpty,
        isTrue,
        reason: 'validWristbands (es) should not be empty',
      );
      expect(es.patientData, isA<String>(), reason: 'patientData (es)');
      expect(
        es.patientData.isNotEmpty,
        isTrue,
        reason: 'patientData (es) should not be empty',
      );
      expect(
        es.registrationComplete,
        isA<String>(),
        reason: 'registrationComplete (es)',
      );
      expect(
        es.registrationComplete.isNotEmpty,
        isTrue,
        reason: 'registrationComplete (es) should not be empty',
      );
      expect(
        es.patientRegistered,
        isA<String>(),
        reason: 'patientRegistered (es)',
      );
      expect(
        es.patientRegistered.isNotEmpty,
        isTrue,
        reason: 'patientRegistered (es) should not be empty',
      );
      expect(
        es.dataSavedLocally,
        isA<String>(),
        reason: 'dataSavedLocally (es)',
      );
      expect(
        es.dataSavedLocally.isNotEmpty,
        isTrue,
        reason: 'dataSavedLocally (es) should not be empty',
      );
      expect(
        es.wristbandWritten,
        isA<String>(),
        reason: 'wristbandWritten (es)',
      );
      expect(
        es.wristbandWritten.isNotEmpty,
        isTrue,
        reason: 'wristbandWritten (es) should not be empty',
      );
      expect(es.syncPending, isA<String>(), reason: 'syncPending (es)');
      expect(
        es.syncPending.isNotEmpty,
        isTrue,
        reason: 'syncPending (es) should not be empty',
      );
      expect(
        es.confirmRegistration,
        isA<String>(),
        reason: 'confirmRegistration (es)',
      );
      expect(
        es.confirmRegistration.isNotEmpty,
        isTrue,
        reason: 'confirmRegistration (es) should not be empty',
      );
      expect(es.reviewData, isA<String>(), reason: 'reviewData (es)');
      expect(
        es.reviewData.isNotEmpty,
        isTrue,
        reason: 'reviewData (es) should not be empty',
      );
      expect(es.addConsultation, isA<String>(), reason: 'addConsultation (es)');
      expect(
        es.addConsultation.isNotEmpty,
        isTrue,
        reason: 'addConsultation (es) should not be empty',
      );
      expect(es.addVaccine, isA<String>(), reason: 'addVaccine (es)');
      expect(
        es.addVaccine.isNotEmpty,
        isTrue,
        reason: 'addVaccine (es) should not be empty',
      );
      expect(es.goHome, isA<String>(), reason: 'goHome (es)');
      expect(
        es.goHome.isNotEmpty,
        isTrue,
        reason: 'goHome (es) should not be empty',
      );
      expect(es.saving, isA<String>(), reason: 'saving (es)');
      expect(
        es.saving.isNotEmpty,
        isTrue,
        reason: 'saving (es) should not be empty',
      );
      expect(es.saveError, isA<String>(), reason: 'saveError (es)');
      expect(
        es.saveError.isNotEmpty,
        isTrue,
        reason: 'saveError (es) should not be empty',
      );
      expect(es.newPatient, isA<String>(), reason: 'newPatient (es)');
      expect(
        es.newPatient.isNotEmpty,
        isTrue,
        reason: 'newPatient (es) should not be empty',
      );
      expect(
        es.consultationSaved,
        isA<String>(),
        reason: 'consultationSaved (es)',
      );
      expect(
        es.consultationSaved.isNotEmpty,
        isTrue,
        reason: 'consultationSaved (es) should not be empty',
      );
      expect(es.vaccineSaved, isA<String>(), reason: 'vaccineSaved (es)');
      expect(
        es.vaccineSaved.isNotEmpty,
        isTrue,
        reason: 'vaccineSaved (es) should not be empty',
      );
      expect(es.today, isA<String>(), reason: 'today (es)');
      expect(
        es.today.isNotEmpty,
        isTrue,
        reason: 'today (es) should not be empty',
      );
      expect(
        es.patientNfcDevice,
        isA<String>(),
        reason: 'patientNfcDevice (es)',
      );
      expect(
        es.patientNfcDevice.isNotEmpty,
        isTrue,
        reason: 'patientNfcDevice (es) should not be empty',
      );
      expect(
        es.patientNfcDeviceSub,
        isA<String>(),
        reason: 'patientNfcDeviceSub (es)',
      );
      expect(
        es.patientNfcDeviceSub.isNotEmpty,
        isTrue,
        reason: 'patientNfcDeviceSub (es) should not be empty',
      );
      expect(es.nfcUidRequired, isA<String>(), reason: 'nfcUidRequired (es)');
      expect(
        es.nfcUidRequired.isNotEmpty,
        isTrue,
        reason: 'nfcUidRequired (es) should not be empty',
      );

      // ── Patient form fields ──
      expect(es.identification, isA<String>(), reason: 'identification (es)');
      expect(
        es.identification.isNotEmpty,
        isTrue,
        reason: 'identification (es) should not be empty',
      );
      expect(es.documentType, isA<String>(), reason: 'documentType (es)');
      expect(
        es.documentType.isNotEmpty,
        isTrue,
        reason: 'documentType (es) should not be empty',
      );
      expect(es.documentNumber, isA<String>(), reason: 'documentNumber (es)');
      expect(
        es.documentNumber.isNotEmpty,
        isTrue,
        reason: 'documentNumber (es) should not be empty',
      );
      expect(es.firstNames, isA<String>(), reason: 'firstNames (es)');
      expect(
        es.firstNames.isNotEmpty,
        isTrue,
        reason: 'firstNames (es) should not be empty',
      );
      expect(es.secondName, isA<String>(), reason: 'secondName (es)');
      expect(
        es.secondName.isNotEmpty,
        isTrue,
        reason: 'secondName (es) should not be empty',
      );
      expect(es.firstLastName, isA<String>(), reason: 'firstLastName (es)');
      expect(
        es.firstLastName.isNotEmpty,
        isTrue,
        reason: 'firstLastName (es) should not be empty',
      );
      expect(es.secondLastName, isA<String>(), reason: 'secondLastName (es)');
      expect(
        es.secondLastName.isNotEmpty,
        isTrue,
        reason: 'secondLastName (es) should not be empty',
      );
      expect(es.gender, isA<String>(), reason: 'gender (es)');
      expect(
        es.gender.isNotEmpty,
        isTrue,
        reason: 'gender (es) should not be empty',
      );
      expect(es.dateOfBirth, isA<String>(), reason: 'dateOfBirth (es)');
      expect(
        es.dateOfBirth.isNotEmpty,
        isTrue,
        reason: 'dateOfBirth (es) should not be empty',
      );
      expect(es.nationality, isA<String>(), reason: 'nationality (es)');
      expect(
        es.nationality.isNotEmpty,
        isTrue,
        reason: 'nationality (es) should not be empty',
      );
      expect(es.origin, isA<String>(), reason: 'origin (es)');
      expect(
        es.origin.isNotEmpty,
        isTrue,
        reason: 'origin (es) should not be empty',
      );
      expect(es.cityRegion, isA<String>(), reason: 'cityRegion (es)');
      expect(
        es.cityRegion.isNotEmpty,
        isTrue,
        reason: 'cityRegion (es) should not be empty',
      );
      expect(es.stateDepartment, isA<String>(), reason: 'stateDepartment (es)');
      expect(
        es.stateDepartment.isNotEmpty,
        isTrue,
        reason: 'stateDepartment (es) should not be empty',
      );
      expect(es.clinicalData, isA<String>(), reason: 'clinicalData (es)');
      expect(
        es.clinicalData.isNotEmpty,
        isTrue,
        reason: 'clinicalData (es) should not be empty',
      );
      expect(es.bloodType, isA<String>(), reason: 'bloodType (es)');
      expect(
        es.bloodType.isNotEmpty,
        isTrue,
        reason: 'bloodType (es) should not be empty',
      );
      expect(es.weight, isA<String>(), reason: 'weight (es)');
      expect(
        es.weight.isNotEmpty,
        isTrue,
        reason: 'weight (es) should not be empty',
      );
      expect(es.height, isA<String>(), reason: 'height (es)');
      expect(
        es.height.isNotEmpty,
        isTrue,
        reason: 'height (es) should not be empty',
      );

      // ── Guardian ──
      expect(es.guardianSection, isA<String>(), reason: 'guardianSection (es)');
      expect(
        es.guardianSection.isNotEmpty,
        isTrue,
        reason: 'guardianSection (es) should not be empty',
      );
      expect(es.guardianName, isA<String>(), reason: 'guardianName (es)');
      expect(
        es.guardianName.isNotEmpty,
        isTrue,
        reason: 'guardianName (es) should not be empty',
      );
      expect(es.relationship, isA<String>(), reason: 'relationship (es)');
      expect(
        es.relationship.isNotEmpty,
        isTrue,
        reason: 'relationship (es) should not be empty',
      );
      expect(es.guardianPhone, isA<String>(), reason: 'guardianPhone (es)');
      expect(
        es.guardianPhone.isNotEmpty,
        isTrue,
        reason: 'guardianPhone (es) should not be empty',
      );
      expect(es.guardianPin, isA<String>(), reason: 'guardianPin (es)');
      expect(
        es.guardianPin.isNotEmpty,
        isTrue,
        reason: 'guardianPin (es) should not be empty',
      );
      expect(es.guardianDocType, isA<String>(), reason: 'guardianDocType (es)');
      expect(
        es.guardianDocType.isNotEmpty,
        isTrue,
        reason: 'guardianDocType (es) should not be empty',
      );
      expect(
        es.guardianDocNumber,
        isA<String>(),
        reason: 'guardianDocNumber (es)',
      );
      expect(
        es.guardianDocNumber.isNotEmpty,
        isTrue,
        reason: 'guardianDocNumber (es) should not be empty',
      );
      expect(
        es.guardianAuthAccepted,
        isA<String>(),
        reason: 'guardianAuthAccepted (es)',
      );
      expect(
        es.guardianAuthAccepted.isNotEmpty,
        isTrue,
        reason: 'guardianAuthAccepted (es) should not be empty',
      );
      expect(es.guardianEmail, isA<String>(), reason: 'guardianEmail (es)');
      expect(
        es.guardianEmail.isNotEmpty,
        isTrue,
        reason: 'guardianEmail (es) should not be empty',
      );
      expect(
        es.editGuardianTitle,
        isA<String>(),
        reason: 'editGuardianTitle (es)',
      );
      expect(
        es.editGuardianTitle.isNotEmpty,
        isTrue,
        reason: 'editGuardianTitle (es) should not be empty',
      );
      expect(
        es.guardianFullName,
        isA<String>(),
        reason: 'guardianFullName (es)',
      );
      expect(
        es.guardianFullName.isNotEmpty,
        isTrue,
        reason: 'guardianFullName (es) should not be empty',
      );
      expect(
        es.guardianFullNameHint,
        isA<String>(),
        reason: 'guardianFullNameHint (es)',
      );
      expect(
        es.guardianFullNameHint.isNotEmpty,
        isTrue,
        reason: 'guardianFullNameHint (es) should not be empty',
      );
      expect(
        es.guardianRelationship,
        isA<String>(),
        reason: 'guardianRelationship (es)',
      );
      expect(
        es.guardianRelationship.isNotEmpty,
        isTrue,
        reason: 'guardianRelationship (es) should not be empty',
      );
      expect(
        es.guardianPhoneLabel,
        isA<String>(),
        reason: 'guardianPhoneLabel (es)',
      );
      expect(
        es.guardianPhoneLabel.isNotEmpty,
        isTrue,
        reason: 'guardianPhoneLabel (es) should not be empty',
      );
      expect(
        es.guardianPhoneHint,
        isA<String>(),
        reason: 'guardianPhoneHint (es)',
      );
      expect(
        es.guardianPhoneHint.isNotEmpty,
        isTrue,
        reason: 'guardianPhoneHint (es) should not be empty',
      );
      expect(
        es.guardianNfcDevice,
        isA<String>(),
        reason: 'guardianNfcDevice (es)',
      );
      expect(
        es.guardianNfcDevice.isNotEmpty,
        isTrue,
        reason: 'guardianNfcDevice (es) should not be empty',
      );
      expect(
        es.guardianNfcUidHint,
        isA<String>(),
        reason: 'guardianNfcUidHint (es)',
      );
      expect(
        es.guardianNfcUidHint.isNotEmpty,
        isTrue,
        reason: 'guardianNfcUidHint (es) should not be empty',
      );
      expect(
        es.guardianNfcUnavailable,
        isA<String>(),
        reason: 'guardianNfcUnavailable (es)',
      );
      expect(
        es.guardianNfcUnavailable.isNotEmpty,
        isTrue,
        reason: 'guardianNfcUnavailable (es) should not be empty',
      );
      expect(
        es.guardianNfcError,
        isA<String>(),
        reason: 'guardianNfcError (es)',
      );
      expect(
        es.guardianNfcError.isNotEmpty,
        isTrue,
        reason: 'guardianNfcError (es) should not be empty',
      );
      expect(es.relParents, isA<String>(), reason: 'relParents (es)');
      expect(
        es.relParents.isNotEmpty,
        isTrue,
        reason: 'relParents (es) should not be empty',
      );
      expect(es.relSiblings, isA<String>(), reason: 'relSiblings (es)');
      expect(
        es.relSiblings.isNotEmpty,
        isTrue,
        reason: 'relSiblings (es) should not be empty',
      );
      expect(es.relUncles, isA<String>(), reason: 'relUncles (es)');
      expect(
        es.relUncles.isNotEmpty,
        isTrue,
        reason: 'relUncles (es) should not be empty',
      );
      expect(es.relGrandparents, isA<String>(), reason: 'relGrandparents (es)');
      expect(
        es.relGrandparents.isNotEmpty,
        isTrue,
        reason: 'relGrandparents (es) should not be empty',
      );

      // ── Read NFC ──
      expect(es.scanWristband, isA<String>(), reason: 'scanWristband (es)');
      expect(
        es.scanWristband.isNotEmpty,
        isTrue,
        reason: 'scanWristband (es) should not be empty',
      );
      expect(es.holdWristband, isA<String>(), reason: 'holdWristband (es)');
      expect(
        es.holdWristband.isNotEmpty,
        isTrue,
        reason: 'holdWristband (es) should not be empty',
      );
      expect(es.scanning, isA<String>(), reason: 'scanning (es)');
      expect(
        es.scanning.isNotEmpty,
        isTrue,
        reason: 'scanning (es) should not be empty',
      );
      expect(es.scanSuccess, isA<String>(), reason: 'scanSuccess (es)');
      expect(
        es.scanSuccess.isNotEmpty,
        isTrue,
        reason: 'scanSuccess (es) should not be empty',
      );
      expect(es.scanFailed, isA<String>(), reason: 'scanFailed (es)');
      expect(
        es.scanFailed.isNotEmpty,
        isTrue,
        reason: 'scanFailed (es) should not be empty',
      );
      expect(
        es.guardianRequired,
        isA<String>(),
        reason: 'guardianRequired (es)',
      );
      expect(
        es.guardianRequired.isNotEmpty,
        isTrue,
        reason: 'guardianRequired (es) should not be empty',
      );
      expect(
        es.guardianRequiredSub,
        isA<String>(),
        reason: 'guardianRequiredSub (es)',
      );
      expect(
        es.guardianRequiredSub.isNotEmpty,
        isTrue,
        reason: 'guardianRequiredSub (es) should not be empty',
      );
      expect(
        es.scanGuardianWristband,
        isA<String>(),
        reason: 'scanGuardianWristband (es)',
      );
      expect(
        es.scanGuardianWristband.isNotEmpty,
        isTrue,
        reason: 'scanGuardianWristband (es) should not be empty',
      );
      expect(es.continueToRead, isA<String>(), reason: 'continueToRead (es)');
      expect(
        es.continueToRead.isNotEmpty,
        isTrue,
        reason: 'continueToRead (es) should not be empty',
      );
      expect(es.readyToScan, isA<String>(), reason: 'readyToScan (es)');
      expect(
        es.readyToScan.isNotEmpty,
        isTrue,
        reason: 'readyToScan (es) should not be empty',
      );

      // ── Patient detail ──
      expect(es.patient, isA<String>(), reason: 'patient (es)');
      expect(
        es.patient.isNotEmpty,
        isTrue,
        reason: 'patient (es) should not be empty',
      );
      expect(es.guardian, isA<String>(), reason: 'guardian (es)');
      expect(
        es.guardian.isNotEmpty,
        isTrue,
        reason: 'guardian (es) should not be empty',
      );
      expect(es.medicalHistory, isA<String>(), reason: 'medicalHistory (es)');
      expect(
        es.medicalHistory.isNotEmpty,
        isTrue,
        reason: 'medicalHistory (es) should not be empty',
      );
      expect(es.medicalStaff, isA<String>(), reason: 'medicalStaff (es)');
      expect(
        es.medicalStaff.isNotEmpty,
        isTrue,
        reason: 'medicalStaff (es) should not be empty',
      );
      expect(es.consultations, isA<String>(), reason: 'consultations (es)');
      expect(
        es.consultations.isNotEmpty,
        isTrue,
        reason: 'consultations (es) should not be empty',
      );
      expect(es.vaccines, isA<String>(), reason: 'vaccines (es)');
      expect(
        es.vaccines.isNotEmpty,
        isTrue,
        reason: 'vaccines (es) should not be empty',
      );
      expect(es.allergens, isA<String>(), reason: 'allergens (es)');
      expect(
        es.allergens.isNotEmpty,
        isTrue,
        reason: 'allergens (es) should not be empty',
      );
      expect(es.showVaccines, isA<String>(), reason: 'showVaccines (es)');
      expect(
        es.showVaccines.isNotEmpty,
        isTrue,
        reason: 'showVaccines (es) should not be empty',
      );
      expect(es.moreDetails, isA<String>(), reason: 'moreDetails (es)');
      expect(
        es.moreDetails.isNotEmpty,
        isTrue,
        reason: 'moreDetails (es) should not be empty',
      );
      expect(es.updatePatient, isA<String>(), reason: 'updatePatient (es)');
      expect(
        es.updatePatient.isNotEmpty,
        isTrue,
        reason: 'updatePatient (es) should not be empty',
      );
      expect(es.lastUpdated, isA<String>(), reason: 'lastUpdated (es)');
      expect(
        es.lastUpdated.isNotEmpty,
        isTrue,
        reason: 'lastUpdated (es) should not be empty',
      );
      expect(
        es.chronicCondition,
        isA<String>(),
        reason: 'chronicCondition (es)',
      );
      expect(
        es.chronicCondition.isNotEmpty,
        isTrue,
        reason: 'chronicCondition (es) should not be empty',
      );

      // ── Edit screens ──
      expect(es.editUpdate, isA<String>(), reason: 'editUpdate (es)');
      expect(
        es.editUpdate.isNotEmpty,
        isTrue,
        reason: 'editUpdate (es) should not be empty',
      );
      expect(
        es.patientInfoReadOnly,
        isA<String>(),
        reason: 'patientInfoReadOnly (es)',
      );
      expect(
        es.patientInfoReadOnly.isNotEmpty,
        isTrue,
        reason: 'patientInfoReadOnly (es) should not be empty',
      );
      expect(es.fieldsProtected, isA<String>(), reason: 'fieldsProtected (es)');
      expect(
        es.fieldsProtected.isNotEmpty,
        isTrue,
        reason: 'fieldsProtected (es) should not be empty',
      );
      expect(es.editableInfo, isA<String>(), reason: 'editableInfo (es)');
      expect(
        es.editableInfo.isNotEmpty,
        isTrue,
        reason: 'editableInfo (es) should not be empty',
      );
      expect(es.address, isA<String>(), reason: 'address (es)');
      expect(
        es.address.isNotEmpty,
        isTrue,
        reason: 'address (es) should not be empty',
      );
      expect(es.street, isA<String>(), reason: 'street (es)');
      expect(
        es.street.isNotEmpty,
        isTrue,
        reason: 'street (es) should not be empty',
      );
      expect(es.city, isA<String>(), reason: 'city (es)');
      expect(
        es.city.isNotEmpty,
        isTrue,
        reason: 'city (es) should not be empty',
      );
      expect(es.state, isA<String>(), reason: 'state (es)');
      expect(
        es.state.isNotEmpty,
        isTrue,
        reason: 'state (es) should not be empty',
      );
      expect(es.name, isA<String>(), reason: 'name (es)');
      expect(
        es.name.isNotEmpty,
        isTrue,
        reason: 'name (es) should not be empty',
      );

      // ── Edit address sheet ──
      expect(es.editResidence, isA<String>(), reason: 'editResidence (es)');
      expect(
        es.editResidence.isNotEmpty,
        isTrue,
        reason: 'editResidence (es) should not be empty',
      );
      expect(
        es.addressZoneSubtitle,
        isA<String>(),
        reason: 'addressZoneSubtitle (es)',
      );
      expect(
        es.addressZoneSubtitle.isNotEmpty,
        isTrue,
        reason: 'addressZoneSubtitle (es) should not be empty',
      );
      expect(es.municipality, isA<String>(), reason: 'municipality (es)');
      expect(
        es.municipality.isNotEmpty,
        isTrue,
        reason: 'municipality (es) should not be empty',
      );
      expect(es.department, isA<String>(), reason: 'department (es)');
      expect(
        es.department.isNotEmpty,
        isTrue,
        reason: 'department (es) should not be empty',
      );
      expect(es.zone, isA<String>(), reason: 'zone (es)');
      expect(
        es.zone.isNotEmpty,
        isTrue,
        reason: 'zone (es) should not be empty',
      );
      expect(es.streetHint, isA<String>(), reason: 'streetHint (es)');
      expect(
        es.streetHint.isNotEmpty,
        isTrue,
        reason: 'streetHint (es) should not be empty',
      );
      expect(es.cityHint, isA<String>(), reason: 'cityHint (es)');
      expect(
        es.cityHint.isNotEmpty,
        isTrue,
        reason: 'cityHint (es) should not be empty',
      );
      expect(es.stateHint, isA<String>(), reason: 'stateHint (es)');
      expect(
        es.stateHint.isNotEmpty,
        isTrue,
        reason: 'stateHint (es) should not be empty',
      );
      expect(es.zoneUrban, isA<String>(), reason: 'zoneUrban (es)');
      expect(
        es.zoneUrban.isNotEmpty,
        isTrue,
        reason: 'zoneUrban (es) should not be empty',
      );
      expect(es.zoneRural, isA<String>(), reason: 'zoneRural (es)');
      expect(
        es.zoneRural.isNotEmpty,
        isTrue,
        reason: 'zoneRural (es) should not be empty',
      );

      // ── Medical history edit ──
      expect(
        es.clinicalEvaluation,
        isA<String>(),
        reason: 'clinicalEvaluation (es)',
      );
      expect(
        es.clinicalEvaluation.isNotEmpty,
        isTrue,
        reason: 'clinicalEvaluation (es) should not be empty',
      );
      expect(
        es.historyCurrentIllness,
        isA<String>(),
        reason: 'historyCurrentIllness (es)',
      );
      expect(
        es.historyCurrentIllness.isNotEmpty,
        isTrue,
        reason: 'historyCurrentIllness (es) should not be empty',
      );
      expect(es.treatmentPlan, isA<String>(), reason: 'treatmentPlan (es)');
      expect(
        es.treatmentPlan.isNotEmpty,
        isTrue,
        reason: 'treatmentPlan (es) should not be empty',
      );
      expect(
        es.backgroundHistory,
        isA<String>(),
        reason: 'backgroundHistory (es)',
      );
      expect(
        es.backgroundHistory.isNotEmpty,
        isTrue,
        reason: 'backgroundHistory (es) should not be empty',
      );
      expect(
        es.chronicConditions,
        isA<String>(),
        reason: 'chronicConditions (es)',
      );
      expect(
        es.chronicConditions.isNotEmpty,
        isTrue,
        reason: 'chronicConditions (es) should not be empty',
      );
      expect(es.personalHistory, isA<String>(), reason: 'personalHistory (es)');
      expect(
        es.personalHistory.isNotEmpty,
        isTrue,
        reason: 'personalHistory (es) should not be empty',
      );
      expect(es.familyHistory, isA<String>(), reason: 'familyHistory (es)');
      expect(
        es.familyHistory.isNotEmpty,
        isTrue,
        reason: 'familyHistory (es) should not be empty',
      );
      expect(
        es.familyHistoryNotes,
        isA<String>(),
        reason: 'familyHistoryNotes (es)',
      );
      expect(
        es.familyHistoryNotes.isNotEmpty,
        isTrue,
        reason: 'familyHistoryNotes (es) should not be empty',
      );
      expect(
        es.addFamilyHistory,
        isA<String>(),
        reason: 'addFamilyHistory (es)',
      );
      expect(
        es.addFamilyHistory.isNotEmpty,
        isTrue,
        reason: 'addFamilyHistory (es) should not be empty',
      );
      expect(es.condition, isA<String>(), reason: 'condition (es)');
      expect(
        es.condition.isNotEmpty,
        isTrue,
        reason: 'condition (es) should not be empty',
      );
      expect(es.noFamilyHistory, isA<String>(), reason: 'noFamilyHistory (es)');
      expect(
        es.noFamilyHistory.isNotEmpty,
        isTrue,
        reason: 'noFamilyHistory (es) should not be empty',
      );
      expect(es.physicalExam, isA<String>(), reason: 'physicalExam (es)');
      expect(
        es.physicalExam.isNotEmpty,
        isTrue,
        reason: 'physicalExam (es) should not be empty',
      );
      expect(es.generalExam, isA<String>(), reason: 'generalExam (es)');
      expect(
        es.generalExam.isNotEmpty,
        isTrue,
        reason: 'generalExam (es) should not be empty',
      );
      expect(es.systemsExam, isA<String>(), reason: 'systemsExam (es)');
      expect(
        es.systemsExam.isNotEmpty,
        isTrue,
        reason: 'systemsExam (es) should not be empty',
      );
      expect(es.add, isA<String>(), reason: 'add (es)');
      expect(es.add.isNotEmpty, isTrue, reason: 'add (es) should not be empty');

      // ── Medical staff edit ──
      expect(es.practitioner, isA<String>(), reason: 'practitioner (es)');
      expect(
        es.practitioner.isNotEmpty,
        isTrue,
        reason: 'practitioner (es) should not be empty',
      );
      expect(
        es.healthcareProvider,
        isA<String>(),
        reason: 'healthcareProvider (es)',
      );
      expect(
        es.healthcareProvider.isNotEmpty,
        isTrue,
        reason: 'healthcareProvider (es) should not be empty',
      );
      expect(es.providerName, isA<String>(), reason: 'providerName (es)');
      expect(
        es.providerName.isNotEmpty,
        isTrue,
        reason: 'providerName (es) should not be empty',
      );
      expect(es.repsCode, isA<String>(), reason: 'repsCode (es)');
      expect(
        es.repsCode.isNotEmpty,
        isTrue,
        reason: 'repsCode (es) should not be empty',
      );
      expect(es.encounter, isA<String>(), reason: 'encounter (es)');
      expect(
        es.encounter.isNotEmpty,
        isTrue,
        reason: 'encounter (es) should not be empty',
      );
      expect(es.dateTime, isA<String>(), reason: 'dateTime (es)');
      expect(
        es.dateTime.isNotEmpty,
        isTrue,
        reason: 'dateTime (es) should not be empty',
      );
      expect(es.diagnosisType, isA<String>(), reason: 'diagnosisType (es)');
      expect(
        es.diagnosisType.isNotEmpty,
        isTrue,
        reason: 'diagnosisType (es) should not be empty',
      );
      expect(es.careModality, isA<String>(), reason: 'careModality (es)');
      expect(
        es.careModality.isNotEmpty,
        isTrue,
        reason: 'careModality (es) should not be empty',
      );
      expect(
        es.dischargeDisposition,
        isA<String>(),
        reason: 'dischargeDisposition (es)',
      );
      expect(
        es.dischargeDisposition.isNotEmpty,
        isTrue,
        reason: 'dischargeDisposition (es) should not be empty',
      );

      // ── Loss of wristband ──
      expect(es.searchPatient, isA<String>(), reason: 'searchPatient (es)');
      expect(
        es.searchPatient.isNotEmpty,
        isTrue,
        reason: 'searchPatient (es) should not be empty',
      );
      expect(
        es.searchRequiredFields,
        isA<String>(),
        reason: 'searchRequiredFields (es)',
      );
      expect(
        es.searchRequiredFields.isNotEmpty,
        isTrue,
        reason: 'searchRequiredFields (es) should not be empty',
      );
      expect(
        es.searchFieldsRequired,
        isA<String>(),
        reason: 'searchFieldsRequired (es)',
      );
      expect(
        es.searchFieldsRequired.isNotEmpty,
        isTrue,
        reason: 'searchFieldsRequired (es) should not be empty',
      );

      // ── Sync ──
      expect(es.syncTitle, isA<String>(), reason: 'syncTitle (es)');
      expect(
        es.syncTitle.isNotEmpty,
        isTrue,
        reason: 'syncTitle (es) should not be empty',
      );
      expect(es.syncAll, isA<String>(), reason: 'syncAll (es)');
      expect(
        es.syncAll.isNotEmpty,
        isTrue,
        reason: 'syncAll (es) should not be empty',
      );
      expect(es.syncNow, isA<String>(), reason: 'syncNow (es)');
      expect(
        es.syncNow.isNotEmpty,
        isTrue,
        reason: 'syncNow (es) should not be empty',
      );
      expect(es.review, isA<String>(), reason: 'review (es)');
      expect(
        es.review.isNotEmpty,
        isTrue,
        reason: 'review (es) should not be empty',
      );
      expect(
        es.syncedSuccessfully,
        isA<String>(),
        reason: 'syncedSuccessfully (es)',
      );
      expect(
        es.syncedSuccessfully.isNotEmpty,
        isTrue,
        reason: 'syncedSuccessfully (es) should not be empty',
      );
      expect(es.syncFailedRetry, isA<String>(), reason: 'syncFailedRetry (es)');
      expect(
        es.syncFailedRetry.isNotEmpty,
        isTrue,
        reason: 'syncFailedRetry (es) should not be empty',
      );
      expect(es.allSynced, isA<String>(), reason: 'allSynced (es)');
      expect(
        es.allSynced.isNotEmpty,
        isTrue,
        reason: 'allSynced (es) should not be empty',
      );
      expect(
        es.noRecordsPending,
        isA<String>(),
        reason: 'noRecordsPending (es)',
      );
      expect(
        es.noRecordsPending.isNotEmpty,
        isTrue,
        reason: 'noRecordsPending (es) should not be empty',
      );
      expect(es.deleteRecord, isA<String>(), reason: 'deleteRecord (es)');
      expect(
        es.deleteRecord.isNotEmpty,
        isTrue,
        reason: 'deleteRecord (es) should not be empty',
      );
      expect(
        es.deleteRecordConfirm,
        isA<String>(),
        reason: 'deleteRecordConfirm (es)',
      );
      expect(
        es.deleteRecordConfirm.isNotEmpty,
        isTrue,
        reason: 'deleteRecordConfirm (es) should not be empty',
      );
      expect(es.pending, isA<String>(), reason: 'pending (es)');
      expect(
        es.pending.isNotEmpty,
        isTrue,
        reason: 'pending (es) should not be empty',
      );

      // ── Brigade ──
      expect(es.brigadeOffline, isA<String>(), reason: 'brigadeOffline (es)');
      expect(
        es.brigadeOffline.isNotEmpty,
        isTrue,
        reason: 'brigadeOffline (es) should not be empty',
      );
      expect(
        es.patientsAppearHere,
        isA<String>(),
        reason: 'patientsAppearHere (es)',
      );
      expect(
        es.patientsAppearHere.isNotEmpty,
        isTrue,
        reason: 'patientsAppearHere (es) should not be empty',
      );
      expect(es.synchronized, isA<String>(), reason: 'synchronized (es)');
      expect(
        es.synchronized.isNotEmpty,
        isTrue,
        reason: 'synchronized (es) should not be empty',
      );
      expect(es.synchronizing, isA<String>(), reason: 'synchronizing (es)');
      expect(
        es.synchronizing.isNotEmpty,
        isTrue,
        reason: 'synchronizing (es) should not be empty',
      );

      // ── NFC Save Flow ──
      expect(es.putOnWristband, isA<String>(), reason: 'putOnWristband (es)');
      expect(
        es.putOnWristband.isNotEmpty,
        isTrue,
        reason: 'putOnWristband (es) should not be empty',
      );
      expect(es.placeWristband, isA<String>(), reason: 'placeWristband (es)');
      expect(
        es.placeWristband.isNotEmpty,
        isTrue,
        reason: 'placeWristband (es) should not be empty',
      );
      expect(es.startWriting, isA<String>(), reason: 'startWriting (es)');
      expect(
        es.startWriting.isNotEmpty,
        isTrue,
        reason: 'startWriting (es) should not be empty',
      );
      expect(es.syncingServer, isA<String>(), reason: 'syncingServer (es)');
      expect(
        es.syncingServer.isNotEmpty,
        isTrue,
        reason: 'syncingServer (es) should not be empty',
      );
      expect(es.pleaseWait, isA<String>(), reason: 'pleaseWait (es)');
      expect(
        es.pleaseWait.isNotEmpty,
        isTrue,
        reason: 'pleaseWait (es) should not be empty',
      );
      expect(
        es.successRegistration,
        isA<String>(),
        reason: 'successRegistration (es)',
      );
      expect(
        es.successRegistration.isNotEmpty,
        isTrue,
        reason: 'successRegistration (es) should not be empty',
      );
      expect(
        es.patientSavedSynced,
        isA<String>(),
        reason: 'patientSavedSynced (es)',
      );
      expect(
        es.patientSavedSynced.isNotEmpty,
        isTrue,
        reason: 'patientSavedSynced (es) should not be empty',
      );
      expect(es.syncFailed, isA<String>(), reason: 'syncFailed (es)');
      expect(
        es.syncFailed.isNotEmpty,
        isTrue,
        reason: 'syncFailed (es) should not be empty',
      );

      // ── Vaccine sheet ──
      expect(es.vaccine, isA<String>(), reason: 'vaccine (es)');
      expect(
        es.vaccine.isNotEmpty,
        isTrue,
        reason: 'vaccine (es) should not be empty',
      );
      expect(es.vaccineName, isA<String>(), reason: 'vaccineName (es)');
      expect(
        es.vaccineName.isNotEmpty,
        isTrue,
        reason: 'vaccineName (es) should not be empty',
      );
      expect(es.cvxCode, isA<String>(), reason: 'cvxCode (es)');
      expect(
        es.cvxCode.isNotEmpty,
        isTrue,
        reason: 'cvxCode (es) should not be empty',
      );
      expect(es.dose, isA<String>(), reason: 'dose (es)');
      expect(
        es.dose.isNotEmpty,
        isTrue,
        reason: 'dose (es) should not be empty',
      );
      expect(es.date, isA<String>(), reason: 'date (es)');
      expect(
        es.date.isNotEmpty,
        isTrue,
        reason: 'date (es) should not be empty',
      );
      expect(es.administeredBy, isA<String>(), reason: 'administeredBy (es)');
      expect(
        es.administeredBy.isNotEmpty,
        isTrue,
        reason: 'administeredBy (es) should not be empty',
      );
      expect(es.administeredAt, isA<String>(), reason: 'administeredAt (es)');
      expect(
        es.administeredAt.isNotEmpty,
        isTrue,
        reason: 'administeredAt (es) should not be empty',
      );

      // ── Vital signs sheet ──
      expect(
        es.editMeasurements,
        isA<String>(),
        reason: 'editMeasurements (es)',
      );
      expect(
        es.editMeasurements.isNotEmpty,
        isTrue,
        reason: 'editMeasurements (es) should not be empty',
      );
      expect(es.weightKg, isA<String>(), reason: 'weightKg (es)');
      expect(
        es.weightKg.isNotEmpty,
        isTrue,
        reason: 'weightKg (es) should not be empty',
      );
      expect(es.heightCm, isA<String>(), reason: 'heightCm (es)');
      expect(
        es.heightCm.isNotEmpty,
        isTrue,
        reason: 'heightCm (es) should not be empty',
      );
      expect(es.previous, isA<String>(), reason: 'previous (es)');
      expect(
        es.previous.isNotEmpty,
        isTrue,
        reason: 'previous (es) should not be empty',
      );
      expect(
        es.bloodTypeReadOnly,
        isA<String>(),
        reason: 'bloodTypeReadOnly (es)',
      );
      expect(
        es.bloodTypeReadOnly.isNotEmpty,
        isTrue,
        reason: 'bloodTypeReadOnly (es) should not be empty',
      );

      // ── Allergen categories ──
      expect(
        es.allergenMedication,
        isA<String>(),
        reason: 'allergenMedication (es)',
      );
      expect(
        es.allergenMedication.isNotEmpty,
        isTrue,
        reason: 'allergenMedication (es) should not be empty',
      );
      expect(es.allergenFood, isA<String>(), reason: 'allergenFood (es)');
      expect(
        es.allergenFood.isNotEmpty,
        isTrue,
        reason: 'allergenFood (es) should not be empty',
      );
      expect(
        es.allergenEnvironment,
        isA<String>(),
        reason: 'allergenEnvironment (es)',
      );
      expect(
        es.allergenEnvironment.isNotEmpty,
        isTrue,
        reason: 'allergenEnvironment (es) should not be empty',
      );
      expect(es.allergenSkin, isA<String>(), reason: 'allergenSkin (es)');
      expect(
        es.allergenSkin.isNotEmpty,
        isTrue,
        reason: 'allergenSkin (es) should not be empty',
      );
      expect(es.allergenInsect, isA<String>(), reason: 'allergenInsect (es)');
      expect(
        es.allergenInsect.isNotEmpty,
        isTrue,
        reason: 'allergenInsect (es) should not be empty',
      );
      expect(es.allergenOther, isA<String>(), reason: 'allergenOther (es)');
      expect(
        es.allergenOther.isNotEmpty,
        isTrue,
        reason: 'allergenOther (es) should not be empty',
      );

      // ── Login screen v2 / Home v2 ──
      expect(
        es.appSubtitleShort,
        isA<String>(),
        reason: 'appSubtitleShort (es)',
      );
      expect(
        es.appSubtitleShort.isNotEmpty,
        isTrue,
        reason: 'appSubtitleShort (es) should not be empty',
      );
      expect(es.emailLabel, isA<String>(), reason: 'emailLabel (es)');
      expect(
        es.emailLabel.isNotEmpty,
        isTrue,
        reason: 'emailLabel (es) should not be empty',
      );
      expect(es.passwordLabel, isA<String>(), reason: 'passwordLabel (es)');
      expect(
        es.passwordLabel.isNotEmpty,
        isTrue,
        reason: 'passwordLabel (es) should not be empty',
      );
      expect(es.rememberSession, isA<String>(), reason: 'rememberSession (es)');
      expect(
        es.rememberSession.isNotEmpty,
        isTrue,
        reason: 'rememberSession (es) should not be empty',
      );
      expect(
        es.sessionEncryptedFooter,
        isA<String>(),
        reason: 'sessionEncryptedFooter (es)',
      );
      expect(
        es.sessionEncryptedFooter.isNotEmpty,
        isTrue,
        reason: 'sessionEncryptedFooter (es) should not be empty',
      );
      expect(es.goodMorning, isA<String>(), reason: 'goodMorning (es)');
      expect(
        es.goodMorning.isNotEmpty,
        isTrue,
        reason: 'goodMorning (es) should not be empty',
      );
      expect(es.goodAfternoon, isA<String>(), reason: 'goodAfternoon (es)');
      expect(
        es.goodAfternoon.isNotEmpty,
        isTrue,
        reason: 'goodAfternoon (es) should not be empty',
      );
      expect(es.goodEvening, isA<String>(), reason: 'goodEvening (es)');
      expect(
        es.goodEvening.isNotEmpty,
        isTrue,
        reason: 'goodEvening (es) should not be empty',
      );
      expect(es.logout, isA<String>(), reason: 'logout (es)');
      expect(
        es.logout.isNotEmpty,
        isTrue,
        reason: 'logout (es) should not be empty',
      );
      expect(es.logoutTitle, isA<String>(), reason: 'logoutTitle (es)');
      expect(
        es.logoutTitle.isNotEmpty,
        isTrue,
        reason: 'logoutTitle (es) should not be empty',
      );
      expect(es.roleDoctor, isA<String>(), reason: 'roleDoctor (es)');
      expect(
        es.roleDoctor.isNotEmpty,
        isTrue,
        reason: 'roleDoctor (es) should not be empty',
      );
      expect(es.roleNurse, isA<String>(), reason: 'roleNurse (es)');
      expect(
        es.roleNurse.isNotEmpty,
        isTrue,
        reason: 'roleNurse (es) should not be empty',
      );
      expect(es.roleOrgAdmin, isA<String>(), reason: 'roleOrgAdmin (es)');
      expect(
        es.roleOrgAdmin.isNotEmpty,
        isTrue,
        reason: 'roleOrgAdmin (es) should not be empty',
      );
      expect(es.roleSuperadmin, isA<String>(), reason: 'roleSuperadmin (es)');
      expect(
        es.roleSuperadmin.isNotEmpty,
        isTrue,
        reason: 'roleSuperadmin (es) should not be empty',
      );
      expect(es.offline, isA<String>(), reason: 'offline (es)');
      expect(
        es.offline.isNotEmpty,
        isTrue,
        reason: 'offline (es) should not be empty',
      );
      expect(es.actionReadNfc, isA<String>(), reason: 'actionReadNfc (es)');
      expect(
        es.actionReadNfc.isNotEmpty,
        isTrue,
        reason: 'actionReadNfc (es) should not be empty',
      );
      expect(
        es.actionReadNfcSub,
        isA<String>(),
        reason: 'actionReadNfcSub (es)',
      );
      expect(
        es.actionReadNfcSub.isNotEmpty,
        isTrue,
        reason: 'actionReadNfcSub (es) should not be empty',
      );
      expect(
        es.actionNewPatient,
        isA<String>(),
        reason: 'actionNewPatient (es)',
      );
      expect(
        es.actionNewPatient.isNotEmpty,
        isTrue,
        reason: 'actionNewPatient (es) should not be empty',
      );
      expect(
        es.actionNewPatientSub,
        isA<String>(),
        reason: 'actionNewPatientSub (es)',
      );
      expect(
        es.actionNewPatientSub.isNotEmpty,
        isTrue,
        reason: 'actionNewPatientSub (es) should not be empty',
      );
      expect(
        es.actionSearchPatient,
        isA<String>(),
        reason: 'actionSearchPatient (es)',
      );
      expect(
        es.actionSearchPatient.isNotEmpty,
        isTrue,
        reason: 'actionSearchPatient (es) should not be empty',
      );
      expect(
        es.actionSearchPatientSub,
        isA<String>(),
        reason: 'actionSearchPatientSub (es)',
      );
      expect(
        es.actionSearchPatientSub.isNotEmpty,
        isTrue,
        reason: 'actionSearchPatientSub (es) should not be empty',
      );
      expect(
        es.actionSearchPatientSubAdmin,
        isA<String>(),
        reason: 'actionSearchPatientSubAdmin (es)',
      );
      expect(
        es.actionSearchPatientSubAdmin.isNotEmpty,
        isTrue,
        reason: 'actionSearchPatientSubAdmin (es) should not be empty',
      );
      expect(
        es.actionPendingSync,
        isA<String>(),
        reason: 'actionPendingSync (es)',
      );
      expect(
        es.actionPendingSync.isNotEmpty,
        isTrue,
        reason: 'actionPendingSync (es) should not be empty',
      );
      expect(
        es.actionPendingSyncEmpty,
        isA<String>(),
        reason: 'actionPendingSyncEmpty (es)',
      );
      expect(
        es.actionPendingSyncEmpty.isNotEmpty,
        isTrue,
        reason: 'actionPendingSyncEmpty (es) should not be empty',
      );
      expect(es.kpiUsers, isA<String>(), reason: 'kpiUsers (es)');
      expect(
        es.kpiUsers.isNotEmpty,
        isTrue,
        reason: 'kpiUsers (es) should not be empty',
      );
      expect(es.kpiSyncedOk, isA<String>(), reason: 'kpiSyncedOk (es)');
      expect(
        es.kpiSyncedOk.isNotEmpty,
        isTrue,
        reason: 'kpiSyncedOk (es) should not be empty',
      );
      expect(
        es.adminManageUsers,
        isA<String>(),
        reason: 'adminManageUsers (es)',
      );
      expect(
        es.adminManageUsers.isNotEmpty,
        isTrue,
        reason: 'adminManageUsers (es) should not be empty',
      );
      expect(
        es.adminManageUsersSub,
        isA<String>(),
        reason: 'adminManageUsersSub (es)',
      );
      expect(
        es.adminManageUsersSub.isNotEmpty,
        isTrue,
        reason: 'adminManageUsersSub (es) should not be empty',
      );
      expect(
        es.adminViewPatients,
        isA<String>(),
        reason: 'adminViewPatients (es)',
      );
      expect(
        es.adminViewPatients.isNotEmpty,
        isTrue,
        reason: 'adminViewPatients (es) should not be empty',
      );
      expect(
        es.adminViewPatientsSub,
        isA<String>(),
        reason: 'adminViewPatientsSub (es)',
      );
      expect(
        es.adminViewPatientsSub.isNotEmpty,
        isTrue,
        reason: 'adminViewPatientsSub (es) should not be empty',
      );
      expect(
        es.readWristbandTitle,
        isA<String>(),
        reason: 'readWristbandTitle (es)',
      );
      expect(
        es.readWristbandTitle.isNotEmpty,
        isTrue,
        reason: 'readWristbandTitle (es) should not be empty',
      );
      expect(
        es.scanGuardianTitle,
        isA<String>(),
        reason: 'scanGuardianTitle (es)',
      );
      expect(
        es.scanGuardianTitle.isNotEmpty,
        isTrue,
        reason: 'scanGuardianTitle (es) should not be empty',
      );
      expect(
        es.scanPatientHeadline,
        isA<String>(),
        reason: 'scanPatientHeadline (es)',
      );
      expect(
        es.scanPatientHeadline.isNotEmpty,
        isTrue,
        reason: 'scanPatientHeadline (es) should not be empty',
      );
      expect(es.scanPatientHint, isA<String>(), reason: 'scanPatientHint (es)');
      expect(
        es.scanPatientHint.isNotEmpty,
        isTrue,
        reason: 'scanPatientHint (es) should not be empty',
      );
      expect(
        es.scanGuardianHeadline,
        isA<String>(),
        reason: 'scanGuardianHeadline (es)',
      );
      expect(
        es.scanGuardianHeadline.isNotEmpty,
        isTrue,
        reason: 'scanGuardianHeadline (es) should not be empty',
      );
      expect(
        es.patientWristbandReady,
        isA<String>(),
        reason: 'patientWristbandReady (es)',
      );
      expect(
        es.patientWristbandReady.isNotEmpty,
        isTrue,
        reason: 'patientWristbandReady (es) should not be empty',
      );
      expect(
        es.nfcNotAvailableHint,
        isA<String>(),
        reason: 'nfcNotAvailableHint (es)',
      );
      expect(
        es.nfcNotAvailableHint.isNotEmpty,
        isTrue,
        reason: 'nfcNotAvailableHint (es) should not be empty',
      );
      expect(
        es.manualPatientUidLabel,
        isA<String>(),
        reason: 'manualPatientUidLabel (es)',
      );
      expect(
        es.manualPatientUidLabel.isNotEmpty,
        isTrue,
        reason: 'manualPatientUidLabel (es) should not be empty',
      );
      expect(
        es.manualPatientUidHint,
        isA<String>(),
        reason: 'manualPatientUidHint (es)',
      );
      expect(
        es.manualPatientUidHint.isNotEmpty,
        isTrue,
        reason: 'manualPatientUidHint (es) should not be empty',
      );
      expect(
        es.manualGuardianUidLabel,
        isA<String>(),
        reason: 'manualGuardianUidLabel (es)',
      );
      expect(
        es.manualGuardianUidLabel.isNotEmpty,
        isTrue,
        reason: 'manualGuardianUidLabel (es) should not be empty',
      );
      expect(
        es.manualGuardianUidHint,
        isA<String>(),
        reason: 'manualGuardianUidHint (es)',
      );
      expect(
        es.manualGuardianUidHint.isNotEmpty,
        isTrue,
        reason: 'manualGuardianUidHint (es) should not be empty',
      );
      expect(es.useManualUid, isA<String>(), reason: 'useManualUid (es)');
      expect(
        es.useManualUid.isNotEmpty,
        isTrue,
        reason: 'useManualUid (es) should not be empty',
      );
      expect(
        es.searchPatientTitle,
        isA<String>(),
        reason: 'searchPatientTitle (es)',
      );
      expect(
        es.searchPatientTitle.isNotEmpty,
        isTrue,
        reason: 'searchPatientTitle (es) should not be empty',
      );
      expect(es.searchSubtitle, isA<String>(), reason: 'searchSubtitle (es)');
      expect(
        es.searchSubtitle.isNotEmpty,
        isTrue,
        reason: 'searchSubtitle (es) should not be empty',
      );
      expect(
        es.searchPrivacyNotice,
        isA<String>(),
        reason: 'searchPrivacyNotice (es)',
      );
      expect(
        es.searchPrivacyNotice.isNotEmpty,
        isTrue,
        reason: 'searchPrivacyNotice (es) should not be empty',
      );
      expect(
        es.documentTypeLabel,
        isA<String>(),
        reason: 'documentTypeLabel (es)',
      );
      expect(
        es.documentTypeLabel.isNotEmpty,
        isTrue,
        reason: 'documentTypeLabel (es) should not be empty',
      );
      expect(
        es.documentNumberLabel,
        isA<String>(),
        reason: 'documentNumberLabel (es)',
      );
      expect(
        es.documentNumberLabel.isNotEmpty,
        isTrue,
        reason: 'documentNumberLabel (es) should not be empty',
      );
      expect(es.firstNameLabel, isA<String>(), reason: 'firstNameLabel (es)');
      expect(
        es.firstNameLabel.isNotEmpty,
        isTrue,
        reason: 'firstNameLabel (es) should not be empty',
      );
      expect(es.lastNameLabel, isA<String>(), reason: 'lastNameLabel (es)');
      expect(
        es.lastNameLabel.isNotEmpty,
        isTrue,
        reason: 'lastNameLabel (es) should not be empty',
      );
      expect(
        es.firstOrSecondLastName,
        isA<String>(),
        reason: 'firstOrSecondLastName (es)',
      );
      expect(
        es.firstOrSecondLastName.isNotEmpty,
        isTrue,
        reason: 'firstOrSecondLastName (es) should not be empty',
      );
      expect(es.dobLabel, isA<String>(), reason: 'dobLabel (es)');
      expect(
        es.dobLabel.isNotEmpty,
        isTrue,
        reason: 'dobLabel (es) should not be empty',
      );
      expect(
        es.guardianNameOptionalLabel,
        isA<String>(),
        reason: 'guardianNameOptionalLabel (es)',
      );
      expect(
        es.guardianNameOptionalLabel.isNotEmpty,
        isTrue,
        reason: 'guardianNameOptionalLabel (es) should not be empty',
      );
      expect(es.guardianHelper, isA<String>(), reason: 'guardianHelper (es)');
      expect(
        es.guardianHelper.isNotEmpty,
        isTrue,
        reason: 'guardianHelper (es) should not be empty',
      );
      expect(es.minThreeChars, isA<String>(), reason: 'minThreeChars (es)');
      expect(
        es.minThreeChars.isNotEmpty,
        isTrue,
        reason: 'minThreeChars (es) should not be empty',
      );
      expect(
        es.searchPatientButton,
        isA<String>(),
        reason: 'searchPatientButton (es)',
      );
      expect(
        es.searchPatientButton.isNotEmpty,
        isTrue,
        reason: 'searchPatientButton (es) should not be empty',
      );
      expect(
        es.searchFooterNote,
        isA<String>(),
        reason: 'searchFooterNote (es)',
      );
      expect(
        es.searchFooterNote.isNotEmpty,
        isTrue,
        reason: 'searchFooterNote (es) should not be empty',
      );
      expect(es.searchNoMatch, isA<String>(), reason: 'searchNoMatch (es)');
      expect(
        es.searchNoMatch.isNotEmpty,
        isTrue,
        reason: 'searchNoMatch (es) should not be empty',
      );

      // ── Patient profile screen ──
      expect(es.unsyncedChanges, isA<String>(), reason: 'unsyncedChanges (es)');
      expect(
        es.unsyncedChanges.isNotEmpty,
        isTrue,
        reason: 'unsyncedChanges (es) should not be empty',
      );
      expect(es.synced, isA<String>(), reason: 'synced (es)');
      expect(
        es.synced.isNotEmpty,
        isTrue,
        reason: 'synced (es) should not be empty',
      );
      expect(es.syncedAt, isA<String>(), reason: 'syncedAt (es)');
      expect(
        es.syncedAt.isNotEmpty,
        isTrue,
        reason: 'syncedAt (es) should not be empty',
      );
      expect(es.syncingBtn, isA<String>(), reason: 'syncingBtn (es)');
      expect(
        es.syncingBtn.isNotEmpty,
        isTrue,
        reason: 'syncingBtn (es) should not be empty',
      );
      expect(es.syncBtn, isA<String>(), reason: 'syncBtn (es)');
      expect(
        es.syncBtn.isNotEmpty,
        isTrue,
        reason: 'syncBtn (es) should not be empty',
      );
      expect(es.savedChangesMsg, isA<String>(), reason: 'savedChangesMsg (es)');
      expect(
        es.savedChangesMsg.isNotEmpty,
        isTrue,
        reason: 'savedChangesMsg (es) should not be empty',
      );
      expect(
        es.notAuthorizedConsultations,
        isA<String>(),
        reason: 'notAuthorizedConsultations (es)',
      );
      expect(
        es.notAuthorizedConsultations.isNotEmpty,
        isTrue,
        reason: 'notAuthorizedConsultations (es) should not be empty',
      );
      expect(
        es.unsyncedChangesTitle,
        isA<String>(),
        reason: 'unsyncedChangesTitle (es)',
      );
      expect(
        es.unsyncedChangesTitle.isNotEmpty,
        isTrue,
        reason: 'unsyncedChangesTitle (es) should not be empty',
      );
      expect(
        es.exitWithoutSyncMsg,
        isA<String>(),
        reason: 'exitWithoutSyncMsg (es)',
      );
      expect(
        es.exitWithoutSyncMsg.isNotEmpty,
        isTrue,
        reason: 'exitWithoutSyncMsg (es) should not be empty',
      );
      expect(es.exit, isA<String>(), reason: 'exit (es)');
      expect(
        es.exit.isNotEmpty,
        isTrue,
        reason: 'exit (es) should not be empty',
      );
      expect(es.tabSummary, isA<String>(), reason: 'tabSummary (es)');
      expect(
        es.tabSummary.isNotEmpty,
        isTrue,
        reason: 'tabSummary (es) should not be empty',
      );
      expect(es.yearsOldSuffix, isA<String>(), reason: 'yearsOldSuffix (es)');
      expect(
        es.yearsOldSuffix.isNotEmpty,
        isTrue,
        reason: 'yearsOldSuffix (es) should not be empty',
      );
      expect(
        es.noAllergiesRegistered,
        isA<String>(),
        reason: 'noAllergiesRegistered (es)',
      );
      expect(
        es.noAllergiesRegistered.isNotEmpty,
        isTrue,
        reason: 'noAllergiesRegistered (es) should not be empty',
      );
      expect(es.addAllergyBtn, isA<String>(), reason: 'addAllergyBtn (es)');
      expect(
        es.addAllergyBtn.isNotEmpty,
        isTrue,
        reason: 'addAllergyBtn (es) should not be empty',
      );
      expect(
        es.allergyCategoryLabel,
        isA<String>(),
        reason: 'allergyCategoryLabel (es)',
      );
      expect(
        es.allergyCategoryLabel.isNotEmpty,
        isTrue,
        reason: 'allergyCategoryLabel (es) should not be empty',
      );
      expect(es.allergenLabel, isA<String>(), reason: 'allergenLabel (es)');
      expect(
        es.allergenLabel.isNotEmpty,
        isTrue,
        reason: 'allergenLabel (es) should not be empty',
      );
      expect(es.allergenHint, isA<String>(), reason: 'allergenHint (es)');
      expect(
        es.allergenHint.isNotEmpty,
        isTrue,
        reason: 'allergenHint (es) should not be empty',
      );
      expect(
        es.reactionOptionalLabel,
        isA<String>(),
        reason: 'reactionOptionalLabel (es)',
      );
      expect(
        es.reactionOptionalLabel.isNotEmpty,
        isTrue,
        reason: 'reactionOptionalLabel (es) should not be empty',
      );
      expect(es.reactionHint, isA<String>(), reason: 'reactionHint (es)');
      expect(
        es.reactionHint.isNotEmpty,
        isTrue,
        reason: 'reactionHint (es) should not be empty',
      );
      expect(
        es.allergiesSheetTitle,
        isA<String>(),
        reason: 'allergiesSheetTitle (es)',
      );
      expect(
        es.allergiesSheetTitle.isNotEmpty,
        isTrue,
        reason: 'allergiesSheetTitle (es) should not be empty',
      );
      expect(
        es.backgroundSheetTitle,
        isA<String>(),
        reason: 'backgroundSheetTitle (es)',
      );
      expect(
        es.backgroundSheetTitle.isNotEmpty,
        isTrue,
        reason: 'backgroundSheetTitle (es) should not be empty',
      );
      expect(
        es.noChronicConditions,
        isA<String>(),
        reason: 'noChronicConditions (es)',
      );
      expect(
        es.noChronicConditions.isNotEmpty,
        isTrue,
        reason: 'noChronicConditions (es) should not be empty',
      );
      expect(
        es.addChronicConditionTitle,
        isA<String>(),
        reason: 'addChronicConditionTitle (es)',
      );
      expect(
        es.addChronicConditionTitle.isNotEmpty,
        isTrue,
        reason: 'addChronicConditionTitle (es) should not be empty',
      );
      expect(
        es.chronicConditionHint,
        isA<String>(),
        reason: 'chronicConditionHint (es)',
      );
      expect(
        es.chronicConditionHint.isNotEmpty,
        isTrue,
        reason: 'chronicConditionHint (es) should not be empty',
      );
      expect(es.noMedications, isA<String>(), reason: 'noMedications (es)');
      expect(
        es.noMedications.isNotEmpty,
        isTrue,
        reason: 'noMedications (es) should not be empty',
      );
      expect(es.medications, isA<String>(), reason: 'medications (es)');
      expect(
        es.medications.isNotEmpty,
        isTrue,
        reason: 'medications (es) should not be empty',
      );
      expect(
        es.personalHistoryTitle,
        isA<String>(),
        reason: 'personalHistoryTitle (es)',
      );
      expect(
        es.personalHistoryTitle.isNotEmpty,
        isTrue,
        reason: 'personalHistoryTitle (es) should not be empty',
      );
      expect(
        es.noFamilyHistoryEntries,
        isA<String>(),
        reason: 'noFamilyHistoryEntries (es)',
      );
      expect(
        es.noFamilyHistoryEntries.isNotEmpty,
        isTrue,
        reason: 'noFamilyHistoryEntries (es) should not be empty',
      );
      expect(es.reactionLabel, isA<String>(), reason: 'reactionLabel (es)');
      expect(
        es.reactionLabel.isNotEmpty,
        isTrue,
        reason: 'reactionLabel (es) should not be empty',
      );
      expect(es.sexMale, isA<String>(), reason: 'sexMale (es)');
      expect(
        es.sexMale.isNotEmpty,
        isTrue,
        reason: 'sexMale (es) should not be empty',
      );
      expect(es.sexFemale, isA<String>(), reason: 'sexFemale (es)');
      expect(
        es.sexFemale.isNotEmpty,
        isTrue,
        reason: 'sexFemale (es) should not be empty',
      );
      expect(
        es.sexIndeterminate,
        isA<String>(),
        reason: 'sexIndeterminate (es)',
      );
      expect(
        es.sexIndeterminate.isNotEmpty,
        isTrue,
        reason: 'sexIndeterminate (es) should not be empty',
      );
      expect(es.docTypeRC, isA<String>(), reason: 'docTypeRC (es)');
      expect(
        es.docTypeRC.isNotEmpty,
        isTrue,
        reason: 'docTypeRC (es) should not be empty',
      );
      expect(es.docTypeTI, isA<String>(), reason: 'docTypeTI (es)');
      expect(
        es.docTypeTI.isNotEmpty,
        isTrue,
        reason: 'docTypeTI (es) should not be empty',
      );
      expect(es.docTypeCC, isA<String>(), reason: 'docTypeCC (es)');
      expect(
        es.docTypeCC.isNotEmpty,
        isTrue,
        reason: 'docTypeCC (es) should not be empty',
      );
      expect(es.docTypeCE, isA<String>(), reason: 'docTypeCE (es)');
      expect(
        es.docTypeCE.isNotEmpty,
        isTrue,
        reason: 'docTypeCE (es) should not be empty',
      );
      expect(es.docTypePA, isA<String>(), reason: 'docTypePA (es)');
      expect(
        es.docTypePA.isNotEmpty,
        isTrue,
        reason: 'docTypePA (es) should not be empty',
      );
      expect(es.docTypePE, isA<String>(), reason: 'docTypePE (es)');
      expect(
        es.docTypePE.isNotEmpty,
        isTrue,
        reason: 'docTypePE (es) should not be empty',
      );
      expect(es.docTypePT, isA<String>(), reason: 'docTypePT (es)');
      expect(
        es.docTypePT.isNotEmpty,
        isTrue,
        reason: 'docTypePT (es) should not be empty',
      );
      expect(es.docTypeMS, isA<String>(), reason: 'docTypeMS (es)');
      expect(
        es.docTypeMS.isNotEmpty,
        isTrue,
        reason: 'docTypeMS (es) should not be empty',
      );
      expect(es.docTypeAS, isA<String>(), reason: 'docTypeAS (es)');
      expect(
        es.docTypeAS.isNotEmpty,
        isTrue,
        reason: 'docTypeAS (es) should not be empty',
      );
      expect(es.medStatusActive, isA<String>(), reason: 'medStatusActive (es)');
      expect(
        es.medStatusActive.isNotEmpty,
        isTrue,
        reason: 'medStatusActive (es) should not be empty',
      );
      expect(
        es.medStatusCompleted,
        isA<String>(),
        reason: 'medStatusCompleted (es)',
      );
      expect(
        es.medStatusCompleted.isNotEmpty,
        isTrue,
        reason: 'medStatusCompleted (es) should not be empty',
      );
      expect(
        es.medStatusStopped,
        isA<String>(),
        reason: 'medStatusStopped (es)',
      );
      expect(
        es.medStatusStopped.isNotEmpty,
        isTrue,
        reason: 'medStatusStopped (es) should not be empty',
      );
      expect(
        es.medStatusUnknown,
        isA<String>(),
        reason: 'medStatusUnknown (es)',
      );
      expect(
        es.medStatusUnknown.isNotEmpty,
        isTrue,
        reason: 'medStatusUnknown (es) should not be empty',
      );
      expect(es.cie10Label, isA<String>(), reason: 'cie10Label (es)');
      expect(
        es.cie10Label.isNotEmpty,
        isTrue,
        reason: 'cie10Label (es) should not be empty',
      );

      // ── Add medication sheet ──
      expect(
        es.addMedicationTitle,
        isA<String>(),
        reason: 'addMedicationTitle (es)',
      );
      expect(
        es.addMedicationTitle.isNotEmpty,
        isTrue,
        reason: 'addMedicationTitle (es) should not be empty',
      );
      expect(
        es.addMedicationSubtitle,
        isA<String>(),
        reason: 'addMedicationSubtitle (es)',
      );
      expect(
        es.addMedicationSubtitle.isNotEmpty,
        isTrue,
        reason: 'addMedicationSubtitle (es) should not be empty',
      );
      expect(es.medicationLabel, isA<String>(), reason: 'medicationLabel (es)');
      expect(
        es.medicationLabel.isNotEmpty,
        isTrue,
        reason: 'medicationLabel (es) should not be empty',
      );
      expect(es.medicationHint, isA<String>(), reason: 'medicationHint (es)');
      expect(
        es.medicationHint.isNotEmpty,
        isTrue,
        reason: 'medicationHint (es) should not be empty',
      );
      expect(es.statusLabel, isA<String>(), reason: 'statusLabel (es)');
      expect(
        es.statusLabel.isNotEmpty,
        isTrue,
        reason: 'statusLabel (es) should not be empty',
      );
      expect(es.dosageLabel, isA<String>(), reason: 'dosageLabel (es)');
      expect(
        es.dosageLabel.isNotEmpty,
        isTrue,
        reason: 'dosageLabel (es) should not be empty',
      );
      expect(es.dosageHint, isA<String>(), reason: 'dosageHint (es)');
      expect(
        es.dosageHint.isNotEmpty,
        isTrue,
        reason: 'dosageHint (es) should not be empty',
      );
      expect(es.notesLabel, isA<String>(), reason: 'notesLabel (es)');
      expect(
        es.notesLabel.isNotEmpty,
        isTrue,
        reason: 'notesLabel (es) should not be empty',
      );
      expect(es.notesHint, isA<String>(), reason: 'notesHint (es)');
      expect(
        es.notesHint.isNotEmpty,
        isTrue,
        reason: 'notesHint (es) should not be empty',
      );

      // ── Edit chronic / personal sheet ──
      expect(
        es.editChronicPersonalHint,
        isA<String>(),
        reason: 'editChronicPersonalHint (es)',
      );
      expect(
        es.editChronicPersonalHint.isNotEmpty,
        isTrue,
        reason: 'editChronicPersonalHint (es) should not be empty',
      );

      // ── Allergies tab ──
      expect(es.reactionHeader, isA<String>(), reason: 'reactionHeader (es)');
      expect(
        es.reactionHeader.isNotEmpty,
        isTrue,
        reason: 'reactionHeader (es) should not be empty',
      );
      expect(
        es.allergyShortMedication,
        isA<String>(),
        reason: 'allergyShortMedication (es)',
      );
      expect(
        es.allergyShortMedication.isNotEmpty,
        isTrue,
        reason: 'allergyShortMedication (es) should not be empty',
      );
      expect(
        es.allergyShortFood,
        isA<String>(),
        reason: 'allergyShortFood (es)',
      );
      expect(
        es.allergyShortFood.isNotEmpty,
        isTrue,
        reason: 'allergyShortFood (es) should not be empty',
      );
      expect(
        es.allergyShortEnvironment,
        isA<String>(),
        reason: 'allergyShortEnvironment (es)',
      );
      expect(
        es.allergyShortEnvironment.isNotEmpty,
        isTrue,
        reason: 'allergyShortEnvironment (es) should not be empty',
      );
      expect(
        es.allergyShortSkin,
        isA<String>(),
        reason: 'allergyShortSkin (es)',
      );
      expect(
        es.allergyShortSkin.isNotEmpty,
        isTrue,
        reason: 'allergyShortSkin (es) should not be empty',
      );
      expect(
        es.allergyShortInsect,
        isA<String>(),
        reason: 'allergyShortInsect (es)',
      );
      expect(
        es.allergyShortInsect.isNotEmpty,
        isTrue,
        reason: 'allergyShortInsect (es) should not be empty',
      );
      expect(
        es.allergyShortOther,
        isA<String>(),
        reason: 'allergyShortOther (es)',
      );
      expect(
        es.allergyShortOther.isNotEmpty,
        isTrue,
        reason: 'allergyShortOther (es) should not be empty',
      );

      // ── Summary tab ──
      expect(es.personalTitle, isA<String>(), reason: 'personalTitle (es)');
      expect(
        es.personalTitle.isNotEmpty,
        isTrue,
        reason: 'personalTitle (es) should not be empty',
      );
      expect(es.chronic, isA<String>(), reason: 'chronic (es)');
      expect(
        es.chronic.isNotEmpty,
        isTrue,
        reason: 'chronic (es) should not be empty',
      );
      expect(es.family, isA<String>(), reason: 'family (es)');
      expect(
        es.family.isNotEmpty,
        isTrue,
        reason: 'family (es) should not be empty',
      );
      expect(es.recordsLabel, isA<String>(), reason: 'recordsLabel (es)');
      expect(
        es.recordsLabel.isNotEmpty,
        isTrue,
        reason: 'recordsLabel (es) should not be empty',
      );

      // ── Consultations View & Detail ──
      expect(
        es.consultationsTabTitle,
        isA<String>(),
        reason: 'consultationsTabTitle (es)',
      );
      expect(
        es.consultationsTabTitle.isNotEmpty,
        isTrue,
        reason: 'consultationsTabTitle (es) should not be empty',
      );
      expect(
        es.noConsultationsRegistered,
        isA<String>(),
        reason: 'noConsultationsRegistered (es)',
      );
      expect(
        es.noConsultationsRegistered.isNotEmpty,
        isTrue,
        reason: 'noConsultationsRegistered (es) should not be empty',
      );
      expect(
        es.addConsultationButton,
        isA<String>(),
        reason: 'addConsultationButton (es)',
      );
      expect(
        es.addConsultationButton.isNotEmpty,
        isTrue,
        reason: 'addConsultationButton (es) should not be empty',
      );
      expect(es.viewDetailHint, isA<String>(), reason: 'viewDetailHint (es)');
      expect(
        es.viewDetailHint.isNotEmpty,
        isTrue,
        reason: 'viewDetailHint (es) should not be empty',
      );
      expect(
        es.consultationDetailTitle,
        isA<String>(),
        reason: 'consultationDetailTitle (es)',
      );
      expect(
        es.consultationDetailTitle.isNotEmpty,
        isTrue,
        reason: 'consultationDetailTitle (es) should not be empty',
      );
      expect(
        es.careContextSection,
        isA<String>(),
        reason: 'careContextSection (es)',
      );
      expect(
        es.careContextSection.isNotEmpty,
        isTrue,
        reason: 'careContextSection (es) should not be empty',
      );
      expect(es.startDateLabel, isA<String>(), reason: 'startDateLabel (es)');
      expect(
        es.startDateLabel.isNotEmpty,
        isTrue,
        reason: 'startDateLabel (es) should not be empty',
      );
      expect(es.endDateLabel, isA<String>(), reason: 'endDateLabel (es)');
      expect(
        es.endDateLabel.isNotEmpty,
        isTrue,
        reason: 'endDateLabel (es) should not be empty',
      );
      expect(
        es.serviceGroupLabel,
        isA<String>(),
        reason: 'serviceGroupLabel (es)',
      );
      expect(
        es.serviceGroupLabel.isNotEmpty,
        isTrue,
        reason: 'serviceGroupLabel (es) should not be empty',
      );
      expect(
        es.environmentLabel,
        isA<String>(),
        reason: 'environmentLabel (es)',
      );
      expect(
        es.environmentLabel.isNotEmpty,
        isTrue,
        reason: 'environmentLabel (es) should not be empty',
      );
      expect(es.entryRouteLabel, isA<String>(), reason: 'entryRouteLabel (es)');
      expect(
        es.entryRouteLabel.isNotEmpty,
        isTrue,
        reason: 'entryRouteLabel (es) should not be empty',
      );
      expect(
        es.externalCauseLabel,
        isA<String>(),
        reason: 'externalCauseLabel (es)',
      );
      expect(
        es.externalCauseLabel.isNotEmpty,
        isTrue,
        reason: 'externalCauseLabel (es) should not be empty',
      );
      expect(es.docLabelShort, isA<String>(), reason: 'docLabelShort (es)');
      expect(
        es.docLabelShort.isNotEmpty,
        isTrue,
        reason: 'docLabelShort (es) should not be empty',
      );
      expect(es.diagnosisTitle, isA<String>(), reason: 'diagnosisTitle (es)');
      expect(
        es.diagnosisTitle.isNotEmpty,
        isTrue,
        reason: 'diagnosisTitle (es) should not be empty',
      );
      expect(
        es.dischargeSection,
        isA<String>(),
        reason: 'dischargeSection (es)',
      );
      expect(
        es.dischargeSection.isNotEmpty,
        isTrue,
        reason: 'dischargeSection (es) should not be empty',
      );
      expect(
        es.riskFactorsSection,
        isA<String>(),
        reason: 'riskFactorsSection (es)',
      );
      expect(
        es.riskFactorsSection.isNotEmpty,
        isTrue,
        reason: 'riskFactorsSection (es) should not be empty',
      );
      expect(
        es.incapacitySection,
        isA<String>(),
        reason: 'incapacitySection (es)',
      );
      expect(
        es.incapacitySection.isNotEmpty,
        isTrue,
        reason: 'incapacitySection (es) should not be empty',
      );
      expect(es.incapacityScope, isA<String>(), reason: 'incapacityScope (es)');
      expect(
        es.incapacityScope.isNotEmpty,
        isTrue,
        reason: 'incapacityScope (es) should not be empty',
      );
      expect(es.incapacityDays, isA<String>(), reason: 'incapacityDays (es)');
      expect(
        es.incapacityDays.isNotEmpty,
        isTrue,
        reason: 'incapacityDays (es) should not be empty',
      );
      expect(es.payerSection, isA<String>(), reason: 'payerSection (es)');
      expect(
        es.payerSection.isNotEmpty,
        isTrue,
        reason: 'payerSection (es) should not be empty',
      );
      expect(es.codeLabel, isA<String>(), reason: 'codeLabel (es)');
      expect(
        es.codeLabel.isNotEmpty,
        isTrue,
        reason: 'codeLabel (es) should not be empty',
      );
      expect(es.dayLun, isA<String>(), reason: 'dayLun (es)');
      expect(
        es.dayLun.isNotEmpty,
        isTrue,
        reason: 'dayLun (es) should not be empty',
      );
      expect(es.dayMar, isA<String>(), reason: 'dayMar (es)');
      expect(
        es.dayMar.isNotEmpty,
        isTrue,
        reason: 'dayMar (es) should not be empty',
      );
      expect(es.dayMie, isA<String>(), reason: 'dayMie (es)');
      expect(
        es.dayMie.isNotEmpty,
        isTrue,
        reason: 'dayMie (es) should not be empty',
      );
      expect(es.dayJue, isA<String>(), reason: 'dayJue (es)');
      expect(
        es.dayJue.isNotEmpty,
        isTrue,
        reason: 'dayJue (es) should not be empty',
      );
      expect(es.dayVie, isA<String>(), reason: 'dayVie (es)');
      expect(
        es.dayVie.isNotEmpty,
        isTrue,
        reason: 'dayVie (es) should not be empty',
      );
      expect(es.daySab, isA<String>(), reason: 'daySab (es)');
      expect(
        es.daySab.isNotEmpty,
        isTrue,
        reason: 'daySab (es) should not be empty',
      );
      expect(es.dayDom, isA<String>(), reason: 'dayDom (es)');
      expect(
        es.dayDom.isNotEmpty,
        isTrue,
        reason: 'dayDom (es) should not be empty',
      );
      expect(es.monEne, isA<String>(), reason: 'monEne (es)');
      expect(
        es.monEne.isNotEmpty,
        isTrue,
        reason: 'monEne (es) should not be empty',
      );
      expect(es.monFeb, isA<String>(), reason: 'monFeb (es)');
      expect(
        es.monFeb.isNotEmpty,
        isTrue,
        reason: 'monFeb (es) should not be empty',
      );
      expect(es.monMarString, isA<String>(), reason: 'monMarString (es)');
      expect(
        es.monMarString.isNotEmpty,
        isTrue,
        reason: 'monMarString (es) should not be empty',
      );
      expect(es.monMar, isA<String>(), reason: 'monMar (es)');
      expect(
        es.monMar.isNotEmpty,
        isTrue,
        reason: 'monMar (es) should not be empty',
      );
      expect(es.monAbr, isA<String>(), reason: 'monAbr (es)');
      expect(
        es.monAbr.isNotEmpty,
        isTrue,
        reason: 'monAbr (es) should not be empty',
      );
      expect(es.monMay, isA<String>(), reason: 'monMay (es)');
      expect(
        es.monMay.isNotEmpty,
        isTrue,
        reason: 'monMay (es) should not be empty',
      );
      expect(es.monJun, isA<String>(), reason: 'monJun (es)');
      expect(
        es.monJun.isNotEmpty,
        isTrue,
        reason: 'monJun (es) should not be empty',
      );
      expect(es.monJul, isA<String>(), reason: 'monJul (es)');
      expect(
        es.monJul.isNotEmpty,
        isTrue,
        reason: 'monJul (es) should not be empty',
      );
      expect(es.monAgo, isA<String>(), reason: 'monAgo (es)');
      expect(
        es.monAgo.isNotEmpty,
        isTrue,
        reason: 'monAgo (es) should not be empty',
      );
      expect(es.monSep, isA<String>(), reason: 'monSep (es)');
      expect(
        es.monSep.isNotEmpty,
        isTrue,
        reason: 'monSep (es) should not be empty',
      );
      expect(es.monOct, isA<String>(), reason: 'monOct (es)');
      expect(
        es.monOct.isNotEmpty,
        isTrue,
        reason: 'monOct (es) should not be empty',
      );
      expect(es.monNov, isA<String>(), reason: 'monNov (es)');
      expect(
        es.monNov.isNotEmpty,
        isTrue,
        reason: 'monNov (es) should not be empty',
      );
      expect(es.monDic, isA<String>(), reason: 'monDic (es)');
      expect(
        es.monDic.isNotEmpty,
        isTrue,
        reason: 'monDic (es) should not be empty',
      );
      expect(es.timeAm, isA<String>(), reason: 'timeAm (es)');
      expect(
        es.timeAm.isNotEmpty,
        isTrue,
        reason: 'timeAm (es) should not be empty',
      );
      expect(es.timePm, isA<String>(), reason: 'timePm (es)');
      expect(
        es.timePm.isNotEmpty,
        isTrue,
        reason: 'timePm (es) should not be empty',
      );
      expect(es.modIntramural, isA<String>(), reason: 'modIntramural (es)');
      expect(
        es.modIntramural.isNotEmpty,
        isTrue,
        reason: 'modIntramural (es) should not be empty',
      );
      expect(
        es.modExtramuralMobil,
        isA<String>(),
        reason: 'modExtramuralMobil (es)',
      );
      expect(
        es.modExtramuralMobil.isNotEmpty,
        isTrue,
        reason: 'modExtramuralMobil (es) should not be empty',
      );
      expect(es.modDomiciliaria, isA<String>(), reason: 'modDomiciliaria (es)');
      expect(
        es.modDomiciliaria.isNotEmpty,
        isTrue,
        reason: 'modDomiciliaria (es) should not be empty',
      );
      expect(es.modJornada, isA<String>(), reason: 'modJornada (es)');
      expect(
        es.modJornada.isNotEmpty,
        isTrue,
        reason: 'modJornada (es) should not be empty',
      );
      expect(
        es.modPrehospitalaria,
        isA<String>(),
        reason: 'modPrehospitalaria (es)',
      );
      expect(
        es.modPrehospitalaria.isNotEmpty,
        isTrue,
        reason: 'modPrehospitalaria (es) should not be empty',
      );
      expect(
        es.modTelemedicinaInteractiva,
        isA<String>(),
        reason: 'modTelemedicinaInteractiva (es)',
      );
      expect(
        es.modTelemedicinaInteractiva.isNotEmpty,
        isTrue,
        reason: 'modTelemedicinaInteractiva (es) should not be empty',
      );
      expect(
        es.modNoInteractiva,
        isA<String>(),
        reason: 'modNoInteractiva (es)',
      );
      expect(
        es.modNoInteractiva.isNotEmpty,
        isTrue,
        reason: 'modNoInteractiva (es) should not be empty',
      );
      expect(
        es.modTelexperticia,
        isA<String>(),
        reason: 'modTelexperticia (es)',
      );
      expect(
        es.modTelexperticia.isNotEmpty,
        isTrue,
        reason: 'modTelexperticia (es) should not be empty',
      );
      expect(
        es.modTelemonitoreo,
        isA<String>(),
        reason: 'modTelemonitoreo (es)',
      );
      expect(
        es.modTelemonitoreo.isNotEmpty,
        isTrue,
        reason: 'modTelemonitoreo (es) should not be empty',
      );
      expect(
        es.sgConsultaExterna,
        isA<String>(),
        reason: 'sgConsultaExterna (es)',
      );
      expect(
        es.sgConsultaExterna.isNotEmpty,
        isTrue,
        reason: 'sgConsultaExterna (es) should not be empty',
      );
      expect(
        es.sgApoyoDiagnostico,
        isA<String>(),
        reason: 'sgApoyoDiagnostico (es)',
      );
      expect(
        es.sgApoyoDiagnostico.isNotEmpty,
        isTrue,
        reason: 'sgApoyoDiagnostico (es) should not be empty',
      );
      expect(es.sgInternacion, isA<String>(), reason: 'sgInternacion (es)');
      expect(
        es.sgInternacion.isNotEmpty,
        isTrue,
        reason: 'sgInternacion (es) should not be empty',
      );
      expect(es.sgQuirurgico, isA<String>(), reason: 'sgQuirurgico (es)');
      expect(
        es.sgQuirurgico.isNotEmpty,
        isTrue,
        reason: 'sgQuirurgico (es) should not be empty',
      );
      expect(
        es.sgAtencionInmediata,
        isA<String>(),
        reason: 'sgAtencionInmediata (es)',
      );
      expect(
        es.sgAtencionInmediata.isNotEmpty,
        isTrue,
        reason: 'sgAtencionInmediata (es) should not be empty',
      );
      expect(es.ceHogar, isA<String>(), reason: 'ceHogar (es)');
      expect(
        es.ceHogar.isNotEmpty,
        isTrue,
        reason: 'ceHogar (es) should not be empty',
      );
      expect(es.ceComunitario, isA<String>(), reason: 'ceComunitario (es)');
      expect(
        es.ceComunitario.isNotEmpty,
        isTrue,
        reason: 'ceComunitario (es) should not be empty',
      );
      expect(es.ceEscolar, isA<String>(), reason: 'ceEscolar (es)');
      expect(
        es.ceEscolar.isNotEmpty,
        isTrue,
        reason: 'ceEscolar (es) should not be empty',
      );
      expect(es.ceLaboral, isA<String>(), reason: 'ceLaboral (es)');
      expect(
        es.ceLaboral.isNotEmpty,
        isTrue,
        reason: 'ceLaboral (es) should not be empty',
      );
      expect(es.ceInstitucional, isA<String>(), reason: 'ceInstitucional (es)');
      expect(
        es.ceInstitucional.isNotEmpty,
        isTrue,
        reason: 'ceInstitucional (es) should not be empty',
      );
      expect(es.dtImpresion, isA<String>(), reason: 'dtImpresion (es)');
      expect(
        es.dtImpresion.isNotEmpty,
        isTrue,
        reason: 'dtImpresion (es) should not be empty',
      );
      expect(
        es.dtConfirmadoNuevo,
        isA<String>(),
        reason: 'dtConfirmadoNuevo (es)',
      );
      expect(
        es.dtConfirmadoNuevo.isNotEmpty,
        isTrue,
        reason: 'dtConfirmadoNuevo (es) should not be empty',
      );
      expect(
        es.dtConfirmadoRepetido,
        isA<String>(),
        reason: 'dtConfirmadoRepetido (es)',
      );
      expect(
        es.dtConfirmadoRepetido.isNotEmpty,
        isTrue,
        reason: 'dtConfirmadoRepetido (es) should not be empty',
      );
      expect(
        es.ddAltaVoluntaria,
        isA<String>(),
        reason: 'ddAltaVoluntaria (es)',
      );
      expect(
        es.ddAltaVoluntaria.isNotEmpty,
        isTrue,
        reason: 'ddAltaVoluntaria (es) should not be empty',
      );
      expect(es.ddFallecido, isA<String>(), reason: 'ddFallecido (es)');
      expect(
        es.ddFallecido.isNotEmpty,
        isTrue,
        reason: 'ddFallecido (es) should not be empty',
      );
      expect(es.ddRemitido, isA<String>(), reason: 'ddRemitido (es)');
      expect(
        es.ddRemitido.isNotEmpty,
        isTrue,
        reason: 'ddRemitido (es) should not be empty',
      );
      expect(es.ddAltaMedica, isA<String>(), reason: 'ddAltaMedica (es)');
      expect(
        es.ddAltaMedica.isNotEmpty,
        isTrue,
        reason: 'ddAltaMedica (es) should not be empty',
      );

      // ── Vaccines tab ──
      expect(
        es.vaccineSchemeTitle,
        isA<String>(),
        reason: 'vaccineSchemeTitle (es)',
      );
      expect(
        es.vaccineSchemeTitle.isNotEmpty,
        isTrue,
        reason: 'vaccineSchemeTitle (es) should not be empty',
      );
      expect(
        es.vaccineLabelSingle,
        isA<String>(),
        reason: 'vaccineLabelSingle (es)',
      );
      expect(
        es.vaccineLabelSingle.isNotEmpty,
        isTrue,
        reason: 'vaccineLabelSingle (es) should not be empty',
      );
      expect(
        es.vaccineLabelPlural,
        isA<String>(),
        reason: 'vaccineLabelPlural (es)',
      );
      expect(
        es.vaccineLabelPlural.isNotEmpty,
        isTrue,
        reason: 'vaccineLabelPlural (es) should not be empty',
      );
      expect(
        es.noVaccinesRegistered,
        isA<String>(),
        reason: 'noVaccinesRegistered (es)',
      );
      expect(
        es.noVaccinesRegistered.isNotEmpty,
        isTrue,
        reason: 'noVaccinesRegistered (es) should not be empty',
      );
      expect(
        es.addVaccineButton,
        isA<String>(),
        reason: 'addVaccineButton (es)',
      );
      expect(
        es.addVaccineButton.isNotEmpty,
        isTrue,
        reason: 'addVaccineButton (es) should not be empty',
      );
      expect(es.doseLabel, isA<String>(), reason: 'doseLabel (es)');
      expect(
        es.doseLabel.isNotEmpty,
        isTrue,
        reason: 'doseLabel (es) should not be empty',
      );

      // ── Admin Manage Users ──
      expect(
        es.manageUsersTitle,
        isA<String>(),
        reason: 'manageUsersTitle (es)',
      );
      expect(
        es.manageUsersTitle.isNotEmpty,
        isTrue,
        reason: 'manageUsersTitle (es) should not be empty',
      );
      expect(es.filterAll, isA<String>(), reason: 'filterAll (es)');
      expect(
        es.filterAll.isNotEmpty,
        isTrue,
        reason: 'filterAll (es) should not be empty',
      );
      expect(es.filterDoctors, isA<String>(), reason: 'filterDoctors (es)');
      expect(
        es.filterDoctors.isNotEmpty,
        isTrue,
        reason: 'filterDoctors (es) should not be empty',
      );
      expect(es.filterNurse, isA<String>(), reason: 'filterNurse (es)');
      expect(
        es.filterNurse.isNotEmpty,
        isTrue,
        reason: 'filterNurse (es) should not be empty',
      );
      expect(es.filterCoord, isA<String>(), reason: 'filterCoord (es)');
      expect(
        es.filterCoord.isNotEmpty,
        isTrue,
        reason: 'filterCoord (es) should not be empty',
      );
      expect(es.noUsersInFilter, isA<String>(), reason: 'noUsersInFilter (es)');
      expect(
        es.noUsersInFilter.isNotEmpty,
        isTrue,
        reason: 'noUsersInFilter (es) should not be empty',
      );
      expect(es.createUserTitle, isA<String>(), reason: 'createUserTitle (es)');
      expect(
        es.createUserTitle.isNotEmpty,
        isTrue,
        reason: 'createUserTitle (es) should not be empty',
      );
      expect(
        es.userStatusActive,
        isA<String>(),
        reason: 'userStatusActive (es)',
      );
      expect(
        es.userStatusActive.isNotEmpty,
        isTrue,
        reason: 'userStatusActive (es) should not be empty',
      );
      expect(
        es.userStatusSuspended,
        isA<String>(),
        reason: 'userStatusSuspended (es)',
      );
      expect(
        es.userStatusSuspended.isNotEmpty,
        isTrue,
        reason: 'userStatusSuspended (es) should not be empty',
      );
      expect(
        es.userDetailOrganization,
        isA<String>(),
        reason: 'userDetailOrganization (es)',
      );
      expect(
        es.userDetailOrganization.isNotEmpty,
        isTrue,
        reason: 'userDetailOrganization (es) should not be empty',
      );
      expect(
        es.userDetailStatus,
        isA<String>(),
        reason: 'userDetailStatus (es)',
      );
      expect(
        es.userDetailStatus.isNotEmpty,
        isTrue,
        reason: 'userDetailStatus (es) should not be empty',
      );
      expect(
        es.userFormFullNameLabel,
        isA<String>(),
        reason: 'userFormFullNameLabel (es)',
      );
      expect(
        es.userFormFullNameLabel.isNotEmpty,
        isTrue,
        reason: 'userFormFullNameLabel (es) should not be empty',
      );
      expect(
        es.userFormEmailLabel,
        isA<String>(),
        reason: 'userFormEmailLabel (es)',
      );
      expect(
        es.userFormEmailLabel.isNotEmpty,
        isTrue,
        reason: 'userFormEmailLabel (es) should not be empty',
      );
      expect(
        es.userFormPasswordLabel,
        isA<String>(),
        reason: 'userFormPasswordLabel (es)',
      );
      expect(
        es.userFormPasswordLabel.isNotEmpty,
        isTrue,
        reason: 'userFormPasswordLabel (es) should not be empty',
      );
      expect(
        es.userFormRoleLabel,
        isA<String>(),
        reason: 'userFormRoleLabel (es)',
      );
      expect(
        es.userFormRoleLabel.isNotEmpty,
        isTrue,
        reason: 'userFormRoleLabel (es) should not be empty',
      );
      expect(
        es.userFormRequiredFieldsError,
        isA<String>(),
        reason: 'userFormRequiredFieldsError (es)',
      );
      expect(
        es.userFormRequiredFieldsError.isNotEmpty,
        isTrue,
        reason: 'userFormRequiredFieldsError (es) should not be empty',
      );
      expect(
        es.userFormCreatingStatus,
        isA<String>(),
        reason: 'userFormCreatingStatus (es)',
      );
      expect(
        es.userFormCreatingStatus.isNotEmpty,
        isTrue,
        reason: 'userFormCreatingStatus (es) should not be empty',
      );
      expect(
        es.userFormCreateButton,
        isA<String>(),
        reason: 'userFormCreateButton (es)',
      );
      expect(
        es.userFormCreateButton.isNotEmpty,
        isTrue,
        reason: 'userFormCreateButton (es) should not be empty',
      );
      expect(es.deletUser, isA<String>(), reason: 'deletUser (es)');
      expect(
        es.deletUser.isNotEmpty,
        isTrue,
        reason: 'deletUser (es) should not be empty',
      );
      expect(es.deleting, isA<String>(), reason: 'deleting (es)');
      expect(
        es.deleting.isNotEmpty,
        isTrue,
        reason: 'deleting (es) should not be empty',
      );
      expect(
        es.permanentlyDelete,
        isA<String>(),
        reason: 'permanentlyDelete (es)',
      );
      expect(
        es.permanentlyDelete.isNotEmpty,
        isTrue,
        reason: 'permanentlyDelete (es) should not be empty',
      );
      expect(
        es.userFormValidationError,
        isA<String>(),
        reason: 'userFormValidationError (es)',
      );
      expect(
        es.userFormValidationError.isNotEmpty,
        isTrue,
        reason: 'userFormValidationError (es) should not be empty',
      );

      // ── Super Admin User ──
      expect(es.manageOrgsTitle, isA<String>(), reason: 'manageOrgsTitle (es)');
      expect(
        es.manageOrgsTitle.isNotEmpty,
        isTrue,
        reason: 'manageOrgsTitle (es) should not be empty',
      );
      expect(
        es.manageOrgsSubtitle,
        isA<String>(),
        reason: 'manageOrgsSubtitle (es)',
      );
      expect(
        es.manageOrgsSubtitle.isNotEmpty,
        isTrue,
        reason: 'manageOrgsSubtitle (es) should not be empty',
      );
      expect(
        es.brigadeStatsTitle,
        isA<String>(),
        reason: 'brigadeStatsTitle (es)',
      );
      expect(
        es.brigadeStatsTitle.isNotEmpty,
        isTrue,
        reason: 'brigadeStatsTitle (es) should not be empty',
      );
      expect(
        es.brigadeStatsSubtitle,
        isA<String>(),
        reason: 'brigadeStatsSubtitle (es)',
      );
      expect(
        es.brigadeStatsSubtitle.isNotEmpty,
        isTrue,
        reason: 'brigadeStatsSubtitle (es) should not be empty',
      );
      expect(
        es.statsScreenTitle,
        isA<String>(),
        reason: 'statsScreenTitle (es)',
      );
      expect(
        es.statsScreenTitle.isNotEmpty,
        isTrue,
        reason: 'statsScreenTitle (es) should not be empty',
      );
      expect(
        es.statsTotalPatients,
        isA<String>(),
        reason: 'statsTotalPatients (es)',
      );
      expect(
        es.statsTotalPatients.isNotEmpty,
        isTrue,
        reason: 'statsTotalPatients (es) should not be empty',
      );
      expect(
        es.statsTotalVaccines,
        isA<String>(),
        reason: 'statsTotalVaccines (es)',
      );
      expect(
        es.statsTotalVaccines.isNotEmpty,
        isTrue,
        reason: 'statsTotalVaccines (es) should not be empty',
      );
      expect(
        es.statsTotalAllergies,
        isA<String>(),
        reason: 'statsTotalAllergies (es)',
      );
      expect(
        es.statsTotalAllergies.isNotEmpty,
        isTrue,
        reason: 'statsTotalAllergies (es) should not be empty',
      );
      expect(
        es.statsMinorsPercentage,
        isA<String>(),
        reason: 'statsMinorsPercentage (es)',
      );
      expect(
        es.statsMinorsPercentage.isNotEmpty,
        isTrue,
        reason: 'statsMinorsPercentage (es) should not be empty',
      );
      expect(
        es.statsVaccineDistribution,
        isA<String>(),
        reason: 'statsVaccineDistribution (es)',
      );
      expect(
        es.statsVaccineDistribution.isNotEmpty,
        isTrue,
        reason: 'statsVaccineDistribution (es) should not be empty',
      );
      expect(
        es.statsAllergyDistribution,
        isA<String>(),
        reason: 'statsAllergyDistribution (es)',
      );
      expect(
        es.statsAllergyDistribution.isNotEmpty,
        isTrue,
        reason: 'statsAllergyDistribution (es) should not be empty',
      );
      expect(
        es.manageOrgsScreenTitle,
        isA<String>(),
        reason: 'manageOrgsScreenTitle (es)',
      );
      expect(
        es.manageOrgsScreenTitle.isNotEmpty,
        isTrue,
        reason: 'manageOrgsScreenTitle (es) should not be empty',
      );
      expect(
        es.orgsNoOrganizations,
        isA<String>(),
        reason: 'orgsNoOrganizations (es)',
      );
      expect(
        es.orgsNoOrganizations.isNotEmpty,
        isTrue,
        reason: 'orgsNoOrganizations (es) should not be empty',
      );
      expect(
        es.orgsCreateOrgTitle,
        isA<String>(),
        reason: 'orgsCreateOrgTitle (es)',
      );
      expect(
        es.orgsCreateOrgTitle.isNotEmpty,
        isTrue,
        reason: 'orgsCreateOrgTitle (es) should not be empty',
      );
      expect(
        es.orgsStepBasicData,
        isA<String>(),
        reason: 'orgsStepBasicData (es)',
      );
      expect(
        es.orgsStepBasicData.isNotEmpty,
        isTrue,
        reason: 'orgsStepBasicData (es) should not be empty',
      );
      expect(
        es.orgsStepAdminUser,
        isA<String>(),
        reason: 'orgsStepAdminUser (es)',
      );
      expect(
        es.orgsStepAdminUser.isNotEmpty,
        isTrue,
        reason: 'orgsStepAdminUser (es) should not be empty',
      );
      expect(es.orgsStepSummary, isA<String>(), reason: 'orgsStepSummary (es)');
      expect(
        es.orgsStepSummary.isNotEmpty,
        isTrue,
        reason: 'orgsStepSummary (es) should not be empty',
      );
      expect(
        es.orgsFieldNameLabel,
        isA<String>(),
        reason: 'orgsFieldNameLabel (es)',
      );
      expect(
        es.orgsFieldNameLabel.isNotEmpty,
        isTrue,
        reason: 'orgsFieldNameLabel (es) should not be empty',
      );
      expect(
        es.orgsFieldEmailLabel,
        isA<String>(),
        reason: 'orgsFieldEmailLabel (es)',
      );
      expect(
        es.orgsFieldEmailLabel.isNotEmpty,
        isTrue,
        reason: 'orgsFieldEmailLabel (es) should not be empty',
      );
      expect(
        es.orgsFieldAdminNameLabel,
        isA<String>(),
        reason: 'orgsFieldAdminNameLabel (es)',
      );
      expect(
        es.orgsFieldAdminNameLabel.isNotEmpty,
        isTrue,
        reason: 'orgsFieldAdminNameLabel (es) should not be empty',
      );
      expect(
        es.orgsFieldAdminEmailLabel,
        isA<String>(),
        reason: 'orgsFieldAdminEmailLabel (es)',
      );
      expect(
        es.orgsFieldAdminEmailLabel.isNotEmpty,
        isTrue,
        reason: 'orgsFieldAdminEmailLabel (es) should not be empty',
      );
      expect(
        es.orgsFieldAdminPassLabel,
        isA<String>(),
        reason: 'orgsFieldAdminPassLabel (es)',
      );
      expect(
        es.orgsFieldAdminPassLabel.isNotEmpty,
        isTrue,
        reason: 'orgsFieldAdminPassLabel (es) should not be empty',
      );
      expect(
        es.orgsSummarySubtitle,
        isA<String>(),
        reason: 'orgsSummarySubtitle (es)',
      );
      expect(
        es.orgsSummarySubtitle.isNotEmpty,
        isTrue,
        reason: 'orgsSummarySubtitle (es) should not be empty',
      );
      expect(
        es.orgsLabelOrganization,
        isA<String>(),
        reason: 'orgsLabelOrganization (es)',
      );
      expect(
        es.orgsLabelOrganization.isNotEmpty,
        isTrue,
        reason: 'orgsLabelOrganization (es) should not be empty',
      );
      expect(
        es.orgsLabelOfficialEmail,
        isA<String>(),
        reason: 'orgsLabelOfficialEmail (es)',
      );
      expect(
        es.orgsLabelOfficialEmail.isNotEmpty,
        isTrue,
        reason: 'orgsLabelOfficialEmail (es) should not be empty',
      );
      expect(
        es.orgsLabelAdministrator,
        isA<String>(),
        reason: 'orgsLabelAdministrator (es)',
      );
      expect(
        es.orgsLabelAdministrator.isNotEmpty,
        isTrue,
        reason: 'orgsLabelAdministrator (es) should not be empty',
      );
      expect(
        es.orgsLabelAdminEmail,
        isA<String>(),
        reason: 'orgsLabelAdminEmail (es)',
      );
      expect(
        es.orgsLabelAdminEmail.isNotEmpty,
        isTrue,
        reason: 'orgsLabelAdminEmail (es) should not be empty',
      );
      expect(
        es.orgsLabelProvisionalPass,
        isA<String>(),
        reason: 'orgsLabelProvisionalPass (es)',
      );
      expect(
        es.orgsLabelProvisionalPass.isNotEmpty,
        isTrue,
        reason: 'orgsLabelProvisionalPass (es) should not be empty',
      );
      expect(es.step, isA<String>(), reason: 'step (es)');
      expect(
        es.step.isNotEmpty,
        isTrue,
        reason: 'step (es) should not be empty',
      );
      expect(es.labelNameAdmin, isA<String>(), reason: 'labelNameAdmin (es)');
      expect(
        es.labelNameAdmin.isNotEmpty,
        isTrue,
        reason: 'labelNameAdmin (es) should not be empty',
      );
      expect(es.orgDetailTitle, isA<String>(), reason: 'orgDetailTitle (es)');
      expect(
        es.orgDetailTitle.isNotEmpty,
        isTrue,
        reason: 'orgDetailTitle (es) should not be empty',
      );
      expect(es.orgDetailId, isA<String>(), reason: 'orgDetailId (es)');
      expect(
        es.orgDetailId.isNotEmpty,
        isTrue,
        reason: 'orgDetailId (es) should not be empty',
      );
      expect(es.orgDeleteButton, isA<String>(), reason: 'orgDeleteButton (es)');
      expect(
        es.orgDeleteButton.isNotEmpty,
        isTrue,
        reason: 'orgDeleteButton (es) should not be empty',
      );
      expect(
        es.orgDeleteDialogTitle,
        isA<String>(),
        reason: 'orgDeleteDialogTitle (es)',
      );
      expect(
        es.orgDeleteDialogTitle.isNotEmpty,
        isTrue,
        reason: 'orgDeleteDialogTitle (es) should not be empty',
      );
      expect(
        es.orgDeleteDialogContent,
        isA<String>(),
        reason: 'orgDeleteDialogContent (es)',
      );
      expect(
        es.orgDeleteDialogContent.isNotEmpty,
        isTrue,
        reason: 'orgDeleteDialogContent (es) should not be empty',
      );
    });

    test('pendingSync interpolates {n} correctly', () {
      expect(es.pendingSync(0), contains('0'));
      expect(es.pendingSync(1), contains('1'));
      expect(es.pendingSync(42), contains('42'));
      expect(es.pendingSync(5), isNot(contains('{n}')));
    });
  });

  group('AppStrings - English locale (en)', () {
    final en = AppStrings.forTesting('en');

    test('every getter returns a non-empty String', () {
      // ── ─ Locale state ──

      // ── ─ String access ──

      // ── Auth ──
      expect(en.appName, isA<String>(), reason: 'appName (en)');
      expect(
        en.appName.isNotEmpty,
        isTrue,
        reason: 'appName (en) should not be empty',
      );
      expect(en.appSubtitle, isA<String>(), reason: 'appSubtitle (en)');
      expect(
        en.appSubtitle.isNotEmpty,
        isTrue,
        reason: 'appSubtitle (en) should not be empty',
      );
      expect(en.signIn, isA<String>(), reason: 'signIn (en)');
      expect(
        en.signIn.isNotEmpty,
        isTrue,
        reason: 'signIn (en) should not be empty',
      );
      expect(en.welcome, isA<String>(), reason: 'welcome (en)');
      expect(
        en.welcome.isNotEmpty,
        isTrue,
        reason: 'welcome (en) should not be empty',
      );
      expect(en.welcomeSub, isA<String>(), reason: 'welcomeSub (en)');
      expect(
        en.welcomeSub.isNotEmpty,
        isTrue,
        reason: 'welcomeSub (en) should not be empty',
      );
      expect(en.email, isA<String>(), reason: 'email (en)');
      expect(
        en.email.isNotEmpty,
        isTrue,
        reason: 'email (en) should not be empty',
      );
      expect(en.emailHint, isA<String>(), reason: 'emailHint (en)');
      expect(
        en.emailHint.isNotEmpty,
        isTrue,
        reason: 'emailHint (en) should not be empty',
      );
      expect(en.emailRequired, isA<String>(), reason: 'emailRequired (en)');
      expect(
        en.emailRequired.isNotEmpty,
        isTrue,
        reason: 'emailRequired (en) should not be empty',
      );
      expect(en.emailInvalid, isA<String>(), reason: 'emailInvalid (en)');
      expect(
        en.emailInvalid.isNotEmpty,
        isTrue,
        reason: 'emailInvalid (en) should not be empty',
      );
      expect(en.password, isA<String>(), reason: 'password (en)');
      expect(
        en.password.isNotEmpty,
        isTrue,
        reason: 'password (en) should not be empty',
      );
      expect(
        en.passwordRequired,
        isA<String>(),
        reason: 'passwordRequired (en)',
      );
      expect(
        en.passwordRequired.isNotEmpty,
        isTrue,
        reason: 'passwordRequired (en) should not be empty',
      );
      expect(
        en.passwordTooShort,
        isA<String>(),
        reason: 'passwordTooShort (en)',
      );
      expect(
        en.passwordTooShort.isNotEmpty,
        isTrue,
        reason: 'passwordTooShort (en) should not be empty',
      );
      expect(en.login, isA<String>(), reason: 'login (en)');
      expect(
        en.login.isNotEmpty,
        isTrue,
        reason: 'login (en) should not be empty',
      );
      expect(en.loginFailed, isA<String>(), reason: 'loginFailed (en)');
      expect(
        en.loginFailed.isNotEmpty,
        isTrue,
        reason: 'loginFailed (en) should not be empty',
      );
      expect(
        en.enterEmailPassword,
        isA<String>(),
        reason: 'enterEmailPassword (en)',
      );
      expect(
        en.enterEmailPassword.isNotEmpty,
        isTrue,
        reason: 'enterEmailPassword (en) should not be empty',
      );
      expect(en.forgotPassword, isA<String>(), reason: 'forgotPassword (en)');
      expect(
        en.forgotPassword.isNotEmpty,
        isTrue,
        reason: 'forgotPassword (en) should not be empty',
      );
      expect(
        en.forgotPasswordMessage,
        isA<String>(),
        reason: 'forgotPasswordMessage (en)',
      );
      expect(
        en.forgotPasswordMessage.isNotEmpty,
        isTrue,
        reason: 'forgotPasswordMessage (en) should not be empty',
      );
      expect(en.ok, isA<String>(), reason: 'ok (en)');
      expect(en.ok.isNotEmpty, isTrue, reason: 'ok (en) should not be empty');
      expect(en.noAccount, isA<String>(), reason: 'noAccount (en)');
      expect(
        en.noAccount.isNotEmpty,
        isTrue,
        reason: 'noAccount (en) should not be empty',
      );
      expect(en.contactAdmin, isA<String>(), reason: 'contactAdmin (en)');
      expect(
        en.contactAdmin.isNotEmpty,
        isTrue,
        reason: 'contactAdmin (en) should not be empty',
      );
      expect(en.sessionExpired, isA<String>(), reason: 'sessionExpired (en)');
      expect(
        en.sessionExpired.isNotEmpty,
        isTrue,
        reason: 'sessionExpired (en) should not be empty',
      );

      // ── Home ──
      expect(en.home, isA<String>(), reason: 'home (en)');
      expect(
        en.home.isNotEmpty,
        isTrue,
        reason: 'home (en) should not be empty',
      );
      expect(en.readNfc, isA<String>(), reason: 'readNfc (en)');
      expect(
        en.readNfc.isNotEmpty,
        isTrue,
        reason: 'readNfc (en) should not be empty',
      );
      expect(en.readNfcSub, isA<String>(), reason: 'readNfcSub (en)');
      expect(
        en.readNfcSub.isNotEmpty,
        isTrue,
        reason: 'readNfcSub (en) should not be empty',
      );
      expect(en.registerNfc, isA<String>(), reason: 'registerNfc (en)');
      expect(
        en.registerNfc.isNotEmpty,
        isTrue,
        reason: 'registerNfc (en) should not be empty',
      );
      expect(en.registerNfcSub, isA<String>(), reason: 'registerNfcSub (en)');
      expect(
        en.registerNfcSub.isNotEmpty,
        isTrue,
        reason: 'registerNfcSub (en) should not be empty',
      );
      expect(en.syncQueue, isA<String>(), reason: 'syncQueue (en)');
      expect(
        en.syncQueue.isNotEmpty,
        isTrue,
        reason: 'syncQueue (en) should not be empty',
      );
      expect(
        en.allRecordsSynced,
        isA<String>(),
        reason: 'allRecordsSynced (en)',
      );
      expect(
        en.allRecordsSynced.isNotEmpty,
        isTrue,
        reason: 'allRecordsSynced (en) should not be empty',
      );
      expect(en.lossOfWristband, isA<String>(), reason: 'lossOfWristband (en)');
      expect(
        en.lossOfWristband.isNotEmpty,
        isTrue,
        reason: 'lossOfWristband (en) should not be empty',
      );
      expect(
        en.lossOfWristbandSub,
        isA<String>(),
        reason: 'lossOfWristbandSub (en)',
      );
      expect(
        en.lossOfWristbandSub.isNotEmpty,
        isTrue,
        reason: 'lossOfWristbandSub (en) should not be empty',
      );
      expect(en.brigadeHistory, isA<String>(), reason: 'brigadeHistory (en)');
      expect(
        en.brigadeHistory.isNotEmpty,
        isTrue,
        reason: 'brigadeHistory (en) should not be empty',
      );
      expect(
        en.brigadeHistorySub,
        isA<String>(),
        reason: 'brigadeHistorySub (en)',
      );
      expect(
        en.brigadeHistorySub.isNotEmpty,
        isTrue,
        reason: 'brigadeHistorySub (en) should not be empty',
      );

      // ── Common ──
      expect(en.back, isA<String>(), reason: 'back (en)');
      expect(
        en.back.isNotEmpty,
        isTrue,
        reason: 'back (en) should not be empty',
      );
      expect(en.next, isA<String>(), reason: 'next (en)');
      expect(
        en.next.isNotEmpty,
        isTrue,
        reason: 'next (en) should not be empty',
      );
      expect(en.continueBtn, isA<String>(), reason: 'continueBtn (en)');
      expect(
        en.continueBtn.isNotEmpty,
        isTrue,
        reason: 'continueBtn (en) should not be empty',
      );
      expect(en.cancel, isA<String>(), reason: 'cancel (en)');
      expect(
        en.cancel.isNotEmpty,
        isTrue,
        reason: 'cancel (en) should not be empty',
      );
      expect(en.save, isA<String>(), reason: 'save (en)');
      expect(
        en.save.isNotEmpty,
        isTrue,
        reason: 'save (en) should not be empty',
      );
      expect(en.search, isA<String>(), reason: 'search (en)');
      expect(
        en.search.isNotEmpty,
        isTrue,
        reason: 'search (en) should not be empty',
      );
      expect(en.retry, isA<String>(), reason: 'retry (en)');
      expect(
        en.retry.isNotEmpty,
        isTrue,
        reason: 'retry (en) should not be empty',
      );
      expect(en.delete, isA<String>(), reason: 'delete (en)');
      expect(
        en.delete.isNotEmpty,
        isTrue,
        reason: 'delete (en) should not be empty',
      );
      expect(en.confirm, isA<String>(), reason: 'confirm (en)');
      expect(
        en.confirm.isNotEmpty,
        isTrue,
        reason: 'confirm (en) should not be empty',
      );
      expect(en.confirmChanges, isA<String>(), reason: 'confirmChanges (en)');
      expect(
        en.confirmChanges.isNotEmpty,
        isTrue,
        reason: 'confirmChanges (en) should not be empty',
      );
      expect(en.loading, isA<String>(), reason: 'loading (en)');
      expect(
        en.loading.isNotEmpty,
        isTrue,
        reason: 'loading (en) should not be empty',
      );
      expect(en.error, isA<String>(), reason: 'error (en)');
      expect(
        en.error.isNotEmpty,
        isTrue,
        reason: 'error (en) should not be empty',
      );
      expect(en.success, isA<String>(), reason: 'success (en)');
      expect(
        en.success.isNotEmpty,
        isTrue,
        reason: 'success (en) should not be empty',
      );
      expect(en.noData, isA<String>(), reason: 'noData (en)');
      expect(
        en.noData.isNotEmpty,
        isTrue,
        reason: 'noData (en) should not be empty',
      );
      expect(en.searchError, isA<String>(), reason: 'searchError (en)');
      expect(
        en.searchError.isNotEmpty,
        isTrue,
        reason: 'searchError (en) should not be empty',
      );

      // ── Register NFC ──
      expect(en.registerTitle, isA<String>(), reason: 'registerTitle (en)');
      expect(
        en.registerTitle.isNotEmpty,
        isTrue,
        reason: 'registerTitle (en) should not be empty',
      );
      expect(
        en.scanNewWristband,
        isA<String>(),
        reason: 'scanNewWristband (en)',
      );
      expect(
        en.scanNewWristband.isNotEmpty,
        isTrue,
        reason: 'scanNewWristband (en) should not be empty',
      );
      expect(
        en.scanNewWristbandSub,
        isA<String>(),
        reason: 'scanNewWristbandSub (en)',
      );
      expect(
        en.scanNewWristbandSub.isNotEmpty,
        isTrue,
        reason: 'scanNewWristbandSub (en) should not be empty',
      );
      expect(en.wristbandReady, isA<String>(), reason: 'wristbandReady (en)');
      expect(
        en.wristbandReady.isNotEmpty,
        isTrue,
        reason: 'wristbandReady (en) should not be empty',
      );
      expect(en.nfcNotAvailable, isA<String>(), reason: 'nfcNotAvailable (en)');
      expect(
        en.nfcNotAvailable.isNotEmpty,
        isTrue,
        reason: 'nfcNotAvailable (en) should not be empty',
      );
      expect(en.manualUidHint, isA<String>(), reason: 'manualUidHint (en)');
      expect(
        en.manualUidHint.isNotEmpty,
        isTrue,
        reason: 'manualUidHint (en) should not be empty',
      );
      expect(en.validWristbands, isA<String>(), reason: 'validWristbands (en)');
      expect(
        en.validWristbands.isNotEmpty,
        isTrue,
        reason: 'validWristbands (en) should not be empty',
      );
      expect(en.patientData, isA<String>(), reason: 'patientData (en)');
      expect(
        en.patientData.isNotEmpty,
        isTrue,
        reason: 'patientData (en) should not be empty',
      );
      expect(
        en.registrationComplete,
        isA<String>(),
        reason: 'registrationComplete (en)',
      );
      expect(
        en.registrationComplete.isNotEmpty,
        isTrue,
        reason: 'registrationComplete (en) should not be empty',
      );
      expect(
        en.patientRegistered,
        isA<String>(),
        reason: 'patientRegistered (en)',
      );
      expect(
        en.patientRegistered.isNotEmpty,
        isTrue,
        reason: 'patientRegistered (en) should not be empty',
      );
      expect(
        en.dataSavedLocally,
        isA<String>(),
        reason: 'dataSavedLocally (en)',
      );
      expect(
        en.dataSavedLocally.isNotEmpty,
        isTrue,
        reason: 'dataSavedLocally (en) should not be empty',
      );
      expect(
        en.wristbandWritten,
        isA<String>(),
        reason: 'wristbandWritten (en)',
      );
      expect(
        en.wristbandWritten.isNotEmpty,
        isTrue,
        reason: 'wristbandWritten (en) should not be empty',
      );
      expect(en.syncPending, isA<String>(), reason: 'syncPending (en)');
      expect(
        en.syncPending.isNotEmpty,
        isTrue,
        reason: 'syncPending (en) should not be empty',
      );
      expect(
        en.confirmRegistration,
        isA<String>(),
        reason: 'confirmRegistration (en)',
      );
      expect(
        en.confirmRegistration.isNotEmpty,
        isTrue,
        reason: 'confirmRegistration (en) should not be empty',
      );
      expect(en.reviewData, isA<String>(), reason: 'reviewData (en)');
      expect(
        en.reviewData.isNotEmpty,
        isTrue,
        reason: 'reviewData (en) should not be empty',
      );
      expect(en.addConsultation, isA<String>(), reason: 'addConsultation (en)');
      expect(
        en.addConsultation.isNotEmpty,
        isTrue,
        reason: 'addConsultation (en) should not be empty',
      );
      expect(en.addVaccine, isA<String>(), reason: 'addVaccine (en)');
      expect(
        en.addVaccine.isNotEmpty,
        isTrue,
        reason: 'addVaccine (en) should not be empty',
      );
      expect(en.goHome, isA<String>(), reason: 'goHome (en)');
      expect(
        en.goHome.isNotEmpty,
        isTrue,
        reason: 'goHome (en) should not be empty',
      );
      expect(en.saving, isA<String>(), reason: 'saving (en)');
      expect(
        en.saving.isNotEmpty,
        isTrue,
        reason: 'saving (en) should not be empty',
      );
      expect(en.saveError, isA<String>(), reason: 'saveError (en)');
      expect(
        en.saveError.isNotEmpty,
        isTrue,
        reason: 'saveError (en) should not be empty',
      );
      expect(en.newPatient, isA<String>(), reason: 'newPatient (en)');
      expect(
        en.newPatient.isNotEmpty,
        isTrue,
        reason: 'newPatient (en) should not be empty',
      );
      expect(
        en.consultationSaved,
        isA<String>(),
        reason: 'consultationSaved (en)',
      );
      expect(
        en.consultationSaved.isNotEmpty,
        isTrue,
        reason: 'consultationSaved (en) should not be empty',
      );
      expect(en.vaccineSaved, isA<String>(), reason: 'vaccineSaved (en)');
      expect(
        en.vaccineSaved.isNotEmpty,
        isTrue,
        reason: 'vaccineSaved (en) should not be empty',
      );
      expect(en.today, isA<String>(), reason: 'today (en)');
      expect(
        en.today.isNotEmpty,
        isTrue,
        reason: 'today (en) should not be empty',
      );
      expect(
        en.patientNfcDevice,
        isA<String>(),
        reason: 'patientNfcDevice (en)',
      );
      expect(
        en.patientNfcDevice.isNotEmpty,
        isTrue,
        reason: 'patientNfcDevice (en) should not be empty',
      );
      expect(
        en.patientNfcDeviceSub,
        isA<String>(),
        reason: 'patientNfcDeviceSub (en)',
      );
      expect(
        en.patientNfcDeviceSub.isNotEmpty,
        isTrue,
        reason: 'patientNfcDeviceSub (en) should not be empty',
      );
      expect(en.nfcUidRequired, isA<String>(), reason: 'nfcUidRequired (en)');
      expect(
        en.nfcUidRequired.isNotEmpty,
        isTrue,
        reason: 'nfcUidRequired (en) should not be empty',
      );

      // ── Patient form fields ──
      expect(en.identification, isA<String>(), reason: 'identification (en)');
      expect(
        en.identification.isNotEmpty,
        isTrue,
        reason: 'identification (en) should not be empty',
      );
      expect(en.documentType, isA<String>(), reason: 'documentType (en)');
      expect(
        en.documentType.isNotEmpty,
        isTrue,
        reason: 'documentType (en) should not be empty',
      );
      expect(en.documentNumber, isA<String>(), reason: 'documentNumber (en)');
      expect(
        en.documentNumber.isNotEmpty,
        isTrue,
        reason: 'documentNumber (en) should not be empty',
      );
      expect(en.firstNames, isA<String>(), reason: 'firstNames (en)');
      expect(
        en.firstNames.isNotEmpty,
        isTrue,
        reason: 'firstNames (en) should not be empty',
      );
      expect(en.secondName, isA<String>(), reason: 'secondName (en)');
      expect(
        en.secondName.isNotEmpty,
        isTrue,
        reason: 'secondName (en) should not be empty',
      );
      expect(en.firstLastName, isA<String>(), reason: 'firstLastName (en)');
      expect(
        en.firstLastName.isNotEmpty,
        isTrue,
        reason: 'firstLastName (en) should not be empty',
      );
      expect(en.secondLastName, isA<String>(), reason: 'secondLastName (en)');
      expect(
        en.secondLastName.isNotEmpty,
        isTrue,
        reason: 'secondLastName (en) should not be empty',
      );
      expect(en.gender, isA<String>(), reason: 'gender (en)');
      expect(
        en.gender.isNotEmpty,
        isTrue,
        reason: 'gender (en) should not be empty',
      );
      expect(en.dateOfBirth, isA<String>(), reason: 'dateOfBirth (en)');
      expect(
        en.dateOfBirth.isNotEmpty,
        isTrue,
        reason: 'dateOfBirth (en) should not be empty',
      );
      expect(en.nationality, isA<String>(), reason: 'nationality (en)');
      expect(
        en.nationality.isNotEmpty,
        isTrue,
        reason: 'nationality (en) should not be empty',
      );
      expect(en.origin, isA<String>(), reason: 'origin (en)');
      expect(
        en.origin.isNotEmpty,
        isTrue,
        reason: 'origin (en) should not be empty',
      );
      expect(en.cityRegion, isA<String>(), reason: 'cityRegion (en)');
      expect(
        en.cityRegion.isNotEmpty,
        isTrue,
        reason: 'cityRegion (en) should not be empty',
      );
      expect(en.stateDepartment, isA<String>(), reason: 'stateDepartment (en)');
      expect(
        en.stateDepartment.isNotEmpty,
        isTrue,
        reason: 'stateDepartment (en) should not be empty',
      );
      expect(en.clinicalData, isA<String>(), reason: 'clinicalData (en)');
      expect(
        en.clinicalData.isNotEmpty,
        isTrue,
        reason: 'clinicalData (en) should not be empty',
      );
      expect(en.bloodType, isA<String>(), reason: 'bloodType (en)');
      expect(
        en.bloodType.isNotEmpty,
        isTrue,
        reason: 'bloodType (en) should not be empty',
      );
      expect(en.weight, isA<String>(), reason: 'weight (en)');
      expect(
        en.weight.isNotEmpty,
        isTrue,
        reason: 'weight (en) should not be empty',
      );
      expect(en.height, isA<String>(), reason: 'height (en)');
      expect(
        en.height.isNotEmpty,
        isTrue,
        reason: 'height (en) should not be empty',
      );

      // ── Guardian ──
      expect(en.guardianSection, isA<String>(), reason: 'guardianSection (en)');
      expect(
        en.guardianSection.isNotEmpty,
        isTrue,
        reason: 'guardianSection (en) should not be empty',
      );
      expect(en.guardianName, isA<String>(), reason: 'guardianName (en)');
      expect(
        en.guardianName.isNotEmpty,
        isTrue,
        reason: 'guardianName (en) should not be empty',
      );
      expect(en.relationship, isA<String>(), reason: 'relationship (en)');
      expect(
        en.relationship.isNotEmpty,
        isTrue,
        reason: 'relationship (en) should not be empty',
      );
      expect(en.guardianPhone, isA<String>(), reason: 'guardianPhone (en)');
      expect(
        en.guardianPhone.isNotEmpty,
        isTrue,
        reason: 'guardianPhone (en) should not be empty',
      );
      expect(en.guardianPin, isA<String>(), reason: 'guardianPin (en)');
      expect(
        en.guardianPin.isNotEmpty,
        isTrue,
        reason: 'guardianPin (en) should not be empty',
      );
      expect(en.guardianDocType, isA<String>(), reason: 'guardianDocType (en)');
      expect(
        en.guardianDocType.isNotEmpty,
        isTrue,
        reason: 'guardianDocType (en) should not be empty',
      );
      expect(
        en.guardianDocNumber,
        isA<String>(),
        reason: 'guardianDocNumber (en)',
      );
      expect(
        en.guardianDocNumber.isNotEmpty,
        isTrue,
        reason: 'guardianDocNumber (en) should not be empty',
      );
      expect(
        en.guardianAuthAccepted,
        isA<String>(),
        reason: 'guardianAuthAccepted (en)',
      );
      expect(
        en.guardianAuthAccepted.isNotEmpty,
        isTrue,
        reason: 'guardianAuthAccepted (en) should not be empty',
      );
      expect(en.guardianEmail, isA<String>(), reason: 'guardianEmail (en)');
      expect(
        en.guardianEmail.isNotEmpty,
        isTrue,
        reason: 'guardianEmail (en) should not be empty',
      );
      expect(
        en.editGuardianTitle,
        isA<String>(),
        reason: 'editGuardianTitle (en)',
      );
      expect(
        en.editGuardianTitle.isNotEmpty,
        isTrue,
        reason: 'editGuardianTitle (en) should not be empty',
      );
      expect(
        en.guardianFullName,
        isA<String>(),
        reason: 'guardianFullName (en)',
      );
      expect(
        en.guardianFullName.isNotEmpty,
        isTrue,
        reason: 'guardianFullName (en) should not be empty',
      );
      expect(
        en.guardianFullNameHint,
        isA<String>(),
        reason: 'guardianFullNameHint (en)',
      );
      expect(
        en.guardianFullNameHint.isNotEmpty,
        isTrue,
        reason: 'guardianFullNameHint (en) should not be empty',
      );
      expect(
        en.guardianRelationship,
        isA<String>(),
        reason: 'guardianRelationship (en)',
      );
      expect(
        en.guardianRelationship.isNotEmpty,
        isTrue,
        reason: 'guardianRelationship (en) should not be empty',
      );
      expect(
        en.guardianPhoneLabel,
        isA<String>(),
        reason: 'guardianPhoneLabel (en)',
      );
      expect(
        en.guardianPhoneLabel.isNotEmpty,
        isTrue,
        reason: 'guardianPhoneLabel (en) should not be empty',
      );
      expect(
        en.guardianPhoneHint,
        isA<String>(),
        reason: 'guardianPhoneHint (en)',
      );
      expect(
        en.guardianPhoneHint.isNotEmpty,
        isTrue,
        reason: 'guardianPhoneHint (en) should not be empty',
      );
      expect(
        en.guardianNfcDevice,
        isA<String>(),
        reason: 'guardianNfcDevice (en)',
      );
      expect(
        en.guardianNfcDevice.isNotEmpty,
        isTrue,
        reason: 'guardianNfcDevice (en) should not be empty',
      );
      expect(
        en.guardianNfcUidHint,
        isA<String>(),
        reason: 'guardianNfcUidHint (en)',
      );
      expect(
        en.guardianNfcUidHint.isNotEmpty,
        isTrue,
        reason: 'guardianNfcUidHint (en) should not be empty',
      );
      expect(
        en.guardianNfcUnavailable,
        isA<String>(),
        reason: 'guardianNfcUnavailable (en)',
      );
      expect(
        en.guardianNfcUnavailable.isNotEmpty,
        isTrue,
        reason: 'guardianNfcUnavailable (en) should not be empty',
      );
      expect(
        en.guardianNfcError,
        isA<String>(),
        reason: 'guardianNfcError (en)',
      );
      expect(
        en.guardianNfcError.isNotEmpty,
        isTrue,
        reason: 'guardianNfcError (en) should not be empty',
      );
      expect(en.relParents, isA<String>(), reason: 'relParents (en)');
      expect(
        en.relParents.isNotEmpty,
        isTrue,
        reason: 'relParents (en) should not be empty',
      );
      expect(en.relSiblings, isA<String>(), reason: 'relSiblings (en)');
      expect(
        en.relSiblings.isNotEmpty,
        isTrue,
        reason: 'relSiblings (en) should not be empty',
      );
      expect(en.relUncles, isA<String>(), reason: 'relUncles (en)');
      expect(
        en.relUncles.isNotEmpty,
        isTrue,
        reason: 'relUncles (en) should not be empty',
      );
      expect(en.relGrandparents, isA<String>(), reason: 'relGrandparents (en)');
      expect(
        en.relGrandparents.isNotEmpty,
        isTrue,
        reason: 'relGrandparents (en) should not be empty',
      );

      // ── Read NFC ──
      expect(en.scanWristband, isA<String>(), reason: 'scanWristband (en)');
      expect(
        en.scanWristband.isNotEmpty,
        isTrue,
        reason: 'scanWristband (en) should not be empty',
      );
      expect(en.holdWristband, isA<String>(), reason: 'holdWristband (en)');
      expect(
        en.holdWristband.isNotEmpty,
        isTrue,
        reason: 'holdWristband (en) should not be empty',
      );
      expect(en.scanning, isA<String>(), reason: 'scanning (en)');
      expect(
        en.scanning.isNotEmpty,
        isTrue,
        reason: 'scanning (en) should not be empty',
      );
      expect(en.scanSuccess, isA<String>(), reason: 'scanSuccess (en)');
      expect(
        en.scanSuccess.isNotEmpty,
        isTrue,
        reason: 'scanSuccess (en) should not be empty',
      );
      expect(en.scanFailed, isA<String>(), reason: 'scanFailed (en)');
      expect(
        en.scanFailed.isNotEmpty,
        isTrue,
        reason: 'scanFailed (en) should not be empty',
      );
      expect(
        en.guardianRequired,
        isA<String>(),
        reason: 'guardianRequired (en)',
      );
      expect(
        en.guardianRequired.isNotEmpty,
        isTrue,
        reason: 'guardianRequired (en) should not be empty',
      );
      expect(
        en.guardianRequiredSub,
        isA<String>(),
        reason: 'guardianRequiredSub (en)',
      );
      expect(
        en.guardianRequiredSub.isNotEmpty,
        isTrue,
        reason: 'guardianRequiredSub (en) should not be empty',
      );
      expect(
        en.scanGuardianWristband,
        isA<String>(),
        reason: 'scanGuardianWristband (en)',
      );
      expect(
        en.scanGuardianWristband.isNotEmpty,
        isTrue,
        reason: 'scanGuardianWristband (en) should not be empty',
      );
      expect(en.continueToRead, isA<String>(), reason: 'continueToRead (en)');
      expect(
        en.continueToRead.isNotEmpty,
        isTrue,
        reason: 'continueToRead (en) should not be empty',
      );
      expect(en.readyToScan, isA<String>(), reason: 'readyToScan (en)');
      expect(
        en.readyToScan.isNotEmpty,
        isTrue,
        reason: 'readyToScan (en) should not be empty',
      );

      // ── Patient detail ──
      expect(en.patient, isA<String>(), reason: 'patient (en)');
      expect(
        en.patient.isNotEmpty,
        isTrue,
        reason: 'patient (en) should not be empty',
      );
      expect(en.guardian, isA<String>(), reason: 'guardian (en)');
      expect(
        en.guardian.isNotEmpty,
        isTrue,
        reason: 'guardian (en) should not be empty',
      );
      expect(en.medicalHistory, isA<String>(), reason: 'medicalHistory (en)');
      expect(
        en.medicalHistory.isNotEmpty,
        isTrue,
        reason: 'medicalHistory (en) should not be empty',
      );
      expect(en.medicalStaff, isA<String>(), reason: 'medicalStaff (en)');
      expect(
        en.medicalStaff.isNotEmpty,
        isTrue,
        reason: 'medicalStaff (en) should not be empty',
      );
      expect(en.consultations, isA<String>(), reason: 'consultations (en)');
      expect(
        en.consultations.isNotEmpty,
        isTrue,
        reason: 'consultations (en) should not be empty',
      );
      expect(en.vaccines, isA<String>(), reason: 'vaccines (en)');
      expect(
        en.vaccines.isNotEmpty,
        isTrue,
        reason: 'vaccines (en) should not be empty',
      );
      expect(en.allergens, isA<String>(), reason: 'allergens (en)');
      expect(
        en.allergens.isNotEmpty,
        isTrue,
        reason: 'allergens (en) should not be empty',
      );
      expect(en.showVaccines, isA<String>(), reason: 'showVaccines (en)');
      expect(
        en.showVaccines.isNotEmpty,
        isTrue,
        reason: 'showVaccines (en) should not be empty',
      );
      expect(en.moreDetails, isA<String>(), reason: 'moreDetails (en)');
      expect(
        en.moreDetails.isNotEmpty,
        isTrue,
        reason: 'moreDetails (en) should not be empty',
      );
      expect(en.updatePatient, isA<String>(), reason: 'updatePatient (en)');
      expect(
        en.updatePatient.isNotEmpty,
        isTrue,
        reason: 'updatePatient (en) should not be empty',
      );
      expect(en.lastUpdated, isA<String>(), reason: 'lastUpdated (en)');
      expect(
        en.lastUpdated.isNotEmpty,
        isTrue,
        reason: 'lastUpdated (en) should not be empty',
      );
      expect(
        en.chronicCondition,
        isA<String>(),
        reason: 'chronicCondition (en)',
      );
      expect(
        en.chronicCondition.isNotEmpty,
        isTrue,
        reason: 'chronicCondition (en) should not be empty',
      );

      // ── Edit screens ──
      expect(en.editUpdate, isA<String>(), reason: 'editUpdate (en)');
      expect(
        en.editUpdate.isNotEmpty,
        isTrue,
        reason: 'editUpdate (en) should not be empty',
      );
      expect(
        en.patientInfoReadOnly,
        isA<String>(),
        reason: 'patientInfoReadOnly (en)',
      );
      expect(
        en.patientInfoReadOnly.isNotEmpty,
        isTrue,
        reason: 'patientInfoReadOnly (en) should not be empty',
      );
      expect(en.fieldsProtected, isA<String>(), reason: 'fieldsProtected (en)');
      expect(
        en.fieldsProtected.isNotEmpty,
        isTrue,
        reason: 'fieldsProtected (en) should not be empty',
      );
      expect(en.editableInfo, isA<String>(), reason: 'editableInfo (en)');
      expect(
        en.editableInfo.isNotEmpty,
        isTrue,
        reason: 'editableInfo (en) should not be empty',
      );
      expect(en.address, isA<String>(), reason: 'address (en)');
      expect(
        en.address.isNotEmpty,
        isTrue,
        reason: 'address (en) should not be empty',
      );
      expect(en.street, isA<String>(), reason: 'street (en)');
      expect(
        en.street.isNotEmpty,
        isTrue,
        reason: 'street (en) should not be empty',
      );
      expect(en.city, isA<String>(), reason: 'city (en)');
      expect(
        en.city.isNotEmpty,
        isTrue,
        reason: 'city (en) should not be empty',
      );
      expect(en.state, isA<String>(), reason: 'state (en)');
      expect(
        en.state.isNotEmpty,
        isTrue,
        reason: 'state (en) should not be empty',
      );
      expect(en.name, isA<String>(), reason: 'name (en)');
      expect(
        en.name.isNotEmpty,
        isTrue,
        reason: 'name (en) should not be empty',
      );

      // ── Edit address sheet ──
      expect(en.editResidence, isA<String>(), reason: 'editResidence (en)');
      expect(
        en.editResidence.isNotEmpty,
        isTrue,
        reason: 'editResidence (en) should not be empty',
      );
      expect(
        en.addressZoneSubtitle,
        isA<String>(),
        reason: 'addressZoneSubtitle (en)',
      );
      expect(
        en.addressZoneSubtitle.isNotEmpty,
        isTrue,
        reason: 'addressZoneSubtitle (en) should not be empty',
      );
      expect(en.municipality, isA<String>(), reason: 'municipality (en)');
      expect(
        en.municipality.isNotEmpty,
        isTrue,
        reason: 'municipality (en) should not be empty',
      );
      expect(en.department, isA<String>(), reason: 'department (en)');
      expect(
        en.department.isNotEmpty,
        isTrue,
        reason: 'department (en) should not be empty',
      );
      expect(en.zone, isA<String>(), reason: 'zone (en)');
      expect(
        en.zone.isNotEmpty,
        isTrue,
        reason: 'zone (en) should not be empty',
      );
      expect(en.streetHint, isA<String>(), reason: 'streetHint (en)');
      expect(
        en.streetHint.isNotEmpty,
        isTrue,
        reason: 'streetHint (en) should not be empty',
      );
      expect(en.cityHint, isA<String>(), reason: 'cityHint (en)');
      expect(
        en.cityHint.isNotEmpty,
        isTrue,
        reason: 'cityHint (en) should not be empty',
      );
      expect(en.stateHint, isA<String>(), reason: 'stateHint (en)');
      expect(
        en.stateHint.isNotEmpty,
        isTrue,
        reason: 'stateHint (en) should not be empty',
      );
      expect(en.zoneUrban, isA<String>(), reason: 'zoneUrban (en)');
      expect(
        en.zoneUrban.isNotEmpty,
        isTrue,
        reason: 'zoneUrban (en) should not be empty',
      );
      expect(en.zoneRural, isA<String>(), reason: 'zoneRural (en)');
      expect(
        en.zoneRural.isNotEmpty,
        isTrue,
        reason: 'zoneRural (en) should not be empty',
      );

      // ── Medical history edit ──
      expect(
        en.clinicalEvaluation,
        isA<String>(),
        reason: 'clinicalEvaluation (en)',
      );
      expect(
        en.clinicalEvaluation.isNotEmpty,
        isTrue,
        reason: 'clinicalEvaluation (en) should not be empty',
      );
      expect(
        en.historyCurrentIllness,
        isA<String>(),
        reason: 'historyCurrentIllness (en)',
      );
      expect(
        en.historyCurrentIllness.isNotEmpty,
        isTrue,
        reason: 'historyCurrentIllness (en) should not be empty',
      );
      expect(en.treatmentPlan, isA<String>(), reason: 'treatmentPlan (en)');
      expect(
        en.treatmentPlan.isNotEmpty,
        isTrue,
        reason: 'treatmentPlan (en) should not be empty',
      );
      expect(
        en.backgroundHistory,
        isA<String>(),
        reason: 'backgroundHistory (en)',
      );
      expect(
        en.backgroundHistory.isNotEmpty,
        isTrue,
        reason: 'backgroundHistory (en) should not be empty',
      );
      expect(
        en.chronicConditions,
        isA<String>(),
        reason: 'chronicConditions (en)',
      );
      expect(
        en.chronicConditions.isNotEmpty,
        isTrue,
        reason: 'chronicConditions (en) should not be empty',
      );
      expect(en.personalHistory, isA<String>(), reason: 'personalHistory (en)');
      expect(
        en.personalHistory.isNotEmpty,
        isTrue,
        reason: 'personalHistory (en) should not be empty',
      );
      expect(en.familyHistory, isA<String>(), reason: 'familyHistory (en)');
      expect(
        en.familyHistory.isNotEmpty,
        isTrue,
        reason: 'familyHistory (en) should not be empty',
      );
      expect(
        en.familyHistoryNotes,
        isA<String>(),
        reason: 'familyHistoryNotes (en)',
      );
      expect(
        en.familyHistoryNotes.isNotEmpty,
        isTrue,
        reason: 'familyHistoryNotes (en) should not be empty',
      );
      expect(
        en.addFamilyHistory,
        isA<String>(),
        reason: 'addFamilyHistory (en)',
      );
      expect(
        en.addFamilyHistory.isNotEmpty,
        isTrue,
        reason: 'addFamilyHistory (en) should not be empty',
      );
      expect(en.condition, isA<String>(), reason: 'condition (en)');
      expect(
        en.condition.isNotEmpty,
        isTrue,
        reason: 'condition (en) should not be empty',
      );
      expect(en.noFamilyHistory, isA<String>(), reason: 'noFamilyHistory (en)');
      expect(
        en.noFamilyHistory.isNotEmpty,
        isTrue,
        reason: 'noFamilyHistory (en) should not be empty',
      );
      expect(en.physicalExam, isA<String>(), reason: 'physicalExam (en)');
      expect(
        en.physicalExam.isNotEmpty,
        isTrue,
        reason: 'physicalExam (en) should not be empty',
      );
      expect(en.generalExam, isA<String>(), reason: 'generalExam (en)');
      expect(
        en.generalExam.isNotEmpty,
        isTrue,
        reason: 'generalExam (en) should not be empty',
      );
      expect(en.systemsExam, isA<String>(), reason: 'systemsExam (en)');
      expect(
        en.systemsExam.isNotEmpty,
        isTrue,
        reason: 'systemsExam (en) should not be empty',
      );
      expect(en.add, isA<String>(), reason: 'add (en)');
      expect(en.add.isNotEmpty, isTrue, reason: 'add (en) should not be empty');

      // ── Medical staff edit ──
      expect(en.practitioner, isA<String>(), reason: 'practitioner (en)');
      expect(
        en.practitioner.isNotEmpty,
        isTrue,
        reason: 'practitioner (en) should not be empty',
      );
      expect(
        en.healthcareProvider,
        isA<String>(),
        reason: 'healthcareProvider (en)',
      );
      expect(
        en.healthcareProvider.isNotEmpty,
        isTrue,
        reason: 'healthcareProvider (en) should not be empty',
      );
      expect(en.providerName, isA<String>(), reason: 'providerName (en)');
      expect(
        en.providerName.isNotEmpty,
        isTrue,
        reason: 'providerName (en) should not be empty',
      );
      expect(en.repsCode, isA<String>(), reason: 'repsCode (en)');
      expect(
        en.repsCode.isNotEmpty,
        isTrue,
        reason: 'repsCode (en) should not be empty',
      );
      expect(en.encounter, isA<String>(), reason: 'encounter (en)');
      expect(
        en.encounter.isNotEmpty,
        isTrue,
        reason: 'encounter (en) should not be empty',
      );
      expect(en.dateTime, isA<String>(), reason: 'dateTime (en)');
      expect(
        en.dateTime.isNotEmpty,
        isTrue,
        reason: 'dateTime (en) should not be empty',
      );
      expect(en.diagnosisType, isA<String>(), reason: 'diagnosisType (en)');
      expect(
        en.diagnosisType.isNotEmpty,
        isTrue,
        reason: 'diagnosisType (en) should not be empty',
      );
      expect(en.careModality, isA<String>(), reason: 'careModality (en)');
      expect(
        en.careModality.isNotEmpty,
        isTrue,
        reason: 'careModality (en) should not be empty',
      );
      expect(
        en.dischargeDisposition,
        isA<String>(),
        reason: 'dischargeDisposition (en)',
      );
      expect(
        en.dischargeDisposition.isNotEmpty,
        isTrue,
        reason: 'dischargeDisposition (en) should not be empty',
      );

      // ── Loss of wristband ──
      expect(en.searchPatient, isA<String>(), reason: 'searchPatient (en)');
      expect(
        en.searchPatient.isNotEmpty,
        isTrue,
        reason: 'searchPatient (en) should not be empty',
      );
      expect(
        en.searchRequiredFields,
        isA<String>(),
        reason: 'searchRequiredFields (en)',
      );
      expect(
        en.searchRequiredFields.isNotEmpty,
        isTrue,
        reason: 'searchRequiredFields (en) should not be empty',
      );
      expect(
        en.searchFieldsRequired,
        isA<String>(),
        reason: 'searchFieldsRequired (en)',
      );
      expect(
        en.searchFieldsRequired.isNotEmpty,
        isTrue,
        reason: 'searchFieldsRequired (en) should not be empty',
      );

      // ── Sync ──
      expect(en.syncTitle, isA<String>(), reason: 'syncTitle (en)');
      expect(
        en.syncTitle.isNotEmpty,
        isTrue,
        reason: 'syncTitle (en) should not be empty',
      );
      expect(en.syncAll, isA<String>(), reason: 'syncAll (en)');
      expect(
        en.syncAll.isNotEmpty,
        isTrue,
        reason: 'syncAll (en) should not be empty',
      );
      expect(en.syncNow, isA<String>(), reason: 'syncNow (en)');
      expect(
        en.syncNow.isNotEmpty,
        isTrue,
        reason: 'syncNow (en) should not be empty',
      );
      expect(en.review, isA<String>(), reason: 'review (en)');
      expect(
        en.review.isNotEmpty,
        isTrue,
        reason: 'review (en) should not be empty',
      );
      expect(
        en.syncedSuccessfully,
        isA<String>(),
        reason: 'syncedSuccessfully (en)',
      );
      expect(
        en.syncedSuccessfully.isNotEmpty,
        isTrue,
        reason: 'syncedSuccessfully (en) should not be empty',
      );
      expect(en.syncFailedRetry, isA<String>(), reason: 'syncFailedRetry (en)');
      expect(
        en.syncFailedRetry.isNotEmpty,
        isTrue,
        reason: 'syncFailedRetry (en) should not be empty',
      );
      expect(en.allSynced, isA<String>(), reason: 'allSynced (en)');
      expect(
        en.allSynced.isNotEmpty,
        isTrue,
        reason: 'allSynced (en) should not be empty',
      );
      expect(
        en.noRecordsPending,
        isA<String>(),
        reason: 'noRecordsPending (en)',
      );
      expect(
        en.noRecordsPending.isNotEmpty,
        isTrue,
        reason: 'noRecordsPending (en) should not be empty',
      );
      expect(en.deleteRecord, isA<String>(), reason: 'deleteRecord (en)');
      expect(
        en.deleteRecord.isNotEmpty,
        isTrue,
        reason: 'deleteRecord (en) should not be empty',
      );
      expect(
        en.deleteRecordConfirm,
        isA<String>(),
        reason: 'deleteRecordConfirm (en)',
      );
      expect(
        en.deleteRecordConfirm.isNotEmpty,
        isTrue,
        reason: 'deleteRecordConfirm (en) should not be empty',
      );
      expect(en.pending, isA<String>(), reason: 'pending (en)');
      expect(
        en.pending.isNotEmpty,
        isTrue,
        reason: 'pending (en) should not be empty',
      );

      // ── Brigade ──
      expect(en.brigadeOffline, isA<String>(), reason: 'brigadeOffline (en)');
      expect(
        en.brigadeOffline.isNotEmpty,
        isTrue,
        reason: 'brigadeOffline (en) should not be empty',
      );
      expect(
        en.patientsAppearHere,
        isA<String>(),
        reason: 'patientsAppearHere (en)',
      );
      expect(
        en.patientsAppearHere.isNotEmpty,
        isTrue,
        reason: 'patientsAppearHere (en) should not be empty',
      );
      expect(en.synchronized, isA<String>(), reason: 'synchronized (en)');
      expect(
        en.synchronized.isNotEmpty,
        isTrue,
        reason: 'synchronized (en) should not be empty',
      );
      expect(en.synchronizing, isA<String>(), reason: 'synchronizing (en)');
      expect(
        en.synchronizing.isNotEmpty,
        isTrue,
        reason: 'synchronizing (en) should not be empty',
      );

      // ── NFC Save Flow ──
      expect(en.putOnWristband, isA<String>(), reason: 'putOnWristband (en)');
      expect(
        en.putOnWristband.isNotEmpty,
        isTrue,
        reason: 'putOnWristband (en) should not be empty',
      );
      expect(en.placeWristband, isA<String>(), reason: 'placeWristband (en)');
      expect(
        en.placeWristband.isNotEmpty,
        isTrue,
        reason: 'placeWristband (en) should not be empty',
      );
      expect(en.startWriting, isA<String>(), reason: 'startWriting (en)');
      expect(
        en.startWriting.isNotEmpty,
        isTrue,
        reason: 'startWriting (en) should not be empty',
      );
      expect(en.syncingServer, isA<String>(), reason: 'syncingServer (en)');
      expect(
        en.syncingServer.isNotEmpty,
        isTrue,
        reason: 'syncingServer (en) should not be empty',
      );
      expect(en.pleaseWait, isA<String>(), reason: 'pleaseWait (en)');
      expect(
        en.pleaseWait.isNotEmpty,
        isTrue,
        reason: 'pleaseWait (en) should not be empty',
      );
      expect(
        en.successRegistration,
        isA<String>(),
        reason: 'successRegistration (en)',
      );
      expect(
        en.successRegistration.isNotEmpty,
        isTrue,
        reason: 'successRegistration (en) should not be empty',
      );
      expect(
        en.patientSavedSynced,
        isA<String>(),
        reason: 'patientSavedSynced (en)',
      );
      expect(
        en.patientSavedSynced.isNotEmpty,
        isTrue,
        reason: 'patientSavedSynced (en) should not be empty',
      );
      expect(en.syncFailed, isA<String>(), reason: 'syncFailed (en)');
      expect(
        en.syncFailed.isNotEmpty,
        isTrue,
        reason: 'syncFailed (en) should not be empty',
      );

      // ── Vaccine sheet ──
      expect(en.vaccine, isA<String>(), reason: 'vaccine (en)');
      expect(
        en.vaccine.isNotEmpty,
        isTrue,
        reason: 'vaccine (en) should not be empty',
      );
      expect(en.vaccineName, isA<String>(), reason: 'vaccineName (en)');
      expect(
        en.vaccineName.isNotEmpty,
        isTrue,
        reason: 'vaccineName (en) should not be empty',
      );
      expect(en.cvxCode, isA<String>(), reason: 'cvxCode (en)');
      expect(
        en.cvxCode.isNotEmpty,
        isTrue,
        reason: 'cvxCode (en) should not be empty',
      );
      expect(en.dose, isA<String>(), reason: 'dose (en)');
      expect(
        en.dose.isNotEmpty,
        isTrue,
        reason: 'dose (en) should not be empty',
      );
      expect(en.date, isA<String>(), reason: 'date (en)');
      expect(
        en.date.isNotEmpty,
        isTrue,
        reason: 'date (en) should not be empty',
      );
      expect(en.administeredBy, isA<String>(), reason: 'administeredBy (en)');
      expect(
        en.administeredBy.isNotEmpty,
        isTrue,
        reason: 'administeredBy (en) should not be empty',
      );
      expect(en.administeredAt, isA<String>(), reason: 'administeredAt (en)');
      expect(
        en.administeredAt.isNotEmpty,
        isTrue,
        reason: 'administeredAt (en) should not be empty',
      );

      // ── Vital signs sheet ──
      expect(
        en.editMeasurements,
        isA<String>(),
        reason: 'editMeasurements (en)',
      );
      expect(
        en.editMeasurements.isNotEmpty,
        isTrue,
        reason: 'editMeasurements (en) should not be empty',
      );
      expect(en.weightKg, isA<String>(), reason: 'weightKg (en)');
      expect(
        en.weightKg.isNotEmpty,
        isTrue,
        reason: 'weightKg (en) should not be empty',
      );
      expect(en.heightCm, isA<String>(), reason: 'heightCm (en)');
      expect(
        en.heightCm.isNotEmpty,
        isTrue,
        reason: 'heightCm (en) should not be empty',
      );
      expect(en.previous, isA<String>(), reason: 'previous (en)');
      expect(
        en.previous.isNotEmpty,
        isTrue,
        reason: 'previous (en) should not be empty',
      );
      expect(
        en.bloodTypeReadOnly,
        isA<String>(),
        reason: 'bloodTypeReadOnly (en)',
      );
      expect(
        en.bloodTypeReadOnly.isNotEmpty,
        isTrue,
        reason: 'bloodTypeReadOnly (en) should not be empty',
      );

      // ── Allergen categories ──
      expect(
        en.allergenMedication,
        isA<String>(),
        reason: 'allergenMedication (en)',
      );
      expect(
        en.allergenMedication.isNotEmpty,
        isTrue,
        reason: 'allergenMedication (en) should not be empty',
      );
      expect(en.allergenFood, isA<String>(), reason: 'allergenFood (en)');
      expect(
        en.allergenFood.isNotEmpty,
        isTrue,
        reason: 'allergenFood (en) should not be empty',
      );
      expect(
        en.allergenEnvironment,
        isA<String>(),
        reason: 'allergenEnvironment (en)',
      );
      expect(
        en.allergenEnvironment.isNotEmpty,
        isTrue,
        reason: 'allergenEnvironment (en) should not be empty',
      );
      expect(en.allergenSkin, isA<String>(), reason: 'allergenSkin (en)');
      expect(
        en.allergenSkin.isNotEmpty,
        isTrue,
        reason: 'allergenSkin (en) should not be empty',
      );
      expect(en.allergenInsect, isA<String>(), reason: 'allergenInsect (en)');
      expect(
        en.allergenInsect.isNotEmpty,
        isTrue,
        reason: 'allergenInsect (en) should not be empty',
      );
      expect(en.allergenOther, isA<String>(), reason: 'allergenOther (en)');
      expect(
        en.allergenOther.isNotEmpty,
        isTrue,
        reason: 'allergenOther (en) should not be empty',
      );

      // ── Login screen v2 / Home v2 ──
      expect(
        en.appSubtitleShort,
        isA<String>(),
        reason: 'appSubtitleShort (en)',
      );
      expect(
        en.appSubtitleShort.isNotEmpty,
        isTrue,
        reason: 'appSubtitleShort (en) should not be empty',
      );
      expect(en.emailLabel, isA<String>(), reason: 'emailLabel (en)');
      expect(
        en.emailLabel.isNotEmpty,
        isTrue,
        reason: 'emailLabel (en) should not be empty',
      );
      expect(en.passwordLabel, isA<String>(), reason: 'passwordLabel (en)');
      expect(
        en.passwordLabel.isNotEmpty,
        isTrue,
        reason: 'passwordLabel (en) should not be empty',
      );
      expect(en.rememberSession, isA<String>(), reason: 'rememberSession (en)');
      expect(
        en.rememberSession.isNotEmpty,
        isTrue,
        reason: 'rememberSession (en) should not be empty',
      );
      expect(
        en.sessionEncryptedFooter,
        isA<String>(),
        reason: 'sessionEncryptedFooter (en)',
      );
      expect(
        en.sessionEncryptedFooter.isNotEmpty,
        isTrue,
        reason: 'sessionEncryptedFooter (en) should not be empty',
      );
      expect(en.goodMorning, isA<String>(), reason: 'goodMorning (en)');
      expect(
        en.goodMorning.isNotEmpty,
        isTrue,
        reason: 'goodMorning (en) should not be empty',
      );
      expect(en.goodAfternoon, isA<String>(), reason: 'goodAfternoon (en)');
      expect(
        en.goodAfternoon.isNotEmpty,
        isTrue,
        reason: 'goodAfternoon (en) should not be empty',
      );
      expect(en.goodEvening, isA<String>(), reason: 'goodEvening (en)');
      expect(
        en.goodEvening.isNotEmpty,
        isTrue,
        reason: 'goodEvening (en) should not be empty',
      );
      expect(en.logout, isA<String>(), reason: 'logout (en)');
      expect(
        en.logout.isNotEmpty,
        isTrue,
        reason: 'logout (en) should not be empty',
      );
      expect(en.logoutTitle, isA<String>(), reason: 'logoutTitle (en)');
      expect(
        en.logoutTitle.isNotEmpty,
        isTrue,
        reason: 'logoutTitle (en) should not be empty',
      );
      expect(en.roleDoctor, isA<String>(), reason: 'roleDoctor (en)');
      expect(
        en.roleDoctor.isNotEmpty,
        isTrue,
        reason: 'roleDoctor (en) should not be empty',
      );
      expect(en.roleNurse, isA<String>(), reason: 'roleNurse (en)');
      expect(
        en.roleNurse.isNotEmpty,
        isTrue,
        reason: 'roleNurse (en) should not be empty',
      );
      expect(en.roleOrgAdmin, isA<String>(), reason: 'roleOrgAdmin (en)');
      expect(
        en.roleOrgAdmin.isNotEmpty,
        isTrue,
        reason: 'roleOrgAdmin (en) should not be empty',
      );
      expect(en.roleSuperadmin, isA<String>(), reason: 'roleSuperadmin (en)');
      expect(
        en.roleSuperadmin.isNotEmpty,
        isTrue,
        reason: 'roleSuperadmin (en) should not be empty',
      );
      expect(en.offline, isA<String>(), reason: 'offline (en)');
      expect(
        en.offline.isNotEmpty,
        isTrue,
        reason: 'offline (en) should not be empty',
      );
      expect(en.actionReadNfc, isA<String>(), reason: 'actionReadNfc (en)');
      expect(
        en.actionReadNfc.isNotEmpty,
        isTrue,
        reason: 'actionReadNfc (en) should not be empty',
      );
      expect(
        en.actionReadNfcSub,
        isA<String>(),
        reason: 'actionReadNfcSub (en)',
      );
      expect(
        en.actionReadNfcSub.isNotEmpty,
        isTrue,
        reason: 'actionReadNfcSub (en) should not be empty',
      );
      expect(
        en.actionNewPatient,
        isA<String>(),
        reason: 'actionNewPatient (en)',
      );
      expect(
        en.actionNewPatient.isNotEmpty,
        isTrue,
        reason: 'actionNewPatient (en) should not be empty',
      );
      expect(
        en.actionNewPatientSub,
        isA<String>(),
        reason: 'actionNewPatientSub (en)',
      );
      expect(
        en.actionNewPatientSub.isNotEmpty,
        isTrue,
        reason: 'actionNewPatientSub (en) should not be empty',
      );
      expect(
        en.actionSearchPatient,
        isA<String>(),
        reason: 'actionSearchPatient (en)',
      );
      expect(
        en.actionSearchPatient.isNotEmpty,
        isTrue,
        reason: 'actionSearchPatient (en) should not be empty',
      );
      expect(
        en.actionSearchPatientSub,
        isA<String>(),
        reason: 'actionSearchPatientSub (en)',
      );
      expect(
        en.actionSearchPatientSub.isNotEmpty,
        isTrue,
        reason: 'actionSearchPatientSub (en) should not be empty',
      );
      expect(
        en.actionSearchPatientSubAdmin,
        isA<String>(),
        reason: 'actionSearchPatientSubAdmin (en)',
      );
      expect(
        en.actionSearchPatientSubAdmin.isNotEmpty,
        isTrue,
        reason: 'actionSearchPatientSubAdmin (en) should not be empty',
      );
      expect(
        en.actionPendingSync,
        isA<String>(),
        reason: 'actionPendingSync (en)',
      );
      expect(
        en.actionPendingSync.isNotEmpty,
        isTrue,
        reason: 'actionPendingSync (en) should not be empty',
      );
      expect(
        en.actionPendingSyncEmpty,
        isA<String>(),
        reason: 'actionPendingSyncEmpty (en)',
      );
      expect(
        en.actionPendingSyncEmpty.isNotEmpty,
        isTrue,
        reason: 'actionPendingSyncEmpty (en) should not be empty',
      );
      expect(en.kpiUsers, isA<String>(), reason: 'kpiUsers (en)');
      expect(
        en.kpiUsers.isNotEmpty,
        isTrue,
        reason: 'kpiUsers (en) should not be empty',
      );
      expect(en.kpiSyncedOk, isA<String>(), reason: 'kpiSyncedOk (en)');
      expect(
        en.kpiSyncedOk.isNotEmpty,
        isTrue,
        reason: 'kpiSyncedOk (en) should not be empty',
      );
      expect(
        en.adminManageUsers,
        isA<String>(),
        reason: 'adminManageUsers (en)',
      );
      expect(
        en.adminManageUsers.isNotEmpty,
        isTrue,
        reason: 'adminManageUsers (en) should not be empty',
      );
      expect(
        en.adminManageUsersSub,
        isA<String>(),
        reason: 'adminManageUsersSub (en)',
      );
      expect(
        en.adminManageUsersSub.isNotEmpty,
        isTrue,
        reason: 'adminManageUsersSub (en) should not be empty',
      );
      expect(
        en.adminViewPatients,
        isA<String>(),
        reason: 'adminViewPatients (en)',
      );
      expect(
        en.adminViewPatients.isNotEmpty,
        isTrue,
        reason: 'adminViewPatients (en) should not be empty',
      );
      expect(
        en.adminViewPatientsSub,
        isA<String>(),
        reason: 'adminViewPatientsSub (en)',
      );
      expect(
        en.adminViewPatientsSub.isNotEmpty,
        isTrue,
        reason: 'adminViewPatientsSub (en) should not be empty',
      );
      expect(
        en.readWristbandTitle,
        isA<String>(),
        reason: 'readWristbandTitle (en)',
      );
      expect(
        en.readWristbandTitle.isNotEmpty,
        isTrue,
        reason: 'readWristbandTitle (en) should not be empty',
      );
      expect(
        en.scanGuardianTitle,
        isA<String>(),
        reason: 'scanGuardianTitle (en)',
      );
      expect(
        en.scanGuardianTitle.isNotEmpty,
        isTrue,
        reason: 'scanGuardianTitle (en) should not be empty',
      );
      expect(
        en.scanPatientHeadline,
        isA<String>(),
        reason: 'scanPatientHeadline (en)',
      );
      expect(
        en.scanPatientHeadline.isNotEmpty,
        isTrue,
        reason: 'scanPatientHeadline (en) should not be empty',
      );
      expect(en.scanPatientHint, isA<String>(), reason: 'scanPatientHint (en)');
      expect(
        en.scanPatientHint.isNotEmpty,
        isTrue,
        reason: 'scanPatientHint (en) should not be empty',
      );
      expect(
        en.scanGuardianHeadline,
        isA<String>(),
        reason: 'scanGuardianHeadline (en)',
      );
      expect(
        en.scanGuardianHeadline.isNotEmpty,
        isTrue,
        reason: 'scanGuardianHeadline (en) should not be empty',
      );
      expect(
        en.patientWristbandReady,
        isA<String>(),
        reason: 'patientWristbandReady (en)',
      );
      expect(
        en.patientWristbandReady.isNotEmpty,
        isTrue,
        reason: 'patientWristbandReady (en) should not be empty',
      );
      expect(
        en.nfcNotAvailableHint,
        isA<String>(),
        reason: 'nfcNotAvailableHint (en)',
      );
      expect(
        en.nfcNotAvailableHint.isNotEmpty,
        isTrue,
        reason: 'nfcNotAvailableHint (en) should not be empty',
      );
      expect(
        en.manualPatientUidLabel,
        isA<String>(),
        reason: 'manualPatientUidLabel (en)',
      );
      expect(
        en.manualPatientUidLabel.isNotEmpty,
        isTrue,
        reason: 'manualPatientUidLabel (en) should not be empty',
      );
      expect(
        en.manualPatientUidHint,
        isA<String>(),
        reason: 'manualPatientUidHint (en)',
      );
      expect(
        en.manualPatientUidHint.isNotEmpty,
        isTrue,
        reason: 'manualPatientUidHint (en) should not be empty',
      );
      expect(
        en.manualGuardianUidLabel,
        isA<String>(),
        reason: 'manualGuardianUidLabel (en)',
      );
      expect(
        en.manualGuardianUidLabel.isNotEmpty,
        isTrue,
        reason: 'manualGuardianUidLabel (en) should not be empty',
      );
      expect(
        en.manualGuardianUidHint,
        isA<String>(),
        reason: 'manualGuardianUidHint (en)',
      );
      expect(
        en.manualGuardianUidHint.isNotEmpty,
        isTrue,
        reason: 'manualGuardianUidHint (en) should not be empty',
      );
      expect(en.useManualUid, isA<String>(), reason: 'useManualUid (en)');
      expect(
        en.useManualUid.isNotEmpty,
        isTrue,
        reason: 'useManualUid (en) should not be empty',
      );
      expect(
        en.searchPatientTitle,
        isA<String>(),
        reason: 'searchPatientTitle (en)',
      );
      expect(
        en.searchPatientTitle.isNotEmpty,
        isTrue,
        reason: 'searchPatientTitle (en) should not be empty',
      );
      expect(en.searchSubtitle, isA<String>(), reason: 'searchSubtitle (en)');
      expect(
        en.searchSubtitle.isNotEmpty,
        isTrue,
        reason: 'searchSubtitle (en) should not be empty',
      );
      expect(
        en.searchPrivacyNotice,
        isA<String>(),
        reason: 'searchPrivacyNotice (en)',
      );
      expect(
        en.searchPrivacyNotice.isNotEmpty,
        isTrue,
        reason: 'searchPrivacyNotice (en) should not be empty',
      );
      expect(
        en.documentTypeLabel,
        isA<String>(),
        reason: 'documentTypeLabel (en)',
      );
      expect(
        en.documentTypeLabel.isNotEmpty,
        isTrue,
        reason: 'documentTypeLabel (en) should not be empty',
      );
      expect(
        en.documentNumberLabel,
        isA<String>(),
        reason: 'documentNumberLabel (en)',
      );
      expect(
        en.documentNumberLabel.isNotEmpty,
        isTrue,
        reason: 'documentNumberLabel (en) should not be empty',
      );
      expect(en.firstNameLabel, isA<String>(), reason: 'firstNameLabel (en)');
      expect(
        en.firstNameLabel.isNotEmpty,
        isTrue,
        reason: 'firstNameLabel (en) should not be empty',
      );
      expect(en.lastNameLabel, isA<String>(), reason: 'lastNameLabel (en)');
      expect(
        en.lastNameLabel.isNotEmpty,
        isTrue,
        reason: 'lastNameLabel (en) should not be empty',
      );
      expect(
        en.firstOrSecondLastName,
        isA<String>(),
        reason: 'firstOrSecondLastName (en)',
      );
      expect(
        en.firstOrSecondLastName.isNotEmpty,
        isTrue,
        reason: 'firstOrSecondLastName (en) should not be empty',
      );
      expect(en.dobLabel, isA<String>(), reason: 'dobLabel (en)');
      expect(
        en.dobLabel.isNotEmpty,
        isTrue,
        reason: 'dobLabel (en) should not be empty',
      );
      expect(
        en.guardianNameOptionalLabel,
        isA<String>(),
        reason: 'guardianNameOptionalLabel (en)',
      );
      expect(
        en.guardianNameOptionalLabel.isNotEmpty,
        isTrue,
        reason: 'guardianNameOptionalLabel (en) should not be empty',
      );
      expect(en.guardianHelper, isA<String>(), reason: 'guardianHelper (en)');
      expect(
        en.guardianHelper.isNotEmpty,
        isTrue,
        reason: 'guardianHelper (en) should not be empty',
      );
      expect(en.minThreeChars, isA<String>(), reason: 'minThreeChars (en)');
      expect(
        en.minThreeChars.isNotEmpty,
        isTrue,
        reason: 'minThreeChars (en) should not be empty',
      );
      expect(
        en.searchPatientButton,
        isA<String>(),
        reason: 'searchPatientButton (en)',
      );
      expect(
        en.searchPatientButton.isNotEmpty,
        isTrue,
        reason: 'searchPatientButton (en) should not be empty',
      );
      expect(
        en.searchFooterNote,
        isA<String>(),
        reason: 'searchFooterNote (en)',
      );
      expect(
        en.searchFooterNote.isNotEmpty,
        isTrue,
        reason: 'searchFooterNote (en) should not be empty',
      );
      expect(en.searchNoMatch, isA<String>(), reason: 'searchNoMatch (en)');
      expect(
        en.searchNoMatch.isNotEmpty,
        isTrue,
        reason: 'searchNoMatch (en) should not be empty',
      );

      // ── Patient profile screen ──
      expect(en.unsyncedChanges, isA<String>(), reason: 'unsyncedChanges (en)');
      expect(
        en.unsyncedChanges.isNotEmpty,
        isTrue,
        reason: 'unsyncedChanges (en) should not be empty',
      );
      expect(en.synced, isA<String>(), reason: 'synced (en)');
      expect(
        en.synced.isNotEmpty,
        isTrue,
        reason: 'synced (en) should not be empty',
      );
      expect(en.syncedAt, isA<String>(), reason: 'syncedAt (en)');
      expect(
        en.syncedAt.isNotEmpty,
        isTrue,
        reason: 'syncedAt (en) should not be empty',
      );
      expect(en.syncingBtn, isA<String>(), reason: 'syncingBtn (en)');
      expect(
        en.syncingBtn.isNotEmpty,
        isTrue,
        reason: 'syncingBtn (en) should not be empty',
      );
      expect(en.syncBtn, isA<String>(), reason: 'syncBtn (en)');
      expect(
        en.syncBtn.isNotEmpty,
        isTrue,
        reason: 'syncBtn (en) should not be empty',
      );
      expect(en.savedChangesMsg, isA<String>(), reason: 'savedChangesMsg (en)');
      expect(
        en.savedChangesMsg.isNotEmpty,
        isTrue,
        reason: 'savedChangesMsg (en) should not be empty',
      );
      expect(
        en.notAuthorizedConsultations,
        isA<String>(),
        reason: 'notAuthorizedConsultations (en)',
      );
      expect(
        en.notAuthorizedConsultations.isNotEmpty,
        isTrue,
        reason: 'notAuthorizedConsultations (en) should not be empty',
      );
      expect(
        en.unsyncedChangesTitle,
        isA<String>(),
        reason: 'unsyncedChangesTitle (en)',
      );
      expect(
        en.unsyncedChangesTitle.isNotEmpty,
        isTrue,
        reason: 'unsyncedChangesTitle (en) should not be empty',
      );
      expect(
        en.exitWithoutSyncMsg,
        isA<String>(),
        reason: 'exitWithoutSyncMsg (en)',
      );
      expect(
        en.exitWithoutSyncMsg.isNotEmpty,
        isTrue,
        reason: 'exitWithoutSyncMsg (en) should not be empty',
      );
      expect(en.exit, isA<String>(), reason: 'exit (en)');
      expect(
        en.exit.isNotEmpty,
        isTrue,
        reason: 'exit (en) should not be empty',
      );
      expect(en.tabSummary, isA<String>(), reason: 'tabSummary (en)');
      expect(
        en.tabSummary.isNotEmpty,
        isTrue,
        reason: 'tabSummary (en) should not be empty',
      );
      expect(en.yearsOldSuffix, isA<String>(), reason: 'yearsOldSuffix (en)');
      expect(
        en.yearsOldSuffix.isNotEmpty,
        isTrue,
        reason: 'yearsOldSuffix (en) should not be empty',
      );
      expect(
        en.noAllergiesRegistered,
        isA<String>(),
        reason: 'noAllergiesRegistered (en)',
      );
      expect(
        en.noAllergiesRegistered.isNotEmpty,
        isTrue,
        reason: 'noAllergiesRegistered (en) should not be empty',
      );
      expect(en.addAllergyBtn, isA<String>(), reason: 'addAllergyBtn (en)');
      expect(
        en.addAllergyBtn.isNotEmpty,
        isTrue,
        reason: 'addAllergyBtn (en) should not be empty',
      );
      expect(
        en.allergyCategoryLabel,
        isA<String>(),
        reason: 'allergyCategoryLabel (en)',
      );
      expect(
        en.allergyCategoryLabel.isNotEmpty,
        isTrue,
        reason: 'allergyCategoryLabel (en) should not be empty',
      );
      expect(en.allergenLabel, isA<String>(), reason: 'allergenLabel (en)');
      expect(
        en.allergenLabel.isNotEmpty,
        isTrue,
        reason: 'allergenLabel (en) should not be empty',
      );
      expect(en.allergenHint, isA<String>(), reason: 'allergenHint (en)');
      expect(
        en.allergenHint.isNotEmpty,
        isTrue,
        reason: 'allergenHint (en) should not be empty',
      );
      expect(
        en.reactionOptionalLabel,
        isA<String>(),
        reason: 'reactionOptionalLabel (en)',
      );
      expect(
        en.reactionOptionalLabel.isNotEmpty,
        isTrue,
        reason: 'reactionOptionalLabel (en) should not be empty',
      );
      expect(en.reactionHint, isA<String>(), reason: 'reactionHint (en)');
      expect(
        en.reactionHint.isNotEmpty,
        isTrue,
        reason: 'reactionHint (en) should not be empty',
      );
      expect(
        en.allergiesSheetTitle,
        isA<String>(),
        reason: 'allergiesSheetTitle (en)',
      );
      expect(
        en.allergiesSheetTitle.isNotEmpty,
        isTrue,
        reason: 'allergiesSheetTitle (en) should not be empty',
      );
      expect(
        en.backgroundSheetTitle,
        isA<String>(),
        reason: 'backgroundSheetTitle (en)',
      );
      expect(
        en.backgroundSheetTitle.isNotEmpty,
        isTrue,
        reason: 'backgroundSheetTitle (en) should not be empty',
      );
      expect(
        en.noChronicConditions,
        isA<String>(),
        reason: 'noChronicConditions (en)',
      );
      expect(
        en.noChronicConditions.isNotEmpty,
        isTrue,
        reason: 'noChronicConditions (en) should not be empty',
      );
      expect(
        en.addChronicConditionTitle,
        isA<String>(),
        reason: 'addChronicConditionTitle (en)',
      );
      expect(
        en.addChronicConditionTitle.isNotEmpty,
        isTrue,
        reason: 'addChronicConditionTitle (en) should not be empty',
      );
      expect(
        en.chronicConditionHint,
        isA<String>(),
        reason: 'chronicConditionHint (en)',
      );
      expect(
        en.chronicConditionHint.isNotEmpty,
        isTrue,
        reason: 'chronicConditionHint (en) should not be empty',
      );
      expect(en.noMedications, isA<String>(), reason: 'noMedications (en)');
      expect(
        en.noMedications.isNotEmpty,
        isTrue,
        reason: 'noMedications (en) should not be empty',
      );
      expect(en.medications, isA<String>(), reason: 'medications (en)');
      expect(
        en.medications.isNotEmpty,
        isTrue,
        reason: 'medications (en) should not be empty',
      );
      expect(
        en.personalHistoryTitle,
        isA<String>(),
        reason: 'personalHistoryTitle (en)',
      );
      expect(
        en.personalHistoryTitle.isNotEmpty,
        isTrue,
        reason: 'personalHistoryTitle (en) should not be empty',
      );
      expect(
        en.noFamilyHistoryEntries,
        isA<String>(),
        reason: 'noFamilyHistoryEntries (en)',
      );
      expect(
        en.noFamilyHistoryEntries.isNotEmpty,
        isTrue,
        reason: 'noFamilyHistoryEntries (en) should not be empty',
      );
      expect(en.reactionLabel, isA<String>(), reason: 'reactionLabel (en)');
      expect(
        en.reactionLabel.isNotEmpty,
        isTrue,
        reason: 'reactionLabel (en) should not be empty',
      );
      expect(en.sexMale, isA<String>(), reason: 'sexMale (en)');
      expect(
        en.sexMale.isNotEmpty,
        isTrue,
        reason: 'sexMale (en) should not be empty',
      );
      expect(en.sexFemale, isA<String>(), reason: 'sexFemale (en)');
      expect(
        en.sexFemale.isNotEmpty,
        isTrue,
        reason: 'sexFemale (en) should not be empty',
      );
      expect(
        en.sexIndeterminate,
        isA<String>(),
        reason: 'sexIndeterminate (en)',
      );
      expect(
        en.sexIndeterminate.isNotEmpty,
        isTrue,
        reason: 'sexIndeterminate (en) should not be empty',
      );
      expect(en.docTypeRC, isA<String>(), reason: 'docTypeRC (en)');
      expect(
        en.docTypeRC.isNotEmpty,
        isTrue,
        reason: 'docTypeRC (en) should not be empty',
      );
      expect(en.docTypeTI, isA<String>(), reason: 'docTypeTI (en)');
      expect(
        en.docTypeTI.isNotEmpty,
        isTrue,
        reason: 'docTypeTI (en) should not be empty',
      );
      expect(en.docTypeCC, isA<String>(), reason: 'docTypeCC (en)');
      expect(
        en.docTypeCC.isNotEmpty,
        isTrue,
        reason: 'docTypeCC (en) should not be empty',
      );
      expect(en.docTypeCE, isA<String>(), reason: 'docTypeCE (en)');
      expect(
        en.docTypeCE.isNotEmpty,
        isTrue,
        reason: 'docTypeCE (en) should not be empty',
      );
      expect(en.docTypePA, isA<String>(), reason: 'docTypePA (en)');
      expect(
        en.docTypePA.isNotEmpty,
        isTrue,
        reason: 'docTypePA (en) should not be empty',
      );
      expect(en.docTypePE, isA<String>(), reason: 'docTypePE (en)');
      expect(
        en.docTypePE.isNotEmpty,
        isTrue,
        reason: 'docTypePE (en) should not be empty',
      );
      expect(en.docTypePT, isA<String>(), reason: 'docTypePT (en)');
      expect(
        en.docTypePT.isNotEmpty,
        isTrue,
        reason: 'docTypePT (en) should not be empty',
      );
      expect(en.docTypeMS, isA<String>(), reason: 'docTypeMS (en)');
      expect(
        en.docTypeMS.isNotEmpty,
        isTrue,
        reason: 'docTypeMS (en) should not be empty',
      );
      expect(en.docTypeAS, isA<String>(), reason: 'docTypeAS (en)');
      expect(
        en.docTypeAS.isNotEmpty,
        isTrue,
        reason: 'docTypeAS (en) should not be empty',
      );
      expect(en.medStatusActive, isA<String>(), reason: 'medStatusActive (en)');
      expect(
        en.medStatusActive.isNotEmpty,
        isTrue,
        reason: 'medStatusActive (en) should not be empty',
      );
      expect(
        en.medStatusCompleted,
        isA<String>(),
        reason: 'medStatusCompleted (en)',
      );
      expect(
        en.medStatusCompleted.isNotEmpty,
        isTrue,
        reason: 'medStatusCompleted (en) should not be empty',
      );
      expect(
        en.medStatusStopped,
        isA<String>(),
        reason: 'medStatusStopped (en)',
      );
      expect(
        en.medStatusStopped.isNotEmpty,
        isTrue,
        reason: 'medStatusStopped (en) should not be empty',
      );
      expect(
        en.medStatusUnknown,
        isA<String>(),
        reason: 'medStatusUnknown (en)',
      );
      expect(
        en.medStatusUnknown.isNotEmpty,
        isTrue,
        reason: 'medStatusUnknown (en) should not be empty',
      );
      expect(en.cie10Label, isA<String>(), reason: 'cie10Label (en)');
      expect(
        en.cie10Label.isNotEmpty,
        isTrue,
        reason: 'cie10Label (en) should not be empty',
      );

      // ── Add medication sheet ──
      expect(
        en.addMedicationTitle,
        isA<String>(),
        reason: 'addMedicationTitle (en)',
      );
      expect(
        en.addMedicationTitle.isNotEmpty,
        isTrue,
        reason: 'addMedicationTitle (en) should not be empty',
      );
      expect(
        en.addMedicationSubtitle,
        isA<String>(),
        reason: 'addMedicationSubtitle (en)',
      );
      expect(
        en.addMedicationSubtitle.isNotEmpty,
        isTrue,
        reason: 'addMedicationSubtitle (en) should not be empty',
      );
      expect(en.medicationLabel, isA<String>(), reason: 'medicationLabel (en)');
      expect(
        en.medicationLabel.isNotEmpty,
        isTrue,
        reason: 'medicationLabel (en) should not be empty',
      );
      expect(en.medicationHint, isA<String>(), reason: 'medicationHint (en)');
      expect(
        en.medicationHint.isNotEmpty,
        isTrue,
        reason: 'medicationHint (en) should not be empty',
      );
      expect(en.statusLabel, isA<String>(), reason: 'statusLabel (en)');
      expect(
        en.statusLabel.isNotEmpty,
        isTrue,
        reason: 'statusLabel (en) should not be empty',
      );
      expect(en.dosageLabel, isA<String>(), reason: 'dosageLabel (en)');
      expect(
        en.dosageLabel.isNotEmpty,
        isTrue,
        reason: 'dosageLabel (en) should not be empty',
      );
      expect(en.dosageHint, isA<String>(), reason: 'dosageHint (en)');
      expect(
        en.dosageHint.isNotEmpty,
        isTrue,
        reason: 'dosageHint (en) should not be empty',
      );
      expect(en.notesLabel, isA<String>(), reason: 'notesLabel (en)');
      expect(
        en.notesLabel.isNotEmpty,
        isTrue,
        reason: 'notesLabel (en) should not be empty',
      );
      expect(en.notesHint, isA<String>(), reason: 'notesHint (en)');
      expect(
        en.notesHint.isNotEmpty,
        isTrue,
        reason: 'notesHint (en) should not be empty',
      );

      // ── Edit chronic / personal sheet ──
      expect(
        en.editChronicPersonalHint,
        isA<String>(),
        reason: 'editChronicPersonalHint (en)',
      );
      expect(
        en.editChronicPersonalHint.isNotEmpty,
        isTrue,
        reason: 'editChronicPersonalHint (en) should not be empty',
      );

      // ── Allergies tab ──
      expect(en.reactionHeader, isA<String>(), reason: 'reactionHeader (en)');
      expect(
        en.reactionHeader.isNotEmpty,
        isTrue,
        reason: 'reactionHeader (en) should not be empty',
      );
      expect(
        en.allergyShortMedication,
        isA<String>(),
        reason: 'allergyShortMedication (en)',
      );
      expect(
        en.allergyShortMedication.isNotEmpty,
        isTrue,
        reason: 'allergyShortMedication (en) should not be empty',
      );
      expect(
        en.allergyShortFood,
        isA<String>(),
        reason: 'allergyShortFood (en)',
      );
      expect(
        en.allergyShortFood.isNotEmpty,
        isTrue,
        reason: 'allergyShortFood (en) should not be empty',
      );
      expect(
        en.allergyShortEnvironment,
        isA<String>(),
        reason: 'allergyShortEnvironment (en)',
      );
      expect(
        en.allergyShortEnvironment.isNotEmpty,
        isTrue,
        reason: 'allergyShortEnvironment (en) should not be empty',
      );
      expect(
        en.allergyShortSkin,
        isA<String>(),
        reason: 'allergyShortSkin (en)',
      );
      expect(
        en.allergyShortSkin.isNotEmpty,
        isTrue,
        reason: 'allergyShortSkin (en) should not be empty',
      );
      expect(
        en.allergyShortInsect,
        isA<String>(),
        reason: 'allergyShortInsect (en)',
      );
      expect(
        en.allergyShortInsect.isNotEmpty,
        isTrue,
        reason: 'allergyShortInsect (en) should not be empty',
      );
      expect(
        en.allergyShortOther,
        isA<String>(),
        reason: 'allergyShortOther (en)',
      );
      expect(
        en.allergyShortOther.isNotEmpty,
        isTrue,
        reason: 'allergyShortOther (en) should not be empty',
      );

      // ── Summary tab ──
      expect(en.personalTitle, isA<String>(), reason: 'personalTitle (en)');
      expect(
        en.personalTitle.isNotEmpty,
        isTrue,
        reason: 'personalTitle (en) should not be empty',
      );
      expect(en.chronic, isA<String>(), reason: 'chronic (en)');
      expect(
        en.chronic.isNotEmpty,
        isTrue,
        reason: 'chronic (en) should not be empty',
      );
      expect(en.family, isA<String>(), reason: 'family (en)');
      expect(
        en.family.isNotEmpty,
        isTrue,
        reason: 'family (en) should not be empty',
      );
      expect(en.recordsLabel, isA<String>(), reason: 'recordsLabel (en)');
      expect(
        en.recordsLabel.isNotEmpty,
        isTrue,
        reason: 'recordsLabel (en) should not be empty',
      );

      // ── Consultations View & Detail ──
      expect(
        en.consultationsTabTitle,
        isA<String>(),
        reason: 'consultationsTabTitle (en)',
      );
      expect(
        en.consultationsTabTitle.isNotEmpty,
        isTrue,
        reason: 'consultationsTabTitle (en) should not be empty',
      );
      expect(
        en.noConsultationsRegistered,
        isA<String>(),
        reason: 'noConsultationsRegistered (en)',
      );
      expect(
        en.noConsultationsRegistered.isNotEmpty,
        isTrue,
        reason: 'noConsultationsRegistered (en) should not be empty',
      );
      expect(
        en.addConsultationButton,
        isA<String>(),
        reason: 'addConsultationButton (en)',
      );
      expect(
        en.addConsultationButton.isNotEmpty,
        isTrue,
        reason: 'addConsultationButton (en) should not be empty',
      );
      expect(en.viewDetailHint, isA<String>(), reason: 'viewDetailHint (en)');
      expect(
        en.viewDetailHint.isNotEmpty,
        isTrue,
        reason: 'viewDetailHint (en) should not be empty',
      );
      expect(
        en.consultationDetailTitle,
        isA<String>(),
        reason: 'consultationDetailTitle (en)',
      );
      expect(
        en.consultationDetailTitle.isNotEmpty,
        isTrue,
        reason: 'consultationDetailTitle (en) should not be empty',
      );
      expect(
        en.careContextSection,
        isA<String>(),
        reason: 'careContextSection (en)',
      );
      expect(
        en.careContextSection.isNotEmpty,
        isTrue,
        reason: 'careContextSection (en) should not be empty',
      );
      expect(en.startDateLabel, isA<String>(), reason: 'startDateLabel (en)');
      expect(
        en.startDateLabel.isNotEmpty,
        isTrue,
        reason: 'startDateLabel (en) should not be empty',
      );
      expect(en.endDateLabel, isA<String>(), reason: 'endDateLabel (en)');
      expect(
        en.endDateLabel.isNotEmpty,
        isTrue,
        reason: 'endDateLabel (en) should not be empty',
      );
      expect(
        en.serviceGroupLabel,
        isA<String>(),
        reason: 'serviceGroupLabel (en)',
      );
      expect(
        en.serviceGroupLabel.isNotEmpty,
        isTrue,
        reason: 'serviceGroupLabel (en) should not be empty',
      );
      expect(
        en.environmentLabel,
        isA<String>(),
        reason: 'environmentLabel (en)',
      );
      expect(
        en.environmentLabel.isNotEmpty,
        isTrue,
        reason: 'environmentLabel (en) should not be empty',
      );
      expect(en.entryRouteLabel, isA<String>(), reason: 'entryRouteLabel (en)');
      expect(
        en.entryRouteLabel.isNotEmpty,
        isTrue,
        reason: 'entryRouteLabel (en) should not be empty',
      );
      expect(
        en.externalCauseLabel,
        isA<String>(),
        reason: 'externalCauseLabel (en)',
      );
      expect(
        en.externalCauseLabel.isNotEmpty,
        isTrue,
        reason: 'externalCauseLabel (en) should not be empty',
      );
      expect(en.docLabelShort, isA<String>(), reason: 'docLabelShort (en)');
      expect(
        en.docLabelShort.isNotEmpty,
        isTrue,
        reason: 'docLabelShort (en) should not be empty',
      );
      expect(en.diagnosisTitle, isA<String>(), reason: 'diagnosisTitle (en)');
      expect(
        en.diagnosisTitle.isNotEmpty,
        isTrue,
        reason: 'diagnosisTitle (en) should not be empty',
      );
      expect(
        en.dischargeSection,
        isA<String>(),
        reason: 'dischargeSection (en)',
      );
      expect(
        en.dischargeSection.isNotEmpty,
        isTrue,
        reason: 'dischargeSection (en) should not be empty',
      );
      expect(
        en.riskFactorsSection,
        isA<String>(),
        reason: 'riskFactorsSection (en)',
      );
      expect(
        en.riskFactorsSection.isNotEmpty,
        isTrue,
        reason: 'riskFactorsSection (en) should not be empty',
      );
      expect(
        en.incapacitySection,
        isA<String>(),
        reason: 'incapacitySection (en)',
      );
      expect(
        en.incapacitySection.isNotEmpty,
        isTrue,
        reason: 'incapacitySection (en) should not be empty',
      );
      expect(en.incapacityScope, isA<String>(), reason: 'incapacityScope (en)');
      expect(
        en.incapacityScope.isNotEmpty,
        isTrue,
        reason: 'incapacityScope (en) should not be empty',
      );
      expect(en.incapacityDays, isA<String>(), reason: 'incapacityDays (en)');
      expect(
        en.incapacityDays.isNotEmpty,
        isTrue,
        reason: 'incapacityDays (en) should not be empty',
      );
      expect(en.payerSection, isA<String>(), reason: 'payerSection (en)');
      expect(
        en.payerSection.isNotEmpty,
        isTrue,
        reason: 'payerSection (en) should not be empty',
      );
      expect(en.codeLabel, isA<String>(), reason: 'codeLabel (en)');
      expect(
        en.codeLabel.isNotEmpty,
        isTrue,
        reason: 'codeLabel (en) should not be empty',
      );
      expect(en.dayLun, isA<String>(), reason: 'dayLun (en)');
      expect(
        en.dayLun.isNotEmpty,
        isTrue,
        reason: 'dayLun (en) should not be empty',
      );
      expect(en.dayMar, isA<String>(), reason: 'dayMar (en)');
      expect(
        en.dayMar.isNotEmpty,
        isTrue,
        reason: 'dayMar (en) should not be empty',
      );
      expect(en.dayMie, isA<String>(), reason: 'dayMie (en)');
      expect(
        en.dayMie.isNotEmpty,
        isTrue,
        reason: 'dayMie (en) should not be empty',
      );
      expect(en.dayJue, isA<String>(), reason: 'dayJue (en)');
      expect(
        en.dayJue.isNotEmpty,
        isTrue,
        reason: 'dayJue (en) should not be empty',
      );
      expect(en.dayVie, isA<String>(), reason: 'dayVie (en)');
      expect(
        en.dayVie.isNotEmpty,
        isTrue,
        reason: 'dayVie (en) should not be empty',
      );
      expect(en.daySab, isA<String>(), reason: 'daySab (en)');
      expect(
        en.daySab.isNotEmpty,
        isTrue,
        reason: 'daySab (en) should not be empty',
      );
      expect(en.dayDom, isA<String>(), reason: 'dayDom (en)');
      expect(
        en.dayDom.isNotEmpty,
        isTrue,
        reason: 'dayDom (en) should not be empty',
      );
      expect(en.monEne, isA<String>(), reason: 'monEne (en)');
      expect(
        en.monEne.isNotEmpty,
        isTrue,
        reason: 'monEne (en) should not be empty',
      );
      expect(en.monFeb, isA<String>(), reason: 'monFeb (en)');
      expect(
        en.monFeb.isNotEmpty,
        isTrue,
        reason: 'monFeb (en) should not be empty',
      );
      expect(en.monMarString, isA<String>(), reason: 'monMarString (en)');
      expect(
        en.monMarString.isNotEmpty,
        isTrue,
        reason: 'monMarString (en) should not be empty',
      );
      expect(en.monMar, isA<String>(), reason: 'monMar (en)');
      expect(
        en.monMar.isNotEmpty,
        isTrue,
        reason: 'monMar (en) should not be empty',
      );
      expect(en.monAbr, isA<String>(), reason: 'monAbr (en)');
      expect(
        en.monAbr.isNotEmpty,
        isTrue,
        reason: 'monAbr (en) should not be empty',
      );
      expect(en.monMay, isA<String>(), reason: 'monMay (en)');
      expect(
        en.monMay.isNotEmpty,
        isTrue,
        reason: 'monMay (en) should not be empty',
      );
      expect(en.monJun, isA<String>(), reason: 'monJun (en)');
      expect(
        en.monJun.isNotEmpty,
        isTrue,
        reason: 'monJun (en) should not be empty',
      );
      expect(en.monJul, isA<String>(), reason: 'monJul (en)');
      expect(
        en.monJul.isNotEmpty,
        isTrue,
        reason: 'monJul (en) should not be empty',
      );
      expect(en.monAgo, isA<String>(), reason: 'monAgo (en)');
      expect(
        en.monAgo.isNotEmpty,
        isTrue,
        reason: 'monAgo (en) should not be empty',
      );
      expect(en.monSep, isA<String>(), reason: 'monSep (en)');
      expect(
        en.monSep.isNotEmpty,
        isTrue,
        reason: 'monSep (en) should not be empty',
      );
      expect(en.monOct, isA<String>(), reason: 'monOct (en)');
      expect(
        en.monOct.isNotEmpty,
        isTrue,
        reason: 'monOct (en) should not be empty',
      );
      expect(en.monNov, isA<String>(), reason: 'monNov (en)');
      expect(
        en.monNov.isNotEmpty,
        isTrue,
        reason: 'monNov (en) should not be empty',
      );
      expect(en.monDic, isA<String>(), reason: 'monDic (en)');
      expect(
        en.monDic.isNotEmpty,
        isTrue,
        reason: 'monDic (en) should not be empty',
      );
      expect(en.timeAm, isA<String>(), reason: 'timeAm (en)');
      expect(
        en.timeAm.isNotEmpty,
        isTrue,
        reason: 'timeAm (en) should not be empty',
      );
      expect(en.timePm, isA<String>(), reason: 'timePm (en)');
      expect(
        en.timePm.isNotEmpty,
        isTrue,
        reason: 'timePm (en) should not be empty',
      );
      expect(en.modIntramural, isA<String>(), reason: 'modIntramural (en)');
      expect(
        en.modIntramural.isNotEmpty,
        isTrue,
        reason: 'modIntramural (en) should not be empty',
      );
      expect(
        en.modExtramuralMobil,
        isA<String>(),
        reason: 'modExtramuralMobil (en)',
      );
      expect(
        en.modExtramuralMobil.isNotEmpty,
        isTrue,
        reason: 'modExtramuralMobil (en) should not be empty',
      );
      expect(en.modDomiciliaria, isA<String>(), reason: 'modDomiciliaria (en)');
      expect(
        en.modDomiciliaria.isNotEmpty,
        isTrue,
        reason: 'modDomiciliaria (en) should not be empty',
      );
      expect(en.modJornada, isA<String>(), reason: 'modJornada (en)');
      expect(
        en.modJornada.isNotEmpty,
        isTrue,
        reason: 'modJornada (en) should not be empty',
      );
      expect(
        en.modPrehospitalaria,
        isA<String>(),
        reason: 'modPrehospitalaria (en)',
      );
      expect(
        en.modPrehospitalaria.isNotEmpty,
        isTrue,
        reason: 'modPrehospitalaria (en) should not be empty',
      );
      expect(
        en.modTelemedicinaInteractiva,
        isA<String>(),
        reason: 'modTelemedicinaInteractiva (en)',
      );
      expect(
        en.modTelemedicinaInteractiva.isNotEmpty,
        isTrue,
        reason: 'modTelemedicinaInteractiva (en) should not be empty',
      );
      expect(
        en.modNoInteractiva,
        isA<String>(),
        reason: 'modNoInteractiva (en)',
      );
      expect(
        en.modNoInteractiva.isNotEmpty,
        isTrue,
        reason: 'modNoInteractiva (en) should not be empty',
      );
      expect(
        en.modTelexperticia,
        isA<String>(),
        reason: 'modTelexperticia (en)',
      );
      expect(
        en.modTelexperticia.isNotEmpty,
        isTrue,
        reason: 'modTelexperticia (en) should not be empty',
      );
      expect(
        en.modTelemonitoreo,
        isA<String>(),
        reason: 'modTelemonitoreo (en)',
      );
      expect(
        en.modTelemonitoreo.isNotEmpty,
        isTrue,
        reason: 'modTelemonitoreo (en) should not be empty',
      );
      expect(
        en.sgConsultaExterna,
        isA<String>(),
        reason: 'sgConsultaExterna (en)',
      );
      expect(
        en.sgConsultaExterna.isNotEmpty,
        isTrue,
        reason: 'sgConsultaExterna (en) should not be empty',
      );
      expect(
        en.sgApoyoDiagnostico,
        isA<String>(),
        reason: 'sgApoyoDiagnostico (en)',
      );
      expect(
        en.sgApoyoDiagnostico.isNotEmpty,
        isTrue,
        reason: 'sgApoyoDiagnostico (en) should not be empty',
      );
      expect(en.sgInternacion, isA<String>(), reason: 'sgInternacion (en)');
      expect(
        en.sgInternacion.isNotEmpty,
        isTrue,
        reason: 'sgInternacion (en) should not be empty',
      );
      expect(en.sgQuirurgico, isA<String>(), reason: 'sgQuirurgico (en)');
      expect(
        en.sgQuirurgico.isNotEmpty,
        isTrue,
        reason: 'sgQuirurgico (en) should not be empty',
      );
      expect(
        en.sgAtencionInmediata,
        isA<String>(),
        reason: 'sgAtencionInmediata (en)',
      );
      expect(
        en.sgAtencionInmediata.isNotEmpty,
        isTrue,
        reason: 'sgAtencionInmediata (en) should not be empty',
      );
      expect(en.ceHogar, isA<String>(), reason: 'ceHogar (en)');
      expect(
        en.ceHogar.isNotEmpty,
        isTrue,
        reason: 'ceHogar (en) should not be empty',
      );
      expect(en.ceComunitario, isA<String>(), reason: 'ceComunitario (en)');
      expect(
        en.ceComunitario.isNotEmpty,
        isTrue,
        reason: 'ceComunitario (en) should not be empty',
      );
      expect(en.ceEscolar, isA<String>(), reason: 'ceEscolar (en)');
      expect(
        en.ceEscolar.isNotEmpty,
        isTrue,
        reason: 'ceEscolar (en) should not be empty',
      );
      expect(en.ceLaboral, isA<String>(), reason: 'ceLaboral (en)');
      expect(
        en.ceLaboral.isNotEmpty,
        isTrue,
        reason: 'ceLaboral (en) should not be empty',
      );
      expect(en.ceInstitucional, isA<String>(), reason: 'ceInstitucional (en)');
      expect(
        en.ceInstitucional.isNotEmpty,
        isTrue,
        reason: 'ceInstitucional (en) should not be empty',
      );
      expect(en.dtImpresion, isA<String>(), reason: 'dtImpresion (en)');
      expect(
        en.dtImpresion.isNotEmpty,
        isTrue,
        reason: 'dtImpresion (en) should not be empty',
      );
      expect(
        en.dtConfirmadoNuevo,
        isA<String>(),
        reason: 'dtConfirmadoNuevo (en)',
      );
      expect(
        en.dtConfirmadoNuevo.isNotEmpty,
        isTrue,
        reason: 'dtConfirmadoNuevo (en) should not be empty',
      );
      expect(
        en.dtConfirmadoRepetido,
        isA<String>(),
        reason: 'dtConfirmadoRepetido (en)',
      );
      expect(
        en.dtConfirmadoRepetido.isNotEmpty,
        isTrue,
        reason: 'dtConfirmadoRepetido (en) should not be empty',
      );
      expect(
        en.ddAltaVoluntaria,
        isA<String>(),
        reason: 'ddAltaVoluntaria (en)',
      );
      expect(
        en.ddAltaVoluntaria.isNotEmpty,
        isTrue,
        reason: 'ddAltaVoluntaria (en) should not be empty',
      );
      expect(en.ddFallecido, isA<String>(), reason: 'ddFallecido (en)');
      expect(
        en.ddFallecido.isNotEmpty,
        isTrue,
        reason: 'ddFallecido (en) should not be empty',
      );
      expect(en.ddRemitido, isA<String>(), reason: 'ddRemitido (en)');
      expect(
        en.ddRemitido.isNotEmpty,
        isTrue,
        reason: 'ddRemitido (en) should not be empty',
      );
      expect(en.ddAltaMedica, isA<String>(), reason: 'ddAltaMedica (en)');
      expect(
        en.ddAltaMedica.isNotEmpty,
        isTrue,
        reason: 'ddAltaMedica (en) should not be empty',
      );

      // ── Vaccines tab ──
      expect(
        en.vaccineSchemeTitle,
        isA<String>(),
        reason: 'vaccineSchemeTitle (en)',
      );
      expect(
        en.vaccineSchemeTitle.isNotEmpty,
        isTrue,
        reason: 'vaccineSchemeTitle (en) should not be empty',
      );
      expect(
        en.vaccineLabelSingle,
        isA<String>(),
        reason: 'vaccineLabelSingle (en)',
      );
      expect(
        en.vaccineLabelSingle.isNotEmpty,
        isTrue,
        reason: 'vaccineLabelSingle (en) should not be empty',
      );
      expect(
        en.vaccineLabelPlural,
        isA<String>(),
        reason: 'vaccineLabelPlural (en)',
      );
      expect(
        en.vaccineLabelPlural.isNotEmpty,
        isTrue,
        reason: 'vaccineLabelPlural (en) should not be empty',
      );
      expect(
        en.noVaccinesRegistered,
        isA<String>(),
        reason: 'noVaccinesRegistered (en)',
      );
      expect(
        en.noVaccinesRegistered.isNotEmpty,
        isTrue,
        reason: 'noVaccinesRegistered (en) should not be empty',
      );
      expect(
        en.addVaccineButton,
        isA<String>(),
        reason: 'addVaccineButton (en)',
      );
      expect(
        en.addVaccineButton.isNotEmpty,
        isTrue,
        reason: 'addVaccineButton (en) should not be empty',
      );
      expect(en.doseLabel, isA<String>(), reason: 'doseLabel (en)');
      expect(
        en.doseLabel.isNotEmpty,
        isTrue,
        reason: 'doseLabel (en) should not be empty',
      );

      // ── Admin Manage Users ──
      expect(
        en.manageUsersTitle,
        isA<String>(),
        reason: 'manageUsersTitle (en)',
      );
      expect(
        en.manageUsersTitle.isNotEmpty,
        isTrue,
        reason: 'manageUsersTitle (en) should not be empty',
      );
      expect(en.filterAll, isA<String>(), reason: 'filterAll (en)');
      expect(
        en.filterAll.isNotEmpty,
        isTrue,
        reason: 'filterAll (en) should not be empty',
      );
      expect(en.filterDoctors, isA<String>(), reason: 'filterDoctors (en)');
      expect(
        en.filterDoctors.isNotEmpty,
        isTrue,
        reason: 'filterDoctors (en) should not be empty',
      );
      expect(en.filterNurse, isA<String>(), reason: 'filterNurse (en)');
      expect(
        en.filterNurse.isNotEmpty,
        isTrue,
        reason: 'filterNurse (en) should not be empty',
      );
      expect(en.filterCoord, isA<String>(), reason: 'filterCoord (en)');
      expect(
        en.filterCoord.isNotEmpty,
        isTrue,
        reason: 'filterCoord (en) should not be empty',
      );
      expect(en.noUsersInFilter, isA<String>(), reason: 'noUsersInFilter (en)');
      expect(
        en.noUsersInFilter.isNotEmpty,
        isTrue,
        reason: 'noUsersInFilter (en) should not be empty',
      );
      expect(en.createUserTitle, isA<String>(), reason: 'createUserTitle (en)');
      expect(
        en.createUserTitle.isNotEmpty,
        isTrue,
        reason: 'createUserTitle (en) should not be empty',
      );
      expect(
        en.userStatusActive,
        isA<String>(),
        reason: 'userStatusActive (en)',
      );
      expect(
        en.userStatusActive.isNotEmpty,
        isTrue,
        reason: 'userStatusActive (en) should not be empty',
      );
      expect(
        en.userStatusSuspended,
        isA<String>(),
        reason: 'userStatusSuspended (en)',
      );
      expect(
        en.userStatusSuspended.isNotEmpty,
        isTrue,
        reason: 'userStatusSuspended (en) should not be empty',
      );
      expect(
        en.userDetailOrganization,
        isA<String>(),
        reason: 'userDetailOrganization (en)',
      );
      expect(
        en.userDetailOrganization.isNotEmpty,
        isTrue,
        reason: 'userDetailOrganization (en) should not be empty',
      );
      expect(
        en.userDetailStatus,
        isA<String>(),
        reason: 'userDetailStatus (en)',
      );
      expect(
        en.userDetailStatus.isNotEmpty,
        isTrue,
        reason: 'userDetailStatus (en) should not be empty',
      );
      expect(
        en.userFormFullNameLabel,
        isA<String>(),
        reason: 'userFormFullNameLabel (en)',
      );
      expect(
        en.userFormFullNameLabel.isNotEmpty,
        isTrue,
        reason: 'userFormFullNameLabel (en) should not be empty',
      );
      expect(
        en.userFormEmailLabel,
        isA<String>(),
        reason: 'userFormEmailLabel (en)',
      );
      expect(
        en.userFormEmailLabel.isNotEmpty,
        isTrue,
        reason: 'userFormEmailLabel (en) should not be empty',
      );
      expect(
        en.userFormPasswordLabel,
        isA<String>(),
        reason: 'userFormPasswordLabel (en)',
      );
      expect(
        en.userFormPasswordLabel.isNotEmpty,
        isTrue,
        reason: 'userFormPasswordLabel (en) should not be empty',
      );
      expect(
        en.userFormRoleLabel,
        isA<String>(),
        reason: 'userFormRoleLabel (en)',
      );
      expect(
        en.userFormRoleLabel.isNotEmpty,
        isTrue,
        reason: 'userFormRoleLabel (en) should not be empty',
      );
      expect(
        en.userFormRequiredFieldsError,
        isA<String>(),
        reason: 'userFormRequiredFieldsError (en)',
      );
      expect(
        en.userFormRequiredFieldsError.isNotEmpty,
        isTrue,
        reason: 'userFormRequiredFieldsError (en) should not be empty',
      );
      expect(
        en.userFormCreatingStatus,
        isA<String>(),
        reason: 'userFormCreatingStatus (en)',
      );
      expect(
        en.userFormCreatingStatus.isNotEmpty,
        isTrue,
        reason: 'userFormCreatingStatus (en) should not be empty',
      );
      expect(
        en.userFormCreateButton,
        isA<String>(),
        reason: 'userFormCreateButton (en)',
      );
      expect(
        en.userFormCreateButton.isNotEmpty,
        isTrue,
        reason: 'userFormCreateButton (en) should not be empty',
      );
      expect(en.deletUser, isA<String>(), reason: 'deletUser (en)');
      expect(
        en.deletUser.isNotEmpty,
        isTrue,
        reason: 'deletUser (en) should not be empty',
      );
      expect(en.deleting, isA<String>(), reason: 'deleting (en)');
      expect(
        en.deleting.isNotEmpty,
        isTrue,
        reason: 'deleting (en) should not be empty',
      );
      expect(
        en.permanentlyDelete,
        isA<String>(),
        reason: 'permanentlyDelete (en)',
      );
      expect(
        en.permanentlyDelete.isNotEmpty,
        isTrue,
        reason: 'permanentlyDelete (en) should not be empty',
      );
      expect(
        en.userFormValidationError,
        isA<String>(),
        reason: 'userFormValidationError (en)',
      );
      expect(
        en.userFormValidationError.isNotEmpty,
        isTrue,
        reason: 'userFormValidationError (en) should not be empty',
      );

      // ── Super Admin User ──────────────────────────────────────────────────
      expect(en.manageOrgsTitle, isA<String>(), reason: 'manageOrgsTitle (en)');
      expect(
        en.manageOrgsTitle.isNotEmpty,
        isTrue,
        reason: 'manageOrgsTitle (en) should not be empty',
      );
      expect(
        en.manageOrgsSubtitle,
        isA<String>(),
        reason: 'manageOrgsSubtitle (en)',
      );
      expect(
        en.manageOrgsSubtitle.isNotEmpty,
        isTrue,
        reason: 'manageOrgsSubtitle (en) should not be empty',
      );
      expect(
        en.brigadeStatsTitle,
        isA<String>(),
        reason: 'brigadeStatsTitle (en)',
      );
      expect(
        en.brigadeStatsTitle.isNotEmpty,
        isTrue,
        reason: 'brigadeStatsTitle (en) should not be empty',
      );
      expect(
        en.brigadeStatsSubtitle,
        isA<String>(),
        reason: 'brigadeStatsSubtitle (en)',
      );
      expect(
        en.brigadeStatsSubtitle.isNotEmpty,
        isTrue,
        reason: 'brigadeStatsSubtitle (en) should not be empty',
      );
      expect(
        en.statsScreenTitle,
        isA<String>(),
        reason: 'statsScreenTitle (en)',
      );
      expect(
        en.statsScreenTitle.isNotEmpty,
        isTrue,
        reason: 'statsScreenTitle (en) should not be empty',
      );
      expect(
        en.statsTotalPatients,
        isA<String>(),
        reason: 'statsTotalPatients (en)',
      );
      expect(
        en.statsTotalPatients.isNotEmpty,
        isTrue,
        reason: 'statsTotalPatients (en) should not be empty',
      );
      expect(
        en.statsTotalVaccines,
        isA<String>(),
        reason: 'statsTotalVaccines (en)',
      );
      expect(
        en.statsTotalVaccines.isNotEmpty,
        isTrue,
        reason: 'statsTotalVaccines (en) should not be empty',
      );
      expect(
        en.statsTotalAllergies,
        isA<String>(),
        reason: 'statsTotalAllergies (en)',
      );
      expect(
        en.statsTotalAllergies.isNotEmpty,
        isTrue,
        reason: 'statsTotalAllergies (en) should not be empty',
      );
      expect(
        en.statsMinorsPercentage,
        isA<String>(),
        reason: 'statsMinorsPercentage (en)',
      );
      expect(
        en.statsMinorsPercentage.isNotEmpty,
        isTrue,
        reason: 'statsMinorsPercentage (en) should not be empty',
      );
      expect(
        en.statsVaccineDistribution,
        isA<String>(),
        reason: 'statsVaccineDistribution (en)',
      );
      expect(
        en.statsVaccineDistribution.isNotEmpty,
        isTrue,
        reason: 'statsVaccineDistribution (en) should not be empty',
      );
      expect(
        en.statsAllergyDistribution,
        isA<String>(),
        reason: 'statsAllergyDistribution (en)',
      );
      expect(
        en.statsAllergyDistribution.isNotEmpty,
        isTrue,
        reason: 'statsAllergyDistribution (en) should not be empty',
      );
      expect(
        en.manageOrgsScreenTitle,
        isA<String>(),
        reason: 'manageOrgsScreenTitle (en)',
      );
      expect(
        en.manageOrgsScreenTitle.isNotEmpty,
        isTrue,
        reason: 'manageOrgsScreenTitle (en) should not be empty',
      );
      expect(
        en.orgsNoOrganizations,
        isA<String>(),
        reason: 'orgsNoOrganizations (en)',
      );
      expect(
        en.orgsNoOrganizations.isNotEmpty,
        isTrue,
        reason: 'orgsNoOrganizations (en) should not be empty',
      );
      expect(
        en.orgsCreateOrgTitle,
        isA<String>(),
        reason: 'orgsCreateOrgTitle (en)',
      );
      expect(
        en.orgsCreateOrgTitle.isNotEmpty,
        isTrue,
        reason: 'orgsCreateOrgTitle (en) should not be empty',
      );
      expect(
        en.orgsStepBasicData,
        isA<String>(),
        reason: 'orgsStepBasicData (en)',
      );
      expect(
        en.orgsStepBasicData.isNotEmpty,
        isTrue,
        reason: 'orgsStepBasicData (en) should not be empty',
      );
      expect(
        en.orgsStepAdminUser,
        isA<String>(),
        reason: 'orgsStepAdminUser (en)',
      );
      expect(
        en.orgsStepAdminUser.isNotEmpty,
        isTrue,
        reason: 'orgsStepAdminUser (en) should not be empty',
      );
      expect(en.orgsStepSummary, isA<String>(), reason: 'orgsStepSummary (en)');
      expect(
        en.orgsStepSummary.isNotEmpty,
        isTrue,
        reason: 'orgsStepSummary (en) should not be empty',
      );
      expect(
        en.orgsFieldNameLabel,
        isA<String>(),
        reason: 'orgsFieldNameLabel (en)',
      );
      expect(
        en.orgsFieldNameLabel.isNotEmpty,
        isTrue,
        reason: 'orgsFieldNameLabel (en) should not be empty',
      );
      expect(
        en.orgsFieldEmailLabel,
        isA<String>(),
        reason: 'orgsFieldEmailLabel (en)',
      );
      expect(
        en.orgsFieldEmailLabel.isNotEmpty,
        isTrue,
        reason: 'orgsFieldEmailLabel (en) should not be empty',
      );
      expect(
        en.orgsFieldAdminNameLabel,
        isA<String>(),
        reason: 'orgsFieldAdminNameLabel (en)',
      );
      expect(
        en.orgsFieldAdminNameLabel.isNotEmpty,
        isTrue,
        reason: 'orgsFieldAdminNameLabel (en) should not be empty',
      );
      expect(
        en.orgsFieldAdminEmailLabel,
        isA<String>(),
        reason: 'orgsFieldAdminEmailLabel (en)',
      );
      expect(
        en.orgsFieldAdminEmailLabel.isNotEmpty,
        isTrue,
        reason: 'orgsFieldAdminEmailLabel (en) should not be empty',
      );
      expect(
        en.orgsFieldAdminPassLabel,
        isA<String>(),
        reason: 'orgsFieldAdminPassLabel (en)',
      );
      expect(
        en.orgsFieldAdminPassLabel.isNotEmpty,
        isTrue,
        reason: 'orgsFieldAdminPassLabel (en) should not be empty',
      );
      expect(
        en.orgsSummarySubtitle,
        isA<String>(),
        reason: 'orgsSummarySubtitle (en)',
      );
      expect(
        en.orgsSummarySubtitle.isNotEmpty,
        isTrue,
        reason: 'orgsSummarySubtitle (en) should not be empty',
      );
      expect(
        en.orgsLabelOrganization,
        isA<String>(),
        reason: 'orgsLabelOrganization (en)',
      );
      expect(
        en.orgsLabelOrganization.isNotEmpty,
        isTrue,
        reason: 'orgsLabelOrganization (en) should not be empty',
      );
      expect(
        en.orgsLabelOfficialEmail,
        isA<String>(),
        reason: 'orgsLabelOfficialEmail (en)',
      );
      expect(
        en.orgsLabelOfficialEmail.isNotEmpty,
        isTrue,
        reason: 'orgsLabelOfficialEmail (en) should not be empty',
      );
      expect(
        en.orgsLabelAdministrator,
        isA<String>(),
        reason: 'orgsLabelAdministrator (en)',
      );
      expect(
        en.orgsLabelAdministrator.isNotEmpty,
        isTrue,
        reason: 'orgsLabelAdministrator (en) should not be empty',
      );
      expect(
        en.orgsLabelAdminEmail,
        isA<String>(),
        reason: 'orgsLabelAdminEmail (en)',
      );
      expect(
        en.orgsLabelAdminEmail.isNotEmpty,
        isTrue,
        reason: 'orgsLabelAdminEmail (en) should not be empty',
      );
      expect(
        en.orgsLabelProvisionalPass,
        isA<String>(),
        reason: 'orgsLabelProvisionalPass (en)',
      );
      expect(
        en.orgsLabelProvisionalPass.isNotEmpty,
        isTrue,
        reason: 'orgsLabelProvisionalPass (en) should not be empty',
      );
      expect(en.step, isA<String>(), reason: 'step (en)');
      expect(
        en.step.isNotEmpty,
        isTrue,
        reason: 'step (en) should not be empty',
      );
      expect(en.labelNameAdmin, isA<String>(), reason: 'labelNameAdmin (en)');
      expect(
        en.labelNameAdmin.isNotEmpty,
        isTrue,
        reason: 'labelNameAdmin (en) should not be empty',
      );
      expect(en.orgDetailTitle, isA<String>(), reason: 'orgDetailTitle (en)');
      expect(
        en.orgDetailTitle.isNotEmpty,
        isTrue,
        reason: 'orgDetailTitle (en) should not be empty',
      );
      expect(en.orgDetailId, isA<String>(), reason: 'orgDetailId (en)');
      expect(
        en.orgDetailId.isNotEmpty,
        isTrue,
        reason: 'orgDetailId (en) should not be empty',
      );
      expect(en.orgDeleteButton, isA<String>(), reason: 'orgDeleteButton (en)');
      expect(
        en.orgDeleteButton.isNotEmpty,
        isTrue,
        reason: 'orgDeleteButton (en) should not be empty',
      );
      expect(
        en.orgDeleteDialogTitle,
        isA<String>(),
        reason: 'orgDeleteDialogTitle (en)',
      );
      expect(
        en.orgDeleteDialogTitle.isNotEmpty,
        isTrue,
        reason: 'orgDeleteDialogTitle (en) should not be empty',
      );
      expect(
        en.orgDeleteDialogContent,
        isA<String>(),
        reason: 'orgDeleteDialogContent (en)',
      );
      expect(
        en.orgDeleteDialogContent.isNotEmpty,
        isTrue,
        reason: 'orgDeleteDialogContent (en) should not be empty',
      );
    });

    test('pendingSync interpolates {n} correctly', () {
      expect(en.pendingSync(0), contains('0'));
      expect(en.pendingSync(1), contains('1'));
      expect(en.pendingSync(42), contains('42'));
      expect(en.pendingSync(5), isNot(contains('{n}')));
    });
  });

  group('AppStrings - _get() fallback / lookup behavior', () {
    test('unsupported locale code falls back to the Spanish table', () {
      final fr = AppStrings.forTesting('fr');
      final es = AppStrings.forTesting('es');
      expect(fr.login, equals(es.login));
      expect(fr.appName, equals(es.appName));
    });

    test('empty locale string falls back to the Spanish table', () {
      final empty = AppStrings.forTesting('');
      final es = AppStrings.forTesting('es');
      expect(empty.home, equals(es.home));
    });

    test('keys missing from both translation maps fall back to the raw key '
        '(documents a translation gap - see note above)', () {
      final es = AppStrings.forTesting('es');
      final en = AppStrings.forTesting('en');

      expect(es.guardianDocType, equals('guardianDocType'));
      expect(en.guardianDocType, equals('guardianDocType'));

      expect(es.guardianDocNumber, equals('guardianDocNumber'));
      expect(en.guardianDocNumber, equals('guardianDocNumber'));

      expect(es.guardianAuthAccepted, equals('guardianAuthAccepted'));
      expect(en.guardianAuthAccepted, equals('guardianAuthAccepted'));

      expect(es.guardianEmail, equals('guardianEmail'));
      expect(en.guardianEmail, equals('guardianEmail'));
    });

    test('keys present only in the Spanish map fall back to the raw key '
        'in English (documents a translation gap - see note above)', () {
      final en = AppStrings.forTesting('en');
      final es = AppStrings.forTesting('es');

      expect(en.ok, equals('ok'));
      expect(es.ok, isNot(equals('ok')));

      expect(en.forgotPasswordMessage, equals('forgotPasswordMessage'));
      expect(es.forgotPasswordMessage, isNot(equals('forgotPasswordMessage')));
    });
  });

  group('AppStrings - statistics keys', () {
    // Every key added for the brigade statistics screen must resolve in both
    // locales. `_get` returns the key itself on a miss, so comparing against
    // the key name catches a map entry that was never added.
    const keys = <String>[
      'statsScreenTitleOrg',
      'statsFilterAll',
      'statsTotalEncounters',
      'statsEmpty',
      'statsOfflineHint',
      'statsForbidden',
    ];

    List<String> valuesFor(AppStrings s) => <String>[
      s.statsScreenTitleOrg,
      s.statsFilterAll,
      s.statsTotalEncounters,
      s.statsEmpty,
      s.statsOfflineHint,
      s.statsForbidden,
    ];

    for (final locale in ['es', 'en']) {
      test('$locale resolves every statistics key', () {
        final values = valuesFor(AppStrings.forTesting(locale));
        for (var i = 0; i < keys.length; i++) {
          expect(values[i].isNotEmpty, isTrue, reason: '${keys[i]} ($locale)');
          expect(
            values[i],
            isNot(keys[i]),
            reason: '${keys[i]} ($locale) is missing from the map',
          );
        }
      });
    }

    test('the two locales differ, so nothing was copy-pasted', () {
      final es = valuesFor(AppStrings.forTesting('es'));
      final en = valuesFor(AppStrings.forTesting('en'));
      expect(es[0], 'Estadísticas de mi Organización');
      expect(en[0], "My Organization's Statistics");
      expect(es[1], 'Todas');
      expect(en[1], 'All');
    });
  });

  group('AppStrings - duplicate-key getters stay in sync', () {
    test('monMarString and monMar return the same value', () {
      final es = AppStrings.forTesting('es');
      final en = AppStrings.forTesting('en');
      expect(es.monMarString, equals(es.monMar));
      expect(en.monMarString, equals(en.monMar));
    });
  });
}
