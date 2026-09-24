import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/data/models/finance_model.dart';

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
    test('should parse from JSON', () {
      final json = {
        'id': 'b-1',
        'categoryId': 'cat-1',
        'monthlyLimit': 200.0,
        'month': 8,
        'year': 2026,
      };

      final budget = BudgetModel.fromJson(json);

      expect(budget.id, 'b-1');
      expect(budget.monthlyLimit, 200.0);
      expect(budget.month, 8);
      expect(budget.year, 2026);
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
}
