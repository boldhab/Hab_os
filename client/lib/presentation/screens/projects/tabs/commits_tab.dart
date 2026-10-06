import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../widgets/app_error_state.dart';
import '../controllers/projects_controller.dart';
import '../dialogs/github_webhook_dialog.dart';

/// Live GitHub commit timeline feed and repository webhook sync status (UC-53 to UC-59)
class GitHubCommitsTab extends ConsumerStatefulWidget {
  final String projectId;
  final String? repoUrl;

  const GitHubCommitsTab({
    super.key,
    required this.projectId,
    required this.repoUrl,
  });

  @override
  ConsumerState<GitHubCommitsTab> createState() => _GitHubCommitsTabState();
}

class _GitHubCommitsTabState extends ConsumerState<GitHubCommitsTab> {
  Map<String, dynamic>? _webhookConfig;
  bool _isLoadingWebhook = false;

  @override
  void initState() {
    super.initState();
    _loadWebhookStatus();
  }

  Future<void> _loadWebhookStatus() async {
    if (widget.repoUrl == null || widget.repoUrl!.isEmpty) return;
    setState(() => _isLoadingWebhook = true);
    try {
      final config = await ref
          .read(projectsControllerProvider)
          .getWebhookConfig(widget.projectId);
      if (mounted) {
        setState(() {
          _webhookConfig = config;
          _isLoadingWebhook = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingWebhook = false);
      }
    }
  }

  String _formatRelativeTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    final dt = DateTime.tryParse(timestamp);
    if (dt == null) return timestamp.split('T')[0];

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commitsAsync = ref.watch(projectCommitsProvider(widget.projectId));
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.repoUrl == null || widget.repoUrl!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.code_rounded,
                  size: 28,
                  color: colorScheme.onSurfaceVariant.withAlpha(140),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No GitHub repository linked',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Edit this project and add a GitHub repository URL (e.g. https://github.com/owner/repo) to activate live commit tracking and automated webhooks.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant.withAlpha(160),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectCommitsProvider(widget.projectId));
        await _loadWebhookStatus();
      },
      color: colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          // 1. Webhook Sync Status Header Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: _buildWebhookSyncStatusCard(colorScheme, isDark),
            ),
          ),

          // 2. Commits Timeline Feed
          commitsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: AppErrorState(
                message: err.toString(),
                onRetry: () =>
                    ref.invalidate(projectCommitsProvider(widget.projectId)),
              ),
            ),
            data: (result) {
              if (result.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorState(result.message, colorScheme),
                );
              }

              if (result.commits.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.commit_rounded,
                            size: 40,
                            color: colorScheme.onSurfaceVariant.withAlpha(120),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No commits recorded yet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Push commits to your repository or configure the GitHub webhook to receive real-time push events.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant.withAlpha(150),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final commit = result.commits[index];
                      final isLast = index == result.commits.length - 1;
                      return _buildTimelineCommitTile(
                        commit,
                        isLast: isLast,
                        colorScheme: colorScheme,
                        isDark: isDark,
                      );
                    },
                    childCount: result.commits.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebhookSyncStatusCard(ColorScheme colorScheme, bool isDark) {
    final hasSecret = _webhookConfig?['hasSecret'] == true;
    final isWebhookActive = hasSecret || (_webhookConfig?['active'] == true);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isWebhookActive
              ? const Color(0xFF00B8A3).withAlpha(80)
              : colorScheme.outlineVariant.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isWebhookActive
                      ? const Color(0xFF00B8A3).withAlpha(25)
                      : Colors.amber.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWebhookActive
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 18,
                  color: isWebhookActive
                      ? const Color(0xFF00B8A3)
                      : Colors.amber[800],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isWebhookActive
                              ? 'GitHub Webhook Active'
                              : 'Webhook Not Configured',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isWebhookActive
                                ? const Color(0xFF00B8A3)
                                : Colors.amber[900],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isWebhookActive
                                ? const Color(0xFF00B8A3)
                                : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.repoUrl ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withAlpha(160),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => GitHubWebhookDialog.show(
                  context,
                  projectId: widget.projectId,
                  repoUrl: widget.repoUrl,
                ),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Configure', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.sensors_rounded,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 5),
              Text(
                'Live SSE event stream connected',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  ref.invalidate(projectCommitsProvider(widget.projectId));
                  _loadWebhookStatus();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Sync Now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCommitTile(
    dynamic commit, {
    required bool isLast,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final sha = commit.sha as String? ?? '';
    final shortSha = sha.length >= 7 ? sha.substring(0, 7) : sha;
    final message = commit.message as String? ?? '';
    final authorName = commit.authorName as String? ?? 'Developer';
    final timestamp = commit.timestamp as String? ?? '';
    final relativeTime = _formatRelativeTime(timestamp);

    // Split commit title and optional description
    final lines = message.split('\n');
    final title = lines.first;
    final description =
        lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Column: Node and Vertical Line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Node
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.commit_rounded,
                    size: 12,
                    color: colorScheme.primary,
                  ),
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.outlineVariant.withAlpha(80),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Commit Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant.withAlpha(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Commit SHA Chip
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: sha));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied commit SHA: $shortSha'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                shortSha,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.copy_rounded,
                                size: 10,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        relativeTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor:
                            colorScheme.primary.withAlpha(40),
                        child: Text(
                          authorName.isNotEmpty
                              ? authorName[0].toUpperCase()
                              : 'D',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        authorName,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? message, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: colorScheme.onSurfaceVariant.withAlpha(120),
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to sync remote commits',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'GitHub API is temporarily unavailable.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withAlpha(160),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  ref.invalidate(projectCommitsProvider(widget.projectId)),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
