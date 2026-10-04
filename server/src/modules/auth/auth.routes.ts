import { Router } from 'express';
import * as authController from './auth.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  registerSchema,
  loginSchema,
  googleAuthSchema,
  refreshTokenSchema,
  updateProfileSchema,
  updatePreferencesSchema,
} from './auth.validation';

const router = Router();

// Public routes
router.post('/register', validate(registerSchema), authController.register);
router.post('/login', validate(loginSchema), authController.login);
router.get('/google', authController.initiateGoogleAuth);
router.post('/google/configure', authController.configureGoogleOAuth);
router.get('/google/callback', authController.handleGoogleCallback);
router.post('/google', validate(googleAuthSchema), authController.googleAuth);
router.post('/refresh', validate(refreshTokenSchema), authController.refreshTokens);

// Authenticated routes
router.post('/logout', authenticate, authController.logout);
router.get('/me', authenticate, authController.getProfile);
router.put('/profile', authenticate, validate(updateProfileSchema), authController.updateProfile);
router.put('/preferences', authenticate, validate(updatePreferencesSchema), authController.updatePreferences);

export default router;
