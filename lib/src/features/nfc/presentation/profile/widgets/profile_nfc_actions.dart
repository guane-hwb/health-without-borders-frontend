// lib/src/features/nfc/presentation/profile/widgets/profile_nfc_actions.dart

import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_strings.dart';
import '../../../../../core/nfc/nfc_guardian_payload.dart';
import '../../../../../core/nfc/nfc_keyring.dart';
import '../../../../../core/nfc/nfc_payload_codec.dart';
import '../../../../../core/nfc/nfc_payload_service.dart';
import '../../../../../core/nfc/nfc_triage_payload.dart';
import '../../../../../core/nfc/partial_card_notice.dart';
import '../../../domain/patient_record.dart';
import '../../nfc_guided_write.dart';
import 'reassign_device_dialog.dart';

/// Ejecuta el flujo guiado de actualización de chips NFC (paciente y guardianes).
Future<bool> executeUpdateNfcChips({
  required BuildContext context,
  required PatientFullRecord record,
  required NfcKeyring keyring,
  required bool patientChipDirty,
  required bool guardianChipDirty,
}) async {
  final isEs = AppStrings.of(context).isEs;
  final messenger = ScaffoldMessenger.of(context);
  final codec = NfcPayloadCodec.fromKeyring(keyring: keyring);

  if (patientChipDirty) {
    final ok = await showNfcGuidedWrite(
      context,
      title: isEs ? 'Pulsera del paciente' : 'Patient wristband',
      instruction: isEs
          ? 'Acerque la pulsera del paciente al teléfono'
          : 'Bring the patient wristband to the phone',
      write: () => NfcPayloadService(codec: codec).writeTriagePayload(
        NfcTriagePayload.buildPatientPayload(record: record),
        expectedUid: record.deviceUid,
      ),
    );
    if (!ok) return false;
  }

  if (!context.mounted) return false;

  if (guardianChipDirty) {
    final guardian1Uid = (record.guardianInfo.deviceUid ?? '').trim();
    final guardian2Uid = (record.guardian2Info?.deviceUid ?? '').trim();
    final hasTwoGuardians = guardian1Uid.isNotEmpty && guardian2Uid.isNotEmpty;

    Future<bool> writeGuardianCard({
      required String expectedUid,
      required String title,
      required String instruction,
    }) async {
      GuardianPayloadFit? fit;
      final written = await showNfcGuidedWrite(
        context,
        title: title,
        instruction: instruction,
        write: () async {
          final result = await NfcPayloadService(codec: codec)
              .writeGuardianRecord(
                buildFit: guardianFitBuilder(record: record, codec: codec),
                expectedUid: expectedUid,
              );
          fit = result.fit;
        },
      );
      if (written && (fit?.isPartial ?? false)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(partialCardNoticeMessage(fit!, isEs)),
            duration: const Duration(seconds: 6),
          ),
        );
      }
      return written;
    }

    var allWritten = true;

    if (guardian1Uid.isNotEmpty) {
      final ok = await writeGuardianCard(
        expectedUid: guardian1Uid,
        title: hasTwoGuardians
            ? (isEs ? 'Tarjeta del guardián 1' : 'Guardian card 1')
            : (isEs ? 'Tarjeta del guardián' : 'Guardian card'),
        instruction: hasTwoGuardians
            ? (isEs
                  ? 'Acerque la tarjeta del guardián 1 al teléfono'
                  : 'Bring guardian card 1 to the phone')
            : (isEs
                  ? 'Acerque la tarjeta del guardián al teléfono'
                  : 'Bring the guardian card to the phone'),
      );
      allWritten = allWritten && ok;
    }

    if (guardian2Uid.isNotEmpty) {
      if (!context.mounted) return false;
      final ok = await writeGuardianCard(
        expectedUid: guardian2Uid,
        title: isEs ? 'Tarjeta del guardián 2' : 'Guardian card 2',
        instruction: isEs
            ? 'Acerque la tarjeta del guardián 2 al teléfono'
            : 'Bring guardian card 2 to the phone',
      );
      allWritten = allWritten && ok;
    }

    return allWritten;
  }

  return true;
}

/// Ejecuta el proceso de reasignación de un dispositivo individual.
Future<PatientFullRecord?> executeReassignOne({
  required BuildContext context,
  required ReassignTarget target,
  required PatientFullRecord record,
  required NfcPayloadCodec codec,
  required bool isEs,
  required void Function(String message, {bool error}) showSnack,
}) async {
  final hasTwo = (record.guardian2Info?.deviceUid ?? '').trim().isNotEmpty;
  String title;
  switch (target) {
    case ReassignTarget.patient:
      title = isEs ? 'dispositivo del paciente' : 'Patient device';
      break;
    case ReassignTarget.guardian1:
      title = hasTwo
          ? (isEs ? 'Tarjeta del guardián 1' : 'Guardian card 1')
          : (isEs ? 'Tarjeta del guardián' : 'Guardian card');
      break;
    case ReassignTarget.guardian2:
      title = isEs ? 'Tarjeta del guardián 2' : 'Guardian card 2';
      break;
  }

  String? newUid;
  HwbChipKind? kind;
  final readOk = await showNfcGuidedRead(
    context,
    title: title,
    instruction: isEs
        ? 'Acerque el dispositivo NUEVO (en blanco) para verificarlo'
        : 'Bring the NEW (blank) device close to verify it',
    read: () async {
      final result = await NfcPayloadService(codec: codec).readHwbChip();
      newUid = result.uid;
      kind = result.kind;
    },
  );
  if (!readOk || newUid == null || newUid!.trim().isEmpty) return null;

  if (kind != HwbChipKind.none) {
    showSnack(
      isEs
          ? 'Ese dispositivo ya está en uso. Use uno en blanco.'
          : 'That device is already in use. Use a blank one.',
      error: true,
    );
    return null;
  }

  final normalizedNew = newUid!.trim();
  final existingUids = <String>{
    record.deviceUid.trim(),
    (record.guardianInfo.deviceUid ?? '').trim(),
    (record.guardian2Info?.deviceUid ?? '').trim(),
  }..removeWhere((e) => e.isEmpty);

  if (existingUids.contains(normalizedNew)) {
    showSnack(
      isEs
          ? 'Ese dispositivo ya pertenece a este paciente.'
          : 'That device already belongs to this patient.',
      error: true,
    );
    return null;
  }

  PatientFullRecord updated;
  switch (target) {
    case ReassignTarget.patient:
      updated = record.copyWith(deviceUid: normalizedNew);
      break;
    case ReassignTarget.guardian1:
      updated = record.copyWith(
        guardianInfo: record.guardianInfo.copyWith(deviceUid: normalizedNew),
      );
      break;
    case ReassignTarget.guardian2:
      final g2 = record.guardian2Info;
      updated = g2 == null
          ? record
          : record.copyWith(
              guardian2Info: g2.copyWith(deviceUid: normalizedNew),
            );
      break;
  }

  if (!context.mounted) return null;

  final writeOk = await showNfcGuidedWrite(
    context,
    title: title,
    instruction: isEs
        ? 'Acerque el MISMO dispositivo nuevo para grabarlo'
        : 'Bring the SAME new device close to write it',
    write: () async {
      final service = NfcPayloadService(codec: codec);
      if (target == ReassignTarget.patient) {
        await service.writeTriagePayload(
          NfcTriagePayload.buildPatientPayload(record: updated),
          expectedUid: normalizedNew,
        );
      } else {
        await service.writeGuardianRecord(
          buildFit: guardianFitBuilder(record: updated, codec: codec),
          expectedUid: normalizedNew,
        );
      }
    },
  );

  return writeOk ? updated : null;
}
