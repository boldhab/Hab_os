import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../providers/ai_chat_provider.dart';
import 'widgets/ai_chat_view.dart';

/// Full-screen conversational AI Assistant screen (UC-131, UC-132, UC-147)
class AiChatScreen extends ConsumerWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withAlpha(25),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HABos AI Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Live context across all domains',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withAlpha(160),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear chat',
            onPressed: () {
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
                        foregroundColor: colorScheme.error,
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
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About HABos AI',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('HABos AI Assistant'),
                    ],
                  ),
                  content: const Text(
                    'HABos AI has direct real-time access to your productivity data:\n\n'
                    '• Tasks due today and overdue items\n'
                    '• Habit streaks and pending check-ins\n'
                    '• Academic deliverables & exams\n'
                    '• Project milestones and focus sessions\n'
                    '• Gym workouts and weekly consistency\n'
                    '• Budget limits, wallet balances and spending\n\n'
                    'Select a domain scope chip to direct the AI to a specific context, or select "All Context" for holistic guidance.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const SafeArea(
        child: AiChatView(showHeader: false),
      ),
    );
  }
}
