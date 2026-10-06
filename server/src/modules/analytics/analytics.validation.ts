import Joi from 'joi';

export const createTimeEntrySchema = Joi.object({
  startTime: Joi.date().iso().required(),
  endTime: Joi.date().iso().greater(Joi.ref('startTime')).allow(null),
  duration: Joi.number().integer().min(1).allow(null), // in seconds
  taskId: Joi.string().uuid().allow(null),
});

export const updateTimeEntrySchema = Joi.object({
  startTime: Joi.date().iso(),
  endTime: Joi.date().iso(),
  duration: Joi.number().integer().min(1),
  taskId: Joi.string().uuid().allow(null),
}).min(1);

export const timeEntryQuerySchema = Joi.object({
  taskId: Joi.string().uuid(),
  startDate: Joi.date().iso(),
  endDate: Joi.date().iso(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

export const retrospectiveQuerySchema = Joi.object({
  period: Joi.string().valid('WEEKLY', 'MONTHLY').default('WEEKLY'),
  timezone: Joi.string().trim().default('UTC'),
});

export const uuidParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});
