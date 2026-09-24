import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/habits/habits_screen.dart';
import '../../presentation/screens/tasks/tasks_screen.dart';
import '../../presentation/screens/tasks/task_details_screen.dart';
import '../../presentation/screens/focus/focus_screen.dart';
import '../../presentation/screens/more/more_screen.dart';
import '../../presentation/screens/finance/finance_screen.dart';
import '../../presentation/screens/gym/gym_screen.dart';
import '../../presentation/screens/goals/goals_screen.dart';
import '../../presentation/screens/projects/projects_screen.dart';
import '../../presentation/screens/projects/project_detail_screen.dart';
import '../../presentation/screens/academic/academic_screen.dart';
import '../../presentation/screens/analytics/analytics_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import 'scaffold_with_nav_bar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final loc = state.matchedLocation;
      final isPublic = loc == '/login' || loc == '/register';

      // Still resolving — don't redirect yet
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.authenticating) {
        return null;
      }

      if (!isAuth && !isPublic) return '/login';
      if (isAuth && isPublic) return '/';
      return null;
    },
    routes: [
      // ── Public routes ──────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Authenticated shell (persistent bottom nav) ─────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ScaffoldWithNavBar(navigationShell: shell),
        branches: [
          // Branch 0: Home / Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Habits
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/habits',
                builder: (context, state) => const HabitsScreen(),
              ),
            ],
          ),

          // Branch 2: Tasks
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return TaskDetailsScreen(taskId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Focus
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/focus',
                builder: (context, state) => const FocusScreen(),
              ),
            ],
          ),

          // Branch 4: More (grid hub + sub-routes)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'finance',
                    builder: (context, state) => const FinanceScreen(),
                  ),
                  GoRoute(
                    path: 'gym',
                    builder: (context, state) => const GymScreen(),
                  ),
                  GoRoute(
                    path: 'goals',
                    builder: (context, state) => const GoalsScreen(),
                  ),
                  GoRoute(
                    path: 'projects',
                    builder: (context, state) => const ProjectsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return ProjectDetailScreen(projectId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'academic',
                    builder: (context, state) => const AcademicScreen(),
                  ),
                  GoRoute(
                    path: 'analytics',
                    builder: (context, state) => const AnalyticsScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
