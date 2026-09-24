import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "More" tab — grid of all secondary domain screens.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _items = [
    _MoreItem(icon: Icons.account_balance_wallet_outlined, label: 'Finance', route: '/more/finance'),
    _MoreItem(icon: Icons.fitness_center_outlined, label: 'Gym', route: '/more/gym'),
    _MoreItem(icon: Icons.flag_outlined, label: 'Goals', route: '/more/goals'),
    _MoreItem(icon: Icons.folder_outlined, label: 'Projects', route: '/more/projects'),
    _MoreItem(icon: Icons.school_outlined, label: 'Academic', route: '/more/academic'),
    _MoreItem(icon: Icons.bar_chart_rounded, label: 'Analytics', route: '/more/analytics'),
    _MoreItem(icon: Icons.settings_outlined, label: 'Settings', route: '/more/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: _items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, i) {
            final item = _items[i];
            return Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.go(item.route),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 32, color: colorScheme.primary),
                    const SizedBox(height: 10),
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final String route;
  const _MoreItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
