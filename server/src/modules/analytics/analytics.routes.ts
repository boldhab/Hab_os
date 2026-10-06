import { Router } from 'express';
import * as analyticsController from './analytics.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createTimeEntrySchema,
  updateTimeEntrySchema,
  timeEntryQuerySchema,
  retrospectiveQuerySchema,
  uuidParamSchema,
} from './analytics.validation';

const router = Router();

// All analytics routes require authentication
router.use(authenticate);

// --- Cross-Domain Retrospective & Reporting (UC-139 to UC-154) ---
router.get(
  '/retrospective',
  validate(retrospectiveQuerySchema, 'query'),
  analyticsController.getRetrospective
);
router.get('/export/csv', validate(retrospectiveQuerySchema, 'query'), analyticsController.exportCsv);
router.get('/export/pdf', validate(retrospectiveQuerySchema, 'query'), analyticsController.exportPdf);

// --- Time Tracker Engine (UC-134 to UC-138) ---
router.post('/time', validate(createTimeEntrySchema), analyticsController.createTimeEntry);
router.get('/time', validate(timeEntryQuerySchema, 'query'), analyticsController.getTimeEntries);
router.put(
  '/time/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateTimeEntrySchema),
  analyticsController.updateTimeEntry
);
router.post(
  '/time/:id/stop',
  validate(uuidParamSchema, 'params'),
  analyticsController.stopTimeEntry
);
router.delete('/time/:id', validate(uuidParamSchema, 'params'), analyticsController.deleteTimeEntry);

export default router;
