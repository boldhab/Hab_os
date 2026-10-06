import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';

export interface CreateTransactionDTO {
  amount: number | Prisma.Decimal;
  type: string;
  categoryId?: string | null;
  date?: Date | string;
  description?: string | null;
  source?: string;
}

export interface UpdateTransactionDTO {
  amount?: number | Prisma.Decimal;
  type?: string;
  categoryId?: string | null;
  date?: Date | string;
  description?: string | null;
  source?: string;
}

export interface GetTransactionsQuery {
  type?: string;
  categoryId?: string;
  month?: number;
  year?: number;
  search?: string;
  page?: number;
  limit?: number;
}

export interface SetBudgetDTO {
  categoryId: string;
  monthlyLimit: number | Prisma.Decimal;
  month?: number;
  year?: number;
}

const IDEMPOTENCY_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

// Helper to normalize Decimal to number for clean JSON serialization
export const decimalToNumber = (val: Prisma.Decimal | number | null | undefined): number => {
  if (val === null || val === undefined) return 0;
  if (typeof val === 'number') return val;
  return Number(val.toFixed(2));
};

// ==========================================
// 1. TRANSACTIONS (UC-102 to UC-106)
// ==========================================

export const createTransaction = async (userId: string, data: CreateTransactionDTO, idempotencyKey?: string) => {
  const trimmedKey = idempotencyKey?.trim();

  // 1. Check persistent idempotency store if key is provided
  if (trimmedKey) {
    const existingKey = await prisma.idempotencyKey.findUnique({
      where: {
        userId_key: {
          userId,
          key: trimmedKey,
        },
      },
    });

    if (existingKey) {
      if (existingKey.expiresAt > new Date()) {
        return existingKey.response;
      }
      // Delete expired key if present
      await prisma.idempotencyKey.delete({ where: { id: existingKey.id } }).catch(() => {});
    }
  }

  // 2. Validate category ownership and category type (must be FINANCE)
  if (data.categoryId) {
    const category = await prisma.category.findFirst({
      where: { id: data.categoryId, userId, type: 'FINANCE' },
    });
    if (!category) {
      throw new ApiError(404, 'Category not found or is not a finance category');
    }
  }

  const amountDecimal = new Prisma.Decimal(data.amount);

  // 3. Persist transaction (and idempotency key atomically if provided)
  let transaction: any;

  if (trimmedKey) {
    try {
      transaction = await prisma.$transaction(async (tx) => {
        const createdTx = await tx.transaction.create({
          data: {
            amount: amountDecimal,
            type: data.type,
            date: data.date ? new Date(data.date) : new Date(),
            description: data.description,
            source: data.source || 'CASH',
            categoryId: data.categoryId || null,
            userId,
          },
          include: {
            category: { select: { id: true, name: true, color: true, icon: true } },
          },
        });

        const serialized = {
          ...createdTx,
          amount: decimalToNumber(createdTx.amount),
        };

        await tx.idempotencyKey.create({
          data: {
            key: trimmedKey,
            userId,
            response: serialized,
            expiresAt: new Date(Date.now() + IDEMPOTENCY_TTL_MS),
          },
        });

        return serialized;
      });
    } catch (err: any) {
      // If a concurrent request created the key, return the existing idempotent response
      if (err.code === 'P2002') {
        const raceKey = await prisma.idempotencyKey.findUnique({
          where: { userId_key: { userId, key: trimmedKey } },
        });
        if (raceKey) {
          return raceKey.response;
        }
      }
      throw err;
    }
  } else {
    const rawTx = await prisma.transaction.create({
      data: {
        amount: amountDecimal,
        type: data.type,
        date: data.date ? new Date(data.date) : new Date(),
        description: data.description,
        source: data.source || 'CASH',
        categoryId: data.categoryId || null,
        userId,
      },
      include: {
        category: { select: { id: true, name: true, color: true, icon: true } },
      },
    });

    transaction = {
      ...rawTx,
      amount: decimalToNumber(rawTx.amount),
    };
  }

  invalidateDashboardCache(userId);

  return transaction;
};

export const getTransactions = async (userId: string, query: GetTransactionsQuery) => {
  const { type, categoryId, month, year, search, page = 1, limit = 20 } = query;
  const skip = (page - 1) * limit;

  const where: Prisma.TransactionWhereInput = { userId };

  if (type) where.type = type;
  if (categoryId) where.categoryId = categoryId;

  if (month && year) {
    const startOfMonth = new Date(year, month - 1, 1, 0, 0, 0);
    const endOfMonth = new Date(year, month, 0, 23, 59, 59, 999);
    where.date = { gte: startOfMonth, lte: endOfMonth };
  } else if (year) {
    const startOfYear = new Date(year, 0, 1, 0, 0, 0);
    const endOfYear = new Date(year, 11, 31, 23, 59, 59, 999);
    where.date = { gte: startOfYear, lte: endOfYear };
  }

  if (search && search.trim() !== '') {
    where.OR = [
      { description: { contains: search, mode: 'insensitive' } },
      { source: { contains: search, mode: 'insensitive' } },
    ];
  }

  const [rawTransactions, total] = await Promise.all([
    prisma.transaction.findMany({
      where,
      skip,
      take: limit,
      orderBy: { date: 'desc' },
      include: {
        category: { select: { id: true, name: true, color: true, icon: true } },
      },
    }),
    prisma.transaction.count({ where }),
  ]);

  const transactions = rawTransactions.map((t) => ({
    ...t,
    amount: decimalToNumber(t.amount),
  }));

  return {
    transactions,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    },
  };
};

export const getTransactionById = async (userId: string, transactionId: string) => {
  const transaction = await prisma.transaction.findFirst({
    where: { id: transactionId, userId },
    include: {
      category: true,
    },
  });

  if (!transaction) {
    throw new ApiError(404, 'Transaction not found');
  }

  return {
    ...transaction,
    amount: decimalToNumber(transaction.amount),
  };
};

export const updateTransaction = async (
  userId: string,
  transactionId: string,
  data: UpdateTransactionDTO
) => {
  const existing = await prisma.transaction.findFirst({
    where: { id: transactionId, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Transaction not found');
  }

  if (data.categoryId) {
    const category = await prisma.category.findFirst({
      where: { id: data.categoryId, userId, type: 'FINANCE' },
    });
    if (!category) {
      throw new ApiError(404, 'Category not found or is not a finance category');
    }
  }

  const updated = await prisma.transaction.update({
    where: { id: transactionId },
    data: {
      ...data,
      amount: data.amount !== undefined ? new Prisma.Decimal(data.amount) : undefined,
      date: data.date ? new Date(data.date) : undefined,
    },
    include: {
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  invalidateDashboardCache(userId);

  return {
    ...updated,
    amount: decimalToNumber(updated.amount),
  };
};

export const deleteTransaction = async (userId: string, transactionId: string) => {
  const existing = await prisma.transaction.findFirst({
    where: { id: transactionId, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Transaction not found');
  }

  await prisma.transaction.delete({ where: { id: transactionId } });

  invalidateDashboardCache(userId);

  return { message: 'Transaction deleted successfully' };
};

// ==========================================
// 2. BUDGETS & TRACKING (UC-107, UC-108)
// ==========================================

export const setBudget = async (userId: string, data: SetBudgetDTO) => {
  const now = new Date();
  const month = data.month || now.getMonth() + 1;
  const year = data.year || now.getFullYear();

  const category = await prisma.category.findFirst({
    where: { id: data.categoryId, userId, type: 'FINANCE' },
  });
  if (!category) {
    throw new ApiError(404, 'Category not found or is not a finance category');
  }

  const monthlyLimitDecimal = new Prisma.Decimal(data.monthlyLimit);

  const budget = await prisma.budget.upsert({
    where: {
      userId_categoryId_month_year: {
        userId,
        categoryId: data.categoryId,
        month,
        year,
      },
    },
    update: {
      monthlyLimit: monthlyLimitDecimal,
    },
    create: {
      categoryId: data.categoryId,
      monthlyLimit: monthlyLimitDecimal,
      month,
      year,
      userId,
    },
    include: {
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  invalidateDashboardCache(userId);

  return {
    ...budget,
    monthlyLimit: decimalToNumber(budget.monthlyLimit),
  };
};

export const getBudgets = async (userId: string, monthQuery?: number, yearQuery?: number) => {
  const now = new Date();
  const month = monthQuery || now.getMonth() + 1;
  const year = yearQuery || now.getFullYear();

  const startOfMonth = new Date(year, month - 1, 1, 0, 0, 0);
  const endOfMonth = new Date(year, month, 0, 23, 59, 59, 999);

  const budgets = await prisma.budget.findMany({
    where: { userId, month, year },
    include: {
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  // Optimize: Single batch aggregation using groupBy instead of N separate queries
  const categoryIds = budgets.map((b) => b.categoryId).filter((id): id is string => Boolean(id));
  const expenseAggregations = categoryIds.length > 0
    ? await prisma.transaction.groupBy({
        by: ['categoryId'],
        where: {
          userId,
          categoryId: { in: categoryIds },
          type: 'EXPENSE',
          date: { gte: startOfMonth, lte: endOfMonth },
        },
        _sum: { amount: true },
      })
    : [];

  const spentMap = new Map<string, Prisma.Decimal>();
  expenseAggregations.forEach((agg) => {
    if (agg.categoryId && agg._sum && agg._sum.amount) {
      spentMap.set(agg.categoryId, new Prisma.Decimal(agg._sum.amount));
    }
  });

  // Calculate actual spending for each budgeted category in O(1) map lookups
  const results = budgets.map((b) => {
    const spentDecimal = (b.categoryId ? spentMap.get(b.categoryId) : undefined) || new Prisma.Decimal(0);
    const monthlyLimitDecimal = new Prisma.Decimal(b.monthlyLimit);

    const spent = decimalToNumber(spentDecimal);
    const monthlyLimit = decimalToNumber(monthlyLimitDecimal);

    const percentageUsed = monthlyLimit > 0
      ? Number(spentDecimal.dividedBy(monthlyLimitDecimal).times(100).toFixed(1))
      : 0;

    const isExceeded = spentDecimal.greaterThan(monthlyLimitDecimal);
    const isWarning = percentageUsed >= 80 && !isExceeded;
    const remainingDecimal = spentDecimal.greaterThan(monthlyLimitDecimal)
      ? new Prisma.Decimal(0)
      : monthlyLimitDecimal.minus(spentDecimal);
    const remaining = decimalToNumber(remainingDecimal);

    return {
      id: b.id,
      category: b.category,
      monthlyLimit,
      spent,
      remaining,
      percentageUsed,
      isWarning,
      isExceeded,
    };
  });

  return {
    month,
    year,
    budgets: results,
  };
};

// ==========================================
// 3. ANALYTICS & REPORTS (UC-109, UC-110, UC-111)
// ==========================================

export const getFinancialAnalytics = async (
  userId: string,
  monthQuery?: number,
  yearQuery?: number
) => {
  const now = new Date();
  const month = monthQuery || now.getMonth() + 1;
  const year = yearQuery || now.getFullYear();

  const startOfMonth = new Date(year, month - 1, 1, 0, 0, 0);
  const endOfMonth = new Date(year, month, 0, 23, 59, 59, 999);

  const [incomeAgg, expenseAgg, expensesByCategory] = await Promise.all([
    prisma.transaction.aggregate({
      where: {
        userId,
        type: 'INCOME',
        date: { gte: startOfMonth, lte: endOfMonth },
      },
      _sum: { amount: true },
    }),
    prisma.transaction.aggregate({
      where: {
        userId,
        type: 'EXPENSE',
        date: { gte: startOfMonth, lte: endOfMonth },
      },
      _sum: { amount: true },
    }),
    prisma.transaction.groupBy({
      by: ['categoryId'],
      where: {
        userId,
        type: 'EXPENSE',
        date: { gte: startOfMonth, lte: endOfMonth },
      },
      _sum: { amount: true },
    }),
  ]);

  const totalIncomeDecimal = incomeAgg._sum.amount ? new Prisma.Decimal(incomeAgg._sum.amount) : new Prisma.Decimal(0);
  const totalExpensesDecimal = expenseAgg._sum.amount ? new Prisma.Decimal(expenseAgg._sum.amount) : new Prisma.Decimal(0);
  const netSavingsDecimal = totalIncomeDecimal.minus(totalExpensesDecimal);

  const totalIncome = decimalToNumber(totalIncomeDecimal);
  const totalExpenses = decimalToNumber(totalExpensesDecimal);
  const netSavings = decimalToNumber(netSavingsDecimal);

  const savingsRate = totalIncomeDecimal.greaterThan(0)
    ? Number(netSavingsDecimal.dividedBy(totalIncomeDecimal).times(100).toFixed(1))
    : 0;

  // Resolve category details (strictly scoped to user for defense in depth)
  const categoryIds = expensesByCategory.map((e) => e.categoryId).filter(Boolean) as string[];
  const categories = await prisma.category.findMany({
    where: { id: { in: categoryIds }, userId },
    select: { id: true, name: true, color: true, icon: true },
  });

  const categoryMap = new Map(categories.map((c) => [c.id, c]));

  const categoryBreakdown = expensesByCategory.map((item) => {
    const itemAmountDecimal = item._sum.amount ? new Prisma.Decimal(item._sum.amount) : new Prisma.Decimal(0);
    const amount = decimalToNumber(itemAmountDecimal);
    const cat = item.categoryId ? categoryMap.get(item.categoryId) : null;
    const percentage = totalExpensesDecimal.greaterThan(0)
      ? Number(itemAmountDecimal.dividedBy(totalExpensesDecimal).times(100).toFixed(1))
      : 0;

    return {
      categoryId: item.categoryId,
      categoryName: cat ? cat.name : 'Uncategorized',
      categoryColor: cat ? cat.color : '#94A3B8',
      amount,
      percentage,
    };
  });

  return {
    month,
    year,
    totalIncome,
    totalExpenses,
    netSavings,
    savingsRate,
    categoryBreakdown,
  };
};

export default {
  createTransaction,
  getTransactions,
  getTransactionById,
  updateTransaction,
  deleteTransaction,
  setBudget,
  getBudgets,
  getFinancialAnalytics,
};
