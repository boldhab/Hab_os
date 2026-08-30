import Joi from 'joi';

export const createTransactionSchema = Joi.object({
  amount: Joi.number().positive().required().messages({
    'number.positive': 'Transaction amount must be a positive number',
    'any.required': 'Amount is required',
  }),
  type: Joi.string().valid('INCOME', 'EXPENSE').required().messages({
    'any.required': 'Transaction type is required (INCOME or EXPENSE)',
  }),
  categoryId: Joi.string().uuid().allow(null),
  date: Joi.date().iso().default(() => new Date().toISOString()),
  description: Joi.string().trim().allow('', null),
  source: Joi.string().trim().default('CASH'),
});

export const updateTransactionSchema = Joi.object({
  amount: Joi.number().positive(),
  type: Joi.string().valid('INCOME', 'EXPENSE'),
  categoryId: Joi.string().uuid().allow(null),
  date: Joi.date().iso(),
  description: Joi.string().trim().allow('', null),
  source: Joi.string().trim(),
});

export const getTransactionsQuerySchema = Joi.object({
  type: Joi.string().valid('INCOME', 'EXPENSE'),
  categoryId: Joi.string().uuid(),
  month: Joi.number().integer().min(1).max(12),
  year: Joi.number().integer().min(2020).max(2050),
  search: Joi.string().trim().allow(''),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

export const setBudgetSchema = Joi.object({
  categoryId: Joi.string().uuid().required().messages({
    'any.required': 'Category ID is required for budget',
  }),
  monthlyLimit: Joi.number().positive().required().messages({
    'any.required': 'Monthly budget limit is required',
  }),
  month: Joi.number().integer().min(1).max(12).default(() => new Date().getMonth() + 1),
  year: Joi.number().integer().min(2020).max(2050).default(() => new Date().getFullYear()),
});

export const uuidParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});
