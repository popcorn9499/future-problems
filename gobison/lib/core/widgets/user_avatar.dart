import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.firstName,
    this.lastName,
    this.imageUrl,
    this.radius = 24,
    this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  final String firstName;
  final String? lastName;
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;

  String get _initials {
    final first = firstName.trim();
    final last = lastName?.trim() ?? '';

    return [
      if (first.isNotEmpty) first[0],
      if (last.isNotEmpty) last[0],
    ].join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final avatarBackgroundColor =
        backgroundColor ?? const Color(0xFFE9DFD2);

    return Semantics(
      button: onTap != null,
      label: '${lastName?.isNotEmpty == true ? lastName : firstName} profile',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: avatarBackgroundColor,
          backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
          child: hasImage
              ? null
              : Text(
                  initials.isEmpty ? '?' : initials,
                  style: TextStyle(
                    color: textColor ?? AppColors.primary,
                    fontSize: radius * 0.65,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
