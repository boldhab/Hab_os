import { Router, Request, Response } from 'express';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';

const router = Router();

router.use(authenticate);

/**
 * GET /api/v1/analytics/retrospective
 */
router.get(
  '/retrospective',
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;

    const retrospective = {
      period: 'THIS_WEEK',
      overallProductivityScore: 86.4,
      totalHoursInvested: 32.5,
      tasksCompletedCount: 14,
      habitsConsistencyRate: 0.92,
      topLifeDomains: [
        { name: 'Coding & Engineering', score: 94 },
        { name: 'University Study', score: 88 },
        { name: 'Fitness & Health', score: 82 },
      ],
      aiInsights: [
        'Your deep work focus was strongest between 09:00 - 12:00.',
        'You maintained a 100% completion rate on your primary habits this week!',
      ],
    };

    return ApiResponse.success(res, retrospective, 'Analytics retrospective retrieved');
  })
);

/**
 * GET /api/v1/analytics
 */
router.get(
  '/',
  asyncHandler(async (_req: Request, res: Response) => {
    return ApiResponse.success(res, { status: 'ok' }, 'Analytics summary');
  })
);

export default router;
