import { Request, Response } from 'express';
import gymService from './gym.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

// --- WORKOUTS ---

export const createWorkout = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const workout = await gymService.createWorkout(authReq.user!.id, req.body);
  return ApiResponse.success(res, workout, 'Workout created successfully', 201);
});

export const getWorkouts = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const limit = req.query.limit ? parseInt(req.query.limit as string) : 20;
  const workouts = await gymService.getWorkouts(authReq.user!.id, limit);
  return ApiResponse.success(res, workouts, 'Workouts retrieved successfully');
});

export const getWorkoutById = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const workout = await gymService.getWorkoutById(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, workout, 'Workout retrieved successfully');
});

export const updateWorkout = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const workout = await gymService.updateWorkout(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, workout, 'Workout updated successfully');
});

export const deleteWorkout = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await gymService.deleteWorkout(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Workout deleted successfully');
});

// --- EXERCISES & SETS ---

export const createExercise = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const exercise = await gymService.createExercise(authReq.user!.id, req.body);
  return ApiResponse.success(res, exercise, 'Exercise registered successfully', 201);
});

export const getExercises = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { category } = req.query;
  const exercises = await gymService.getExercises(authReq.user!.id, category as string);
  return ApiResponse.success(res, exercises, 'Exercises retrieved successfully');
});

export const addExerciseToWorkout = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const workout = await gymService.addExerciseToWorkout(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, workout, 'Exercise added to workout', 201);
});

export const recordSet = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await gymService.recordSet(authReq.user!.id, req.params.workoutExerciseId, req.body);
  return ApiResponse.success(res, result, 'Set recorded successfully', 201);
});

// --- BODY METRICS & ANALYTICS ---

export const recordBodyMetric = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const metric = await gymService.recordBodyMetric(authReq.user!.id, req.body);
  return ApiResponse.success(res, metric, 'Body metric recorded successfully', 201);
});

export const getBodyMetrics = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const limit = req.query.limit ? parseInt(req.query.limit as string) : 30;
  const metrics = await gymService.getBodyMetrics(authReq.user!.id, limit);
  return ApiResponse.success(res, metrics, 'Body metrics retrieved successfully');
});

export const getGymAnalytics = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const analytics = await gymService.getGymAnalytics(authReq.user!.id);
  return ApiResponse.success(res, analytics, 'Gym analytics retrieved successfully');
});

export default {
  createWorkout,
  getWorkouts,
  getWorkoutById,
  updateWorkout,
  deleteWorkout,
  createExercise,
  getExercises,
  addExerciseToWorkout,
  recordSet,
  recordBodyMetric,
  getBodyMetrics,
  getGymAnalytics,
};
