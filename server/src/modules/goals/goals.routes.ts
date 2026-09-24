import { Router, Request, Response } from 'express';
import prisma from '../../config/db';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';

const router = Router();

router.use(authenticate);

/**
 * GET /api/v1/goals
 */
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;

    const goals = await prisma.goal.findMany({
      where: { userId },
      include: {
        milestones: true,
        tasks: { select: { id: true, title: true, isCompleted: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return ApiResponse.success(res, goals, 'Goals retrieved');
  })
);

/**
 * POST /api/v1/goals
 */
router.post(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const { title, description, category, targetDate, priority } = req.body;

    const goal = await prisma.goal.create({
      data: {
        userId,
        title,
        description: description || null,
        category: category || 'PERSONAL',
        targetDate: targetDate ? new Date(targetDate) : null,
        priority: priority || 'MEDIUM',
        progress: 0.0,
      },
    });

    return ApiResponse.success(res, goal, 'Goal created', 201);
  })
);

/**
 * PATCH /api/v1/goals/:id
 */
router.patch(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const { title, description, progress, status, priority, targetDate } = req.body;

    const updateData: any = {};
    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;
    if (progress !== undefined) updateData.progress = Number(progress);
    if (status !== undefined) updateData.status = status;
    if (priority !== undefined) updateData.priority = priority;
    if (targetDate !== undefined) updateData.targetDate = targetDate ? new Date(targetDate) : null;

    const goal = await prisma.goal.update({
      where: { id },
      data: updateData,
    });

    return ApiResponse.success(res, goal, 'Goal updated');
  })
);

/**
 * DELETE /api/v1/goals/:id
 */
router.delete(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    await prisma.goal.delete({ where: { id } });
    return ApiResponse.success(res, null, 'Goal deleted');
  })
);

export default router;
