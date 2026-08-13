// lib/src/core/nfc/partial_card_notice.dart

import 'nfc_guardian_payload.dart';

String partialCardNoticeMessage(GuardianPayloadFit fit, bool isEs) {
  final parts = <String>[];
  if (fit.droppedConsultations > 0) {
    parts.add(
      isEs
          ? '${fit.droppedConsultations} consulta(s)'
          : '${fit.droppedConsultations} consultation(s)',
    );
  }
  if (fit.droppedVaccines > 0) {
    parts.add(
      isEs
          ? '${fit.droppedVaccines} vacuna(s)'
          : '${fit.droppedVaccines} vaccine(s)',
    );
  }
  final dropped = parts.join(isEs ? ' y ' : ' and ');
  return isEs
      ? 'La tarjeta es pequeña: se guardaron las entradas más recientes. '
            'Quedaron fuera $dropped (siguen en el servidor).'
      : 'The card is small: the most recent entries were saved. '
            'Left off: $dropped (still on the server).';
}
