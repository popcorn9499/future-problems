import 'package:flutter/material.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/models/user.dart';

import 'package:gobison/core/navigation/no_animation_page_route.dart';
import 'package:gobison/features/auth/presentation/login_page.dart';
import 'package:gobison/core/services/session_service.dart';

import 'app_sidebar.dart';

class AppShell extends StatefulWidget {
  final Widget dashboardPage;
  final Widget inboxPage;
  final Widget rideRequestPage;
  final Widget rideOfferPage;
  final User user;
  final ImageProvider? profileImage;
  final VoidCallback onProfileTap;

  const AppShell({
    super.key,
    required this.dashboardPage,
    required this.inboxPage,
    required this.rideRequestPage,
    required this.rideOfferPage,
    required this.user,
    this.profileImage,
    required this.onProfileTap,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> handleLogout() async {
    try {
      await SessionService().logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        NoAnimationPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  String get _pageTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Messages';
      case 2:
        return 'Create Ride Request';
      case 3:
        return 'Create Ride Offer';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final pages = [
      widget.dashboardPage,
      widget.inboxPage,
      widget.rideRequestPage,
      widget.rideOfferPage,
    ];

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            AppSidebar(
              isExpanded: _isSidebarExpanded,
              selectedIndex: _selectedIndex,
              onToggle: _toggleSidebar,
              onDestinationSelected: _selectPage,
              onLogout: handleLogout,
            ),
            Expanded(
              child: Column(
                children: [
                  // Persistent top bar
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(bottom: BorderSide(color: colors.outlineVariant, width: 0.7)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _pageTitle,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),

                        const Spacer(),
                        UserAvatar(
                          firstName: widget.user.firstName,
                          lastName: widget.user.lastName,
                          radius: 21,
                          onTap: widget.onProfileTap,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(index: _selectedIndex, children: pages),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
