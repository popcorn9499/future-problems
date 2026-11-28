import 'package:flutter/material.dart';
import 'package:gobison/features/auth/presentation/verification_page.dart';
import 'package:gobison/features/dashboard/presentation/dashboard_page.dart';
import 'package:gobison/features/map/map_page.dart';

import '../../../core/models/user_profile.dart';
import 'login_page.dart';
import '../../profile/presentation/display_profile_page.dart';
import '../../profile/presentation/edit_profile_page.dart';
import '../../profile/profile_service.dart';
import '../../messages/presentation/inbox_page.dart';
import '../../messages/messaging_controller.dart';
import '../../../core/navigation/app_shell.dart';

import '../../ride_request/presentation/ride_request_page.dart';
import '../../ride_offer/presentation/ride_offer_page.dart';

import '../../../core/services/session_service.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key, this.sessionService, this.profileService});

  final SessionService? sessionService;
  final ProfileService? profileService;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<SessionData?> _sessionFuture;
  MessagingController? _messagingController;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _loadSession();
  }

  @override
  void dispose() {
    _messagingController?.dispose();
    super.dispose();
  }

  Future<SessionData?> _loadSession() async {
    final session = await (widget.sessionService ?? SessionService())
        .loadCurrentSession();
    if (session == null) return null;

    final profile = await (widget.profileService ?? ProfileService())
        .getCurrentProfile(userId: session.user.id);
    SessionService.updateCachedProfile(profile);
    return SessionService.cachedSession ?? session;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionData?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load your account.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    key: const Key('session-retry-button'),
                    onPressed: () {
                      setState(() {
                        _sessionFuture = _loadSession();
                      });
                    },
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }

        final session = snapshot.data;

        if (session == null) {
          return const LoginPage();
        }

        if (session.user.verified == false) {
          return VerificationPage(
            email: session.user.email,
            user: session.user,
            userProfile: session.profile,
          );
        }
        final messaging = _messagingController ??= MessagingController();
        return AppShell(
          messagingController: messaging,
          dashboardPage: DashboardPage(user: session.user),
          rideOfferPage: RideOfferPage(userId: session.user.id),
          inboxPage: InboxPage(
            currentUserId: session.user.id,
            controller: messaging,
            showAppBar: false,
          ),
          user: session.user,
          rideRequestPage: RideRequestPage(userId: session.user.id),
          mapPage: CarpoolMultiSourceMapPage(user: session.user),

          onProfileTap: () {
            final currentSession = SessionService.cachedSession ?? session;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DisplayProfilePage(
                  user: currentSession.user,
                  profile: currentSession.profile,
                  currentUserId: currentSession.user.id,
                  onAccountDeleted: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  onEditProfile: (user, profile) => Navigator.of(context)
                      .push<UserProfile>(
                        MaterialPageRoute(
                          builder: (_) =>
                              EditProfilePage(user: user, profile: profile),
                        ),
                      ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
