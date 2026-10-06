import 'package:flutter/material.dart';
import '../screens/ai/ai_chat_bottom_sheet.dart';

/// Universal AI Assistant action button for AppBars across screens (UC-131, UC-132, UC-147)
class AppBarAiButton extends StatelessWidget {
  const AppBarAiButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: colorScheme.primary,
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
      tooltip: 'HABos AI Assistant',
      onPressed: () => AiChatBottomSheet.show(context),
    );
  }
}
