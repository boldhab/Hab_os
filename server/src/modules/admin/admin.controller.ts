import { Request, Response } from 'express';
import asyncHandler from '../../common/asyncHandler';
import adminService from './admin.service';
import auditLogger from './auditLog.service';
import { AuthRequest } from '../../middleware/auth';
import { ADMIN_SECRET_KEY } from '../../middleware/adminAuth';
import authService from '../auth/auth.service';

export const getHealth = asyncHandler(async (_req: Request, res: Response) => {
  const health = await adminService.getSystemHealth();
  res.json({ success: true, data: health });
});

export const getStats = asyncHandler(async (_req: Request, res: Response) => {
  const stats = await adminService.getSystemStats();
  res.json({ success: true, data: stats });
});

export const getUsers = asyncHandler(async (_req: Request, res: Response) => {
  const users = await adminService.getAllUsers();
  res.json({ success: true, count: users.length, data: users });
});

export const updateUserRole = asyncHandler(async (req: Request, res: Response) => {
  const { id } = req.params;
  const { role } = req.body;
  const actor = (req as AuthRequest).user?.email || 'admin';
  const updated = await adminService.updateUserRole(id, role, actor);
  res.json({ success: true, data: updated });
});

export const resetUserPassword = asyncHandler(async (req: Request, res: Response) => {
  const { id } = req.params;
  const { newPassword } = req.body;
  const actor = (req as AuthRequest).user?.email || 'admin';
  const result = await adminService.resetUserPassword(id, newPassword, actor);
  res.json({ success: true, data: result });
});

export const deleteUser = asyncHandler(async (req: Request, res: Response) => {
  const { id } = req.params;
  const actor = (req as AuthRequest).user?.email || 'admin';
  await adminService.deleteUser(id, actor);
  res.json({ success: true, message: 'User deleted successfully' });
});

export const createUser = asyncHandler(async (req: Request, res: Response) => {
  const actor = (req as AuthRequest).user?.email || 'admin';
  const result = await adminService.createUser(req.body, actor);
  res.status(201).json({ success: true, data: result });
});

export const getJobs = asyncHandler(async (_req: Request, res: Response) => {
  const jobs = adminService.getJobsTelemetry();
  res.json({ success: true, data: jobs });
});

export const triggerJob = asyncHandler(async (req: Request, res: Response) => {
  const { jobName } = req.params;
  const actor = (req as AuthRequest).user?.email || 'admin';
  const result = await adminService.triggerJob(jobName, actor);
  res.json({ success: result.success, data: result });
});

export const toggleScheduler = asyncHandler(async (req: Request, res: Response) => {
  const { enabled } = req.body;
  const actor = (req as AuthRequest).user?.email || 'admin';
  const result = adminService.toggleScheduler(Boolean(enabled), actor);
  res.json({ success: true, data: result });
});

export const getLogs = asyncHandler(async (req: Request, res: Response) => {
  const { level, search, limit } = req.query;
  const logs = auditLogger.getLogs({
    level: level as string,
    search: search as string,
    limit: limit ? parseInt(limit as string, 10) : undefined,
  });
  res.json({ success: true, count: logs.length, data: logs });
});

export const clearLogs = asyncHandler(async (_req: Request, res: Response) => {
  auditLogger.clear();
  res.json({ success: true, message: 'Audit logs buffer cleared' });
});

export const getConfig = asyncHandler(async (_req: Request, res: Response) => {
  const config = adminService.getRuntimeConfig();
  res.json({ success: true, data: config });
});

export const updateConfig = asyncHandler(async (req: Request, res: Response) => {
  const actor = (req as AuthRequest).user?.email || 'admin';
  const updated = adminService.updateRuntimeConfig(req.body, actor);
  res.json({ success: true, data: updated });
});

export const flushCache = asyncHandler(async (req: Request, res: Response) => {
  const actor = (req as AuthRequest).user?.email || 'admin';
  const result = adminService.flushCache(actor);
  res.json({ success: true, data: result });
});

export const pingDatabase = asyncHandler(async (_req: Request, res: Response) => {
  const status = await adminService.getDatabaseStatus();
  res.json({ success: true, data: status });
});

export const adminLogin = asyncHandler(async (req: Request, res: Response) => {
  const { secretKey, email, password } = req.body;

  if (secretKey && secretKey === ADMIN_SECRET_KEY) {
    auditLogger.log({
      level: 'SECURITY',
      category: 'AUTH',
      message: 'Admin session authenticated via Master Admin Key',
      user: 'admin-key-holder',
    });
    return res.json({
      success: true,
      data: {
        token: 'admin-master-session-token',
        user: {
          id: 'admin-master-id',
          name: 'Root Administrator',
          email: 'admin@habos.dev',
          role: 'ADMIN',
        },
      },
    });
  }

  if (email && password) {
    const result = await authService.login({ email, password });
    auditLogger.log({
      level: 'SECURITY',
      category: 'AUTH',
      message: `Admin session authenticated via user credentials (${email})`,
      user: email,
    });
    return res.json({ success: true, data: result });
  }

  res.status(401).json({
    success: false,
    message: 'Invalid administrative credentials or secret key',
  });
});
