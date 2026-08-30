import { Request, Response } from 'express';
import habitsService from './habits.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * @desc    Create a new habit
 * @route   POST /api/v1/habits
 * @access  Private
 */
export const createHabit = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const habit = await habitsService.createHabit(authReq.user!.id, req.body);
  return ApiResponse.success(res, habit, 'Habit created successfully', 201);
});

/**
 * @desc    Get all habits with today's completion status
 * @route   GET /api/v1/habits
 * @access  Private
 */
export const getHabits = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const includeInactive = req.query.includeInactive === 'true';
  const page = req.query.page ? parseInt(req.query.page as string, 10) : undefined;
  const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : undefined;
  const habits = await habitsService.getHabits(authReq.user!.id, includeInactive, page, limit);
  return ApiResponse.success(res, habits, 'Habits retrieved successfully');
});

/**
 * @desc    Get summary metrics for dashboard
 * @route   GET /api/v1/habits/summary
 * @access  Private
 */
export const getHabitsSummary = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const summary = await habitsService.getHabitsSummary(authReq.user!.id);
  return ApiResponse.success(res, summary, 'Habits summary retrieved successfully');
});

/**
 * @desc    Get single habit with recent logs
 * @route   GET /api/v1/habits/:id
 * @access  Private
 */
export const getHabitById = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const habit = await habitsService.getHabitById(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, habit, 'Habit retrieved successfully');
});

/**
 * @desc    Update a habit
 * @route   PUT /api/v1/habits/:id
 * @access  Private
 */
export const updateHabit = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const habit = await habitsService.updateHabit(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, habit, 'Habit updated successfully');
});

/**
 * @desc    Log completion for a habit & recalculate streaks
 * @route   POST /api/v1/habits/:id/log
 * @access  Private
 */
export const logHabitCompletion = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await habitsService.logHabitCompletion(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, result, 'Habit logged successfully');
});

/**
 * @desc    Get habit history & heatmap data
 * @route   GET /api/v1/habits/:id/history
 * @access  Private
 */
export const getHabitHistory = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { startDate, endDate } = req.query;
  const history = await habitsService.getHabitHistory(
    authReq.user!.id,
    req.params.id,
    startDate as string,
    endDate as string
  );
  return ApiResponse.success(res, history, 'Habit history retrieved successfully');
});

/**
 * @desc    Delete a habit
 * @route   DELETE /api/v1/habits/:id
 * @access  Private
 */
export const deleteHabit = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await habitsService.deleteHabit(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Habit deleted successfully');
});

export default {
  createHabit,
  getHabits,
  getHabitsSummary,
  getHabitById,
  updateHabit,
  logHabitCompletion,
  getHabitHistory,
  deleteHabit,
};
