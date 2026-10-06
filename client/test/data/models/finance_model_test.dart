import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/data/models/finance_model.dart';
import 'package:habos_client/presentation/providers/finance_provider.dart';

void main() {
  group('TransactionModel', () {
    test('should parse from valid JSON', () {
      final json = {
        'id': 'tx-1',
        'amount': 49.99,
        'type': 'EXPENSE',
        'category': {
          'id': 'cat-1',
          'name': 'Food & Groceries',
        },
        'date': '2026-08-31T12:00:00.000Z',
        'description': 'Weekly grocery run',
        'source': 'CARD',
      };

      final tx = TransactionModel.fromJson(json);

      expect(tx.id, 'tx-1');
      expect(tx.amount, 49.99);
      expect(tx.type, 'EXPENSE');
      expect(tx.category?.name, 'Food & Groceries');
      expect(tx.isExpense, isTrue);
      expect(tx.isIncome, isFalse);
    });
  });

  group('BudgetModel', () {
    test('should parse from backend enriched budget structure', () {
      final json = {
        'id': 'b-1',
        'category': {
          'id': 'cat-1',
          'name': 'Food & Groceries',
          'color': '#F59E0B',
          'icon': 'restaurant',
        },
        'monthlyLimit': 800.0,
        'spent': 640.0,
        'remaining': 160.0,
        'percentageUsed': 80.0,
        'isWarning': true,
        'isExceeded': false,
        'month': 10,
        'year': 2026,
      };

      final budget = BudgetModel.fromJson(json);

      expect(budget.id, 'b-1');
      expect(budget.categoryId, 'cat-1');
      expect(budget.monthlyLimit, 800.0);
      expect(budget.spent, 640.0);
      expect(budget.remaining, 160.0);
      expect(budget.percentageUsed, 80.0);
      expect(budget.isWarning, isTrue);
      expect(budget.isExceeded, isFalse);
      expect(budget.category?.name, 'Food & Groceries');
    });

    test('should parse minimal budget without calculation fields', () {
      final json = {
        'id': 'b-2',
        'categoryId': 'cat-2',
        'monthlyLimit': 300.0,
        'month': 10,
        'year': 2026,
      };

      final budget = BudgetModel.fromJson(json);

      expect(budget.id, 'b-2');
      expect(budget.monthlyLimit, 300.0);
      expect(budget.spent, 0.0);
      expect(budget.remaining, 300.0);
      expect(budget.percentageUsed, 0.0);
      expect(budget.isWarning, isFalse);
      expect(budget.isExceeded, isFalse);
    });
  });

  group('FinanceAnalyticsModel', () {
    test('should parse analytics summary correctly', () {
      final json = {
        'totalIncome': 5000.0,
        'totalExpense': 2000.0,
        'netSavings': 3000.0,
      };

      final analytics = FinanceAnalyticsModel.fromJson(json);

      expect(analytics.totalIncome, 5000.0);
      expect(analytics.totalExpense, 2000.0);
      expect(analytics.netSavings, 3000.0);
    });
  });

  group('FinanceState.copyWith Filter Preservation', () {
    test('preserves selectedType when omitted in copyWith', () {
      const state = FinanceState(
        selectedType: 'EXPENSE',
        searchQuery: 'groceries',
      );

      // copyWith without passing selectedType
      final updated = state.copyWith(status: FinanceStatus.loaded);

      expect(updated.selectedType, 'EXPENSE',
          reason: 'Filter should NOT be reset to null when omitted');
      expect(updated.searchQuery, 'groceries');
      expect(updated.status, FinanceStatus.loaded);
    });

    test('allows explicitly clearing selectedType to null', () {
      const state = FinanceState(
        selectedType: 'EXPENSE',
      );

      final updated = state.copyWith(selectedType: null);

      expect(updated.selectedType, isNull,
          reason: 'Passing explicit null should clear the filter');
    });
  });

  group('Pagination Parsing', () {
    test('should parse PaginationInfo correctly', () {
      final json = {
        'total': 45,
        'page': 2,
        'limit': 20,
        'totalPages': 3,
      };

      final pagination = PaginationInfo.fromJson(json);

      expect(pagination.total, 45);
      expect(pagination.page, 2);
      expect(pagination.limit, 20);
      expect(pagination.totalPages, 3);
    });
  });
}
