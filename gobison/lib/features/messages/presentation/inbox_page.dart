import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../messaging_controller.dart';
import '../models/conversation.dart';
import 'chat_page.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({
    super.key,
    required this.currentUserId,
    this.controller,
    this.showAppBar = true,
  });

  final String currentUserId;
  final MessagingController? controller;
  final bool showAppBar;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  late final MessagingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? MessagingController();
    _controller.loadInbox();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await _controller.loadInbox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Messages'),
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              surfaceTintColor: Colors.transparent,
            )
          : null,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoadingInbox && _controller.inbox.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.inboxErrorMessage != null &&
              _controller.inbox.isEmpty) {
            return _MessageState(
              icon: Icons.cloud_off_outlined,
              title: 'Messages are unavailable',
              subtitle: _controller.inboxErrorMessage!,
              action: TextButton(
                onPressed: _reload,
                child: const Text('Try again'),
              ),
            );
          }

          final inboxItems = _controller.inbox;
          if (inboxItems.isEmpty) {
            return const _MessageState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No conversations yet',
              subtitle: 'When you connect with another rider, your messages will show up here.',
            );
          }

          return Column(
            children: [
              if (_controller.usingMockData) const _PreviewNotice(),
              if (_controller.isLoadingInbox)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: inboxItems.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 84),
                    itemBuilder: (context, index) => _InboxTile(
                      conversation: inboxItems[index],
                      onTap: () async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatPage(
                              conversation: inboxItems[index],
                              currentUserId: widget.currentUserId,
                              controller: _controller,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = conversation.participant.displayName;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: UserAvatar(
        firstName: conversation.participant.firstName,
        lastName: conversation.participant.lastName,
        radius: 27,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          conversation.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatListTime(conversation.lastMessageAt),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 7),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
    color: AppColors.surface,
    child: const Text(
      'Preview messages · All messages are simulated and not sent to a real user.',
      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}

String _formatListTime(DateTime? value) {
  if (value == null) return '';
  final date = value.toLocal();
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }
  return '${date.month}/${date.day}';
}
