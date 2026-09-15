import { Request, Response } from 'express';
import aiService from './ai.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * @desc    Ask AI assistant with cross-domain context
 * @route   POST /api/v1/ai/ask
 * @access  Private
 */
export const askAssistant = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await aiService.askAssistant(authReq.user!.id, req.body);
  return ApiResponse.success(res, result, 'AI response generated');
});

/**
 * @desc    Get personalized daily operational briefing
 * @route   GET /api/v1/ai/briefing
 * @access  Private
 */
export const getDailyBriefing = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const briefing = await aiService.generateDailyBriefing(authReq.user!.id);
  return ApiResponse.success(res, briefing, 'Daily briefing generated');
});

/**
 * @desc    Get recommended next action / task
 * @route   GET /api/v1/ai/recommendation
 * @access  Private
 */
export const getRecommendation = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const recommendation = await aiService.recommendNextAction(authReq.user!.id);
  return ApiResponse.success(res, recommendation, 'Next action recommendation generated');
});

export default {
  askAssistant,
  getDailyBriefing,
  getRecommendation,
};
