// test/unit/reassign_device_dialog_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/features/nfc/presentation/profile/widgets/reassign_device_dialog.dart';

void main() {
  group('ReassignDeviceDialog — Unit Models & Enums', () {
    test('ReassignTarget enum has correct target values', () {
      expect(
        ReassignTarget.values,
        equals([
          ReassignTarget.patient,
          ReassignTarget.guardian1,
          ReassignTarget.guardian2,
        ]),
      );
    });

    test('ReassignSelection instantiates cleanly with provided properties', () {
      const selection = ReassignSelection(
        targets: [ReassignTarget.patient, ReassignTarget.guardian1],
        reason: 'damaged',
      );

      expect(
        selection.targets,
        equals([ReassignTarget.patient, ReassignTarget.guardian1]),
      );
      expect(selection.reason, equals('damaged'));
    });
  });
}
