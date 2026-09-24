import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _savingWeights = false;

  // Default Life Score component weights
  double _weightHabits = 25;
  double _weightTasks = 20;
  double _weightFocus = 20;
  double _weightGym = 15;
  double _weightFinance = 10;
  double _weightGoals = 10;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User Profile Header Card ───────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      user?.name != null && user!.name!.isNotEmpty
                          ? user.name![0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withAlpha(180),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: colorScheme.onPrimaryContainer,
                    onPressed: () => _openEditProfileDialog(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Life Score Weights Configuration ─────────────────────────────
          Text(
            'Life Score Weights Customization',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust component weights used in calculating your overall score.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildWeightSlider('Habits', _weightHabits, (v) {
                    setState(() => _weightHabits = v);
                  }),
                  _buildWeightSlider('Tasks', _weightTasks, (v) {
                    setState(() => _weightTasks = v);
                  }),
                  _buildWeightSlider('Focus', _weightFocus, (v) {
                    setState(() => _weightFocus = v);
                  }),
                  _buildWeightSlider('Gym', _weightGym, (v) {
                    setState(() => _weightGym = v);
                  }),
                  _buildWeightSlider('Finance', _weightFinance, (v) {
                    setState(() => _weightFinance = v);
                  }),
                  _buildWeightSlider('Goals', _weightGoals, (v) {
                    setState(() => _weightGoals = v);
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _savingWeights ? null : _saveWeights,
                      icon: _savingWeights
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_rounded),
                      label: const Text('Save Weights'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── System Hardening Status ───────────────────────────────────────
          Text(
            'System Security & Architecture',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.shield_outlined,
                      color: colorScheme.primary),
                  title: const Text('Token Encryption'),
                  subtitle: const Text('AES-256-GCM Encrypted Storage'),
                  trailing: const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 18),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.flash_on_outlined,
                      color: colorScheme.primary),
                  title: const Text('Zero-Stale UX'),
                  subtitle: const Text('Instant Write Cache Invalidation'),
                  trailing: const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 18),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.phonelink_lock_rounded,
                      color: colorScheme.primary),
                  title: const Text('Token Storage'),
                  subtitle: const Text('Flutter Secure Storage Enabled'),
                  trailing: const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Sign Out Button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWeightSlider(
      String label, double value, ValueChanged<double> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: 0,
              max: 50,
              divisions: 50,
              label: '${value.toInt()}%',
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('${value.toInt()}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWeights() async {
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
            'goals': _weightGoals,
          },
        },
      );
      ref.read(dashboardProvider.notifier).load(showLoading: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Life Score weights updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating preferences: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingWeights = false);
    }
  }

  Future<void> _openEditProfileDialog(BuildContext context) async {
    final authUser = ref.read(authProvider).user;
    final nameController = TextEditingController(text: authUser?.name ?? '');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirm == true && nameController.text.trim().isNotEmpty) {
      try {
        final dio = ref.read(dioProvider);
        await dio.put(ApiEndpoints.updateProfile, data: {
          'name': nameController.text.trim(),
        });
        await ref.read(authProvider.notifier).checkAuthStatus();
      } catch (_) {}
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}
