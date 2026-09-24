import { Router } from 'express';
import * as analyticsController from './analytics.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createTimeEntrySchema,
  timeEntryQuerySchema,
  uuidParamSchema,
} from './analytics.validation';

const router = Router();

// All analytics routes require authentication
router.use(authenticate);

// --- Cross-Domain Retrospective (UC-139 to UC-146) ---
router.get('/retrospective', analyticsController.getRetrospective);

// --- Time Entries (UC-134 to UC-138) ---
router.post('/time', validate(createTimeEntrySchema), analyticsController.createTimeEntry);
router.get('/time', validate(timeEntryQuerySchema, 'query'), analyticsController.getTimeEntries);
router.delete('/time/:id', validate(uuidParamSchema, 'params'), analyticsController.deleteTimeEntry);

export default router;
