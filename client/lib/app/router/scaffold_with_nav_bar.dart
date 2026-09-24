import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent bottom NavigationBar shell wrapping all authenticated tabs.
class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  static const _tabs = [
    _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavTab(icon: Icons.loop_outlined, activeIcon: Icons.loop_rounded, label: 'Habits'),
    _NavTab(icon: Icons.task_alt_outlined, activeIcon: Icons.task_alt_rounded, label: 'Tasks'),
    _NavTab(icon: Icons.timer_outlined, activeIcon: Icons.timer_rounded, label: 'Focus'),
    _NavTab(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabTap,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }

  void _onTabTap(int index) {
    navigationShell.goBranch(
      index,
      // Re-tap active tab → pop to root of that branch
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
