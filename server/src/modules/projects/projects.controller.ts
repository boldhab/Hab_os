import { Request, Response } from 'express';
import projectsService from './projects.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

// --- PROJECTS ---

export const createProject = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const project = await projectsService.createProject(authReq.user!.id, req.body);
  return ApiResponse.success(res, project, 'Project created successfully', 201);
});

export const getProjects = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { status, page, limit } = req.query;
  const pageNum = page ? parseInt(page as string, 10) : undefined;
  const limitNum = limit ? parseInt(limit as string, 10) : undefined;
  const projects = await projectsService.getProjects(authReq.user!.id, status as string, pageNum, limitNum);
  return ApiResponse.success(res, projects, 'Projects retrieved successfully');
});

export const getProjectById = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const project = await projectsService.getProjectById(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, project, 'Project retrieved successfully');
});

export const updateProject = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const project = await projectsService.updateProject(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, project, 'Project updated successfully');
});

export const deleteProject = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await projectsService.deleteProject(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Project deleted successfully');
});

// --- FEATURES ---

export const createFeature = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const feature = await projectsService.createFeature(authReq.user!.id, req.params.projectId, req.body);
  return ApiResponse.success(res, feature, 'Feature created successfully', 201);
});

export const updateFeature = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const feature = await projectsService.updateFeature(
    authReq.user!.id,
    req.params.projectId,
    req.params.featureId,
    req.body
  );
  return ApiResponse.success(res, feature, 'Feature updated successfully');
});

export const deleteFeature = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await projectsService.deleteFeature(
    authReq.user!.id,
    req.params.projectId,
    req.params.featureId
  );
  return ApiResponse.success(res, result, 'Feature deleted successfully');
});

// --- BUGS ---

export const createBug = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const bug = await projectsService.createBug(authReq.user!.id, req.params.projectId, req.body);
  return ApiResponse.success(res, bug, 'Bug reported successfully', 201);
});

export const updateBug = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const bug = await projectsService.updateBug(
    authReq.user!.id,
    req.params.projectId,
    req.params.bugId,
    req.body
  );
  return ApiResponse.success(res, bug, 'Bug updated successfully');
});

export const deleteBug = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await projectsService.deleteBug(
    authReq.user!.id,
    req.params.projectId,
    req.params.bugId
  );
  return ApiResponse.success(res, result, 'Bug removed successfully');
});

export default {
  createProject,
  getProjects,
  getProjectById,
  updateProject,
  deleteProject,
  createFeature,
  updateFeature,
  deleteFeature,
  createBug,
  updateBug,
  deleteBug,
};
