import { Request, Response } from 'express';
import techService from './tech.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

export const createTechLearning = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const learning = await techService.createTechLearning(authReq.user!.id, req.body);
  return ApiResponse.success(res, learning, 'Technology learning entry created', 201);
});

export const getTechLearnings = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { category, status, page, limit } = req.query;
  const pageNum = page ? parseInt(page as string, 10) : undefined;
  const limitNum = limit ? parseInt(limit as string, 10) : undefined;
  const learnings = await techService.getTechLearnings(
    authReq.user!.id,
    category as string,
    status as string,
    pageNum,
    limitNum
  );
  return ApiResponse.success(res, learnings, 'Technology learning entries retrieved');
});

export const getTechSummary = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const summary = await techService.getTechSummary(authReq.user!.id);
  return ApiResponse.success(res, summary, 'Tech learning summary retrieved');
});

export const getTechLearningById = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const learning = await techService.getTechLearningById(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, learning, 'Technology learning entry retrieved');
});

export const updateTechLearning = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const learning = await techService.updateTechLearning(
    authReq.user!.id,
    req.params.id,
    req.body
  );
  return ApiResponse.success(res, learning, 'Technology learning entry updated');
});

export const deleteTechLearning = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await techService.deleteTechLearning(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Technology learning entry deleted');
});

export default {
  createTechLearning,
  getTechLearnings,
  getTechSummary,
  getTechLearningById,
  updateTechLearning,
  deleteTechLearning,
};
