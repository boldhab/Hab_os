import { Request, Response } from 'express';
import lifeScoreService from './lifescore.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * @desc    Get real-time calculated Life Score with breakdown & tips
 * @route   GET /api/v1/lifescore
 * @access  Private
 */
export const getLifeScore = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await lifeScoreService.calculateLifeScore(authReq.user!.id);
  return ApiResponse.success(res, result, 'Life Score calculated successfully');
});

/**
 * @desc    Snapshot and record today's Life Score
 * @route   POST /api/v1/lifescore/snapshot
 * @access  Private
 */
export const snapshotLifeScore = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await lifeScoreService.snapshotDailyLifeScore(authReq.user!.id);
  return ApiResponse.success(res, result, 'Life Score recorded successfully', 201);
});

/**
 * @desc    Get 30-day historical life score logs
 * @route   GET /api/v1/lifescore/history
 * @access  Private
 */
export const getLifeScoreHistory = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const limit = req.query.limit ? parseInt(req.query.limit as string) : 30;
  const logs = await lifeScoreService.getLifeScoreHistory(authReq.user!.id, limit);
  return ApiResponse.success(res, logs, 'Life Score history retrieved');
});

export default {
  getLifeScore,
  snapshotLifeScore,
  getLifeScoreHistory,
};
