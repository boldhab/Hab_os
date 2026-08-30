import { Router } from 'express';
import * as gymController from './gym.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createWorkoutSchema,
  updateWorkoutSchema,
  createExerciseSchema,
  addExerciseToWorkoutSchema,
  recordSetSchema,
  recordBodyMetricSchema,
  uuidParamSchema,
  workoutExerciseParamSchema,
} from './gym.validation';

const router = Router();

// All gym routes require authentication
router.use(authenticate);

// --- Analytics (UC-101) ---
router.get('/analytics', gymController.getGymAnalytics);

// --- Exercises (UC-92, UC-98) ---
router.post('/exercises', validate(createExerciseSchema), gymController.createExercise);
router.get('/exercises', gymController.getExercises);

// --- Body Metrics (UC-99, UC-100) ---
router.post('/metrics', validate(recordBodyMetricSchema), gymController.recordBodyMetric);
router.get('/metrics', gymController.getBodyMetrics);

// --- Workouts (UC-91 to UC-97) ---
router.post('/', validate(createWorkoutSchema), gymController.createWorkout);
router.get('/', gymController.getWorkouts);
router.get('/:id', validate(uuidParamSchema, 'params'), gymController.getWorkoutById);
router.put(
  '/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateWorkoutSchema),
  gymController.updateWorkout
);
router.delete('/:id', validate(uuidParamSchema, 'params'), gymController.deleteWorkout);

// --- Exercises in Workout & Sets (UC-93 to UC-96) ---
router.post(
  '/:id/exercises',
  validate(uuidParamSchema, 'params'),
  validate(addExerciseToWorkoutSchema),
  gymController.addExerciseToWorkout
);
router.post(
  '/exercises/:workoutExerciseId/sets',
  validate(recordSetSchema),
  gymController.recordSet
);

export default router;
