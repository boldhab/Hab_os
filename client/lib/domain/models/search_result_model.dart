import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Single item returned from cross-domain global search (UC-167, UC-168)
class SearchResultItem extends Equatable {
  final String id;
  final String type; // 'TASK' | 'PROJECT' | 'COURSE' | 'ASSIGNMENT' | 'NOTE' | 'HABIT' | 'GOAL' | 'WORKOUT' | 'TRANSACTION'
  final String title;
  final String? subtitle;
  final String rawRoute;
  final Map<String, dynamic>? details;

  const SearchResultItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.rawRoute,
    this.details,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString().toUpperCase() ?? 'TASK',
      title: json['title']?.toString() ?? 'Untitled',
      subtitle: json['subtitle']?.toString(),
      rawRoute: json['route']?.toString() ?? '',
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'route': rawRoute,
        if (details != null) 'details': details,
      };

  IconData get icon {
    switch (type) {
      case 'TASK':
        return Icons.task_alt_rounded;
      case 'PROJECT':
        return Icons.folder_rounded;
      case 'COURSE':
        return Icons.school_rounded;
      case 'ASSIGNMENT':
        return Icons.assignment_rounded;
      case 'NOTE':
        return Icons.menu_book_rounded;
      case 'HABIT':
        return Icons.repeat_rounded;
      case 'GOAL':
        return Icons.flag_rounded;
      case 'WORKOUT':
        return Icons.fitness_center_rounded;
      case 'TRANSACTION':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'TASK':
        return Colors.blue.shade600;
      case 'PROJECT':
        return Colors.teal.shade600;
      case 'COURSE':
      case 'ASSIGNMENT':
        return Colors.deepPurpleAccent;
      case 'NOTE':
        return Colors.indigo.shade600;
      case 'HABIT':
        return Colors.cyan.shade700;
      case 'GOAL':
        return Colors.amber.shade800;
      case 'WORKOUT':
        return Colors.redAccent.shade400;
      case 'TRANSACTION':
        return const Color(0xFF10B981);
      default:
        return Colors.grey.shade700;
    }
  }

  String get domainLabel {
    switch (type) {
      case 'TASK':
        return 'Task';
      case 'PROJECT':
        return 'Project';
      case 'COURSE':
        return 'Course';
      case 'ASSIGNMENT':
        return 'Assignment';
      case 'NOTE':
        return 'Vault Note';
      case 'HABIT':
        return 'Habit';
      case 'GOAL':
        return 'Goal';
      case 'WORKOUT':
        return 'Gym Workout';
      case 'TRANSACTION':
        return 'Finance';
      default:
        return type;
    }
  }

  /// Direct client navigation path corresponding to GoRouter routes
  String get clientRoute {
    switch (type) {
      case 'TASK':
        return '/tasks/$id';
      case 'PROJECT':
        return '/more/projects/$id';
      case 'COURSE':
        return '/more/academic/$id';
      case 'ASSIGNMENT':
        return '/more/academic';
      case 'NOTE':
        return '/more/vault/$id';
      case 'HABIT':
        return '/habits';
      case 'GOAL':
        return '/more/goals/$id';
      case 'WORKOUT':
        return '/more/gym/$id';
      case 'TRANSACTION':
        return '/more/finance';
      default:
        return rawRoute.startsWith('/') ? rawRoute : '/$rawRoute';
    }
  }

  @override
  List<Object?> get props => [id, type, title, subtitle, rawRoute, details];
}

/// Global Search Container Response
class GlobalSearchResult extends Equatable {
  final String query;
  final String domain;
  final int totalResults;
  final List<SearchResultItem> results;

  const GlobalSearchResult({
    required this.query,
    this.domain = 'ALL',
    this.totalResults = 0,
    this.results = const [],
  });

  factory GlobalSearchResult.fromJson(Map<String, dynamic> json) {
    final listRaw = json['results'];
    final List<SearchResultItem> items = [];
    if (listRaw is List) {
      for (final i in listRaw) {
        if (i is Map) {
          items.add(SearchResultItem.fromJson(Map<String, dynamic>.from(i)));
        }
      }
    }

    return GlobalSearchResult(
      query: json['query']?.toString() ?? '',
      domain: json['domain']?.toString() ?? 'ALL',
      totalResults: json['totalResults'] is num
          ? (json['totalResults'] as num).toInt()
          : items.length,
      results: items,
    );
  }

  @override
  List<Object?> get props => [query, domain, totalResults, results];
}
