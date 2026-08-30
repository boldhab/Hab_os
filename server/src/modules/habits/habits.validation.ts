import Joi from 'joi';

export const createHabitSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Habit name is required',
    'any.required': 'Habit name is required',
  }),
  description: Joi.string().trim().allow('', null),
  frequency: Joi.string().valid('DAILY', 'WEEKLY', 'CUSTOM').default('DAILY'),
  targetType: Joi.string().valid('CHECKBOX', 'DURATION', 'COUNT').default('CHECKBOX'),
  targetValue: Joi.number().integer().min(1).default(1),
  reminderTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  categoryId: Joi.string().uuid().allow(null),
});

export const updateHabitSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  frequency: Joi.string().valid('DAILY', 'WEEKLY', 'CUSTOM'),
  targetType: Joi.string().valid('CHECKBOX', 'DURATION', 'COUNT'),
  targetValue: Joi.number().integer().min(1),
  reminderTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  categoryId: Joi.string().uuid().allow(null),
  isActive: Joi.boolean(),
});

export const logHabitSchema = Joi.object({
  date: Joi.date().iso().default(() => new Date().toISOString().split('T')[0]),
  isCompleted: Joi.boolean().default(true),
  value: Joi.number().integer().min(0).default(1),
  notes: Joi.string().trim().allow('', null),
});

export const habitIdParamSchema = Joi.object({
  id: Joi.string().uuid().required().messages({
    'string.guid': 'Invalid habit ID format',
    'any.required': 'Habit ID is required',
  }),
});
