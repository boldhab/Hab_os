import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../../config/db';
import env from '../../config/env';
import ApiResponse from '../../common/apiResponse';
import ApiError from '../../common/apiError';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';
import validate from '../../middleware/validate';
import { authLimiter } from '../../middleware/rateLimiter';
import { logAuditFromReq } from '../../utils/auditLogger';
import {
  loginSchema,
  registerSchema,
  refreshTokenSchema,
  updateProfileSchema,
  updatePreferencesSchema,
} from './auth.validation';

const router = Router();

// Helper to generate and persist auth tokens
const generateTokens = async (userId: string) => {
  const accessToken = jwt.sign({ id: userId }, env.JWT_SECRET, { expiresIn: '15m' });
  const refreshToken = jwt.sign(
    { id: userId, jti: crypto.randomUUID() },
    env.JWT_REFRESH_SECRET,
    { expiresIn: '30d' }
  );

  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 30);

  await prisma.refreshToken.create({
    data: {
      token: refreshToken,
      userId,
      expiresAt,
    },
  });

  return { accessToken, refreshToken };
};

/**
 * POST /api/v1/auth/login
 * Rate limited to 10 attempts / 15 mins per IP.
 * Validates payload schema.
 */
router.post(
  '/login',
  authLimiter,
  validate(loginSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { email, password } = req.body;
    const normalizedEmail = email.toLowerCase().trim();

    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
    });

    if (!user) {
      logAuditFromReq(req, 'AUTH_LOGIN_FAILURE', 'FAILURE', { email: normalizedEmail, reason: 'User not found' });
      throw new ApiError(401, 'Invalid email or password');
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      logAuditFromReq(req, 'AUTH_LOGIN_FAILURE', 'FAILURE', { email: normalizedEmail, reason: 'Incorrect password' }, user.id);
      throw new ApiError(401, 'Invalid email or password');
    }

    const tokens = await generateTokens(user.id);

    logAuditFromReq(req, 'AUTH_LOGIN_SUCCESS', 'SUCCESS', { email: user.email }, user.id);

    return ApiResponse.success(
      res,
      {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          avatarUrl: user.avatarUrl,
          timezone: user.timezone,
          dateFormat: user.dateFormat,
        },
        tokens,
      },
      'Login successful'
    );
  })
);

/**
 * POST /api/v1/auth/register
 * Rate limited to 10 attempts / 15 mins per IP.
 * Validates payload schema.
 */
router.post(
  '/register',
  authLimiter,
  validate(registerSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { email, password, name } = req.body;
    const normalizedEmail = email.toLowerCase().trim();

    const existingUser = await prisma.user.findUnique({
      where: { email: normalizedEmail },
    });

    if (existingUser) {
      logAuditFromReq(req, 'AUTH_REGISTER_FAILURE', 'FAILURE', { email: normalizedEmail, reason: 'Email in use' });
      throw new ApiError(400, 'A user with this email already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await prisma.user.create({
      data: {
        email: normalizedEmail,
        password: hashedPassword,
        name: name ? name.trim() : null,
        preferences: {
          create: {
            dashboardModules: [
              'priorities',
              'life_score',
              'coding_stats',
              'study_timer',
              'gym_workout',
              'finance_summary',
              'habits',
            ],
          },
        },
      },
    });

    const tokens = await generateTokens(user.id);

    logAuditFromReq(req, 'AUTH_REGISTER_SUCCESS', 'SUCCESS', { email: user.email }, user.id);

    return ApiResponse.success(
      res,
      {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          avatarUrl: user.avatarUrl,
          timezone: user.timezone,
          dateFormat: user.dateFormat,
        },
        tokens,
      },
      'Registration successful',
      201
    );
  })
);

/**
 * GET /api/v1/auth/me
 */
router.get(
  '/me',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    return ApiResponse.success(res, authReq.user, 'Profile retrieved');
  })
);

/**
 * POST /api/v1/auth/refresh
 * Rate limited to 10 attempts / 15 mins per IP.
 * Implements single-use refresh token rotation and token-family reuse/breach detection.
 */
router.post(
  '/refresh',
  authLimiter,
  validate(refreshTokenSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { refreshToken } = req.body;

    const storedToken = await prisma.refreshToken.findUnique({
      where: { token: refreshToken },
    });

    // 1. REUSE DETECTION: If token exists but was already revoked, token theft has occurred!
    if (storedToken && storedToken.revoked) {
      // Invalidate all active refresh tokens for this user immediately
      await prisma.refreshToken.updateMany({
        where: { userId: storedToken.userId, revoked: false },
        data: { revoked: true },
      });

      logAuditFromReq(
        req,
        'AUTH_TOKEN_REUSE_DETECTED',
        'CRITICAL',
        {
          reason: 'Revoked refresh token presented. Revoked all sessions for user.',
          tokenId: storedToken.id,
        },
        storedToken.userId
      );

      throw new ApiError(403, 'Invalid refresh token: token reuse detected. All active sessions have been terminated.');
    }

    // 2. EXPIRATION OR NON-EXISTENCE CHECK
    if (!storedToken || storedToken.expiresAt < new Date()) {
      logAuditFromReq(req, 'AUTH_TOKEN_REFRESH_FAILURE', 'FAILURE', {
        reason: !storedToken ? 'Token not found in database' : 'Token expired',
      });
      throw new ApiError(401, 'Invalid or expired refresh token');
    }

    // 3. CRYPTOGRAPHIC SIGNATURE VERIFICATION
    let decoded: any;
    try {
      decoded = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET);
    } catch {
      logAuditFromReq(
        req,
        'AUTH_TOKEN_REFRESH_FAILURE',
        'FAILURE',
        { reason: 'Invalid signature on refresh token' },
        storedToken.userId
      );
      throw new ApiError(401, 'Invalid refresh token signature');
    }

    // 4. ROTATION: Revoke the current single-use refresh token
    await prisma.refreshToken.update({
      where: { id: storedToken.id },
      data: { revoked: true },
    });

    // 5. Issue new access token AND new rotated refresh token
    const newTokens = await generateTokens(decoded.id || storedToken.userId);

    logAuditFromReq(
      req,
      'AUTH_TOKEN_REFRESH_SUCCESS',
      'SUCCESS',
      { previousTokenId: storedToken.id },
      storedToken.userId
    );

    return ApiResponse.success(
      res,
      {
        accessToken: newTokens.accessToken,
        refreshToken: newTokens.refreshToken,
      },
      'Tokens refreshed successfully'
    );
  })
);

/**
 * PUT /api/v1/auth/profile
 * Validates updateProfileSchema
 */
router.put(
  '/profile',
  authenticate,
  validate(updateProfileSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const { name, avatarUrl, timezone, dateFormat } = req.body;

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        name: name !== undefined ? name : undefined,
        avatarUrl: avatarUrl !== undefined ? avatarUrl : undefined,
        timezone: timezone !== undefined ? timezone : undefined,
        dateFormat: dateFormat !== undefined ? dateFormat : undefined,
      },
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
        timezone: true,
        dateFormat: true,
      },
    });

    logAuditFromReq(req, 'AUTH_PROFILE_UPDATE', 'SUCCESS', { updatedFields: Object.keys(req.body) }, userId);

    return ApiResponse.success(res, updatedUser, 'Profile updated');
  })
);

/**
 * PUT /api/v1/auth/preferences
 * Validates updatePreferencesSchema
 */
router.put(
  '/preferences',
  authenticate,
  validate(updatePreferencesSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const { lifeScoreWeights, dailyCodingTargetMins, dailyStudyTargetMins, weeklyGymTarget } = req.body;

    const prefs = await prisma.userPreference.upsert({
      where: { userId },
      update: {
        lifeScoreWeights: lifeScoreWeights !== undefined ? lifeScoreWeights : undefined,
        dailyCodingTargetMins: dailyCodingTargetMins !== undefined ? Number(dailyCodingTargetMins) : undefined,
        dailyStudyTargetMins: dailyStudyTargetMins !== undefined ? Number(dailyStudyTargetMins) : undefined,
        weeklyGymTarget: weeklyGymTarget !== undefined ? Number(weeklyGymTarget) : undefined,
      },
      create: {
        userId,
        lifeScoreWeights: lifeScoreWeights || {},
        dailyCodingTargetMins: dailyCodingTargetMins ? Number(dailyCodingTargetMins) : 120,
        dailyStudyTargetMins: dailyStudyTargetMins ? Number(dailyStudyTargetMins) : 120,
        weeklyGymTarget: weeklyGymTarget ? Number(weeklyGymTarget) : 4,
      },
    });

    logAuditFromReq(req, 'AUTH_PREFERENCES_UPDATE', 'SUCCESS', { updatedFields: Object.keys(req.body) }, userId);

    return ApiResponse.success(res, prefs, 'Preferences updated');
  })
);

export default router;
