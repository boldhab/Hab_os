import { Router } from 'express';
import requireAdmin from '../../middleware/adminAuth';
import * as adminController from './admin.controller';

const router = Router();

// Public Admin Login / Session handshake
router.post('/login', adminController.adminLogin);

// Protected Admin Endpoints
router.use(requireAdmin);

// System Health & Telemetry
router.get('/health', adminController.getHealth);
router.get('/stats', adminController.getStats);

// User Management
router.get('/users', adminController.getUsers);
router.post('/users', adminController.createUser);
router.patch('/users/:id/role', adminController.updateUserRole);
router.post('/users/:id/reset-password', adminController.resetUserPassword);
router.delete('/users/:id', adminController.deleteUser);

// Background Worker Engine & Jobs
router.get('/jobs', adminController.getJobs);
router.post('/jobs/:jobName/run', adminController.triggerJob);
router.post('/jobs/toggle', adminController.toggleScheduler);

// Audit & Security Logs
router.get('/logs', adminController.getLogs);
router.post('/logs/clear', adminController.clearLogs);

// Runtime Configuration & Domain Weights
router.get('/config', adminController.getConfig);
router.put('/config', adminController.updateConfig);

// Maintenance & Diagnostics
router.post('/maintenance/cache-clear', adminController.flushCache);
router.get('/maintenance/db-ping', adminController.pingDatabase);

export default router;
