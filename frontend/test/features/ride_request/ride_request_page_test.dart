import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/ride_request/presentation/ride_request_page.dart';

void main() {
  const testUserId = '123';

  Widget createTestWidget() {
    return const MaterialApp(
      home: RideRequestPage(userId: testUserId),
    );
  }

  Future<void> enterRequiredFields(
    WidgetTester tester,
  ) async {
    final textFields = find.byType(TextFormField);

    await tester.ensureVisible(textFields.at(0));
    await tester.enterText(textFields.at(0), 'Toronto');

    await tester.ensureVisible(textFields.at(1));
    await tester.enterText(textFields.at(1), '123 Main Street');

    await tester.pumpAndSettle();
  }

  Future<void> selectRideType(
    WidgetTester tester,
    String rideType,
  ) async {
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    await tester.tap(find.text(rideType).last);
    await tester.pumpAndSettle();
  }

  Future<void> selectTime(
      WidgetTester tester, {
      int index = 0,
    }) async {
      final timeSelector = find.text('Select time').at(index);

      await tester.ensureVisible(timeSelector);
      await tester.tap(timeSelector);
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsOneWidget);
    }

  Future<void> confirmTimePicker(
    WidgetTester tester,
  ) async {
    final okButton = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.text('OK'),
    );

    await tester.tap(okButton);
    await tester.pumpAndSettle();
  }

  Future<void> tapReset(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    final resetButton = find.text('Reset');

    await tester.ensureVisible(resetButton);
    await tester.pumpAndSettle();

    await tester.tap(resetButton);
    await tester.pumpAndSettle();
  }

  group('RideRequestPage', () {

    testWidgets('displays the ride request page and form fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('Request a Ride'), findsOneWidget);

      expect(
        find.text('Let fellow Bisons when and where you need a ride.'),
        findsOneWidget,
      );

      expect(find.text('City *'), findsOneWidget);
      expect(find.text('Street Address *'), findsOneWidget);
      expect(find.text('Ride Type *'), findsOneWidget);
      expect(find.text('Arriving at Campus'), findsOneWidget);
      expect(
        find.text('Desired campus arrival time *'),
        findsOneWidget,
      );
      expect(find.text('Select time'), findsOneWidget);
      expect(find.text('Days of the week *'), findsOneWidget);
      expect(find.text('Additional Description'), findsOneWidget);

      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Submit Ride Offer'), findsOneWidget);

      expect(
        find.text('GoBison • Ride with the herd.'),
        findsOneWidget,
      );
    });

    testWidgets('displays the correct text field hints', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Enter your city'), findsOneWidget);
      expect(
        find.text('Enter your address'),
        findsOneWidget,
      );
      expect(
        find.text('Enter any additional details'),
        findsOneWidget,
      );
    });

    testWidgets('displays all weekdays as selectable chips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
    });

    testWidgets('allows selecting a weekday', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final mondayChip = find.widgetWithText(FilterChip, 'Mon');

      await tester.ensureVisible(mondayChip);
      await tester.tap(mondayChip);
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilterChip>(mondayChip).selected,
        isTrue,
      );
    });

    testWidgets('allows deselecting a previously selected weekday', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final mondayChip = find.widgetWithText(FilterChip, 'Mon');

      await tester.ensureVisible(mondayChip);
      await tester.tap(mondayChip);
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilterChip>(mondayChip).selected,
        isTrue,
      );

      await tester.tap(mondayChip);
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilterChip>(mondayChip).selected,
        isFalse,
      );
    });

    testWidgets('allows selecting multiple weekdays', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final mondayChip = find.widgetWithText(FilterChip, 'Mon');
      final wednesdayChip = find.widgetWithText(FilterChip, 'Wed');

      await tester.ensureVisible(mondayChip);
      await tester.tap(mondayChip);
      await tester.pumpAndSettle();

      await tester.ensureVisible(wednesdayChip);
      await tester.tap(wednesdayChip);
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilterChip>(mondayChip).selected,
        isTrue,
      );

      expect(
        tester.widget<FilterChip>(wednesdayChip).selected,
        isTrue,
      );
    });

    testWidgets('shows validation errors when city is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final submitButton = find.text('Submit Ride Offer');

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter City'), findsOneWidget);
    });

    testWidgets('shows validation errors when street address is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your city'),
        'Toronto',
      );

      final submitButton = find.text('Submit Ride Offer');

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter Street Address'),
        findsOneWidget,
      );
    });

    testWidgets('shows validation errors when city contains only whitespace', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your city'),
        '   ',
      );

      final submitButton = find.text('Submit Ride Offer');

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter City'), findsOneWidget);
    });

    testWidgets(
      'shows validation errors when street address contains only whitespace',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your city'),
          'Toronto',
        );

        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Enter your address',
          ),
          '   ',
        );

        final submitButton = find.text('Submit Ride Offer');

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(
          find.text('Please enter Street Address'),
          findsOneWidget,
        );
      },
    );

    testWidgets('allows entering an optional description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final descriptionField = find.byType(TextFormField).last;

      await tester.ensureVisible(descriptionField);

      await tester.enterText(
        descriptionField,
        'I need a ride every weekday.',
      );

      await tester.pumpAndSettle();

      expect(
        find.text('I need a ride every weekday.'),
        findsOneWidget,
      );
    });

    testWidgets('does not show validation error for empty optional description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final descriptionField = find.byType(TextFormField).last;

      await tester.ensureVisible(descriptionField);
      await tester.enterText(descriptionField, '');

      await tester.pumpAndSettle();

      expect(
        find.text('Please enter Additional Description'),
        findsNothing,
      );
    });

    testWidgets('submit button is initially enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(
          ElevatedButton,
          'Submit Ride Offer',
        ),
      );

      expect(button.onPressed, isNotNull);
    });

    testWidgets('reset button is initially enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Reset'),
      );

      expect(button.onPressed, isNotNull);
    });

    testWidgets('reset displays confirmation message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tapReset(tester);

      expect(
        find.text('Form has been reset.'),
        findsOneWidget,
      );
    });

    testWidgets('reset clears all text fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await enterRequiredFields(tester);

      final descriptionField = find.byType(TextFormField).last;

      await tester.enterText(
        descriptionField,
        'Test description',
      );

      await tester.pumpAndSettle();

      await tapReset(tester);

      expect(find.text('Toronto'), findsNothing);
      expect(find.text('123 Main Street'), findsNothing);
      expect(find.text('Test description'), findsNothing);

      expect(find.text('Enter your city'), findsOneWidget);
      expect(
        find.text('Enter your address'),
        findsOneWidget,
      );
      expect(
        find.text('Enter any additional details'),
        findsOneWidget,
      );
    });

    testWidgets('reset deselects all weekdays', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final mondayChip = find.widgetWithText(FilterChip, 'Mon');
      final wednesdayChip = find.widgetWithText(FilterChip, 'Wed');

      await tester.ensureVisible(mondayChip);
      await tester.tap(mondayChip);
      await tester.pumpAndSettle();

      await tester.ensureVisible(wednesdayChip);
      await tester.tap(wednesdayChip);
      await tester.pumpAndSettle();

      await tapReset(tester);

      expect(
        tester.widget<FilterChip>(mondayChip).selected,
        isFalse,
      );

      expect(
        tester.widget<FilterChip>(wednesdayChip).selected,
        isFalse,
      );
    });

    group('Time Selection', () {
      testWidgets('displays time picker when arrival time is tapped', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectTime(tester);

        expect(find.byType(TimePickerDialog), findsOneWidget);
      });

      testWidgets('allows entering an arrival time using the time picker', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectTime(tester);

        final timePickerFields = find.descendant(
          of: find.byType(TimePickerDialog),
          matching: find.byType(TextField),
        );

        expect(timePickerFields, findsWidgets);

        final hourField = timePickerFields.first;

        await tester.tap(hourField);
        await tester.enterText(hourField, '08');
        await tester.pumpAndSettle();

        await confirmTimePicker(tester);

        expect(find.text('Select time'), findsNothing);
      });

      testWidgets('allows selecting a departure time', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Departing from Campus');

        await selectTime(tester);
        await confirmTimePicker(tester);

        expect(find.text('Select time'), findsNothing);
      });

      testWidgets('allows selecting both round trip times', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Round Trip');

        expect(find.text('Select time'), findsNWidgets(2));

        await selectTime(tester);
        await confirmTimePicker(tester);

        expect(find.text('Select time'), findsOneWidget);

        await selectTime(tester);
        await confirmTimePicker(tester);

        expect(find.text('Select time'), findsNothing);
      });
    });

    group('Time Validation', () {
      testWidgets('shows validation message when arrival time is not selected', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await enterRequiredFields(tester);

        final mondayChip = find.widgetWithText(FilterChip, 'Mon');

        await tester.ensureVisible(mondayChip);
        await tester.tap(mondayChip);
        await tester.pumpAndSettle();

        final submitButton = find.text('Submit Ride Offer');

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(
          find.text('Please select an arrival time.'),
          findsOneWidget,
        );
      });

      testWidgets('shows validation message when departure time is not selected', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Departing from Campus');

        await enterRequiredFields(tester);

        final mondayChip = find.widgetWithText(FilterChip, 'Mon');

        await tester.ensureVisible(mondayChip);
        await tester.tap(mondayChip);
        await tester.pumpAndSettle();

        final submitButton = find.text('Submit Ride Offer');

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(
          find.text('Please select a departure time.'),
          findsOneWidget,
        );
      });

      testWidgets('requires both times for round trip', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Round Trip');

        await enterRequiredFields(tester);

        final mondayChip = find.widgetWithText(FilterChip, 'Mon');

        await tester.ensureVisible(mondayChip);
        await tester.tap(mondayChip);
        await tester.pumpAndSettle();

        final submitButton = find.text('Submit Ride Offer');

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(
          find.text('Please select an arrival time.'),
          findsOneWidget,
        );
      });

      testWidgets('validates departure time after arrival time is selected', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Round Trip');

        await enterRequiredFields(tester);

        final mondayChip = find.widgetWithText(FilterChip, 'Mon');

        await tester.ensureVisible(mondayChip);
        await tester.tap(mondayChip);
        await tester.pumpAndSettle();

        await selectTime(tester);
        await confirmTimePicker(tester);

        final submitButton = find.text('Submit Ride Offer');

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(
          find.text('Please select a departure time.'),
          findsOneWidget,
        );
      });
    });
    testWidgets('reset clears selected arrival time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await selectTime(tester);
      await confirmTimePicker(tester);

      expect(find.text('Select time'), findsNothing);

      await tapReset(tester);

      expect(find.text('Select time'), findsOneWidget);
      expect(find.text('Arriving at Campus'), findsOneWidget);
    });

    testWidgets('reset clears both round trip times and ride type', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await selectRideType(tester, 'Round Trip');
      await selectTime(tester, index: 0);
      await confirmTimePicker(tester);
      await selectTime(tester, index: 0);
      await confirmTimePicker(tester);

      expect(find.text('Select time'), findsNothing);

      await tapReset(tester);

      expect(find.text('Arriving at Campus'), findsOneWidget);
      expect(find.text('Select time'), findsOneWidget);
      expect(find.text('Campus arrival time *'), findsNothing);
      expect(find.text('Campus departure time *'), findsNothing);
    });

    testWidgets('reset clears validation errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final submitButton = find.text('Submit Ride Offer');

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter City'), findsOneWidget);

      await tapReset(tester);

      expect(find.text('Please enter City'), findsNothing);
      expect(find.text('Please enter Street Address'), findsNothing);
    });

    group('Ride Type Selection', () {
      testWidgets('defaults to arriving ride type', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Desired campus arrival time *'), findsOneWidget);
        expect(find.text('Select time'), findsOneWidget);

        expect(
          find.text('Desired campus departure time *'),
          findsNothing,
        );
      });

      testWidgets('displays departure time selector when departing is selected', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Departing from Campus');

        expect(
          find.text('Desired campus departure time *'),
          findsOneWidget,
        );

        expect(
          find.text('Desired campus arrival time *'),
          findsNothing,
        );

        expect(find.text('Select time'), findsOneWidget);
      });

      testWidgets('displays both time selectors for round trip', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Round Trip');

        expect(find.text('Campus arrival time *'), findsOneWidget);
        expect(find.text('Campus departure time *'), findsOneWidget);

        expect(find.text('Select time'), findsNWidgets(2));
      });

      testWidgets('clears departure time when switching to arriving', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Departing from Campus');

        await selectTime(tester);
        await confirmTimePicker(tester);

        await selectRideType(tester, 'Arriving at Campus');

        expect(
          find.text('Desired campus arrival time *'),
          findsOneWidget,
        );

        expect(find.text('Select time'), findsOneWidget);
        expect(
          find.text('Desired campus departure time *'),
          findsNothing,
        );
      });

      testWidgets('clears arrival time when switching to departing', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectTime(tester);
        await confirmTimePicker(tester);

        await selectRideType(tester, 'Departing from Campus');

        expect(
          find.text('Desired campus departure time *'),
          findsOneWidget,
        );

        expect(find.text('Select time'), findsOneWidget);

        expect(
          find.text('Desired campus arrival time *'),
          findsNothing,
        );
      });
    });
  });
}
