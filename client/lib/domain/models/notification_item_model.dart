import 'package:equatable/equatable.dart';

/// Notification categories supported by HABos Inbox Center (UC-159 to UC-166)
enum NotificationCategory {
  all,
  reminder,
  alert,
  academic,
  system;

  String get label {
    switch (this) {
      case NotificationCategory.all:
        return 'All';
      case NotificationCategory.reminder:
        return 'Reminders';
      case NotificationCategory.alert:
        return 'Alerts';
      case NotificationCategory.academic:
        return 'Academic';
      case NotificationCategory.system:
        return 'System';
    }
  }

  static NotificationCategory fromString(String val) {
    final normalized = val.trim().toUpperCase();
    switch (normalized) {
      case 'REMINDER':
      case 'REMINDERS':
        return NotificationCategory.reminder;
      case 'ALERT':
      case 'ALERTS':
        return NotificationCategory.alert;
      case 'ACADEMIC':
        return NotificationCategory.academic;
      case 'SYSTEM':
        return NotificationCategory.system;
      default:
        return NotificationCategory.all;
    }
  }
}

/// Represents an in-app notification in HABos (UC-159 to UC-166)
class NotificationItem extends Equatable {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.scheduledFor,
    this.sentAt,
    required this.createdAt,
    this.metadata,
  });

  /// Maps backend notification type to domain category
  NotificationCategory get category {
    final upperType = type.toUpperCase();
    if (upperType.contains('EXAM') ||
        upperType.contains('COURSE') ||
        upperType.contains('ACADEMIC')) {
      return NotificationCategory.academic;
    }
    if (upperType.contains('ALERT') ||
        upperType.contains('STREAK') ||
        upperType.contains('BUDGET') ||
        upperType.contains('WARNING')) {
      return NotificationCategory.alert;
    }
    if (upperType.contains('REMINDER') ||
        upperType.contains('TASK') ||
        upperType.contains('SCHEDULE') ||
        upperType.contains('HABIT') ||
        upperType.contains('WORKOUT') ||
        upperType.contains('GOAL')) {
      return NotificationCategory.reminder;
    }
    return NotificationCategory.system;
  }

  /// Resolves deep-link navigation route from metadata if available (UC-164)
  String? get targetRoute {
    if (metadata != null) {
      if (metadata!['route'] is String &&
          (metadata!['route'] as String).isNotEmpty) {
        return metadata!['route'] as String;
      }
      if (metadata!['taskId'] != null) {
        return '/tasks/${metadata!['taskId']}';
      }
      if (metadata!['examId'] != null || metadata!['courseId'] != null) {
        return '/more/academic';
      }
      if (metadata!['habitId'] != null) {
        return '/habits';
      }
      if (metadata!['workoutId'] != null) {
        return '/more/gym';
      }
      if (metadata!['goalId'] != null) {
        return '/more/goals';
      }
      if (metadata!['projectId'] != null) {
        return '/more/projects';
      }
    }
    return null;
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? scheduledFor,
    DateTime? sentAt,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'GENERAL',
      isRead: json['isRead'] == true,
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.tryParse(json['scheduledFor'].toString())
          : null,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'isRead': isRead,
        if (scheduledFor != null) 'scheduledFor': scheduledFor!.toIso8601String(),
        if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        type,
        isRead,
        scheduledFor,
        sentAt,
        createdAt,
        metadata,
      ];
}
