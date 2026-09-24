import { Router, Request, Response } from 'express';
import * as integrationsController from './integrations.controller';
import integrationsService from './integrations.service';
import { authenticate, AuthRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import {
  syncGitHubSchema,
  importRepoSchema,
  syncLeetCodeSchema,
  analyzeRepoParamSchema,
} from './integrations.validation';

const router = Router();

// ==========================================
// 1. PUBLIC WEBHOOKS & HEALTH
// ==========================================

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

router.get('/', (_req: Request, res: Response) => {
  res.json({ message: 'Integrations endpoint ready' });
});

// ==========================================
// 2. AUTHENTICATED ROUTES
// ==========================================

router.use(authenticate);

// --- GitHub Developer Hub ---
router.post('/github/sync', validate(syncGitHubSchema), integrationsController.syncGitHub);
router.get('/github/stats', integrationsController.getGitHubStats);
router.get('/github/repos', integrationsController.listGitHubRepositories);
router.post('/github/import', validate(importRepoSchema), integrationsController.importRepositoryAsProject);
router.post('/github/import-repo', validate(importRepoSchema), integrationsController.importRepositoryAsProject);

router.get(
  '/github/repos/:owner/:repo/analyze',
  validate(analyzeRepoParamSchema, 'params'),
  integrationsController.analyzeRepository
);
router.get(
  '/github/analyze/:owner/:repo',
  validate(analyzeRepoParamSchema, 'params'),
  integrationsController.analyzeRepository
);

// --- LeetCode Integration ---
router.get('/leetcode/stats', integrationsController.getLeetCodeStats);
router.post('/leetcode/sync', validate(syncLeetCodeSchema), integrationsController.syncLeetCode);

export default router;
