
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/ride_offer/presentation/ride_offer_page.dart';

void main() {
  const testUserId = '123';

  Widget createTestWidget() {
    return const MaterialApp(
      home: RideOfferPage(userId: testUserId),
    );
  }

  Future<void> selectPassengerCount(
    WidgetTester tester,
    int count,
  ) async {
    final dropdown = find.byType(DropdownButton<int>);

    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text('$count').last);
    await tester.pumpAndSettle();
  }

  Future<void> enterRequiredFields(
    WidgetTester tester,
  ) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your city'),
      'Toronto',
    );

    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        'Enter your starting address',
      ),
      '123 Main Street',
    );
  }

  Future<void> submitForm(WidgetTester tester) async {
    final submitButton = find.text('Submit Ride Offer');

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
  }

  group('RideOfferPage', () {

    testWidgets('displays the ride offer page and form fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Create Ride Offer'), findsOneWidget);
      expect(find.text('Offer a Ride'), findsOneWidget);

      expect(
        find.text(
          'Let fellow Bisons know when and where you have room for a ride.',
        ),
        findsOneWidget,
      );

      expect(find.text('City *'), findsOneWidget);
      expect(find.text('Street Address *'), findsOneWidget);

      expect(
        find.text('Desired campus arrival time *'),
        findsOneWidget,
      );

      expect(
        find.text('Number of Available Passenger Seats *'),
        findsOneWidget,
      );

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
        find.text('Enter your starting address'),
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

      await submitForm(tester);

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

      await submitForm(tester);

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

      await submitForm(tester);

      expect(find.text('Please enter City'), findsOneWidget);
    });

    testWidgets('shows validation errors when street address contains only whitespace', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your city'),
        'Toronto',
      );

      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Enter your starting address',
        ),
        '   ',
      );

      await submitForm(tester);

      expect(
        find.text('Please enter Street Address'),
        findsOneWidget,
      );
    });

    testWidgets('shows passenger validation when seats are not selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await enterRequiredFields(tester);
      await submitForm(tester);

      expect(
        find.text('Please select the number of available seats'),
        findsOneWidget,
      );
    });

    testWidgets('does not show validation errors when selecting passenger count', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await selectPassengerCount(tester, 3);

      expect(find.text('Please enter City'), findsNothing);

      expect(
        find.text('Please select the number of available seats'),
        findsNothing,
      );
    });

    testWidgets('does not show validation errors before submitting', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await selectPassengerCount(tester, 3);

      expect(find.text('Please enter City'), findsNothing);
      expect(find.text('Please enter Street Address'), findsNothing);

      expect(
        find.text('Please select the number of available seats'),
        findsNothing,
      );
    });

    testWidgets('allows selecting a passenger seat count', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await selectPassengerCount(tester, 3);

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('displays passenger seat options from 1 to 9', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final dropdown = find.byType(DropdownButton<int>);

      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      for (int i = 1; i <= 9; i++) {
        expect(find.text('$i'), findsWidgets);
      }
    });

    testWidgets('displays time picker when arrival time is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final timeSelector = find.text('Select arrival time');

      await tester.ensureVisible(timeSelector);
      await tester.tap(timeSelector);
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsOneWidget);
    });

    testWidgets('allows entering an arrival time using the time picker', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final timeSelector = find.text('Select arrival time');

      await tester.ensureVisible(timeSelector);
      await tester.tap(timeSelector);
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsOneWidget);

      final timePickerFields = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );

      expect(timePickerFields, findsWidgets);

      final hourField = timePickerFields.first;

      await tester.ensureVisible(hourField);
      await tester.tap(hourField);
      await tester.enterText(hourField, '08');
      await tester.pumpAndSettle();

      final okButton = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.text('OK'),
      );

      await tester.tap(okButton);
      await tester.pumpAndSettle();

      expect(find.text('Select arrival time'), findsNothing);
    });

    testWidgets('shows validation when arrival time is not selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await enterRequiredFields(tester);
      await selectPassengerCount(tester, 2);

      final mondayChip = find.widgetWithText(FilterChip, 'Mon');

      await tester.ensureVisible(mondayChip);
      await tester.tap(mondayChip);
      await tester.pumpAndSettle();

      await submitForm(tester);

      expect(
        find.text('Please select an arrival time.'),
        findsOneWidget,
      );
    });

    testWidgets('shows validation when no weekday is selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await enterRequiredFields(tester);
      await selectPassengerCount(tester, 2);

      final timeSelector = find.text('Select arrival time');

      await tester.ensureVisible(timeSelector);
      await tester.tap(timeSelector);
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await submitForm(tester);

      expect(
        find.text('Please select at least one day.'),
        findsOneWidget,
      );
    });

    testWidgets('allows entering an optional description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final descriptionField = find.widgetWithText(
        TextFormField,
        'Enter any additional details',
      );

      await tester.ensureVisible(descriptionField);

      await tester.enterText(
        descriptionField,
        'I can offer rides every weekday.',
      );

      await tester.pumpAndSettle();

      expect(
        find.text('I can offer rides every weekday.'),
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

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final resetButton = find.text('Reset');
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(find.text('Toronto'), findsNothing);
      expect(find.text('123 Main Street'), findsNothing);
      expect(find.text('Test description'), findsNothing);
      expect(find.text('Enter your city'), findsOneWidget);
      expect(find.text('Enter your starting address'), findsOneWidget,);
      expect(
        find.text('Enter any additional details'),
        findsOneWidget,
      );
    });

    testWidgets('reset clears passenger selection', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await selectPassengerCount(tester, 3);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(
        find.text('Select number of available seats'),
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

      await tester.tap(wednesdayChip);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilterChip>(mondayChip).selected,
        isFalse,
      );

      expect(
        tester.widget<FilterChip>(wednesdayChip).selected,
        isFalse,
      );
    });

    testWidgets('reset clears validation errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await submitForm(tester);

      expect(find.text('Please enter City'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter City'), findsNothing);
      expect(find.text('Please enter Street Address'), findsNothing);
      expect(
        find.text('Please select the number of available seats'),
        findsNothing,
      );
    });

    testWidgets('reset displays confirmation message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final resetButton = find.text('Reset');

      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(find.text('Form has been reset.'), findsOneWidget);
    });

  });
}
