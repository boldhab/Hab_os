import { Request, Response } from 'express';
import analyticsService from './analytics.service';
import { generateAnalyticsCsv, generateAnalyticsPdf } from './engines/report_generator';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

export const createTimeEntry = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const entry = await analyticsService.createTimeEntry(authReq.user!.id, req.body);
  return ApiResponse.success(res, entry, 'Time entry recorded successfully', 201);
});

export const updateTimeEntry = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const entry = await analyticsService.updateTimeEntry(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, entry, 'Time entry updated successfully');
});

export const stopTimeEntry = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const entry = await analyticsService.stopTimeEntry(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, entry, 'Active time entry stopped successfully');
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
  const period = ((req.query.period as string) || 'WEEKLY').toUpperCase() as 'WEEKLY' | 'MONTHLY';
  const timezone =
    (req.query.timezone as string) ||
    (req.headers['x-timezone'] as string) ||
    authReq.user?.timezone ||
    'UTC';

  const report = await analyticsService.getCrossDomainRetrospective(authReq.user!.id, period, timezone);
  return ApiResponse.success(res, report, 'Productivity retrospective report generated');
});

export const exportCsv = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const period = ((req.query.period as string) || 'WEEKLY').toUpperCase() as 'WEEKLY' | 'MONTHLY';
  const timezone =
    (req.query.timezone as string) ||
    (req.headers['x-timezone'] as string) ||
    authReq.user?.timezone ||
    'UTC';

  const report = await analyticsService.getCrossDomainRetrospective(authReq.user!.id, period, timezone);
  const csvData = generateAnalyticsCsv(report);

  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader(
    'Content-Disposition',
    `attachment; filename="habos-retrospective-${period.toLowerCase()}-${new Date().toISOString().split('T')[0]}.csv"`
  );
  return res.status(200).send(csvData);
});

export const exportPdf = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const period = ((req.query.period as string) || 'WEEKLY').toUpperCase() as 'WEEKLY' | 'MONTHLY';
  const timezone =
    (req.query.timezone as string) ||
    (req.headers['x-timezone'] as string) ||
    authReq.user?.timezone ||
    'UTC';

  const report = await analyticsService.getCrossDomainRetrospective(authReq.user!.id, period, timezone);
  const pdfBuffer = generateAnalyticsPdf(report);

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader(
    'Content-Disposition',
    `attachment; filename="habos-retrospective-${period.toLowerCase()}-${new Date().toISOString().split('T')[0]}.pdf"`
  );
  return res.status(200).send(pdfBuffer);
});

export default {
  createTimeEntry,
  updateTimeEntry,
  stopTimeEntry,
  getTimeEntries,
  deleteTimeEntry,
  getRetrospective,
  exportCsv,
  exportPdf,
};
