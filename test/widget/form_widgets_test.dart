// test/widget/form_widgets_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_without_borders_frontend/src/shared/widgets/form_widgets.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

void main() {
  group('FormSectionHeader', () {
    testWidgets('renders icon and title, no subtitle when omitted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const FormSectionHeader(icon: Icons.person, title: 'Patient data'),
        ),
      );

      expect(find.text('Patient data'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(FormSectionHeader), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FormSectionHeader(
            icon: Icons.badge,
            title: 'Identification',
            subtitle: 'Fill in the ID details',
          ),
        ),
      );

      expect(find.text('Identification'), findsOneWidget);
      expect(find.text('Fill in the ID details'), findsOneWidget);
      expect(find.byIcon(Icons.badge), findsOneWidget);
    });
  });

  group('LabeledTextField', () {
    testWidgets(
      'renders with only required params (all optionals null/default)',
      (tester) async {
        final controller = TextEditingController();
        await tester.pumpWidget(
          _wrap(LabeledTextField(label: 'First name', controller: controller)),
        );

        expect(find.text('First name'), findsOneWidget);
        expect(find.text('*'), findsNothing);
        expect(find.byType(TextField), findsOneWidget);

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.maxLines, 1);
        expect(textField.keyboardType, TextInputType.text);
        expect(textField.decoration?.prefixIcon, isNull);
        expect(textField.decoration?.suffixIcon, isNull);
        expect(textField.decoration?.hintText, isNull);
        expect(find.text('helper'), findsNothing);
      },
    );

    testWidgets('shows hint, helper, prefix icon, suffix and required marker', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          LabeledTextField(
            label: 'Email',
            controller: controller,
            hint: 'name@example.com',
            helper: 'We will never share your email',
            prefixIcon: Icons.email,
            suffix: const Icon(Icons.check),
            requiredField: true,
            keyboardType: TextInputType.emailAddress,
            maxLines: 3,
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
      expect(find.text('We will never share your email'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'name@example.com');
      expect(textField.keyboardType, TextInputType.emailAddress);
      expect(textField.maxLines, 3);
    });

    testWidgets('typing invokes onChanged with the new text', (tester) async {
      final controller = TextEditingController();
      String? lastValue;
      await tester.pumpWidget(
        _wrap(
          LabeledTextField(
            label: 'Notes',
            controller: controller,
            onChanged: (v) => lastValue = v,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello world');
      expect(lastValue, 'hello world');
      expect(controller.text, 'hello world');
    });
  });

  group('LabeledDropdown', () {
    testWidgets(
      'renders all items and shows the current value, no required marker by default',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            LabeledDropdown<String>(
              label: 'Document type',
              value: 'CC',
              items: const {'CC': 'National ID', 'PA': 'Passport'},
              onChanged: (_) {},
            ),
          ),
        );

        expect(find.text('Document type'), findsOneWidget);
        expect(find.text('*'), findsNothing);
        expect(find.text('National ID'), findsOneWidget);
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      },
    );

    testWidgets('shows required marker when requiredField is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LabeledDropdown<String>(
            label: 'Document type',
            value: 'CC',
            items: const {'CC': 'National ID', 'PA': 'Passport'},
            onChanged: (_) {},
            requiredField: true,
          ),
        ),
      );

      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('selecting a different item invokes onChanged with its key', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(
          LabeledDropdown<String>(
            label: 'Document type',
            value: 'CC',
            items: const {'CC': 'National ID', 'PA': 'Passport'},
            onChanged: (v) => selected = v,
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Passport').last);
      await tester.pumpAndSettle();

      expect(selected, 'PA');
    });
  });

  group('LabeledDateField', () {
    testWidgets(
      'shows placeholder when value is null, no required marker by default',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            LabeledDateField(
              label: 'Date of birth',
              value: null,
              onChanged: (_) {},
            ),
          ),
        );

        expect(find.text('Date of birth'), findsOneWidget);
        expect(find.text('*'), findsNothing);
        expect(find.text('YYYY-MM-DD'), findsOneWidget);
      },
    );

    testWidgets(
      'formats a provided date with zero-padded month/day, shows required marker',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            LabeledDateField(
              label: 'Date of birth',
              value: DateTime(2024, 3, 5),
              onChanged: (_) {},
              requiredField: true,
            ),
          ),
        );

        expect(find.text('*'), findsOneWidget);
        expect(find.text('2024-03-05'), findsOneWidget);
      },
    );

    testWidgets('tapping opens the date picker; confirming calls onChanged', (
      tester,
    ) async {
      DateTime? picked;
      await tester.pumpWidget(
        _wrap(
          LabeledDateField(
            label: 'Date of birth',
            value: DateTime(2020, 1, 10),
            onChanged: (d) => picked = d,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
    });

    testWidgets(
      'tapping opens the date picker; cancelling does not call onChanged',
      (tester) async {
        DateTime? picked;
        await tester.pumpWidget(
          _wrap(
            LabeledDateField(
              label: 'Date of birth',
              value: null,
              onChanged: (d) => picked = d,
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Cancel'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(picked, isNull);
      },
    );
  });

  group('ChipSelector', () {
    testWidgets('renders label, options and required marker when requested', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ChipSelector<String>(
            label: 'Blood type',
            options: const {'O+': 'O+', 'A+': 'A+'},
            value: 'O+',
            onChanged: (_) {},
            requiredField: true,
          ),
        ),
      );

      expect(find.text('Blood type'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
      expect(find.text('O+'), findsOneWidget);
      expect(find.text('A+'), findsOneWidget);
    });

    testWidgets('hides the label row entirely when showLabel is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ChipSelector<String>(
            label: 'Blood type',
            options: const {'O+': 'O+', 'A+': 'A+'},
            value: 'O+',
            onChanged: (_) {},
            requiredField: true,
            showLabel: false,
          ),
        ),
      );

      expect(find.text('Blood type'), findsNothing);
      expect(find.text('*'), findsNothing);
      expect(find.text('O+'), findsOneWidget);
    });

    testWidgets('tapping an option invokes onChanged with its key', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(
          ChipSelector<String>(
            label: 'Blood type',
            options: const {'O+': 'O+', 'A+': 'A+', 'B+': 'B+'},
            value: 'O+',
            onChanged: (v) => selected = v,
          ),
        ),
      );

      await tester.tap(find.text('B+'));
      await tester.pumpAndSettle();

      expect(selected, 'B+');
    });
  });
}
