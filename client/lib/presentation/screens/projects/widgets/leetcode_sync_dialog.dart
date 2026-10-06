import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/dev_integrations_model.dart';
import '../../../providers/dev_integrations_provider.dart';

class LeetCodeSyncDialog extends ConsumerStatefulWidget {
  final LeetCodeStatsModel? initialStats;

  const LeetCodeSyncDialog({super.key, this.initialStats});

  static Future<void> show(BuildContext context, {LeetCodeStatsModel? initialStats}) {
    return showDialog(
      context: context,
      builder: (ctx) => LeetCodeSyncDialog(initialStats: initialStats),
    );
  }

  @override
  ConsumerState<LeetCodeSyncDialog> createState() => _LeetCodeSyncDialogState();
}

class _LeetCodeSyncDialogState extends ConsumerState<LeetCodeSyncDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _easyController;
  late TextEditingController _mediumController;
  late TextEditingController _hardController;
  late TextEditingController _streakController;
  late TextEditingController _longestStreakController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initialStats;
    _usernameController = TextEditingController(text: s?.username ?? '');
    _easyController = TextEditingController(text: s != null ? s.easySolved.toString() : '');
    _mediumController = TextEditingController(text: s != null ? s.mediumSolved.toString() : '');
    _hardController = TextEditingController(text: s != null ? s.hardSolved.toString() : '');
    _streakController = TextEditingController(text: s != null ? s.currentStreak.toString() : '');
    _longestStreakController =
        TextEditingController(text: s != null ? s.longestStreak.toString() : '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _easyController.dispose();
    _mediumController.dispose();
    _hardController.dispose();
    _streakController.dispose();
    _longestStreakController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final username = _usernameController.text.trim();
      final easy = int.tryParse(_easyController.text.trim()) ?? 0;
      final medium = int.tryParse(_mediumController.text.trim()) ?? 0;
      final hard = int.tryParse(_hardController.text.trim()) ?? 0;
      final streak = int.tryParse(_streakController.text.trim()) ?? 0;
      final longest = int.tryParse(_longestStreakController.text.trim()) ?? streak;

      await ref.read(leetCodeStatsProvider.notifier).syncStats(
            username: username,
            easySolved: easy,
            mediumSolved: medium,
            hardSolved: hard,
            currentStreak: streak,
            longestStreak: longest,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('LeetCode profile synced successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA116).withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.code_rounded,
              color: Color(0xFFFFA116),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Sync LeetCode Profile',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'LeetCode Username',
                  hintText: 'e.g. tour_de_code',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Username required' : null,
              ),
              const SizedBox(height: 14),
              const Text(
                'Problem Counts Breakdown',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _easyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Easy',
                        prefixIcon: Icon(Icons.circle, size: 12, color: Color(0xFF00B8A3)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _mediumController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Medium',
                        prefixIcon: Icon(Icons.circle, size: 12, color: Color(0xFFFFC01E)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _hardController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Hard',
                        prefixIcon: Icon(Icons.circle, size: 12, color: Color(0xFFFF375F)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _streakController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Current Streak (Days)',
                        prefixIcon: Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _longestStreakController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Longest Streak',
                        prefixIcon: Icon(Icons.emoji_events_outlined, color: Colors.amber),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Sync Stats'),
        ),
      ],
    );
  }
}
