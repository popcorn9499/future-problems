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
  });

  final String firstName;
  final String? lastName;
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;

  String get _initials {
    final first = firstName.trim();
    final last = lastName != null ? lastName?.trim() : '';

    return [
      if (first.isNotEmpty) first[0],
      if (last!.isNotEmpty) last[0],
    ].join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials;

    return Semantics(
      button: onTap != null,
      label: '${lastName!.isNotEmpty ? lastName : firstName} profile',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFE9DFD2),
          backgroundImage: imageUrl != null && imageUrl!.trim().isNotEmpty
              ? NetworkImage(imageUrl!)
              : null,
          child: imageUrl != null && imageUrl!.trim().isNotEmpty
              ? null
              : Text(
                  initials.isEmpty ? '?' : initials,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: radius * 0.65,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
