import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_model.dart';
import '../../data/repositories/finance_repository.dart';
import 'dashboard_provider.dart';

enum FinanceStatus { initial, loading, loaded, error }

class FinanceState {
  final FinanceStatus status;
  final List<TransactionModel> transactions;
  final List<BudgetModel> budgets;
  final FinanceAnalyticsModel? analytics;
  final String? selectedType; // null, 'INCOME', 'EXPENSE'
  final String searchQuery;
  final String? errorMessage;

  const FinanceState({
    this.status = FinanceStatus.initial,
    this.transactions = const [],
    this.budgets = const [],
    this.analytics,
    this.selectedType,
    this.searchQuery = '',
    this.errorMessage,
  });

  double get totalIncome {
    return transactions
        .where((t) => t.type == 'INCOME')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == 'EXPENSE')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  FinanceState copyWith({
    FinanceStatus? status,
    List<TransactionModel>? transactions,
    List<BudgetModel>? budgets,
    FinanceAnalyticsModel? analytics,
    String? selectedType,
    String? searchQuery,
    String? errorMessage,
  }) {
    return FinanceState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      budgets: budgets ?? this.budgets,
      analytics: analytics ?? this.analytics,
      selectedType: selectedType,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  final FinanceRepository _repository;
  final Ref _ref;

  FinanceNotifier(this._repository, this._ref) : super(const FinanceState()) {
    loadFinanceData();
  }

  Future<void> loadFinanceData({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(status: FinanceStatus.loading);
    }
    try {
      final transactions = await _repository.getTransactions(
        type: state.selectedType,
        search: state.searchQuery,
      );
      final budgets = await _repository.getBudgets();
      FinanceAnalyticsModel? analytics;
      try {
        analytics = await _repository.getAnalytics();
      } catch (_) {}

      state = state.copyWith(
        status: FinanceStatus.loaded,
        transactions: transactions,
        budgets: budgets,
        analytics: analytics,
      );
    } catch (e) {
      state = state.copyWith(
        status: FinanceStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void setTypeFilter(String? type) {
    state = FinanceState(
      status: state.status,
      transactions: state.transactions,
      budgets: state.budgets,
      analytics: state.analytics,
      selectedType: type,
      searchQuery: state.searchQuery,
    );
    loadFinanceData(showLoading: false);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadFinanceData(showLoading: false);
  }

  Future<bool> createTransaction(Map<String, dynamic> payload) async {
    try {
      await _repository.createTransaction(payload);
      await loadFinanceData(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadFinanceData(showLoading: false);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final financeProvider =
    StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return FinanceNotifier(repository, ref);
});
