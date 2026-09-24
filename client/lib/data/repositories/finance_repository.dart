import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/finance_model.dart';

class FinanceRepository {
  final Dio _dio;

  FinanceRepository(this._dio);

  Future<List<TransactionModel>> getTransactions({
    String? type,
    int? month,
    int? year,
    String? search,
  }) async {
    final query = <String, dynamic>{
      if (type != null && type.isNotEmpty) 'type': type,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final response =
        await _dio.get(ApiEndpoints.financeTransactions, queryParameters: query);
    final data = response.data['data'];
    List items = [];
    if (data is Map && data.containsKey('data')) {
      items = data['data'] as List;
    } else if (data is List) {
      items = data;
    }
    return items
        .map((i) => TransactionModel.fromJson(Map<String, dynamic>.from(i)))
        .toList();
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> payload) async {
    final response =
        await _dio.post(ApiEndpoints.financeTransactions, data: payload);
    final data = response.data['data'] ?? response.data;
    return TransactionModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteTransaction(String id) async {
    await _dio.delete(ApiEndpoints.financeTransactionById(id));
  }

  Future<List<BudgetModel>> getBudgets() async {
    final response = await _dio.get(ApiEndpoints.financeBudgets);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data
          .map((i) => BudgetModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }
    return [];
  }

  Future<BudgetModel> setBudget(Map<String, dynamic> payload) async {
    final response =
        await _dio.post(ApiEndpoints.financeBudgets, data: payload);
    final data = response.data['data'] ?? response.data;
    return BudgetModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<FinanceAnalyticsModel> getAnalytics() async {
    final response = await _dio.get(ApiEndpoints.financeAnalytics);
    final data = response.data['data'] ?? response.data;
    return FinanceAnalyticsModel.fromJson(Map<String, dynamic>.from(data));
  }
}

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FinanceRepository(dio);
});
