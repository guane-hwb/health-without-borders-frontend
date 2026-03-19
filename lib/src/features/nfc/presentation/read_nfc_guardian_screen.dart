import 'package:flutter/material.dart';

import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import 'edit_guardian_screen.dart';
import 'edit_medical_history_screen.dart';
import 'edit_medical_staff_screen.dart';
import 'edit_patient_screen.dart';
import 'nfc_save_flow.dart';
import 'shared_read_nfc_header.dart';
import 'show_allergens_screen.dart';
import 'show_vaccines_screen.dart';

class ReadNfcGuardianScreen extends StatefulWidget {
  const ReadNfcGuardianScreen({super.key});

  @override
  State<ReadNfcGuardianScreen> createState() => _ReadNfcGuardianScreenState();
}

class _ReadNfcGuardianScreenState extends State<ReadNfcGuardianScreen> {
  int _selectedTab = 0;

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
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 44),
                    child: Column(
                      children: [
                        _PatientProfileCard(
                          onEdit: () => _push(const EditPatientScreen()),
                          onShowVaccines: () =>
                              _push(const ShowVaccinesScreen()),
                        ),
                        const SizedBox(height: 18),
                        _AllergenCard(
                          onMoreDetails: () =>
                              _push(const ShowAllergensScreen()),
                        ),
                        const SizedBox(height: 18),
                        _TabBar(
                          selectedIndex: _selectedTab,
                          onTap: (int index) {
                            setState(() {
                              _selectedTab = index;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTabContent(),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 33,
                          child: ElevatedButton.icon(
                            onPressed: () => showNfcSaveFlow(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.nfc,
                              size: 20,
                              color: AppColors.white,
                            ),
                            label: const Text(
                              'Update patient',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
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

  void _push(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 1:
        return _MedicalHistoryTab(
          onEdit: () => _push(const EditMedicalHistoryScreen()),
        );
      case 2:
        return _MedicalStaffTab(
          onEdit: () => _push(const EditMedicalStaffScreen()),
        );
      default:
        return _GuardianTab(
          onEdit: () => _push(const EditGuardianScreen()),
        );
    }
  }
}

class _PatientProfileCard extends StatelessWidget {
  const _PatientProfileCard({
    required this.onEdit,
    required this.onShowVaccines,
  });

  final VoidCallback onEdit;
  final VoidCallback onShowVaccines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 10,
            offset: Offset(1, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFF90CAF9),
                child: Icon(Icons.person, size: 40, color: Color(0xFF1A237E)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sofia Rojas',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Femenino, 2018-03-22',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Colombia',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A396),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 18,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Container(
            color: const Color(0xFFEBF2F8),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: const Row(
              children: [
                Icon(Icons.monitor_weight, size: 24, color: AppColors.secondary),
                SizedBox(width: 8),
                Text('Weight: 24 kg', style: TextStyle(fontSize: 15)),
                SizedBox(width: 20),
                Icon(Icons.open_in_full, size: 20, color: AppColors.secondary),
                SizedBox(width: 8),
                Text('Height: 122 cm', style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.bloodtype, size: 24, color: AppColors.secondary),
              SizedBox(width: 8),
              Text('Blood type: A+', style: TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.assignment, size: 24, color: AppColors.secondary),
              SizedBox(width: 8),
              Text('Chronic condition: Asma', style: TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 33,
            child: ElevatedButton.icon(
              onPressed: onShowVaccines,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon:
                  const Icon(Icons.vaccines, size: 20, color: AppColors.white),
              label: const Text(
                'Show Vaccines',
                style: TextStyle(color: AppColors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergenCard extends StatelessWidget {
  const _AllergenCard({required this.onMoreDetails});

  final VoidCallback onMoreDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFCF3F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error),
        boxShadow: const [
          BoxShadow(color: Color(0x24000000), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 39,
            decoration: const BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.warning, size: 24, color: Colors.yellow),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Allergens (2 Detected)',
                    style: TextStyle(color: AppColors.white, fontSize: 15),
                  ),
                ),
                Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              children: [
                _AllergenRow(name: 'Penicilina', severity: 'Moderada'),
                SizedBox(height: 8),
                _AllergenRow(name: 'Maní', severity: 'Severa'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 33,
                child: ElevatedButton.icon(
                  onPressed: onMoreDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A396),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(
                    Icons.visibility,
                    size: 20,
                    color: AppColors.white,
                  ),
                  label: const Text(
                    'More details',
                    style: TextStyle(color: AppColors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergenRow extends StatelessWidget {
  const _AllergenRow({required this.name, required this.severity});

  final String name;
  final String severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.back_hand,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(name, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          const Icon(Icons.warning, size: 20, color: Colors.amber),
          const SizedBox(width: 4),
          Text('Severity: $severity', style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const List<_TabDef> _tabs = <_TabDef>[
    _TabDef(Icons.person, 'Guardian'),
    _TabDef(Icons.receipt_long, 'Medical history'),
    _TabDef(Icons.medical_information, 'Medical staff'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E4E4),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List<Widget>.generate(_tabs.length, (int index) {
          final bool selected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? AppColors.secondary : Colors.transparent,
                  borderRadius: index == 0
                      ? const BorderRadius.horizontal(
                          left: Radius.circular(15),
                        )
                      : index == _tabs.length - 1
                          ? const BorderRadius.horizontal(
                              right: Radius.circular(15),
                            )
                          : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _tabs[index].icon,
                      size: 20,
                      color:
                          selected ? AppColors.white : const Color(0xFF686868),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _tabs[index].label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected
                              ? AppColors.white
                              : const Color(0xFF686868),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _GuardianTab extends StatelessWidget {
  const _GuardianTab({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      headerTitle: 'Companion / Guardian',
      onEdit: onEdit,
      children: const [
        _InfoRow(icon: Icons.person, text: 'Name: Ana Torres'),
        _InfoRow(
          icon: Icons.badge,
          text: 'Identification number: 10665987416',
        ),
        _InfoRow(icon: Icons.family_restroom, text: 'Relationship: Madre'),
        _InfoRow(
          icon: Icons.call,
          text: 'Contact (Cellphone): +57 310 987543',
        ),
      ],
    );
  }
}

class _MedicalHistoryTab extends StatelessWidget {
  const _MedicalHistoryTab({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          headerTitle: 'Medical History',
          onEdit: onEdit,
          children: const [
            _HistoryEntry(
              icon: Icons.description,
              title: 'History of current illness',
              body:
                  'La madre refiere que la niña presenta congestión nasal, estornudos y tos leve desde hace dos días.',
            ),
            SizedBox(height: 10),
            _HistoryEntry(
              icon: Icons.vaccines,
              title: 'Personal history',
              body:
                  'Esquema de vacunas completo para su edad. Sin alergias conocidas ni enfermedades previas.',
            ),
            SizedBox(height: 10),
            _HistoryEntry(
              icon: Icons.family_restroom,
              title: 'Family History',
              body:
                  'Padre con rinitis alérgica. Abuela materna con antecedentes de asma.',
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _LastUpdatedFooter(),
      ],
    );
  }
}

class _MedicalStaffTab extends StatelessWidget {
  const _MedicalStaffTab({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      headerTitle: 'Medical Staff',
      onEdit: onEdit,
      children: const [
        _InfoRow(icon: Icons.local_hospital, text: 'Medical staff'),
        Padding(
          padding: EdgeInsets.only(left: 34),
          child: Text('Dr Joe Doe', style: TextStyle(fontSize: 15)),
        ),
        SizedBox(height: 6),
        _InfoRow(
          icon: Icons.local_activity,
          text: 'Type visit: Consulta pediatrica',
        ),
        _InfoRow(icon: Icons.apartment, text: 'Place: CONSULTORIO 01'),
        SizedBox(height: 6),
        Padding(
          padding: EdgeInsets.only(left: 10),
          child: Row(
            children: [
              Text(
                'Date',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 18),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppColors.secondary),
              SizedBox(width: 6),
              Text('19/08/2025', style: TextStyle(fontSize: 15)),
              SizedBox(width: 18),
              Icon(Icons.access_time, size: 16, color: AppColors.secondary),
              SizedBox(width: 6),
              Text('11:19', style: TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.headerTitle,
    required this.onEdit,
    required this.children,
  });

  final String headerTitle;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 10,
            offset: Offset(1, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    headerTitle,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00A396),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 14,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _LastUpdatedFooter extends StatelessWidget {
  const _LastUpdatedFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 10,
            offset: Offset(1, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.work_outline, size: 28, color: AppColors.secondary),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text('Enf. Mario Lopez', style: TextStyle(fontSize: 11)),
            ],
          ),
          Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: AppColors.secondary),
                  SizedBox(width: 4),
                  Text('19/08/2025 - 11:19', style: TextStyle(fontSize: 11)),
                ],
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 12, color: AppColors.secondary),
                  SizedBox(width: 4),
                  Text('IPS Salud Total', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
