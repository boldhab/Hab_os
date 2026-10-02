import { Router, Request, Response } from 'express';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import projectsService from './projects.service';
import { projectEventBus } from './projects.events';
import {
  createProjectSchema,
  updateProjectSchema,
  createFeatureSchema,
  updateFeatureSchema,
  createBugSchema,
  updateBugSchema,
  moveBoardItemSchema,
} from './projects.validation';

const router = Router();

// ==========================================
// 0. PUBLIC GITHUB WEBHOOK RECEIVER
// ==========================================

router.post(
  '/:id/webhooks/github',
  asyncHandler(async (req: Request, res: Response) => {
    const event = (req.headers['x-github-event'] as string) || 'push';
    const signature = req.headers['x-hub-signature-256'] as string | undefined;
    const rawBody = (req as any).rawBody as Buffer | undefined;

    const result = await projectsService.handleProjectGithubWebhook(
      req.params.id,
      event,
      req.body,
      rawBody,
      signature
    );
    return ApiResponse.success(res, result, 'GitHub webhook processed');
  })
);

router.use(authenticate);

// ==========================================
// 0.1 SSE REAL-TIME EVENT STREAM
// ==========================================

router.get(
  '/:id/events',
  (req: Request, res: Response) => {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'X-Accel-Buffering': 'no',
    });

    res.write(`event: connected\ndata: {"status":"connected","projectId":"${req.params.id}"}\n\n`);

    projectEventBus.addClient(req.params.id, res);

    const pingInterval = setInterval(() => {
      try {
        res.write(`: ping\n\n`);
      } catch (_) {}
    }, 25000);

    req.on('close', () => {
      clearInterval(pingInterval);
      projectEventBus.removeClient(req.params.id, res);
    });
  }
);

// ==========================================
// 1. TECH STACK INSIGHTS (Cross-Project)
// ==========================================

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

router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const { status, page, limit } = req.query;
    const pageNum = page ? parseInt(page as string, 10) : undefined;
    const limitNum = limit ? parseInt(limit as string, 10) : undefined;
    const projects = await projectsService.getProjects(authReq.user!.id, status as string, pageNum, limitNum);
    return ApiResponse.success(res, projects, 'Projects retrieved');
  })
);

router.post(
  '/',
  validate(createProjectSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const project = await projectsService.createProject(authReq.user!.id, req.body);
    return ApiResponse.success(res, project, 'Project created', 201);
  })
);

router.get(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const project = await projectsService.getProjectById(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, project, 'Project retrieved');
  })
);

const handleUpdateProject = [
  validate(updateProjectSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const project = await projectsService.updateProject(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, project, 'Project updated');
  }),
];

router.put('/:id', ...handleUpdateProject);
router.patch('/:id', ...handleUpdateProject);

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

router.get(
  '/:id/features',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const features = await projectsService.getFeatures(authReq.user!.id, req.params.id, req.query);
    return ApiResponse.success(res, features, 'Project features retrieved');
  })
);

router.post(
  '/:id/features',
  validate(createFeatureSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const feature = await projectsService.createFeature(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, feature, 'Feature created', 201);
  })
);

const handleUpdateFeature = [
  validate(updateFeatureSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const feature = await projectsService.updateFeature(
      authReq.user!.id,
      req.params.id,
      req.params.featureId,
      req.body
    );
    return ApiResponse.success(res, feature, 'Feature updated');
  }),
];

router.put('/:id/features/:featureId', ...handleUpdateFeature);
router.patch('/:id/features/:featureId', ...handleUpdateFeature);

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

router.get(
  '/:id/bugs',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const bugs = await projectsService.getBugs(authReq.user!.id, req.params.id, req.query);
    return ApiResponse.success(res, bugs, 'Project bugs retrieved');
  })
);

router.post(
  '/:id/bugs',
  validate(createBugSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const bug = await projectsService.createBug(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, bug, 'Bug created', 201);
  })
);

const handleUpdateBug = [
  validate(updateBugSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const bug = await projectsService.updateBug(
      authReq.user!.id,
      req.params.id,
      req.params.bugId,
      req.body
    );
    return ApiResponse.success(res, bug, 'Bug updated');
  }),
];

router.put('/:id/bugs/:bugId', ...handleUpdateBug);
router.patch('/:id/bugs/:bugId', ...handleUpdateBug);

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

router.get(
  '/:id/board',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const board = await projectsService.getBoard(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, board, 'Project board retrieved');
  })
);

router.post(
  '/:id/board/move',
  validate(moveBoardItemSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const result = await projectsService.moveBoardItem(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, result, 'Board item moved');
  })
);

// ==========================================
// 6. ANALYTICS & COMMITS
// ==========================================

router.get(
  '/:id/analytics',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const analytics = await projectsService.getProjectAnalytics(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, analytics, 'Project analytics retrieved');
  })
);

router.get(
  '/:id/commits',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const commits = await projectsService.getProjectCommits(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, commits, 'Project commits retrieved');
  })
);

// ==========================================
// 7. GITHUB WEBHOOK CONFIG & ENTITY LINKS
// ==========================================

router.get(
  '/:id/webhooks/config',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const config = await projectsService.getProjectWebhookConfig(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, config, 'Project webhook config retrieved');
  })
);

router.post(
  '/:id/webhooks/secret',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const result = await projectsService.generateProjectWebhookSecret(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, result, 'Project webhook secret generated');
  })
);

router.get(
  '/:id/github-links',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const links = await projectsService.getProjectGithubLinks(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, links, 'Project GitHub links retrieved');
  })
);

router.post(
  '/:id/github-links',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const link = await projectsService.linkGithubEntity(authReq.user!.id, req.params.id, req.body);
    return ApiResponse.success(res, link, 'GitHub link created', 201);
  })
);

router.delete(
  '/:id/github-links/:linkId',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await projectsService.unlinkGithubEntity(authReq.user!.id, req.params.id, req.params.linkId);
    return ApiResponse.success(res, null, 'GitHub link deleted');
  })
);

export default router;
