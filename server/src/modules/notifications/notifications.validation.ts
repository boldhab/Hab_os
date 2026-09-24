import Joi from 'joi';

export const createNotificationSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required(),
  message: Joi.string().trim().min(1).required(),
  type: Joi.string()
    .valid(
      'TASK_REMINDER',
      'EXAM_REMINDER',
      'GOAL_REMINDER',
      'HABIT_REMINDER',
      'WORKOUT_REMINDER',
      'BUDGET_ALERT',
      'STREAK_ALERT',
      'SCHEDULE_EVENT',
      'GENERAL'
    )
    .default('GENERAL'),
  scheduledFor: Joi.date().iso().allow(null),
  metadata: Joi.object().allow(null),
});

export const notificationIdParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});
