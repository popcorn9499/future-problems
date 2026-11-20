import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/user_avatar.dart';
import '../../../core/models/user.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/theme/avatar_color_option.dart';

import 'package:gobison/core/navigation/no_animation_page_route.dart';
import 'package:gobison/features/auth/presentation/login_page.dart';
import 'package:gobison/features/messages/messaging_controller.dart';
import 'package:gobison/core/services/session_service.dart';

import 'app_sidebar.dart';

class AppShell extends StatefulWidget {
  final Widget dashboardPage;
  final Widget inboxPage;
  final MessagingController? messagingController;
  final Widget rideRequestPage;
  final Widget rideOfferPage;
  final Widget mapPage;
  final User user;
  final ImageProvider? profileImage;
  final VoidCallback onProfileTap;

  const AppShell({
    super.key,
    required this.dashboardPage,
    required this.inboxPage,
    this.messagingController,
    required this.rideRequestPage,
    required this.rideOfferPage,
    required this.mapPage,
    required this.user,
    this.profileImage,
    required this.onProfileTap,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  Timer? _unreadTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startUnreadRefresh();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messagingController != widget.messagingController) {
      _startUnreadRefresh();
    }
  }

  void _startUnreadRefresh() {
    _unreadTimer?.cancel();
    final controller = widget.messagingController;
    if (controller == null) return;
    unawaited(controller.loadInbox());
    _unreadTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshUnread(),
    );
  }

  void _refreshUnread() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    unawaited(widget.messagingController?.loadInbox(silent: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshUnread();
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
      case 4:
        return 'Browse Ride Requests & Offers';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final pages = [
      widget.dashboardPage,
      _selectedIndex == 1 ? widget.inboxPage : const SizedBox.shrink(),
      widget.rideRequestPage,
      widget.rideOfferPage,
      TickerMode(enabled: _selectedIndex == 4, child: widget.mapPage),
    ];

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            ListenableBuilder(
              listenable: Listenable.merge([widget.messagingController]),
              builder: (context, _) => AppSidebar(
                isExpanded: _isSidebarExpanded,
                selectedIndex: _selectedIndex,
                unreadMessages: widget.messagingController?.unreadCount ?? 0,
                onToggle: _toggleSidebar,
                onDestinationSelected: _selectPage,
                onLogout: handleLogout,
              ),
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
                      border: Border(
                        bottom: BorderSide(
                          color: colors.outlineVariant,
                          width: 0.7,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _pageTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const Spacer(),
                        ValueListenableBuilder<UserProfile?>(
                          valueListenable: SessionService.profileNotifier,
                          builder: (context, profile, _) {
                            final currentProfile =
                                profile?.userId == widget.user.id
                                ? profile
                                : null;
                            return UserAvatar(
                              firstName:
                                  currentProfile?.firstName ??
                                  widget.user.firstName,
                              lastName:
                                  currentProfile?.lastName ??
                                  widget.user.lastName,
                              radius: 21,
                              onTap: widget.onProfileTap,
                              backgroundColor:
                                  AvatarColorOption.getBackgroundColor(
                                    currentProfile?.avatarColor,
                                  ),
                              textColor: AvatarColorOption.getTextColor(
                                currentProfile?.avatarColor,
                              ),
                            );
                          },
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
