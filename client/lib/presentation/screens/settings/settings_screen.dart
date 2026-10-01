import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_semantic_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../widgets/common/app_card.dart';
import '../../providers/theme_provider.dart';

Widget buildSettingsDetailHeader(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color accent,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          accent,
          Color.lerp(accent, Colors.black, 0.18) ?? accent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.24),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleLarge(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.bodySmall(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildSettingsDetailCardToggle(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
  Color? accent,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final activeColor = accent ?? AppColors.primaryRed;

  return Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: activeColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge(context).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall(context).copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = AppSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hairlineColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.titleLarge(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroProfileCard(context, user),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickSettingPill(
                          context,
                          icon: Icons.lock_outline_rounded,
                          label: 'Security',
                          accent: semantics.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildQuickSettingPill(
                          context,
                          icon: Icons.palette_outlined,
                          label: 'Appearance',
                          accent: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionHeader(context, 'Account'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsNavigationRow(
                          context,
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.primaryRed,
                          title: 'Personal Information',
                          subtitle: 'Student info, bio & contact details',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const _PersonalInfoScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: hairlineColor),
                        _buildSettingsNavigationRow(
                          context,
                          icon: Icons.lock_reset_rounded,
                          iconColor: AppColors.primaryRed,
                          title: 'Password & Security',
                          subtitle: 'Last changed 24 days ago',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const _PasswordSecurityScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionHeader(context, 'Preferences'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsNavigationRow(
                          context,
                          icon: Icons.track_changes_rounded,
                          iconColor: AppColors.primaryRed,
                          title: 'Life Score Weights',
                          subtitle: 'Balance your daily impact',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const _LifeScoreSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: hairlineColor),
                        _buildSettingsNavigationRow(
                          context,
                          icon: Icons.notifications_active_outlined,
                          iconColor: AppColors.primaryRed,
                          title: 'Notifications',
                          subtitle: 'Reminders, quiet hours, and alerts',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const _NotificationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: hairlineColor),
                        _buildSettingsNavigationRow(
                          context,
                          icon: Icons.palette_outlined,
                          iconColor: AppColors.primaryRed,
                          title: 'Appearance',
                          subtitle: 'Theme, motion and personalization',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const _AppearanceSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: hairlineColor),
                        _buildSettingsNavigationRow(
                          context,
                          icon: Icons.smartphone_rounded,
                          iconColor: AppColors.primaryRed,
                          title: 'App Behavior',
                          subtitle: 'Start page and smart automation',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const _AppBehaviorSettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionHeader(context, 'Security & Data'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsNavigationRow(
                          context,
                          icon: Icons.shield_outlined,
                          iconColor: semantics.success,
                          title: 'Security & Privacy',
                          subtitle: 'App lock, sessions and export',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const _SecurityPrivacyScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: hairlineColor),
                        _buildSettingsNavigationRow(
                          context,
                          icon: Icons.link_rounded,
                          iconColor: colorScheme.primary,
                          title: 'Connected Accounts',
                          subtitle: 'Google, GitHub and calendar',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const _ConnectedAccountsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionHeader(context, 'About'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsNavigationRow(
                          context,
                          icon: Icons.info_outline_rounded,
                          iconColor: colorScheme.primary,
                          title: 'About HABos',
                          subtitle: 'Version 1.0.0 • Help & terms',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const _AboutSettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _confirmSignOut(context),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign Out'),
                      style: FilledButton.styleFrom(
                        backgroundColor: semantics.danger,
                        foregroundColor: semantics.onDanger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text(
                      'Made with ❤️ for better habits.',
                      style: AppTypography.bodySmall(context).copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Main Screen Helper Widgets ──────────────────────────────────────────────

  Widget _buildHeroProfileCard(BuildContext context, dynamic user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            Color.lerp(colorScheme.primary, Colors.black, 0.18) ??
                colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(24),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha(55),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                user?.name != null && user!.name!.isNotEmpty
                    ? user.name![0].toUpperCase()
                    : 'H',
                style: AppTypography.h2(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Habtamu Befekadu',
                  style: AppTypography.titleLarge(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Student • DBU • Developer',
                    style: AppTypography.bodySmall(context).copyWith(
                      color: Colors.white.withAlpha(220),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'habtamu@example.com',
                  style: AppTypography.bodySmall(context).copyWith(
                    color: Colors.white.withAlpha(220),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _PersonalInfoScreen(),
                ),
              );
            },
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm, top: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelMedium(context).copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsNavigationRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        AppHaptics.light();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSettingPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color accent,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelLarge(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final semantics = AppSemanticColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of HABos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: semantics.danger,
              foregroundColor: semantics.onDanger,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      AppHaptics.medium();
      await ref.read(authProvider.notifier).logout();
    }
  }
}

// =============================================================================
// DETAIL SUB-PAGES
// =============================================================================

// ── 1. NOTIFICATION SETTINGS DETAIL SCREEN ──────────────────────────────────
class _NotificationSettingsScreen extends StatefulWidget {
  const _NotificationSettingsScreen();

  @override
  State<_NotificationSettingsScreen> createState() =>
      __NotificationSettingsScreenState();
}

class __NotificationSettingsScreenState
    extends State<_NotificationSettingsScreen> {
  bool _dailyReminder = true;
  bool _habitReminders = true;
  bool _taskDeadlines = true;
  bool _focusReminder = true;
  bool _workoutReminder = false;
  bool _financeReminder = false;
  bool _streakMilestones = true;

  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hairlineColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSettingsDetailHeader(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  subtitle:
                      'Stay on top of goals, reminders and important moments',
                  accent: AppColors.primaryRed,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.notifications_active_outlined,
                        title: 'Daily Reminder',
                        subtitle: 'Morning summary & daily planning push',
                        value: _dailyReminder,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _dailyReminder = v);
                        },
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.repeat_rounded,
                        title: 'Habit Reminders',
                        subtitle: 'Nudges for scheduled routine habits',
                        value: _habitReminders,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _habitReminders = v);
                        },
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.alarm_rounded,
                        title: 'Task Deadlines',
                        subtitle: 'Alerts before upcoming task due dates',
                        value: _taskDeadlines,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _taskDeadlines = v);
                        },
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.timer_outlined,
                        title: 'Focus Session Reminder',
                        subtitle: 'Break times and session completion',
                        value: _focusReminder,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _focusReminder = v);
                        },
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.fitness_center_rounded,
                        title: 'Workout Reminder',
                        subtitle: 'Gym and physical activity prompts',
                        value: _workoutReminder,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _workoutReminder = v);
                        },
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Finance Reminder',
                        subtitle: 'Budget tracking and subscription alerts',
                        value: _financeReminder,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _financeReminder = v);
                        },
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.local_fire_department_rounded,
                        title: 'Streak Milestones',
                        subtitle: 'Celebrations for habit streak targets',
                        value: _streakMilestones,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _streakMilestones = v);
                        },
                        accent: AppColors.primaryRed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Notification Schedule',
                    style: AppTypography.labelLarge(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Morning Reminder'),
                        subtitle: Text(_morningTime.format(context)),
                        trailing: const Icon(Icons.access_time_rounded),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _morningTime,
                          );
                          if (time != null) {
                            setState(() => _morningTime = time);
                          }
                        },
                      ),
                      Divider(height: 1, color: hairlineColor),
                      ListTile(
                        title: const Text('Evening Review'),
                        subtitle: Text(_eveningTime.format(context)),
                        trailing: const Icon(Icons.access_time_rounded),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _eveningTime,
                          );
                          if (time != null) {
                            setState(() => _eveningTime = time);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 2. LIFE SCORE SETTINGS DETAIL SCREEN ────────────────────────────────────
class _LifeScoreSettingsScreen extends ConsumerStatefulWidget {
  const _LifeScoreSettingsScreen();

  @override
  ConsumerState<_LifeScoreSettingsScreen> createState() =>
      __LifeScoreSettingsScreenState();
}

class __LifeScoreSettingsScreenState
    extends ConsumerState<_LifeScoreSettingsScreen> {
  bool _savingWeights = false;
  double _initialHabits = 30;
  double _initialTasks = 20;
  double _initialFocus = 20;
  double _initialGym = 15;
  double _initialFinance = 15;

  late double _weightHabits;
  late double _weightTasks;
  late double _weightFocus;
  late double _weightGym;
  late double _weightFinance;

  @override
  void initState() {
    super.initState();
    _weightHabits = _initialHabits;
    _weightTasks = _initialTasks;
    _weightFocus = _initialFocus;
    _weightGym = _initialGym;
    _weightFinance = _initialFinance;
  }

  bool get _hasWeightChanges {
    return _weightHabits != _initialHabits ||
        _weightTasks != _initialTasks ||
        _weightFocus != _initialFocus ||
        _weightGym != _initialGym ||
        _weightFinance != _initialFinance;
  }

  double get _totalWeight =>
      _weightHabits + _weightTasks + _weightFocus + _weightGym + _weightFinance;

  @override
  Widget build(BuildContext context) {
    final semantics = AppSemanticColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Score Weights'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSettingsDetailHeader(
                  context,
                  icon: Icons.track_changes_rounded,
                  title: 'Life Score',
                  subtitle:
                      'Tune how your daily routines influence your personal momentum',
                  accent: AppColors.primaryRed,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Life Score',
                            style: AppTypography.bodyMedium(context).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '78 / 100',
                              style: AppTypography.h3(context).copyWith(
                                color: AppColors.primaryRed,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSliderRow('Habits', _weightHabits,
                          (v) => setState(() => _weightHabits = v)),
                      _buildSliderRow('Tasks', _weightTasks,
                          (v) => setState(() => _weightTasks = v)),
                      _buildSliderRow('Focus', _weightFocus,
                          (v) => setState(() => _weightFocus = v)),
                      _buildSliderRow('Fitness', _weightGym,
                          (v) => setState(() => _weightGym = v)),
                      _buildSliderRow('Finance', _weightFinance,
                          (v) => setState(() => _weightFinance = v)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _totalWeight == 100
                                ? 'Weights balanced correctly'
                                : 'Weights sum to ${_totalWeight.toInt()}% (target 100%)',
                            style: AppTypography.bodySmall(context).copyWith(
                              color: _totalWeight == 100
                                  ? semantics.success
                                  : semantics.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _totalWeight == 100
                                  ? semantics.successContainer
                                      .withValues(alpha: 0.6)
                                  : semantics.warningContainer
                                      .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Total ${_totalWeight.toInt()}%',
                              style: AppTypography.labelSmall(context).copyWith(
                                color: _totalWeight == 100
                                    ? semantics.success
                                    : semantics.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                AppHaptics.light();
                                setState(() {
                                  _weightHabits = 30;
                                  _weightTasks = 20;
                                  _weightFocus = 20;
                                  _weightGym = 15;
                                  _weightFinance = 15;
                                });
                              },
                              child: const Text('Reset default'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: (_hasWeightChanges && !_savingWeights)
                                  ? () async {
                                      setState(() => _savingWeights = true);
                                      try {
                                        final dio = ref.read(dioProvider);
                                        await dio.put(
                                            ApiEndpoints.updatePreferences,
                                            data: {
                                              'lifeScoreWeights': {
                                                'habits': _weightHabits,
                                                'tasks': _weightTasks,
                                                'focus': _weightFocus,
                                                'gym': _weightGym,
                                                'finance': _weightFinance,
                                              }
                                            });
                                        setState(() {
                                          _initialHabits = _weightHabits;
                                          _initialTasks = _weightTasks;
                                          _initialFocus = _weightFocus;
                                          _initialGym = _weightGym;
                                          _initialFinance = _weightFinance;
                                        });
                                        ref
                                            .read(dashboardProvider.notifier)
                                            .load(showLoading: false);
                                        if (mounted) {
                                          AppHaptics.success();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Life Score weights saved!')),
                                          );
                                        }
                                      } catch (_) {}
                                      if (mounted)
                                        setState(() => _savingWeights = false);
                                    }
                                  : null,
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed),
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow(
      String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
              width: 70,
              child: Text(label, style: AppTypography.bodyMedium(context))),
          Expanded(
            child: Slider(
              value: value,
              min: 0,
              max: 50,
              divisions: 50,
              activeColor: AppColors.primaryRed,
              onChanged: (v) {
                AppHaptics.light();
                onChanged(v);
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${value.toInt()}%',
              textAlign: TextAlign.end,
              style: AppTypography.labelMedium(context)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. APPEARANCE SETTINGS DETAIL SCREEN ────────────────────────────────────
class _AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const _AppearanceSettingsScreen();

  @override
  ConsumerState<_AppearanceSettingsScreen> createState() =>
      __AppearanceSettingsScreenState();
}

class __AppearanceSettingsScreenState
    extends ConsumerState<_AppearanceSettingsScreen> {
  bool _enableAnimations = true;
  bool _enableHaptics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance & Theme'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSettingsDetailHeader(
                  context,
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Fine-tune mood, motion and how HABos feels to you',
                  accent: AppColors.primaryRed,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Mode',
                        style: AppTypography.bodyMedium(context)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Light'),
                              icon: Icon(Icons.light_mode_rounded),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Dark'),
                              icon: Icon(Icons.dark_mode_rounded),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('System'),
                              icon: Icon(Icons.brightness_auto_rounded),
                            ),
                          ],
                          selected: {ref.watch(themeProvider)},
                          onSelectionChanged: (selection) {
                            AppHaptics.selection();
                            ref
                                .read(themeProvider.notifier)
                                .setThemeMode(selection.first);
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Accent Color',
                              style: AppTypography.bodyMedium(context)),
                          Chip(
                            avatar: const Text('🔥'),
                            label: Text('Ember',
                                style: TextStyle(color: AppColors.primaryRed)),
                            backgroundColor:
                                AppColors.primaryRed.withValues(alpha: 0.12),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.sm),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.motion_photos_on_rounded,
                        title: 'Animations',
                        subtitle: 'Fluid UI micro-transitions',
                        value: _enableAnimations,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _enableAnimations = v);
                        },
                        accent: AppColors.primaryRed,
                      ),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.vibration_rounded,
                        title: 'Haptic Feedback',
                        subtitle: 'Tactile physical vibrations',
                        value: _enableHaptics,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _enableHaptics = v);
                        },
                        accent: AppColors.primaryRed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 4. APP BEHAVIOR DETAIL SCREEN ───────────────────────────────────────────
class _AppBehaviorSettingsScreen extends StatefulWidget {
  const _AppBehaviorSettingsScreen();

  @override
  State<_AppBehaviorSettingsScreen> createState() =>
      __AppBehaviorSettingsScreenState();
}

class __AppBehaviorSettingsScreenState
    extends State<_AppBehaviorSettingsScreen> {
  bool _autoStartFocus = false;
  bool _confirmTaskCompletion = true;
  bool _showCompletedHabits = true;
  String _startPage = 'Home';
  String _weekStartsOn = 'Monday';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Behavior'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                buildSettingsDetailHeader(
                  context,
                  icon: Icons.smartphone_rounded,
                  title: 'Behavior',
                  subtitle:
                      'Set the rhythm of your app experience and daily flow',
                  accent: AppColors.primaryRed,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Start Page'),
                        trailing: DropdownButton<String>(
                          value: _startPage,
                          underline: const SizedBox(),
                          items: ['Home', 'Tasks', 'Habits', 'Focus']
                              .map((p) =>
                                  DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _startPage = val);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.timer_rounded,
                        title: 'Auto-start Focus Timer',
                        subtitle: 'Jump directly into focus sessions',
                        value: _autoStartFocus,
                        onChanged: (v) => setState(() => _autoStartFocus = v),
                        accent: AppColors.primaryRed,
                      ),
                      const Divider(height: 1),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.check_circle_rounded,
                        title: 'Confirm Task Completion',
                        subtitle: 'Double-check before marking a task done',
                        value: _confirmTaskCompletion,
                        onChanged: (v) =>
                            setState(() => _confirmTaskCompletion = v),
                        accent: AppColors.primaryRed,
                      ),
                      const Divider(height: 1),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.visibility_rounded,
                        title: 'Show Completed Habits',
                        subtitle: 'Keep finished habits visible in your feed',
                        value: _showCompletedHabits,
                        onChanged: (v) =>
                            setState(() => _showCompletedHabits = v),
                        accent: AppColors.primaryRed,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Week Starts On'),
                        trailing: DropdownButton<String>(
                          value: _weekStartsOn,
                          underline: const SizedBox(),
                          items: ['Monday', 'Sunday', 'Saturday']
                              .map((d) =>
                                  DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _weekStartsOn = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 5. SECURITY & PRIVACY DETAIL SCREEN ─────────────────────────────────────
class _SecurityPrivacyScreen extends StatefulWidget {
  const _SecurityPrivacyScreen();

  @override
  State<_SecurityPrivacyScreen> createState() => __SecurityPrivacyScreenState();
}

class __SecurityPrivacyScreenState extends State<_SecurityPrivacyScreen> {
  bool _appLock = false;

  @override
  Widget build(BuildContext context) {
    final semantics = AppSemanticColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Privacy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                buildSettingsDetailHeader(
                  context,
                  icon: Icons.shield_outlined,
                  title: 'Security',
                  subtitle:
                      'Protect your account and manage your data with confidence',
                  accent: semantics.success,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.fingerprint_rounded,
                        title: 'Biometric / App Lock',
                        subtitle: 'Require authentication to open HABos',
                        value: _appLock,
                        onChanged: (v) => setState(() => _appLock = v),
                        accent: semantics.success,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Active Sessions'),
                        subtitle: const Text('2 active devices logged in'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Active sessions inspected')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Export My Data'),
                        subtitle:
                            const Text('Download a JSON copy of all data'),
                        trailing: const Icon(Icons.download_rounded),
                        onTap: () {
                          AppHaptics.success();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Exporting HABos archive...')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AppHaptics.heavy();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Account?'),
                          content: const Text(
                              'This will permanently erase your HABos account.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel')),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: FilledButton.styleFrom(
                                  backgroundColor: semantics.danger),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.delete_forever_rounded,
                        color: semantics.danger),
                    label: Text('Delete Account',
                        style: TextStyle(color: semantics.danger)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: semantics.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 6. CONNECTED ACCOUNTS SCREEN ────────────────────────────────────────────
class _ConnectedAccountsScreen extends StatefulWidget {
  const _ConnectedAccountsScreen();

  @override
  State<_ConnectedAccountsScreen> createState() =>
      __ConnectedAccountsScreenState();
}

class __ConnectedAccountsScreenState extends State<_ConnectedAccountsScreen> {
  bool _google = true;
  bool _github = true;
  bool _calendar = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Accounts'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                buildSettingsDetailHeader(
                  context,
                  icon: Icons.link_rounded,
                  title: 'Connections',
                  subtitle: 'Link your essential tools and services to HABos',
                  accent: AppColors.primaryRed,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.g_mobiledata_rounded,
                        title: 'Google SSO',
                        subtitle: 'Fast sign-in across your devices',
                        value: _google,
                        onChanged: (v) => setState(() => _google = v),
                        accent: colorScheme.primary,
                      ),
                      const Divider(height: 1),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.code_rounded,
                        title: 'GitHub',
                        subtitle: 'Repositories & commits sync',
                        value: _github,
                        onChanged: (v) => setState(() => _github = v),
                        accent: colorScheme.primary,
                      ),
                      const Divider(height: 1),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.calendar_month_rounded,
                        title: 'Google Calendar',
                        subtitle: 'Keep your schedule in sync',
                        value: _calendar,
                        onChanged: (v) => setState(() => _calendar = v),
                        accent: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 7. PERSONAL INFORMATION SCREEN ──────────────────────────────────────────
class _PersonalInfoScreen extends ConsumerStatefulWidget {
  const _PersonalInfoScreen();

  @override
  ConsumerState<_PersonalInfoScreen> createState() =>
      __PersonalInfoScreenState();
}

class __PersonalInfoScreenState extends ConsumerState<_PersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController =
        TextEditingController(text: user?.name ?? 'Habtamu Befekadu');
    _bioController =
        TextEditingController(text: 'Full-Stack Developer • DBU Student');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                buildSettingsDetailHeader(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  subtitle: 'Keep your public information current and readable',
                  accent: AppColors.primaryRed,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Details',
                        style: AppTypography.titleMedium(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _bioController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Short Bio / Student Role',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            try {
                              final dio = ref.read(dioProvider);
                              await dio.put(ApiEndpoints.updateProfile, data: {
                                'name': _nameController.text.trim(),
                              });
                              await ref
                                  .read(authProvider.notifier)
                                  .checkAuthStatus();
                              if (mounted) {
                                AppHaptics.success();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Profile updated!')),
                                );
                              }
                            } catch (_) {}
                          },
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryRed),
                          child: const Text('Save Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 8. PASSWORD & SECURITY SCREEN ───────────────────────────────────────────
class _PasswordSecurityScreen extends StatelessWidget {
  const _PasswordSecurityScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password & Security'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                buildSettingsDetailHeader(
                  context,
                  icon: Icons.lock_reset_rounded,
                  title: 'Password',
                  subtitle: 'Keep your account protected and private',
                  accent: AppColors.primaryRed,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Credentials',
                        style: AppTypography.titleMedium(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            AppHaptics.success();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Password updated!')),
                            );
                          },
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryRed),
                          child: const Text('Update Password'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 9. ABOUT SETTINGS SCREEN ────────────────────────────────────────────────
class _AboutSettingsScreen extends StatelessWidget {
  const _AboutSettingsScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About HABos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                buildSettingsDetailHeader(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  subtitle:
                      'Built to make your habits and goals more intentional',
                  accent: AppColors.primaryRed,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.layers_rounded,
                            color: AppColors.primaryRed, size: 30),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'HABos Productivity Suite',
                        style: AppTypography.h3(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Version 1.0.0 (Build 2026.1)',
                        style: AppTypography.bodySmall(context).copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'HABos is your personal productivity operating system combining habits, tasks, focus sessions, fitness, finance, and academic tracking into a single Life Score.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium(context).copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
