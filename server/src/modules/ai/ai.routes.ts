import { Router } from 'express';
import * as aiController from './ai.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { askAiSchema } from './ai.validation';

const router = Router();

// All AI assistant routes require authentication
router.use(authenticate);

router.post('/ask', validate(askAiSchema), aiController.askAssistant);
router.get('/briefing', aiController.getDailyBriefing);
router.get('/recommendation', aiController.getRecommendation);

// Module 19: AI Insights Engine & Neglected Areas (UC-136 to UC-143)
router.get('/neglected-areas', aiController.getNeglectedAreas);
router.get('/recommend-tasks', aiController.getRecommendedTasks);
router.get('/plan', aiController.getPersonalizedPlan);
router.post('/plan', aiController.getPersonalizedPlan);
router.get('/insights', aiController.getDomainInsights);
router.get('/insights/:domain', aiController.getDomainInsights);

export default router;

