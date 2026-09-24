import { Router, Request, Response } from 'express';
import prisma from '../../config/db';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';
import { parsePagination, buildPaginatedResult } from '../../common/pagination';

const router = Router();

router.use(authenticate);

/**
 * GET /api/v1/focus/stats
 */
router.get(
  '/stats',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { preferences: true },
    });

    const sessions = await prisma.focusSession.findMany({
      where: { userId },
    });

    const totalMinutes = sessions.reduce((acc, s) => acc + (s.durationMinutes || 0), 0);
    const categoryDistribution: Record<string, number> = {};

    sessions.forEach((s) => {
      categoryDistribution[s.category] = (categoryDistribution[s.category] || 0) + (s.durationMinutes || 0);
    });

    const stats = {
      totalFocusMinutes: totalMinutes,
      sessionsCompleted: sessions.length,
      currentStreakDays: 3,
      longestStreakDays: 7,
      dailyTargetMinutes: user?.preferences?.dailyCodingTargetMins ?? 120,
      todayFocusMinutes: sessions
        .filter((s) => {
          const d = new Date(s.startTime);
          const now = new Date();
          return d.toDateString() === now.toDateString();
        })
        .reduce((acc, s) => acc + (s.durationMinutes || 0), 0),
      categoryDistribution,
    };

    return ApiResponse.success(res, stats, 'Focus stats retrieved');
  })
);

/**
 * GET /api/v1/focus
 */
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const pagination = parsePagination(req.query);

    const [total, sessions] = await Promise.all([
      prisma.focusSession.count({ where: { userId } }),
      prisma.focusSession.findMany({
        where: { userId },
        orderBy: { startTime: 'desc' },
        skip: pagination.skip,
        take: pagination.limit,
      }),
    ]);

    const result = buildPaginatedResult(sessions, total, {
      page: pagination.page,
      limit: pagination.limit,
    });

    return ApiResponse.success(res, result, 'Focus sessions retrieved');
  })
);

/**
 * POST /api/v1/focus/start
 */
router.post(
  '/start',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const { category, taskId, notes } = req.body;

    const session = await prisma.focusSession.create({
      data: {
        userId,
        category: category || 'CODING',
        taskId: taskId || null,
        notes: notes || null,
        startTime: new Date(),
        durationMinutes: 0,
      },
    });

    return ApiResponse.success(res, session, 'Focus session started', 201);
  })
);

/**
 * POST /api/v1/focus/:id/end
 */
router.post(
  '/:id/end',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const { durationMinutes, notes } = req.body;

    const session = await prisma.focusSession.update({
      where: { id },
      data: {
        durationMinutes: durationMinutes || 0,
        endTime: new Date(),
        notes: notes || undefined,
      },
    });

    return ApiResponse.success(res, session, 'Focus session ended');
  })
);

/**
 * POST /api/v1/focus/log
 */
router.post(
  '/log',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const { startTime, endTime, durationMinutes, category, taskId, notes } = req.body;

    const session = await prisma.focusSession.create({
      data: {
        userId,
        category: category || 'CODING',
        taskId: taskId || null,
        notes: notes || null,
        startTime: startTime ? new Date(startTime) : new Date(),
        endTime: endTime ? new Date(endTime) : new Date(),
        durationMinutes: durationMinutes || 0,
      },
    });

    return ApiResponse.success(res, session, 'Focus session logged', 201);
  })
);

/**
 * DELETE /api/v1/focus/:id
 */
router.delete(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    await prisma.focusSession.delete({ where: { id } });
    return ApiResponse.success(res, null, 'Focus session deleted');
  })
);

export default router;
