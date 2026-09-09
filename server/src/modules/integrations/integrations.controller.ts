import { Request, Response } from 'express';
import integrationsService from './integrations.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

export const getGitHubStats = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const stats = await integrationsService.getGitHubStats(authReq.user!.id);
  return ApiResponse.success(res, stats, 'GitHub stats retrieved');
});

export const syncGitHub = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await integrationsService.syncGitHub(authReq.user!.id, req.body);
  return ApiResponse.success(res, result, 'GitHub integration synced successfully');
});

export const listGitHubRepositories = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const repos = await integrationsService.listGitHubRepositories(authReq.user!.id);
  return ApiResponse.success(res, repos, 'GitHub repositories retrieved successfully');
});

export const importRepositoryAsProject = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await integrationsService.importRepositoryAsProject(authReq.user!.id, req.body);
  return ApiResponse.success(res, result, result.message, result.isNewlyCreated ? 201 : 200);
});

export const analyzeRepository = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { owner, repo } = req.params;
  const analysis = await integrationsService.analyzeRepository(authReq.user!.id, owner, repo);
  return ApiResponse.success(res, analysis, 'Repository commit and code analysis generated');
});

export const getLeetCodeStats = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const stats = await integrationsService.getLeetCodeStats(authReq.user!.id);
  return ApiResponse.success(res, stats, 'LeetCode stats retrieved');
});

export const syncLeetCode = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await integrationsService.syncLeetCode(authReq.user!.id, req.body);
  return ApiResponse.success(res, result, 'LeetCode integration synced successfully');
});

export default {
  getGitHubStats,
  syncGitHub,
  listGitHubRepositories,
  importRepositoryAsProject,
  analyzeRepository,
  getLeetCodeStats,
  syncLeetCode,
};
