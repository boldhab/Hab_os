import Joi from 'joi';

export const FOCUS_CATEGORIES = [
  'CODING',
  'STUDY',
  'PROJECT',
  'READING',
  'WELLNESS',
  'OTHER',
] as const;

export type FocusCategory = (typeof FOCUS_CATEGORIES)[number];

export const FOCUS_STATUSES = [
  'RUNNING',
  'PAUSED',
  'COMPLETED',
  'CANCELLED',
] as const;

export type FocusStatus = (typeof FOCUS_STATUSES)[number];

export const startFocusSchema = Joi.object({
  category: Joi.string().valid(...FOCUS_CATEGORIES).default('CODING'),
  taskId: Joi.string().uuid().allow(null),
  courseId: Joi.string().uuid().allow(null),
  notes: Joi.string().trim().max(1000).allow('', null),
});

export const endFocusSchema = Joi.object({
  durationMinutes: Joi.number().integer().min(1).max(1440).required().messages({
    'any.required': 'Duration in minutes is required',
  }),
  notes: Joi.string().trim().max(1000).allow('', null),
  taskId: Joi.string().uuid().allow(null),
});

export const logCompletedFocusSchema = Joi.object({
  startTime: Joi.date().iso().required().messages({
    'any.required': 'Start time is required',
  }),
  endTime: Joi.date().iso().greater(Joi.ref('startTime')).required().messages({
    'date.greater': 'End time must be after start time',
    'any.required': 'End time is required',
  }),
  durationMinutes: Joi.number().integer().min(1).max(1440).required().messages({
    'any.required': 'Duration in minutes is required',
  }),
  category: Joi.string().valid(...FOCUS_CATEGORIES).default('CODING'),
  taskId: Joi.string().uuid().allow(null),
  courseId: Joi.string().uuid().allow(null),
  notes: Joi.string().trim().max(1000).allow('', null),
});

export const cancelFocusSchema = Joi.object({
  notes: Joi.string().trim().max(1000).allow('', null),
});

export const getFocusQuerySchema = Joi.object({
  category: Joi.string().valid(...FOCUS_CATEGORIES),
  status: Joi.string().valid(...FOCUS_STATUSES),
  taskId: Joi.string().uuid(),
  courseId: Joi.string().uuid(),
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
