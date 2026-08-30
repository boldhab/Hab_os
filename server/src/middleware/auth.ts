import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import prisma from '../config/db';
import ApiError from '../common/apiError';
import asyncHandler from '../common/asyncHandler';

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
      process.env.JWT_SECRET || 'supersecretjwtkey_habos_2026_secure'
    ) as JwtPayload;

    const user = await prisma.user.findUnique({
      where: { id: decoded.id },
      select: {
        id: true,
        email: true,
        name: true,
        timezone: true,
        dateFormat: true,
        avatarUrl: true,
      },
    });

    if (!user) {
      throw new ApiError(401, 'User associated with this token no longer exists');
    }

    authReq.user = user;
    next();
  } catch (error: unknown) {
    if (error instanceof Error && error.name === 'TokenExpiredError') {
      throw new ApiError(401, 'Access token has expired, please refresh token');
    }
    throw new ApiError(401, 'Invalid authentication token');
  }
});

export default authenticate;
