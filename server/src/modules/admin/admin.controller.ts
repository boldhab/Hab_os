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

export const getJobs = asyncHandler(async (_req: Request, res: Response) => {
  const telemetry = adminService.getJobsTelemetry();
  res.status(200).json({ success: true, data: telemetry });
});

export const runJob = asyncHandler(async (req: Request, res: Response) => {
  const { jobName } = req.params;
  const actor = (req as any).user?.email || 'admin';
  const result = await adminService.triggerJob(jobName, actor);
  res.status(200).json({ success: true, data: result });
});
