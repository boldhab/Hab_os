import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../widgets/app_error_state.dart';
import '../controllers/projects_controller.dart';
import '../models/project_models.dart';

/// Kanban board tab with optimistic state management (Fix 8).
/// Moves are applied instantly to [_localBoard] before the API call.
/// On network failure the provider is invalidated to roll back to server state.
class KanbanBoardTab extends ConsumerStatefulWidget {
  final String projectId;
  const KanbanBoardTab({super.key, required this.projectId});

  @override
  ConsumerState<KanbanBoardTab> createState() => _KanbanBoardTabState();
}

class _KanbanBoardTabState extends ConsumerState<KanbanBoardTab> {
  int _phoneColIdx = 0;

  /// Optimistic local copy of the board. Null means "use provider data".
  KanbanBoardModel? _localBoard;

  static const _columnKeys = ['TODO', 'IN_PROGRESS', 'BLOCKED', 'COMPLETED'];
  static const _columnLabels = ['To Do', 'In Progress', 'Blocked', 'Done'];

  Map<String, List<KanbanCardModel>> _buildColumnsMap(KanbanBoardModel board) {
    return {
      'TODO': board.todo,
      'IN_PROGRESS': board.inProgress,
      'BLOCKED': board.blocked,
      'COMPLETED': board.completed,
    };
  }

  KanbanBoardModel _applyOptimisticMove(
    KanbanBoardModel board,
    KanbanCardModel item,
    String targetStatus,
  ) {
    // Remove from all columns
    List<KanbanCardModel> removeFrom(List<KanbanCardModel> col) =>
        col.where((c) => c.id != item.id).toList();

    final updatedItem = KanbanCardModel(
      id: item.id,
      type: item.type,
      title: item.title,
      priority: item.priority,
      status: targetStatus,
      order: (board.columns[targetStatus]?.lastOrNull?.order ?? 0) + 1000,
      isCompleted: targetStatus == 'COMPLETED',
      severity: item.severity,
      githubIssueNumber: item.githubIssueNumber,
    );

    return KanbanBoardModel(
      projectId: board.projectId,
      totalItems: board.totalItems,
      todo: targetStatus == 'TODO'
          ? [...removeFrom(board.todo), updatedItem]
          : removeFrom(board.todo),
      inProgress: targetStatus == 'IN_PROGRESS'
          ? [...removeFrom(board.inProgress), updatedItem]
          : removeFrom(board.inProgress),
      blocked: targetStatus == 'BLOCKED'
          ? [...removeFrom(board.blocked), updatedItem]
          : removeFrom(board.blocked),
      completed: targetStatus == 'COMPLETED'
          ? [...removeFrom(board.completed), updatedItem]
          : removeFrom(board.completed),
    );
  }

  Future<void> _moveItem(
    BuildContext context,
    KanbanCardModel item,
    KanbanBoardModel board,
    String targetStatus,
  ) async {
    // 1. Apply optimistic update immediately
    final optimisticBoard = _applyOptimisticMove(board, item, targetStatus);
    setState(() => _localBoard = optimisticBoard);

    try {
      final targetItems = board.columns[targetStatus] ?? [];
      final lastOrder = targetItems.isEmpty ? 0.0 : targetItems.last.order;
      await ref.read(projectsControllerProvider).moveBoardItem(
            projectId: widget.projectId,
            entityType: item.type,
            entityId: item.id,
            targetStatus: targetStatus,
            prevOrder: lastOrder > 0 ? lastOrder : null,
          );
      // Clear local board so provider data takes over on next refresh
      if (mounted) setState(() => _localBoard = null);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${item.title} moved to ${_labelFor(targetStatus)}'),
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
      // Roll back by discarding the local state and invalidating the provider
      if (mounted) setState(() => _localBoard = null);
      ref.invalidate(projectBoardProvider(widget.projectId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Move failed: ${e.toString()}'),
          backgroundColor: AppSemanticColors.of(context).danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _labelFor(String status) {
    final idx = _columnKeys.indexOf(status);
    return idx >= 0 ? _columnLabels[idx] : status;
  }

  void _showMoveSheet(
      BuildContext context, KanbanCardModel item, KanbanBoardModel board) {
    final currentStatus = item.type == 'BUG'
        ? _bugStatusToBoard(item.status)
        : (item.isCompleted ? 'COMPLETED' : item.status);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 2,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                    '${item.type} · ${item.priority} Priority',
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant)),
                const Divider(height: 20),
                const Text('Move to:',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _columnKeys
                      .where((k) => k != currentStatus)
                      .map((key) => ActionChip(
                            label: Text(_labelFor(key)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _moveItem(context, item, board, key);
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _bugStatusToBoard(String bugStatus) {
    switch (bugStatus.toUpperCase()) {
      case 'RESOLVED':
      case 'CLOSED':
        return 'COMPLETED';
      case 'IN_PROGRESS':
        return 'IN_PROGRESS';
      default:
        return 'TODO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(projectBoardProvider(widget.projectId));
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;
    final semantics = AppSemanticColors.of(context);

    return boardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(projectBoardProvider(widget.projectId)),
      ),
      data: (serverBoard) {
        // Use optimistic local board if available, otherwise fall back to server
        final board = _localBoard ?? serverBoard;
        final columnsMap = _buildColumnsMap(board);

        return LayoutBuilder(builder: (context, constraints) {
          final isPhone = constraints.maxWidth < 600;

          if (isPhone) {
            final activeKey = _columnKeys[_phoneColIdx];
            final activeItems = columnsMap[activeKey] ?? [];

            return Column(
              children: [
                Container(
                  color: colorScheme.surfaceContainerHighest.withAlpha(30),
                  child: Row(
                    children: _columnKeys.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final key = entry.value;
                      final count = (columnsMap[key] ?? []).length;
                      final selected = _phoneColIdx == idx;
                      return Expanded(
                        child: DragTarget<KanbanCardModel>(
                          onWillAcceptWithDetails: (details) =>
                              details.data.status != key,
                          onAcceptWithDetails: (details) {
                            AppHaptics.selection();
                            _moveItem(context, details.data, board, key);
                          },
                          builder: (context, candidateData, rejectedData) {
                            final isHovered = candidateData.isNotEmpty;
                            return InkWell(
                              onTap: () {
                                AppHaptics.selection();
                                setState(() => _phoneColIdx = idx);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isHovered
                                      ? primaryRed.withAlpha(200)
                                      : (selected
                                          ? primaryRed
                                          : Colors.transparent),
                                  border: selected
                                      ? null
                                      : Border(
                                          bottom: BorderSide(
                                              color: colorScheme
                                                  .outlineVariant
                                                  .withAlpha(40))),
                                ),
                                child: Text(
                                  '${_columnLabels[idx]} ($count)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selected || isHovered
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: selected || isHovered
                                        ? Colors.white
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: activeItems.isEmpty
                      ? Center(
                          child: Text('No items',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant
                                      .withAlpha(120))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: activeItems.length,
                          itemBuilder: (context, idx) {
                            final item = activeItems[idx];
                            return _buildCard(context, item, board,
                                colorScheme, semantics, primaryRed);
                          },
                        ),
                ),
              ],
            );
          }

          // Tablet / Desktop Drag-and-Drop Columns
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _columnKeys.asMap().entries.map((entry) {
                final idx = entry.key;
                final colKey = entry.value;
                final items = columnsMap[colKey] ?? [];

                return DragTarget<KanbanCardModel>(
                  onWillAcceptWithDetails: (details) =>
                      details.data.status != colKey,
                  onAcceptWithDetails: (details) {
                    AppHaptics.selection();
                    _moveItem(context, details.data, board, colKey);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovered = candidateData.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? primaryRed.withAlpha(18)
                            : colorScheme.surfaceContainerHighest
                                .withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isHovered
                              ? primaryRed
                              : colorScheme.outlineVariant.withAlpha(30),
                          width: isHovered ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: isHovered
                                        ? primaryRed
                                        : primaryRed.withAlpha(180),
                                    width: 3),
                                bottom: BorderSide(
                                    color: colorScheme.outlineVariant
                                        .withAlpha(30)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_columnLabels[idx],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        colorScheme.surfaceContainerHigh,
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text('${items.length}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme
                                              .onSurfaceVariant)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: items.isEmpty
                                ? Center(
                                    child: Text(
                                      isHovered ? 'Drop here' : 'Empty',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isHovered
                                              ? FontWeight.w700
                                              : FontWeight.normal,
                                          color: isHovered
                                              ? primaryRed
                                              : colorScheme
                                                  .onSurfaceVariant
                                                  .withAlpha(100)),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(10),
                                    itemCount: items.length,
                                    itemBuilder: (ctx, itemIdx) {
                                      final item = items[itemIdx];
                                      return _buildCard(
                                          ctx,
                                          item,
                                          board,
                                          colorScheme,
                                          semantics,
                                          primaryRed);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          );
        });
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    KanbanCardModel item,
    KanbanBoardModel board,
    ColorScheme colorScheme,
    AppSemanticColors semantics,
    Color primaryRed,
  ) {
    final cardContent = _buildCardContent(
      context,
      item,
      board,
      colorScheme,
      semantics,
      primaryRed,
      isDragging: false,
    );

    return LongPressDraggable<KanbanCardModel>(
      data: item,
      delay: const Duration(milliseconds: 180),
      hapticFeedbackOnStart: true,
      feedback: Material(
        elevation: 8,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 270,
          child: _buildCardContent(
            context,
            item,
            board,
            colorScheme,
            semantics,
            primaryRed,
            isDragging: true,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: cardContent,
      ),
      child: cardContent,
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    KanbanCardModel item,
    KanbanBoardModel board,
    ColorScheme colorScheme,
    AppSemanticColors semantics,
    Color primaryRed, {
    required bool isDragging,
  }) {
    Color typeColor = primaryRed;
    IconData typeIcon = Icons.task_outlined;
    if (item.type == 'FEATURE') {
      typeColor = semantics.success;
      typeIcon = Icons.star_outline_rounded;
    } else if (item.type == 'BUG') {
      final sev = item.severity?.toUpperCase() ?? 'MAJOR';
      typeColor = sev == 'CRITICAL' ? semantics.danger : semantics.warning;
      typeIcon = Icons.bug_report_outlined;
    }

    final isPriorityHigh = item.priority.toUpperCase() == 'CRITICAL' ||
        item.priority.toUpperCase() == 'HIGH';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDragging
              ? primaryRed.withAlpha(120)
              : colorScheme.outlineVariant.withAlpha(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDragging ? 25 : 7),
            blurRadius: isDragging ? 12 : 8,
            offset: Offset(0, isDragging ? 6 : 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcon, size: 14, color: typeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              if (!isDragging)
                GestureDetector(
                  onTap: () => _showMoveSheet(context, item, board),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryRed.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Move',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryRed),
                    ),
                  ),
                ),
            ],
          ),
          if (item.type == 'BUG' && item.severity != null) ...[
            const SizedBox(height: 4),
            Text(
              'Severity: ${item.severity}',
              style: TextStyle(
                  fontSize: 10,
                  color: typeColor,
                  fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color:
                      isPriorityHigh ? primaryRed : colorScheme.outline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                item.priority,
                style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant.withAlpha(140),
                    fontWeight: FontWeight.w600),
              ),
              if (item.milestone != null && item.milestone!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.flag_outlined,
                    size: 11,
                    color: colorScheme.primary),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    item.milestone!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
              if (item.githubIssueNumber != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.link_rounded,
                    size: 12,
                    color: colorScheme.onSurfaceVariant.withAlpha(120)),
                const SizedBox(width: 3),
                Text('#${item.githubIssueNumber}',
                    style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant
                            .withAlpha(120))),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
