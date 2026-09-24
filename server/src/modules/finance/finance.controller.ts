import { Request, Response } from 'express';
import financeService from './finance.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

// --- TRANSACTIONS ---

export const createTransaction = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const idempotencyKey = (req.headers['idempotency-key'] || req.headers['x-idempotency-key']) as string | undefined;
  const transaction = await financeService.createTransaction(authReq.user!.id, req.body, idempotencyKey);
  return ApiResponse.success(res, transaction, 'Transaction recorded successfully', 201);
});

export const getTransactions = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await financeService.getTransactions(authReq.user!.id, req.query);
  return ApiResponse.success(res, result, 'Transactions retrieved successfully');
});

export const getTransactionById = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const transaction = await financeService.getTransactionById(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, transaction, 'Transaction retrieved successfully');
});

export const updateTransaction = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const transaction = await financeService.updateTransaction(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, transaction, 'Transaction updated successfully');
});

export const deleteTransaction = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await financeService.deleteTransaction(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Transaction deleted successfully');
});

// --- BUDGETS ---

export const setBudget = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const budget = await financeService.setBudget(authReq.user!.id, req.body);
  return ApiResponse.success(res, budget, 'Budget set successfully', 201);
});

export const getBudgets = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const month = req.query.month ? parseInt(req.query.month as string) : undefined;
  const year = req.query.year ? parseInt(req.query.year as string) : undefined;
  const budgets = await financeService.getBudgets(authReq.user!.id, month, year);
  return ApiResponse.success(res, budgets, 'Budgets retrieved successfully');
});

// --- ANALYTICS ---

export const getFinancialAnalytics = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const month = req.query.month ? parseInt(req.query.month as string) : undefined;
  const year = req.query.year ? parseInt(req.query.year as string) : undefined;
  const analytics = await financeService.getFinancialAnalytics(authReq.user!.id, month, year);
  return ApiResponse.success(res, analytics, 'Financial analytics calculated successfully');
});

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
