import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'nfc_save_flow.dart';
import 'shared_read_nfc_header.dart';

class RegisterNfcScreen extends StatefulWidget {
  const RegisterNfcScreen({super.key});

  @override
  State<RegisterNfcScreen> createState() => _RegisterNfcScreenState();
}

class _RegisterNfcScreenState extends State<RegisterNfcScreen> {
  int _currentStep = 0;
  bool _privacyAccepted = false;

  final TextEditingController _deviceUidCtrl = TextEditingController();
  final TextEditingController _guardianNameCtrl = TextEditingController();
  final TextEditingController _guardianIdCtrl = TextEditingController();
  final TextEditingController _guardianRelCtrl = TextEditingController();
  final TextEditingController _guardianAddressCtrl = TextEditingController();
  final TextEditingController _guardianContactCtrl = TextEditingController();
  final TextEditingController _guardianEmailCtrl = TextEditingController();

  String _guardianDocType = 'Select an option';
  String _guardianCountry = 'Select an option';

  final TextEditingController _patientNameCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();

  String _gender = 'Select an option';
  String _patientCountry = 'Select an option';
  String _bloodType = 'Select an option';

  final TextEditingController _currentIllnessCtrl = TextEditingController();
  final TextEditingController _personalHistoryCtrl = TextEditingController();
  final TextEditingController _familyHistoryCtrl = TextEditingController();
  final TextEditingController _generalExamCtrl = TextEditingController();
  final TextEditingController _systemsExamCtrl = TextEditingController();
  final TextEditingController _hospitalizationsCtrl = TextEditingController();
  final TextEditingController _surgeriesCtrl = TextEditingController();
  final TextEditingController _transfusionsCtrl = TextEditingController();
  final TextEditingController _epidemiologicalCtrl = TextEditingController();
  final TextEditingController _immunologicalCtrl = TextEditingController();
  final TextEditingController _staffNameCtrl = TextEditingController();
  final TextEditingController _staffPlaceCtrl = TextEditingController();
  final TextEditingController _staffDateCtrl = TextEditingController();

  String _typeVisit = 'Select an option';

  @override
  void dispose() {
    _deviceUidCtrl.dispose();
    _guardianNameCtrl.dispose();
    _guardianIdCtrl.dispose();
    _guardianRelCtrl.dispose();
    _guardianAddressCtrl.dispose();
    _guardianContactCtrl.dispose();
    _guardianEmailCtrl.dispose();
    _patientNameCtrl.dispose();
    _dobCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _currentIllnessCtrl.dispose();
    _personalHistoryCtrl.dispose();
    _familyHistoryCtrl.dispose();
    _generalExamCtrl.dispose();
    _systemsExamCtrl.dispose();
    _hospitalizationsCtrl.dispose();
    _surgeriesCtrl.dispose();
    _transfusionsCtrl.dispose();
    _epidemiologicalCtrl.dispose();
    _immunologicalCtrl.dispose();
    _staffNameCtrl.dispose();
    _staffPlaceCtrl.dispose();
    _staffDateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SharedReadNfcHeader(title: 'Register NFC'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StepIndicator(currentStep: _currentStep),
                        const SizedBox(height: 14),
                        _buildCurrentStep(),
                        const SizedBox(height: 20),
                        _buildButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 116,
              right: 116,
              bottom: 14,
              child: ScreenBottomHandle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _Step1Guardian(
          deviceUidCtrl: _deviceUidCtrl,
          nameCtrl: _guardianNameCtrl,
          docType: _guardianDocType,
          onDocTypeChanged: (String v) =>
              setState(() => _guardianDocType = v),
          idCtrl: _guardianIdCtrl,
          relationshipCtrl: _guardianRelCtrl,
          country: _guardianCountry,
          onCountryChanged: (String v) =>
              setState(() => _guardianCountry = v),
          addressCtrl: _guardianAddressCtrl,
          contactCtrl: _guardianContactCtrl,
          emailCtrl: _guardianEmailCtrl,
          privacyAccepted: _privacyAccepted,
          onPrivacyChanged: (bool v) =>
              setState(() => _privacyAccepted = v),
          onShowPrivacyPolicy: () => _showPrivacyPolicy(context),
        );
      case 1:
        return _Step2Patient(
          nameCtrl: _patientNameCtrl,
          dobCtrl: _dobCtrl,
          gender: _gender,
          onGenderChanged: (String v) => setState(() => _gender = v),
          country: _patientCountry,
          onCountryChanged: (String v) =>
              setState(() => _patientCountry = v),
          weightCtrl: _weightCtrl,
          heightCtrl: _heightCtrl,
          bloodType: _bloodType,
          onBloodTypeChanged: (String v) =>
              setState(() => _bloodType = v),
        );
      case 2:
        return _Step3MedicalHistory(
          currentIllnessCtrl: _currentIllnessCtrl,
          personalHistoryCtrl: _personalHistoryCtrl,
          familyHistoryCtrl: _familyHistoryCtrl,
          generalExamCtrl: _generalExamCtrl,
          systemsExamCtrl: _systemsExamCtrl,
          hospitalizationsCtrl: _hospitalizationsCtrl,
          surgeriesCtrl: _surgeriesCtrl,
          transfusionsCtrl: _transfusionsCtrl,
          epidemiologicalCtrl: _epidemiologicalCtrl,
          immunologicalCtrl: _immunologicalCtrl,
          staffNameCtrl: _staffNameCtrl,
          staffPlaceCtrl: _staffPlaceCtrl,
          staffDateCtrl: _staffDateCtrl,
          typeVisit: _typeVisit,
          onTypeVisitChanged: (String v) =>
              setState(() => _typeVisit = v),
        );
      case 3:
        return _Step4Summary(
          guardianName: _guardianNameCtrl.text,
          guardianId: _guardianIdCtrl.text,
          guardianRel: _guardianRelCtrl.text,
          guardianAddress: _guardianAddressCtrl.text,
          guardianContact: _guardianContactCtrl.text,
          patientName: _patientNameCtrl.text,
          dob: _dobCtrl.text,
          gender: _gender,
          country: _patientCountry,
          weight: _weightCtrl.text,
          height: _heightCtrl.text,
          bloodType: _bloodType,
          currentIllness: _currentIllnessCtrl.text,
          personalHistory: _personalHistoryCtrl.text,
          familyHistory: _familyHistoryCtrl.text,
          staffName: _staffNameCtrl.text,
          staffPlace: _staffPlaceCtrl.text,
          staffDate: _staffDateCtrl.text,
          typeVisit: _typeVisit,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildButtons() {
    if (_currentStep == 0) {
      return SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton.icon(
          onPressed: () => setState(() => _currentStep = 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A396),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.arrow_forward, size: 18, color: AppColors.white),
          label: const Text(
            'Next',
            style: TextStyle(color: AppColors.white, fontSize: 14),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.arrow_back_ios,
                  size: 14, color: AppColors.white),
              label: const Text(
                'Back',
                style: TextStyle(color: AppColors.white, fontSize: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  _syncAndSave(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 3
                    ? const Color(0xFF00A396)
                    : const Color(0xFF00A396),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(
                _currentStep == 3 ? Icons.save : Icons.arrow_forward,
                size: 18,
                color: AppColors.white,
              ),
              label: Text(
                _currentStep == 3 ? 'Save' : 'Next',
                style:
                    const TextStyle(color: AppColors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _PrivacyPolicyDialog(),
    );
  }

  PatientFullRecord _buildRecord() {
    final String now = DateTime.now().toIso8601String();

    // Map UI gender to backend biologicalSex code
    final String bioSex;
    switch (_gender) {
      case 'Female': bioSex = 'F'; break;
      case 'Male':   bioSex = 'M'; break;
      default:       bioSex = 'I'; break;
    }

    // Map UI country to ISO 3166-1 alpha-3
    final String natCode;
    switch (_patientCountry) {
      case 'Colombia':   natCode = 'COL'; break;
      case 'Venezuela':  natCode = 'VEN'; break;
      default:           natCode = 'COL'; break;
    }

    return PatientFullRecord(
      patientId: const Uuid().v4(),
      deviceUid: _deviceUidCtrl.text,
      patientInfo: PatientInfo(
        identification: PatientIdentification(
          documentType: 'MS', // Default for minors without ID
          documentNumber: '',
        ),
        firstLastName: '',
        firstName: _patientNameCtrl.text,
        dob: _dobCtrl.text,
        nationalityCode: natCode,
        biologicalSex: bioSex,
        address: Address(
          city: '',
          state: '',
          country: natCode,
        ),
        bloodType: _bloodType == 'Select an option' ? null : _bloodType,
        weight: double.tryParse(_weightCtrl.text),
        height: double.tryParse(_heightCtrl.text),
      ),
      guardianInfo: GuardianInfo(
        name: _guardianNameCtrl.text,
        relationship: _guardianRelCtrl.text,
        phone: _guardianContactCtrl.text,
      ),
      backgroundHistory: BackgroundHistory(
        personalHistory: _personalHistoryCtrl.text.isEmpty
            ? null
            : _personalHistoryCtrl.text,
        chronicConditions: null,
        familyHistory: <FamilyHistoryItem>[],
        familyHistoryNotes: _familyHistoryCtrl.text.isEmpty
            ? null
            : _familyHistoryCtrl.text,
      ),
      medicalHistory: <MedicalHistoryItem>[
        MedicalHistoryItem(
          type: _typeVisit == 'Select an option' ? 'Consultation' : _typeVisit,
          startDateTime: _staffDateCtrl.text.isEmpty ? now : _staffDateCtrl.text,
          careModality: '01',
          serviceGroup: '01',
          careEnvironment: '05',
          provider: ProviderInfo(
            repsCode: '',
            name: _staffPlaceCtrl.text,
          ),
          practitioner: PractitionerInfo(
            documentType: 'CC',
            documentNumber: '',
            name: _staffNameCtrl.text,
          ),
          clinicalEvaluation: ClinicalEvaluation(
            historyOfCurrentIllness: _currentIllnessCtrl.text.isEmpty
                ? null
                : _currentIllnessCtrl.text,
            generalPhysicalExamination: _generalExamCtrl.text.isEmpty
                ? null
                : _generalExamCtrl.text,
            systemsExamination: _systemsExamCtrl.text.isEmpty
                ? null
                : _systemsExamCtrl.text,
          ),
          diagnosis: <DiagnosisItem>[], // Backend LLM fills this
          diagnosisType: '01',
        ),
      ],
    );
  }

  void _syncAndSave(BuildContext context) {
    final PatientFullRecord record = _buildRecord();
    final scope = AppScope.of(context);

    showNfcSaveFlow(
      context,
      onSync: () async {
        // 1. Save locally FIRST (offline-first — never depends on internet)
        await scope.localDatabase.savePatient(record);

        // 2. Attempt cloud sync (best-effort — SyncEngine retries later)
        try {
          await scope.patientRepository.syncPatient(record);
          await scope.localDatabase.markSynced(record.patientId);
        } catch (_) {
          // Sync failed — record stays in local DB with is_synced=false.
          // The SyncEngine will retry automatically when connectivity returns.
        }
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(4, (int index) {
        final bool active = index <= currentStep;
        final bool isCurrent = index == currentStep;
        return Expanded(
          child: Row(
            children: [
              if (index > 0)
                Expanded(
                  child: Container(
                    height: 3,
                    color: active
                        ? AppColors.secondary
                        : const Color(0xFFD0D0D0),
                  ),
                ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? AppColors.secondary
                      : active
                          ? const Color(0xFF00A396)
                          : const Color(0xFFD0D0D0),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color:
                          active ? AppColors.white : const Color(0xFF888888),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Step1Guardian extends StatelessWidget {
  const _Step1Guardian({
    required this.deviceUidCtrl,
    required this.nameCtrl,
    required this.docType,
    required this.onDocTypeChanged,
    required this.idCtrl,
    required this.relationshipCtrl,
    required this.country,
    required this.onCountryChanged,
    required this.addressCtrl,
    required this.contactCtrl,
    required this.emailCtrl,
    required this.privacyAccepted,
    required this.onPrivacyChanged,
    required this.onShowPrivacyPolicy,
  });

  final TextEditingController deviceUidCtrl;
  final TextEditingController nameCtrl;
  final String docType;
  final ValueChanged<String> onDocTypeChanged;
  final TextEditingController idCtrl;
  final TextEditingController relationshipCtrl;
  final String country;
  final ValueChanged<String> onCountryChanged;
  final TextEditingController addressCtrl;
  final TextEditingController contactCtrl;
  final TextEditingController emailCtrl;
  final bool privacyAccepted;
  final ValueChanged<bool> onPrivacyChanged;
  final VoidCallback onShowPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Companion / Guardian Information'),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Device UID'),
        Row(
          children: [
            Expanded(child: _InputField(controller: deviceUidCtrl)),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_scanner,
                  color: AppColors.white, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Name'),
        _InputField(controller: nameCtrl, icon: Icons.person),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Document type'),
        _DropdownField(
          value: docType,
          items: const [
            'Select an option',
            'Citizenship card',
            'Passport',
            'Other',
          ],
          onChanged: onDocTypeChanged,
        ),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Identification number'),
        _InputField(controller: idCtrl, icon: Icons.badge),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Relationship'),
        _InputField(controller: relationshipCtrl, icon: Icons.family_restroom),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Country'),
        _DropdownField(
          value: country,
          items: const [
            'Select an option',
            'Colombia',
            'Venezuela',
            'Other',
          ],
          onChanged: onCountryChanged,
        ),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Address'),
        _InputField(controller: addressCtrl, icon: Icons.location_on),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Contect'),
        _InputField(controller: contactCtrl, icon: Icons.call),
        const SizedBox(height: 18),
        const _SectionTitle('Authorization & Privacy'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: privacyAccepted,
              onChanged: (bool? v) => onPrivacyChanged(v ?? false),
              activeColor: AppColors.secondary,
            ),
            Expanded(
              child: GestureDetector(
                onTap: onShowPrivacyPolicy,
                child: const Text.rich(
                  TextSpan(
                    text:
                        'The guardian acknowledges having read and authorized the processing of the minor\'s data and the ',
                    children: [
                      TextSpan(
                        text: 'privacy policy',
                        style: TextStyle(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' including the electronic receipt of receipts.',
                      ),
                    ],
                  ),
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Email'),
        _InputField(controller: emailCtrl, icon: Icons.email),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Biometric signature'),
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: const Center(
            child: Text(
              '✏ Sign here',
              style: TextStyle(color: AppColors.disabled, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 32,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A396),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Clear signature',
              style: TextStyle(color: AppColors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _Step2Patient extends StatelessWidget {
  const _Step2Patient({
    required this.nameCtrl,
    required this.dobCtrl,
    required this.gender,
    required this.onGenderChanged,
    required this.country,
    required this.onCountryChanged,
    required this.weightCtrl,
    required this.heightCtrl,
    required this.bloodType,
    required this.onBloodTypeChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController dobCtrl;
  final String gender;
  final ValueChanged<String> onGenderChanged;
  final String country;
  final ValueChanged<String> onCountryChanged;
  final TextEditingController weightCtrl;
  final TextEditingController heightCtrl;
  final String bloodType;
  final ValueChanged<String> onBloodTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Patient Information'),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Name'),
        _InputField(controller: nameCtrl, icon: Icons.person),
        const SizedBox(height: 10),
        const _FieldLabel('Date of Birth'),
        _InputField(controller: dobCtrl, icon: Icons.calendar_today),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Gender'),
        _DropdownField(
          value: gender,
          items: const ['Select an option', 'Female', 'Male'],
          onChanged: onGenderChanged,
        ),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Country'),
        _DropdownField(
          value: country,
          items: const [
            'Select an option',
            'Colombia',
            'Venezuela',
            'Other',
          ],
          onChanged: onCountryChanged,
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Physical information'),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Weight'),
        _InputField(controller: weightCtrl, icon: Icons.monitor_weight),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Height'),
        _InputField(controller: heightCtrl, icon: Icons.open_in_full),
        const SizedBox(height: 10),
        _FieldLabel.withStar('Blood Type'),
        _DropdownField(
          value: bloodType,
          items: const [
            'Select an option',
            'A+',
            'A-',
            'B+',
            'B-',
            'O+',
            'O-',
            'AB+',
            'AB-',
          ],
          onChanged: onBloodTypeChanged,
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Vaccine'),
        const SizedBox(height: 6),
        _tableHeader(const ['Vaccine', 'Does', 'Date', 'Administrated By']),
        const SizedBox(height: 8),
        _addRowButton(context, 'Add Vaccine', _showAddVaccine),
        const SizedBox(height: 18),
        const _SectionTitle('Allergen'),
        const SizedBox(height: 6),
        _tableHeader(const ['Allergen', 'Reaction', 'Severity', 'Notes']),
        const SizedBox(height: 8),
        _addRowButton(context, 'Add Allergen', _showAddAllergen),
      ],
    );
  }

  Widget _tableHeader(List<String> cols) {
    return Row(
      children: cols
          .map((String c) => Expanded(
                child: Text(c, style: const TextStyle(fontSize: 11)),
              ))
          .toList(),
    );
  }

  Widget _addRowButton(
    BuildContext context,
    String label,
    void Function(BuildContext) onTap,
  ) {
    return SizedBox(
      height: 30,
      child: ElevatedButton.icon(
        onPressed: () => onTap(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: const Icon(Icons.add, size: 16, color: AppColors.white),
        label: Text(
          label,
          style: const TextStyle(color: AppColors.white, fontSize: 12),
        ),
      ),
    );
  }

  static void _showAddVaccine(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddVaccineSheet(),
    );
  }

  static void _showAddAllergen(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddAllergenSheet(),
    );
  }
}

class _Step3MedicalHistory extends StatelessWidget {
  const _Step3MedicalHistory({
    required this.currentIllnessCtrl,
    required this.personalHistoryCtrl,
    required this.familyHistoryCtrl,
    required this.generalExamCtrl,
    required this.systemsExamCtrl,
    required this.hospitalizationsCtrl,
    required this.surgeriesCtrl,
    required this.transfusionsCtrl,
    required this.epidemiologicalCtrl,
    required this.immunologicalCtrl,
    required this.staffNameCtrl,
    required this.staffPlaceCtrl,
    required this.staffDateCtrl,
    required this.typeVisit,
    required this.onTypeVisitChanged,
  });

  final TextEditingController currentIllnessCtrl;
  final TextEditingController personalHistoryCtrl;
  final TextEditingController familyHistoryCtrl;
  final TextEditingController generalExamCtrl;
  final TextEditingController systemsExamCtrl;
  final TextEditingController hospitalizationsCtrl;
  final TextEditingController surgeriesCtrl;
  final TextEditingController transfusionsCtrl;
  final TextEditingController epidemiologicalCtrl;
  final TextEditingController immunologicalCtrl;
  final TextEditingController staffNameCtrl;
  final TextEditingController staffPlaceCtrl;
  final TextEditingController staffDateCtrl;
  final String typeVisit;
  final ValueChanged<String> onTypeVisitChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('General'),
        const SizedBox(height: 8),
        _textArea('History of current illness', currentIllnessCtrl),
        _textArea('Personal History', personalHistoryCtrl),
        _textArea('Family History', familyHistoryCtrl),
        const SizedBox(height: 14),
        const _SectionTitle('Physical Examination'),
        const SizedBox(height: 8),
        _textArea('General Physical Examination', generalExamCtrl),
        _textArea('Systems Examination', systemsExamCtrl),
        const SizedBox(height: 14),
        const _SectionTitle('Personal History'),
        const SizedBox(height: 8),
        _textArea('Hospitalizations', hospitalizationsCtrl),
        _textArea('Surgeries', surgeriesCtrl),
        _textArea('Transfusions', transfusionsCtrl),
        _textArea('Epidemiological history', epidemiologicalCtrl),
        _textArea('Immunological history', immunologicalCtrl),
        const SizedBox(height: 14),
        const _SectionTitle('Medical Staff'),
        const SizedBox(height: 8),
        const _FieldLabel('Name'),
        _InputField(controller: staffNameCtrl, icon: Icons.person),
        const SizedBox(height: 10),
        const _FieldLabel('Place'),
        _InputField(controller: staffPlaceCtrl, icon: Icons.apartment),
        const SizedBox(height: 10),
        const _FieldLabel('Date'),
        _InputField(controller: staffDateCtrl, icon: Icons.calendar_today),
        const SizedBox(height: 10),
        const _FieldLabel('Type visit'),
        _DropdownField(
          value: typeVisit,
          items: const [
            'Select an option',
            'Consulta pediatrica',
            'Urgencias',
            'Control',
          ],
          onChanged: onTypeVisitChanged,
        ),
      ],
    );
  }

  Widget _textArea(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            maxLines: 2,
            maxLength: 100,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: label,
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.disabled),
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step4Summary extends StatelessWidget {
  const _Step4Summary({
    required this.guardianName,
    required this.guardianId,
    required this.guardianRel,
    required this.guardianAddress,
    required this.guardianContact,
    required this.patientName,
    required this.dob,
    required this.gender,
    required this.country,
    required this.weight,
    required this.height,
    required this.bloodType,
    required this.currentIllness,
    required this.personalHistory,
    required this.familyHistory,
    required this.staffName,
    required this.staffPlace,
    required this.staffDate,
    required this.typeVisit,
  });

  final String guardianName;
  final String guardianId;
  final String guardianRel;
  final String guardianAddress;
  final String guardianContact;
  final String patientName;
  final String dob;
  final String gender;
  final String country;
  final String weight;
  final String height;
  final String bloodType;
  final String currentIllness;
  final String personalHistory;
  final String familyHistory;
  final String staffName;
  final String staffPlace;
  final String staffDate;
  final String typeVisit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        _summaryCard('Companion / Guardian Information', [
          _row(Icons.person, 'Name: $guardianName'),
          _row(Icons.badge, 'Identification number: $guardianId'),
          _row(Icons.family_restroom, 'Relationship: $guardianRel'),
          _row(Icons.location_on, 'Address: $guardianAddress'),
          _row(Icons.call, 'Contact (Cellphone): $guardianContact'),
        ]),
        const SizedBox(height: 12),
        _summaryCard('Patient Information', [
          _row(Icons.person, patientName),
          Row(
            children: [
              _chip('Date Birthday', dob),
              const SizedBox(width: 8),
              _chip('Gender', gender),
              const SizedBox(width: 8),
              _chip('Country', country),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        _summaryCard('Physical information', [
          Row(
            children: [
              _chip(null, '$weight Kg'),
              const SizedBox(width: 8),
              _chip(null, '$height cm'),
              const SizedBox(width: 8),
              _chip(Icons.bloodtype, bloodType),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        _summaryCard('General', [
          _historyBlock(
              Icons.description, 'History of current illness', currentIllness),
          const SizedBox(height: 6),
          _historyBlock(Icons.vaccines, 'Personal history', personalHistory),
          const SizedBox(height: 6),
          _historyBlock(
              Icons.family_restroom, 'Family History', familyHistory),
        ]),
        const SizedBox(height: 12),
        _summaryCard('Medical Staff', [
          _row(Icons.person, 'Dr $staffName'),
          _row(Icons.local_activity, 'Type visit: $typeVisit'),
          _row(Icons.apartment, 'Place: $staffPlace'),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Row(
              children: [
                const Text('Date',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                const Icon(Icons.calendar_today,
                    size: 14, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(staffDate, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _summaryCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _chip(Object? iconOrLabel, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.secondary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconOrLabel is IconData)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(iconOrLabel, size: 14, color: AppColors.secondary),
            ),
          Text(value, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _historyBlock(IconData icon, String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _PrivacyPolicyDialog extends StatelessWidget {
  const _PrivacyPolicyDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Privacy policy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const SizedBox(
              height: 350,
              child: SingleChildScrollView(
                child: Text(
                  'Privacy Policy: Notice on Data Processing for Minors\n\n'
                  '1. Introduction\n'
                  'This Privacy Policy describes how we collect, use, and protect the personal data of minors and their legal guardians. By providing your consent, you authorize the processing of this information for the purpose of medical identification and emergency assistance.\n\n'
                  '2. Data We Collect\n'
                  '• Minor\'s Information: Full name, identification number, and relevant medical/health conditions.\n'
                  '• Guardian\'s Information: Full name, relationship to the minor, contact details, and physical address.\n'
                  '• Biometric Data: Digital signature as proof of legal authorization.\n\n'
                  '3. Data Security\n'
                  'We implement high-level encryption and security protocols to ensure that personal and medical information is stored safely and is only accessible by authorized parties during an emergency.\n\n'
                  '4. Your Rights (ARCO Rights)\n'
                  'As a guardian, you have the right to access, rectify, cancel, or oppose the processing of your data or the minor\'s data at any time through our support channels.\n\n'
                  '5. Receipt of Proof of Consent\n'
                  'Upon acceptance, a digital copy of this authorization and your digital signature will be sent to the email address provided as a legal receipt of this transaction.\n\n'
                  '6. Purpose of Processing\n'
                  'The data collected will be used exclusively for medical identification, emergency response, and health record management.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(color: AppColors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddVaccineSheet extends StatefulWidget {
  const _AddVaccineSheet();

  @override
  State<_AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends State<_AddVaccineSheet> {
  final TextEditingController _vaccineNameCtrl = TextEditingController();
  final TextEditingController _vaccineCodeCtrl = TextEditingController();
  final TextEditingController _doseCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _byCtrl = TextEditingController();
  final TextEditingController _atCtrl = TextEditingController();

  @override
  void dispose() {
    _vaccineNameCtrl.dispose();
    _vaccineCodeCtrl.dispose();
    _doseCtrl.dispose();
    _dateCtrl.dispose();
    _byCtrl.dispose();
    _atCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Enter your vaccine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Vaccine Name'),
            _InputField(controller: _vaccineNameCtrl),
            const SizedBox(height: 10),
            const _FieldLabel('CVX Code'),
            _InputField(controller: _vaccineCodeCtrl),
            const SizedBox(height: 10),
            const _FieldLabel('Dose'),
            _InputField(controller: _doseCtrl),
            const SizedBox(height: 10),
            const _FieldLabel('Date'),
            _InputField(controller: _dateCtrl),
            const SizedBox(height: 10),
            const _FieldLabel('Administrated By'),
            _InputField(controller: _byCtrl),
            const SizedBox(height: 10),
            const _FieldLabel('Administrated At'),
            _InputField(controller: _atCtrl),
            const SizedBox(height: 18),
            SizedBox(
              width: 120,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.save, size: 16, color: AppColors.white),
                label: const Text(
                  'Save',
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAllergenSheet extends StatefulWidget {
  const _AddAllergenSheet();

  @override
  State<_AddAllergenSheet> createState() => _AddAllergenSheetState();
}

class _AddAllergenSheetState extends State<_AddAllergenSheet> {
  static const List<String> _allergens = <String>[
    'Penicillin',
    'Peanuts',
    'Seafood',
    'Eggs',
    'Milk',
    'Latex',
  ];

  static const List<String> _reactions = <String>[
    'Habones',
    'Edema de mucosas',
    'Dificultad para respirar',
    'Choque anafiláctico',
    'Paro cardiaco',
  ];

  static const List<String> _severityLevels = <String>[
    'Mild',
    'Moderate',
    'Severe',
  ];

  final TextEditingController _notesCtrl = TextEditingController();

  String? _selectedAllergen = _allergens.first;
  String? _selectedReaction = _reactions.first;
  String? _selectedSeverity = _severityLevels.first;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Enter your allergen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Allergen'),
            _CatalogDropdown(
              value: _selectedAllergen,
              hint: 'Select allergen',
              items: _allergens,
              onChanged: (String? value) {
                setState(() => _selectedAllergen = value);
              },
            ),
            const SizedBox(height: 10),
            const _FieldLabel('Reaction'),
            _CatalogDropdown(
              value: _selectedReaction,
              hint: 'Select reaction',
              items: _reactions,
              onChanged: (String? value) {
                setState(() => _selectedReaction = value);
              },
            ),
            const SizedBox(height: 10),
            const _FieldLabel('Severity'),
            _CatalogDropdown(
              value: _selectedSeverity,
              hint: 'Select severity',
              items: _severityLevels,
              onChanged: (String? value) {
                setState(() => _selectedSeverity = value);
              },
            ),
            const SizedBox(height: 10),
            const _FieldLabel('Notes'),
            _InputField(controller: _notesCtrl),
            const SizedBox(height: 18),
            SizedBox(
              width: 120,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.save, size: 16, color: AppColors.white),
                label: const Text(
                  'Save',
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogDropdown extends StatelessWidget {
  const _CatalogDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint),
          value: value,
          items: items
              .map(
                (String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text) : required = false;

  const _FieldLabel.withStar(this.text) : required = true;

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(fontSize: 13),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({this.controller, this.icon});

  final TextEditingController? controller;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixIcon:
            icon != null ? Icon(icon, size: 18, color: AppColors.secondary) : null,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: items
              .map((String e) =>
                  DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: (String? v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}