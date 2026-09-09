import { Router } from 'express';
import * as integrationsController from './integrations.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  syncGitHubSchema,
  importRepoSchema,
  analyzeRepoParamSchema,
  syncLeetCodeSchema,
} from './integrations.validation';

const router = Router();

// All integration routes require authentication
router.use(authenticate);

// --- GitHub Core & Sync (UC-53 to UC-58) ---
router.get('/github', integrationsController.getGitHubStats);
router.post('/github/sync', validate(syncGitHubSchema), integrationsController.syncGitHub);

// --- GitHub Repository Exploration & Import ---
router.get('/github/repos', integrationsController.listGitHubRepositories);
router.post('/github/import-repo', validate(importRepoSchema), integrationsController.importRepositoryAsProject);
router.get(
  '/github/repos/:owner/:repo/analyze',
  validate(analyzeRepoParamSchema, 'params'),
  integrationsController.analyzeRepository
);

// --- LeetCode DSA (UC-59 to UC-64) ---
router.get('/leetcode', integrationsController.getLeetCodeStats);
router.post('/leetcode/sync', validate(syncLeetCodeSchema), integrationsController.syncLeetCode);

export default router;
