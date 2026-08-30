import { Router } from 'express';
import * as techController from './tech.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createTechLearningSchema,
  updateTechLearningSchema,
  uuidParamSchema,
} from './tech.validation';

const router = Router();

// All tech routes require authentication
router.use(authenticate);

router.get('/summary', techController.getTechSummary);
router.post('/', validate(createTechLearningSchema), techController.createTechLearning);
router.get('/', techController.getTechLearnings);
router.get('/:id', validate(uuidParamSchema, 'params'), techController.getTechLearningById);
router.put(
  '/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateTechLearningSchema),
  techController.updateTechLearning
);
router.delete('/:id', validate(uuidParamSchema, 'params'), techController.deleteTechLearning);

export default router;
