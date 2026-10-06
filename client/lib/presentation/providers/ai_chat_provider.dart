import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/ai_chat_model.dart';

class AiChatState {
  final List<ChatMessage> messages;
  final String selectedScope;
  final bool isLoading;
  final String? errorMessage;

  const AiChatState({
    this.messages = const [],
    this.selectedScope = 'ALL',
    this.isLoading = false,
    this.errorMessage,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    String? selectedScope,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      selectedScope: selectedScope ?? this.selectedScope,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref _ref;

  AiChatNotifier(this._ref)
      : super(AiChatState(
          messages: [
            ChatMessage(
              id: 'initial-welcome',
              text:
                  'Hello! I am your HABos AI assistant. I have live access to your tasks, habit streaks, study deadlines, gym workouts, and budget. How can I help you today?',
              isUser: false,
              timestamp: DateTime.now(),
              contextScope: 'ALL',
            ),
          ],
        ));

  void setScope(String scope) {
    state = state.copyWith(selectedScope: scope);
  }

  Future<void> sendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || state.isLoading) return;

    final userMsg = ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      text: prompt,
      isUser: true,
      timestamp: DateTime.now(),
      contextScope: state.selectedScope,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      clearError: true,
    );

    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        ApiEndpoints.aiAsk,
        data: {
          'prompt': prompt,
          'contextScope': state.selectedScope,
        },
      );

      final payload = response.data['data'] ?? response.data;
      final replyText = payload['response']?.toString() ?? 'I could not generate a response at this time.';
      final summary = payload['contextSummary'] is Map<String, dynamic>
          ? payload['contextSummary'] as Map<String, dynamic>
          : null;

      final aiMsg = ChatMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: replyText,
        isUser: false,
        timestamp: DateTime.now(),
        contextScope: state.selectedScope,
        contextSummary: summary,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
    } catch (e) {
      final errorMsg = ChatMessage(
        id: 'err-${DateTime.now().millisecondsSinceEpoch}',
        text: 'Sorry, I encountered an error communicating with the AI service: $e',
        isUser: false,
        timestamp: DateTime.now(),
        contextScope: state.selectedScope,
      );

      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearConversation() {
    state = state.copyWith(
      messages: [
        ChatMessage(
          id: 'reset-welcome',
          text: 'Conversation cleared. How can I assist you with your schedule or goals?',
          isUser: false,
          timestamp: DateTime.now(),
          contextScope: state.selectedScope,
        ),
      ],
      clearError: true,
    );
  }
}

final aiChatProvider =
    StateNotifierProvider.autoDispose<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref);
});
