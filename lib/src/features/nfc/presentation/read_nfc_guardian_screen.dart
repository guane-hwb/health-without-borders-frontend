import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'edit_guardian_screen.dart';
import 'edit_medical_history_screen.dart';
import 'edit_medical_staff_screen.dart';
import 'edit_patient_screen.dart';
import 'nfc_save_flow.dart';
import 'shared_read_nfc_header.dart';
import 'show_allergens_screen.dart';
import 'show_vaccines_screen.dart';

class ReadNfcGuardianScreen extends StatefulWidget {
  const ReadNfcGuardianScreen({super.key, required this.patient});
  final PatientFullRecord patient;
  @override
  State<ReadNfcGuardianScreen> createState() => _ReadNfcGuardianScreenState();
}

class _ReadNfcGuardianScreenState extends State<ReadNfcGuardianScreen> {
  int _selectedTab = 0;
  PatientFullRecord get _p => widget.patient;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            SharedReadNfcHeader(
              title: s.patient,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 44),
              child: Column(children: [
                _PatientProfileCard(patient: _p,
                    onEdit: () => _push(EditPatientScreen(patient: _p)),
                    onShowVaccines: () => _push(ShowVaccinesScreen(patient: _p))),
                const SizedBox(height: 18),
                _AllergenCard(allergies: _p.allergies,
                    onMoreDetails: () => _push(ShowAllergensScreen(patient: _p))),
                const SizedBox(height: 18),
                _TabBar(selectedIndex: _selectedTab,
                    onTap: (i) => setState(() => _selectedTab = i)),
                const SizedBox(height: 12),
                _buildTabContent(s),
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, height: 33,
                  child: ElevatedButton.icon(
                    onPressed: () => _syncPatient(context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    icon: const Icon(Icons.nfc, size: 20, color: AppColors.white),
                    label: Text(s.updatePatient, style: const TextStyle(color: AppColors.white, fontSize: 14)),
                  )),
              ]),
            )),
          ]),
          const Positioned(left: 116, right: 116, bottom: 14, child: ScreenBottomHandle()),
        ]),
      ),
    );
  }

  void _push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
  void _syncPatient(BuildContext ctx) {
    final r = AppScope.of(ctx).patientRepository;
    showNfcSaveFlow(ctx, onSync: () async => r.syncPatient(_p));
  }

  Widget _buildTabContent(AppStrings s) {
    switch (_selectedTab) {
      case 1: return _MedicalHistoryTab(patient: _p, onEdit: () => _push(EditMedicalHistoryScreen(patient: _p)));
      case 2: return _MedicalStaffTab(patient: _p, onEdit: () => _push(EditMedicalStaffScreen(patient: _p)));
      default: return _GuardianTab(patient: _p, onEdit: () => _push(EditGuardianScreen(patient: _p)));
    }
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────
String _practName(MedicalHistoryItem? v) => v?.practitioner?.name ?? v?.physician ?? 'N/A';
String _provName(MedicalHistoryItem? v) => v?.provider?.name ?? v?.location ?? 'N/A';
String _vDate(MedicalHistoryItem? v) { final d = v?.startDateTime; if (d == null || d.isEmpty) return 'N/A'; return d.contains('T') ? d.split('T').first : d; }

// ─── Patient Profile Card ───────────────────────────────────────────────────
class _PatientProfileCard extends StatelessWidget {
  const _PatientProfileCard({required this.patient, required this.onEdit, required this.onShowVaccines});
  final PatientFullRecord patient; final VoidCallback onEdit, onShowVaccines;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final info = patient.patientInfo;
    final sexLabels = {'M': s.gender == 'Género *' ? 'Masculino' : 'Male', 'F': s.gender == 'Género *' ? 'Femenino' : 'Female', 'I': 'N/A'};
    final sex = sexLabels[info.biologicalSex] ?? info.biologicalSex;
    final chronic = patient.backgroundHistory?.chronicConditions ?? 'N/A';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 10, offset: Offset(1, 7))]),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(radius: 30, backgroundColor: Color(0xFF90CAF9), child: Icon(Icons.person, size: 40, color: Color(0xFF1A237E))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(info.fullName, style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('$sex, ${info.dob}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
            Text(info.nationalityCode, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
          ])),
          GestureDetector(onTap: onEdit, child: Container(width: 30, height: 30,
              decoration: const BoxDecoration(color: Color(0xFF00A396), shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 18, color: AppColors.white))),
        ]),
        const Divider(height: 24),
        Container(color: const Color(0xFFEBF2F8), padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(children: [
            const Icon(Icons.monitor_weight, size: 24, color: AppColors.secondary), const SizedBox(width: 8),
            Text('${s.weight}: ${info.weight ?? 'N/A'} kg', style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 20),
            const Icon(Icons.open_in_full, size: 20, color: AppColors.secondary), const SizedBox(width: 8),
            Text('${s.height}: ${info.height ?? 'N/A'} cm', style: const TextStyle(fontSize: 15)),
          ])),
        const SizedBox(height: 8),
        Row(children: [const Icon(Icons.bloodtype, size: 24, color: AppColors.secondary), const SizedBox(width: 8),
          Text('${s.bloodType}: ${info.bloodType ?? 'N/A'}', style: const TextStyle(fontSize: 15))]),
        const SizedBox(height: 4),
        Row(children: [const Icon(Icons.assignment, size: 24, color: AppColors.secondary), const SizedBox(width: 8),
          Text('${s.chronicCondition}: $chronic', style: const TextStyle(fontSize: 15))]),
        const SizedBox(height: 10),
        SizedBox(height: 33, child: ElevatedButton.icon(onPressed: onShowVaccines,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14)),
            icon: const Icon(Icons.vaccines, size: 20, color: AppColors.white),
            label: Text('${s.showVaccines} (${patient.vaccinationRecord.length})',
                style: const TextStyle(color: AppColors.white, fontSize: 12)))),
      ]),
    );
  }
}

// ─── Allergen Card ──────────────────────────────────────────────────────────
class _AllergenCard extends StatelessWidget {
  const _AllergenCard({required this.allergies, required this.onMoreDetails});
  final List<AllergyInfo> allergies; final VoidCallback onMoreDetails;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFFFCF3F2), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error),
          boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 10)]),
      child: Column(children: [
        Container(width: double.infinity, height: 39,
          decoration: const BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            const Icon(Icons.warning, size: 24, color: Colors.yellow), const SizedBox(width: 8),
            Expanded(child: Text('${s.allergens} (${allergies.length})', style: const TextStyle(color: AppColors.white, fontSize: 15))),
            Container(width: 25, height: 25, decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                child: Center(child: Text('${allergies.length}', style: const TextStyle(color: AppColors.error, fontSize: 15, fontWeight: FontWeight.w600)))),
          ])),
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 8), child: Column(children: [
          for (int i = 0; i < allergies.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _AllergenRow(name: allergies[i].allergen, reaction: allergies[i].reaction ?? ''),
          ],
          if (allergies.isEmpty) const Text('—', style: TextStyle(fontSize: 14)),
        ])),
        Padding(padding: const EdgeInsets.only(left: 14, bottom: 14),
          child: Align(alignment: Alignment.centerLeft, child: SizedBox(height: 33,
            child: ElevatedButton.icon(onPressed: onMoreDetails,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A396),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14)),
                icon: const Icon(Icons.visibility, size: 20, color: AppColors.white),
                label: Text(s.moreDetails, style: const TextStyle(color: AppColors.white, fontSize: 12)))))),
      ]),
    );
  }
}

class _AllergenRow extends StatelessWidget {
  const _AllergenRow({required this.name, required this.reaction});
  final String name, reaction;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 10)]),
    child: Row(children: [
      const Icon(Icons.back_hand, size: 20, color: AppColors.textSecondary), const SizedBox(width: 6),
      Text(name, style: const TextStyle(fontSize: 15)), const Spacer(),
      if (reaction.isNotEmpty) ...[const Icon(Icons.warning, size: 20, color: Colors.amber), const SizedBox(width: 4),
        Text(reaction, style: const TextStyle(fontSize: 15))],
    ]),
  );
}

// ─── Tab Bar ────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  const _TabBar({required this.selectedIndex, required this.onTap});
  final int selectedIndex; final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final tabs = [
      _TabDef(Icons.person, s.guardian),
      _TabDef(Icons.receipt_long, s.medicalHistory),
      _TabDef(Icons.medical_information, s.medicalStaff),
    ];
    return Container(height: 45,
      decoration: BoxDecoration(color: const Color(0xFFE4E4E4), borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4))]),
      child: Row(children: List.generate(tabs.length, (i) {
        final sel = i == selectedIndex;
        return Expanded(child: GestureDetector(onTap: () => onTap(i),
          child: Container(
            decoration: BoxDecoration(color: sel ? AppColors.secondary : Colors.transparent,
                borderRadius: i == 0 ? const BorderRadius.horizontal(left: Radius.circular(15))
                    : i == tabs.length - 1 ? const BorderRadius.horizontal(right: Radius.circular(15)) : null),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(tabs[i].icon, size: 20, color: sel ? AppColors.white : const Color(0xFF686868)),
              const SizedBox(width: 4),
              Flexible(child: Text(tabs[i].label, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: sel ? AppColors.white : const Color(0xFF686868)))),
            ]),
          )));
      })),
    );
  }
}
class _TabDef { const _TabDef(this.icon, this.label); final IconData icon; final String label; }

// ─── Tab content ────────────────────────────────────────────────────────────
class _GuardianTab extends StatelessWidget {
  const _GuardianTab({required this.patient, required this.onEdit});
  final PatientFullRecord patient; final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final g = patient.guardianInfo;
    return _SectionCard(headerTitle: s.guardian, onEdit: onEdit, children: [
      _InfoRow(icon: Icons.person, text: '${s.name}: ${g.name}'),
      _InfoRow(icon: Icons.family_restroom, text: '${s.relationship}: ${g.relationship}'),
      _InfoRow(icon: Icons.call, text: '${s.guardianPhone}: ${g.phone}'),
    ]);
  }
}

class _MedicalHistoryTab extends StatelessWidget {
  const _MedicalHistoryTab({required this.patient, required this.onEdit});
  final PatientFullRecord patient; final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final bg = patient.backgroundHistory;
    final v = patient.medicalHistory.isNotEmpty ? patient.medicalHistory.last : null;
    final eval = v?.clinicalEvaluation;
    final relLabels = {'01': 'Padres', '02': 'Hermanos', '03': 'Tíos', '04': 'Abuelos'};
    String fhDisplay = s.noData;
    if (bg != null) {
      final parts = <String>[];
      for (final item in bg.familyHistory) { parts.add('${item.conditionDescription} (${relLabels[item.relationship] ?? item.relationship})'); }
      if (bg.familyHistoryNotes?.isNotEmpty == true) parts.add(bg.familyHistoryNotes!);
      if (parts.isNotEmpty) fhDisplay = parts.join(', ');
    }
    return Column(children: [
      _SectionCard(headerTitle: s.medicalHistory, onEdit: onEdit, children: [
        _HistoryEntry(icon: Icons.description, title: s.historyCurrentIllness, body: eval?.historyOfCurrentIllness ?? s.noData),
        const SizedBox(height: 10),
        _HistoryEntry(icon: Icons.vaccines, title: s.personalHistory, body: bg?.personalHistory ?? s.noData),
        const SizedBox(height: 10),
        _HistoryEntry(icon: Icons.family_restroom, title: s.familyHistory, body: fhDisplay),
      ]),
      const SizedBox(height: 14),
      _LastUpdatedFooter(visit: v),
    ]);
  }
}

class _MedicalStaffTab extends StatelessWidget {
  const _MedicalStaffTab({required this.patient, required this.onEdit});
  final PatientFullRecord patient; final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final v = patient.medicalHistory.isNotEmpty ? patient.medicalHistory.last : null;
    return _SectionCard(headerTitle: s.medicalStaff, onEdit: onEdit, children: [
      _InfoRow(icon: Icons.local_hospital, text: 'Dr. ${_practName(v)}'),
      const SizedBox(height: 6),
      _InfoRow(icon: Icons.local_activity, text: '${s.encounter}: ${v?.type ?? 'N/A'}'),
      _InfoRow(icon: Icons.apartment, text: '${s.providerName}: ${_provName(v)}'),
      const SizedBox(height: 6),
      _InfoRow(icon: Icons.calendar_today, text: '${s.date}: ${_vDate(v)}'),
    ]);
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.headerTitle, required this.onEdit, required this.children});
  final String headerTitle; final VoidCallback onEdit; final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity,
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 10, offset: Offset(1, 7))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: double.infinity, height: 40,
        decoration: const BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          Expanded(child: Text(headerTitle, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w500))),
          GestureDetector(onTap: onEdit, child: Container(width: 25, height: 25,
              decoration: const BoxDecoration(color: Color(0xFF00A396), shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 14, color: AppColors.white))),
        ])),
      Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
    ]));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [Icon(icon, size: 24, color: AppColors.secondary), const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 15)))]));
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.icon, required this.title, required this.body});
  final IconData icon; final String title, body;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFEBF2F8), borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 20, color: AppColors.primary), const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)))]),
      const SizedBox(height: 6),
      Text(body, style: const TextStyle(fontSize: 13)),
    ]));
}

class _LastUpdatedFooter extends StatelessWidget {
  const _LastUpdatedFooter({this.visit});
  final MedicalHistoryItem? visit;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 10, offset: Offset(1, 4))]),
      child: Row(children: [
        const Icon(Icons.work_outline, size: 28, color: AppColors.secondary), const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.lastUpdated, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text(_practName(visit), style: const TextStyle(fontSize: 11)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.calendar_today, size: 12, color: AppColors.secondary), const SizedBox(width: 4), Text(_vDate(visit), style: const TextStyle(fontSize: 11))]),
          const SizedBox(height: 2),
          Row(children: [const Icon(Icons.location_on, size: 12, color: AppColors.secondary), const SizedBox(width: 4), Text(_provName(visit), style: const TextStyle(fontSize: 11))]),
        ]),
      ]));
  }
}