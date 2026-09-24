import { Router } from 'express';
import * as scheduleController from './schedule.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createEventSchema,
  updateEventSchema,
  getScheduleQuerySchema,
  eventIdParamSchema,
} from './schedule.validation';

const router = Router();

// All schedule routes require authentication
router.use(authenticate);

router.post('/', validate(createEventSchema), scheduleController.createEvent);
router.get('/daily', validate(getScheduleQuerySchema, 'query'), scheduleController.getDailySchedule);
router.get('/weekly', validate(getScheduleQuerySchema, 'query'), scheduleController.getWeeklySchedule);
router.get('/:id', validate(eventIdParamSchema, 'params'), scheduleController.getEventById);
router.put(
  '/:id',
  validate(eventIdParamSchema, 'params'),
  validate(updateEventSchema),
  scheduleController.updateEvent
);
router.delete(
  '/:id',
  validate(eventIdParamSchema, 'params'),
  scheduleController.deleteEvent
);

export default router;
