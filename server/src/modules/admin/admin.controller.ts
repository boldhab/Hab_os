import { Request, Response } from 'express';
import { asyncHandler } from '../../middleware/errorHandler';
import adminService from './admin.service';
import auditLogger from './auditLog.service';

export const getHealth = asyncHandler(async (_req: Request, res: Response) => {
  const health = await adminService.getSystemHealth();
  res.status(200).json({ success: true, data: health });
});

export const getStats = asyncHandler(async (_req: Request, res: Response) => {
  const stats = await adminService.getSystemStats();
  res.status(200).json({ success: true, data: stats });
});
