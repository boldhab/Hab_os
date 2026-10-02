import Joi from 'joi';

export const createProjectSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Project title is required',
    'any.required': 'Project title is required',
  }),
  description: Joi.string().trim().allow('', null),
  repoUrl: Joi.string().uri().allow('', null),
  status: Joi.string().valid('PLANNING', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'ARCHIVED').default('PLANNING'),
  progress: Joi.number().min(0).max(100).default(0.0),
  technologies: Joi.array().items(Joi.string().trim()).default([]),
  color: Joi.string().trim().default('#10B981'),
  manualProgress: Joi.boolean().default(false),
  webhookSecret: Joi.string().trim().allow('', null),
});

export const updateProjectSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  repoUrl: Joi.string().uri().allow('', null),
  status: Joi.string().valid('PLANNING', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'ARCHIVED'),
  progress: Joi.number().min(0).max(100),
  technologies: Joi.array().items(Joi.string().trim()),
  color: Joi.string().trim(),
  manualProgress: Joi.boolean(),
  webhookSecret: Joi.string().trim().allow('', null),
});

export const createFeatureSchema = Joi.object({
  // Accept both `name` and `title` — service maps title → name
  name: Joi.string().trim().min(1).max(255),
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  status: Joi.string().valid('TODO', 'IN_PROGRESS', 'COMPLETED', 'BLOCKED').default('TODO'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL').default('MEDIUM'),
  assignedTaskId: Joi.string().uuid().allow(null),
  githubIssueNumber: Joi.number().integer().positive().allow(null),
  githubUrl: Joi.string().uri().allow('', null),
  order: Joi.number(),
}).or('name', 'title').messages({
  'object.missing': 'Feature name or title is required',
});

export const updateFeatureSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255),
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  status: Joi.string().valid('TODO', 'IN_PROGRESS', 'COMPLETED', 'BLOCKED'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'),
  assignedTaskId: Joi.string().uuid().allow(null),
  githubIssueNumber: Joi.number().integer().positive().allow(null),
  githubUrl: Joi.string().uri().allow('', null),
  order: Joi.number(),
});

export const createBugSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Bug title is required',
    'any.required': 'Bug title is required',
  }),
  description: Joi.string().trim().required().messages({
    'string.empty': 'Bug description is required',
    'any.required': 'Bug description is required',
  }),
  stepsToReproduce: Joi.string().trim().allow('', null),
  severity: Joi.string().valid('CRITICAL', 'MAJOR', 'MINOR').default('MAJOR'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL').default('MEDIUM'),
  status: Joi.string().valid('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED').default('OPEN'),
  githubIssueNumber: Joi.number().integer().positive().allow(null),
  githubUrl: Joi.string().uri().allow('', null),
  order: Joi.number(),
});

export const updateBugSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim(),
  stepsToReproduce: Joi.string().trim().allow('', null),
  severity: Joi.string().valid('CRITICAL', 'MAJOR', 'MINOR'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'),
  status: Joi.string().valid('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'),
  resolutionNotes: Joi.string().trim().allow('', null),
  githubIssueNumber: Joi.number().integer().positive().allow(null),
  githubUrl: Joi.string().uri().allow('', null),
  order: Joi.number(),
});

export const moveBoardItemSchema = Joi.object({
  entityType: Joi.string().valid('TASK', 'FEATURE', 'BUG').required(),
  entityId: Joi.string().uuid().required(),
  targetStatus: Joi.string().valid('TODO', 'IN_PROGRESS', 'BLOCKED', 'COMPLETED').required(),
  prevOrder: Joi.number().allow(null),
  nextOrder: Joi.number().allow(null),
});

export const uuidParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

export const projectFeatureParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
  featureId: Joi.string().uuid().required(),
});

export const projectBugParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
  bugId: Joi.string().uuid().required(),
});
