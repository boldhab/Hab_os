import { Router, Request, Response } from 'express';
import * as tasksController from './tasks.controller';
import tasksService from './tasks.service';
import { authenticate, AuthRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
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

router.get(
  '/matrix',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const matrix = await tasksService.getEisenhowerMatrix(authReq.user!.id);
    return ApiResponse.success(res, matrix, 'Eisenhower matrix retrieved');
  })
);

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
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const subtask = await tasksService.createSubtask(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, subtask, 'Subtask created', 201);
  })
);

router.post(
  '/:id/dependencies',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const { blockingTaskId } = req.body;
    const dependency = await tasksService.addDependency(authReq.user!.id, req.params.id, blockingTaskId);
    return ApiResponse.success(res, dependency, 'Task dependency added', 201);
  })
);

router.delete(
  '/:id/dependencies/:blockingId',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await tasksService.removeDependency(authReq.user!.id, req.params.id, req.params.blockingId);
    return ApiResponse.success(res, null, 'Task dependency removed');
  })
);

export default router;
