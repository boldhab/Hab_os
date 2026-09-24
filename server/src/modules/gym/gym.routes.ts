import { Router, Request, Response } from 'express';
import * as gymController from './gym.controller';
import gymService from './gym.service';
import { authenticate, AuthRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import {
  createWorkoutSchema,
  updateWorkoutSchema,
  createExerciseSchema,
  addExerciseToWorkoutSchema,
  recordSetSchema,
  recordBodyMetricSchema,
  uuidParamSchema,
} from './gym.validation';

const router = Router();

// All gym routes require authentication
router.use(authenticate);

// --- Analytics & Insights ---
router.get('/analytics', gymController.getGymAnalytics);

router.get(
  '/stats',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const stats = await gymService.getGymStats(authReq.user!.id);
    return ApiResponse.success(res, stats, 'Gym statistics retrieved');
  })
);

router.get(
  '/insights',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const insights = await gymService.getGymInsights(authReq.user!.id);
    return ApiResponse.success(res, insights, 'Training insights retrieved');
  })
);

router.get(
  '/prs',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const prs = await gymService.getPersonalRecords(authReq.user!.id);
    return ApiResponse.success(res, prs, 'Personal records retrieved');
  })
);

// --- Templates ---
router.get(
  '/templates',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const templates = await gymService.getTemplates(authReq.user!.id);
    return ApiResponse.success(res, templates, 'Workout templates retrieved');
  })
);

router.post(
  '/templates',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const template = await gymService.createTemplate(authReq.user!.id, req.body);
    return ApiResponse.success(res, template, 'Workout template created', 201);
  })
);

router.get(
  '/templates/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const template = await gymService.getTemplateById(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, template, 'Workout template retrieved');
  })
);

router.delete(
  '/templates/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await gymService.deleteTemplate(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, null, 'Workout template deleted');
  })
);

// --- Exercises ---
router.post('/exercises', validate(createExerciseSchema), gymController.createExercise);
router.get('/exercises', gymController.getExercises);

router.get(
  '/exercises/:id/history',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const history = await gymService.getExerciseHistory(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, history, 'Exercise history retrieved');
  })
);

// --- Body Metrics ---
router.post('/metrics', validate(recordBodyMetricSchema), gymController.recordBodyMetric);
router.get('/metrics', gymController.getBodyMetrics);
router.post('/body-metrics', validate(recordBodyMetricSchema), gymController.recordBodyMetric);
router.get('/body-metrics', gymController.getBodyMetrics);

router.delete(
  '/body-metrics/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    await gymService.deleteBodyMetric(authReq.user!.id, req.params.id);
    return ApiResponse.success(res, null, 'Body metric deleted');
  })
);

// --- Workouts ---
router.post('/', validate(createWorkoutSchema), gymController.createWorkout);
router.post('/workouts', validate(createWorkoutSchema), gymController.createWorkout);

router.get('/', gymController.getWorkouts);
router.get('/workouts', gymController.getWorkouts);

router.get('/:id', validate(uuidParamSchema, 'params'), gymController.getWorkoutById);
router.get('/workouts/:id', validate(uuidParamSchema, 'params'), gymController.getWorkoutById);

router.put(
  '/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateWorkoutSchema),
  gymController.updateWorkout
);
router.patch(
  '/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateWorkoutSchema),
  gymController.updateWorkout
);
router.put(
  '/workouts/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateWorkoutSchema),
  gymController.updateWorkout
);
router.patch(
  '/workouts/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateWorkoutSchema),
  gymController.updateWorkout
);

router.delete('/:id', validate(uuidParamSchema, 'params'), gymController.deleteWorkout);
router.delete('/workouts/:id', validate(uuidParamSchema, 'params'), gymController.deleteWorkout);

// --- Exercises in Workout & Sets ---
router.post(
  '/:id/exercises',
  validate(uuidParamSchema, 'params'),
  validate(addExerciseToWorkoutSchema),
  gymController.addExerciseToWorkout
);

router.post(
  '/exercises/:workoutExerciseId/sets',
  validate(recordSetSchema),
  gymController.recordSet
);

export default router;
