import { Router, Request, Response } from 'express';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';
import tasksService from './tasks.service';

const router = Router();

router.use(authenticate);

/**
 * GET /api/v1/tasks/stats
 */
router.get(
  '/stats',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const stats = await tasksService.getTaskStats(authReq.user!.id);
    return ApiResponse.success(res, stats, 'Task statistics retrieved');
  })
);

/**
 * GET /api/v1/tasks/matrix
 * Categorizes active tasks into the 4 Eisenhower Matrix quadrants
 */
router.get(
  '/matrix',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const matrix = await tasksService.getEisenhowerMatrix(authReq.user!.id);
    return ApiResponse.success(res, matrix, 'Eisenhower matrix retrieved');
  })
);

/**
 * GET /api/v1/tasks
 * Supports filtering (?status=, ?priority=, ?projectId=, ?search=, ?parentTaskId=)
 * Supports pagination (?page=1&limit=20)
 */
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const result = await tasksService.getTasks(authReq.user!.id, req.query);
    return ApiResponse.success(res, result, 'Tasks retrieved');
  })
);

/**
 * POST /api/v1/tasks
 */
router.post(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const task = await tasksService.createTask(authReq.user!.id, req.body);
    return ApiResponse.success(res, task, 'Task created', 201);
  })
);

/**
 * POST /api/v1/tasks/:id/subtasks
 * Creates a subtask linked to a parent task
 */
router.post(
  '/:id/subtasks',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const subtask = await tasksService.createSubtask(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, subtask, 'Subtask created', 201);
  })
);

/**
 * POST /api/v1/tasks/:id/dependencies
 * Adds a blocker prerequisite: task :id is blocked by req.body.blockingTaskId
 */
router.post(
  '/:id/dependencies',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const { blockingTaskId } = req.body;
    const dependency = await tasksService.addDependency(authReq.user!.id, req.params.id, blockingTaskId);
    return ApiResponse.success(res, dependency, 'Task dependency added', 201);
  })
);

/**
 * DELETE /api/v1/tasks/:id/dependencies/:blockingId
 * Removes a blocker prerequisite
 */
router.delete(
  '/:id/dependencies/:blockingId',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await tasksService.removeDependency(authReq.user!.id, req.params.id, req.params.blockingId);
    return ApiResponse.success(res, null, 'Task dependency removed');
  })
);

/**
 * PATCH /api/v1/tasks/:id/complete
 * Dedicated endpoint to toggle task completion
 */
router.patch(
  '/:id/complete',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const task = await tasksService.toggleComplete(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, task, 'Task completion toggled');
  })
);

/**
 * PATCH /api/v1/tasks/:id
 */
router.patch(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const task = await tasksService.updateTask(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, task, 'Task updated');
  })
);

/**
 * DELETE /api/v1/tasks/:id
 */
router.delete(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await tasksService.deleteTask(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, null, 'Task deleted');
  })
);

export default router;
