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
  const utcYear = now.getUTCFullYear();
  const utcMonth = now.getUTCMonth();
  const utcDate = now.getUTCDate();
  const startOfToday = new Date(Date.UTC(utcYear, utcMonth, utcDate, 0, 0, 0, 0));
  const endOfToday = new Date(Date.UTC(utcYear, utcMonth, utcDate, 23, 59, 59, 999));

  const dayOfWeek = now.getUTCDay();
  const daysFromMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
  const startOfWeek = new Date(startOfToday);
  startOfWeek.setUTCDate(startOfWeek.getUTCDate() - daysFromMonday);

  const startOfMonth = new Date(Date.UTC(utcYear, utcMonth, 1, 0, 0, 0, 0));
  const startOfNextMonth = new Date(Date.UTC(utcYear, utcMonth + 1, 1, 0, 0, 0, 0));

  // Concurrently fetch all dashboard cards and domain activities
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
    recentTransactions,
    recentFocusSessions,
    recentCompletedTasks,
    recentHabitLogs,
    recentWorkouts,
    recentStudySessions,
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
      take: 4,
      include: { course: { select: { id: true, name: true, code: true, color: true } } },
    }),
    prisma.exam.findMany({
      where: {
        course: { userId },
        examDate: { gte: now },
      },
      orderBy: { examDate: 'asc' },
      take: 4,
      include: { course: { select: { id: true, name: true, code: true, color: true } } },
    }),
    prisma.workout.findMany({
      where: { userId, date: { gte: startOfWeek, lte: now } },
      orderBy: { date: 'desc' },
    }),
    prisma.transaction.aggregate({
      where: { userId, type: 'EXPENSE', date: { gte: startOfMonth, lt: startOfNextMonth } },
      _sum: { amount: true },
    }),
    prisma.budget.findMany({
      where: { userId, month: utcMonth + 1, year: utcYear },
    }),
    aiService.recommendNextAction(userId),
    // Recent domain events for unified activity stream
    prisma.transaction.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      take: 5,
      include: { category: { select: { name: true, icon: true, color: true } } },
    }),
    prisma.focusSession.findMany({
      where: { userId, status: 'COMPLETED' },
      orderBy: { startTime: 'desc' },
      take: 5,
    }),
    prisma.task.findMany({
      where: { userId, isCompleted: true },
      orderBy: { updatedAt: 'desc' },
      take: 5,
      select: { id: true, title: true, updatedAt: true, project: { select: { title: true } } },
    }),
    prisma.habitLog.findMany({
      where: { habit: { userId }, isCompleted: true },
      orderBy: { date: 'desc' },
      take: 5,
      include: { habit: { select: { name: true } } },
    }),
    prisma.workout.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      take: 4,
    }),
    prisma.studySession.findMany({
      where: { userId },
      orderBy: { startTime: 'desc' },
      take: 4,
      include: { course: { select: { name: true } } },
    }),
  ]);

  // Format Habits Checklist
  const habitItems = habits.map((h) => ({
    id: h.id,
    name: h.name,
    frequency: h.frequency,
    targetType: h.targetType,
    targetValue: h.targetValue,
    currentStreak: h.currentStreak,
    currentValue: h.logs[0]?.value ?? 0,
    isCompletedToday: h.logs.length > 0 && h.logs[0].isCompleted,
  }));

  // Gym weekly status
  const targetGymWorkouts = user?.preferences?.weeklyGymTarget || 4;
  const workedOutToday = workoutsThisWeek.some((w) => {
    const wDate = new Date(w.date);
    return wDate >= startOfToday && wDate <= endOfToday;
  });

  // Finance summary
  const spentThisMonth = monthExpenses._sum.amount ? Number(monthExpenses._sum.amount) : 0;
  const totalBudgetCap = budgets.reduce((sum, b) => sum + Number(b.monthlyLimit), 0);
  const budgetRemaining = Math.max(0, totalBudgetCap - spentThisMonth);

  // Unified Chronological Activity Stream
  const rawActivities: Array<{
    id: string;
    type: 'TRANSACTION' | 'FOCUS' | 'TASK' | 'HABIT' | 'WORKOUT' | 'STUDY';
    title: string;
    subtitle?: string;
    timestamp: Date;
    amount?: number;
    color?: string;
  }> = [];

  recentTransactions.forEach((t) => {
    const numAmount = Number(t.amount);
    rawActivities.push({
      id: `tx-${t.id}`,
      type: 'TRANSACTION',
      title: `${t.type === 'EXPENSE' ? 'Spent' : 'Received'} $${numAmount.toFixed(2)}`,
      subtitle: t.description || t.category?.name || t.source || 'Transaction',
      timestamp: t.date,
      amount: t.type === 'EXPENSE' ? -numAmount : numAmount,
      color: t.type === 'EXPENSE' ? '#EF4444' : '#10B981',
    });
  });

  recentFocusSessions.forEach((f) => {
    rawActivities.push({
      id: `focus-${f.id}`,
      type: 'FOCUS',
      title: `Completed ${f.durationMinutes}m Focus Block`,
      subtitle: f.category || 'Focus Session',
      timestamp: f.startTime,
      color: '#6366F1',
    });
  });

  recentCompletedTasks.forEach((t) => {
    rawActivities.push({
      id: `task-${t.id}`,
      type: 'TASK',
      title: `Completed "${t.title}"`,
      subtitle: t.project?.title ? `Project: ${t.project.title}` : 'Task',
      timestamp: t.updatedAt,
      color: '#10B981',
    });
  });

  recentHabitLogs.forEach((hl) => {
    rawActivities.push({
      id: `habit-${hl.id}`,
      type: 'HABIT',
      title: `Checked habit: ${hl.habit.name}`,
      subtitle: 'Daily streak updated',
      timestamp: hl.date,
      color: '#F59E0B',
    });
  });

  recentWorkouts.forEach((w) => {
    rawActivities.push({
      id: `workout-${w.id}`,
      type: 'WORKOUT',
      title: `Logged Workout: ${w.name}`,
      subtitle: `${w.durationMinutes || 60} mins session`,
      timestamp: w.date,
      color: '#EC4899',
    });
  });

  recentStudySessions.forEach((s) => {
    rawActivities.push({
      id: `study-${s.id}`,
      type: 'STUDY',
      title: `Studied for ${s.course?.name || 'Course'}`,
      subtitle: `${s.durationMinutes} mins logged`,
      timestamp: s.startTime,
      color: '#8B5CF6',
    });
  });

  rawActivities.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  const recentActivities = rawActivities.slice(0, 10);

  // Dashboard module visibility preferences
  const defaultDashboardModules = [
    'LIFE_SCORE',
    'HABITS',
    'TASKS',
    'SCHEDULE',
    'ACADEMIC',
    'PROJECTS',
    'FITNESS',
    'FINANCE',
    'RECENT_ACTIVITY',
  ];
  const userModules = user?.preferences?.dashboardModules;
  const dashboardModules: string[] =
    Array.isArray(userModules) && userModules.length > 0
      ? (userModules as string[])
      : defaultDashboardModules;

  const feed = {
    user: {
      name: user?.name || 'User',
      email: user?.email,
      avatarUrl: user?.avatarUrl,
      dashboardModules,
    },
    dashboardModules,
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
    recentActivities,
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
