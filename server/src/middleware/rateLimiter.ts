import rateLimit from 'express-rate-limit';
import { Request, Response } from 'express';

/**
 * Strict rate limiter for authentication routes (login, register, refresh)
 * Limits an IP to 10 attempts per 15-minute window.
 */
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  limit: process.env.NODE_ENV === 'production' ? 10 : 50,
  standardHeaders: true,
  legacyHeaders: true,
  skip: () => process.env.NODE_ENV === 'test',
  handler: (_req: Request, res: Response) => {
    res.status(429).json({
      success: false,
      message: 'Too many authentication attempts from this IP. Please try again after 15 minutes.',
    });
  },
});

/**
 * General rate limiter for all API endpoints
 * Limits an IP to 300 requests per 15-minute window.
 */
export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  limit: process.env.NODE_ENV === 'production' ? 300 : 1000,
  standardHeaders: true,
  legacyHeaders: true,
  skip: () => process.env.NODE_ENV === 'test',
  handler: (_req: Request, res: Response) => {
    res.status(429).json({
      success: false,
      message: 'Too many requests from this IP. Please try again later.',
    });
  },
});

export default {
  authLimiter,
  apiLimiter,
};
