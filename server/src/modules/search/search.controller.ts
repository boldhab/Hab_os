import { Request, Response } from 'express';
import searchService from './search.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * @desc    Global omni-search across all domains
 * @route   GET /api/v1/search
 * @access  Private
 */
export const searchGlobal = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { q, domain, limit } = req.query;
  const result = await searchService.searchGlobal(authReq.user!.id, {
    q: q as string,
    domain: domain as 'ALL',
    limit: limit ? parseInt(limit as string) : 10,
  });
  return ApiResponse.success(res, result, 'Search results retrieved');
});

export default {
  searchGlobal,
};
