import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/notification_item_model.dart';

class NotificationsState {
  final List<NotificationItem> items;
  final NotificationCategory selectedCategory;
  final int unreadCount;
  final bool isLoading;
  final bool isOperating;
  final String? errorMessage;

  const NotificationsState({
    this.items = const [],
    this.selectedCategory = NotificationCategory.all,
    this.unreadCount = 0,
    this.isLoading = false,
    this.isOperating = false,
    this.errorMessage,
  });

  List<NotificationItem> get filteredItems {
    if (selectedCategory == NotificationCategory.all) {
      return items;
    }
    return items.where((item) => item.category == selectedCategory).toList();
  }

  NotificationsState copyWith({
    List<NotificationItem>? items,
    NotificationCategory? selectedCategory,
    int? unreadCount,
    bool? isLoading,
    bool? isOperating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      isOperating: isOperating ?? this.isOperating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref _ref;

  NotificationsNotifier(this._ref) : super(const NotificationsState()) {
    loadNotifications();
  }

  Future<void> loadNotifications({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final dio = _ref.read(dioProvider);

      final responses = await Future.wait([
        dio.get(ApiEndpoints.notifications, queryParameters: {'limit': 50}),
        dio.get(ApiEndpoints.notificationsUnreadCount),
      ]);

      final notifData = responses[0].data['data'] ?? responses[0].data;
      final countData = responses[1].data['data'] ?? responses[1].data;

      final items = (notifData as List? ?? [])
          .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
          .toList();

      final unreadCount = countData['unreadCount'] is int
          ? countData['unreadCount'] as int
          : items.where((i) => !i.isRead).length;

      state = state.copyWith(
        items: items,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications: $e',
      );
    }
  }

  void setCategory(NotificationCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> markAsRead(String id) async {
    final prevItems = state.items;
    final prevCount = state.unreadCount;

    final targetIndex = state.items.indexWhere((i) => i.id == id);
    if (targetIndex == -1 || state.items[targetIndex].isRead) return;

    // Optimistic update
    final updatedList = List<NotificationItem>.from(state.items);
    updatedList[targetIndex] = updatedList[targetIndex].copyWith(isRead: true);
    final newCount = (prevCount > 0) ? prevCount - 1 : 0;

    state = state.copyWith(
      items: updatedList,
      unreadCount: newCount,
    );

    try {
      final dio = _ref.read(dioProvider);
      await dio.patch(ApiEndpoints.notificationRead(id));
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        items: prevItems,
        unreadCount: prevCount,
        errorMessage: 'Failed to mark notification as read: $e',
      );
    }
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0 && state.items.every((i) => i.isRead)) {
      return;
    }

    final prevItems = state.items;
    final prevCount = state.unreadCount;

    // Optimistic update
    final updatedList = state.items.map((i) => i.copyWith(isRead: true)).toList();
    state = state.copyWith(
      items: updatedList,
      unreadCount: 0,
    );

    try {
      final dio = _ref.read(dioProvider);
      await dio.patch(ApiEndpoints.notificationsReadAll);
    } catch (e) {
      state = state.copyWith(
        items: prevItems,
        unreadCount: prevCount,
        errorMessage: 'Failed to mark all notifications as read: $e',
      );
    }
  }

  Future<void> deleteNotification(String id) async {
    final prevItems = state.items;
    final prevCount = state.unreadCount;

    final target = state.items.firstWhere(
      (i) => i.id == id,
      orElse: () => NotificationItem(
        id: '',
        title: '',
        message: '',
        type: '',
        createdAt: DateTime.now(),
      ),
    );
    if (target.id.isEmpty) return;

    final isUnread = !target.isRead;
    final updatedList = state.items.where((i) => i.id != id).toList();
    final newCount = (isUnread && prevCount > 0) ? prevCount - 1 : prevCount;

    state = state.copyWith(
      items: updatedList,
      unreadCount: newCount,
    );

    try {
      final dio = _ref.read(dioProvider);
      await dio.delete(ApiEndpoints.notificationById(id));
    } catch (e) {
      state = state.copyWith(
        items: prevItems,
        unreadCount: prevCount,
        errorMessage: 'Failed to delete notification: $e',
      );
    }
  }

  Future<void> clearAll() async {
    final prevItems = state.items;
    final prevCount = state.unreadCount;

    state = state.copyWith(
      items: const [],
      unreadCount: 0,
    );

    try {
      final dio = _ref.read(dioProvider);
      await dio.delete(ApiEndpoints.notifications);
    } catch (e) {
      state = state.copyWith(
        items: prevItems,
        unreadCount: prevCount,
        errorMessage: 'Failed to clear notifications: $e',
      );
    }
  }

  Future<int> generateContextualAlerts() async {
    state = state.copyWith(isOperating: true, clearError: true);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post(ApiEndpoints.notificationsGenerateAlerts);
      final count = response.data['data']?['generatedCount'] as int? ?? 0;

      await loadNotifications(showLoading: false);
      state = state.copyWith(isOperating: false);
      return count;
    } catch (e) {
      state = state.copyWith(
        isOperating: false,
        errorMessage: 'Failed to generate contextual alerts: $e',
      );
      return 0;
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider.select((s) => s.unreadCount));
});
