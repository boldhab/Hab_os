import 'package:equatable/equatable.dart';

/// Embedded code snippet with syntax metadata (UC-124)
class CodeSnippet extends Equatable {
  final String language;
  final String code;
  final String? description;

  const CodeSnippet({
    required this.language,
    required this.code,
    this.description,
  });

  factory CodeSnippet.fromJson(Map<String, dynamic> json) {
    return CodeSnippet(
      language: json['language']?.toString() ?? 'text',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'code': code,
        if (description != null) 'description': description,
      };

  CodeSnippet copyWith({
    String? language,
    String? code,
    String? description,
  }) {
    return CodeSnippet(
      language: language ?? this.language,
      code: code ?? this.code,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [language, code, description];
}

/// Bidirectional cross-link to another note in the Knowledge Vault (UC-129, UC-130)
class NoteLinkItem extends Equatable {
  final String id;
  final String title;
  final String? direction; // 'outgoing' | 'incoming'

  const NoteLinkItem({
    required this.id,
    required this.title,
    this.direction,
  });

  factory NoteLinkItem.fromJson(Map<String, dynamic> json, {String? direction}) {
    return NoteLinkItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Note',
      direction: direction,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (direction != null) 'direction': direction,
      };

  @override
  List<Object?> get props => [id, title, direction];
}

/// Associated category metadata
class VaultNoteCategory extends Equatable {
  final String id;
  final String name;
  final String? color;
  final String? icon;

  const VaultNoteCategory({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });

  factory VaultNoteCategory.fromJson(Map<String, dynamic> json) {
    return VaultNoteCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'General',
      color: json['color']?.toString(),
      icon: json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
      };

  @override
  List<Object?> get props => [id, name, color, icon];
}

/// Knowledge Vault Note Entity (UC-120 to UC-130)
class VaultNote extends Equatable {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final List<CodeSnippet> codeSnippets;
  final bool isMistakeSolution;
  final String? categoryId;
  final VaultNoteCategory? category;
  final List<NoteLinkItem> linkedNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VaultNote({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.codeSnippets = const [],
    this.isMistakeSolution = false,
    this.categoryId,
    this.category,
    this.linkedNotes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory VaultNote.fromJson(Map<String, dynamic> json) {
    // Parse tags
    final tagsRaw = json['tags'];
    final List<String> parsedTags = [];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        if (t != null) parsedTags.add(t.toString());
      }
    }

    // Parse code snippets
    final snippetsRaw = json['codeSnippets'];
    final List<CodeSnippet> parsedSnippets = [];
    if (snippetsRaw is List) {
      for (final s in snippetsRaw) {
        if (s is Map) {
          parsedSnippets.add(CodeSnippet.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    // Parse bidirectional links
    final List<NoteLinkItem> parsedLinks = [];
    if (json['sourceLinks'] is List) {
      for (final l in json['sourceLinks']) {
        if (l is Map && l['targetNote'] is Map) {
          parsedLinks.add(NoteLinkItem.fromJson(
            Map<String, dynamic>.from(l['targetNote']),
            direction: 'outgoing',
          ));
        }
      }
    }
    if (json['targetLinks'] is List) {
      for (final l in json['targetLinks']) {
        if (l is Map && l['sourceNote'] is Map) {
          parsedLinks.add(NoteLinkItem.fromJson(
            Map<String, dynamic>.from(l['sourceNote']),
            direction: 'incoming',
          ));
        }
      }
    }

    // Parse dates
    final created = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now();
    final updated = json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'].toString()) ?? created
        : created;

    return VaultNote(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Note',
      content: json['content']?.toString() ?? '',
      tags: parsedTags,
      codeSnippets: parsedSnippets,
      isMistakeSolution: json['isMistakeSolution'] == true,
      categoryId: json['categoryId']?.toString(),
      category: json['category'] is Map
          ? VaultNoteCategory.fromJson(Map<String, dynamic>.from(json['category']))
          : null,
      linkedNotes: parsedLinks,
      createdAt: created,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'tags': tags,
        'codeSnippets': codeSnippets.map((s) => s.toJson()).toList(),
        'isMistakeSolution': isMistakeSolution,
        'categoryId': categoryId,
        if (category != null) 'category': category!.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  VaultNote copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    List<CodeSnippet>? codeSnippets,
    bool? isMistakeSolution,
    String? categoryId,
    VaultNoteCategory? category,
    List<NoteLinkItem>? linkedNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VaultNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      codeSnippets: codeSnippets ?? this.codeSnippets,
      isMistakeSolution: isMistakeSolution ?? this.isMistakeSolution,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      linkedNotes: linkedNotes ?? this.linkedNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        tags,
        codeSnippets,
        isMistakeSolution,
        categoryId,
        category,
        linkedNotes,
        createdAt,
        updatedAt,
      ];
}
