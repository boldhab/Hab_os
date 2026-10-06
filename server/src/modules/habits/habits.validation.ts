import Joi from 'joi';

const validateFrequencyMatrix = (obj: any, helpers: any) => {
  const freq = obj.frequency;
  const period = obj.targetFrequencyPeriod;
  const count = obj.targetFrequencyCount;

  if (freq === 'DAILY' && period === 'MONTH') {
    return helpers.message({
      custom: 'Daily habits cannot have a monthly target period. Use CUSTOM frequency for monthly targets.',
    });
  }

  if (freq === 'WEEKLY' && period === 'MONTH') {
    return helpers.message({
      custom: 'Weekly habits cannot have a monthly target period. Use CUSTOM frequency for monthly targets.',
    });
  }

  if (freq === 'WEEKLY' && period === 'DAY') {
    return helpers.message({
      custom: 'Weekly habits cannot have a daily target period. Use WEEK or DAY with DAILY frequency.',
    });
  }

  if (period === 'WEEK' && count !== undefined && count > 7) {
    return helpers.message({
      custom: 'Weekly target count cannot exceed 7 days per week.',
    });
  }

  if (period === 'MONTH' && count !== undefined && count > 31) {
    return helpers.message({
      custom: 'Monthly target count cannot exceed 31 days per month.',
    });
  }

  if (period === 'DAY' && count !== undefined && count > 1) {
    return helpers.message({
      custom: 'Daily period target count cannot exceed 1. Use COUNT or DURATION targetType for multiple daily reps.',
    });
  }

  return obj;
};

export const createHabitSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Habit name is required',
    'any.required': 'Habit name is required',
  }),
  description: Joi.string().trim().allow('', null),
  frequency: Joi.string().valid('DAILY', 'WEEKLY', 'CUSTOM').default('DAILY'),
  targetFrequencyCount: Joi.number().integer().min(1).default(1),
  targetFrequencyPeriod: Joi.string().valid('DAY', 'WEEK', 'MONTH').default('DAY'),
  targetType: Joi.string().valid('CHECKBOX', 'DURATION', 'COUNT').default('CHECKBOX'),
  targetValue: Joi.number().integer().min(1).default(1),
  reminderTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  categoryId: Joi.string().uuid().allow(null),
  difficulty: Joi.string().valid('TRIVIAL', 'EASY', 'MEDIUM', 'HARD', 'EPIC').default('MEDIUM'),
  weight: Joi.number().min(0.1).max(10.0).default(1.0),
  streakFreezes: Joi.number().integer().min(0).max(5).default(2),
}).custom(validateFrequencyMatrix);

export const updateHabitSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  frequency: Joi.string().valid('DAILY', 'WEEKLY', 'CUSTOM'),
  targetFrequencyCount: Joi.number().integer().min(1),
  targetFrequencyPeriod: Joi.string().valid('DAY', 'WEEK', 'MONTH'),
  targetType: Joi.string().valid('CHECKBOX', 'DURATION', 'COUNT'),
  targetValue: Joi.number().integer().min(1),
  reminderTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  categoryId: Joi.string().uuid().allow(null),
  difficulty: Joi.string().valid('TRIVIAL', 'EASY', 'MEDIUM', 'HARD', 'EPIC'),
  weight: Joi.number().min(0.1).max(10.0),
  streakFreezes: Joi.number().integer().min(0).max(5),
  isActive: Joi.boolean(),
}).custom(validateFrequencyMatrix);

export const refillFreezeSchema = Joi.object({
  count: Joi.number().integer().min(1).max(3).default(1),
});

export const logHabitSchema = Joi.object({
  date: Joi.date().iso().default(() => new Date().toISOString().split('T')[0]),
  isCompleted: Joi.boolean().default(true),
  value: Joi.number().min(0).default(1),
  notes: Joi.string().trim().allow('', null),
}).custom((obj, helpers) => {
  // Reject contradictory payloads: cannot mark complete with value 0
  if (obj.isCompleted === true && obj.value === 0) {
    return helpers.message({
      custom: 'Cannot mark habit as completed with a value of 0',
    });
  }
  return obj;
});

export const habitIdParamSchema = Joi.object({
  id: Joi.string().uuid().required().messages({
    'string.guid': 'Invalid habit ID format',
    'any.required': 'Habit ID is required',
  }),
});

export const createRoutineSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255).required(),
  description: Joi.string().trim().allow('', null),
  icon: Joi.string().trim().default('routine'),
  color: Joi.string().trim().default('#3B82F6'),
  targetTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  habitIds: Joi.array().items(Joi.string().uuid()).default([]),
});

export const updateRoutineSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  icon: Joi.string().trim(),
  color: Joi.string().trim(),
  targetTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  habitIds: Joi.array().items(Joi.string().uuid()),
});

export const routineIdParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});
