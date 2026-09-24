import { Router, Request, Response } from 'express';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';
import gymService from './gym.service';

const router = Router();

router.use(authenticate);

// ==========================================
// 1. WORKOUTS (Transactional Logging & Query)
// ==========================================

/**
 * GET /api/v1/gym/workouts
 * (Also supports GET /api/v1/gym)
 */
router.get(
  ['/', '/workouts'],
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const result = await gymService.getWorkouts(authReq.user!.id, req.query);
    return ApiResponse.success(res, result, 'Workouts retrieved');
  })
);

/**
 * POST /api/v1/gym/workouts
 * (Also supports POST /api/v1/gym)
 */
router.post(
  ['/', '/workouts'],
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const workout = await gymService.logWorkout(authReq.user!.id, req.body);
    return ApiResponse.success(res, workout, 'Workout logged successfully', 201);
  })
);

/**
 * GET /api/v1/gym/workouts/:id
 */
router.get(
  '/workouts/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const workout = await gymService.getWorkoutById(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, workout, 'Workout retrieved');
  })
);

/**
 * DELETE /api/v1/gym/workouts/:id
 * (Also supports DELETE /api/v1/gym/:id)
 */
router.delete(
  ['/:id', '/workouts/:id'],
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await gymService.deleteWorkout(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, null, 'Workout deleted');
  })
);

// ==========================================
// 2. EXERCISE CATALOG & PROGRESSION HISTORY
// ==========================================

/**
 * GET /api/v1/gym/exercises
 */
router.get(
  '/exercises',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const exercises = await gymService.getExercises(authReq.user!.id, req.query);
    return ApiResponse.success(res, exercises, 'Exercises retrieved');
  })
);

/**
 * POST /api/v1/gym/exercises
 */
router.post(
  '/exercises',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const exercise = await gymService.createExercise(authReq.user!.id, req.body);
    return ApiResponse.success(res, exercise, 'Custom exercise created', 201);
  })
);

/**
 * GET /api/v1/gym/exercises/:id/history
 */
router.get(
  '/exercises/:id/history',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const history = await gymService.getExerciseHistory(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, history, 'Exercise history retrieved');
  })
);

// ==========================================
// 3. PERSONAL RECORDS & PROGRESSIVE OVERLOAD
// ==========================================

/**
 * GET /api/v1/gym/prs
 */
router.get(
  '/prs',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const prs = await gymService.getPersonalRecords(authReq.user!.id);
    return ApiResponse.success(res, prs, 'Personal records retrieved');
  })
);

/**
 * GET /api/v1/gym/stats
 */
router.get(
  '/stats',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const stats = await gymService.getGymStats(authReq.user!.id);
    return ApiResponse.success(res, stats, 'Gym statistics retrieved');
  })
);

/**
 * GET /api/v1/gym/insights
 */
router.get(
  '/insights',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const insights = await gymService.getGymInsights(authReq.user!.id);
    return ApiResponse.success(res, insights, 'Training insights retrieved');
  })
);

// ==========================================
// 4. WORKOUT TEMPLATES & ROUTINES
// ==========================================

/**
 * GET /api/v1/gym/templates
 */
router.get(
  '/templates',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const templates = await gymService.getTemplates(authReq.user!.id);
    return ApiResponse.success(res, templates, 'Workout templates retrieved');
  })
);

/**
 * POST /api/v1/gym/templates
 */
router.post(
  '/templates',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const template = await gymService.createTemplate(authReq.user!.id, req.body);
    return ApiResponse.success(res, template, 'Workout template created', 201);
  })
);

/**
 * GET /api/v1/gym/templates/:id
 */
router.get(
  '/templates/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const template = await gymService.getTemplateById(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, template, 'Workout template retrieved');
  })
);

/**
 * DELETE /api/v1/gym/templates/:id
 */
router.delete(
  '/templates/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await gymService.deleteTemplate(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, null, 'Workout template deleted');
  })
);

// ==========================================
// 5. BODY METRICS & 7-DAY MOVING AVERAGE
// ==========================================

/**
 * GET /api/v1/gym/body-metrics
 */
router.get(
  '/body-metrics',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const metrics = await gymService.getBodyMetrics(authReq.user!.id);
    return ApiResponse.success(res, metrics, 'Body metrics retrieved');
  })
);

/**
 * POST /api/v1/gym/body-metrics
 */
router.post(
  '/body-metrics',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const metric = await gymService.logBodyMetric(authReq.user!.id, req.body);
    return ApiResponse.success(res, metric, 'Body metric logged', 201);
  })
);

/**
 * DELETE /api/v1/gym/body-metrics/:id
 */
router.delete(
  '/body-metrics/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await gymService.deleteBodyMetric(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, null, 'Body metric deleted');
  })
);

export default router;
