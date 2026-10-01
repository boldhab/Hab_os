import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goal_repository.dart';
import 'dashboard_provider.dart';

final selectedGoalCategoryProvider = StateProvider<String>((ref) => 'ALL');

final goalsListProvider =
    FutureProvider.autoDispose<List<GoalModel>>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  final category = ref.watch(selectedGoalCategoryProvider);
  return repo.getGoals(category: category == 'ALL' ? null : category);
});

final goalsHealthProvider =
    FutureProvider.autoDispose<GoalsHealthSummary>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getGoalsHealth();
});

final goalDetailsProvider =
    FutureProvider.autoDispose.family<GoalModel, String>((ref, goalId) async {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getGoalById(goalId);
});

final goalTreeProvider = FutureProvider.autoDispose
    .family<GoalTreeModel, String>((ref, goalId) async {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getGoalTree(goalId);
});

class GoalsNotifier extends StateNotifier<AsyncValue<void>> {
  final GoalRepository _repo;
  final Ref _ref;

  GoalsNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<GoalModel?> createGoal(Map<String, dynamic> payload) async {
    state = const AsyncValue.loading();
    try {
      final goal = await _repo.createGoal(payload);
      _ref.invalidate(goalsListProvider);
      _ref.invalidate(goalsHealthProvider);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      state = const AsyncValue.data(null);
      return goal;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateGoal(String id, Map<String, dynamic> payload) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateGoal(id, payload);
      _ref.invalidate(goalsListProvider);
      _ref.invalidate(goalDetailsProvider(id));
      _ref.invalidate(goalTreeProvider(id));
      _ref.invalidate(goalsHealthProvider);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteGoal(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteGoal(id);
      _ref.invalidate(goalsListProvider);
      _ref.invalidate(goalsHealthProvider);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createMilestone(
      String goalId, Map<String, dynamic> payload) async {
    try {
      await _repo.createMilestone(goalId, payload);
      _ref.invalidate(goalDetailsProvider(goalId));
      _ref.invalidate(goalTreeProvider(goalId));
      _ref.invalidate(goalsListProvider);
      _ref.invalidate(goalsHealthProvider);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMilestone(
    String goalId,
    String milestoneId,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _repo.updateMilestone(goalId, milestoneId, payload);
      _ref.invalidate(goalDetailsProvider(goalId));
      _ref.invalidate(goalTreeProvider(goalId));
      _ref.invalidate(goalsListProvider);
      _ref.invalidate(goalsHealthProvider);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMilestone(String goalId, String milestoneId) async {
    try {
      await _repo.deleteMilestone(goalId, milestoneId);
      _ref.invalidate(goalDetailsProvider(goalId));
      _ref.invalidate(goalTreeProvider(goalId));
      _ref.invalidate(goalsListProvider);
      _ref.invalidate(goalsHealthProvider);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> recordCheckIn(
      String goalId, String confidence, String? note) async {
    try {
      await _repo.recordCheckIn(goalId, confidence, note);
      _ref.invalidate(goalDetailsProvider(goalId));
      _ref.invalidate(goalsHealthProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> contributeFinancial(String goalId, double amount) async {
    try {
      await _repo.contributeFinancial(goalId, amount);
      _ref.invalidate(goalDetailsProvider(goalId));
      _ref.invalidate(goalTreeProvider(goalId));
      _ref.invalidate(goalsListProvider);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final goalsActionsProvider =
    StateNotifierProvider<GoalsNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  return GoalsNotifier(repo, ref);
});
