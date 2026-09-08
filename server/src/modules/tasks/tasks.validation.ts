import Joi from 'joi';

export const createTaskSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Task title is required',
    'any.required': 'Task title is required',
  }),
  description: Joi.string().trim().allow('', null),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL').default('MEDIUM'),
  status: Joi.string().valid('TODO', 'IN_PROGRESS', 'COMPLETED', 'BLOCKED').default('TODO'),
  dueDate: Joi.date().iso().allow(null),
  estimatedMinutes: Joi.number().integer().min(1).max(1440).allow(null),
  projectId: Joi.string().uuid().allow(null),
  goalId: Joi.string().uuid().allow(null),
  categoryId: Joi.string().uuid().allow(null),
});

export const updateTaskSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'),
  status: Joi.string().valid('TODO', 'IN_PROGRESS', 'COMPLETED', 'BLOCKED'),
  isCompleted: Joi.boolean(),
  dueDate: Joi.date().iso().allow(null),
  estimatedMinutes: Joi.number().integer().min(1).max(1440).allow(null),
  projectId: Joi.string().uuid().allow(null),
  goalId: Joi.string().uuid().allow(null),
  categoryId: Joi.string().uuid().allow(null),
});

export const getTasksQuerySchema = Joi.object({
  view: Joi.string().valid('today', 'upcoming', 'overdue', 'completed', 'all').default('all'),
  status: Joi.string().valid('TODO', 'IN_PROGRESS', 'COMPLETED', 'BLOCKED'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'),
  projectId: Joi.string().uuid(),
  goalId: Joi.string().uuid(),
  categoryId: Joi.string().uuid(),
  search: Joi.string().trim().allow(''),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

export const taskIdParamSchema = Joi.object({
  id: Joi.string().uuid().required().messages({
    'string.guid': 'Invalid task ID format',
    'any.required': 'Task ID is required',
  }),
});
