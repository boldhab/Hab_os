import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiEndpoints {
  // Default base URL: 10.0.2.2 for Android emulator, localhost for desktop/iOS/web
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
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
  static const String habitsSummary = '/habits/summary';
  static String taskById(String taskId) => '/tasks/$taskId';
  static String taskComplete(String taskId) => '/tasks/$taskId/complete';
  static const String taskStats = '/tasks/stats';

  // Focus
  static const String focusStart = '/focus/start';
  static String focusEnd(String id) => '/focus/$id/end';
  static const String focusLog = '/focus/log';
  static const String focusStats = '/focus/stats';
  static String focusById(String id) => '/focus/$id';

  // Finance
  static const String financeTransactions = '/finance/transactions';
  static String financeTransactionById(String id) => '/finance/transactions/$id';
  static const String financeBudgets = '/finance/budgets';
  static const String financeAnalytics = '/finance/analytics';

  // Analytics
  static const String analyticsRetrospective = '/analytics/retrospective';

  // Developer Hub & Projects
  static String projectById(String id) => '/projects/$id';
  static String projectFeatures(String id) => '/projects/$id/features';
  static String projectFeatureById(String id, String featId) => '/projects/$id/features/$featId';
  static String projectBugs(String id) => '/projects/$id/bugs';
  static String projectBugById(String id, String bugId) => '/projects/$id/bugs/$bugId';
  static String projectBoard(String id) => '/projects/$id/board';
  static String projectBoardMove(String id) => '/projects/$id/board/move';
  static String projectAnalytics(String id) => '/projects/$id/analytics';
  static String projectCommits(String id) => '/projects/$id/commits';
  static const String projectTechInsights = '/projects/insights/tech-stack';

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
}
