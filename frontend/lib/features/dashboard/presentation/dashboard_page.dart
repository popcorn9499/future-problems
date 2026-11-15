import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/user.dart';
import '../../../core/models/ride_agreement.dart';
import '../dashboard_controller.dart';
import '../dashboard_service.dart';

const List<(String, String)> _weekdays = [
  ('MONDAY', 'M'),
  ('TUESDAY', 'T'),
  ('WEDNESDAY', 'W'),
  ('THURSDAY', 'T'),
  ('FRIDAY', 'F'),
];

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.user,
    this.dashboardService,
  });

  final User user;
  final DashboardService? dashboardService;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardService _dashboardService;
  late final DashboardController _dashboardController;

  final Set<String> _selectedDays = {};

  @override
  void initState() {
    super.initState();

    _dashboardService = widget.dashboardService ?? DashboardService();
    _dashboardController = DashboardController(_dashboardService);
    _dashboardController.loadAgreements();
  }

  @override
  void dispose() {
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

  Widget _buildBody() {
    final controller = _dashboardController;
    final filteredAgreements =
        controller.getFilteredAgreements(_selectedDays);

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
        title: 'No ride agreements yet',
        message:
            'Once you and other students agree on a ride, '
            'it will show up here.',
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
            padding: const EdgeInsets.all(24),
            itemCount: groupedAgreements.isEmpty
                ? 2
                : groupedAgreements.length + 1,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _DayFilter(
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
                );
              }

              if (groupedAgreements.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: _MessageState(
                    icon: Icons.event_busy_outlined,
                    iconColor: AppColors.textSecondary,
                    title: 'No rides on this day',
                    message:
                        'You have no ride agreements scheduled for this day.',
                  ),
                );
              }

              final group = groupedAgreements[index - 1];

              if (group.length == 1) {
                return _TicketCard(
                  agreement: group.first,
                  currentUserId: widget.user.email,
                );
              }

              return _RoundTripGroup(
                agreements: group,
                currentUserId: widget.user.email,
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
      child: ListenableBuilder(
        listenable: _dashboardController,
        builder: (context, child) => _buildBody(),
      ),
    );
  }
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
    final hasDrivers = agreement.drivers.isNotEmpty;
    final hasPassengers = agreement.passengers.isNotEmpty;
    final hasMembers = hasDrivers || hasPassengers;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _TicketHeader(agreement: agreement),
          ),
          const _TearLine(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _WeekdayRow(
                        activeDays: agreement.daysOfWeek,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RideTime(agreement: agreement),
                  ],
                ),
                if (hasMembers) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDrivers)
                              _MemberSection(
                                label: agreement.drivers.length > 1
                                    ? 'DRIVERS'
                                    : 'DRIVER',
                                members: agreement.drivers,
                                currentUserId: currentUserId,
                              ),
                            if (hasDrivers && hasPassengers)
                              const SizedBox(height: 10),
                            if (hasPassengers)
                              _MemberSection(
                                label: agreement.passengers.length > 1
                                    ? 'PASSENGERS'
                                    : 'PASSENGER',
                                members: agreement.passengers,
                                currentUserId: currentUserId,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _OwnershipLabels(agreement: agreement),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _OwnershipLabels(agreement: agreement),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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

    if (isUnjoinedOwnListing) {
      if (agreement.drivers.isNotEmpty &&
          agreement.passengers.isEmpty) {
        title = 'YOUR RIDE OFFER';
      } else if (agreement.passengers.isNotEmpty &&
          agreement.drivers.isEmpty) {
        title = 'YOUR RIDE REQUEST';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
  const _OwnershipLabels({required this.agreement});

  final RideAgreement agreement;

  @override
  Widget build(BuildContext context) {
    final isUnjoinedOwnListing =
        agreement.createdByCurrentUser &&
        agreement.id == null &&
        agreement.drivers.length + agreement.passengers.length <= 1;

    return Wrap(
      alignment: WrapAlignment.end,
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
    return Row(
      children: [
        for (final (day, letter) in _weekdays)
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: _DayCircle(
              letter: letter,
              active: activeDays.contains(day),
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
  });

  final String letter;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
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
          fontSize: 13,
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
    return Container(
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
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.primary,
            child: Text(
              member.initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            member.fullName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isCurrentUser
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
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

class _DayFilter extends StatelessWidget {
  const _DayFilter({
    required this.selectedDays,
    required this.onDaySelected,
    required this.onClear,
  });

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
            for (final (day, _) in _weekdays)
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
