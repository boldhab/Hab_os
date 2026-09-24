import Joi from 'joi';

export const createTechLearningSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Technology name is required',
    'any.required': 'Technology name is required',
  }),
  status: Joi.string()
    .valid('NOT_STARTED', 'LEARNING', 'PRACTICING', 'COMPLETED')
    .default('NOT_STARTED'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH').default('MEDIUM'),
  progressPercentage: Joi.number().min(0).max(100).default(0.0),
  resources: Joi.array()
    .items(
      Joi.object({
        title: Joi.string().trim().required(),
        type: Joi.string().trim().allow('', null),
        url: Joi.string().uri().allow('', null),
        notes: Joi.string().trim().allow('', null),
      })
    )
    .default([]),
});

export const updateTechLearningSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255),
  status: Joi.string().valid('NOT_STARTED', 'LEARNING', 'PRACTICING', 'COMPLETED'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH'),
  progressPercentage: Joi.number().min(0).max(100),
  resources: Joi.array().items(
    Joi.object({
      title: Joi.string().trim().required(),
      type: Joi.string().trim().allow('', null),
      url: Joi.string().uri().allow('', null),
      notes: Joi.string().trim().allow('', null),
    })
  ),
});

export const uuidParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});
