import Joi from 'joi';

export const createWorkoutSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Workout name is required',
    'any.required': 'Workout name is required',
  }),
  date: Joi.date().iso().default(() => new Date().toISOString()),
  startTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  durationMinutes: Joi.number().integer().min(1).max(360).default(60),
  notes: Joi.string().trim().allow('', null),
  isCompleted: Joi.boolean().default(true),
});

export const updateWorkoutSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255),
  date: Joi.date().iso(),
  startTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  durationMinutes: Joi.number().integer().min(1).max(360),
  notes: Joi.string().trim().allow('', null),
  isCompleted: Joi.boolean(),
});

export const createExerciseSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Exercise name is required',
    'any.required': 'Exercise name is required',
  }),
  category: Joi.string()
    .valid('CHEST', 'BACK', 'LEGS', 'SHOULDERS', 'ARMS', 'CORE', 'CARDIO')
    .default('CHEST'),
  notes: Joi.string().trim().allow('', null),
});

export const addExerciseToWorkoutSchema = Joi.object({
  exerciseId: Joi.string().uuid().required(),
  order: Joi.number().integer().min(1).default(1),
  sets: Joi.array()
    .items(
      Joi.object({
        setNumber: Joi.number().integer().min(1).required(),
        weightKg: Joi.number().min(0).required(),
        repetitions: Joi.number().integer().min(0).required(),
        notes: Joi.string().trim().allow('', null),
      })
    )
    .default([]),
});

export const recordSetSchema = Joi.object({
  setNumber: Joi.number().integer().min(1).required(),
  weightKg: Joi.number().min(0).required(),
  repetitions: Joi.number().integer().min(0).required(),
  notes: Joi.string().trim().allow('', null),
});

export const recordBodyMetricSchema = Joi.object({
  date: Joi.date().iso().default(() => new Date().toISOString()),
  weightKg: Joi.number().min(20).max(300).required().messages({
    'any.required': 'Body weight in kg is required',
  }),
  chestCm: Joi.number().min(0).allow(null),
  waistCm: Joi.number().min(0).allow(null),
  armsCm: Joi.number().min(0).allow(null),
  legsCm: Joi.number().min(0).allow(null),
  notes: Joi.string().trim().allow('', null),
});

export const uuidParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

export const workoutExerciseParamSchema = Joi.object({
  workoutId: Joi.string().uuid().required(),
  workoutExerciseId: Joi.string().uuid().required(),
});
