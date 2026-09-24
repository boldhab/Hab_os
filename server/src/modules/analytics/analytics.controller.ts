import { Request, Response } from 'express';
import analyticsService from './analytics.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

export const createTimeEntry = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const entry = await analyticsService.createTimeEntry(authReq.user!.id, req.body);
  return ApiResponse.success(res, entry, 'Time entry recorded successfully', 201);
});

export const getTimeEntries = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await analyticsService.getTimeEntries(authReq.user!.id, req.query);
  return ApiResponse.success(res, result, 'Time entries retrieved successfully');
});

export const deleteTimeEntry = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await analyticsService.deleteTimeEntry(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Time entry deleted successfully');
});

export const getRetrospective = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const report = await analyticsService.getCrossDomainRetrospective(authReq.user!.id);
  return ApiResponse.success(res, report, 'Productivity retrospective report generated');
});

export default {
  createTimeEntry,
  getTimeEntries,
  deleteTimeEntry,
  getRetrospective,
};
