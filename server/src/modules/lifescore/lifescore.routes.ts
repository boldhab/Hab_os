import { Router } from 'express';
import * as lifeScoreController from './lifescore.controller';
import { authenticate } from '../../middleware/auth';

const router = Router();

// All lifescore routes require authentication
router.use(authenticate);

router.get('/', lifeScoreController.getLifeScore);
router.post('/snapshot', lifeScoreController.snapshotLifeScore);
router.get('/history', lifeScoreController.getLifeScoreHistory);

export default router;
