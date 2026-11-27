import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/avatar_color_option.dart';
import '../../../core/models/user.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/ride_agreement.dart';
import '../../../core/services/session_service.dart';
import '../../../core/navigation/tab_refresh.dart';
import '../../ride_request/presentation/edit_ride_request_dialog.dart';
import '../../ride_offer/ride_offer_service.dart';
import '../../ride_request/ride_request_service.dart';
import '../../profile/presentation/profile_popup.dart';
import '../../profile/profile_service.dart';
import '../dashboard_controller.dart';
import '../dashboard_service.dart';


const List<(String, String)> _weekdays = [
  ('MONDAY', 'M'),
  ('TUESDAY', 'T'),
  ('WEDNESDAY', 'W'),
  ('THURSDAY', 'T'),
  ('FRIDAY', 'F'),
];

List<(String, String)> _visibleDays(Iterable<String> savedDays) => [
  ..._weekdays,
  if (savedDays.contains('SATURDAY')) ('SATURDAY', 'Sa'),
  if (savedDays.contains('SUNDAY')) ('SUNDAY', 'Su'),
];

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.user,
    this.dashboardService,
    this.rideRequestService,
    this.rideOfferService,
    this.profileService,

  });

  final User user;
  final DashboardService? dashboardService;
  final RideRequestService? rideRequestService;
  final RideOfferService? rideOfferService;
  final ProfileService? profileService;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardService _dashboardService;
  late final DashboardController _dashboardController;

  final Set<String> _selectedDays = {};
  TicketFilter _kind = TicketFilter.all;
  late final _requests = widget.rideRequestService ?? RideRequestService();
  late final _offers = widget.rideOfferService ?? RideOfferService();
  late final _profiles = widget.profileService ?? ProfileService();

  bool _busy = false;

    @override
  void initState() {
    super.initState();

    _dashboardService = widget.dashboardService ?? DashboardService();
    _dashboardController = DashboardController(_dashboardService);
    _dashboardController.loadAgreements();
    TabRefresh.dashboard.addListener(_reloadAgreements);
  }

  void _reloadAgreements() => _dashboardController.loadAgreements();
  
  void _showProfile(AgreementMember member) =>
    showProfilePopup(context, member: member, currentUserId: widget.user.id, service: _profiles);

  @override
  void dispose() {
    TabRefresh.dashboard.removeListener(_reloadAgreements);
    _dashboardController.dispose();
    super.dispose();
  }

  List<List<RideAgreement>> _groupAgreements(
    List<RideAgreement> agreements,
  ) {
    final groups = <String, List<RideAgreement>>{};
    for (final agreement in agreements) {
      final key = agreement.roundTripId != null
          ? 'roundTrip:${agreement.roundTripId}'
          : 'listing:${agreement.listingId}';

      groups.putIfAbsent(key, () => []).add(agreement);
    }

    return groups.values.map((group) {
      group.sort((a, b) {
        if (a.rideType == 'ARRIVAL' && b.rideType != 'ARRIVAL') {
          return -1;
        }
        if (b.rideType == 'ARRIVAL' && a.rideType != 'ARRIVAL') {
          return 1;
        }
        return 0;
      });

      return group;
    }).toList();
  }

  Future<bool> _cancelOnServer(RideAgreement ride, {bool confirmed = false}) async {
    if (ride.listingType == 'OFFER') {
      final result = await _offers.cancelRideOffer(ride.listingId, confirmParticipants: confirmed);
      return result == RideOfferCancellationResult.cancelled;
    }
    final result = await _requests.cancelRideRequest(ride.listingId, confirmParticipants: confirmed);
    return result == RideRequestCancellationResult.cancelled;
  }

  Future<void> _cancelRide(RideAgreement ride) async {
    if (_busy) return;
    setState(() => _busy = true);
    final kind = ride.listingType == 'OFFER' ? 'offer' : 'request';
    try {
      final cancelled = await _cancelOnServer(ride);
      if (!mounted) return;
      if (!cancelled) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text(ride.roundTripId == null ? 'Cancel $kind?' : 'Cancel both legs?'),
            content: const Text('Other people have joined this ride. Cancel it for everyone?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Keep ride')),
              TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Yes, cancel')),
            ],
          ),
        );
        if (!mounted || confirmed != true) return;
        final accepted = await _cancelOnServer(ride, confirmed: true);
        if (!mounted) return;
        if (!accepted) throw StateError('Cancellation was not confirmed');
      }
      await _dashboardController.loadAgreements();
      if (!mounted) return;
      final suffix = _dashboardController.errorMessage == null ? '' : ' Pull to refresh your dashboard.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ride $kind cancelled.$suffix')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not confirm cancellation. Refresh to check your ride.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<RideAgreement> _editableLegs(RideAgreement ride) {
    final tripId = ride.roundTripId;
    final legs = tripId == null ? [ride] : _dashboardController.agreements
        .where((leg) => leg.roundTripId == tripId).toList();
    final email = widget.user.email.toLowerCase();
    for (final leg in legs) {
      if (!leg.createdByCurrentUser || leg.listingType != ride.listingType ||
          leg.status.toUpperCase() == 'CANCELLED' ||
          [...leg.drivers, ...leg.passengers].any((member) => member.id.toLowerCase() != email)) {
        return [];
      }
    }
    final unique = {for (final leg in legs) leg.listingId: leg}.values.toList();
    if (tripId != null && (unique.length != 2 ||
        !unique.any((leg) => leg.rideType == 'ARRIVAL') ||
        !unique.any((leg) => leg.rideType == 'DEPARTURE'))) {
      return [];
    }
    return unique;
  }

  Future<void> _editRide(RideAgreement ride, List<RideAgreement> editable) async {
    if (_busy || editable.isEmpty) return;
    setState(() => _busy = true);
    final isOffer = ride.listingType == 'OFFER';
    final kind = isOffer ? 'offer' : 'request';
    try {
      final legs = isOffer
          ? [ride, ...editable.where((leg) => leg.listingId != ride.listingId)]
          : editable;
      final load = isOffer ? _offers.getRideOfferDetails : _requests.getRideRequestDetails;
      final details = await Future.wait(legs.map((leg) => load(leg.listingId)));
      if (!mounted) return;

      for (var i = 0; i < legs.length; i++) {
        final detail = details[i];
        final type = legs[i].rideType == 'ARRIVAL' ? 'arriving' : 'departing';
        if (detail[isOffer ? 'offerId' : 'requestId'] != legs[i].listingId ||
            detail['roundTripId'] != legs[i].roundTripId ||
            detail['rideType'] != type || detail['status'] == 'CANCELLED') {
          throw StateError('Ride details changed');
        }
        final seats = detail['passengerNum'];
        if (isOffer && (seats is! int || seats < 1 || detail['askingForDrivers'] is! bool)) {
          throw StateError('Incomplete offer details');
        }
      }

      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => isOffer
            ? EditRideRequestDialog.offer(legs: details, service: _offers)
            : EditRideRequestDialog(legs: details, service: _requests),
      );
      if (!mounted || saved != true) return;
      await _dashboardController.loadAgreements();
      if (!mounted) return;
      final suffix = _dashboardController.errorMessage == null ? '' : ' Pull to refresh your dashboard.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ride $kind updated.$suffix')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open this $kind. Refresh and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildBody() {
    final controller = _dashboardController;
    final filteredAgreements = controller.getFilteredAgreements(_selectedDays, kind: _kind);

    if (controller.isLoading && controller.agreements.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (controller.errorMessage != null &&
        controller.agreements.isEmpty) {
      return _MessageState(
        icon: Icons.error_outline,
        iconColor: AppColors.error,
        title: 'Something went wrong',
        message: controller.errorMessage!,
        actionLabel: 'Try again',
        onAction: controller.loadAgreements,
      );
    }

        if (controller.agreements.isEmpty) {
      return const _MessageState(
        icon: Icons.confirmation_number_outlined,
        iconColor: AppColors.primary,
        title: 'Nothing here yet',
        message:
            "Rides you've agreed on, and the offers and requests you post, "
            'will show up here.',
      );
    }

    final groupedAgreements = _groupAgreements(filteredAgreements);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: controller.loadAgreements,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView.separated(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
            ),
            itemCount: groupedAgreements.isEmpty
                ? 2
                : groupedAgreements.length + 1,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _KindFilter(
                      selected: _kind,
                      onChanged: (kind) => setState(() => _kind = kind),
                    ),
                    const SizedBox(height: 16),
                    _DayFilter(
                      savedDays: controller.agreements.expand((ride) => ride.daysOfWeek),
                      selectedDays: _selectedDays,
                      onDaySelected: (day) {
                        setState(() {
                          if (_selectedDays.contains(day)) {
                            _selectedDays.remove(day);
                          } else {
                            _selectedDays.add(day);
                          }
                        });
                      },
                      onClear: () {
                        setState(() {
                          _selectedDays.clear();
                        });
                      },
                    ),
                  ],
                );
              }

              if (groupedAgreements.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: _MessageState(
                    icon: Icons.event_busy_outlined,
                    iconColor: AppColors.textSecondary,
                    title: 'No matching rides',
                    message:
                        'Nothing matches your current filters. ',
                  ),
                );
              }

              final group = groupedAgreements[index - 1];

              final ride = group.first;
              final ticket = group.length == 1
                  ? _TicketCard(agreement: ride, currentUserId: widget.user.email)
                  : _RoundTripGroup(agreements: group, currentUserId: widget.user.email);
              if (!ride.createdByCurrentUser || (ride.listingType != 'REQUEST' && ride.listingType != 'OFFER') ||
                  group.every((leg) => leg.status.toUpperCase() == 'CANCELLED')) {
                return ticket;
              }

              final editable = _editableLegs(ride);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ticket,
                  if (editable.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : () => _editRide(ride, editable),
                        child: Text(ride.listingType == 'OFFER' ? 'Edit offer' : 'Edit request'),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : () => _cancelRide(ride),
                      child: Text(ride.roundTripId == null ? (ride.listingType == 'OFFER' ? 'Cancel offer' : 'Cancel request') : 'Cancel both legs'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: _MemberTapScope(
        onTap: _showProfile,
        child: ListenableBuilder(
          listenable: _dashboardController,
          builder: (context, child) => _buildBody(),
        ),
      ),
    );
  }
}

class _MemberTapScope extends InheritedWidget {
  const _MemberTapScope({required this.onTap, required super.child});

  final ValueChanged<AgreementMember> onTap;

  static ValueChanged<AgreementMember>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MemberTapScope>()?.onTap;

  @override
  bool updateShouldNotify(_MemberTapScope oldWidget) =>
      onTap != oldWidget.onTap;
}

class _RoundTripGroup extends StatelessWidget {
  const _RoundTripGroup({
    required this.agreements,
    required this.currentUserId,
  });

  final List<RideAgreement> agreements;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.repeat,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ROUND TRIP',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.primary,
                  ),
                ),
                
              ],
            ),
          ),
          for (int i = 0; i < agreements.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'TWO LEGS · ONE ROUND TRIP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
              ),
            _TicketCard(
              agreement: agreements[i],
              currentUserId: currentUserId,
            ),
          ],
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.agreement,
    required this.currentUserId,
  });

  final RideAgreement agreement;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final pad = compact ? 12.0 : 16.0;

    final hasDrivers = agreement.drivers.isNotEmpty;
    final hasPassengers = agreement.passengers.isNotEmpty;
    final hasMembers = hasDrivers || hasPassengers;
    final isWaiting = agreement.id == null;

    final memberSections = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDrivers)
          _MemberSection(
            label: agreement.drivers.length > 1 ? 'DRIVERS' : 'DRIVER',
            members: agreement.drivers,
            currentUserId: currentUserId,
          ),
        if (hasDrivers && hasPassengers) const SizedBox(height: 10),
        if (hasPassengers)
          _MemberSection(
            label: agreement.passengers.length > 1
                ? 'PASSENGERS'
                : 'PASSENGER',
            members: agreement.passengers,
            currentUserId: currentUserId,
          ),
      ],
    );

    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWaiting
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.5),
          width: isWaiting ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 10),
            child: _TicketHeader(agreement: agreement),
          ),
          const _TearLine(),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _WeekdayRow(activeDays: agreement.daysOfWeek),
                      _RideTime(agreement: agreement),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 520;

                    if (!hasMembers) {
                      return Align(
                        alignment: narrow
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: _OwnershipLabels(
                          agreement: agreement,
                          alignEnd: !narrow,
                        ),
                      );
                    }

                    // Narrow card (phone): members first, pills underneath,
                    // everything left-aligned.
                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          memberSections,
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _OwnershipLabels(
                              agreement: agreement,
                              alignEnd: false,
                            ),
                          ),
                        ],
                      );
                    }

                    // Wide card: members on the left, pills on the right.
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: memberSections),
                        const SizedBox(width: 10),
                        _OwnershipLabels(agreement: agreement),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!compact) return card;

    // On phones, shrink all text in the ticket to 90% of whatever the user's
    // own font-size setting is.
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(
          mediaQuery.textScaler.scale(1) * 0.9,
        ),
      ),
      child: card,
    );
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.agreement});

  final RideAgreement agreement;

  @override
  Widget build(BuildContext context) {
    final isUnjoinedOwnListing =
        agreement.createdByCurrentUser &&
        agreement.id == null &&
        !_hasJoiners(agreement);

    String title = 'RIDE ARRANGEMENT';
    IconData icon = Icons.handshake_outlined;

    if (isUnjoinedOwnListing) {
      if (agreement.drivers.isNotEmpty &&
          agreement.passengers.isEmpty) {
        title = 'YOUR RIDE OFFER';
        icon = Icons.event_seat_outlined;
      } else if (agreement.passengers.isNotEmpty &&
          agreement.drivers.isEmpty) {
        title = 'YOUR RIDE REQUEST';
        icon = Icons.hail;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: isUnjoinedOwnListing
                  ? AppColors.textSecondary
                  : AppColors.primary,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            _StatusChip(status: agreement.status),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Place(
                label: 'FROM',
                name: agreement.origin,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.directions_car_filled_outlined,
                color: AppColors.primary,
                size: 23,
              ),
            ),
            Expanded(
              child: _Place(
                label: 'TO',
                name: agreement.destination,
                alignEnd: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _hasJoiners(RideAgreement agreement) {
    return agreement.drivers.length + agreement.passengers.length > 1;
  }
}

class _OwnershipLabels extends StatelessWidget {
  const _OwnershipLabels({
    required this.agreement,
    this.alignEnd = true,
  });

  final RideAgreement agreement;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final isUnjoinedOwnListing =
        agreement.createdByCurrentUser &&
        agreement.id == null &&
        agreement.status.toUpperCase() != 'CANCELLED' &&
        agreement.drivers.length + agreement.passengers.length <= 1;

    return Wrap(
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      spacing: 7,
      runSpacing: 5,
      children: [
        _LabelPill(
          label: agreement.createdByCurrentUser
              ? 'CREATED BY YOU'
              : 'JOINED',
          icon: agreement.createdByCurrentUser
              ? Icons.person_outline
              : Icons.group_outlined,
          isPrimary: agreement.createdByCurrentUser,
        ),
        if (isUnjoinedOwnListing)
          const _LabelPill(
            label: 'WAITING FOR OTHERS',
            icon: Icons.hourglass_empty,
            isPrimary: false,
          ),
      ],
    );
  }
}

class _LabelPill extends StatelessWidget {
  const _LabelPill({
    required this.label,
    required this.icon,
    required this.isPrimary,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final color =
        isPrimary ? AppColors.primary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RideTime extends StatelessWidget {
  const _RideTime({required this.agreement});

  final RideAgreement agreement;

  @override
  Widget build(BuildContext context) {
    final label = agreement.rideType == 'ARRIVAL'
        ? 'ARRIVAL TIME'
        : 'DEPARTURE TIME';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule,
              color: AppColors.primary,
              size: 17,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          agreement.rideTimeLabel,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({
    required this.label,
    required this.name,
    this.alignEnd = false,
  });

  final String label;
  final String name;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          name,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toUpperCase();

    final color = switch (normalizedStatus) {
      'OPEN' => const Color.fromARGB(255, 87, 150, 71),
      'FULL' => AppColors.primary,
      'ARCHIVED' => AppColors.textSecondary,
      _ => AppColors.textSecondary,
    };

    final label = status.isEmpty
        ? ''
        : status[0].toUpperCase() + status.substring(1).toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _TearLine extends StatelessWidget {
  const _TearLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _Notch(isLeft: true),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dashCount = (constraints.maxWidth / 10).floor();

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  dashCount,
                  (_) => Container(
                    width: 5,
                    height: 1.5,
                    color: AppColors.border,
                  ),
                ),
              );
            },
          ),
        ),
        const _Notch(isLeft: false),
      ],
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({required this.isLeft});

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(10);

    return SizedBox(
      width: 10,
      height: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: isLeft
              ? const BorderRadius.only(
                  topRight: radius,
                  bottomRight: radius,
                )
              : const BorderRadius.only(
                  topLeft: radius,
                  bottomLeft: radius,
                ),
        ),
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.activeDays});

  final List<String> activeDays;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Wrap(
      children: [
        for (final (day, letter) in _visibleDays(activeDays))
          Padding(
            padding: EdgeInsets.only(right: compact ? 5 : 7),
            child: _DayCircle(
              letter: letter,
              active: activeDays.contains(day),
              size: compact ? 28 : 32,
            ),
          ),
      ],
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.letter,
    required this.active,
    this.size = 32,
  });

  final String letter;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size < 32 ? 12 : 13,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _MemberSection extends StatelessWidget {
  const _MemberSection({
    required this.label,
    required this.members,
    required this.currentUserId,
  });

  final String label;
  final List<AgreementMember> members;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final member in members)
              _MemberChip(
                member: member,
                isCurrentUser: member.id == currentUserId,
              ),
          ],
        ),
      ],
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.member,
    required this.isCurrentUser,
  });

  final AgreementMember member;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final onTap = _MemberTapScope.maybeOf(context);

    final chip = Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isCurrentUser ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<UserProfile?>(
            valueListenable: SessionService.profileNotifier,
            builder: (context, profile, _) {
              final avatarColor = isCurrentUser ? profile?.avatarColor : null;
              return CircleAvatar(
                radius: 13,
                backgroundColor: isCurrentUser
                    ? AvatarColorOption.getBackgroundColor(avatarColor)
                    : AppColors.primary,
                child: Text(
                  member.initials,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser
                        ? AvatarColorOption.getTextColor(avatarColor)
                        : Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 7),
          ValueListenableBuilder<UserProfile?>(
            valueListenable: SessionService.profileNotifier,
            builder: (context, profile, _) {
              final fullName = isCurrentUser && profile != null
                  ? '${profile.firstName} ${profile.lastName ?? ''}'.trim()
                  : member.fullName;
              return Text(
                fullName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCurrentUser
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              );
            },
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'YOU',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;

    return Semantics(
      button: true,
      label: 'View ${member.fullName}\'s profile',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(member),
          child: chip,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: iconColor),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KindFilter extends StatelessWidget {
  const _KindFilter({required this.selected, required this.onChanged});

  final TicketFilter selected;
  final ValueChanged<TicketFilter> onChanged;

  static const _options = <(TicketFilter, String)>[
    (TicketFilter.all, 'All'),
    (TicketFilter.agreements, 'Agreements'),
    (TicketFilter.waitingOffers, 'Seeking riders'),
    (TicketFilter.waitingRequests, 'Seeking a driver'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SHOW',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in _options)
              ChoiceChip(
                label: Text(label),
                selected: selected == value,
                onSelected: (_) => onChanged(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayFilter extends StatelessWidget {
  const _DayFilter({
    required this.savedDays,
    required this.selectedDays,
    required this.onDaySelected,
    required this.onClear,
  });

  final Iterable<String> savedDays;
  final Set<String> selectedDays;
  final ValueChanged<String> onDaySelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedDays.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FILTER BY DAY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: allSelected,
              onSelected: (_) => onClear(),
            ),
            for (final (day, _) in _visibleDays([...savedDays, ...selectedDays]))
              FilterChip(
                label: Text(
                  day[0] + day.substring(1).toLowerCase(),
                ),
                selected: selectedDays.contains(day),
                onSelected: (_) => onDaySelected(day),
              ),
          ],
        ),
      ],
    );
  }
}
