import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum RideListingKind { offer, request }

class DashboardRideTarget {
  const DashboardRideTarget.listing(this.kind, String id)
    : listingId = id,
      roundTripId = null;

  const DashboardRideTarget.roundTrip(this.kind, String id)
    : listingId = null,
      roundTripId = id;

  final RideListingKind kind;
  final String? listingId;
  final String? roundTripId;
}

class DashboardRideNavigation extends InheritedWidget {
  const DashboardRideNavigation({
    super.key,
    required this.target,
    required this.openDashboardRide,
    required super.child,
  });

  final ValueListenable<DashboardRideTarget?> target;
  final ValueChanged<DashboardRideTarget> openDashboardRide;

  static DashboardRideNavigation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DashboardRideNavigation>();

  @override
  bool updateShouldNotify(DashboardRideNavigation oldWidget) =>
      target != oldWidget.target;
}
