import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../widgets/common/app_card.dart';

/// Displays the AI-generated next-action recommendation.
class AiTipCard extends StatelessWidget {
  final String tip;

  const AiTipCard({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryRed = colorScheme.primary;

    return AppCard(
      borderRadius: 20.0,
      backgroundColor: primaryRed.withAlpha(isDark ? 30 : 16),
      border: BorderSide(
        color: primaryRed.withAlpha(isDark ? 60 : 40),
        width: 1.0,
      ),
      padding: AppSpacing.cardPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryRed.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: primaryRed,
              size: 18,
            ),
          ),
          AppSpacing.horizontalGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI SUGGESTION',
                  style: TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
                AppSpacing.verticalGapXs,
                Text(
                  tip,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
