import Joi from 'joi';

export const createNoteSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Note title is required',
    'any.required': 'Note title is required',
  }),
  content: Joi.string().allow('', null).default(''),
  tags: Joi.array().items(Joi.string().trim()).default([]),
  codeSnippets: Joi.array()
    .items(
      Joi.object({
        language: Joi.string().trim().default('typescript'),
        code: Joi.string().required(),
        description: Joi.string().trim().allow('', null),
      })
    )
    .default([]),
  isMistakeSolution: Joi.boolean().default(false),
  categoryId: Joi.string().uuid().allow(null),
});

export const updateNoteSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  content: Joi.string().allow('', null),
  tags: Joi.array().items(Joi.string().trim()),
  codeSnippets: Joi.array().items(
    Joi.object({
      language: Joi.string().trim().default('typescript'),
      code: Joi.string().required(),
      description: Joi.string().trim().allow('', null),
    })
  ),
  isMistakeSolution: Joi.boolean(),
  categoryId: Joi.string().uuid().allow(null),
});

export const vaultSearchQuerySchema = Joi.object({
  search: Joi.string().trim().allow(''),
  tag: Joi.string().trim(),
  isMistakeSolution: Joi.boolean(),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

export const uuidParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});
