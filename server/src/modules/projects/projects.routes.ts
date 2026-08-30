import { Router } from 'express';
import * as projectsController from './projects.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createProjectSchema,
  updateProjectSchema,
  createFeatureSchema,
  updateFeatureSchema,
  createBugSchema,
  updateBugSchema,
  uuidParamSchema,
  projectFeatureParamSchema,
  projectBugParamSchema,
} from './projects.validation';

const router = Router();

// All project routes require authentication
router.use(authenticate);

// --- Projects (UC-38 to UC-42) ---
router.post('/', validate(createProjectSchema), projectsController.createProject);
router.get('/', projectsController.getProjects);
router.get('/:id', validate(uuidParamSchema, 'params'), projectsController.getProjectById);
router.put(
  '/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateProjectSchema),
  projectsController.updateProject
);
router.delete('/:id', validate(uuidParamSchema, 'params'), projectsController.deleteProject);

// --- Features (UC-43 to UC-47) ---
router.post(
  '/:projectId/features',
  validate(createFeatureSchema),
  projectsController.createFeature
);
router.put(
  '/:projectId/features/:featureId',
  validate(projectFeatureParamSchema, 'params'),
  validate(updateFeatureSchema),
  projectsController.updateFeature
);
router.delete(
  '/:projectId/features/:featureId',
  validate(projectFeatureParamSchema, 'params'),
  projectsController.deleteFeature
);

// --- Bugs (UC-48 to UC-52) ---
router.post(
  '/:projectId/bugs',
  validate(createBugSchema),
  projectsController.createBug
);
router.put(
  '/:projectId/bugs/:bugId',
  validate(projectBugParamSchema, 'params'),
  validate(updateBugSchema),
  projectsController.updateBug
);
router.delete(
  '/:projectId/bugs/:bugId',
  validate(projectBugParamSchema, 'params'),
  projectsController.deleteBug
);

export default router;
