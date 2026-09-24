import { Router } from 'express';
import * as dashboardController from './dashboard.controller';
import { authenticate } from '../../middleware/auth';

const router = Router();

// All dashboard routes require authentication
router.use(authenticate);

router.get('/', dashboardController.getDashboardFeed);

export default router;
