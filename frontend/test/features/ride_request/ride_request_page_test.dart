import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/core/widgets/pickup_map_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/features/ride_request/ride_request_service.dart';
import 'package:gobison/features/ride_request/presentation/ride_request_page.dart';

void main() {
  const testUserId = '123';

  Widget createTestWidget() {
    return const MaterialApp(home: RideRequestPage(userId: testUserId));
  }

  Future<void> enterRequiredFields(WidgetTester tester) async {
    final textFields = find.byType(TextFormField);

    await tester.ensureVisible(textFields.at(0));
    await tester.enterText(textFields.at(0), 'Toronto');

    await tester.ensureVisible(textFields.at(1));
    await tester.enterText(textFields.at(1), '123 Main Street');

    await tester.pumpAndSettle();
  }

  Future<void> selectRideType(WidgetTester tester, String rideType) async {
    final dropdown = find.byType(DropdownButton<String>);

    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text(rideType).last);
    await tester.pumpAndSettle();
  }

  Future<void> selectTime(WidgetTester tester, {int index = 0}) async {
    final timeSelector = find.text('Select time').at(index);

    await tester.ensureVisible(timeSelector);
    await tester.tap(timeSelector);
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerDialog), findsOneWidget);
  }

  Future<void> confirmTimePicker(WidgetTester tester) async {
    final okButton = find.descendant(of: find.byType(TimePickerDialog), matching: find.text('OK'));

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

  Future<void> submitRideWithClient(
    WidgetTester tester,
    http.Client client, {
    bool pickLocation = false,
  }) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: RideRequestPage(
          userId: testUserId,
          service: RideRequestService(client: client),
        ),
      ),
    );
    if (pickLocation) {
      await tester.enterText(find.byType(TextFormField).first, 'Winnipeg');
      final pick = find.descendant(
        of: find.byType(TextFormField).at(1),
        matching: find.byTooltip('Pick on map'),
      );
      await tester.ensureVisible(pick);
      await tester.tap(pick);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(FlutterMap)).width, 680);
      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Street Address *'), findsOneWidget);

      await tester.tap(pick);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Use this location')).onPressed, isNull);
      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Use this location'));
      await tester.pumpAndSettle();
      expect(find.text('Pickup label'), findsOneWidget);
      await tester.tap(find.text('Use street address'));
      await tester.pumpAndSettle();
      expect(find.text('Street Address *'), findsOneWidget);

      await tester.tap(pick);
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Use this location'));
      await tester.pumpAndSettle();
    } else {
      await enterRequiredFields(tester);
    }
    await tester.ensureVisible(find.text('Select time'));
    await tester.tap(find.text('Select time'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(TimePickerDialog), matching: find.text('OK')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mon'));
    await tester.tap(find.text('Mon'));
    final submitButton = find.text('Submit Ride Offer');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
  }

  group('RideRequestPage', () {
    testWidgets('pickup map actions fit on a narrow screen', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: PickupMapDialog()));
      await tester.pumpAndSettle();

      final map = find.byType(FlutterMap);
      expect(tester.getSize(map).width, lessThan(360));
      await tester.tapAt(tester.getCenter(map));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Cancel').hitTestable(), findsOneWidget);
      expect(find.text('Use this location').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('submits a map pickup with no label', (tester) async {
      final writes = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        writes.add(body);
        return http.Response(jsonEncode({
          ...body,
          'requestId': 'ride123',
          'userId': testUserId,
          'streetAddress': 'Pinned pickup',
        }), 201);
      });

      await submitRideWithClient(tester, client, pickLocation: true);

      expect(writes.single['streetAddress'], isEmpty);
      final location = writes.single['location'] as Map<String, dynamic>;
      expect(location['latitude'], closeTo(49.8951, 0.001));
      expect(location['longitude'], closeTo(-97.1384, 0.001));
      expect(find.text('Street Address *'), findsOneWidget);
    });

    testWidgets('displays the ride request page and form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Request a Ride'), findsOneWidget);

      expect(find.text('Let fellow Bisons know when and where you need a ride.'), findsOneWidget);

      expect(find.text('City *'), findsOneWidget);
      expect(find.text('Street Address *'), findsOneWidget);
      expect(find.text('Ride Type *'), findsOneWidget);
      expect(find.text('To campus'), findsOneWidget);
      expect(find.text('Arrive at campus by *'), findsOneWidget);
      expect(find.text('Select time'), findsOneWidget);
      expect(find.text('Days of the week *'), findsOneWidget);
      expect(find.text('Additional Description'), findsOneWidget);

      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Submit Ride Offer'), findsOneWidget);

      expect(
        find.text('GoBison • Ride with the herd. © OpenStreetMap contributors'),
        findsOneWidget,
      );
    });

    testWidgets('displays the correct text field hints', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Enter your city'), findsOneWidget);
      expect(find.text('Enter your address'), findsOneWidget);
      expect(find.text('Enter any additional details'), findsOneWidget);
    });

    testWidgets('displays all weekdays as selectable chips', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
    });

    testWidgets('allows selecting a weekday', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final mondayChip = find.widgetWithText(FilterChip, 'Mon');

      await tester.ensureVisible(mondayChip);
      await tester.tap(mondayChip);
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(mondayChip).selected, isTrue);
    });

    testWidgets('allows deselecting a previously selected weekday', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final mondayChip = find.widgetWithText(FilterChip, 'Mon');

      await tester.ensureVisible(mondayChip);
      await tester.tap(mondayChip);
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(mondayChip).selected, isTrue);

      await tester.tap(mondayChip);
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(mondayChip).selected, isFalse);
    });

    testWidgets('allows selecting multiple weekdays', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final mondayChip = find.widgetWithText(FilterChip, 'Mon');
      final wednesdayChip = find.widgetWithText(FilterChip, 'Wed');

      await tester.ensureVisible(mondayChip);
      await tester.tap(mondayChip);
      await tester.pumpAndSettle();

      await tester.ensureVisible(wednesdayChip);
      await tester.tap(wednesdayChip);
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(mondayChip).selected, isTrue);

      expect(tester.widget<FilterChip>(wednesdayChip).selected, isTrue);
    });

    testWidgets('shows validation errors when city is empty', (WidgetTester tester) async {
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

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your city'), 'Toronto');

      final submitButton = find.text('Submit Ride Offer');

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter Street Address'), findsOneWidget);
    });

    testWidgets('shows validation errors when city contains only whitespace', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your city'), '   ');

      final submitButton = find.text('Submit Ride Offer');

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter City'), findsOneWidget);
    });

    testWidgets('shows validation errors when street address contains only whitespace', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your city'), 'Toronto');

      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your address'), '   ');

      final submitButton = find.text('Submit Ride Offer');

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter Street Address'), findsOneWidget);
    });

    testWidgets('allows entering an optional description', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final descriptionField = find.byType(TextFormField).last;

      await tester.ensureVisible(descriptionField);

      await tester.enterText(descriptionField, 'I need a ride every weekday.');

      await tester.pumpAndSettle();

      expect(find.text('I need a ride every weekday.'), findsOneWidget);
    });

    testWidgets('does not show validation error for empty optional description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final descriptionField = find.byType(TextFormField).last;

      await tester.ensureVisible(descriptionField);
      await tester.enterText(descriptionField, '');

      await tester.pumpAndSettle();

      expect(find.text('Please enter Additional Description'), findsNothing);
    });

    testWidgets('submit button is initially enabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Submit Ride Offer'),
      );

      expect(button.onPressed, isNotNull);
    });

    testWidgets('reset button is initially enabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Reset'));

      expect(button.onPressed, isNotNull);
    });

    testWidgets('reset displays confirmation message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tapReset(tester);

      expect(find.text('Form has been reset.'), findsOneWidget);
    });

    testWidgets('reset clears all text fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await enterRequiredFields(tester);

      final descriptionField = find.byType(TextFormField).last;

      await tester.enterText(descriptionField, 'Test description');

      await tester.pumpAndSettle();

      await tapReset(tester);

      expect(find.text('Toronto'), findsNothing);
      expect(find.text('123 Main Street'), findsNothing);
      expect(find.text('Test description'), findsNothing);

      expect(find.text('Enter your city'), findsOneWidget);
      expect(find.text('Enter your address'), findsOneWidget);
      expect(find.text('Enter any additional details'), findsOneWidget);
    });

    testWidgets('reset deselects all weekdays', (WidgetTester tester) async {
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

      expect(tester.widget<FilterChip>(mondayChip).selected, isFalse);

      expect(tester.widget<FilterChip>(wednesdayChip).selected, isFalse);
    });

    group('Time Selection', () {
      testWidgets('displays time picker when arrival time is tapped', (WidgetTester tester) async {
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

      testWidgets('allows selecting a departure time', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'From campus');

        await selectTime(tester);
        await confirmTimePicker(tester);

        expect(find.text('Select time'), findsNothing);
      });

      testWidgets('allows selecting both round trip times', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Round trip');

        expect(find.text('Select time'), findsNWidgets(2));

        await selectTime(tester);
        await confirmTimePicker(tester);

        expect(find.text('Select time'), findsOneWidget);

        await selectTime(tester);
        await confirmTimePicker(tester);

        expect(find.text('Select time'), findsNothing);
      });

      testWidgets('validates departure time must be after arrival time', (
        WidgetTester tester
      ) async {
        await tester.pumpWidget(createTestWidget());
        await selectRideType(tester, 'Round trip');
        await enterRequiredFields(tester);
        final mondayChip = find.widgetWithText(FilterChip, 'Mon');
        await tester.ensureVisible(mondayChip);
        await tester.tap(mondayChip);
        await tester.pumpAndSettle();
        await selectTime(tester, index: 0);

        final arrivalFields = find.descendant(
          of: find.byType(TimePickerDialog),
          matching: find.byType(TextField),
        );

        await tester.enterText(arrivalFields.first, '10');
        await tester.enterText(arrivalFields.last, '00');
        await confirmTimePicker(tester);
        await selectTime(tester, index: 0);

        final departureFields = find.descendant(
          of: find.byType(TimePickerDialog),
          matching: find.byType(TextField),
        );

        await tester.enterText(departureFields.first, '08');
        await tester.enterText(departureFields.last, '00');
        final amButton = find.text('AM');

        if (amButton.evaluate().isNotEmpty) {
          await tester.tap(amButton);
          await tester.pumpAndSettle();
        }

        await confirmTimePicker(tester);
        final submitButton = find.text('Submit Ride Offer');

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pump();

        await tester.pump(const Duration(seconds: 1));

        expect(
          find.text('Your campus departure must be after your campus arrival.'),
          findsOneWidget,
        );
      },);
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

        expect(find.text('Choose when you need to arrive at campus.'), findsOneWidget);
      });

      testWidgets('shows validation message when departure time is not selected', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'From campus');

        await enterRequiredFields(tester);

        final mondayChip = find.widgetWithText(FilterChip, 'Mon');

        await tester.ensureVisible(mondayChip);
        await tester.tap(mondayChip);
        await tester.pumpAndSettle();

        final submitButton = find.text('Submit Ride Offer');

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(find.text('Choose when you want to leave campus.'), findsOneWidget);
      });

      testWidgets('requires both times for round trip', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Round trip');

        await enterRequiredFields(tester);

        final mondayChip = find.widgetWithText(FilterChip, 'Mon');

        await tester.ensureVisible(mondayChip);
        await tester.tap(mondayChip);
        await tester.pumpAndSettle();

        final submitButton = find.text('Submit Ride Offer');

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(find.text('Choose when you need to arrive at campus.'), findsOneWidget);
      });

      testWidgets('validates departure time after arrival time is selected', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Round trip');

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

        expect(find.text('Choose when you want to leave campus.'), findsOneWidget);
      });
    });
    testWidgets('reset clears selected arrival time', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await selectTime(tester);
      await confirmTimePicker(tester);

      expect(find.text('Select time'), findsNothing);

      await tapReset(tester);

      expect(find.text('Select time'), findsOneWidget);
      expect(find.text('To campus'), findsOneWidget);
    });

    testWidgets('reset clears both round trip times and ride type', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await selectRideType(tester, 'Round trip');
      await selectTime(tester, index: 0);
      await confirmTimePicker(tester);
      await selectTime(tester, index: 0);
      await confirmTimePicker(tester);

      expect(find.text('Select time'), findsNothing);

      await tapReset(tester);

      expect(find.text('To campus'), findsOneWidget);
      expect(find.text('Select time'), findsOneWidget);
      expect(find.text('Arrive at campus by *'), findsOneWidget);
      expect(find.text('Leave campus at *'), findsNothing);
    });

    testWidgets('reset clears validation errors', (WidgetTester tester) async {
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
      testWidgets('defaults to arriving ride type', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Arrive at campus by *'), findsOneWidget);
        expect(find.text('Select time'), findsOneWidget);

        expect(find.text('Leave campus at *'), findsNothing);
      });

      testWidgets('displays departure time selector when departing is selected', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'From campus');

        expect(find.text('Leave campus at *'), findsOneWidget);

        expect(find.text('Arrive at campus by *'), findsNothing);

        expect(find.text('Select time'), findsOneWidget);
      });

      testWidgets('displays both time selectors for round trip', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'Round trip');

        expect(find.text('Arrive at campus by *'), findsOneWidget);
        expect(find.text('Leave campus at *'), findsOneWidget);

        expect(find.text('Select time'), findsNWidgets(2));
      });

      testWidgets('clears departure time when switching to arriving', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        await selectRideType(tester, 'From campus');

        await selectTime(tester);
        await confirmTimePicker(tester);

        await selectRideType(tester, 'To campus');

        expect(find.text('Arrive at campus by *'), findsOneWidget);

        expect(find.text('Select time'), findsOneWidget);
        expect(find.text('Leave campus at *'), findsNothing);
      });

      testWidgets('clears arrival time when switching to departing', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        await selectTime(tester);
        await confirmTimePicker(tester);

        await selectRideType(tester, 'From campus');

        expect(find.text('Leave campus at *'), findsOneWidget);

        expect(find.text('Select time'), findsOneWidget);

        expect(find.text('Arrive at campus by *'), findsNothing);
      });
    });

    group('address lookup responses', () {
      testWidgets('shows an invalid address popup and preserves form input', (
        WidgetTester tester,
      ) async {
        var serviceCallCount = 0;
        final client = MockClient((_) async {
          serviceCallCount++;
          return http.Response(jsonEncode({'code': 'INVALID_ADDRESS'}), 422);
        });

        await submitRideWithClient(tester, client);

        expect(serviceCallCount, 1);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(
              'We couldn’t locate that address in Canada. Check the street address and city and try again.',
            ),
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextFormField);
        expect(tester.widget<TextFormField>(textFields.at(0)).controller!.text, 'Toronto');
        expect(tester.widget<TextFormField>(textFields.at(1)).controller!.text, '123 Main Street');
      });

      testWidgets('shows a temporary lookup error and preserves form input', (
        WidgetTester tester,
      ) async {
        var serviceCallCount = 0;
        final client = MockClient((_) async {
          serviceCallCount++;
          return http.Response(jsonEncode({'code': 'GEOCODING_UNAVAILABLE'}), 503);
        });

        await submitRideWithClient(tester, client);

        expect(serviceCallCount, 1);
        expect(find.byType(AlertDialog), findsNothing);
        expect(
          find.text('Address lookup is temporarily unavailable. Please try again.'),
          findsOneWidget,
        );
        final textFields = find.byType(TextFormField);
        expect(tester.widget<TextFormField>(textFields.at(0)).controller!.text, 'Toronto');
        expect(tester.widget<TextFormField>(textFields.at(1)).controller!.text, '123 Main Street');
      });

      testWidgets('clears form input after a successful submission', (WidgetTester tester) async {
        var serviceCallCount = 0;
        final client = MockClient((_) async {
          serviceCallCount++;
          return http.Response(
            jsonEncode({
              'requestId': 'ride123',
              'userId': testUserId,
              'rideType': 'arriving',
              'city': 'Toronto',
              'streetAddress': '123 Main Street',
              'arrivalTime': '07:15',
              'daysOfWeek': ['MONDAY'],
            }),
            201,
          );
        });

        await submitRideWithClient(tester, client);

        expect(serviceCallCount, 1);
        expect(find.byType(AlertDialog), findsNothing);
        final textFields = find.byType(TextFormField);
        expect(tester.widget<TextFormField>(textFields.at(0)).controller!.text, isEmpty);
        expect(tester.widget<TextFormField>(textFields.at(1)).controller!.text, isEmpty);
      });
    });
  });
}
