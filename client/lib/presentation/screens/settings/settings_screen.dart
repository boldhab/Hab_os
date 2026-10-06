import 'package:dio/dio.dart';
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
import '../../widgets/app_badge.dart';

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
                          subtitle: 'Update account password & credentials',
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
                          trailingBadge: AppBadge.info(
                            label: 'Roadmap',
                            context: context,
                            size: AppBadgeSize.compact,
                          ),
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
                          trailingBadge: AppBadge.info(
                            label: 'Coming Soon',
                            context: context,
                            size: AppBadgeSize.compact,
                          ),
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
                    (user?.bio != null && (user!.bio as String).isNotEmpty)
                        ? user.bio!
                        : 'Student • DBU • Developer',
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
    Widget? trailingBadge,
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.bodyLarge(context).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (trailingBadge != null) ...[
                        const SizedBox(width: 8),
                        trailingBadge,
                      ],
                    ],
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
class _NotificationSettingsScreen extends ConsumerStatefulWidget {
  const _NotificationSettingsScreen();

  @override
  ConsumerState<_NotificationSettingsScreen> createState() =>
      __NotificationSettingsScreenState();
}

class __NotificationSettingsScreenState
    extends ConsumerState<_NotificationSettingsScreen> {
  bool _dailyReminder = true;
  bool _habitReminders = true;
  bool _taskDeadlines = true;
  bool _focusReminder = true;
  bool _workoutReminder = false;
  bool _financeReminder = false;
  bool _streakMilestones = true;

  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 6, minute: 30);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final storage = ref.read(secureStorageProvider);
    final userPrefs = ref.read(authProvider).user?.preferences;

    final daily = await storage.getBoolSetting('notif_dailyReminder');
    final habits = await storage.getBoolSetting('notif_habitReminders');
    final tasks = await storage.getBoolSetting('notif_taskDeadlines');
    final focus = await storage.getBoolSetting('notif_focusReminder');
    final workout = await storage.getBoolSetting('notif_workoutReminder');
    final finance = await storage.getBoolSetting('notif_financeReminder');
    final streak = await storage.getBoolSetting('notif_streakMilestones');

    final morningStr = await storage.getStringSetting('notif_morningTime');
    final eveningStr = await storage.getStringSetting('notif_eveningTime');

    final qStartStr = userPrefs?.quietHoursStart ??
        await storage.getStringSetting('notif_quietHoursStart') ??
        '22:30';
    final qEndStr = userPrefs?.quietHoursEnd ??
        await storage.getStringSetting('notif_quietHoursEnd') ??
        '06:30';

    if (mounted) {
      setState(() {
        if (daily != null) _dailyReminder = daily;
        if (habits != null) _habitReminders = habits;
        if (tasks != null) _taskDeadlines = tasks;
        if (focus != null) _focusReminder = focus;
        if (workout != null) _workoutReminder = workout;
        if (finance != null) _financeReminder = finance;
        if (streak != null) _streakMilestones = streak;

        if (morningStr != null && morningStr.contains(':')) {
          final parts = morningStr.split(':');
          _morningTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 8,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
        if (eveningStr != null && eveningStr.contains(':')) {
          final parts = eveningStr.split(':');
          _eveningTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 21,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
        if (qStartStr.contains(':')) {
          final parts = qStartStr.split(':');
          _quietStart = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 22,
            minute: int.tryParse(parts[1]) ?? 30,
          );
        }
        if (qEndStr.contains(':')) {
          final parts = qEndStr.split(':');
          _quietEnd = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 6,
            minute: int.tryParse(parts[1]) ?? 30,
          );
        }
      });
    }
  }

  Future<void> _updateToggle(
      String key, bool value, VoidCallback updateState) async {
    AppHaptics.selection();
    updateState();
    await ref.read(secureStorageProvider).saveBoolSetting(key, value);
  }

  Future<void> _saveQuietHours() async {
    final startStr =
        '${_quietStart.hour.toString().padLeft(2, '0')}:${_quietStart.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${_quietEnd.hour.toString().padLeft(2, '0')}:${_quietEnd.minute.toString().padLeft(2, '0')}';

    final storage = ref.read(secureStorageProvider);
    await storage.saveStringSetting('notif_quietHoursStart', startStr);
    await storage.saveStringSetting('notif_quietHoursEnd', endStr);

    try {
      final dio = ref.read(dioProvider);
      await dio.put(
        ApiEndpoints.updatePreferences,
        data: {
          'quietHoursStart': startStr,
          'quietHoursEnd': endStr,
        },
      );
      await ref.read(authProvider.notifier).checkAuthStatus();
      if (mounted) {
        AppHaptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiet hours schedule saved!')),
        );
      }
    } catch (_) {}
  }

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
                      'Stay on top of goals, reminders and quiet moments',
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
                        onChanged: (v) => _updateToggle(
                          'notif_dailyReminder',
                          v,
                          () => setState(() => _dailyReminder = v),
                        ),
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.repeat_rounded,
                        title: 'Habit Reminders',
                        subtitle: 'Nudges for scheduled routine habits',
                        value: _habitReminders,
                        onChanged: (v) => _updateToggle(
                          'notif_habitReminders',
                          v,
                          () => setState(() => _habitReminders = v),
                        ),
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.alarm_rounded,
                        title: 'Task Deadlines',
                        subtitle: 'Alerts before upcoming task due dates',
                        value: _taskDeadlines,
                        onChanged: (v) => _updateToggle(
                          'notif_taskDeadlines',
                          v,
                          () => setState(() => _taskDeadlines = v),
                        ),
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.timer_outlined,
                        title: 'Focus Session Reminder',
                        subtitle: 'Break times and session completion',
                        value: _focusReminder,
                        onChanged: (v) => _updateToggle(
                          'notif_focusReminder',
                          v,
                          () => setState(() => _focusReminder = v),
                        ),
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.fitness_center_rounded,
                        title: 'Workout Reminder',
                        subtitle: 'Gym and physical activity prompts',
                        value: _workoutReminder,
                        onChanged: (v) => _updateToggle(
                          'notif_workoutReminder',
                          v,
                          () => setState(() => _workoutReminder = v),
                        ),
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Finance Reminder',
                        subtitle: 'Budget tracking and subscription alerts',
                        value: _financeReminder,
                        onChanged: (v) => _updateToggle(
                          'notif_financeReminder',
                          v,
                          () => setState(() => _financeReminder = v),
                        ),
                        accent: AppColors.primaryRed,
                      ),
                      Divider(height: 1, color: hairlineColor),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.local_fire_department_rounded,
                        title: 'Streak Milestones',
                        subtitle: 'Celebrations for habit streak targets',
                        value: _streakMilestones,
                        onChanged: (v) => _updateToggle(
                          'notif_streakMilestones',
                          v,
                          () => setState(() => _streakMilestones = v),
                        ),
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
                        leading: const Icon(Icons.wb_sunny_outlined),
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
                            final timeStr =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            await ref
                                .read(secureStorageProvider)
                                .saveStringSetting('notif_morningTime', timeStr);
                          }
                        },
                      ),
                      Divider(height: 1, color: hairlineColor),
                      ListTile(
                        leading: const Icon(Icons.nightlight_outlined),
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
                            final timeStr =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            await ref
                                .read(secureStorageProvider)
                                .saveStringSetting('notif_eveningTime', timeStr);
                          }
                        },
                      ),
                      Divider(height: 1, color: hairlineColor),
                      ListTile(
                        leading: const Icon(Icons.bedtime_outlined),
                        title: const Text('Quiet Hours (Do Not Disturb)'),
                        subtitle: Text(
                            '${_quietStart.format(context)} – ${_quietEnd.format(context)} (Synced to cloud)'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final start = await showTimePicker(
                            context: context,
                            initialTime: _quietStart,
                            helpText: 'Select Quiet Hours Start',
                          );
                          if (start == null || !mounted) return;

                          final end = await showTimePicker(
                            context: context,
                            initialTime: _quietEnd,
                            helpText: 'Select Quiet Hours End',
                          );
                          if (end == null || !mounted) return;

                          setState(() {
                            _quietStart = start;
                            _quietEnd = end;
                          });
                          await _saveQuietHours();
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

  late double _initialTasks;
  late double _initialHabits;
  late double _initialCoding;
  late double _initialStudy;
  late double _initialGym;
  late double _initialFinance;

  late double _weightTasks;
  late double _weightHabits;
  late double _weightCoding;
  late double _weightStudy;
  late double _weightGym;
  late double _weightFinance;

  static double _parseWeight(dynamic val, double fallback) {
    if (val is num) {
      final d = val.toDouble();
      if (d > 0 && d <= 1.0) {
        return (d * 100).roundToDouble();
      }
      return d.roundToDouble();
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final weights = user?.preferences?.lifeScoreWeights;

    // Backward compatibility: if previous client saved legacy 'focus' but omitted coding/study
    final legacyFocus = weights?['focus'];
    double fallbackCoding = 15;
    double fallbackStudy = 15;
    if (legacyFocus is num && weights?['coding'] == null && weights?['study'] == null) {
      final focusVal = _parseWeight(legacyFocus, 30);
      fallbackCoding = (focusVal / 2).roundToDouble();
      fallbackStudy = focusVal - fallbackCoding;
    }

    _initialTasks = _parseWeight(weights?['tasks'], 20);
    _initialHabits = _parseWeight(weights?['habits'], 20);
    _initialCoding = _parseWeight(weights?['coding'], fallbackCoding);
    _initialStudy = _parseWeight(weights?['study'], fallbackStudy);
    _initialGym = _parseWeight(weights?['gym'], 15);
    _initialFinance = _parseWeight(weights?['finance'], 15);

    _weightTasks = _initialTasks;
    _weightHabits = _initialHabits;
    _weightCoding = _initialCoding;
    _weightStudy = _initialStudy;
    _weightGym = _initialGym;
    _weightFinance = _initialFinance;
  }

  bool get _hasWeightChanges {
    return _weightTasks != _initialTasks ||
        _weightHabits != _initialHabits ||
        _weightCoding != _initialCoding ||
        _weightStudy != _initialStudy ||
        _weightGym != _initialGym ||
        _weightFinance != _initialFinance;
  }

  double get _totalWeight =>
      _weightTasks +
      _weightHabits +
      _weightCoding +
      _weightStudy +
      _weightGym +
      _weightFinance;

  @override
  Widget build(BuildContext context) {
    final semantics = AppSemanticColors.of(context);
    final overallScore =
        ref.watch(dashboardProvider).feed?.lifeScore?.overallScore;
    final scoreDisplay = overallScore != null
        ? '${overallScore.toStringAsFixed(0)} / 100'
        : '— / 100';

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
                              scoreDisplay,
                              style: AppTypography.h3(context).copyWith(
                                color: AppColors.primaryRed,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSliderRow(
                        label: 'Tasks',
                        icon: Icons.check_circle_outline_rounded,
                        value: _weightTasks,
                        onChanged: (v) => setState(() => _weightTasks = v),
                      ),
                      _buildSliderRow(
                        label: 'Habits',
                        icon: Icons.repeat_rounded,
                        value: _weightHabits,
                        onChanged: (v) => setState(() => _weightHabits = v),
                      ),
                      _buildSliderRow(
                        label: 'Coding',
                        icon: Icons.code_rounded,
                        value: _weightCoding,
                        onChanged: (v) => setState(() => _weightCoding = v),
                      ),
                      _buildSliderRow(
                        label: 'Study',
                        icon: Icons.school_outlined,
                        value: _weightStudy,
                        onChanged: (v) => setState(() => _weightStudy = v),
                      ),
                      _buildSliderRow(
                        label: 'Fitness',
                        icon: Icons.fitness_center_rounded,
                        value: _weightGym,
                        onChanged: (v) => setState(() => _weightGym = v),
                      ),
                      _buildSliderRow(
                        label: 'Finance',
                        icon: Icons.account_balance_wallet_outlined,
                        value: _weightFinance,
                        onChanged: (v) => setState(() => _weightFinance = v),
                      ),
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
                                  _weightTasks = 20;
                                  _weightHabits = 20;
                                  _weightCoding = 15;
                                  _weightStudy = 15;
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
                                        final double total = _totalWeight > 0 ? _totalWeight : 100.0;
                                        final normalizedWeights = {
                                          'tasks': double.parse((_weightTasks / total).toStringAsFixed(4)),
                                          'habits': double.parse((_weightHabits / total).toStringAsFixed(4)),
                                          'coding': double.parse((_weightCoding / total).toStringAsFixed(4)),
                                          'study': double.parse((_weightStudy / total).toStringAsFixed(4)),
                                          'gym': double.parse((_weightGym / total).toStringAsFixed(4)),
                                          'finance': double.parse((_weightFinance / total).toStringAsFixed(4)),
                                        };

                                        await dio.put(
                                            ApiEndpoints.updatePreferences,
                                            data: {
                                              'lifeScoreWeights': normalizedWeights,
                                            });

                                        setState(() {
                                          _initialTasks = _weightTasks;
                                          _initialHabits = _weightHabits;
                                          _initialCoding = _weightCoding;
                                          _initialStudy = _weightStudy;
                                          _initialGym = _weightGym;
                                          _initialFinance = _weightFinance;
                                        });

                                        // Refresh auth session so preferences stay in sync
                                        await ref
                                            .read(authProvider.notifier)
                                            .checkAuthStatus();

                                        // Refresh dashboard so life score updates immediately
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
                                      } catch (_) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Failed to save Life Score weights')),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _savingWeights = false);
                                        }
                                      }
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

  Widget _buildSliderRow({
    required String label,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
              width: 58,
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
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(secureStorageProvider);
    final anim = await storage.getBoolSetting('appearance_animations');
    final haptics = await storage.getBoolSetting('appearance_haptics');
    if (mounted) {
      setState(() {
        if (anim != null) _enableAnimations = anim;
        if (haptics != null) _enableHaptics = haptics;
      });
    }
  }

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
                        onChanged: (v) async {
                          AppHaptics.selection();
                          setState(() => _enableAnimations = v);
                          await ref
                              .read(secureStorageProvider)
                              .saveBoolSetting('appearance_animations', v);
                        },
                        accent: AppColors.primaryRed,
                      ),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.vibration_rounded,
                        title: 'Haptic Feedback',
                        subtitle: 'Tactile physical vibrations',
                        value: _enableHaptics,
                        onChanged: (v) async {
                          AppHaptics.selection();
                          setState(() => _enableHaptics = v);
                          await ref
                              .read(secureStorageProvider)
                              .saveBoolSetting('appearance_haptics', v);
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
class _AppBehaviorSettingsScreen extends ConsumerStatefulWidget {
  const _AppBehaviorSettingsScreen();

  @override
  ConsumerState<_AppBehaviorSettingsScreen> createState() =>
      __AppBehaviorSettingsScreenState();
}

class __AppBehaviorSettingsScreenState
    extends ConsumerState<_AppBehaviorSettingsScreen> {
  bool _autoStartFocus = false;
  bool _confirmTaskCompletion = true;
  bool _showCompletedHabits = true;
  String _startPage = 'Home';
  String _weekStartsOn = 'Monday';
  static const List<Map<String, dynamic>> _availableModules = [
    {'id': 'LIFE_SCORE', 'name': 'Life Score Momentum', 'icon': Icons.track_changes_rounded},
    {'id': 'HABITS', 'name': 'Daily Habits Checklist', 'icon': Icons.check_circle_outline_rounded},
    {'id': 'TASKS', 'name': 'Tasks Due Today', 'icon': Icons.task_alt_rounded},
    {'id': 'SCHEDULE', 'name': 'Schedule & Timeline', 'icon': Icons.calendar_today_rounded},
    {'id': 'ACADEMIC', 'name': 'Academic Deadlines', 'icon': Icons.school_outlined},
    {'id': 'PROJECTS', 'name': 'Active Projects', 'icon': Icons.folder_open_rounded},
    {'id': 'FITNESS', 'name': 'Fitness & Workouts', 'icon': Icons.fitness_center_rounded},
    {'id': 'FINANCE', 'name': 'Finance Overview', 'icon': Icons.account_balance_wallet_outlined},
    {'id': 'RECENT_ACTIVITY', 'name': 'Recent Activity', 'icon': Icons.history_rounded},
  ];

  Set<String> _enabledModules = {
    'LIFE_SCORE',
    'HABITS',
    'TASKS',
    'SCHEDULE',
    'ACADEMIC',
    'PROJECTS',
    'FITNESS',
    'FINANCE',
    'RECENT_ACTIVITY',
  };
  bool _savingModules = false;

  @override
  void initState() {
    super.initState();
    _loadBehavior();
  }

  Future<void> _loadBehavior() async {
    final storage = ref.read(secureStorageProvider);
    final user = ref.read(authProvider).user;
    final savedModules = user?.preferences?.dashboardModules;

    final startPage = await storage.getStringSetting('behavior_startPage');
    final autoFocus = await storage.getBoolSetting('behavior_autoStartFocus');
    final confirmTask =
        await storage.getBoolSetting('behavior_confirmTaskCompletion');
    final showHabits =
        await storage.getBoolSetting('behavior_showCompletedHabits');
    final weekStarts = await storage.getStringSetting('behavior_weekStartsOn');

    if (mounted) {
      setState(() {
        if (startPage != null) _startPage = startPage;
        if (autoFocus != null) _autoStartFocus = autoFocus;
        if (confirmTask != null) _confirmTaskCompletion = confirmTask;
        if (showHabits != null) _showCompletedHabits = showHabits;
        if (weekStarts != null) _weekStartsOn = weekStarts;
        if (savedModules != null && savedModules.isNotEmpty) {
          _enabledModules = savedModules.map((m) => m.toUpperCase()).toSet();
        }
      });
    }
  }

  Future<void> _toggleModule(String moduleId, bool enabled) async {
    AppHaptics.selection();
    final updated = Set<String>.from(_enabledModules);
    if (enabled) {
      updated.add(moduleId);
    } else {
      if (updated.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('At least one dashboard module must remain enabled.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      updated.remove(moduleId);
    }

    setState(() {
      _enabledModules = updated;
      _savingModules = true;
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.put(
        ApiEndpoints.updatePreferences,
        data: {
          'dashboardModules': updated.toList(),
        },
      );
      await ref.read(authProvider.notifier).checkAuthStatus();
      await ref.read(dashboardProvider.notifier).load(showLoading: false);
    } catch (_) {
      // In case of error, revert is handled on next load
    } finally {
      if (mounted) setState(() => _savingModules = false);
    }
  }

  Future<void> _updateBool(
      String key, bool value, VoidCallback updateState) async {
    AppHaptics.selection();
    updateState();
    await ref.read(secureStorageProvider).saveBoolSetting(key, value);
  }

  Future<void> _updateString(
      String key, String value, VoidCallback updateState) async {
    AppHaptics.selection();
    updateState();
    await ref.read(secureStorageProvider).saveStringSetting(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                        leading: const Icon(Icons.home_outlined),
                        title: const Text('Start Page'),
                        trailing: DropdownButton<String>(
                          value: _startPage,
                          underline: const SizedBox(),
                          items: ['Home', 'Tasks', 'Habits', 'Focus']
                              .map((p) =>
                                  DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _updateString(
                                'behavior_startPage',
                                val,
                                () => setState(() => _startPage = val),
                              );
                            }
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
                        onChanged: (v) => _updateBool(
                          'behavior_autoStartFocus',
                          v,
                          () => setState(() => _autoStartFocus = v),
                        ),
                        accent: AppColors.primaryRed,
                      ),
                      const Divider(height: 1),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.check_circle_rounded,
                        title: 'Confirm Task Completion',
                        subtitle: 'Double-check before marking a task done',
                        value: _confirmTaskCompletion,
                        onChanged: (v) => _updateBool(
                          'behavior_confirmTaskCompletion',
                          v,
                          () => setState(() => _confirmTaskCompletion = v),
                        ),
                        accent: AppColors.primaryRed,
                      ),
                      const Divider(height: 1),
                      buildSettingsDetailCardToggle(
                        context,
                        icon: Icons.visibility_rounded,
                        title: 'Show Completed Habits',
                        subtitle: 'Keep finished habits visible in your feed',
                        value: _showCompletedHabits,
                        onChanged: (v) => _updateBool(
                          'behavior_showCompletedHabits',
                          v,
                          () => setState(() => _showCompletedHabits = v),
                        ),
                        accent: AppColors.primaryRed,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Week Starts On'),
                        trailing: DropdownButton<String>(
                          value: _weekStartsOn,
                          underline: const SizedBox(),
                          items: ['Monday', 'Sunday', 'Saturday']
                              .map((d) =>
                                  DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _updateString(
                                'behavior_weekStartsOn',
                                val,
                                () => setState(() => _weekStartsOn = val),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DASHBOARD MODULES',
                      style: AppTypography.labelMedium(context).copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (_savingModules)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < _availableModules.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        buildSettingsDetailCardToggle(
                          context,
                          icon: _availableModules[i]['icon'] as IconData,
                          title: _availableModules[i]['name'] as String,
                          subtitle: _enabledModules
                                  .contains(_availableModules[i]['id'] as String)
                              ? 'Visible on Dashboard'
                              : 'Hidden from Dashboard',
                          value: _enabledModules
                              .contains(_availableModules[i]['id'] as String),
                          onChanged: (v) => _toggleModule(
                            _availableModules[i]['id'] as String,
                            v,
                          ),
                          accent: AppColors.primaryRed,
                        ),
                      ],
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
class _SecurityPrivacyScreen extends ConsumerStatefulWidget {
  const _SecurityPrivacyScreen();

  @override
  ConsumerState<_SecurityPrivacyScreen> createState() =>
      __SecurityPrivacyScreenState();
}

class __SecurityPrivacyScreenState
    extends ConsumerState<_SecurityPrivacyScreen> {
  bool _appLock = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final storage = ref.read(secureStorageProvider);
    final appLock = await storage.getBoolSetting('security_appLock');
    if (mounted && appLock != null) {
      setState(() => _appLock = appLock);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantics = AppSemanticColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(authProvider).user;

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
                      'Protect your account and manage your credentials with confidence',
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
                        subtitle: 'Require authentication when launching HABos',
                        value: _appLock,
                        onChanged: (v) async {
                          AppHaptics.selection();
                          setState(() => _appLock = v);
                          await ref
                              .read(secureStorageProvider)
                              .saveBoolSetting('security_appLock', v);
                        },
                        accent: semantics.success,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.devices_rounded),
                        title: const Text('Active Sessions'),
                        subtitle: Text(
                            'Logged in as ${user?.email ?? 'active user'} (Current device)'),
                        trailing: AppBadge.info(
                          label: 'Active',
                          context: context,
                          size: AppBadgeSize.compact,
                        ),
                        onTap: () {
                          AppHaptics.light();
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Sessions',
                                    style: AppTypography.titleLarge(context),
                                  ),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    leading: const Icon(Icons.smartphone_rounded),
                                    title: const Text('Current Mobile Device'),
                                    subtitle: Text(
                                        'Authenticated via JWT • Active now • User: ${user?.email}'),
                                    trailing: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Close'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.download_rounded),
                        title: const Text('Export My Data'),
                        subtitle: const Text('Download a JSON copy of all data'),
                        trailing: AppBadge.info(
                          label: 'Roadmap',
                          context: context,
                          size: AppBadgeSize.compact,
                        ),
                        onTap: () {
                          AppHaptics.light();
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Export Data'),
                              content: const Text(
                                'Comprehensive JSON/CSV data export for habits, tasks, focus logs, and gym metrics is scheduled for the v1.1 privacy milestone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Got it'),
                                ),
                              ],
                            ),
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
                              'This action is irreversible. All habits, tasks, workout logs, and focus sessions will be permanently purged.'),
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
class _ConnectedAccountsScreen extends ConsumerWidget {
  const _ConnectedAccountsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(authProvider).user;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSettingsDetailHeader(
                  context,
                  icon: Icons.link_rounded,
                  title: 'Connections',
                  subtitle: 'Link external developer tools and services to HABos',
                  accent: colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 20, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Third-party services sync tasks, repositories, and schedules with HABos.',
                          style: AppTypography.bodySmall(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(24),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.g_mobiledata_rounded,
                              size: 28, color: colorScheme.primary),
                        ),
                        title: const Text('Google Account'),
                        subtitle: Text(
                            'Authenticated with ${user?.email ?? 'primary email'}'),
                        trailing: AppBadge.success(
                          label: 'Connected',
                          context: context,
                          size: AppBadgeSize.compact,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.code_rounded, size: 20),
                        ),
                        title: const Text('GitHub'),
                        subtitle: const Text(
                            'Sync commits & repositories via Developer Hub'),
                        trailing: AppBadge.info(
                          label: 'Configured',
                          context: context,
                          size: AppBadgeSize.compact,
                        ),
                        onTap: () {
                          AppHaptics.light();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'GitHub personal access token is configured in Developer Hub / Projects.'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(24),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_month_rounded,
                              size: 20, color: Colors.blue),
                        ),
                        title: const Text('Google Calendar'),
                        subtitle: const Text(
                            'Bi-directional schedule sync planned for v1.1'),
                        trailing: AppBadge.info(
                          label: 'Coming Soon',
                          context: context,
                          size: AppBadgeSize.compact,
                        ),
                        onTap: () {
                          AppHaptics.light();
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Google Calendar Integration'),
                              content: const Text(
                                'Bi-directional calendar event synchronization with HabOS academic deadlines and task scheduling is coming in v1.1.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Got it'),
                                ),
                              ],
                            ),
                          );
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
    _bioController = TextEditingController(
        text: user?.bio ?? 'Full-Stack Developer • DBU Student');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
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
                                'bio': _bioController.text.trim(),
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
class _PasswordSecurityScreen extends ConsumerStatefulWidget {
  const _PasswordSecurityScreen();

  @override
  ConsumerState<_PasswordSecurityScreen> createState() =>
      __PasswordSecurityScreenState();
}

class __PasswordSecurityScreenState
    extends ConsumerState<_PasswordSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioProvider);
      final currentPass = _currentPasswordController.text;
      final newPass = _newPasswordController.text;

      await dio.put(
        ApiEndpoints.updateProfile,
        data: {
          'currentPassword': currentPass,
          'newPassword': newPass,
        },
      );

      if (!mounted) return;

      AppHaptics.success();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      AppHaptics.warning();
      final String errorMsg = e is DioException && e.response?.data != null
          ? (e.response!.data['message']?.toString() ??
              'Failed to update password. Please check your current password.')
          : 'Failed to update password. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password & Security'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  buildSettingsDetailHeader(
                    context,
                    icon: Icons.lock_reset_rounded,
                    title: 'Password',
                    subtitle: 'Keep your account protected with a strong password',
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
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Enter your current password and choose a new password of at least 8 characters.',
                          style: AppTypography.bodySmall(context).copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrent,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrent
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(Icons.key_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters long';
                            }
                            if (value == _currentPasswordController.text) {
                              return 'New password must be different from current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _updatePassword(),
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon: const Icon(Icons.key_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _updatePassword,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Update Password'),
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
