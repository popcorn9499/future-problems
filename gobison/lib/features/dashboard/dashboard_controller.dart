import 'package:flutter/material.dart';

import '../../core/models/ride_agreement.dart';
import '../auth/auth_controller.dart' show extractErrorCode;

import 'dashboard_response_handler.dart';
import 'dashboard_service.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._dashboardService);

  final DashboardService _dashboardService;

  bool isLoading = false;
  String? errorMessage;
  List<RideAgreement> agreements = [];

  List<RideAgreement> getFilteredAgreements(Set<String> selectedDays) {
  if (selectedDays.isEmpty) return agreements;

  return agreements.where((agreement) {
    return agreement.daysOfWeek.any(selectedDays.contains);
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
      notifyListeners();
    }
  }
}