import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import 'edit_vaccine_sheet.dart';
import 'shared_read_nfc_header.dart';

class ShowVaccinesScreen extends StatelessWidget {
  const ShowVaccinesScreen({super.key});

  static const List<_VaccineData> _vaccines = <_VaccineData>[
    _VaccineData(
      name: 'Triple viral (SRP)',
      dose: '1ra Dosis',
      date: '22/03/2019',
      administeredBy: 'Enf. Carla fuentes',
      administeredAt: 'IPS Salud Total, Barranquilla',
    ),
    _VaccineData(
      name: 'Varicela',
      dose: 'Unica',
      date: '22/03/2019',
      administeredBy: 'Enf. Carla fuentes',
      administeredAt: 'IPS Salud Total, Barranquilla',
    ),
    _VaccineData(
      name: 'Polio',
      dose: 'Refuerzo',
      date: '15/04/2023',
      administeredBy: 'Enf. Mario Lopez',
      administeredAt: 'Clinica pedriatrica la Asuncion',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                          'Show Vaccines',
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
                          _vaccines.length,
                          (int i) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _VaccineCard(vaccine: _vaccines[i]),
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
                onPressed: () => _openEditVaccine(context, null),
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

  void _openEditVaccine(BuildContext context, _VaccineData? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditVaccineSheet(
        initialVaccine: existing?.name,
        initialDose: existing?.dose,
        initialDate: existing?.date,
        initialAdministeredBy: existing?.administeredBy,
        initialAdministeredAt: existing?.administeredAt,
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

class _VaccineData {
  const _VaccineData({
    required this.name,
    required this.dose,
    required this.date,
    required this.administeredBy,
    required this.administeredAt,
  });

  final String name;
  final String dose;
  final String date;
  final String administeredBy;
  final String administeredAt;
}

class _VaccineCard extends StatelessWidget {
  const _VaccineCard({required this.vaccine});

  final _VaccineData vaccine;

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
                const Icon(Icons.vaccines, size: 20, color: AppColors.white),
                const SizedBox(width: 8),
                Text(
                  'Vaccine: ${vaccine.name}',
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
                _field('Dose:', vaccine.dose),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Date: ${vaccine.date}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _field('Administred By:', vaccine.administeredBy),
                const SizedBox(height: 4),
                _field('Administred At:', vaccine.administeredAt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        children: <TextSpan>[
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
