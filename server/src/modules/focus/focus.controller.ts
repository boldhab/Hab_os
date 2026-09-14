import { Request, Response } from 'express';
import focusService from './focus.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * @desc    Start a new focus session timer
 * @route   POST /api/v1/focus/start
 * @access  Private
 */
export const startSession = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const session = await focusService.startSession(authReq.user!.id, req.body);
  return ApiResponse.success(res, session, 'Focus session started', 201);
});

/**
 * @desc    End active focus session & record duration
 * @route   POST /api/v1/focus/:id/end
 * @access  Private
 */
export const endSession = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const session = await focusService.endSession(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, session, 'Focus session completed');
});

/**
 * @desc    Log completed focus session (e.g. from completed Pomodoro timer)
 * @route   POST /api/v1/focus/log
 * @access  Private
 */
export const logCompletedSession = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const session = await focusService.logCompletedSession(authReq.user!.id, req.body);
  return ApiResponse.success(res, session, 'Focus session recorded', 201);
});

/**
 * @desc    Get focus session history with category filters
 * @route   GET /api/v1/focus
 * @access  Private
 */
export const getFocusSessions = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await focusService.getFocusSessions(authReq.user!.id, req.query);
  return ApiResponse.success(res, result, 'Focus sessions retrieved');
});

/**
 * @desc    Get focus time metrics (Today, Week, Month, Category breakdown)
 * @route   GET /api/v1/focus/stats
 * @access  Private
 */
export const getFocusStats = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const stats = await focusService.getFocusStats(authReq.user!.id);
  return ApiResponse.success(res, stats, 'Focus statistics calculated');
});

/**
 * @desc    Delete a focus session
 * @route   DELETE /api/v1/focus/:id
 * @access  Private
 */
export const deleteSession = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await focusService.deleteSession(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Focus session deleted');
});

export default {
  startSession,
  endSession,
  logCompletedSession,
  getFocusSessions,
  getFocusStats,
  deleteSession,
};
