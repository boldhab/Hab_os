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

export default router;
