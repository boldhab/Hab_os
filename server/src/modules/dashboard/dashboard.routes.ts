import { Router, Request, Response } from 'express';
import prisma from '../../config/db';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import authenticate, { AuthRequest } from '../../middleware/auth';
import cache from '../../utils/cache';

const router = Router();

router.get(
  '/',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const authReq = req as AuthRequest;
    const userId = authReq.user!.id;
    const cacheKey = `dashboard:${userId}`;

    // 1. Check in-memory cache
    const cachedFeed = cache.get(cacheKey);
    if (cachedFeed) {
      res.setHeader('X-Cache', 'HIT');
      return ApiResponse.success(res, cachedFeed, 'Dashboard feed loaded (cached)');
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() - today.getDay());

    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);

    // 2. Execute all 8 aggregation queries concurrently with Promise.all
    const [
      user,
      habits,
      tasks,
      projects,
      workoutsThisWeek,
      transactions,
      budgets,
      latestLifeScore,
    ] = await Promise.all([
      // Query 1: User & Preferences
      prisma.user.findUnique({
        where: { id: userId },
        include: { preferences: true },
      }),

      // Query 2: Active Habits with today's log
      prisma.habit.findMany({
        where: { userId, isActive: true },
        include: {
          logs: {
            where: {
              date: {
                gte: today,
                lt: tomorrow,
              },
            },
          },
        },
      }),

      // Query 3: Tasks Due Today or active
      prisma.task.findMany({
        where: {
          userId,
          OR: [
            { dueDate: { gte: today, lt: tomorrow } },
            { status: { in: ['TODO', 'IN_PROGRESS'] } },
          ],
        },
        include: {
          project: { select: { title: true } },
        },
        take: 10,
      }),

      // Query 4: Recent Projects with counts
      prisma.project.findMany({
        where: { userId },
        include: {
          _count: {
            select: {
              tasks: true,
              features: true,
              bugs: true,
            },
          },
        },
        take: 5,
      }),

      // Query 5: Fitness / Workouts this week
      prisma.workout.findMany({
        where: {
          userId,
          date: { gte: startOfWeek },
          isCompleted: true,
        },
        orderBy: { date: 'desc' },
      }),

      // Query 6: Monthly Expenses
      prisma.transaction.findMany({
        where: {
          userId,
          date: { gte: startOfMonth },
          type: 'EXPENSE',
        },
      }),

      // Query 7: Active Monthly Budgets
      prisma.budget.findMany({
        where: {
          userId,
          month: today.getMonth() + 1,
          year: today.getFullYear(),
        },
      }),

      // Query 8: Latest Life Score Log
      prisma.lifeScoreLog.findFirst({
        where: { userId },
        orderBy: { date: 'desc' },
      }),
    ]);

    // 3. Process Habits
    const habitItems = habits.map((h) => ({
      id: h.id,
      name: h.name,
      frequency: h.frequency,
      currentStreak: h.currentStreak,
      isCompletedToday: h.logs.length > 0 && h.logs[0].isCompleted,
    }));
    const completedHabitsToday = habitItems.filter((h) => h.isCompletedToday).length;

    // 4. Process Tasks
    const taskItems = tasks.map((t) => ({
      id: t.id,
      title: t.title,
      priority: t.priority,
      status: t.status,
      isCompleted: t.isCompleted,
      dueDate: t.dueDate ? t.dueDate.toISOString() : null,
      project: t.project,
    }));

    // 5. Process Workouts
    const latestWorkout = workoutsThisWeek.length > 0 ? workoutsThisWeek[0] : null;
    const workedOutToday = workoutsThisWeek.some((w) => w.date >= today && w.date < tomorrow);

    // 6. Process Finance
    const spentThisMonth = transactions.reduce((acc, curr) => acc + curr.amount, 0);
    const totalBudgetCap = budgets.reduce((acc, curr) => acc + curr.monthlyLimit, 0) || 1000;
    const budgetRemaining = Math.max(0, totalBudgetCap - spentThisMonth);

    // 7. Process Life Score
    const overallScore = latestLifeScore?.overallScore ?? 84.5;
    const level = overallScore >= 80 ? 'Master' : overallScore >= 60 ? 'Achiever' : 'Beginner';

    const feedData = {
      user: {
        name: user?.name || 'Explorer',
        avatarUrl: user?.avatarUrl,
      },
      lifeScore: {
        overallScore,
        level,
        components: [
          { name: 'Tasks', score: latestLifeScore?.taskScore ?? 85, weight: 0.2 },
          { name: 'Coding', score: latestLifeScore?.codingScore ?? 90, weight: 0.2 },
          { name: 'Study', score: latestLifeScore?.studyScore ?? 80, weight: 0.2 },
          { name: 'Gym', score: latestLifeScore?.gymScore ?? 75, weight: 0.2 },
          { name: 'Habits', score: latestLifeScore?.habitScore ?? 92, weight: 0.2 },
        ],
      },
      habits: {
        total: habitItems.length,
        completedToday: completedHabitsToday,
        items: habitItems,
      },
      timeline: {
        tasksDueToday: taskItems,
      },
      projects: projects.map((p) => ({
        id: p.id,
        title: p.title,
        description: p.description,
        status: p.status,
        progress: p.progress,
        _count: p._count,
      })),
      fitness: {
        workoutsThisWeekCount: workoutsThisWeek.length,
        targetWorkouts: user?.preferences?.weeklyGymTarget ?? 4,
        workedOutToday,
        latestWorkout: latestWorkout ? { name: latestWorkout.name } : null,
      },
      finance: {
        spentThisMonth,
        totalBudgetCap,
        budgetRemaining,
        isWarning: spentThisMonth > totalBudgetCap * 0.9,
      },
      aiRecommendation: 'Great momentum today! Stay focused on your primary priorities to maintain your productivity streak.',
      generatedAt: new Date().toISOString(),
    };

    // 8. Cache response for 60 seconds
    cache.set(cacheKey, feedData, 60);
    res.setHeader('X-Cache', 'MISS');

    return ApiResponse.success(res, feedData, 'Dashboard feed loaded');
  })
);

export default router;
