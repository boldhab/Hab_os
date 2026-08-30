import { Router } from 'express';
import * as focusController from './focus.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  startFocusSchema,
  endFocusSchema,
  logCompletedFocusSchema,
  getFocusQuerySchema,
  focusIdParamSchema,
} from './focus.validation';

const router = Router();

// All focus routes require authentication
router.use(authenticate);

router.post('/start', validate(startFocusSchema), focusController.startSession);
router.post(
  '/:id/end',
  validate(focusIdParamSchema, 'params'),
  validate(endFocusSchema),
  focusController.endSession
);
router.post('/log', validate(logCompletedFocusSchema), focusController.logCompletedSession);
router.get('/', validate(getFocusQuerySchema, 'query'), focusController.getFocusSessions);
router.get('/stats', focusController.getFocusStats);
router.delete('/:id', validate(focusIdParamSchema, 'params'), focusController.deleteSession);

export default router;
