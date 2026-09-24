import { Router, Request, Response } from 'express';
import prisma from '../../config/db';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';

const router = Router();

router.use(authenticate);

/**
 * GET /api/v1/courses
 */
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;

    const courses = await prisma.course.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    return ApiResponse.success(res, courses, 'Courses retrieved');
  })
);

/**
 * POST /api/v1/courses
 */
router.post(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const { name, code, instructor, semester, credits, color } = req.body;

    const course = await prisma.course.create({
      data: {
        userId,
        name,
        code: code || null,
        instructor: instructor || null,
        semester: semester || 'Current Semester',
        credits: credits ? Number(credits) : 3,
        color: color || '#8B5CF6',
      },
    });

    return ApiResponse.success(res, course, 'Course created', 201);
  })
);

/**
 * DELETE /api/v1/courses/:id
 */
router.delete(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    await prisma.course.delete({ where: { id } });
    return ApiResponse.success(res, null, 'Course deleted');
  })
);

export default router;
