import Joi from 'joi';

export const createEventSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Event title is required',
    'any.required': 'Event title is required',
  }),
  description: Joi.string().trim().allow('', null),
  location: Joi.string().trim().allow('', null),
  color: Joi.string().trim().default('#6366F1'),
  startTime: Joi.date().iso().required().messages({
    'any.required': 'Start time is required',
  }),
  endTime: Joi.date().iso().greater(Joi.ref('startTime')).required().messages({
    'date.greater': 'End time must be strictly after start time',
    'any.required': 'End time is required',
  }),
  isRecurring: Joi.boolean().default(false),
  recurrenceRule: Joi.string().trim().allow('', null),
});

export const updateEventSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  location: Joi.string().trim().allow('', null),
  color: Joi.string().trim(),
  startTime: Joi.date().iso(),
  endTime: Joi.date().iso(),
  isRecurring: Joi.boolean(),
  recurrenceRule: Joi.string().trim().allow('', null),
});

export const getScheduleQuerySchema = Joi.object({
  date: Joi.date().iso(), // Target single day for timeline (UC-21)
  startDate: Joi.date().iso(), // Range start (UC-22)
  endDate: Joi.date().iso(),   // Range end (UC-22)
});

export const eventIdParamSchema = Joi.object({
  id: Joi.string().uuid().required().messages({
    'string.guid': 'Invalid event ID format',
    'any.required': 'Event ID is required',
  }),
});
