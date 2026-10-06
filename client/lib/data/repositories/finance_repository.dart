import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/finance_model.dart';

class FinanceRepository {
  final Dio _dio;

  FinanceRepository(this._dio);

  Future<PaginatedTransactions> getTransactions({
    String? type,
    String? categoryId,
    int? month,
    int? year,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      if (type != null && type.isNotEmpty) 'type': type,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'limit': limit,
    };
    final response = await _dio.get(
      ApiEndpoints.financeTransactions,
      queryParameters: query,
    );
    final data = response.data['data'] ?? response.data;

    List items = [];
    PaginationInfo pagination = PaginationInfo(
      total: 0,
      page: page,
      limit: limit,
      totalPages: 1,
    );

    if (data is Map) {
      if (data.containsKey('transactions') && data['transactions'] is List) {
        items = data['transactions'] as List;
      } else if (data.containsKey('data') && data['data'] is List) {
        items = data['data'] as List;
      }
      if (data.containsKey('pagination') && data['pagination'] is Map) {
        pagination = PaginationInfo.fromJson(
          Map<String, dynamic>.from(data['pagination']),
        );
      }
    } else if (data is List) {
      items = data;
      pagination = PaginationInfo(
        total: items.length,
        page: 1,
        limit: items.isNotEmpty ? items.length : 20,
        totalPages: 1,
      );
    }

    final transactions = items
        .map((i) => TransactionModel.fromJson(Map<String, dynamic>.from(i)))
        .toList();

    return PaginatedTransactions(
      transactions: transactions,
      pagination: pagination,
    );
  }

  Future<TransactionModel> createTransaction(
    Map<String, dynamic> payload, {
    String? idempotencyKey,
  }) async {
    final options = Options(
      headers: idempotencyKey != null && idempotencyKey.isNotEmpty
          ? {'Idempotency-Key': idempotencyKey}
          : null,
    );
    final response = await _dio.post(
      ApiEndpoints.financeTransactions,
      data: payload,
      options: options,
    );
    final data = response.data['data'] ?? response.data;
    return TransactionModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteTransaction(String id) async {
    await _dio.delete(ApiEndpoints.financeTransactionById(id));
  }

  Future<List<BudgetModel>> getBudgets({int? month, int? year}) async {
    final query = <String, dynamic>{
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    };
    final response = await _dio.get(
      ApiEndpoints.financeBudgets,
      queryParameters: query.isNotEmpty ? query : null,
    );
    final data = response.data['data'] ?? response.data;

    List items = [];
    if (data is Map && data.containsKey('budgets') && data['budgets'] is List) {
      items = data['budgets'] as List;
    } else if (data is List) {
      items = data;
    }

    return items
        .map((i) => BudgetModel.fromJson(Map<String, dynamic>.from(i)))
        .toList();
  }

  Future<BudgetModel> setBudget(Map<String, dynamic> payload) async {
    final response =
        await _dio.post(ApiEndpoints.financeBudgets, data: payload);
    final data = response.data['data'] ?? response.data;
    return BudgetModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<FinanceAnalyticsModel> getAnalytics({int? month, int? year}) async {
    final query = <String, dynamic>{
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    };
    final response = await _dio.get(
      ApiEndpoints.financeAnalytics,
      queryParameters: query.isNotEmpty ? query : null,
    );
    final data = response.data['data'] ?? response.data;
    return FinanceAnalyticsModel.fromJson(Map<String, dynamic>.from(data));
  }
}

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FinanceRepository(dio);
});
