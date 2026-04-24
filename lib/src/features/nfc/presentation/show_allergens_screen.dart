import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'shared_read_nfc_header.dart';

class ShowAllergensScreen extends StatelessWidget {
  const ShowAllergensScreen({super.key, required this.patient});

  final PatientFullRecord patient;

  @override
  Widget build(BuildContext context) {
    final allergens = patient.allergies
        .map((AllergyInfo a) => _AllergenData(
              name: a.allergen,
              category: a.category,
              reaction: a.reaction ?? '',
              severity: '',
              notes: a.notes ?? '',
            ))
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SharedReadNfcHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 44),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 3, top: 14),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
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
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  size: 15,
                                  color: AppColors.white,
                                ),
                                label: const Text(
                                  'Back',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Show Allergens',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _LastUpdatedCard(),
                        const SizedBox(height: 14),
                        ...List<Widget>.generate(
                          allergens.length,
                          (int i) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _AllergenDetailCard(allergen: allergens[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 18,
              bottom: 30,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: AppColors.secondary,
                child: const Icon(Icons.add, color: AppColors.white),
              ),
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
}

class _LastUpdatedCard extends StatelessWidget {
  const _LastUpdatedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x24000000), blurRadius: 10, offset: Offset(1, 4)),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.work_outline, size: 30, color: AppColors.secondary),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text('Enf. Mario Lopez', style: TextStyle(fontSize: 12)),
            ],
          ),
          Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppColors.secondary),
                  SizedBox(width: 4),
                  Text('19/08/2025 - 11:19', style: TextStyle(fontSize: 12)),
                ],
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.secondary),
                  SizedBox(width: 4),
                  Text('IPS Salud Total', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllergenData {
  const _AllergenData({
    required this.name,
    required this.category,
    required this.reaction,
    required this.severity,
    required this.notes,
  });

  static const Map<String, String> categoryLabels = {
    '01': 'Medicamento',
    '02': 'Alimento',
    '03': 'Sustancia ambiente',
    '04': 'Sustancia piel',
    '05': 'Picadura insectos',
    '06': 'Otra',
  };

  final String name;
  final String category;
  final String reaction;
  final String severity;
  final String notes;

  String get categoryLabel => categoryLabels[category] ?? 'Otra';
}

class _AllergenDetailCard extends StatelessWidget {
  const _AllergenDetailCard({required this.allergen});

  final _AllergenData allergen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x24000000), blurRadius: 10, offset: Offset(1, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Allergen: ${allergen.name}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldRow(Icons.favorite_border, 'Reaction:', allergen.reaction),
                const SizedBox(height: 8),
                _fieldRow(Icons.warning_amber, 'Severity:', allergen.severity),
                const SizedBox(height: 8),
                _fieldRow(Icons.note_alt, 'Notes:', allergen.notes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              children: <TextSpan>[
                TextSpan(
                  text: '$label  ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}