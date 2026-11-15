import 'package:flutter/material.dart';

class NavigationItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const NavigationItem({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: isExpanded ? '' : label,
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
            child: Row(
              children: [
                SizedBox(
                  width: isExpanded ? 48 : 54,
                  child: Icon(
                    icon,
                    color: isSelected ? colors.primary : colors.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                if (isExpanded)
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
