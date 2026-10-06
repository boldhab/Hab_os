import { Request, Response } from 'express';
import tasksService from './tasks.service';
import calendarSyncService from './calendarSync.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * @desc    Create a new task
 * @route   POST /api/v1/tasks
 * @access  Private
 */
export const createTask = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const task = await tasksService.createTask(authReq.user!.id, req.body);
  return ApiResponse.success(res, task, 'Task created successfully', 201);
});

/**
 * @desc    Get all tasks with filtering, search, and pagination
 * @route   GET /api/v1/tasks
 * @access  Private
 */
export const getTasks = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await tasksService.getTasks(authReq.user!.id, req.query);
  return ApiResponse.success(res, result, 'Tasks retrieved successfully');
});

/**
 * @desc    Get task statistics for dashboard
 * @route   GET /api/v1/tasks/stats
 * @access  Private
 */
export const getTaskStats = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const stats = await tasksService.getTaskStats(authReq.user!.id);
  return ApiResponse.success(res, stats, 'Task statistics retrieved successfully');
});

/**
 * @desc    Get a single task by ID
 * @route   GET /api/v1/tasks/:id
 * @access  Private
 */
export const getTaskById = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const task = await tasksService.getTaskById(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, task, 'Task retrieved successfully');
});

/**
 * @desc    Update a task
 * @route   PUT /api/v1/tasks/:id
 * @access  Private
 */
export const updateTask = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const task = await tasksService.updateTask(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, task, 'Task updated successfully');
});

/**
 * @desc    Toggle task completion status
 * @route   PATCH /api/v1/tasks/:id/complete
 * @access  Private
 */
export const toggleTaskComplete = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const task = await tasksService.toggleTaskComplete(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, task, 'Task completion status updated');
});

/**
 * @desc    Delete a task
 * @route   DELETE /api/v1/tasks/:id
 * @access  Private
 */
export const deleteTask = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await tasksService.deleteTask(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Task deleted successfully');
});

/**
 * @desc    Get daily workload capacity
 * @route   GET /api/v1/tasks/workload
 * @access  Private
 */
export const getDailyWorkload = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const workload = await tasksService.getDailyWorkload(authReq.user!.id);
  return ApiResponse.success(res, workload, 'Daily workload retrieved successfully');
});

/**
 * @desc    Get Eisenhower matrix categorization
 * @route   GET /api/v1/tasks/matrix
 * @access  Private
 */
export const getEisenhowerMatrix = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const matrix = await tasksService.getEisenhowerMatrix(authReq.user!.id);
  return ApiResponse.success(res, matrix, 'Eisenhower matrix retrieved');
});

/**
 * @desc    Create a subtask under a parent task
 * @route   POST /api/v1/tasks/:id/subtasks
 * @access  Private
 */
export const createSubtask = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const subtask = await tasksService.createSubtask(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, subtask, 'Subtask created', 201);
});

/**
 * @desc    Add a blocking dependency to a task
 * @route   POST /api/v1/tasks/:id/dependencies
 * @access  Private
 */
export const addDependency = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { blockingTaskId } = req.body;
  const dependency = await tasksService.addDependency(authReq.user!.id, req.params.id, blockingTaskId);
  return ApiResponse.success(res, dependency, 'Task dependency added', 201);
});

/**
 * @desc    Remove a task dependency
 * @route   DELETE /api/v1/tasks/:id/dependencies/:blockingId
 * @access  Private
 */
export const removeDependency = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  await tasksService.removeDependency(authReq.user!.id, req.params.id, req.params.blockingId);
  return ApiResponse.success(res, null, 'Task dependency removed');
});

/**
 * @desc    Reorder task with fractional positioning
 * @route   POST /api/v1/tasks/reorder
 * @access  Private
 */
export const reorderTask = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await tasksService.reorderTask(authReq.user!.id, req.body);
  return ApiResponse.success(res, result, 'Task reordered successfully');
});

/**
 * @desc    Sync single task to Google Calendar
 * @route   POST /api/v1/tasks/:id/sync-calendar
 * @access  Private
 */
export const syncTaskToCalendar = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await calendarSyncService.syncTaskToCalendar(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Task synchronized to Google Calendar');
});

/**
 * @desc    Trigger full two-way Google Calendar synchronization
 * @route   POST /api/v1/tasks/sync-calendar
 * @access  Private
 */
export const syncAllTasksCalendar = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await calendarSyncService.syncAllTasks(authReq.user!.id);
  return ApiResponse.success(res, result, 'Google Calendar synchronization complete');
});

export default {
  createTask,
  getTasks,
  getTaskStats,
  getTaskById,
  updateTask,
  toggleTaskComplete,
  deleteTask,
  getDailyWorkload,
  getEisenhowerMatrix,
  createSubtask,
  addDependency,
  removeDependency,
  reorderTask,
  syncTaskToCalendar,
  syncAllTasksCalendar,
};

