import { Router } from 'express';
import * as habitsController from './habits.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createHabitSchema,
  updateHabitSchema,
  logHabitSchema,
  habitIdParamSchema,
} from './habits.validation';

const router = Router();

// All habit routes require authentication
router.use(authenticate);

router.post('/', validate(createHabitSchema), habitsController.createHabit);
router.get('/', habitsController.getHabits);
router.get('/summary', habitsController.getHabitsSummary);
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
router.delete(
  '/:id',
  validate(habitIdParamSchema, 'params'),
  habitsController.deleteHabit
);

export default router;
