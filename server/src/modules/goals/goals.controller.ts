import { Request, Response } from 'express';
import goalsService from './goals.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

// --- GOALS ---

export const createGoal = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const goal = await goalsService.createGoal(authReq.user!.id, req.body);
  return ApiResponse.success(res, goal, 'Goal created successfully', 201);
});

export const getGoals = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { category, page, limit } = req.query;
  const pageNum = page ? parseInt(page as string, 10) : undefined;
  const limitNum = limit ? parseInt(limit as string, 10) : undefined;
  const goals = await goalsService.getGoals(authReq.user!.id, category as string, pageNum, limitNum);
  return ApiResponse.success(res, goals, 'Goals retrieved successfully');
});

export const getRoadmap = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const roadmap = await goalsService.getRoadmap(authReq.user!.id);
  return ApiResponse.success(res, roadmap, 'Goal roadmap retrieved successfully');
});

export const getGoalById = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const goal = await goalsService.getGoalById(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, goal, 'Goal retrieved successfully');
});

export const updateGoal = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const goal = await goalsService.updateGoal(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, goal, 'Goal updated successfully');
});

export const deleteGoal = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await goalsService.deleteGoal(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Goal deleted successfully');
});

// --- MILESTONES ---

export const createMilestone = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const milestone = await goalsService.createMilestone(authReq.user!.id, req.params.goalId, req.body);
  return ApiResponse.success(res, milestone, 'Milestone added successfully', 201);
});

export const updateMilestone = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const milestone = await goalsService.updateMilestone(
    authReq.user!.id,
    req.params.goalId,
    req.params.milestoneId,
    req.body
  );
  return ApiResponse.success(res, milestone, 'Milestone updated successfully');
});

export const deleteMilestone = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await goalsService.deleteMilestone(
    authReq.user!.id,
    req.params.goalId,
    req.params.milestoneId
  );
  return ApiResponse.success(res, result, 'Milestone deleted successfully');
});

export default {
  createGoal,
  getGoals,
  getRoadmap,
  getGoalById,
  updateGoal,
  deleteGoal,
  createMilestone,
  updateMilestone,
  deleteMilestone,
};
