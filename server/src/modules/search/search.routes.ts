import { Router } from 'express';
import * as searchController from './search.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { globalSearchQuerySchema } from './search.validation';

const router = Router();

// All search routes require authentication
router.use(authenticate);

router.get('/', validate(globalSearchQuerySchema, 'query'), searchController.searchGlobal);

export default router;
