import { Router } from 'express';
import * as financeController from './finance.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createTransactionSchema,
  updateTransactionSchema,
  getTransactionsQuerySchema,
  setBudgetSchema,
  uuidParamSchema,
} from './finance.validation';

const router = Router();

// All finance routes require authentication
router.use(authenticate);

// --- Analytics (UC-110, UC-111) ---
router.get('/analytics', financeController.getFinancialAnalytics);

// --- Budgets (UC-107, UC-108) ---
router.post('/budgets', validate(setBudgetSchema), financeController.setBudget);
router.get('/budgets', financeController.getBudgets);

// --- Transactions (UC-102 to UC-106) ---
router.post('/transactions', validate(createTransactionSchema), financeController.createTransaction);
router.get(
  '/transactions',
  validate(getTransactionsQuerySchema, 'query'),
  financeController.getTransactions
);
router.get('/transactions/:id', validate(uuidParamSchema, 'params'), financeController.getTransactionById);
router.put(
  '/transactions/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateTransactionSchema),
  financeController.updateTransaction
);
router.delete(
  '/transactions/:id',
  validate(uuidParamSchema, 'params'),
  financeController.deleteTransaction
);

export default router;
