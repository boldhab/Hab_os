import { Router } from 'express';
import * as goalsController from './goals.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createGoalSchema,
  updateGoalSchema,
  createMilestoneSchema,
  updateMilestoneSchema,
  createCheckInSchema,
  contributeGoalSchema,
  uuidParamSchema,
  goalMilestoneParamSchema,
} from './goals.validation';

const router = Router();

// All goals routes require authentication
router.use(authenticate);

// --- Roadmap & Health (Special Views) ---
router.get('/roadmap', goalsController.getRoadmap);
router.get('/health', goalsController.getGoalsHealth);

// --- Goals ---
router.post('/', validate(createGoalSchema), goalsController.createGoal);
router.get('/', goalsController.getGoals);
router.get('/:id', validate(uuidParamSchema, 'params'), goalsController.getGoalById);
router.get('/:id/tree', validate(uuidParamSchema, 'params'), goalsController.getGoalTree);
router.put(
  '/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateGoalSchema),
  goalsController.updateGoal
);
router.delete('/:id', validate(uuidParamSchema, 'params'), goalsController.deleteGoal);

// --- Financial Contribution ---
router.post(
  '/:id/contribute',
  validate(uuidParamSchema, 'params'),
  validate(contributeGoalSchema),
  goalsController.contributeFinancialGoal
);

// --- Milestones ---
router.get(
  '/:goalId/milestones',
  goalsController.getMilestones
);
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

// --- Check-Ins ---
router.get(
  '/:id/checkins',
  validate(uuidParamSchema, 'params'),
  goalsController.getGoalCheckIns
);
router.post(
  '/:id/checkins',
  validate(uuidParamSchema, 'params'),
  validate(createCheckInSchema),
  goalsController.recordCheckIn
);

export default router;
