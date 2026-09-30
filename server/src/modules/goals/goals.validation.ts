import Joi from 'joi';

export const createGoalSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Goal title is required',
    'any.required': 'Goal title is required',
  }),
  description: Joi.string().trim().allow('', null),
  category: Joi.string()
    .valid('CAREER', 'HEALTH', 'EDUCATION', 'PERSONAL', 'FINANCIAL', 'FITNESS', 'LEARNING')
    .default('PERSONAL'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL').default('MEDIUM'),
  targetDate: Joi.date().iso().allow(null),
  progress: Joi.number().min(0).max(100).default(0.0),
  targetAmount: Joi.number().min(0).allow(null),
  currentAmount: Joi.number().min(0).default(0.0),
  color: Joi.string().trim().default('#3B82F6'),
  milestones: Joi.array()
    .items(
      Joi.object({
        title: Joi.string().trim().required(),
        description: Joi.string().trim().allow('', null),
        targetDate: Joi.date().iso().allow(null),
        isCompleted: Joi.boolean().default(false),
        weight: Joi.number().min(0.1).default(1.0),
        order: Joi.number().default(0.0),
      })
    )
    .default([]),
});

export const updateGoalSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  category: Joi.string().valid('CAREER', 'HEALTH', 'EDUCATION', 'PERSONAL', 'FINANCIAL', 'FITNESS', 'LEARNING'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'),
  status: Joi.string().valid('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED', 'ARCHIVED'),
  targetDate: Joi.date().iso().allow(null),
  progress: Joi.number().min(0).max(100),
  targetAmount: Joi.number().min(0).allow(null),
  currentAmount: Joi.number().min(0),
  color: Joi.string().trim(),
});

export const createMilestoneSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Milestone title is required',
    'any.required': 'Milestone title is required',
  }),
  description: Joi.string().trim().allow('', null),
  targetDate: Joi.date().iso().allow(null),
  isCompleted: Joi.boolean().default(false),
  weight: Joi.number().min(0.1).default(1.0),
  order: Joi.number().default(0.0),
});

export const updateMilestoneSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  targetDate: Joi.date().iso().allow(null),
  status: Joi.string().valid('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED'),
  isCompleted: Joi.boolean(),
  weight: Joi.number().min(0.1),
  order: Joi.number(),
});

export const createCheckInSchema = Joi.object({
  confidence: Joi.string().valid('ON_TRACK', 'BEHIND', 'AT_RISK').default('ON_TRACK'),
  note: Joi.string().trim().allow('', null),
});

export const contributeGoalSchema = Joi.object({
  amount: Joi.number().positive().required(),
});

export const uuidParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

export const goalMilestoneParamSchema = Joi.object({
  goalId: Joi.string().uuid().required(),
  milestoneId: Joi.string().uuid().required(),
});
