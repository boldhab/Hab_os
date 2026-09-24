import { Request, Response } from 'express';
import notificationsService from './notifications.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * @desc    Get user notifications
 * @route   GET /api/v1/notifications
 * @access  Private
 */
export const getNotifications = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const unreadOnly = req.query.unreadOnly === 'true';
  const limit = req.query.limit ? parseInt(req.query.limit as string) : 50;
  const notifications = await notificationsService.getNotifications(authReq.user!.id, unreadOnly, limit);
  return ApiResponse.success(res, notifications, 'Notifications retrieved');
});

/**
 * @desc    Get unread notifications badge count
 * @route   GET /api/v1/notifications/unread-count
 * @access  Private
 */
export const getUnreadCount = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const count = await notificationsService.getUnreadCount(authReq.user!.id);
  return ApiResponse.success(res, count, 'Unread notification count retrieved');
});

/**
 * @desc    Create a notification manually
 * @route   POST /api/v1/notifications
 * @access  Private
 */
export const createNotification = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const notification = await notificationsService.createNotification(authReq.user!.id, req.body);
  return ApiResponse.success(res, notification, 'Notification created successfully', 201);
});

/**
 * @desc    Generate contextual alerts from impending deadlines, exams, and streak risks
 * @route   POST /api/v1/notifications/generate-alerts
 * @access  Private
 */
export const generateAlerts = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await notificationsService.generateContextualAlerts(authReq.user!.id);
  return ApiResponse.success(res, result, 'Contextual alerts generated');
});

/**
 * @desc    Mark a notification as read
 * @route   PATCH /api/v1/notifications/:id/read
 * @access  Private
 */
export const markAsRead = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const notification = await notificationsService.markAsRead(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, notification, 'Notification marked as read');
});

/**
 * @desc    Mark all notifications as read
 * @route   PATCH /api/v1/notifications/read-all
 * @access  Private
 */
export const markAllAsRead = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await notificationsService.markAllAsRead(authReq.user!.id);
  return ApiResponse.success(res, result, 'All notifications marked as read');
});

/**
 * @desc    Delete a notification
 * @route   DELETE /api/v1/notifications/:id
 * @access  Private
 */
export const deleteNotification = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await notificationsService.deleteNotification(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Notification deleted successfully');
});

/**
 * @desc    Clear all notifications
 * @route   DELETE /api/v1/notifications
 * @access  Private
 */
export const clearAllNotifications = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await notificationsService.clearAllNotifications(authReq.user!.id);
  return ApiResponse.success(res, result, 'All notifications cleared');
});

export default {
  getNotifications,
  getUnreadCount,
  createNotification,
  generateAlerts,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearAllNotifications,
};
