import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RideLocationPrivacyNote extends StatelessWidget {
  const RideLocationPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 14),
        SizedBox(width: 5),
        Expanded(
          child: Text(
            'Your exact address is private; other riders see an approximate '
            'location on the map.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
