import 'package:flutter/material.dart';
import '../../../../data/models/habit_model.dart';
import '../../../../app/theme/app_spacing.dart';

/// Modal dialog for logging numeric progress or duration minutes on habits.
class LogProgressDialog extends StatefulWidget {
  final HabitModel habit;

  const LogProgressDialog({super.key, required this.habit});

  static Future<int?> show(BuildContext context, HabitModel habit) {
    return showDialog<int>(
      context: context,
      builder: (_) => LogProgressDialog(habit: habit),
    );
  }

  @override
  State<LogProgressDialog> createState() => _LogProgressDialogState();
}

class _LogProgressDialogState extends State<LogProgressDialog> {
  late int _value;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.habit.currentTodayValue;
    _controller = TextEditingController(text: _value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final habit = widget.habit;
    final isDone = _value >= habit.targetValue;
    final unit = habit.targetType == 'DURATION' ? 'minutes' : 'reps';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.track_changes_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log Progress',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                        ),
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Target Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Target: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${habit.targetValue} $unit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Counter Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    onPressed: _value > 0
                        ? () {
                            setState(() {
                              _value = (_value -
                                      (habit.targetType == 'DURATION' ? 5 : 1))
                                  .clamp(0, 99999);
                              _controller.text = _value.toString();
                            });
                          }
                        : null,
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) {
                          setState(() => _value = parsed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _value += (habit.targetType == 'DURATION' ? 5 : 1);
                        _controller.text = _value.toString();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Increment Quick Chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  ActionChip(
                    label: const Text('+1'),
                    onPressed: () {
                      setState(() {
                        _value += 1;
                        _controller.text = _value.toString();
                      });
                    },
                  ),
                  if (habit.targetType == 'DURATION' ||
                      habit.targetValue >= 10) ...[
                    ActionChip(
                      label: const Text('+5'),
                      onPressed: () {
                        setState(() {
                          _value += 5;
                          _controller.text = _value.toString();
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('+15'),
                      onPressed: () {
                        setState(() {
                          _value += 15;
                          _controller.text = _value.toString();
                        });
                      },
                    ),
                  ],
                  ActionChip(
                    avatar: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Complete Target'),
                    onPressed: () {
                      setState(() {
                        _value = habit.targetValue;
                        _controller.text = _value.toString();
                      });
                    },
                  ),
                ],
              ),
              if (isDone) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Target achieved for today! 🎉',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _value),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save Progress'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

