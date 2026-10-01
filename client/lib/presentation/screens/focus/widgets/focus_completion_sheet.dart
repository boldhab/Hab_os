import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class FocusCompletionSheet extends StatefulWidget {
  final int durationMinutes;
  final String category;
  final Future<void> Function(String? notes) onSave;

  const FocusCompletionSheet({
    super.key,
    required this.durationMinutes,
    required this.category,
    required this.onSave,
  });

  @override
  State<FocusCompletionSheet> createState() => _FocusCompletionSheetState();
}

class _FocusCompletionSheetState extends State<FocusCompletionSheet> {
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AppSpacing.verticalGapLg,

            // Animated Check Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primaryRed.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: primaryRed,
              ),
            ),
            AppSpacing.verticalGapMd,

            Text(
              'Focus Session Completed!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.durationMinutes} minutes of focused ${widget.category.toLowerCase()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            AppSpacing.verticalGapLg,

            // Notes input
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'What did you accomplish? (optional)',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withAlpha(140),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(50),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              maxLines: 2,
            ),
            AppSpacing.verticalGapLg,

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        await widget.onSave(_notesController.text.trim());
                        if (mounted) Navigator.pop(context);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Session',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            AppSpacing.verticalGapSm,
          ],
        ),
      ),
    );
  }
}
