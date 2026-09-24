import { Router, Request, Response } from 'express';
import prisma from '../../config/db';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';

const router = Router();

router.use(authenticate);

/**
 * GET /api/v1/finance/transactions
 */
router.get(
  '/transactions',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const { type, search } = req.query;

    const where: any = { userId };
    if (type && typeof type === 'string') {
      where.type = type.toUpperCase();
    }
    if (search && typeof search === 'string') {
      where.description = { contains: search, mode: 'insensitive' };
    }

    const transactions = await prisma.transaction.findMany({
      where,
      include: { category: true },
      orderBy: { date: 'desc' },
      take: 100,
    });

    return ApiResponse.success(res, transactions, 'Transactions retrieved');
  })
);

/**
 * POST /api/v1/finance/transactions
 */
router.post(
  '/transactions',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const { amount, type, description, date, categoryId, source } = req.body;

    const transaction = await prisma.transaction.create({
      data: {
        userId,
        amount: Number(amount) || 0,
        type: type || 'EXPENSE',
        description: description || null,
        date: date ? new Date(date) : new Date(),
        categoryId: categoryId || null,
        source: source || 'CASH',
      },
      include: { category: true },
    });

    return ApiResponse.success(res, transaction, 'Transaction created', 201);
  })
);

/**
 * DELETE /api/v1/finance/transactions/:id
 */
router.delete(
  '/transactions/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    await prisma.transaction.delete({ where: { id } });
    return ApiResponse.success(res, null, 'Transaction deleted');
  })
);

/**
 * GET /api/v1/finance/budgets
 */
router.get(
  '/budgets',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const now = new Date();

    const budgets = await prisma.budget.findMany({
      where: {
        userId,
        month: now.getMonth() + 1,
        year: now.getFullYear(),
      },
      include: { category: true },
    });

    return ApiResponse.success(res, budgets, 'Budgets retrieved');
  })
);

/**
 * POST /api/v1/finance/budgets
 */
router.post(
  '/budgets',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const { monthlyLimit, month, year, categoryId } = req.body;
    const now = new Date();

    const budget = await prisma.budget.upsert({
      where: {
        userId_categoryId_month_year: {
          userId,
          categoryId: categoryId || '',
          month: month || now.getMonth() + 1,
          year: year || now.getFullYear(),
        },
      },
      update: { monthlyLimit: Number(monthlyLimit) },
      create: {
        userId,
        monthlyLimit: Number(monthlyLimit) || 500,
        month: month || now.getMonth() + 1,
        year: year || now.getFullYear(),
        categoryId: categoryId || null,
      },
      include: { category: true },
    });

    return ApiResponse.success(res, budget, 'Budget set');
  })
);

/**
 * GET /api/v1/finance/analytics
 */
router.get(
  '/analytics',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const transactions = await prisma.transaction.findMany({
      where: { userId, date: { gte: startOfMonth } },
    });

    const income = transactions.filter((t) => t.type === 'INCOME').reduce((s, t) => s + t.amount, 0);
    const expenses = transactions.filter((t) => t.type === 'EXPENSE').reduce((s, t) => s + t.amount, 0);

    const analytics = {
      totalIncome: income,
      totalExpenses: expenses,
      netSavings: income - expenses,
      burnRatePerDay: expenses / Math.max(1, now.getDate()),
      categoryBreakdown: {},
    };

    return ApiResponse.success(res, analytics, 'Finance analytics retrieved');
  })
);

export default router;
