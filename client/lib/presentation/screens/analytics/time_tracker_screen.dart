import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../../domain/models/retrospective_model.dart';

class TimeTrackerScreen extends ConsumerStatefulWidget {
  const TimeTrackerScreen({super.key});

  @override
  ConsumerState<TimeTrackerScreen> createState() => _TimeTrackerScreenState();
}

class _TimeTrackerScreenState extends ConsumerState<TimeTrackerScreen> {
  String _formatElapsed(int seconds) {
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0m';
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hrs > 0) {
      return '${hrs}h ${mins}m';
    }
    return '${mins}m';
  }

  void _showStartTimerBottomSheet() {
    final tasksState = ref.read(tasksProvider);
    final pendingTasks = tasksState.tasks.where((t) => !t.isCompleted).toList();
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.toLowerCase().trim();
            final filteredTasks = pendingTasks.where((t) {
              return t.title.toLowerCase().contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Track Time for Task',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick start unassigned button
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pop(ctx);
                        ref.read(timeTrackerProvider.notifier).startTimer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.timer_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'General Activity (Unassigned)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Start timer without linking to any specific task',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search field
                    TextField(
                      controller: searchController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search pending tasks...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'OR LINK TO PENDING TASK (${filteredTasks.length})',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(160),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tasks List
                    Flexible(
                      child: filteredTasks.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              child: Text(
                                'No matching pending tasks found.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredTasks.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final task = filteredTasks[idx];
                                return ListTile(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    ref
                                        .read(timeTrackerProvider.notifier)
                                        .startTimer(taskId: task.id);
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withAlpha(35),
                                    ),
                                  ),
                                  tileColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow,
                                  leading: const Icon(Icons.check_circle_outline_rounded),
                                  title: Text(
                                    task.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task.priority,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDurationDialog(TimeEntryModel entry) {
    final controller = TextEditingController(
      text: ((entry.duration ?? 0) ~/ 60).toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adjust Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter duration in minutes:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                suffixText: 'mins',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final mins = int.tryParse(controller.text.trim());
              if (mins != null && mins > 0) {
                final newDurationSeconds = mins * 60;
                final newEndTime = entry.startTime.add(Duration(minutes: mins));
                ref.read(timeTrackerProvider.notifier).updateEntry(
                      entry.id,
                      duration: newDurationSeconds,
                      endTime: newEndTime,
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Time entry updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final primaryRed = colorScheme.primary;
    final trackerState = ref.watch(timeTrackerProvider);
    final active = trackerState.activeEntry;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Time Tracker',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh entries',
            onPressed: () =>
                ref.read(timeTrackerProvider.notifier).fetchEntries(),
          ),
        ],
      ),
      body: trackerState.isLoading && trackerState.entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(timeTrackerProvider.notifier).fetchEntries(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  // 1. Persistent Stopwatch Engine Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryRed.withAlpha(24),
                          colorScheme.surfaceContainerHigh,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: active != null
                            ? primaryRed.withAlpha(120)
                            : colorScheme.outlineVariant.withAlpha(50),
                        width: active != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (active != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: primaryRed.withAlpha(30),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: primaryRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  active.taskTitle != null
                                      ? 'TRACKING: ${active.taskTitle!.toUpperCase()}'
                                      : 'RECORDING LIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: primaryRed,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Digital Stopwatch Timer
                        Text(
                          _formatElapsed(trackerState.activeElapsedSeconds),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: colorScheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Control Buttons
                        if (active == null)
                          FilledButton.icon(
                            onPressed: _showStartTimerBottomSheet,
                            icon: const Icon(Icons.play_arrow_rounded, size: 22),
                            label: const Text(
                              'Start Timer',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryRed,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          )
                        else
                          FilledButton.icon(
                            onPressed: () {
                              ref
                                  .read(timeTrackerProvider.notifier)
                                  .stopActiveTimer();
                            },
                            icon: const Icon(Icons.stop_rounded, size: 22),
                            label: const Text(
                              'Stop & Save',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: semantics.danger,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalGapLg,

                  // 2. Interactive Log Stream
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LOG STREAM (SWIPE TO DELETE)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: colorScheme.onSurfaceVariant.withAlpha(160),
                        ),
                      ),
                      Text(
                        '${trackerState.entries.length} entries',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalGapSm,

                  if (trackerState.entries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'No time entries logged yet. Press Start Timer above to record activity.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trackerState.entries.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = trackerState.entries[index];
                        final timeFmt = DateFormat('MMM d, h:mm a');
                        final isLive = entry.isActive;

                        return Dismissible(
                          key: Key(entry.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: semantics.danger.withAlpha(30),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.delete_forever_rounded,
                              color: semantics.danger,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Time Entry?'),
                                content: const Text(
                                    'Are you sure you want to permanently remove this entry?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(
                                        backgroundColor: semantics.danger),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) {
                            ref
                                .read(timeTrackerProvider.notifier)
                                .deleteEntry(entry.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Time entry deleted')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isLive
                                  ? primaryRed.withAlpha(12)
                                  : colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isLive
                                    ? primaryRed.withAlpha(60)
                                    : colorScheme.outlineVariant.withAlpha(35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isLive
                                        ? primaryRed.withAlpha(20)
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isLive
                                        ? Icons.timer_outlined
                                        : Icons.access_time_rounded,
                                    color: isLive
                                        ? primaryRed
                                        : colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.taskTitle ?? 'General Task Time',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timeFmt.format(entry.startTime),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant
                                              .withAlpha(160),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isLive
                                          ? 'LIVE'
                                          : _formatDuration(entry.duration),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isLive
                                            ? primaryRed
                                            : colorScheme.onSurface,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                    if (!isLive)
                                      GestureDetector(
                                        onTap: () =>
                                            _showEditDurationDialog(entry),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Edit',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
