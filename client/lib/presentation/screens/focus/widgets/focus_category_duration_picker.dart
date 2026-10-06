import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../providers/focus_provider.dart';

class FocusCategoryDurationPicker extends StatelessWidget {
  final FocusState state;
  final FocusNotifier notifier;

  const FocusCategoryDurationPicker({
    super.key,
    required this.state,
    required this.notifier,
  });

  static const _categories = [
    {'id': 'CODING', 'label': 'Coding', 'icon': Icons.code_rounded},
    {'id': 'STUDY', 'label': 'Study', 'icon': Icons.menu_book_rounded},
    {'id': 'PROJECT', 'label': 'Project', 'icon': Icons.work_outline_rounded},
    {'id': 'READING', 'label': 'Reading', 'icon': Icons.book_outlined},
    {'id': 'WELLNESS', 'label': 'Wellness', 'icon': Icons.self_improvement_rounded},
    {'id': 'OTHER', 'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  static const _durations = [15, 25, 45, 60];

  void _openCustomDurationPicker(BuildContext context) {
    int selectedMinutes = state.targetMinutes;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Container(
          height: 320,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AppSpacing.verticalGapMd,
              Text(
                'Custom Target Duration',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: Duration(minutes: selectedMinutes),
                  onTimerDurationChanged: (Duration duration) {
                    selectedMinutes = duration.inMinutes.clamp(1, 480);
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    AppHaptics.selection();
                    notifier.setDuration(selectedMinutes);
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Set Duration',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    final isCustomDuration = !_durations.contains(state.targetMinutes);

    return Column(
      children: [
        // Category Icon Circles
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _categories.map((c) {
            final catId = c['id'] as String;
            final selected = state.category == catId;
            final icon = c['icon'] as IconData;
            final label = c['label'] as String;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: GestureDetector(
                  onTap: () {
                    AppHaptics.selection();
                    notifier.setCategory(catId);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selected
                              ? primaryRed.withAlpha(25)
                              : colorScheme.surfaceContainerHighest.withAlpha(70),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? primaryRed : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 22,
                          color: selected
                              ? primaryRed
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? primaryRed
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        AppSpacing.verticalGapLg,

        // Duration Presets Segmented Row
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(60),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: colorScheme.outlineVariant.withAlpha(30),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
              ..._durations.map((d) {
                final selected = state.targetMinutes == d;
                return InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    notifier.setDuration(d);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? primaryRed : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${d}m',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }),
              InkWell(
                onTap: () => _openCustomDurationPicker(context),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCustomDuration ? primaryRed : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCustomDuration ? '${state.targetMinutes}m' : 'Custom',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCustomDuration
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isCustomDuration
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: isCustomDuration
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
