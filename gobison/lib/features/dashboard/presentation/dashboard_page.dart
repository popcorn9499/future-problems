import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
 
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
  const DashboardPage({super.key, required this.user, this.dashboardService});
 
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
 
  Widget _buildBody() {
    final controller = _dashboardController;
    final filteredAgreements = controller.getFilteredAgreements(_selectedDays); 
    if (controller.isLoading && controller.agreements.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
 
    if (controller.errorMessage != null && controller.agreements.isEmpty) {
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
 
    return RefreshIndicator(
  color: AppColors.primary,
  onRefresh: controller.loadAgreements,
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 850),
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: filteredAgreements.isEmpty ? 2 : filteredAgreements.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(height: 20),
        itemBuilder: (context, index) {
  // Filter chips at the top
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

  // No agreements match the selected day
  if (filteredAgreements.isEmpty) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: _MessageState(
        icon: Icons.event_busy_outlined,
        iconColor: AppColors.textSecondary,
        title: 'No rides on this day',
        message: 'You have no ride agreements scheduled for this day.',
      ),
    );
  }

  // Display agreement ticket
  return _TicketCard(
    agreement: filteredAgreements[index - 1],
    currentUserId: widget.user.id,
    onCopyAddress: _copyAddress,
  );
},
      ),
    ),
  ),
);
  }
 
  @override
  Widget build(BuildContext context) {
    // No Scaffold/AppBar/SafeArea: AppShell already provides the sidebar,
    // the top bar with the page title, and the SafeArea.
    return ColoredBox(
      color: AppColors.background,
      child: ListenableBuilder(
        listenable: _dashboardController,
        builder: (context, child) => _buildBody(),
      ),
    );
  }
 
  void _copyAddress(String? address) {
    if (address == null || address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No address available.'),
        ),
      );
      return;
    }
 
    Clipboard.setData(ClipboardData(text: address));
 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
 
class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.agreement,
    required this.currentUserId,
    required this.onCopyAddress,
  });
 
  final RideAgreement agreement;
  final String currentUserId;
  final ValueChanged<String?> onCopyAddress;
 
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _TicketHeader(agreement: agreement),
          ),
          const _TearLine(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      agreement.departureTimeLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _WeekdayRow(activeDays: agreement.daysOfWeek),
                const SizedBox(height: 20),
                _MemberSection(
                  label: agreement.drivers.length > 1 ? 'DRIVERS' : 'DRIVER',
                  members: agreement.drivers,
                  currentUserId: currentUserId,
                  onCopyAddress: onCopyAddress,
                ),
                const SizedBox(height: 16),
                _MemberSection(
                  label: agreement.passengers.length > 1
                      ? 'PASSENGERS'
                      : 'PASSENGER',
                  members: agreement.passengers,
                  currentUserId: currentUserId,
                  onCopyAddress: onCopyAddress,
                ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RIDE AGREEMENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              ),
            ),
            _StatusChip(status: agreement.status),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Place(label: 'FROM', name: agreement.origin),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.directions_car_filled_outlined,
                color: AppColors.primary,
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
}
 
class _Place extends StatelessWidget {
  const _Place({required this.label, required this.name, this.alignEnd = false});
 
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
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
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
    final isActive = status.toUpperCase() == 'ACTIVE';
    final color = isActive ? const Color.fromARGB(255, 87, 150, 71) : AppColors.textSecondary;
    final label = status.isEmpty
        ? ''
        : status[0].toUpperCase() + status.substring(1).toLowerCase();
 
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical:8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
 
/// The dashed "perforation" between the header and body, with side notches.
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
              ? const BorderRadius.only(topRight: radius, bottomRight: radius)
              : const BorderRadius.only(topLeft: radius, bottomLeft: radius),
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
            padding: const EdgeInsets.only(right: 8),
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
  const _DayCircle({required this.letter, required this.active});
 
  final String letter;
  final bool active;
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
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
    required this.onCopyAddress,
  });
 
  final String label;
  final List<AgreementMember> members;
  final String currentUserId;
  final ValueChanged<String?> onCopyAddress;
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final member in members)
              _MemberChip(
                member: member,
                isCurrentUser: member.id == currentUserId,
                onCopyAddress: onCopyAddress,
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
    required this.onCopyAddress,
  });
 
  final AgreementMember member;
  final bool isCurrentUser;
  final ValueChanged<String?> onCopyAddress;
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
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
            radius: 14,
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
          const SizedBox(width: 8),
          Text(
  member.fullName,
  style: TextStyle(
    fontSize: 13,
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
          if (!isCurrentUser && member.address.trim().isNotEmpty) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Copy address',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.copy,
                size: 16,
                color: AppColors.primary,
              ),
              onPressed: () => onCopyAddress(member.address),
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