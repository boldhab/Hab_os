import { Request, Response } from 'express';
import tasksService from './tasks.service';
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

export default {
  createTask,
  getTasks,
  getTaskStats,
  getTaskById,
  updateTask,
  toggleTaskComplete,
  deleteTask,
};
