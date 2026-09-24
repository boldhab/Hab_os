import { Router, Request, Response } from 'express';
import prisma from '../../config/db';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';

const router = Router();

router.use(authenticate);

/**
 * GET /api/v1/habits
 */
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;

    const habits = await prisma.habit.findMany({
      where: { userId },
      include: {
        category: true,
        logs: {
          orderBy: { date: 'desc' },
          take: 7,
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return ApiResponse.success(res, habits, 'Habits retrieved');
  })
);

/**
 * POST /api/v1/habits
 */
router.post(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const { name, description, frequency, targetType, targetValue, reminderTime, categoryId } = req.body;

    const habit = await prisma.habit.create({
      data: {
        userId,
        name,
        description: description || null,
        frequency: frequency || 'DAILY',
        targetType: targetType || 'CHECKBOX',
        targetValue: targetValue ? Number(targetValue) : 1,
        reminderTime: reminderTime || null,
        categoryId: categoryId || null,
      },
    });

    return ApiResponse.success(res, habit, 'Habit created', 201);
  })
);

/**
 * POST /api/v1/habits/:id/log
 */
router.post(
  '/:id/log',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const log = await prisma.habitLog.upsert({
      where: {
        habitId_date: {
          habitId: id,
          date: today,
        },
      },
      update: {
        isCompleted: true,
      },
      create: {
        habitId: id,
        date: today,
        isCompleted: true,
        value: 1,
      },
    });

    await prisma.habit.update({
      where: { id },
      data: {
        currentStreak: { increment: 1 },
      },
    });

    return ApiResponse.success(res, log, 'Habit logged');
  })
);

/**
 * DELETE /api/v1/habits/:id
 */
router.delete(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    await prisma.habit.delete({ where: { id } });
    return ApiResponse.success(res, null, 'Habit deleted');
  })
);

export default router;
