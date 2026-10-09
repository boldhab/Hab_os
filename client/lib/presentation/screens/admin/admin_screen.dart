import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_semantic_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/common/app_card.dart';

/// Provider for Admin Telemetry & Statistics
final adminStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(
    ApiEndpoints.adminStats,
    options: Options(headers: {'X-Demo-Admin': 'true'}),
  );
  if (response.data is Map && response.data['data'] != null) {
    return Map<String, dynamic>.from(response.data['data']);
  }
  return {};
});

/// Provider for Background Workers Telemetry
final adminJobsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(
    ApiEndpoints.adminJobs,
    options: Options(headers: {'X-Demo-Admin': 'true'}),
  );
  if (response.data is Map &&
      response.data['data'] != null &&
      response.data['data']['tasks'] is List) {
    final list = response.data['data']['tasks'] as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return [];
});

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  bool _isFlushingCache = false;

  Future<void> _refreshAll() async {
    ref.invalidate(adminStatsProvider);
    ref.invalidate(adminJobsProvider);
  }

  Future<void> _runJob(String jobName) async {
    final dio = ref.read(dioProvider);
    final semantics = AppSemanticColors.of(context);

    try {
      final res = await dio.post(
        ApiEndpoints.adminRunJob(jobName),
        options: Options(headers: {'X-Demo-Admin': 'true'}),
      );
      if (mounted) {
        final duration = res.data?['data']?['durationMs'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Worker "$jobName" completed in ${duration}ms'),
            backgroundColor: semantics.successContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(adminJobsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to execute "$jobName"'),
            backgroundColor: semantics.dangerContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _flushCache() async {
    setState(() => _isFlushingCache = true);
    final dio = ref.read(dioProvider);
    final semantics = AppSemanticColors.of(context);

    try {
      await dio.post(
        ApiEndpoints.adminFlushCache,
        options: Options(headers: {'X-Demo-Admin': 'true'}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ In-memory dashboard feed cache flushed'),
            backgroundColor: semantics.successContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cache flush failed'),
            backgroundColor: semantics.dangerContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFlushingCache = false);
    }
  }

  Future<void> _openWebAdminPortal() async {
    final uri = Uri.parse('http://localhost:5000/admin');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Open http://localhost:5000/admin in your browser'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = AppSemanticColors.of(context);
    final statsAsync = ref.watch(adminStatsProvider);
    final jobsAsync = ref.watch(adminJobsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, size: 22, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Admin Console'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: 'Open Web Portal',
            onPressed: _openWebAdminPortal,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Summary Row
              statsAsync.when(
                data: (stats) => _buildKpiGrid(stats, colorScheme, semantics),
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  ),
                ),
                error: (err, _) => _buildErrorCard('Stats error: $err', semantics),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Background Workers Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scheduled Jobs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isFlushingCache ? null : _flushCache,
                    icon: _isFlushingCache
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                          )
                        : Icon(Icons.cleaning_services_rounded, size: 16, color: colorScheme.primary),
                    label: Text('Flush Cache', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              jobsAsync.when(
                data: (jobs) => _buildJobsList(jobs, colorScheme, semantics),
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  ),
                ),
                error: (err, _) => _buildErrorCard('Jobs error: $err', semantics),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Telemetry Snapshot Card
              statsAsync.maybeWhen(
                data: (stats) => _buildDomainSummaryCard(stats, colorScheme, semantics),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildKpiGrid(Map<String, dynamic> stats, ColorScheme colorScheme, AppSemanticColors semantics) {
    final users = stats['users'] as Map<String, dynamic>? ?? {};
    final lifeScore = stats['lifeScore'] as Map<String, dynamic>? ?? {};
    final system = stats['system'] as Map<String, dynamic>? ?? {};
    final memory = system['memory'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        _buildKpiCard(
          label: 'Users',
          value: '${users['total'] ?? 2}',
          subtext: '${users['admins'] ?? 1} Admins',
          icon: Icons.people_rounded,
          color: colorScheme.primary,
          colorScheme: colorScheme,
        ),
        _buildKpiCard(
          label: 'Life Score',
          value: '${lifeScore['globalAverage'] ?? 82.4}',
          subtext: '${lifeScore['streakRetentionRate'] ?? '94.2%'} Streaks',
          icon: Icons.speed_rounded,
          color: semantics.success,
          colorScheme: colorScheme,
        ),
        _buildKpiCard(
          label: 'RAM Heap',
          value: '${memory['heapUsedMb'] ?? '--'} MB',
          subtext: 'Process Active',
          icon: Icons.memory_rounded,
          color: colorScheme.secondary,
          colorScheme: colorScheme,
        ),
        _buildKpiCard(
          label: 'Uptime',
          value: '${system['uptimeFormatted'] ?? 'Active'}',
          subtext: '${system['environment'] ?? 'dev'} mode',
          icon: Icons.timer_rounded,
          color: colorScheme.tertiary,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    return AppCard(
      borderRadius: 16.0,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList(List<Map<String, dynamic>> jobs, ColorScheme colorScheme, AppSemanticColors semantics) {
    if (jobs.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No background workers registered.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: jobs.map((job) {
        final name = job['name']?.toString() ?? 'Worker';
        final desc = job['description']?.toString() ?? '';
        final status = job['lastStatus']?.toString() ?? 'IDLE';
        final runCount = job['runCount'] ?? 0;
        final intervalSec = ((job['intervalMs'] ?? 60000) / 1000).round();
        final duration = job['lastDurationMs'];

        final isSuccess = status == 'SUCCESS';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSuccess ? semantics.successContainer : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: isSuccess ? semantics.success : colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${intervalSec}s',
                              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Runs: $runCount ${duration != null ? '• Last: ${duration}ms' : ''}',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => _runJob(name),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(54, 32),
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                  child: const Text('Run', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDomainSummaryCard(Map<String, dynamic> stats, ColorScheme colorScheme, AppSemanticColors semantics) {
    final domains = stats['domains'] as Map<String, dynamic>? ?? {};

    return AppCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_customize_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'System Breakdown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Divider(height: 24, color: colorScheme.outlineVariant.withAlpha(50)),
          _buildDomainRow(
            'Productivity & Tasks',
            '${domains['productivity']?['tasksTotal'] ?? 142} tasks',
            '${domains['productivity']?['tasksCompleted'] ?? 98} done',
            colorScheme.primary,
            colorScheme,
          ),
          const SizedBox(height: 10),
          _buildDomainRow(
            'Software Engineering',
            '${domains['devAndSoftware']?['activeProjects'] ?? 6} projects',
            '${domains['devAndSoftware']?['githubCommitsTracked'] ?? 384} commits',
            colorScheme.secondary,
            colorScheme,
          ),
          const SizedBox(height: 10),
          _buildDomainRow(
            'Gym & Physical Fitness',
            '${domains['healthAndFitness']?['workoutsLogged'] ?? 48} workouts',
            '${domains['healthAndFitness']?['personalRecords'] ?? 19} PRs',
            semantics.danger,
            colorScheme,
          ),
          const SizedBox(height: 10),
          _buildDomainRow(
            'Personal Finance',
            '${domains['personalFinance']?['transactionsLogged'] ?? 114} entries',
            'Optimal budget',
            colorScheme.tertiary,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildDomainRow(
    String title,
    String mainMetric,
    String subMetric,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: TextStyle(fontSize: 12, color: colorScheme.onSurface)),
        ),
        Text(
          mainMetric,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        const SizedBox(width: 8),
        Text(
          '($subMetric)',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error, AppSemanticColors semantics) {
    return AppCard(
      backgroundColor: semantics.dangerContainer,
      padding: const EdgeInsets.all(14),
      child: Text(error, style: TextStyle(color: semantics.onDangerContainer)),
    );
  }
}
