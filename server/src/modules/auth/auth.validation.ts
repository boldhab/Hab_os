import Joi from 'joi';

export const registerSchema = Joi.object({
  name: Joi.string().trim().max(100).allow('', null),
  email: Joi.string().trim().email().required().messages({
    'string.email': 'Please provide a valid email address',
    'any.required': 'Email address is required',
  }),
  password: Joi.string().min(8).required().messages({
    'string.min': 'Password must be at least 8 characters long',
    'any.required': 'Password is required',
  }),
  timezone: Joi.string().trim().default('UTC'),
  dateFormat: Joi.string().trim().default('YYYY-MM-DD'),
});

export const loginSchema = Joi.object({
  email: Joi.string().trim().email().required().messages({
    'string.email': 'Please provide a valid email address',
    'any.required': 'Email is required',
  }),
  password: Joi.string().required().messages({
    'any.required': 'Password is required',
  }),
});

export const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required().messages({
    'any.required': 'Refresh token is required',
  }),
});

export const updateProfileSchema = Joi.object({
  name: Joi.string().trim().max(100),
  avatarUrl: Joi.string().uri().allow('', null),
  timezone: Joi.string().trim(),
  dateFormat: Joi.string().trim(),
  currentPassword: Joi.string().when('newPassword', {
    is: Joi.exist(),
    then: Joi.required().messages({
      'any.required': 'Current password is required to set a new password',
    }),
  }),
  newPassword: Joi.string().min(8).messages({
    'string.min': 'New password must be at least 8 characters long',
  }),
});

export const updatePreferencesSchema = Joi.object({
  dashboardModules: Joi.array().items(Joi.string()),
  dailyCodingTargetMins: Joi.number().integer().min(0).max(1440),
  dailyStudyTargetMins: Joi.number().integer().min(0).max(1440),
  dailyReadingTargetMins: Joi.number().integer().min(0).max(1440),
  weeklyGymTarget: Joi.number().integer().min(0).max(14),
  quietHoursStart: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  quietHoursEnd: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  lifeScoreWeights: Joi.object(),
});
