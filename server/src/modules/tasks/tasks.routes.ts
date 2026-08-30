import { Router } from 'express';
import * as tasksController from './tasks.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createTaskSchema,
  updateTaskSchema,
  getTasksQuerySchema,
  taskIdParamSchema,
} from './tasks.validation';

const router = Router();

// All task routes require authentication
router.use(authenticate);

router.post('/', validate(createTaskSchema), tasksController.createTask);
router.get('/', validate(getTasksQuerySchema, 'query'), tasksController.getTasks);
router.get('/stats', tasksController.getTaskStats);
router.get('/:id', validate(taskIdParamSchema, 'params'), tasksController.getTaskById);
router.put(
  '/:id',
  validate(taskIdParamSchema, 'params'),
  validate(updateTaskSchema),
  tasksController.updateTask
);
router.patch(
  '/:id/complete',
  validate(taskIdParamSchema, 'params'),
  tasksController.toggleTaskComplete
);
router.delete(
  '/:id',
  validate(taskIdParamSchema, 'params'),
  tasksController.deleteTask
);

export default router;
