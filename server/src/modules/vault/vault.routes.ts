import { Router } from 'express';
import * as vaultController from './vault.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createNoteSchema,
  updateNoteSchema,
  vaultSearchQuerySchema,
  uuidParamSchema,
} from './vault.validation';

const router = Router();

// All vault routes require authentication
router.use(authenticate);

// --- Omni-Search, Tags & Graph (UC-127 to UC-133) ---
router.get('/search', vaultController.searchVault);
router.get('/tags', vaultController.getVaultTags);
router.get('/graph', vaultController.getNoteGraph);
router.post('/links', vaultController.linkNotes);
router.delete('/links', vaultController.unlinkNotes);

// --- Notes & Snippets (UC-121 to UC-126) ---
router.post('/notes', validate(createNoteSchema), vaultController.createNote);
router.get('/notes', validate(vaultSearchQuerySchema, 'query'), vaultController.getNotes);
router.get('/notes/:id', validate(uuidParamSchema, 'params'), vaultController.getNoteById);
router.put(
  '/notes/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateNoteSchema),
  vaultController.updateNote
);
router.delete('/notes/:id', validate(uuidParamSchema, 'params'), vaultController.deleteNote);

export default router;
