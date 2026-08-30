import prisma from '../../config/db';
import lifeScoreService from '../lifescore/lifescore.service';
import aiService from '../ai/ai.service';

interface CachedFeed {
  data: any;
  expiresAt: number;
}

const FEED_CACHE_TTL_MS = 60 * 1000; // 60-second TTL
const dashboardCache = new Map<string, CachedFeed>();

/**
 * Invalidate in-memory dashboard feed cache for a specific user or globally.
 * Architectural Pattern: Any write/mutation function that modifies domain data rendered 
 * on the home dashboard (Tasks, Habits, Focus Sessions, Gym Workouts, Projects, Goals, 
 * Academic Assignments, Finance Transactions) MUST call `invalidateDashboardCache(userId)` 
 * to ensure zero-stale instant UX updates.
 */
export const invalidateDashboardCache = (userId?: string) => {
  if (userId) {
    dashboardCache.delete(userId);
  } else {
    dashboardCache.clear();
  }
};

/**
 * UC-06, UC-07: Get Unified Home Dashboard Feed (with 60s TTL in-memory caching)
 */
export const getDashboardFeed = async (userId: string, bypassCache = false) => {
  const cached = dashboardCache.get(userId);
  if (!bypassCache && cached && cached.expiresAt > Date.now()) {
    return cached.data;
  }

  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

  const dayOfWeek = now.getDay();
  const diffToMonday = now.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1);
  const startOfWeek = new Date(now.setDate(diffToMonday));
  startOfWeek.setHours(0, 0, 0, 0);

  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);
  const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);

  // Concurrently fetch all dashboard cards
  const [
    user,
    lifeScore,
    scheduleEventsToday,
    tasksDueToday,
    habits,
    activeProjects,
    upcomingAssignments,
    upcomingExams,
    workoutsThisWeek,
    monthExpenses,
    budgets,
    aiRecommendation,
  ] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, name: true, avatarUrl: true, preferences: true },
    }),
    lifeScoreService.calculateLifeScore(userId),
    prisma.scheduleEvent.findMany({
      where: {
        userId,
        startTime: { lte: endOfToday },
        endTime: { gte: startOfToday },
      },
      orderBy: { startTime: 'asc' },
    }),
    prisma.task.findMany({
      where: {
        userId,
        dueDate: { gte: startOfToday, lte: endOfToday },
      },
      orderBy: [{ isCompleted: 'asc' }, { priority: 'desc' }],
      include: {
        project: { select: { id: true, title: true, color: true } },
      },
    }),
    prisma.habit.findMany({
      where: { userId, isActive: true },
      orderBy: [{ currentStreak: 'desc' }],
      include: {
        logs: {
          where: { date: { gte: startOfToday, lte: endOfToday } },
          take: 1,
        },
      },
    }),
    prisma.project.findMany({
      where: { userId, status: 'IN_PROGRESS' },
      take: 4,
      orderBy: { updatedAt: 'desc' },
      include: {
        _count: { select: { features: true, bugs: true, tasks: true } },
      },
    }),
    prisma.assignment.findMany({
      where: {
        course: { userId },
        dueDate: { gte: now },
        status: { notIn: ['SUBMITTED', 'GRADED'] },
      },
      orderBy: { dueDate: 'asc' },
      take: 3,
      include: { course: { select: { name: true, color: true } } },
    }),
    prisma.exam.findMany({
      where: {
        course: { userId },
        examDate: { gte: now },
      },
      orderBy: { examDate: 'asc' },
      take: 2,
      include: { course: { select: { name: true, color: true } } },
    }),
    prisma.workout.findMany({
      where: { userId, date: { gte: startOfWeek } },
      orderBy: { date: 'desc' },
    }),
    prisma.transaction.aggregate({
      where: { userId, type: 'EXPENSE', date: { gte: startOfMonth, lte: endOfMonth } },
      _sum: { amount: true },
    }),
    prisma.budget.findMany({
      where: { userId },
    }),
    aiService.recommendNextAction(userId),
  ]);

  // Format Habits Checklist
  const habitItems = habits.map((h) => ({
    id: h.id,
    name: h.name,
    frequency: h.frequency,
    currentStreak: h.currentStreak,
    isCompletedToday: h.logs.length > 0 && h.logs[0].isCompleted,
  }));

  // Gym weekly status
  const targetGymWorkouts = user?.preferences?.weeklyGymTarget || 4;
  const workedOutToday = workoutsThisWeek.some((w) => {
    const wDate = new Date(w.date);
    return wDate >= startOfToday && wDate <= endOfToday;
  });

  // Finance summary
  const spentThisMonth = monthExpenses._sum.amount || 0;
  const totalBudgetCap = budgets.reduce((sum, b) => sum + b.monthlyLimit, 0);
  const budgetRemaining = Math.max(0, totalBudgetCap - spentThisMonth);

  const feed = {
    user: {
      name: user?.name || 'User',
      email: user?.email,
      avatarUrl: user?.avatarUrl,
    },
    lifeScore: {
      overallScore: lifeScore.overallScore,
      level: lifeScore.level,
      components: lifeScore.components,
    },
    timeline: {
      scheduleEvents: scheduleEventsToday,
      tasksDueToday,
    },
    habits: {
      total: habitItems.length,
      completedToday: habitItems.filter((h) => h.isCompletedToday).length,
      items: habitItems,
    },
    projects: activeProjects,
    academics: {
      upcomingAssignments,
      upcomingExams,
    },
    fitness: {
      workoutsThisWeekCount: workoutsThisWeek.length,
      targetWorkouts: targetGymWorkouts,
      workedOutToday,
      latestWorkout: workoutsThisWeek[0] || null,
    },
    finance: {
      spentThisMonth,
      totalBudgetCap,
      budgetRemaining,
      isWarning: totalBudgetCap > 0 && (spentThisMonth / totalBudgetCap) >= 0.8,
    },
    aiRecommendation,
    generatedAt: new Date(),
  };

  dashboardCache.set(userId, {
    data: feed,
    expiresAt: Date.now() + FEED_CACHE_TTL_MS,
  });

  return feed;
};

export default {
  getDashboardFeed,
  invalidateDashboardCache,
};
