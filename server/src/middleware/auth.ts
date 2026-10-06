import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import ApiError from '../common/apiError';
import asyncHandler from '../common/asyncHandler';
import env from '../config/env';
import authService from '../modules/auth/auth.service';

export interface AuthenticatedUser {
  id: string;
  email: string;
  name: string | null;
  timezone: string;
  dateFormat: string;
  avatarUrl: string | null;
}

export interface AuthRequest extends Request {
  user?: AuthenticatedUser;
}

interface JwtPayload {
  id: string;
  iat?: number;
  exp?: number;
}

export const authenticate = asyncHandler(async (req: Request, _res: Response, next: NextFunction) => {
  const authReq = req as AuthRequest;
  let token: string | undefined;
  const authHeader = req.headers.authorization;

  if (authHeader && authHeader.startsWith('Bearer ')) {
    token = authHeader.split(' ')[1];
  }

  if (!token) {
    throw new ApiError(401, 'Authentication token is required');
  }

  try {
    const decoded = jwt.verify(
      token,
      env.JWT_SECRET
    ) as JwtPayload;

    // Look up user from in-memory store instead of database
    const storedUser = authService.getUserById(decoded.id);

    if (!storedUser) {
      throw new ApiError(401, 'User associated with this token no longer exists');
    }

    authReq.user = {
      id: storedUser.id,
      email: storedUser.email,
      name: storedUser.name,
      timezone: storedUser.timezone,
      dateFormat: storedUser.dateFormat,
      avatarUrl: storedUser.avatarUrl,
    };
    next();
  } catch (error: unknown) {
    if (error instanceof ApiError) throw error;
    if (error instanceof Error && error.name === 'TokenExpiredError') {
      throw new ApiError(401, 'Access token has expired, please refresh token');
    }
    throw new ApiError(401, 'Invalid authentication token');
  }
});

export default authenticate;
