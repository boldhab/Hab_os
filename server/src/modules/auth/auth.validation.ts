import Joi from 'joi';

export const loginSchema = Joi.object({
  email: Joi.string().email().max(255).required().messages({
    'string.email': 'Please provide a valid email address',
    'string.empty': 'Email is required',
    'any.required': 'Email is required',
  }),
  password: Joi.string().min(6).max(128).required().messages({
    'string.min': 'Password must be at least 6 characters long',
    'string.max': 'Password cannot exceed 128 characters',
    'string.empty': 'Password is required',
    'any.required': 'Password is required',
  }),
});

export const registerSchema = Joi.object({
  email: Joi.string().email().max(255).required().messages({
    'string.email': 'Please provide a valid email address',
    'string.empty': 'Email is required',
    'any.required': 'Email is required',
  }),
  password: Joi.string().min(6).max(128).required().messages({
    'string.min': 'Password must be at least 6 characters long',
    'string.max': 'Password cannot exceed 128 characters',
    'string.empty': 'Password is required',
    'any.required': 'Password is required',
  }),
  name: Joi.string().max(100).allow('', null).optional().messages({
    'string.max': 'Name cannot exceed 100 characters',
  }),
});

export const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required().messages({
    'string.empty': 'Refresh token is required',
    'any.required': 'Refresh token is required',
  }),
});

export const updateProfileSchema = Joi.object({
  name: Joi.string().max(100).allow('', null).optional(),
  avatarUrl: Joi.string().uri().allow('', null).optional().messages({
    'string.uri': 'Avatar URL must be a valid URL',
  }),
  timezone: Joi.string().max(50).optional(),
  dateFormat: Joi.string().max(20).optional(),
});

export const updatePreferencesSchema = Joi.object({
  lifeScoreWeights: Joi.object().optional(),
  dailyCodingTargetMins: Joi.number().integer().min(0).max(1440).optional(),
  dailyStudyTargetMins: Joi.number().integer().min(0).max(1440).optional(),
  weeklyGymTarget: Joi.number().integer().min(0).max(14).optional(),
});
