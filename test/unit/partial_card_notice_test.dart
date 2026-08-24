// test/unit/partial_card_notice_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/core/nfc/nfc_guardian_payload.dart';
import 'package:health_without_borders_frontend/src/core/nfc/partial_card_notice.dart';

GuardianPayloadFit _fit({
  int keptConsultations = 0,
  int totalConsultations = 0,
  int keptVaccines = 0,
  int totalVaccines = 0,
}) {
  return GuardianPayloadFit(
    payload: const <String, dynamic>{},
    includedConsultations: keptConsultations,
    includedVaccines: keptVaccines,
    totalConsultations: totalConsultations,
    totalVaccines: totalVaccines,
    estimatedBytes: 100,
    fits: true,
  );
}

void main() {
  group('partialCardNoticeMessage', () {
    test('nombra solo las consultas cuando solo se recortaron consultas', () {
      final message = partialCardNoticeMessage(
        _fit(keptConsultations: 1, totalConsultations: 4),
        true,
      );
      expect(message, contains('3 consulta(s)'));
      expect(message, isNot(contains('vacuna')));
    });

    test('nombra solo las vacunas cuando solo se recortaron vacunas', () {
      final message = partialCardNoticeMessage(
        _fit(keptVaccines: 2, totalVaccines: 5),
        true,
      );
      expect(message, contains('3 vacuna(s)'));
      expect(message, isNot(contains('consulta')));
    });

    test('une ambos con "y" en español', () {
      final message = partialCardNoticeMessage(
        _fit(
          keptConsultations: 1,
          totalConsultations: 3,
          keptVaccines: 0,
          totalVaccines: 1,
        ),
        true,
      );
      expect(message, contains('2 consulta(s) y 1 vacuna(s)'));
    });

    test('une ambos con "and" en inglés', () {
      final message = partialCardNoticeMessage(
        _fit(
          keptConsultations: 1,
          totalConsultations: 3,
          keptVaccines: 0,
          totalVaccines: 1,
        ),
        false,
      );
      expect(message, contains('2 consultation(s) and 1 vaccine(s)'));
    });

    test('aclara que lo recortado sigue en el servidor (es)', () {
      final message = partialCardNoticeMessage(
        _fit(keptConsultations: 1, totalConsultations: 2),
        true,
      );
      expect(message, contains('siguen en el servidor'));
      expect(message, contains('más recientes'));
    });

    test('aclara que lo recortado sigue en el servidor (en)', () {
      final message = partialCardNoticeMessage(
        _fit(keptConsultations: 1, totalConsultations: 2),
        false,
      );
      expect(message, contains('still on the server'));
      expect(message, contains('most recent'));
    });

    test('no rompe cuando no se recortó nada', () {
      final message = partialCardNoticeMessage(_fit(), true);
      expect(message, isNotEmpty);
    });
  });
}
