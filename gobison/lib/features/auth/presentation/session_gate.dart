import 'package:flutter/material.dart';
import 'package:gobison/features/auth/presentation/verification_page.dart';

import 'login_page.dart';
import '../../home/presentation/home_page.dart';
import '../../profile/presentation/display_profile_page.dart';
import '../../profile/presentation/edit_profile_page.dart';
import '../../../core/navigation/app_shell.dart';

import '../../ride_request/presentation/ride_request_page.dart';
import '../../ride_offer/presentation/ride_offer_page.dart';

import '../../../core/services/session_service.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key, this.sessionService});

  final SessionService? sessionService;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<SessionData?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = (widget.sessionService ?? SessionService())
        .loadCurrentSession();
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
                    onPressed: () {
                      setState(() {
                        _sessionFuture =
                            (widget.sessionService ?? SessionService())
                                .loadCurrentSession();
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
        return AppShell(
          dashboardPage: HomePage(user: session.user, profile: session.profile),
          messagesPage: const Placeholder(),
          user: session.user, // Adjust to your actual profile field.
          rideRequestPage: RideRequestPage(userId: session.user.id),
          rideOfferPage: RideOfferPage(userId: session.user.id),
          onProfileTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DisplayProfilePage(
                  user: session.user,
                  profile: session.profile,
                  currentUserId: session.user.id,
                  onAccountDeleted: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  onEdit: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(
                          user: session.user,
                          profile: session.profile,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
