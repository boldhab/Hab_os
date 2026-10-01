import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../providers/focus_provider.dart';
import 'widgets/focus_timer_gauge.dart';
import 'widgets/focus_controls.dart';
import 'widgets/focus_category_duration_picker.dart';
import 'widgets/focus_stats_row.dart';
import 'widgets/focus_session_history.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusProvider);
    final notifier = ref.read(focusProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final primaryRed = colorScheme.primary;

    final isIdle = state.status == PomodoroStatus.idle;

    // Listen for session completion transition for celebration haptics
    ref.listen<FocusState>(focusProvider, (prev, next) {
      if (prev?.status == PomodoroStatus.running &&
          next.status == PomodoroStatus.idle) {
        AppHaptics.celebration();
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Focus',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              _getFormattedDate(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant.withAlpha(180),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: colorScheme.onSurfaceVariant),
            tooltip: 'Refresh stats',
            onPressed: () {
              AppHaptics.light();
              notifier.loadTodayData();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          if (isWide) {
            // Wide Screen / Tablet / Landscape 2-Pane View
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSessionCockpit(
                            context,
                            state: state,
                            notifier: notifier,
                            isIdle: isIdle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: colorScheme.outlineVariant.withAlpha(40),
                ),
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsSurface(context, state),
                        AppSpacing.verticalGapXl,
                        FocusSessionHistory(
                          state: state,
                          notifier: notifier,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile Standard View
          return RefreshIndicator(
            onRefresh: () => notifier.loadTodayData(),
            color: primaryRed,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  _buildSessionCockpit(
                    context,
                    state: state,
                    notifier: notifier,
                    isIdle: isIdle,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: isIdle
                        ? Column(
                            children: [
                              const SizedBox(height: 32),
                              _buildStatsSurface(context, state),
                              const SizedBox(height: 32),
                              FocusSessionHistory(
                                state: state,
                                notifier: notifier,
                              ),
                              const SizedBox(height: 24),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionCockpit(
    BuildContext context, {
    required FocusState state,
    required FocusNotifier notifier,
    required bool isIdle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withAlpha(18),
            colorScheme.surfaceContainerLow,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.primary.withAlpha(38)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isIdle ? 'Make space to think' : 'Stay with the moment',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                isIdle ? Icons.self_improvement_rounded : Icons.bolt_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FocusTimerGauge(
            state: state,
            pulseAnimation: _pulseAnimation,
          ),
          const SizedBox(height: 14),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isIdle
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: FocusCategoryDurationPicker(
                      key: const ValueKey('picker'),
                      state: state,
                      notifier: notifier,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
          FocusControls(state: state, notifier: notifier),
        ],
      ),
    );
  }

  Widget _buildStatsSurface(BuildContext context, FocusState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(55)),
      ),
      child: FocusStatsRow(state: state),
    );
  }
}
