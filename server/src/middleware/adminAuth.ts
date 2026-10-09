import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import ApiError from '../common/apiError';
import asyncHandler from '../common/asyncHandler';
import env from '../config/env';
import authService from '../modules/auth/auth.service';
import { AuthRequest } from './auth';

export const ADMIN_SECRET_KEY = process.env.ADMIN_SECRET_KEY || 'habos-admin-secret-2026';

export const requireAdmin = asyncHandler(async (req: Request, _res: Response, next: NextFunction) => {
  const authReq = req as AuthRequest;

  // 1. Check Header or Query Admin Secret Key
  const headerKey = req.headers['x-admin-key'] as string;
  const queryKey = req.query['admin_key'] as string;
  const providedKey = headerKey || queryKey;

  if (providedKey && providedKey === ADMIN_SECRET_KEY) {
    authReq.user = {
      id: 'admin-system-key',
      email: 'admin@habos.dev',
      name: 'Root Administrator',
      timezone: 'UTC',
      dateFormat: 'YYYY-MM-DD',
      avatarUrl: null,
      role: 'ADMIN',
    };
    return next();
  }

  // 2. Check Demo Admin Bypass in Development / Test
  const isDev = env.NODE_ENV !== 'production';
  const demoHeader = req.headers['x-demo-admin'];
  if (isDev && (demoHeader === 'true' || req.query['demo'] === 'true')) {
    authReq.user = {
      id: 'demo-admin-session',
      email: 'admin@habos.dev',
      name: 'HabOS Dev Administrator',
      timezone: 'UTC',
      dateFormat: 'YYYY-MM-DD',
      avatarUrl: null,
      role: 'ADMIN',
    };
    return next();
  }

  // 3. Check JWT Bearer Token
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      const decoded = jwt.verify(token, env.JWT_SECRET) as { id: string };
      const storedUser = authService.getUserById(decoded.id);

      if (storedUser) {
        const isAdmin =
          (storedUser as any).role === 'ADMIN' ||
          storedUser.email === 'admin@habos.dev' ||
          storedUser.email === 'demo@habos.dev';

        if (isAdmin) {
          authReq.user = {
            id: storedUser.id,
            email: storedUser.email,
            name: storedUser.name,
            timezone: storedUser.timezone,
            dateFormat: storedUser.dateFormat,
            avatarUrl: storedUser.avatarUrl,
            role: 'ADMIN',
          };
          return next();
        }
      }
    } catch (_err) {
      // Continue to unauthorized response
    }
  }

  throw new ApiError(403, 'Administrative access required. Provide a valid Admin Key or sign in with an Administrator account.');
});

export default requireAdmin;
