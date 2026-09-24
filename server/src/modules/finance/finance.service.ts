import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';

export interface CreateTransactionDTO {
  amount: number;
  type: string;
  categoryId?: string | null;
  date?: Date | string;
  description?: string | null;
  source?: string;
}

export interface UpdateTransactionDTO {
  amount?: number;
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
  monthlyLimit: number;
  month?: number;
  year?: number;
}

interface IdempotencyRecord {
  response: any;
  expiresAt: number;
}

const idempotencyStore = new Map<string, IdempotencyRecord>();
const IDEMPOTENCY_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

// ==========================================
// 1. TRANSACTIONS (UC-102 to UC-106)
// ==========================================

export const createTransaction = async (userId: string, data: CreateTransactionDTO, idempotencyKey?: string) => {
  if (idempotencyKey && idempotencyKey.trim() !== '') {
    const cacheKey = `${userId}:${idempotencyKey.trim()}`;
    const cached = idempotencyStore.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.response;
    }
  }

  if (data.categoryId) {
    const category = await prisma.category.findFirst({
      where: { id: data.categoryId, userId },
    });
    if (!category) throw new ApiError(404, 'Category not found');
  }

  const transaction = await prisma.transaction.create({
    data: {
      amount: data.amount,
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

  if (idempotencyKey && idempotencyKey.trim() !== '') {
    const cacheKey = `${userId}:${idempotencyKey.trim()}`;
    idempotencyStore.set(cacheKey, {
      response: transaction,
      expiresAt: Date.now() + IDEMPOTENCY_TTL_MS,
    });
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

  const [transactions, total] = await Promise.all([
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

  return transaction;
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
      where: { id: data.categoryId, userId },
    });
    if (!category) throw new ApiError(404, 'Category not found');
  }

  const updated = await prisma.transaction.update({
    where: { id: transactionId },
    data: {
      ...data,
      date: data.date ? new Date(data.date) : undefined,
    },
    include: {
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  invalidateDashboardCache(userId);

  return updated;
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
    where: { id: data.categoryId, userId },
  });
  if (!category) throw new ApiError(404, 'Category not found');

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
      monthlyLimit: data.monthlyLimit,
    },
    create: {
      categoryId: data.categoryId,
      monthlyLimit: data.monthlyLimit,
      month,
      year,
      userId,
    },
    include: {
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  return budget;
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

  // Calculate actual spending for each budgeted category
  const results = await Promise.all(
    budgets.map(async (b) => {
      const expenses = await prisma.transaction.aggregate({
        where: {
          userId,
          categoryId: b.categoryId,
          type: 'EXPENSE',
          date: { gte: startOfMonth, lte: endOfMonth },
        },
        _sum: { amount: true },
      });

      const spent = expenses._sum.amount || 0;
      const percentageUsed = Number(((spent / b.monthlyLimit) * 100).toFixed(1));
      const isExceeded = spent > b.monthlyLimit;
      const isWarning = percentageUsed >= 80 && !isExceeded;

      return {
        id: b.id,
        category: b.category,
        monthlyLimit: b.monthlyLimit,
        spent,
        remaining: Math.max(0, b.monthlyLimit - spent),
        percentageUsed,
        isWarning,
        isExceeded,
      };
    })
  );

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

  const totalIncome = incomeAgg._sum.amount || 0;
  const totalExpenses = expenseAgg._sum.amount || 0;
  const netSavings = totalIncome - totalExpenses;
  const savingsRate = totalIncome > 0 ? Number(((netSavings / totalIncome) * 100).toFixed(1)) : 0;

  // Resolve category details
  const categoryIds = expensesByCategory.map((e) => e.categoryId).filter(Boolean) as string[];
  const categories = await prisma.category.findMany({
    where: { id: { in: categoryIds } },
    select: { id: true, name: true, color: true, icon: true },
  });

  const categoryMap = new Map(categories.map((c) => [c.id, c]));

  const categoryBreakdown = expensesByCategory.map((item) => {
    const amount = item._sum.amount || 0;
    const cat = item.categoryId ? categoryMap.get(item.categoryId) : null;
    const percentage = totalExpenses > 0 ? Number(((amount / totalExpenses) * 100).toFixed(1)) : 0;

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
