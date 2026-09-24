import { Router, Request, Response } from 'express';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';
import integrationsService from './integrations.service';

const router = Router();

// ==========================================
// 1. PUBLIC GITHUB WEBHOOK (Signature Verified)
// ==========================================

/**
 * POST /api/v1/integrations/github/webhook
 */
router.post(
  '/github/webhook',
  asyncHandler(async (req: Request, res: Response) => {
    const event = (req.headers['x-github-event'] as string) || 'push';
    const signature = req.headers['x-hub-signature-256'] as string | undefined;
    const rawBody = (req as any).rawBody as Buffer | undefined;

    const result = await integrationsService.handleWebhook(event, req.body, rawBody, signature);
    return ApiResponse.success(res, result, 'GitHub webhook processed');
  })
);

// General health check
router.get('/', (_req: Request, res: Response) => {
  res.json({ message: 'Integrations endpoint ready' });
});

// ==========================================
// 2. AUTHENTICATED GITHUB DEVELOPER HUB ROUTES
// ==========================================

router.use(authenticate);

/**
 * POST /api/v1/integrations/github/sync
 */
router.post(
  '/github/sync',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const integration = await integrationsService.syncGitHub(authReq.user!.id, req.body);
    return ApiResponse.success(res, integration, 'GitHub account synced');
  })
);

/**
 * GET /api/v1/integrations/github/repos
 */
router.get(
  '/github/repos',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const repos = await integrationsService.listUserRepos(authReq.user!.id);
    return ApiResponse.success(res, repos, 'GitHub repositories retrieved');
  })
);

/**
 * POST /api/v1/integrations/github/import-repo
 */
router.post(
  '/github/import-repo',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const result = await integrationsService.importRepo(authReq.user!.id, req.body);
    return ApiResponse.success(res, result, 'Repository imported as project', 201);
  })
);

/**
 * GET /api/v1/integrations/github/repos/:owner/:repo/analyze
 */
router.get(
  '/github/repos/:owner/:repo/analyze',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const analysis = await integrationsService.analyzeRepo(
      authReq.user!.id,
      req.params.owner,
      req.params.repo
    );
    return ApiResponse.success(res, analysis, 'Repository analysis completed');
  })
);

export default router;
