import { Request, Response } from 'express';
import scheduleService from './schedule.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

/**
 * @desc    Create a new schedule event
 * @route   POST /api/v1/schedule
 * @access  Private
 */
export const createEvent = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await scheduleService.createEvent(authReq.user!.id, req.body);
  return ApiResponse.success(res, result, 'Schedule event created', 201);
});

/**
 * @desc    Get daily schedule timeline
 * @route   GET /api/v1/schedule/daily
 * @access  Private
 */
export const getDailySchedule = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { date } = req.query;
  const result = await scheduleService.getDailySchedule(authReq.user!.id, date as string);
  return ApiResponse.success(res, result, 'Daily schedule retrieved');
});

/**
 * @desc    Get weekly schedule overview
 * @route   GET /api/v1/schedule/weekly
 * @access  Private
 */
export const getWeeklySchedule = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { startDate } = req.query;
  const result = await scheduleService.getWeeklySchedule(authReq.user!.id, startDate as string);
  return ApiResponse.success(res, result, 'Weekly schedule retrieved');
});

/**
 * @desc    Get single event by ID
 * @route   GET /api/v1/schedule/:id
 * @access  Private
 */
export const getEventById = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const event = await scheduleService.getEventById(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, event, 'Event retrieved');
});

/**
 * @desc    Update a schedule event
 * @route   PUT /api/v1/schedule/:id
 * @access  Private
 */
export const updateEvent = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await scheduleService.updateEvent(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, result, 'Event updated');
});

/**
 * @desc    Delete a schedule event
 * @route   DELETE /api/v1/schedule/:id
 * @access  Private
 */
export const deleteEvent = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await scheduleService.deleteEvent(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Event deleted');
});

export default {
  createEvent,
  getDailySchedule,
  getWeeklySchedule,
  getEventById,
  updateEvent,
  deleteEvent,
};
