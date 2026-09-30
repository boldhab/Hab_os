import { Router } from 'express';
import * as habitsController from './habits.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createHabitSchema,
  updateHabitSchema,
  logHabitSchema,
  habitIdParamSchema,
  createRoutineSchema,
  updateRoutineSchema,
  routineIdParamSchema,
} from './habits.validation';

const router = Router();

// All habit routes require authentication
router.use(authenticate);

// --- Static and collection endpoints (defined before :id) ---
router.post('/', validate(createHabitSchema), habitsController.createHabit);
router.get('/', habitsController.getHabits);
router.get('/summary', habitsController.getHabitsSummary);
router.get('/correlations', habitsController.getHabitCorrelations);

// --- Routines (Defined before :id) ---
router.get('/routines', habitsController.getRoutines);
router.post('/routines', validate(createRoutineSchema), habitsController.createRoutine);
router.get('/routines/:id', validate(routineIdParamSchema, 'params'), habitsController.getRoutineById);
router.put(
  '/routines/:id',
  validate(routineIdParamSchema, 'params'),
  validate(updateRoutineSchema),
  habitsController.updateRoutine
);
router.delete('/routines/:id', validate(routineIdParamSchema, 'params'), habitsController.deleteRoutine);
router.post('/routines/:id/complete', validate(routineIdParamSchema, 'params'), habitsController.completeRoutine);

// --- Habit Item endpoints (:id) ---
router.get('/:id', validate(habitIdParamSchema, 'params'), habitsController.getHabitById);
router.put(
  '/:id',
  validate(habitIdParamSchema, 'params'),
  validate(updateHabitSchema),
  habitsController.updateHabit
);
router.post(
  '/:id/log',
  validate(habitIdParamSchema, 'params'),
  validate(logHabitSchema),
  habitsController.logHabitCompletion
);
router.get(
  '/:id/history',
  validate(habitIdParamSchema, 'params'),
  habitsController.getHabitHistory
);
router.post(
  '/:id/freeze',
  validate(habitIdParamSchema, 'params'),
  habitsController.refillStreakFreeze
);
router.delete(
  '/:id',
  validate(habitIdParamSchema, 'params'),
  habitsController.deleteHabit
);

export default router;
