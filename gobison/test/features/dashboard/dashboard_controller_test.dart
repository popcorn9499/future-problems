import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/features/dashboard/dashboard_controller.dart';
import 'package:gobison/features/dashboard/dashboard_service.dart';

/// Replaces the network layer so the controller is tested on its own.
/// Set [onFetchAgreements] in each test to decide what the "server" does.
class FakeDashboardService extends DashboardService {
  FakeDashboardService()
    : super(
        client: MockClient((_) async => http.Response('[]', 200)),
        useMock: false,
      );

  Future<List<Map<String, dynamic>>> Function()? onFetchAgreements;

  @override
  Future<List<Map<String, dynamic>>> fetchAgreements() {
    return onFetchAgreements!();
  }
}

Map<String, dynamic> _agreementJson({
  int id = 1,
  List<String> days = const ['MONDAY', 'WEDNESDAY'],
}) => {
  'id': id,
  'origin': 'Steinbach',
  'destination': 'University of Manitoba',
  'departureTime': '07:45',
  'daysOfWeek': days,
  'status': 'ACTIVE',
  'drivers': [
    {
      'id': 'd$id',
      'firstName': 'Dana',
      'lastName': 'Driver',
      'address': '1 Main St',
    },
  ],
  'passengers': [
    {
      'id': 'p$id',
      'firstName': 'Pat',
      'lastName': 'Passenger',
      'address': '2 Oak Ave',
    },
  ],
};

void main() {
  group('DashboardController', () {
    late FakeDashboardService dashboardService;
    late DashboardController controller;

    setUp(() {
      dashboardService = FakeDashboardService();
      controller = DashboardController(dashboardService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts idle with no data and no error', () {
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.agreements, isEmpty);
    });

    test('loadAgreements stores the agreements after success', () async {
      dashboardService.onFetchAgreements = () async => [
        _agreementJson(id: 1),
        _agreementJson(id: 2),
      ];

      await controller.loadAgreements();

      expect(controller.agreements.map((a) => a.id), ['1', '2']);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('an empty response is a success, not an error', () async {
      dashboardService.onFetchAgreements = () async => [];

      await controller.loadAgreements();

      expect(controller.agreements, isEmpty);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('sets loading while agreements are being fetched', () async {
      final completer = Completer<List<Map<String, dynamic>>>();
      dashboardService.onFetchAgreements = () => completer.future;

      final future = controller.loadAgreements();

      expect(controller.isLoading, isTrue);

      completer.complete([_agreementJson()]);
      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.agreements, hasLength(1));
    });

    test('notifies listeners when loading starts and when it finishes', () async {
      final loadingStates = <bool>[];
      controller.addListener(() => loadingStates.add(controller.isLoading));
      dashboardService.onFetchAgreements = () async => [_agreementJson()];

      await controller.loadAgreements();

      expect(loadingStates, [true, false]);
    });

    const expectedMessages = {
      401: 'Your session has expired. Please log in again.',
      429: 'Too many requests. Please try again in a moment.',
      500: 'It\'s not you, it\'s us. Please try again later.',
    };

    expectedMessages.forEach((status, message) {
      test('loadAgreements displays the right message for HTTP $status', () async {
        dashboardService.onFetchAgreements = () async {
          throw Exception('Loading ride agreements failed ($status): ');
        };

        await controller.loadAgreements();

        expect(controller.errorMessage, message);
        expect(controller.agreements, isEmpty);
        expect(controller.isLoading, isFalse);
      });
    });

    test('loadAgreements displays the generic message for other failures', () async {
      dashboardService.onFetchAgreements = () async {
        throw Exception('offline');
      };

      await controller.loadAgreements();

      expect(
        controller.errorMessage,
        'Unable to load your rides. Please try again later.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('loadAgreements displays the generic message for malformed agreements', () async {
      dashboardService.onFetchAgreements = () async => [
        {'unexpected': true},
      ];

      await controller.loadAgreements();

      expect(
        controller.errorMessage,
        'Unable to load your rides. Please try again later.',
      );
      expect(controller.agreements, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('clears an earlier error when a retry succeeds', () async {
      dashboardService.onFetchAgreements = () async {
        throw Exception('Loading ride agreements failed (500): ');
      };
      await controller.loadAgreements();
      expect(controller.errorMessage, isNotNull);

      dashboardService.onFetchAgreements = () async => [_agreementJson()];
      await controller.loadAgreements();

      expect(controller.errorMessage, isNull);
      expect(controller.agreements, hasLength(1));
    });

    test('keeps previously loaded agreements when a refresh fails', () async {
      dashboardService.onFetchAgreements = () async => [_agreementJson()];
      await controller.loadAgreements();

      dashboardService.onFetchAgreements = () async {
        throw Exception('Loading ride agreements failed (500): ');
      };
      await controller.loadAgreements();

      expect(controller.agreements, hasLength(1));
      expect(controller.errorMessage, isNotNull);
    });
  });

  group('DashboardController with the real service', () {
    // These two go through the real DashboardService so the link between its
    // exception text and extractErrorCode is exercised, which a fake that
    // throws a hand-written string cannot check.
    DashboardController controllerFor(http.Response Function() respond) {
      final controller = DashboardController(
        DashboardService(
          client: MockClient((request) async => respond()),
          useMock: false,
        ),
      );
      addTearDown(controller.dispose);
      return controller;
    }

    test('an HTTP 401 response becomes the session-expired message', () async {
      final controller = controllerFor(() => http.Response('', 401));

      await controller.loadAgreements();

      expect(
        controller.errorMessage,
        'Your session has expired. Please log in again.',
      );
    });

    test('a 200 response with agreements is parsed into models', () async {
      final controller = controllerFor(
        () => http.Response(jsonEncode([_agreementJson(id: 7)]), 200),
      );

      await controller.loadAgreements();

      expect(controller.agreements.single.id, '7');
      expect(controller.agreements.single.drivers.single.fullName, 'Dana Driver');
      expect(controller.errorMessage, isNull);
    });
  });

  group('getFilteredAgreements', () {
    late FakeDashboardService dashboardService;
    late DashboardController controller;

    setUp(() async {
      dashboardService = FakeDashboardService()
        ..onFetchAgreements = () async => [
          _agreementJson(id: 1, days: ['MONDAY', 'WEDNESDAY']),
          _agreementJson(id: 2, days: ['TUESDAY', 'THURSDAY']),
          _agreementJson(id: 3, days: ['FRIDAY']),
        ];
      controller = DashboardController(dashboardService);
      await controller.loadAgreements();
    });

    tearDown(() {
      controller.dispose();
    });

    List<String> idsFor(Set<String> days) =>
        controller.getFilteredAgreements(days).map((a) => a.id).toList();

    test('returns everything when no days are selected', () {
      expect(idsFor({}), ['1', '2', '3']);
    });

    test('returns agreements that run on the selected day', () {
      expect(idsFor({'MONDAY'}), ['1']);
      expect(idsFor({'FRIDAY'}), ['3']);
    });

    test('matches if any selected day overlaps, not all of them', () {
      expect(idsFor({'MONDAY', 'THURSDAY'}), ['1', '2']);
    });

    test('returns an empty list when nothing runs on the selected days', () {
      expect(idsFor({'SUNDAY'}), isEmpty);
    });

    test('does not modify the underlying agreements list', () {
      idsFor({'MONDAY'});

      expect(controller.agreements, hasLength(3));
    });
  });
}