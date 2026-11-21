import 'package:flutter/material.dart';

import '../../../core/models/ride_agreement.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/avatar_color_option.dart';
import '../../../core/widgets/user_avatar.dart';
import '../profile_controller.dart' show extractErrorCode;
import '../profile_service.dart';

Future<void> showProfilePopup(
  BuildContext context, {
  required AgreementMember member,
  ProfileService? service,
}) {
  final popup = _ProfilePopup(
    member: member,
    service: service ?? ProfileService(),
  );

  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => popup,
    );
  }

  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: popup,
      ),
    ),
  );
}

class _ProfilePopup extends StatefulWidget {
  const _ProfilePopup({required this.member, required this.service});

  final AgreementMember member;
  final ProfileService service;

  @override
  State<_ProfilePopup> createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<_ProfilePopup> {
  late Future<UserProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.service.getProfile(userId: widget.member.id);
  }

  void _retry() {
    setState(() {
      _profile = widget.service.getProfile(userId: widget.member.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: FutureBuilder<UserProfile>(
          future: _profile,
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final name = profile == null
                ? widget.member.fullName
                : [profile.firstName, profile.lastName ?? '']
                      .where((part) => part.trim().isNotEmpty)
                      .join(' ');

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: UserAvatar(
                    firstName: widget.member.firstName,
                    lastName: widget.member.lastName,
                    radius: 40,
                    backgroundColor: AvatarColorOption.getBackgroundColor(
                      profile?.avatarColor,
                    ),
                    textColor: AvatarColorOption.getTextColor(
                      profile?.avatarColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (snapshot.hasError)
                  _ErrorBlock(error: snapshot.error!, onRetry: _retry)
                else
                  _Details(profile: profile!),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.profile});

  final UserProfile profile;

  bool _has(String? value) => value != null && value.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (_has(profile.pronouns)) ('PRONOUNS', profile.pronouns!),
      if (profile.age != null) ('AGE', profile.age.toString()),
      if (_has(profile.description)) ('ABOUT ME', profile.description!),
    ];

    if (rows.isEmpty) {
      return const Text(
        "This user hasn't added any profile details yet.",
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in rows) ...[
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
          Text(value, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final notFound = extractErrorCode(error) == 404;

    return Column(
      children: [
        Text(
          notFound
              ? 'This profile is no longer available.'
              : "We couldn't load this profile.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        if (!notFound)
          TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}