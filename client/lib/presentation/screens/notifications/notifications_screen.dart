import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/models/notification_item_model.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/app_empty_state.dart';

/// Notifications & Inbox Center Screen (UC-159 to UC-166)
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.academic:
        return Icons.school_rounded;
      case NotificationCategory.alert:
        return Icons.warning_amber_rounded;
      case NotificationCategory.reminder:
        return Icons.alarm_rounded;
      case NotificationCategory.system:
        return Icons.info_outline_rounded;
      case NotificationCategory.all:
        return Icons.all_inbox_rounded;
    }
  }

  Color _getCategoryColor(NotificationCategory category, ColorScheme colorScheme) {
    switch (category) {
      case NotificationCategory.academic:
        return const Color(0xFF8E24AA); // Purple
      case NotificationCategory.alert:
        return const Color(0xFFE65100); // Deep Orange
      case NotificationCategory.reminder:
        return colorScheme.primary;
      case NotificationCategory.system:
        return const Color(0xFF00897B); // Teal
      case NotificationCategory.all:
        return colorScheme.primary;
    }
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
          'Are you sure you want to permanently delete all notifications from your inbox?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              ref.read(notificationsProvider.notifier).clearAll();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Inbox Center',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withAlpha(50),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${state.unreadCount} unread',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: state.unreadCount > 0
                ? () {
                    ref.read(notificationsProvider.notifier).markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                : null,
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) async {
              if (value == 'scan') {
                final count = await ref
                    .read(notificationsProvider.notifier)
                    .generateContextualAlerts();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        count > 0
                            ? 'Generated $count new contextual alerts'
                            : 'All deadlines and streaks are currently up to date',
                      ),
                    ),
                  );
                }
              } else if (value == 'clear') {
                _confirmClearAll(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.radar_rounded, size: 18),
                    SizedBox(width: 12),
                    Text('Scan for Deadline Alerts'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined,
                        size: 18, color: Color(0xFFEA4335)),
                    SizedBox(width: 12),
                    Text('Clear All Notifications',
                        style: TextStyle(color: Color(0xFFEA4335))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Category Filter Bar (UC-163)
          _buildCategoryFilters(context, ref, state, colorScheme, isDark),

          // 2. Unread Banner (UC-162)
          if (state.unreadCount > 0) ...[
            _buildUnreadBanner(context, ref, state, colorScheme, isDark),
          ],

          const Divider(height: 1, thickness: 0.5),

          // 3. Notification Items List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(notificationsProvider.notifier)
                  .loadNotifications(showLoading: false),
              color: colorScheme.primary,
              child: _buildBody(context, ref, state, colorScheme, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(
    BuildContext context,
    WidgetRef ref,
    NotificationsState state,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    const categories = [
      NotificationCategory.all,
      NotificationCategory.reminder,
      NotificationCategory.alert,
      NotificationCategory.academic,
      NotificationCategory.system,
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == state.selectedCategory;
          final catColor = _getCategoryColor(cat, colorScheme);

          final count = cat == NotificationCategory.all
              ? state.items.length
              : state.items.where((i) => i.category == cat).length;

          return ChoiceChip(
            showCheckmark: false,
            avatar: Icon(
              _getCategoryIcon(cat),
              size: 14,
              color: isSelected
                  ? colorScheme.onPrimary
                  : (cat == NotificationCategory.all
                      ? colorScheme.onSurfaceVariant
                      : catColor),
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withAlpha(50)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            selected: isSelected,
            selectedColor: colorScheme.primary,
            backgroundColor: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerHighest.withAlpha(120),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withAlpha(60),
                width: 1,
              ),
            ),
            onSelected: (_) {
              ref.read(notificationsProvider.notifier).setCategory(cat);
            },
          );
        },
      ),
    );
  }

  Widget _buildUnreadBanner(
    BuildContext context,
    WidgetRef ref,
    NotificationsState state,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(isDark ? 28 : 16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withAlpha(60),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mark_email_unread_rounded,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${state.unreadCount} unread notification${state.unreadCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              ref.read(notificationsProvider.notifier).markAllAsRead();
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NotificationsState state,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colorScheme.primary,
        ),
      );
    }

    final items = state.filteredItems;

    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppEmptyState(
            icon: Icons.notifications_off_outlined,
            title: state.selectedCategory == NotificationCategory.all
                ? 'Inbox is Empty'
                : 'No ${state.selectedCategory.label} Found',
            description: state.selectedCategory == NotificationCategory.all
                ? 'You are all caught up! Impending deadlines, streaks, and focus reminders will arrive here.'
                : 'No notifications matching the "${state.selectedCategory.label}" category filter.',
            actionLabel: 'Scan for Alerts',
            onAction: () async {
              final count = await ref
                  .read(notificationsProvider.notifier)
                  .generateContextualAlerts();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0
                          ? 'Found and generated $count alerts'
                          : 'No pending deadline alerts right now',
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildNotificationCard(context, ref, item, colorScheme, isDark);
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final catColor = _getCategoryColor(item.category, colorScheme);
    final catIcon = _getCategoryIcon(item.category);
    final relativeTime = _formatRelativeTime(item.createdAt);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) {
        ref.read(notificationsProvider.notifier).deleteNotification(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${item.title}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          // 1. Mark as read if not already read (UC-161)
          if (!item.isRead) {
            ref.read(notificationsProvider.notifier).markAsRead(item.id);
          }

          // 2. Deep-link navigation if targetRoute exists (UC-164)
          final route = item.targetRoute;
          if (route != null && route.isNotEmpty) {
            context.push(route);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: item.isRead
                ? (isDark
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surfaceContainerHighest.withAlpha(90))
                : (isDark
                    ? colorScheme.primary.withAlpha(20)
                    : colorScheme.primary.withAlpha(12)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? (isDark
                      ? colorScheme.outlineVariant.withAlpha(35)
                      : colorScheme.outlineVariant.withAlpha(60))
                  : colorScheme.primary.withAlpha(80),
              width: item.isRead ? 0.8 : 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon Badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: catColor.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: catColor.withAlpha(70),
                    width: 1,
                  ),
                ),
                child: Icon(
                  catIcon,
                  size: 20,
                  color: catColor,
                ),
              ),
              const SizedBox(width: 12),

              // Title, Message, Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          relativeTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withAlpha(150),
                          ),
                        ),
                        if (item.targetRoute != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'View details',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action Popup
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withAlpha(140),
                ),
                padding: EdgeInsets.zero,
                splashRadius: 18,
                onSelected: (val) {
                  if (val == 'toggle_read') {
                    if (item.isRead) {
                      // Note: backend supports markAsRead; if already read, no-op or mark
                    } else {
                      ref.read(notificationsProvider.notifier).markAsRead(item.id);
                    }
                  } else if (val == 'delete') {
                    ref.read(notificationsProvider.notifier).deleteNotification(item.id);
                  }
                },
                itemBuilder: (ctx) => [
                  if (!item.isRead)
                    const PopupMenuItem(
                      value: 'toggle_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Mark as read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 16, color: Color(0xFFEA4335)),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Color(0xFFEA4335))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
