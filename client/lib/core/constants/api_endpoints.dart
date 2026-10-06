import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Support custom base URL passed at build/run time via:
  // flutter run --dart-define=API_BASE_URL=http://<YOUR_COMPUTER_IP>:5000/api/v1
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/v1';
    }
    return 'http://localhost:5000/api/v1';
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String profile = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String updatePreferences = '/auth/preferences';

  // Dashboard & Life Score
  static const String dashboardFeed = '/dashboard';
  static const String lifeScore = '/lifescore';

  // Domains
  static const String tasks = '/tasks';
  static const String habits = '/habits';
  static const String focus = '/focus';
  static const String projects = '/projects';
  static const String courses = '/courses';
  static const String gym = '/gym';
  static const String finance = '/finance';
  static const String goals = '/goals';
  static const String vault = '/vault';
  static const String notifications = '/notifications';
  static const String logout = '/auth/logout';

  // Dynamic helpers
  static String habitLog(String habitId) => '/habits/$habitId/log';
  static String habitById(String habitId) => '/habits/$habitId';
  static String habitHistory(String habitId) => '/habits/$habitId/history';
  static String habitFreeze(String habitId) => '/habits/$habitId/freeze';
  static const String habitCorrelations = '/habits/correlations';
  static const String habitRoutines = '/habits/routines';
  static String habitRoutineById(String id) => '/habits/routines/$id';
  static String habitRoutineComplete(String id) =>
      '/habits/routines/$id/complete';
  static const String habitsSummary = '/habits/summary';
  static String taskById(String taskId) => '/tasks/$taskId';
  static String taskComplete(String taskId) => '/tasks/$taskId/complete';
  static const String taskStats = '/tasks/stats';
  static const String taskWorkload = '/tasks/workload';
  static const String taskMatrix = '/tasks/matrix';
  static String taskSubtasks(String taskId) => '/tasks/$taskId/subtasks';
  static String taskDependencies(String taskId) =>
      '/tasks/$taskId/dependencies';
  static String taskDependency(String taskId, String blockingId) =>
      '/tasks/$taskId/dependencies/$blockingId';
  static const String taskReorder = '/tasks/reorder';
  static const String taskSyncCalendar = '/tasks/sync-calendar';
  static String taskSyncCalendarSingle(String id) => '/tasks/$id/sync-calendar';

  // Focus
  static const String focusStart = '/focus/start';
  static String focusEnd(String id) => '/focus/$id/end';
  static String focusCancel(String id) => '/focus/$id/cancel';
  static const String focusLog = '/focus/log';
  static const String focusStats = '/focus/stats';
  static String focusById(String id) => '/focus/$id';

  // Finance
  static const String financeTransactions = '/finance/transactions';
  static String financeTransactionById(String id) =>
      '/finance/transactions/$id';
  static const String financeBudgets = '/finance/budgets';
  static const String financeAnalytics = '/finance/analytics';

  // Analytics & Time Tracking
  static const String analyticsRetrospective = '/analytics/retrospective';
  static const String analyticsExportCsv = '/analytics/export/csv';
  static const String analyticsExportPdf = '/analytics/export/pdf';
  static const String analyticsTime = '/analytics/time';
  static String analyticsTimeById(String id) => '/analytics/time/$id';
  static String analyticsTimeStop(String id) => '/analytics/time/$id/stop';

  // Developer Hub & Projects
  static String projectById(String id) => '/projects/$id';
  static String projectFeatures(String id) => '/projects/$id/features';
  static String projectFeatureById(String id, String featId) =>
      '/projects/$id/features/$featId';
  static String projectBugs(String id) => '/projects/$id/bugs';
  static String projectBugById(String id, String bugId) =>
      '/projects/$id/bugs/$bugId';
  static String projectBoard(String id) => '/projects/$id/board';
  static String projectBoardMove(String id) => '/projects/$id/board/move';
  static String projectAnalytics(String id) => '/projects/$id/analytics';
  static String projectCommits(String id) => '/projects/$id/commits';
  static const String projectTechInsights = '/projects/insights/tech-stack';
  static String projectWebhookConfig(String id) =>
      '/projects/$id/webhooks/config';
  static String projectWebhookSecret(String id) =>
      '/projects/$id/webhooks/secret';
  static String projectGithubLinks(String id) =>
      '/projects/$id/github-links';
  static String projectGithubLinkById(String id, String linkId) =>
      '/projects/$id/github-links/$linkId';
  static String projectEvents(String id) => '/projects/$id/events';
  static String registerGithubWebhook(String owner, String repo) =>
      '/integrations/github/repos/$owner/$repo/webhook';

  // Academic & Courses
  static String courseById(String id) => '/courses/$id';
  static String courseAssignments(String id) => '/courses/$id/assignments';
  static String courseAssignmentById(String id, String aId) =>
      '/courses/$id/assignments/$aId';
  static String courseExams(String id) => '/courses/$id/exams';
  static String courseExamById(String id, String eId) =>
      '/courses/$id/exams/$eId';
  static String courseAttendance(String id) => '/courses/$id/attendance';
  static String courseSchedules(String id) => '/courses/$id/schedules';
  static String courseScheduleById(String id, String sId) =>
      '/courses/$id/schedules/$sId';
  static String courseWhatIf(String id) => '/courses/$id/what-if';
  static String courseStudy(String id) => '/courses/$id/study';
  static const String academicSummary = '/courses/summary';
  static const String academicGpa = '/courses/gpa';
  static const String academicSchedules = '/courses/schedules';

  // Gym & Fitness
  static const String gymWorkouts = '/gym/workouts';
  static String gymWorkoutById(String id) => '/gym/workouts/$id';
  static const String gymExercises = '/gym/exercises';
  static String gymExerciseHistory(String id) => '/gym/exercises/$id/history';
  static const String gymPRs = '/gym/prs';
  static const String gymStats = '/gym/stats';
  static const String gymInsights = '/gym/insights';
  static const String gymTemplates = '/gym/templates';
  static String gymTemplateById(String id) => '/gym/templates/$id';
  static const String gymBodyMetrics = '/gym/body-metrics';
  static String gymBodyMetricById(String id) => '/gym/body-metrics/$id';

  // Goals & Milestones
  static String goalById(String id) => '/goals/$id';
  static String goalTree(String id) => '/goals/$id/tree';
  static String goalContribute(String id) => '/goals/$id/contribute';
  static String goalMilestones(String goalId) => '/goals/$goalId/milestones';
  static String goalMilestoneById(String goalId, String milestoneId) =>
      '/goals/$goalId/milestones/$milestoneId';
  static String goalCheckIns(String id) => '/goals/$id/checkins';
  static const String goalsHealth = '/goals/health';
  static const String goalsRoadmap = '/goals/roadmap';

  // AI Assistant & Insights Engine (UC-136 to UC-143)
  static const String aiNeglectedAreas = '/ai/neglected-areas';
  static const String aiRecommendTasks = '/ai/recommend-tasks';
  static const String aiPlan = '/ai/plan';
  static const String aiInsights = '/ai/insights';
  static String aiInsightByDomain(String domain) => '/ai/insights/$domain';
  static const String aiBriefing = '/ai/briefing';
  static const String aiRecommendation = '/ai/recommendation';
  static const String aiAsk = '/ai/ask';

  // Knowledge Vault (UC-120 to UC-130)
  static const String vaultNotes = '/vault/notes';
  static String vaultNoteById(String id) => '/vault/notes/$id';
  static const String vaultTags = '/vault/tags';
  static const String vaultSearch = '/vault/search';
  static const String vaultGraph = '/vault/graph';
  static const String vaultLinks = '/vault/links';

  // Global Search (UC-167 to UC-172)
  static const String globalSearch = '/search';

  // Notifications Center (UC-159 to UC-166)
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationsGenerateAlerts = '/notifications/generate-alerts';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notificationById(String id) => '/notifications/$id';

  // Developer Hub Integrations (UC-53 to UC-64)
  static const String integrationsLeetCodeStats = '/integrations/leetcode/stats';
  static const String integrationsLeetCodeSync = '/integrations/leetcode/sync';
  static const String integrationsGitHubStats = '/integrations/github/stats';
  static const String integrationsGitHubSync = '/integrations/github/sync';
  static const String integrationsGitHubRepos = '/integrations/github/repos';
  static const String integrationsGitHubImport = '/integrations/github/import';
  static String integrationsGitHubAnalyze(String owner, String repo) =>
      '/integrations/github/repos/$owner/$repo/analyze';
}
