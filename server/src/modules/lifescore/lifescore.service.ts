import prisma from '../../config/db';

export interface LifeScoreBreakdown {
  overallScore: number;
  level: 'OPTIMAL' | 'PRODUCTIVE' | 'BALANCED' | 'NEEDS_ATTENTION';
  components: {
    tasks: { score: number; weight: number; label: string };
    habits: { score: number; weight: number; label: string };
    coding: { score: number; weight: number; label: string };
    study: { score: number; weight: number; label: string };
    gym: { score: number; weight: number; label: string };
    finance: { score: number; weight: number; label: string };
  };
  recommendations: string[];
  calculatedAt: Date;
}

/**
 * Calculate Real-Time Algorithmic Life Score (UC-158 to UC-166)
 */
export const calculateLifeScore = async (userId: string): Promise<LifeScoreBreakdown> => {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

  const dayOfWeek = now.getDay();
  const diffToMonday = now.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1);
  const startOfWeek = new Date(now.setDate(diffToMonday));
  startOfWeek.setHours(0, 0, 0, 0);

  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);

  // Fetch all domain data concurrently
  const [
    user,
    tasksToday,
    overdueTasks,
    habits,
    focusSessionsToday,
    weekWorkouts,
    courses,
    monthExpenses,
    monthIncome,
    budgets,
  ] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      include: { preferences: true },
    }),
    prisma.task.findMany({
      where: {
        userId,
        dueDate: { gte: startOfToday, lte: endOfToday },
      },
    }),
    prisma.task.count({
      where: {
        userId,
        isCompleted: false,
        dueDate: { lt: startOfToday },
      },
    }),
    prisma.habit.findMany({
      where: { userId, isActive: true },
      include: {
        logs: {
          where: { date: { gte: startOfToday, lte: endOfToday } },
          take: 1,
        },
      },
    }),
    prisma.focusSession.findMany({
      where: { userId, startTime: { gte: startOfToday, lte: endOfToday } },
    }),
    prisma.workout.findMany({
      where: { userId, date: { gte: startOfWeek } },
    }),
    prisma.course.findMany({
      where: { userId },
      include: {
        assignments: true,
        attendances: true,
      },
    }),
    prisma.transaction.aggregate({
      where: { userId, type: 'EXPENSE', date: { gte: startOfMonth } },
      _sum: { amount: true },
    }),
    prisma.transaction.aggregate({
      where: { userId, type: 'INCOME', date: { gte: startOfMonth } },
      _sum: { amount: true },
    }),
    prisma.budget.findMany({
      where: { userId },
    }),
  ]);

  const recommendations: string[] = [];

  // 1. Task Score (Weight: 0.20)
  let taskScore = 75; // Baseline if no tasks due
  if (tasksToday.length > 0) {
    const completed = tasksToday.filter((t) => t.isCompleted).length;
    taskScore = (completed / tasksToday.length) * 100;
  }
  if (overdueTasks > 0) {
    taskScore = Math.max(0, taskScore - overdueTasks * 10);
    recommendations.push(`Clear ${overdueTasks} overdue task(s) to restore your Task component score.`);
  }

  // 2. Habit Score (Weight: 0.20)
  let habitScore = 80;
  if (habits.length > 0) {
    const completed = habits.filter((h) => h.logs.length > 0 && h.logs[0].isCompleted).length;
    const rate = (completed / habits.length) * 100;
    const avgStreak = habits.reduce((sum, h) => sum + h.currentStreak, 0) / habits.length;
    const streakBonus = Math.min(15, avgStreak * 2);
    habitScore = Math.min(100, rate * 0.85 + streakBonus);

    if (rate < 100) {
      recommendations.push(`Complete remaining ${habits.length - completed} habit(s) today to maximize habit consistency.`);
    }
  }

  // 3. Coding & Dev Score (Weight: 0.15)
  const targetCodingMins = user?.preferences?.dailyCodingTargetMins || 120;
  const codingMins = focusSessionsToday
    .filter((f) => f.category === 'CODING' || f.category === 'PROJECT')
    .reduce((sum, f) => sum + f.durationMinutes, 0);
  const codingScore = Math.min(100, (codingMins / targetCodingMins) * 100);
  if (codingScore < 70) {
    recommendations.push(`Log ${Math.max(0, targetCodingMins - codingMins)} more minutes of coding focus to reach your daily target.`);
  }

  // 4. Study & Academic Score (Weight: 0.15)
  const targetStudyMins = user?.preferences?.dailyStudyTargetMins || 120;
  const studyMins = focusSessionsToday
    .filter((f) => f.category === 'STUDY' || f.category === 'READING')
    .reduce((sum, f) => sum + f.durationMinutes, 0);
  let studyScore = Math.min(100, (studyMins / targetStudyMins) * 100);
  if (courses.length > 0) {
    let totalAssignments = 0;
    let submittedAssignments = 0;
    courses.forEach((c) => {
      totalAssignments += c.assignments.length;
      submittedAssignments += c.assignments.filter((a) => a.status === 'SUBMITTED' || a.status === 'GRADED').length;
    });
    const assignmentRate = totalAssignments > 0 ? (submittedAssignments / totalAssignments) * 100 : 100;
    studyScore = studyScore * 0.5 + assignmentRate * 0.5;
  }

  // 5. Gym & Fitness Score (Weight: 0.15)
  const targetWorkouts = user?.preferences?.weeklyGymTarget || 4;
  const loggedWorkouts = weekWorkouts.length;
  const gymScore = Math.min(100, (loggedWorkouts / targetWorkouts) * 100);
  if (gymScore < 75) {
    recommendations.push(`You have logged ${loggedWorkouts}/${targetWorkouts} gym sessions this week.`);
  }

  // 6. Personal Finance Score (Weight: 0.15)
  let financeScore = 85;
  const totalSpent = monthExpenses._sum.amount || 0;
  const totalEarned = monthIncome._sum.amount || 0;
  const totalBudget = budgets.reduce((sum, b) => sum + b.monthlyLimit, 0);

  if (totalBudget > 0) {
    const budgetAdherence = totalSpent <= totalBudget ? 100 : Math.max(0, 100 - ((totalSpent - totalBudget) / totalBudget) * 100);
    const savingsRate = totalEarned > 0 ? Math.max(0, ((totalEarned - totalSpent) / totalEarned) * 100) : 50;
    financeScore = Math.min(100, budgetAdherence * 0.6 + savingsRate * 0.4);
  }

  // Composite Weighted Score Calculation (supports custom weights in UserPreference)
  const defaultWeights = {
    tasks: 0.20,
    habits: 0.20,
    coding: 0.15,
    study: 0.15,
    gym: 0.15,
    finance: 0.15,
  };

  const customWeights = (user?.preferences?.lifeScoreWeights as Record<string, number> | null) || {};

  const weights = {
    tasks: typeof customWeights.tasks === 'number' ? customWeights.tasks : defaultWeights.tasks,
    habits: typeof customWeights.habits === 'number' ? customWeights.habits : defaultWeights.habits,
    coding: typeof customWeights.coding === 'number' ? customWeights.coding : defaultWeights.coding,
    study: typeof customWeights.study === 'number' ? customWeights.study : defaultWeights.study,
    gym: typeof customWeights.gym === 'number' ? customWeights.gym : defaultWeights.gym,
    finance: typeof customWeights.finance === 'number' ? customWeights.finance : defaultWeights.finance,
  };

  const rawOverall =
    taskScore * weights.tasks +
    habitScore * weights.habits +
    codingScore * weights.coding +
    studyScore * weights.study +
    gymScore * weights.gym +
    financeScore * weights.finance;

  const overallScore = Number(rawOverall.toFixed(1));

  // Determine Level
  let level: 'OPTIMAL' | 'PRODUCTIVE' | 'BALANCED' | 'NEEDS_ATTENTION' = 'BALANCED';
  if (overallScore >= 85) level = 'OPTIMAL';
  else if (overallScore >= 70) level = 'PRODUCTIVE';
  else if (overallScore >= 50) level = 'BALANCED';
  else level = 'NEEDS_ATTENTION';

  return {
    overallScore,
    level,
    components: {
      tasks: { score: Number(taskScore.toFixed(1)), weight: weights.tasks, label: 'Tasks & Deadlines' },
      habits: { score: Number(habitScore.toFixed(1)), weight: weights.habits, label: 'Habit Streaks' },
      coding: { score: Number(codingScore.toFixed(1)), weight: weights.coding, label: 'Development Focus' },
      study: { score: Number(studyScore.toFixed(1)), weight: weights.study, label: 'Academic & Learning' },
      gym: { score: Number(gymScore.toFixed(1)), weight: weights.gym, label: 'Physical Fitness' },
      finance: { score: Number(financeScore.toFixed(1)), weight: weights.finance, label: 'Financial Health' },
    },
    recommendations,
    calculatedAt: new Date(),
  };
};

/**
 * Snapshot today's Life Score into database (UC-162)
 */
export const snapshotDailyLifeScore = async (userId: string) => {
  const breakdown = await calculateLifeScore(userId);

  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);

  const existingLog = await prisma.lifeScoreLog.findFirst({
    where: {
      userId,
      date: { gte: startOfToday },
    },
  });

  let log;
  if (existingLog) {
    log = await prisma.lifeScoreLog.update({
      where: { id: existingLog.id },
      data: {
        overallScore: breakdown.overallScore,
        taskScore: breakdown.components.tasks.score,
        habitScore: breakdown.components.habits.score,
        codingScore: breakdown.components.coding.score,
        studyScore: breakdown.components.study.score,
        gymScore: breakdown.components.gym.score,
        financeScore: breakdown.components.finance.score,
      },
    });
  } else {
    log = await prisma.lifeScoreLog.create({
      data: {
        date: new Date(),
        overallScore: breakdown.overallScore,
        taskScore: breakdown.components.tasks.score,
        habitScore: breakdown.components.habits.score,
        codingScore: breakdown.components.coding.score,
        studyScore: breakdown.components.study.score,
        gymScore: breakdown.components.gym.score,
        financeScore: breakdown.components.finance.score,
        userId,
      },
    });
  }

  return {
    log,
    breakdown,
  };
};

/**
 * Get 30-Day Historical Trend for Charts (UC-163)
 */
export const getLifeScoreHistory = async (userId: string, limit = 30) => {
  const logs = await prisma.lifeScoreLog.findMany({
    where: { userId },
    orderBy: { date: 'asc' },
    take: limit,
  });

  return logs;
};

export default {
  calculateLifeScore,
  snapshotDailyLifeScore,
  getLifeScoreHistory,
};
