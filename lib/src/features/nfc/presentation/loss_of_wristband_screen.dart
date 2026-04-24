import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'read_nfc_guardian_screen.dart';
import 'shared_read_nfc_header.dart';

/// Search for a patient who lost their wristband using identity fields.
///
/// Backend contract (GET /api/v1/patients/search):
///   Required: document_number, birth_date (YYYY-MM-DD), first_name, last_name
///   Optional: guardian_name
///   Returns: single PatientFullRecord or 404
class LossOfWristbandScreen extends StatefulWidget {
  const LossOfWristbandScreen({super.key});

  @override
  State<LossOfWristbandScreen> createState() => _LossOfWristbandScreenState();
}

class _LossOfWristbandScreenState extends State<LossOfWristbandScreen> {
  final TextEditingController _docNumberCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _guardianCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _docNumberCtrl.dispose();
    _dobCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _guardianCtrl.dispose();
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
                const SharedReadNfcHeader(title: 'Loss of wristband'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        SizedBox(
                          height: 33,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A396),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            icon: const Icon(Icons.arrow_back_ios,
                                size: 15, color: AppColors.white),
                            label: const Text('Back',
                                style: TextStyle(
                                    color: AppColors.white, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Search Patient',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'All four fields are required to find the patient.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        _field('Document Number', _docNumberCtrl,
                            Icons.badge_outlined, true),
                        const SizedBox(height: 14),
                        _field('Date of Birth (YYYY-MM-DD)', _dobCtrl,
                            Icons.calendar_today, true),
                        const SizedBox(height: 14),
                        _field('First Name', _firstNameCtrl,
                            Icons.person_outline, true),
                        const SizedBox(height: 14),
                        _field('Last Name', _lastNameCtrl,
                            Icons.person_outline, true),
                        const SizedBox(height: 14),
                        _field('Guardian Name (optional)', _guardianCtrl,
                            Icons.family_restroom, false),
                        const SizedBox(height: 24),
                        Center(
                          child: SizedBox(
                            width: 237,
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: _isSearching ? null : _search,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.disabled,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: _isSearching
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Icon(Icons.search,
                                      size: 18, color: AppColors.white),
                              label: const Text('Search',
                                  style: TextStyle(
                                      color: AppColors.white, fontSize: 16)),
                            ),
                          ),
                        ),
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

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon,
    bool required,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Future<void> _search() async {
    final docNumber = _docNumberCtrl.text.trim();
    final dob = _dobCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final guardianName = _guardianCtrl.text.trim();

    if (docNumber.isEmpty ||
        dob.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Document number, DOB, first name, and last name are required.'),
        ),
      );
      return;
    }

    setState(() => _isSearching = true);
    try {
      final PatientFullRecord patient =
          await AppScope.of(context).patientRepository.searchPatient(
                documentNumber: docNumber,
                birthDate: dob,
                firstName: firstName,
                lastName: lastName,
                guardianName: guardianName.isEmpty ? null : guardianName,
              );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReadNfcGuardianScreen(patient: patient),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }
}