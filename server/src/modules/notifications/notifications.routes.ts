import { Router } from 'express';
import * as notificationsController from './notifications.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createNotificationSchema,
  notificationIdParamSchema,
} from './notifications.validation';

const router = Router();

// All notification routes require authentication
router.use(authenticate);

router.get('/', notificationsController.getNotifications);
router.get('/unread-count', notificationsController.getUnreadCount);
router.post('/generate-alerts', notificationsController.generateAlerts);
router.patch('/read-all', notificationsController.markAllAsRead);
router.delete('/', notificationsController.clearAllNotifications);

router.post('/', validate(createNotificationSchema), notificationsController.createNotification);
router.patch(
  '/:id/read',
  validate(notificationIdParamSchema, 'params'),
  notificationsController.markAsRead
);
router.delete(
  '/:id',
  validate(notificationIdParamSchema, 'params'),
  notificationsController.deleteNotification
);

export default router;
