// lib/src/core/sync/sync_conflicts.dart

/// Codes the backend puts in `conflicts` when it accepts a /sync (201) but
/// keeps its own value for part of the record. Everything else was saved.
abstract final class SyncConflictCode {
  /// The copy was based on an older recordVersion: the server kept its
  /// wristband and guardians, merged allergies and background instead of
  /// replacing them, and took the new visits and vaccines.
  static const String staleBaseVersion = 'stale_payload_base_version';

  /// The copy carried a wristband or guardian card that was already retired.
  static const String staleRetiredDeviceUid =
      'stale_payload_retired_device_uid';

  /// The record was matched by its wristband under another patientId: the
  /// guardians were not changed.
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
              ? 'El registro ya había cambiado en el servidor (en otro '
                    'dispositivo o en un envío anterior). Se conservaron sus '
                    'acudientes y se unieron alergias y antecedentes: lo que '
                    'se quitó aquí puede seguir en el servidor. Las consultas '
                    'y vacunas nuevas sí se guardaron.'
              : 'The record had already changed on the server (on another '
                    'device or in an earlier attempt). Its guardians were '
                    'kept and allergies and history were merged: anything '
                    'removed here may still be on the server. New visits and '
                    'vaccines were saved.',
        staleRetiredDeviceUid =>
          isEs
              ? 'Esta copia tenía una pulsera o tarjeta ya retirada. El '
                    'servidor conservó la pulsera, los acudientes y sus '
                    'tarjetas actuales; el resto se guardó.'
              : 'This copy had a wristband or card that was already retired. '
                    'The server kept the current wristband, guardians and '
                    'cards; the rest was saved.',
        guardiansNotChanged =>
          isEs
              ? 'La pulsera ya identificaba a este paciente en otro registro. '
                    'Los acudientes no se cambiaron; el resto se guardó.'
              : 'The wristband already identified this patient in another '
                    'record. The guardians were not changed; the rest was '
                    'saved.',
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
          ? 'Lo que ve es la versión del servidor: actualice la pulsera y la '
                'tarjeta.'
          : "What you see is the server's version: update the wristband and "
                'card.';
    }
    return isEs
        ? 'Escanee de nuevo la pulsera para ver la versión del servidor y '
              'actualizar la pulsera y la tarjeta.'
        : "Scan the wristband again to see the server's version and update "
              'the wristband and card.';
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
