import { Router } from 'express';
import * as tasksController from './tasks.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createTaskSchema,
  updateTaskSchema,
  getTasksQuerySchema,
  taskIdParamSchema,
  reorderTaskSchema,
  createSubtaskSchema,
  addDependencySchema,
  dependencyParamsSchema,
} from './tasks.validation';

const router = Router();

// All task routes require authentication
router.use(authenticate);

router.post('/', validate(createTaskSchema), tasksController.createTask);
router.get('/', validate(getTasksQuerySchema, 'query'), tasksController.getTasks);
router.get('/stats', tasksController.getTaskStats);
router.get('/workload', tasksController.getDailyWorkload);
router.get('/matrix', tasksController.getEisenhowerMatrix);
router.post('/reorder', validate(reorderTaskSchema), tasksController.reorderTask);
router.post('/sync-calendar', tasksController.syncAllTasksCalendar);

router.get('/:id', validate(taskIdParamSchema, 'params'), tasksController.getTaskById);


router.put(
  '/:id',
  validate(taskIdParamSchema, 'params'),
  validate(updateTaskSchema),
  tasksController.updateTask
);

router.patch(
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

router.post(
  '/:id/subtasks',
  validate(taskIdParamSchema, 'params'),
  validate(createSubtaskSchema),
  tasksController.createSubtask
);

router.post(
  '/:id/dependencies',
  validate(taskIdParamSchema, 'params'),
  validate(addDependencySchema),
  tasksController.addDependency
);

router.delete(
  '/:id/dependencies/:blockingId',
  validate(dependencyParamsSchema, 'params'),
  tasksController.removeDependency
);

router.post(
  '/:id/sync-calendar',
  validate(taskIdParamSchema, 'params'),
  tasksController.syncTaskToCalendar
);

export default router;

