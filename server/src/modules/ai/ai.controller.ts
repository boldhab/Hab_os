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

/**
 * @desc    Identify neglected areas across all life domains (UC-142)
 * @route   GET /api/v1/ai/neglected-areas
 * @access  Private
 */
export const getNeglectedAreas = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const periodDays = req.query.periodDays ? parseInt(req.query.periodDays as string, 10) : 7;
  const result = await aiService.identifyNeglectedAreas(authReq.user!.id, periodDays);
  return ApiResponse.success(res, result, 'Neglected areas identified');
});

/**
 * @desc    Recommend next high-impact tasks (UC-141)
 * @route   GET /api/v1/ai/recommend-tasks
 * @access  Private
 */
export const getRecommendedTasks = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 5;
  const tasks = await aiService.recommendNextTasks(authReq.user!.id, limit);
  return ApiResponse.success(res, tasks, 'Recommended tasks generated');
});

/**
 * @desc    Generate personalized weekly plan balancing lagging areas (UC-143)
 * @route   GET /api/v1/ai/plan, POST /api/v1/ai/plan
 * @access  Private
 */
export const getPersonalizedPlan = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const goalPrompt = (req.body?.goalPrompt || req.query?.goalPrompt) as string | undefined;
  const plan = await aiService.generatePersonalizedPlan(authReq.user!.id, goalPrompt);
  return ApiResponse.success(res, plan, 'Personalized plan generated');
});

/**
 * @desc    Analyze domain performance insights (UC-136 to UC-140)
 * @route   GET /api/v1/ai/insights, GET /api/v1/ai/insights/:domain
 * @access  Private
 */
export const getDomainInsights = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const domain = (req.params.domain || req.query.domain) as string | undefined;
  const insights = await aiService.analyzeDomainInsights(authReq.user!.id, domain);
  return ApiResponse.success(res, insights, 'Domain performance insights generated');
});

export default {
  askAssistant,
  getDailyBriefing,
  getRecommendation,
  getNeglectedAreas,
  getRecommendedTasks,
  getPersonalizedPlan,
  getDomainInsights,
};
