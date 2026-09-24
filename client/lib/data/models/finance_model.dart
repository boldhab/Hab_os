import 'package:equatable/equatable.dart';

class TransactionCategorySummary extends Equatable {
  final String id;
  final String name;
  final String? color;
  final String? icon;

  const TransactionCategorySummary({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });

  factory TransactionCategorySummary.fromJson(Map<String, dynamic> json) {
    return TransactionCategorySummary(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'],
      icon: json['icon'],
    );
  }

  @override
  List<Object?> get props => [id, name, color, icon];
}

class TransactionModel extends Equatable {
  final String id;
  final double amount;
  final String type; // 'INCOME' or 'EXPENSE'
  final String? categoryId;
  final String date;
  final String? description;
  final String source;
  final TransactionCategorySummary? category;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.date,
    this.description,
    required this.source,
    this.category,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'EXPENSE',
      categoryId: json['categoryId'],
      date: json['date'] ?? '',
      description: json['description'],
      source: json['source'] ?? 'CASH',
      category: json['category'] != null
          ? TransactionCategorySummary.fromJson(Map<String, dynamic>.from(json['category']))
          : null,
    );
  }

  bool get isExpense => type.toUpperCase() == 'EXPENSE';
  bool get isIncome => type.toUpperCase() == 'INCOME';

  @override
  List<Object?> get props => [
        id,
        amount,
        type,
        categoryId,
        date,
        description,
        source,
        category,
      ];
}

class BudgetModel extends Equatable {
  final String id;
  final String categoryId;
  final double monthlyLimit;
  final int month;
  final int year;
  final TransactionCategorySummary? category;

  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.monthlyLimit,
    required this.month,
    required this.year,
    this.category,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] ?? '',
      categoryId: json['categoryId'] ?? '',
      monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 0.0,
      month: json['month'] ?? 1,
      year: json['year'] ?? 2026,
      category: json['category'] != null
          ? TransactionCategorySummary.fromJson(Map<String, dynamic>.from(json['category']))
          : null,
    );
  }

  @override
  List<Object?> get props => [id, categoryId, monthlyLimit, month, year, category];
}

class FinanceAnalyticsModel extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double netSavings;

  const FinanceAnalyticsModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
  });

  factory FinanceAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return FinanceAnalyticsModel(
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      netSavings: (json['netSavings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [totalIncome, totalExpense, netSavings];
}
