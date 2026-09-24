import { Router, Request, Response } from 'express';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';
import projectsService from './projects.service';

const router = Router();

router.use(authenticate);

// ==========================================
// 1. TECH STACK INSIGHTS (Cross-Project)
// ==========================================

/**
 * GET /api/v1/projects/insights/tech-stack
 */
router.get(
  '/insights/tech-stack',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const insights = await projectsService.getTechStackInsights(authReq.user!.id);
    return ApiResponse.success(res, insights, 'Tech stack insights retrieved');
  })
);

// ==========================================
// 2. PROJECTS CRUD
// ==========================================

/**
 * GET /api/v1/projects
 */
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const projects = await projectsService.getProjects(authReq.user!.id);
    return ApiResponse.success(res, projects, 'Projects retrieved');
  })
);

/**
 * POST /api/v1/projects
 */
router.post(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const project = await projectsService.createProject(authReq.user!.id, req.body);
    return ApiResponse.success(res, project, 'Project created', 201);
  })
);

/**
 * GET /api/v1/projects/:id
 */
router.get(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const project = await projectsService.getProjectById(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, project, 'Project retrieved');
  })
);

/**
 * PATCH /api/v1/projects/:id
 */
router.patch(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const project = await projectsService.updateProject(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, project, 'Project updated');
  })
);

/**
 * DELETE /api/v1/projects/:id
 */
router.delete(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await projectsService.deleteProject(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, null, 'Project deleted');
  })
);

// ==========================================
// 3. FEATURES CRUD
// ==========================================

/**
 * GET /api/v1/projects/:id/features
 */
router.get(
  '/:id/features',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const features = await projectsService.getFeatures(authReq.user!.id, req.params.id, req.query);
    return ApiResponse.success(res, features, 'Project features retrieved');
  })
);

/**
 * POST /api/v1/projects/:id/features
 */
router.post(
  '/:id/features',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const feature = await projectsService.createFeature(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, feature, 'Feature created', 201);
  })
);

/**
 * PATCH /api/v1/projects/:id/features/:featureId
 */
router.patch(
  '/:id/features/:featureId',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const feature = await projectsService.updateFeature(
      authReq.user!.id,
      req.params.id,
      req.params.featureId,
      req.body
    );
    return ApiResponse.success(res, feature, 'Feature updated');
  })
);

/**
 * DELETE /api/v1/projects/:id/features/:featureId
 */
router.delete(
  '/:id/features/:featureId',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await projectsService.deleteFeature(authReq.user!.id, req.params.id, req.params.featureId);
    return ApiResponse.success(res, null, 'Feature deleted');
  })
);

// ==========================================
// 4. BUGS CRUD
// ==========================================

/**
 * GET /api/v1/projects/:id/bugs
 */
router.get(
  '/:id/bugs',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const bugs = await projectsService.getBugs(authReq.user!.id, req.params.id, req.query);
    return ApiResponse.success(res, bugs, 'Project bugs retrieved');
  })
);

/**
 * POST /api/v1/projects/:id/bugs
 */
router.post(
  '/:id/bugs',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const bug = await projectsService.createBug(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, bug, 'Bug created', 201);
  })
);

/**
 * PATCH /api/v1/projects/:id/bugs/:bugId
 */
router.patch(
  '/:id/bugs/:bugId',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const bug = await projectsService.updateBug(
      authReq.user!.id,
      req.params.id,
      req.params.bugId,
      req.body
    );
    return ApiResponse.success(res, bug, 'Bug updated');
  })
);

/**
 * DELETE /api/v1/projects/:id/bugs/:bugId
 */
router.delete(
  '/:id/bugs/:bugId',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await projectsService.deleteBug(authReq.user!.id, req.params.id, req.params.bugId);
    return ApiResponse.success(res, null, 'Bug deleted');
  })
);

// ==========================================
// 5. KANBAN BOARD & MOVE
// ==========================================

/**
 * GET /api/v1/projects/:id/board
 */
router.get(
  '/:id/board',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const board = await projectsService.getBoard(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, board, 'Project board retrieved');
  })
);

/**
 * POST /api/v1/projects/:id/board/move
 */
router.post(
  '/:id/board/move',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const result = await projectsService.moveBoardItem(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, result, 'Board item moved');
  })
);

// ==========================================
// 6. ANALYTICS & COMMITS
// ==========================================

/**
 * GET /api/v1/projects/:id/analytics
 */
router.get(
  '/:id/analytics',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const analytics = await projectsService.getProjectAnalytics(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, analytics, 'Project analytics retrieved');
  })
);

/**
 * GET /api/v1/projects/:id/commits
 */
router.get(
  '/:id/commits',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const commits = await projectsService.getProjectCommits(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, commits, 'Project commits retrieved');
  })
);

export default router;
