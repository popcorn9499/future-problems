import 'package:flutter/material.dart';

import '../../core/models/ride_agreement.dart';
import '../auth/auth_controller.dart' show extractErrorCode;

import 'dashboard_response_handler.dart';
import 'dashboard_service.dart';

enum TicketFilter { all, agreements, waitingOffers, waitingRequests }

class DashboardController extends ChangeNotifier {
  DashboardController(this._dashboardService);

  final DashboardService _dashboardService;

  bool isLoading = false;
  String? errorMessage;
  List<RideAgreement> agreements = [];

  List<RideAgreement> getFilteredAgreements(
    Set<String> selectedDays, {
    TicketFilter kind = TicketFilter.all,
  }) {
    return agreements.where((agreement) {
      final waiting = agreement.id == null && agreement.status.toUpperCase() != 'CANCELLED';
      final matchesKind = switch (kind) {
        TicketFilter.all => true,
        TicketFilter.agreements => agreement.id != null,
        // An unjoined offer has only its owner as a driver; an unjoined request has
        // only its owner as a passenger.
        TicketFilter.waitingOffers =>
            waiting && agreement.drivers.isNotEmpty,
        TicketFilter.waitingRequests =>
            waiting && agreement.passengers.isNotEmpty,
      };
      final matchesDays = selectedDays.isEmpty ||
          agreement.daysOfWeek.any(selectedDays.contains);
      return matchesKind && matchesDays;
    }).toList();
  }

  Future<void> loadAgreements() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _dashboardService.fetchAgreements();
      agreements = data.map(RideAgreement.fromJson).toList();
    } catch (e) {
      errorMessage = DashboardResponseHandler.handleLoadError(
        extractErrorCode(e),
      );
    } finally {
      isLoading = false;
      if (hasListeners) notifyListeners();
    }
  }
}