import Joi from 'joi';

export const createTimeEntrySchema = Joi.object({
  startTime: Joi.date().iso().required(),
  endTime: Joi.date().iso().greater(Joi.ref('startTime')).required(),
  duration: Joi.number().integer().min(1).required(), // in seconds
  taskId: Joi.string().uuid().allow(null),
});

export const timeEntryQuerySchema = Joi.object({
  taskId: Joi.string().uuid(),
  startDate: Joi.date().iso(),
  endDate: Joi.date().iso(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

export const uuidParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});
