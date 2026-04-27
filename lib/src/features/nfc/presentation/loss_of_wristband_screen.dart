import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import 'profile/patient_profile_screen.dart';
import 'shared_read_nfc_header.dart';

class LossOfWristbandScreen extends StatefulWidget {
  const LossOfWristbandScreen({super.key});
  @override
  State<LossOfWristbandScreen> createState() => _LossOfWristbandScreenState();
}

class _LossOfWristbandScreenState extends State<LossOfWristbandScreen> {
  final _docCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _fnCtrl = TextEditingController();
  final _lnCtrl = TextEditingController();
  final _gnCtrl = TextEditingController();
  bool _searching = false;
  @override
  void dispose() {
    _docCtrl.dispose();
    _dobCtrl.dispose();
    _fnCtrl.dispose();
    _lnCtrl.dispose();
    _gnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SharedReadNfcHeader(
                  title: s.lossOfWristband,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.searchPatient,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.searchRequiredFields,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _f(s.documentNumber, _docCtrl, Icons.badge_outlined),
                        const SizedBox(height: 14),
                        _f(
                          '${s.dateOfBirth} (YYYY-MM-DD)',
                          _dobCtrl,
                          Icons.calendar_today,
                        ),
                        const SizedBox(height: 14),
                        _f(s.firstNames, _fnCtrl, Icons.person_outline),
                        const SizedBox(height: 14),
                        _f(s.firstLastName, _lnCtrl, Icons.person_outline),
                        const SizedBox(height: 14),
                        _f(
                          '${s.guardianName} (${s.noData})',
                          _gnCtrl,
                          Icons.family_restroom,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: SizedBox(
                            width: 237,
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: _searching ? null : _search,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.disabled,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: _searching
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.search,
                                      size: 18,
                                      color: AppColors.white,
                                    ),
                              label: Text(
                                s.search,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                ),
                              ),
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

  Widget _f(String label, TextEditingController c, IconData icon) => Column(
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
        controller: c,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    ],
  );
  Future<void> _search() async {
    final s = AppStrings.of(context);
    if (_docCtrl.text.trim().isEmpty ||
        _dobCtrl.text.trim().isEmpty ||
        _fnCtrl.text.trim().isEmpty ||
        _lnCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.searchFieldsRequired)));
      return;
    }
    setState(() => _searching = true);
    try {
      final patient = await AppScope.of(context).patientRepository
          .searchPatient(
            documentNumber: _docCtrl.text.trim(),
            birthDate: _dobCtrl.text.trim(),
            firstName: _fnCtrl.text.trim(),
            lastName: _lnCtrl.text.trim(),
            guardianName: _gnCtrl.text.trim().isEmpty
                ? null
                : _gnCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PatientProfileScreen(patient: patient),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }
}
