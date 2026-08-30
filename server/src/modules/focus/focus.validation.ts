import Joi from 'joi';

export const startFocusSchema = Joi.object({
  category: Joi.string().valid('CODING', 'STUDY', 'PROJECT', 'READING', 'OTHER').default('CODING'),
  taskId: Joi.string().uuid().allow(null),
  notes: Joi.string().trim().allow('', null),
});

export const endFocusSchema = Joi.object({
  durationMinutes: Joi.number().integer().min(1).max(1440).required().messages({
    'any.required': 'Duration in minutes is required',
  }),
  notes: Joi.string().trim().allow('', null),
  taskId: Joi.string().uuid().allow(null),
});

export const logCompletedFocusSchema = Joi.object({
  startTime: Joi.date().iso().required(),
  endTime: Joi.date().iso().required(),
  durationMinutes: Joi.number().integer().min(1).max(1440).required(),
  category: Joi.string().valid('CODING', 'STUDY', 'PROJECT', 'READING', 'OTHER').default('CODING'),
  taskId: Joi.string().uuid().allow(null),
  notes: Joi.string().trim().allow('', null),
});

export const getFocusQuerySchema = Joi.object({
  category: Joi.string().valid('CODING', 'STUDY', 'PROJECT', 'READING', 'OTHER'),
  taskId: Joi.string().uuid(),
  startDate: Joi.date().iso(),
  endDate: Joi.date().iso(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

export const focusIdParamSchema = Joi.object({
  id: Joi.string().uuid().required().messages({
    'string.guid': 'Invalid focus session ID format',
    'any.required': 'Focus session ID is required',
  }),
});
