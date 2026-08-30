import Joi from 'joi';

export const createGoalSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Goal title is required',
    'any.required': 'Goal title is required',
  }),
  description: Joi.string().trim().allow('', null),
  category: Joi.string()
    .valid('CAREER', 'FITNESS', 'FINANCIAL', 'LEARNING', 'PERSONAL')
    .default('PERSONAL'),
  targetDate: Joi.date().iso().allow(null),
  progress: Joi.number().min(0).max(100).default(0.0),
  color: Joi.string().trim().default('#3B82F6'),
  milestones: Joi.array()
    .items(
      Joi.object({
        title: Joi.string().trim().required(),
        targetDate: Joi.date().iso().allow(null),
        isCompleted: Joi.boolean().default(false),
      })
    )
    .default([]),
});

export const updateGoalSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  category: Joi.string().valid('CAREER', 'FITNESS', 'FINANCIAL', 'LEARNING', 'PERSONAL'),
  targetDate: Joi.date().iso().allow(null),
  progress: Joi.number().min(0).max(100),
  color: Joi.string().trim(),
});

export const createMilestoneSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Milestone title is required',
    'any.required': 'Milestone title is required',
  }),
  targetDate: Joi.date().iso().allow(null),
  isCompleted: Joi.boolean().default(false),
});

export const updateMilestoneSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  targetDate: Joi.date().iso().allow(null),
  isCompleted: Joi.boolean(),
});

export const uuidParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

export const goalMilestoneParamSchema = Joi.object({
  goalId: Joi.string().uuid().required(),
  milestoneId: Joi.string().uuid().required(),
});
