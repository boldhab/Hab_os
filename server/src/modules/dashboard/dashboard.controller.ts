import { Request, Response } from 'express';
import dashboardService from './dashboard.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * @desc    Get complete unified home dashboard feed
 * @route   GET /api/v1/dashboard
 * @access  Private
 */
export const getDashboardFeed = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const feed = await dashboardService.getDashboardFeed(authReq.user!.id);
  return ApiResponse.success(res, feed, 'Dashboard feed retrieved successfully');
});

export default {
  getDashboardFeed,
};
