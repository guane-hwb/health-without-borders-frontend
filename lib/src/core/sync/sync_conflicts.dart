// lib/src/core/sync/sync_conflicts.dart

/// Codes the backend puts in `conflicts` when it accepts a /sync (201) but
/// keeps its own value for part of the record. Everything else was saved.
abstract final class SyncConflictCode {
  /// The copy was based on an older recordVersion: the server kept its
  /// devices and guardians, merged allergies and background instead of
  /// replacing them, and took the new visits and vaccines.
  static const String staleBaseVersion = 'stale_payload_base_version';

  /// The copy carried a patient or guardian device that was already retired.
  static const String staleRetiredDeviceUid =
      'stale_payload_retired_device_uid';

  /// The record was matched by its patient device under another patientId:
  /// the guardians were not changed.
  static const String guardiansNotChanged =
      'guardians_not_changed_by_tag_resolved_sync';

  /// `visit_edit_not_applied:<encounterIdentifier>`: the server already had
  /// that visit and kept its own version, so the correction is not saved.
  static const String visitEditNotAppliedPrefix = 'visit_edit_not_applied:';

  /// `vaccination_edit_not_applied:<vaccinationId>`: same, for a vaccine.
  static const String vaccinationEditNotAppliedPrefix =
      'vaccination_edit_not_applied:';

  /// One line per kind of conflict in [codes], in the order they first
  /// appear. Visits and vaccines are counted, not listed by id.
  static List<String> describe(List<String> codes, {required bool isEs}) {
    final List<String> lines = <String>[];
    final Set<String> seen = <String>{};
    final int visits = codes
        .where((String c) => c.startsWith(visitEditNotAppliedPrefix))
        .length;
    final int vaccines = codes
        .where((String c) => c.startsWith(vaccinationEditNotAppliedPrefix))
        .length;

    for (final String code in codes) {
      final String kind = code.startsWith(visitEditNotAppliedPrefix)
          ? visitEditNotAppliedPrefix
          : code.startsWith(vaccinationEditNotAppliedPrefix)
          ? vaccinationEditNotAppliedPrefix
          : _isKnown(code)
          ? code
          : '';
      if (!seen.add(kind)) continue;
      lines.add(switch (kind) {
        // Also what a retry gets when the first attempt was saved but its
        // answer never arrived, hence "or an earlier attempt".
        staleBaseVersion =>
          isEs
              ? 'El registro ya había cambiado en el servidor (otra persona '
                    'lo actualizó o un envío anterior ya se había guardado). '
                    'Se conservaron sus guardianes y se unieron alergias y '
                    'antecedentes: lo que se quitó aquí puede seguir en el '
                    'servidor. Las consultas y vacunas nuevas sí se guardaron.'
              : 'The record had already changed on the server (someone else '
                    'updated it, or an earlier attempt had already been '
                    'saved). Its guardians were kept and allergies and history '
                    'were merged: anything removed here may still be on the '
                    'server. New visits and vaccines were saved.',
        staleRetiredDeviceUid =>
          isEs
              ? 'Esta copia tenía un dispositivo ya retirado, del paciente o '
                    'del guardián. El servidor conservó los dispositivos y los '
                    'guardianes actuales; el resto se guardó.'
              : 'This copy had a device that was already retired, a patient '
                    'or a guardian device. The server kept the current devices '
                    'and guardians; the rest was saved.',
        guardiansNotChanged =>
          isEs
              ? 'El dispositivo del paciente ya lo identificaba en otro '
                    'registro. Los guardianes no se cambiaron; el resto se '
                    'guardó.'
              : 'The patient device already identified this patient in '
                    'another record. The guardians were not changed; the rest '
                    'was saved.',
        visitEditNotAppliedPrefix => _editNotApplied(
          visits,
          isEs: isEs,
          oneEs: 'consulta',
          manyEs: 'consultas',
          oneEn: 'visit',
          manyEn: 'visits',
        ),
        vaccinationEditNotAppliedPrefix => _editNotApplied(
          vaccines,
          isEs: isEs,
          oneEs: 'vacuna',
          manyEs: 'vacunas',
          oneEn: 'vaccine',
          manyEn: 'vaccines',
        ),
        _ =>
          isEs
              ? 'El servidor no aplicó parte de los cambios; el resto se '
                    'guardó.'
              : 'The server did not apply part of the changes; the rest was '
                    'saved.',
      });
    }
    return lines;
  }

  /// What the user does next. [serverCopyShown]: the screen already shows
  /// the record as the server has it.
  static String nextStep({required bool serverCopyShown, required bool isEs}) {
    if (serverCopyShown) {
      return isEs
          ? 'Lo que ve es la versión del servidor: actualice el dispositivo '
                'del paciente y el del guardián.'
          : "What you see is the server's version: update the patient device "
                'and the guardian device.';
    }
    return isEs
        ? 'Escanee de nuevo el dispositivo del paciente para ver la versión '
              'del servidor y actualizar los dispositivos.'
        : "Scan the patient device again to see the server's version and "
              'update the devices.';
  }

  static bool _isKnown(String code) =>
      code == staleBaseVersion ||
      code == staleRetiredDeviceUid ||
      code == guardiansNotChanged;

  static String _editNotApplied(
    int count, {
    required bool isEs,
    required String oneEs,
    required String manyEs,
    required String oneEn,
    required String manyEn,
  }) {
    if (isEs) {
      return count == 1
          ? 'La corrección de una $oneEs ya registrada NO se guardó en el '
                'servidor: conserva su versión anterior.'
          : 'Las correcciones de $count $manyEs ya registradas NO se '
                'guardaron en el servidor: conservan su versión anterior.';
    }
    return count == 1
        ? 'The correction to a $oneEn already on the server was NOT saved: '
              'the server kept its earlier version.'
        : 'The corrections to $count $manyEn already on the server were NOT '
              'saved: the server kept their earlier versions.';
  }
}
