import 'package:flutter/material.dart';

import '../../../core/widgets/go_bison_logo.dart';

import 'navigation_item.dart';

class AppSidebar extends StatelessWidget {
  final bool isExpanded;
  final int selectedIndex;
  final VoidCallback onToggle;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;

  const AppSidebar({
    super.key,
    required this.isExpanded,
    required this.selectedIndex,
    required this.onToggle,
    required this.onDestinationSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isExpanded ? 250 : 76,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.outlineVariant, width: 0.7)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            child: isExpanded
          ? Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: GoBisonLogo(height: 60),
                  ),
                ),
                IconButton(
                  onPressed: onToggle,
                  tooltip: 'Collapse sidebar',
                  icon: const Icon(Icons.menu_open_rounded),
                ),
              ],
            )
          : Center(
              child: LogoSmall(height: 45),
            ),
          ),
          if (!isExpanded)
            IconButton(
              onPressed: onToggle,
              tooltip: 'Expand sidebar',
              icon: const Icon(Icons.menu_rounded),
            ),

          const SizedBox(height: 20),

          NavigationItem(
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            isSelected: selectedIndex == 0,
            isExpanded: isExpanded,
            onTap: () => onDestinationSelected(0),
          ),

          NavigationItem(
            label: 'Messages',
            icon: Icons.chat_bubble_outline_rounded,
            isSelected: selectedIndex == 1,
            isExpanded: isExpanded,
            onTap: () => onDestinationSelected(1),
          ),

          NavigationItem(
            label: 'Create Ride Request',
            icon: Icons.person_outline_rounded,
            isSelected: selectedIndex == 2,
            isExpanded: isExpanded,
            onTap: () => onDestinationSelected(2),
          ),

          NavigationItem(
            label: 'Create Ride Offer',
            icon: Icons.directions_car_outlined,
            isSelected: selectedIndex == 3,
            isExpanded: isExpanded,
            onTap: () => onDestinationSelected(3),
          ),

          const Spacer(),
          NavigationItem(
            label: 'Log Out',
            icon: Icons.logout_rounded,
            isSelected: false,
            isExpanded: isExpanded,
            onTap: onLogout,
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
