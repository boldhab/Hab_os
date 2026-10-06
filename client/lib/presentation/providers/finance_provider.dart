import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/finance_model.dart';
import '../../data/repositories/finance_repository.dart';
import 'dashboard_provider.dart';

enum FinanceStatus { initial, loading, loaded, error }

// Sentinel object to distinguish between "keep current value" and "set to null"
const Object _undefined = Object();

class FinanceState {
  final FinanceStatus status;
  final List<TransactionModel> transactions;
  final List<BudgetModel> budgets;
  final FinanceAnalyticsModel? analytics;
  final String? selectedType; // null ('All'), 'INCOME', 'EXPENSE'
  final String searchQuery;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final bool hasMore;

  const FinanceState({
    this.status = FinanceStatus.initial,
    this.transactions = const [],
    this.budgets = const [],
    this.analytics,
    this.selectedType,
    this.searchQuery = '',
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.hasMore = false,
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
    Object? selectedType = _undefined,
    String? searchQuery,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return FinanceState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      budgets: budgets ?? this.budgets,
      analytics: analytics ?? this.analytics,
      selectedType: identical(selectedType, _undefined)
          ? this.selectedType
          : (selectedType as String?),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  final FinanceRepository _repository;
  final Ref _ref;
  Timer? _searchDebounceTimer;

  FinanceNotifier(this._repository, this._ref) : super(const FinanceState()) {
    loadFinanceData();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> loadFinanceData({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(status: FinanceStatus.loading, currentPage: 1);
    }
    try {
      final paginated = await _repository.getTransactions(
        type: state.selectedType,
        search: state.searchQuery,
        page: 1,
        limit: 20,
      );
      final budgets = await _repository.getBudgets();
      FinanceAnalyticsModel? analytics;
      try {
        analytics = await _repository.getAnalytics();
      } catch (_) {}

      state = state.copyWith(
        status: FinanceStatus.loaded,
        transactions: paginated.transactions,
        budgets: budgets,
        analytics: analytics,
        currentPage: paginated.pagination.page,
        totalPages: paginated.pagination.totalPages,
        hasMore: paginated.pagination.page < paginated.pagination.totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        status: FinanceStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMoreTransactions() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final paginated = await _repository.getTransactions(
        type: state.selectedType,
        search: state.searchQuery,
        page: nextPage,
        limit: 20,
      );

      state = state.copyWith(
        isLoadingMore: false,
        transactions: [...state.transactions, ...paginated.transactions],
        currentPage: paginated.pagination.page,
        totalPages: paginated.pagination.totalPages,
        hasMore: paginated.pagination.page < paginated.pagination.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setTypeFilter(String? type) {
    state = state.copyWith(selectedType: type);
    loadFinanceData(showLoading: false);
  }

  void setSearchQuery(String query) {
    // 300ms Debounce to prevent firing requests on every single keystroke
    _searchDebounceTimer?.cancel();
    state = state.copyWith(searchQuery: query);
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadFinanceData(showLoading: false);
    });
  }

  Future<bool> createTransaction(
    Map<String, dynamic> payload, {
    String? idempotencyKey,
  }) async {
    try {
      await _repository.createTransaction(
        payload,
        idempotencyKey: idempotencyKey,
      );
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

  Future<bool> setBudget(Map<String, dynamic> payload) async {
    try {
      await _repository.setBudget(payload);
      final budgets = await _repository.getBudgets();
      state = state.copyWith(budgets: budgets);
      _ref.read(dashboardProvider.notifier).load(showLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final financeProvider =
    StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return FinanceNotifier(repository, ref);
});
