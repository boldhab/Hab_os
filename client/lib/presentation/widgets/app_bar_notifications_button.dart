import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notifications_provider.dart';

/// Top AppBar notification bell action with live unread badge counter (UC-160)
class AppBarNotificationsButton extends ConsumerWidget {
  const AppBarNotificationsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: unreadCount > 0
          ? '$unreadCount Unread Notifications'
          : 'Notifications',
      onPressed: () => context.push('/more/notifications'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            unreadCount > 0
                ? Icons.notifications_active_rounded
                : Icons.notifications_outlined,
            size: 22,
            color: unreadCount > 0
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
