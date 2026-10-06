import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../providers/ai_chat_provider.dart';
import 'ai_chat_bubble.dart';
import 'ai_quick_prompt_chips.dart';
import 'ai_scope_selector.dart';

class AiChatView extends ConsumerStatefulWidget {
  final bool showHeader;
  final VoidCallback? onClose;

  const AiChatView({
    super.key,
    this.showHeader = false,
    this.onClose,
  });

  @override
  ConsumerState<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends ConsumerState<AiChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final canSend = _textController.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _textController.text;
    if (text.trim().isEmpty) return;

    ref.read(aiChatProvider.notifier).sendMessage(text);
    if (customText == null) {
      _textController.clear();
    }
    _scrollToBottom();
  }

  void _confirmClearConversation() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear Conversation?'),
        content: const Text(
          'Are you sure you want to reset this chat session? Message history will be cleared.',
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
              ref.read(aiChatProvider.notifier).clearConversation();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto scroll when message list changes
    ref.listen(aiChatProvider.select((s) => s.messages.length), (prev, next) {
      if (prev != next) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        if (widget.showHeader) ...[
          _buildHeader(colorScheme, isDark),
        ],

        // 1. Context Scope Selector Bar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: AiScopeSelector(
            selectedScope: chatState.selectedScope,
            onScopeSelected: (scope) {
              ref.read(aiChatProvider.notifier).setScope(scope);
            },
          ),
        ),

        const Divider(height: 1, thickness: 0.5),

        // 2. Chat Message List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < chatState.messages.length) {
                final msg = chatState.messages[index];
                return AiChatBubble(message: msg);
              } else {
                return const AiTypingIndicatorBubble();
              }
            },
          ),
        ),

        // Error message banner if any
        if (chatState.errorMessage != null && !chatState.isLoading) ...[
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withAlpha(120),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chatState.errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onErrorContainer,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        // 3. Pre-built Prompt Suggestion Chips Carousel
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: AiQuickPromptChips(
            activeScope: chatState.selectedScope,
            onPromptSelected: (prompt) {
              _sendMessage(prompt);
            },
          ),
        ),

        // 4. Text Input Composer
        _buildInputComposer(chatState, colorScheme, isDark),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(60),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withAlpha(25),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HABos AI Assistant',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Connected to live workspace data',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            tooltip: 'Clear conversation',
            color: colorScheme.onSurfaceVariant,
            onPressed: _confirmClearConversation,
          ),
          if (widget.onClose != null) ...[
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: 'Close',
              color: colorScheme.onSurfaceVariant,
              onPressed: widget.onClose,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputComposer(
    AiChatState chatState,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        6,
        AppSpacing.md,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerHighest.withAlpha(120),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withAlpha(70),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (_canSend && !chatState.isLoading) {
                      _sendMessage();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Ask HABos AI assistant...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _canSend && !chatState.isLoading
                    ? colorScheme.primary
                    : colorScheme.onSurface.withAlpha(20),
              ),
              child: IconButton(
                icon: chatState.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        size: 20,
                        color: _canSend
                            ? Colors.white
                            : colorScheme.onSurfaceVariant.withAlpha(80),
                      ),
                tooltip: 'Send prompt',
                onPressed: _canSend && !chatState.isLoading
                    ? () => _sendMessage()
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
