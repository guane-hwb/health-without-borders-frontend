import 'package:flutter/material.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../design/tokens/app_colors.dart';
import '../../../shared/widgets/screen_bottom_handle.dart';
import '../domain/patient_record.dart';
import 'shared_read_nfc_header.dart';

class ShowAllergensScreen extends StatelessWidget {
  const ShowAllergensScreen({super.key, required this.patient});
  final PatientFullRecord patient;
  @override Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final allergens = patient.allergies.map((a) => _AD(name: a.allergen, category: a.category, reaction: a.reaction ?? '', notes: a.notes ?? '')).toList();
    return Scaffold(backgroundColor: const Color(0xFFEBF2F8),
      body: SafeArea(child: Stack(children: [
        Column(children: [
          SharedReadNfcHeader(title: s.allergens, onBack: () => Navigator.of(context).pop()),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 44), child: Column(children: [
            const SizedBox(height: 14),
            Text(s.allergens, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.secondary)),
            const SizedBox(height: 14),
            ...allergens.map((a) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _AllergenCard(a: a, s: s))),
          ]))),
        ]),
        Positioned(right: 18, bottom: 30, child: FloatingActionButton(onPressed: () {}, backgroundColor: AppColors.secondary, child: const Icon(Icons.add, color: AppColors.white))),
        const Positioned(left: 116, right: 116, bottom: 14, child: ScreenBottomHandle()),
      ])));
  }
}
class _AD { const _AD({required this.name, required this.category, required this.reaction, required this.notes}); final String name, category, reaction, notes; }
class _AllergenCard extends StatelessWidget {
  const _AllergenCard({required this.a, required this.s});
  final _AD a; final AppStrings s;
  static const _cats = {'01': 'allergenMedication', '02': 'allergenFood', '03': 'allergenEnvironment', '04': 'allergenSkin', '05': 'allergenInsect', '06': 'allergenOther'};
  String _categoryLabel() => _cats[a.category] ?? a.category;
  @override Widget build(BuildContext context) => Container(width: double.infinity,
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 10, offset: Offset(1, 4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
        child: Row(children: [const Icon(Icons.warning, size: 20, color: Colors.amber), const SizedBox(width: 8), Text('${s.allergens}: ${a.name}', style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w500))])),
      Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.label, size: 18, color: AppColors.secondary), const SizedBox(width: 8), Text('${s.allergenOther}: ${_categoryLabel()}', style: const TextStyle(fontSize: 14))]),
        const SizedBox(height: 8),
        if (a.reaction.isNotEmpty) Row(children: [const Icon(Icons.favorite_border, size: 18, color: AppColors.secondary), const SizedBox(width: 8), Text(a.reaction, style: const TextStyle(fontSize: 14))]),
        if (a.notes.isNotEmpty) ...[const SizedBox(height: 8), Row(children: [const Icon(Icons.note_alt, size: 18, color: AppColors.secondary), const SizedBox(width: 8), Text(a.notes, style: const TextStyle(fontSize: 14))])],
      ])),
    ]));
}