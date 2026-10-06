import 'package:equatable/equatable.dart';

/// Single message in the Conversational AI Assistant thread (UC-131, UC-132, UC-147)
class ChatMessage extends Equatable {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String contextScope; // 'ALL' | 'TASKS' | 'HABITS' | 'STUDY' | 'DEV' | 'GYM' | 'FINANCE'
  final Map<String, dynamic>? contextSummary;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.contextScope = 'ALL',
    this.contextSummary,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text']?.toString() ?? json['response']?.toString() ?? '',
      isUser: json['isUser'] == true,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      contextScope: json['contextScope']?.toString() ?? 'ALL',
      contextSummary: json['contextSummary'] is Map<String, dynamic>
          ? json['contextSummary'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'contextScope': contextScope,
        if (contextSummary != null) 'contextSummary': contextSummary,
      };

  @override
  List<Object?> get props => [id, text, isUser, timestamp, contextScope, contextSummary];
}

/// Pre-built prompt chip suggestion
class PromptChipSuggestion {
  final String label;
  final String prompt;
  final String scope;

  const PromptChipSuggestion({
    required this.label,
    required this.prompt,
    required this.scope,
  });

  static const List<PromptChipSuggestion> defaults = [
    PromptChipSuggestion(
      label: 'What should I do next?',
      prompt: 'What should I do next?',
      scope: 'ALL',
    ),
    PromptChipSuggestion(
      label: 'Summarize my spending',
      prompt: 'Summarize my spending this month',
      scope: 'FINANCE',
    ),
    PromptChipSuggestion(
      label: 'Am I ready for exams?',
      prompt: 'Am I ready for exams and what assignments are due?',
      scope: 'STUDY',
    ),
    PromptChipSuggestion(
      label: 'Gym workout status',
      prompt: 'How is my gym consistency this week?',
      scope: 'GYM',
    ),
    PromptChipSuggestion(
      label: 'Habits pending today',
      prompt: 'What habits do I need to complete today?',
      scope: 'HABITS',
    ),
    PromptChipSuggestion(
      label: 'Coding target progress',
      prompt: 'How much focus time do I have logged towards my coding target?',
      scope: 'DEV',
    ),
  ];
}
