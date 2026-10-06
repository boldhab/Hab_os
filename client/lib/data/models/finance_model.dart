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
          ? TransactionCategorySummary.fromJson(
              Map<String, dynamic>.from(json['category']))
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
  final double spent;
  final double remaining;
  final double percentageUsed;
  final bool isWarning;
  final bool isExceeded;
  final TransactionCategorySummary? category;

  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.monthlyLimit,
    required this.month,
    required this.year,
    this.spent = 0.0,
    this.remaining = 0.0,
    this.percentageUsed = 0.0,
    this.isWarning = false,
    this.isExceeded = false,
    this.category,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    final limit = (json['monthlyLimit'] as num?)?.toDouble() ?? 0.0;
    final spentVal = (json['spent'] as num?)?.toDouble() ?? 0.0;
    final remainingVal = json['remaining'] != null
        ? (json['remaining'] as num).toDouble()
        : (limit - spentVal > 0 ? limit - spentVal : 0.0);
    final percentVal = json['percentageUsed'] != null
        ? (json['percentageUsed'] as num).toDouble()
        : (limit > 0 ? (spentVal / limit) * 100 : 0.0);

    return BudgetModel(
      id: json['id'] ?? '',
      categoryId: json['categoryId'] ?? json['category']?['id'] ?? '',
      monthlyLimit: limit,
      month: json['month'] ?? 1,
      year: json['year'] ?? 2026,
      spent: spentVal,
      remaining: remainingVal,
      percentageUsed: percentVal,
      isWarning: json['isWarning'] as bool? ?? (percentVal >= 80 && spentVal <= limit),
      isExceeded: json['isExceeded'] as bool? ?? (spentVal > limit),
      category: json['category'] != null
          ? TransactionCategorySummary.fromJson(
              Map<String, dynamic>.from(json['category']))
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        monthlyLimit,
        month,
        year,
        spent,
        remaining,
        percentageUsed,
        isWarning,
        isExceeded,
        category,
      ];
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

class PaginationInfo extends Equatable {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginationInfo({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [total, page, limit, totalPages];
}

class PaginatedTransactions extends Equatable {
  final List<TransactionModel> transactions;
  final PaginationInfo pagination;

  const PaginatedTransactions({
    required this.transactions,
    required this.pagination,
  });

  @override
  List<Object?> get props => [transactions, pagination];
}
