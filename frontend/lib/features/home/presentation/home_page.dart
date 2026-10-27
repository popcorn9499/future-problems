import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/user.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/go_bison_logo.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.profile,
    required this.onProfileTap,
  });

  final User user;
  final UserProfile profile;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        toolbarHeight: 100,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,

          children: [const GoBisonLogo(height: 100)],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: UserAvatar(
                firstName: user.firstName,
                lastName: user.lastName,
                radius: 21,
                onTap: onProfileTap,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_outlined,
                      size: 58,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Your next ride starts here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.25,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'We’re working on something exciting '
                    'to make getting to campus easier.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.construction_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Feature coming soon',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  OutlinedButton.icon(
                    onPressed: onProfileTap,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('View My Profile'),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
