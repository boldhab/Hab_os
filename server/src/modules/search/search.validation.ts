import Joi from 'joi';

export const globalSearchQuerySchema = Joi.object({
  q: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Search query is required',
    'any.required': 'Search query is required',
  }),
  domain: Joi.string()
    .valid('ALL', 'TASKS', 'PROJECTS', 'COURSES', 'VAULT', 'HABITS', 'GOALS', 'GYM', 'FINANCE')
    .default('ALL'),
  limit: Joi.number().integer().min(1).max(50).default(10),
});
