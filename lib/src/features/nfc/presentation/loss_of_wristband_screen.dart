import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../../home/presentation/home_screen.dart';
import 'read_nfc_guardian_screen.dart';
import 'shared_read_nfc_header.dart';

class LossOfWristbandScreen extends StatefulWidget {
  const LossOfWristbandScreen({super.key});

  @override
  State<LossOfWristbandScreen> createState() => _LossOfWristbandScreenState();
}

class _LossOfWristbandScreenState extends State<LossOfWristbandScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _guardianCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topNavigationActions(context),
                        const SizedBox(height: 14),
                        const Text(
                          'Search Patient',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field('Name', _nameCtrl, Icons.person, true),
                        const SizedBox(height: 14),
                        _field(
                          'Date of Birth',
                          _dobCtrl,
                          Icons.calendar_today,
                          true,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          'Guardian Name',
                          _guardianCtrl,
                          Icons.person,
                          true,
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _isSearching ? null : _search,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: _isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.search,
                                    size: 20,
                                    color: AppColors.white,
                                  ),
                            label: Text(
                              _isSearching ? 'Searching...' : 'Search',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
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

  Widget _topNavigationActions(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 34,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 14,
              color: AppColors.white,
            ),
            label: const Text(
              'Back',
              style: TextStyle(color: AppColors.white, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A396),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(
              Icons.home_rounded,
              size: 16,
              color: AppColors.white,
            ),
            label: const Text(
              'Home',
              style: TextStyle(color: AppColors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon,
    bool required,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
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
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            hintText: label,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.disabled),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            prefixIcon: Icon(icon, size: 18, color: AppColors.secondary),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _search() async {
    final nameParts = _nameCtrl.text.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    setState(() => _isSearching = true);

    try {
      final repo = AppScope.of(context).patientRepository;
      final results = await repo.searchPatients(
        firstName: firstName,
        lastName: lastName,
        birthDate: _dobCtrl.text.trim(),
        guardianName: _guardianCtrl.text.trim().isNotEmpty
            ? _guardianCtrl.text.trim()
            : null,
      );

      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No patients found')));
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReadNfcGuardianScreen(patient: results.first),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }
}
