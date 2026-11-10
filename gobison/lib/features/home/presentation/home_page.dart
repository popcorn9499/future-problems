
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/user.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/go_bison_logo.dart';
import '../../../core/theme/avatar_color_option.dart';

// Add your ride page imports here.
import '../../ride_request/presentation/ride_request_page.dart';
import '../../ride_offer/presentation/ride_offer_page.dart';

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

  Widget _buildRideOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 28,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                height: 76,
                width: 76,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          children: [
            const GoBisonLogo(height: 100),
          ],
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
                backgroundColor: AvatarColorOption.getBackgroundColor(profile.avatarColor,),
                textColor: AvatarColorOption.getTextColor(profile.avatarColor,),
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
                    'Whether you need a ride or have room to offer one, '
                    'GoBison makes getting to campus easier.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 36),

                  Row(
                    children: [
                      _buildRideOption(
                        context: context,
                        title: 'Request a Ride',
                        icon: Icons.person_outline,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RideRequestPage(userId: user.id,),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 16),

                      _buildRideOption(
                        context: context,
                        title: 'Offer a Ride',
                        icon: Icons.directions_car_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RideOfferPage(userId: user.id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  OutlinedButton.icon(
                    onPressed: onProfileTap,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('View My Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                      ),
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
