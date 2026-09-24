import Joi from 'joi';

export const syncGitHubSchema = Joi.object({
  username: Joi.string().trim().min(1).max(100).required().messages({
    'string.empty': 'GitHub username is required',
    'any.required': 'GitHub username is required',
  }),
  accessToken: Joi.string().trim().allow('', null),
  publicReposCount: Joi.number().integer().min(0).default(0),
  totalCommits: Joi.number().integer().min(0).default(0),
  currentStreak: Joi.number().integer().min(0).default(0),
  longestStreak: Joi.number().integer().min(0).default(0),
});

export const importRepoSchema = Joi.object({
  repoName: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Repository name is required',
    'any.required': 'Repository name is required',
  }),
  owner: Joi.string().trim().min(1).max(100).required().messages({
    'string.empty': 'Repository owner is required',
    'any.required': 'Repository owner is required',
  }),
  repoUrl: Joi.string().uri().required().messages({
    'string.uri': 'Valid GitHub URL is required',
    'any.required': 'Repository URL is required',
  }),
  description: Joi.string().trim().allow('', null),
  language: Joi.string().trim().allow('', null),
  technologies: Joi.array().items(Joi.string().trim()),
  color: Joi.string().trim().default('#10B981'),
});

export const analyzeRepoParamSchema = Joi.object({
  owner: Joi.string().trim().required(),
  repo: Joi.string().trim().required(),
});

export const syncLeetCodeSchema = Joi.object({
  username: Joi.string().trim().min(1).max(100).required().messages({
    'string.empty': 'LeetCode username is required',
    'any.required': 'LeetCode username is required',
  }),
  easySolved: Joi.number().integer().min(0).default(0),
  mediumSolved: Joi.number().integer().min(0).default(0),
  hardSolved: Joi.number().integer().min(0).default(0),
  currentStreak: Joi.number().integer().min(0).default(0),
  longestStreak: Joi.number().integer().min(0).default(0),
});
