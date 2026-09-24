import { Router } from 'express';
import * as goalsController from './goals.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createGoalSchema,
  updateGoalSchema,
  createMilestoneSchema,
  updateMilestoneSchema,
  uuidParamSchema,
  goalMilestoneParamSchema,
} from './goals.validation';

const router = Router();

// All goals routes require authentication
router.use(authenticate);

// --- Roadmap View (UC-119, UC-120) ---
router.get('/roadmap', goalsController.getRoadmap);

// --- Goals (UC-112 to UC-114) ---
router.post('/', validate(createGoalSchema), goalsController.createGoal);
router.get('/', goalsController.getGoals);
router.get('/:id', validate(uuidParamSchema, 'params'), goalsController.getGoalById);
router.put(
  '/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateGoalSchema),
  goalsController.updateGoal
);
router.delete('/:id', validate(uuidParamSchema, 'params'), goalsController.deleteGoal);

// --- Milestones (UC-115, UC-116) ---
router.post(
  '/:goalId/milestones',
  validate(createMilestoneSchema),
  goalsController.createMilestone
);
router.put(
  '/:goalId/milestones/:milestoneId',
  validate(goalMilestoneParamSchema, 'params'),
  validate(updateMilestoneSchema),
  goalsController.updateMilestone
);
router.delete(
  '/:goalId/milestones/:milestoneId',
  validate(goalMilestoneParamSchema, 'params'),
  goalsController.deleteMilestone
);

export default router;
