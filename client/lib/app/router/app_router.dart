import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/auth_callback_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/habits/habits_screen.dart';
import '../../presentation/screens/tasks/tasks_screen.dart';
import '../../presentation/screens/tasks/task_details_screen.dart';
import '../../presentation/screens/focus/focus_screen.dart';
import '../../presentation/screens/more/more_screen.dart';
import '../../presentation/screens/finance/finance_screen.dart';
import '../../presentation/screens/gym/gym_screen.dart';
import '../../presentation/screens/goals/goals_screen.dart';
import '../../presentation/screens/goals/goal_detail_screen.dart';
import '../../presentation/screens/projects/projects_screen.dart';
import '../../presentation/screens/projects/project_detail_screen.dart';
import '../../presentation/screens/academic/academic_screen.dart';
import '../../presentation/screens/academic/course_detail_screen.dart';
import '../../presentation/screens/analytics/analytics_screen.dart';
import '../../presentation/screens/analytics/time_tracker_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/vault/vault_screen.dart';
import '../../presentation/screens/vault/note_detail_screen.dart';
import '../../presentation/screens/vault/note_edit_screen.dart';
import '../../presentation/screens/search/global_search_screen.dart';
import '../../presentation/screens/ai/ai_chat_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import '../../presentation/screens/admin/admin_screen.dart';
import 'scaffold_with_nav_bar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final loc = state.matchedLocation;
      final isPublic = loc == '/login' || loc == '/register' || loc == '/auth/callback';

      // Still resolving — don't redirect yet
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.authenticating) {
        return null;
      }

      if (!isAuth && !isPublic) return '/login';
      if (isAuth && (loc == '/login' || loc == '/register')) return '/';
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
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          final refreshToken = state.uri.queryParameters['refreshToken'];
          final error = state.uri.queryParameters['error'];
          return AuthCallbackScreen(
            token: token,
            refreshToken: refreshToken,
            error: error,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: '/ai/chat',
        builder: (context, state) => const AiChatScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
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
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return GymScreen(initialWorkoutId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'goals',
                    builder: (context, state) => const GoalsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return GoalDetailScreen(goalId: id);
                        },
                      ),
                    ],
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
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return CourseDetailScreen(courseId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'analytics',
                    builder: (context, state) => const AnalyticsScreen(),
                    routes: [
                      GoRoute(
                        path: 'time-tracker',
                        builder: (context, state) =>
                            const TimeTrackerScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'vault',
                    builder: (context, state) => const VaultScreen(),
                    routes: [
                      GoRoute(
                        path: 'create',
                        builder: (context, state) => const NoteEditScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return NoteDetailScreen(noteId: id);
                        },
                        routes: [
                          GoRoute(
                            path: 'edit',
                            builder: (context, state) {
                              final id = state.pathParameters['id'] ?? '';
                              return NoteEditScreen(noteId: id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'ai',
                    builder: (context, state) => const AiChatScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'admin',
                    builder: (context, state) => const AdminScreen(),
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
