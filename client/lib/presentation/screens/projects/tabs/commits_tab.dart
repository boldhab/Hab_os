import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/app_error_state.dart';
import '../controllers/projects_controller.dart';

class GitHubCommitsTab extends ConsumerWidget {
  final String projectId;
  final String? repoUrl;
  const GitHubCommitsTab({super.key, required this.projectId, required this.repoUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commitsAsync = ref.watch(projectCommitsProvider(projectId));
    final colorScheme = Theme.of(context).colorScheme;

    if (repoUrl == null || repoUrl!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code_rounded,
                  size: 40,
                  color: colorScheme.onSurfaceVariant.withAlpha(120)),
              const SizedBox(height: 12),
              const Text('No repository linked',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Edit this project and add a GitHub repository URL to track commits.',
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withAlpha(160)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return commitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(projectCommitsProvider(projectId)),
      ),
      data: (result) {
        // Render contextual error banner when GitHub API was unreachable
        if (result.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 40,
                      color: colorScheme.onSurfaceVariant.withAlpha(120)),
                  const SizedBox(height: 12),
                  const Text('Unable to sync remote commits',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    result.message ??
                        'GitHub API is temporarily unavailable.',
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withAlpha(160)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(projectCommitsProvider(projectId)),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (result.commits.isEmpty) {
          return Center(
            child: Text('No commits recorded.',
                style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant.withAlpha(140))),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: result.commits.length,
          itemBuilder: (context, i) {
            final c = result.commits[i];
            final shortSha = c.sha.length >= 7 ? c.sha.substring(0, 7) : c.sha;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colorScheme.outlineVariant.withAlpha(30)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(shortSha,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: colorScheme.primary,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(
                          '${c.authorName} · ${c.timestamp.split('T')[0]}',
                          style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant
                                  .withAlpha(140)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
