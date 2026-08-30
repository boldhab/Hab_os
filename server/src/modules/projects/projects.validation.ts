import Joi from 'joi';

export const createProjectSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Project title is required',
    'any.required': 'Project title is required',
  }),
  description: Joi.string().trim().allow('', null),
  repoUrl: Joi.string().uri().allow('', null),
  status: Joi.string().valid('PLANNING', 'IN_PROGRESS', 'COMPLETED', 'ARCHIVED').default('PLANNING'),
  progress: Joi.number().min(0).max(100).default(0.0),
  technologies: Joi.array().items(Joi.string().trim()).default([]),
  color: Joi.string().trim().default('#10B981'),
});

export const updateProjectSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  repoUrl: Joi.string().uri().allow('', null),
  status: Joi.string().valid('PLANNING', 'IN_PROGRESS', 'COMPLETED', 'ARCHIVED'),
  progress: Joi.number().min(0).max(100),
  technologies: Joi.array().items(Joi.string().trim()),
  color: Joi.string().trim(),
});

export const createFeatureSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Feature name is required',
    'any.required': 'Feature name is required',
  }),
  description: Joi.string().trim().allow('', null),
  status: Joi.string().valid('TODO', 'IN_PROGRESS', 'COMPLETED', 'BLOCKED').default('TODO'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL').default('MEDIUM'),
  assignedTaskId: Joi.string().uuid().allow(null),
});

export const updateFeatureSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  status: Joi.string().valid('TODO', 'IN_PROGRESS', 'COMPLETED', 'BLOCKED'),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'),
  assignedTaskId: Joi.string().uuid().allow(null),
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
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL').default('MEDIUM'),
  status: Joi.string().valid('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED').default('OPEN'),
});

export const updateBugSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim(),
  stepsToReproduce: Joi.string().trim().allow('', null),
  priority: Joi.string().valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'),
  status: Joi.string().valid('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'),
  resolutionNotes: Joi.string().trim().allow('', null),
});

export const uuidParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

export const projectFeatureParamSchema = Joi.object({
  projectId: Joi.string().uuid().required(),
  featureId: Joi.string().uuid().required(),
});

export const projectBugParamSchema = Joi.object({
  projectId: Joi.string().uuid().required(),
  bugId: Joi.string().uuid().required(),
});
