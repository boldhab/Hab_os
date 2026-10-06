import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/search_result_model.dart';

class GlobalSearchState {
  final String query;
  final String selectedDomain;
  final List<SearchResultItem> results;
  final List<String> recentSearches;
  final bool isLoading;
  final String? errorMessage;

  const GlobalSearchState({
    this.query = '',
    this.selectedDomain = 'ALL',
    this.results = const [],
    this.recentSearches = const [
      'Docker',
      'Operating Systems',
      'Budget',
      'Sprint',
      'Workout',
    ],
    this.isLoading = false,
    this.errorMessage,
  });

  GlobalSearchState copyWith({
    String? query,
    String? selectedDomain,
    List<SearchResultItem>? results,
    List<String>? recentSearches,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GlobalSearchState(
      query: query ?? this.query,
      selectedDomain: selectedDomain ?? this.selectedDomain,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class GlobalSearchNotifier extends StateNotifier<GlobalSearchState> {
  final Ref _ref;
  Timer? _debounceTimer;

  GlobalSearchNotifier(this._ref) : super(const GlobalSearchState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void onQueryChanged(String newQuery) {
    state = state.copyWith(query: newQuery);
    _debounceTimer?.cancel();

    if (newQuery.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false, clearError: true);
      return;
    }

    // Debounce network requests by 250ms (UC-168)
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      executeSearch();
    });
  }

  void selectDomain(String domain) {
    if (state.selectedDomain == domain) return;
    state = state.copyWith(selectedDomain: domain);
    if (state.query.trim().isNotEmpty) {
      executeSearch();
    }
  }

  Future<void> executeSearch() async {
    final queryText = state.query.trim();
    if (queryText.isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get(
        ApiEndpoints.globalSearch,
        queryParameters: {
          'q': queryText,
          'domain': state.selectedDomain,
          'limit': 20,
        },
      );

      final payload = response.data['data'] ?? response.data;
      final parsed = GlobalSearchResult.fromJson(Map<String, dynamic>.from(payload));

      state = state.copyWith(
        results: parsed.results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Search failed: $e',
      );
    }
  }

  void addRecentSearch(String term) {
    final clean = term.trim();
    if (clean.isEmpty) return;
    final updated = [clean, ...state.recentSearches.where((s) => s.toLowerCase() != clean.toLowerCase())];
    state = state.copyWith(recentSearches: updated.take(8).toList());
  }

  void removeRecentSearch(String term) {
    final updated = state.recentSearches.where((s) => s != term).toList();
    state = state.copyWith(recentSearches: updated);
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
  }

  void clearSearch() {
    state = state.copyWith(query: '', results: [], isLoading: false, clearError: true);
  }
}

final globalSearchProvider =
    StateNotifierProvider.autoDispose<GlobalSearchNotifier, GlobalSearchState>((ref) {
  return GlobalSearchNotifier(ref);
});
