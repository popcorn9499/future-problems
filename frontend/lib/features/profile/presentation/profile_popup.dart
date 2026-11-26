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
      backgroundColor: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      builder: (_) => popup,
    );
  }

  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
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
  static const _bandHeight = 88.0;
  static const _avatarRadius = 40.0;
  static const _ringWidth = 3.0;

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
      top: false,
      child: SingleChildScrollView(
        child: FutureBuilder<UserProfile>(
          future: _profile,
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final tint = AvatarColorOption.getBackgroundColor(
              profile?.avatarColor,
            );
            final name = profile == null
                ? widget.member.fullName
                : [profile.firstName, profile.lastName ?? '']
                      .where((part) => part.trim().isNotEmpty)
                      .join(' ');

            // Half of the avatar (plus its ring) hangs below the colour band.
            const overlap = _avatarRadius + _ringWidth;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: _bandHeight,
                      color: tint.withValues(alpha: 0.6),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -overlap,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(_ringWidth),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: UserAvatar(
                            firstName: widget.member.firstName,
                            lastName: widget.member.lastName,
                            radius: _avatarRadius,
                            backgroundColor: tint,
                            textColor: AvatarColorOption.getTextColor(
                              profile?.avatarColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: overlap + 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
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
    final hasPronouns = _has(profile.pronouns);
    final hasAge = profile.age != null;
    final hasAbout = _has(profile.description);

    if (!hasPronouns && !hasAge && !hasAbout) {
      return const Text(
        "This user hasn't added any profile details yet.",
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPronouns || hasAge)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasPronouns)
                _InfoPill(
                  icon: Icons.person_outline,
                  label: profile.pronouns!,
                ),
              if (hasAge)
                _InfoPill(
                  icon: Icons.cake_outlined,
                  label: 'Age ${profile.age}',
                ),
            ],
          ),
        if (hasAbout) ...[
          if (hasPronouns || hasAge) const SizedBox(height: 18),
          const Text(
            'ABOUT ME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _QuoteBlock(text: profile.description!),
        ],
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote,
            size: 22,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
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