import Joi from 'joi';

export const askAiSchema = Joi.object({
  prompt: Joi.string().trim().min(1).max(2000).required().messages({
    'string.empty': 'Prompt cannot be empty',
    'any.required': 'Prompt is required',
  }),
  contextScope: Joi.string()
    .valid('ALL', 'TASKS', 'HABITS', 'STUDY', 'DEV', 'GYM', 'FINANCE')
    .default('ALL'),
});

export const briefingQuerySchema = Joi.object({
  date: Joi.date().iso(),
});
