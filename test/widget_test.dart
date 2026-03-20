import 'package:flutter_test/flutter_test.dart';

import 'package:health_without_borders_frontend/src/app.dart';

void main() {
  testWidgets('renders home actions', (tester) async {
    await tester.pumpWidget(HealthWithoutBordersApp());

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Read NFC'), findsOneWidget);
    expect(find.text('Register NFC'), findsOneWidget);
  });
}
