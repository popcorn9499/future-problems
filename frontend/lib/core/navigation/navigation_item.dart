import 'package:flutter/material.dart';

import '../widgets/unread_message_badge.dart';

class NavigationItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  final int unreadCount;

  const NavigationItem({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final badge = unreadCount > 0 ? UnreadMessageBadge(count: unreadCount) : null;
    final semanticLabel = '$label, $unreadCount unread '
        'message${unreadCount == 1 ? '' : 's'}';
    final item = Tooltip(
      message: isExpanded ? '' : (badge == null ? label : semanticLabel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 48,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showLabel = isExpanded && constraints.maxWidth >= 120;
                final iconWidget = Icon(
                  icon,
                  color: isSelected ? colors.primary : colors.onSurfaceVariant,
                  size: 22,
                );
                if (!showLabel) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(width: double.infinity, child: iconWidget),
                      if (badge != null)
                        PositionedDirectional(top: 2, end: 2, child: badge),
                    ],
                  );
                }
                return Row(
                  children: [
                    SizedBox(width: 48, child: iconWidget),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? colors.primary : colors.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 12),
                        child: badge,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    if (badge == null) return item;
    return Semantics(
      label: semanticLabel,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: item,
    );
  }
}
