import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import {
  RetrospectiveReportData,
  CategorySpending,
  CourseStudyTime,
  StrengthProgressionPoint,
} from './engines/report_generator';

export interface CreateTimeEntryDTO {
  startTime: Date | string;
  endTime?: Date | string | null;
  duration?: number | null;
  taskId?: string | null;
}

export interface UpdateTimeEntryDTO {
  startTime?: Date | string;
  endTime?: Date | string | null;
  duration?: number | null;
  taskId?: string | null;
}

export interface TimeEntryQuery {
  taskId?: string;
  startDate?: Date | string;
  endDate?: Date | string;
  page?: number;
  limit?: number;
}

export const getLocalDateKey = (date: Date, timeZone: string = 'UTC'): string => {
  try {
    return new Intl.DateTimeFormat('en-CA', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(date);
  } catch {
    return date.toISOString().split('T')[0];
  }
};

export const getLocalStartOfDay = (referenceDate: Date, daysAgo: number = 0, timeZone: string = 'UTC'): Date => {
  try {
    const localDateStr = getLocalDateKey(referenceDate, timeZone);
    const [y, m, d] = localDateStr.split('-').map(Number);
    const targetUtc = new Date(Date.UTC(y, m - 1, d, 0, 0, 0, 0));
    targetUtc.setUTCDate(targetUtc.getUTCDate() - daysAgo);

    const tzString = targetUtc.toLocaleString('en-US', { timeZone });
    const utcString = targetUtc.toLocaleString('en-US', { timeZone: 'UTC' });
    const diffMs = new Date(tzString).getTime() - new Date(utcString).getTime();
    return new Date(targetUtc.getTime() - diffMs);
  } catch {
    const fallback = new Date(referenceDate);
    fallback.setUTCDate(fallback.getUTCDate() - daysAgo);
    fallback.setUTCHours(0, 0, 0, 0);
    return fallback;
  }
};

// ==========================================
// 1. TIME TRACKER ENGINE & CRUD (UC-134 to UC-138)
// ==========================================

export const createTimeEntry = async (userId: string, data: CreateTimeEntryDTO) => {
  if (data.taskId) {
    const task = await prisma.task.findFirst({
      where: { id: data.taskId, userId },
    });
    if (!task) throw new ApiError(404, 'Associated task not found');
  }

  const start = new Date(data.startTime);
  const end = data.endTime ? new Date(data.endTime) : null;
  let duration = data.duration ?? null;

  if (end && !duration) {
    duration = Math.max(1, Math.round((end.getTime() - start.getTime()) / 1000));
  }

  return await prisma.timeEntry.create({
    data: {
      startTime: start,
      endTime: end,
      duration,
      taskId: data.taskId || null,
      userId,
    },
    include: {
      task: { select: { id: true, title: true, priority: true } },
    },
  });
};

export const updateTimeEntry = async (userId: string, id: string, data: UpdateTimeEntryDTO) => {
  const existing = await prisma.timeEntry.findFirst({
    where: { id, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Time entry not found');
  }

  if (data.taskId !== undefined && data.taskId !== null) {
    const task = await prisma.task.findFirst({
      where: { id: data.taskId, userId },
    });
    if (!task) throw new ApiError(404, 'Associated task not found');
  }

  const start = data.startTime ? new Date(data.startTime) : existing.startTime;
  const end = data.endTime !== undefined ? (data.endTime ? new Date(data.endTime) : null) : existing.endTime;
  let duration = data.duration !== undefined ? data.duration : existing.duration;

  if (end && data.duration === undefined && (data.startTime || data.endTime)) {
    duration = Math.max(1, Math.round((end.getTime() - start.getTime()) / 1000));
  }

  return await prisma.timeEntry.update({
    where: { id },
    data: {
      startTime: start,
      endTime: end,
      duration,
      taskId: data.taskId !== undefined ? data.taskId : existing.taskId,
    },
    include: {
      task: { select: { id: true, title: true, priority: true } },
    },
  });
};

export const stopTimeEntry = async (userId: string, id: string) => {
  const existing = await prisma.timeEntry.findFirst({
    where: { id, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Time entry not found');
  }

  if (existing.endTime) {
    return existing;
  }

  const now = new Date();
  const durationSeconds = Math.max(
    1,
    Math.round((now.getTime() - new Date(existing.startTime).getTime()) / 1000)
  );

  return await prisma.timeEntry.update({
    where: { id },
    data: {
      endTime: now,
      duration: durationSeconds,
    },
    include: {
      task: { select: { id: true, title: true, priority: true } },
    },
  });
};

export const getTimeEntries = async (userId: string, query: TimeEntryQuery) => {
  const { taskId, startDate, endDate, page = 1, limit = 20 } = query;
  const skip = (page - 1) * limit;

  const where: Prisma.TimeEntryWhereInput = { userId };

  if (taskId) where.taskId = taskId;
  if (startDate || endDate) {
    where.startTime = {
      gte: startDate ? new Date(startDate) : undefined,
      lte: endDate ? new Date(endDate) : undefined,
    };
  }

  const [entries, total] = await Promise.all([
    prisma.timeEntry.findMany({
      where,
      skip,
      take: limit,
      orderBy: { startTime: 'desc' },
      include: {
        task: { select: { id: true, title: true, priority: true, project: true } },
      },
    }),
    prisma.timeEntry.count({ where }),
  ]);

  return {
    entries,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    },
  };
};

export const deleteTimeEntry = async (userId: string, id: string) => {
  const existing = await prisma.timeEntry.findFirst({
    where: { id, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Time entry not found');
  }

  await prisma.timeEntry.delete({ where: { id } });
  return { message: 'Time entry deleted successfully' };
};

// ==========================================
// 2. CROSS-DOMAIN ANALYTICS & DEEP DOMAIN TRENDS (UC-144 to UC-152)
// ==========================================

export const getCrossDomainRetrospective = async (
  userId: string,
  period: 'WEEKLY' | 'MONTHLY' = 'WEEKLY',
  timezone: string = 'UTC'
): Promise<RetrospectiveReportData> => {
  const now = new Date();
  const daysInPeriod = period === 'MONTHLY' ? 30 : 7;

  const currentStart = getLocalStartOfDay(now, daysInPeriod - 1, timezone);
  const previousStart = getLocalStartOfDay(now, daysInPeriod * 2 - 1, timezone);

  // Parallel multi-domain queries joining 10 entity groups
  const [
    focusSessions,
    completedTasks,
    workouts,
    habitLogs,
    timeEntries,
    studySessions,
    githubIntegration,
    leetCodeIntegration,
    transactions,
    personalRecords,
  ] = await Promise.all([
    prisma.focusSession.findMany({
      where: { userId, status: 'COMPLETED', startTime: { gte: previousStart } },
    }),
    prisma.task.findMany({
      where: { userId, isCompleted: true, completedAt: { gte: previousStart } },
      select: { id: true, title: true, priority: true, completedAt: true },
    }),
    prisma.workout.findMany({ where: { userId, date: { gte: previousStart } } }),
    prisma.habitLog.findMany({
      where: { habit: { userId }, isCompleted: true, date: { gte: previousStart } },
    }),
    prisma.timeEntry.findMany({ where: { userId, startTime: { gte: previousStart } } }),
    prisma.studySession.findMany({
      where: { userId, startTime: { gte: previousStart } },
      include: { course: { select: { id: true, name: true, code: true, color: true } } },
    }),
    prisma.gitHubIntegration.findUnique({ where: { userId } }),
    prisma.leetCodeIntegration.findUnique({ where: { userId } }),
    prisma.transaction.findMany({
      where: { userId, date: { gte: previousStart } },
      include: { category: { select: { id: true, name: true, color: true } } },
    }),
    prisma.personalRecord.findMany({
      where: { userId },
      orderBy: { achievedDate: 'asc' },
      take: 15,
      include: { exercise: { select: { name: true } } },
    }),
  ]);

  // Segment current vs previous datasets
  const currFocus = focusSessions.filter((f) => new Date(f.startTime) >= currentStart);
  const prevFocus = focusSessions.filter((f) => new Date(f.startTime) < currentStart);

  const currTasks = completedTasks.filter((t) => t.completedAt && new Date(t.completedAt) >= currentStart);
  const prevTasks = completedTasks.filter((t) => t.completedAt && new Date(t.completedAt) < currentStart);

  const currWorkouts = workouts.filter((w) => new Date(w.date) >= currentStart);
  const prevWorkouts = workouts.filter((w) => new Date(w.date) < currentStart);

  const currHabits = habitLogs.filter((h) => new Date(h.date) >= currentStart);
  const prevHabits = habitLogs.filter((h) => new Date(h.date) < currentStart);

  const currTime = timeEntries.filter((t) => new Date(t.startTime) >= currentStart);
  const prevTime = timeEntries.filter((t) => new Date(t.startTime) < currentStart);

  const currStudy = studySessions.filter((s) => new Date(s.startTime) >= currentStart);
  const prevStudy = studySessions.filter((s) => new Date(s.startTime) < currentStart);

  const currTx = transactions.filter((tx) => new Date(tx.date) >= currentStart);
  const prevTx = transactions.filter((tx) => new Date(tx.date) < currentStart);

  const currFocusHours = currFocus.reduce((acc, f) => acc + f.durationMinutes / 60, 0);
  const prevFocusHours = prevFocus.reduce((acc, f) => acc + f.durationMinutes / 60, 0);

  const currTrackedHours = currTime.reduce((acc, t) => acc + (t.duration || 0) / 3600, 0);
  const prevTrackedHours = prevTime.reduce((acc, t) => acc + (t.duration || 0) / 3600, 0);

  const currStudyHours = currStudy.reduce((acc, s) => acc + s.durationMinutes / 60, 0);
  const prevStudyHours = prevStudy.reduce((acc, s) => acc + s.durationMinutes / 60, 0);

  const currIncome = currTx.filter((t) => t.type === 'INCOME').reduce((acc, t) => acc + Number(t.amount), 0);
  const currExpense = currTx.filter((t) => t.type === 'EXPENSE').reduce((acc, t) => acc + Number(t.amount), 0);
  const currSavings = currIncome - currExpense;

  const prevIncome = prevTx.filter((t) => t.type === 'INCOME').reduce((acc, t) => acc + Number(t.amount), 0);
  const prevExpense = prevTx.filter((t) => t.type === 'EXPENSE').reduce((acc, t) => acc + Number(t.amount), 0);
  const prevSavings = prevIncome - prevExpense;

  const calcDelta = (current: number, previous: number): number => {
    if (previous === 0) return current > 0 ? 100.0 : 0.0;
    return Number((((current - previous) / previous) * 100).toFixed(1));
  };

  const comparison = [
    {
      metric: 'Focus Time',
      current: Number(currFocusHours.toFixed(1)),
      previous: Number(prevFocusHours.toFixed(1)),
      unit: 'hrs',
      deltaPercentage: calcDelta(currFocusHours, prevFocusHours),
    },
    {
      metric: 'Completed Tasks',
      current: currTasks.length,
      previous: prevTasks.length,
      unit: 'tasks',
      deltaPercentage: calcDelta(currTasks.length, prevTasks.length),
    },
    {
      metric: 'Workouts',
      current: currWorkouts.length,
      previous: prevWorkouts.length,
      unit: 'sessions',
      deltaPercentage: calcDelta(currWorkouts.length, prevWorkouts.length),
    },
    {
      metric: 'Habits Logged',
      current: currHabits.length,
      previous: prevHabits.length,
      unit: 'logs',
      deltaPercentage: calcDelta(currHabits.length, prevHabits.length),
    },
    {
      metric: 'Study Time',
      current: Number(currStudyHours.toFixed(1)),
      previous: Number(prevStudyHours.toFixed(1)),
      unit: 'hrs',
      deltaPercentage: calcDelta(currStudyHours, prevStudyHours),
    },
    {
      metric: 'Net Savings',
      current: Number(currSavings.toFixed(2)),
      previous: Number(prevSavings.toFixed(2)),
      unit: '$',
      deltaPercentage: calcDelta(currSavings, prevSavings),
    },
  ];

  // Daily distribution timeline
  const dailyFocusHours: Record<string, number> = {};
  for (let i = daysInPeriod - 1; i >= 0; i--) {
    const dayStart = getLocalStartOfDay(now, i, timezone);
    const dateKey = getLocalDateKey(dayStart, timezone);
    dailyFocusHours[dateKey] = 0;
  }

  // Hourly Productivity Calculation (UC-147)
  let morningMinutes = 0;
  let afternoonMinutes = 0;
  let eveningMinutes = 0;
  let nightMinutes = 0;

  currFocus.forEach((f) => {
    const key = getLocalDateKey(new Date(f.startTime), timezone);
    if (dailyFocusHours[key] !== undefined) {
      dailyFocusHours[key] = Number((dailyFocusHours[key] + f.durationMinutes / 60).toFixed(1));
    }

    const startHour = new Date(f.startTime).getHours();
    if (startHour >= 6 && startHour < 12) morningMinutes += f.durationMinutes;
    else if (startHour >= 12 && startHour < 18) afternoonMinutes += f.durationMinutes;
    else if (startHour >= 18 && startHour < 24) eveningMinutes += f.durationMinutes;
    else nightMinutes += f.durationMinutes;
  });

  const maxPeriod = Math.max(morningMinutes, afternoonMinutes, eveningMinutes, nightMinutes);
  let peakWindow = 'Morning (6 AM - 12 PM)';
  if (maxPeriod === afternoonMinutes && afternoonMinutes > 0) peakWindow = 'Afternoon (12 PM - 6 PM)';
  else if (maxPeriod === eveningMinutes && eveningMinutes > 0) peakWindow = 'Evening (6 PM - 12 AM)';
  else if (maxPeriod === nightMinutes && nightMinutes > 0) peakWindow = 'Night (12 AM - 6 AM)';

  // 1. Spending By Category (UC-151)
  const categoryMap = new Map<string, { name: string; color: string; amount: number }>();
  currTx
    .filter((t) => t.type === 'EXPENSE')
    .forEach((t) => {
      const catName = t.category?.name || 'General';
      const catColor = t.category?.color || '#EF4444';
      const currentAmount = categoryMap.get(catName)?.amount || 0;
      categoryMap.set(catName, {
        name: catName,
        color: catColor,
        amount: currentAmount + Number(t.amount),
      });
    });

  const spendingByCategory: CategorySpending[] = Array.from(categoryMap.values()).map((c) => ({
    name: c.name,
    color: c.color,
    amount: Number(c.amount.toFixed(2)),
    percentage: currExpense > 0 ? Number(((c.amount / currExpense) * 100).toFixed(1)) : 0,
  }));

  // 2. Study Time Distribution By Course (UC-149)
  const courseMap = new Map<string, { name: string; code?: string | null; color: string; minutes: number; count: number }>();
  currStudy.forEach((s) => {
    const courseName = s.course?.name || 'Self-Directed Study';
    const courseCode = s.course?.code;
    const courseColor = s.course?.color || '#8B5CF6';
    const entry = courseMap.get(courseName) || {
      name: courseName,
      code: courseCode,
      color: courseColor,
      minutes: 0,
      count: 0,
    };
    entry.minutes += s.durationMinutes;
    entry.count += 1;
    courseMap.set(courseName, entry);
  });

  const studyByCourse: CourseStudyTime[] = Array.from(courseMap.values()).map((c) => ({
    courseName: c.name,
    code: c.code,
    color: c.color,
    hours: Number((c.minutes / 60).toFixed(1)),
    sessionsCount: c.count,
  }));

  // 3. Gym 1RM Strength Progression (UC-150)
  const strengthProgression: StrengthProgressionPoint[] = personalRecords.map((pr) => ({
    exerciseName: pr.exercise.name,
    weightKg: pr.weightKg,
    repetitions: pr.repetitions,
    oneRepMax: pr.calculatedOneRepMax ?? pr.weightKg,
    date: pr.achievedDate.toISOString().split('T')[0],
  }));

  return {
    period,
    summary: {
      totalFocusHours: Number(currFocusHours.toFixed(1)),
      totalTrackedHours: Number(currTrackedHours.toFixed(1)),
      completedTasksCount: currTasks.length,
      workoutsCount: currWorkouts.length,
      habitsCompletedCount: currHabits.length,
    },
    comparison,
    dailyFocusHours,
    completedTasks: currTasks.map((t) => ({
      id: t.id,
      title: t.title,
      priority: t.priority,
    })),
    multiDomain: {
      study: {
        totalHours: Number(currStudyHours.toFixed(1)),
        sessionCount: currStudy.length,
        byCourse: studyByCourse,
      },
      coding: {
        totalCommits: githubIntegration?.totalCommits ?? 0,
        currentStreak: githubIntegration?.currentStreak ?? 0,
        leetcodeTotal: leetCodeIntegration?.totalSolved ?? 0,
        leetcodeEasy: leetCodeIntegration?.easySolved ?? 0,
        leetcodeMedium: leetCodeIntegration?.mediumSolved ?? 0,
        leetcodeHard: leetCodeIntegration?.hardSolved ?? 0,
      },
      finance: {
        totalIncome: Number(currIncome.toFixed(2)),
        totalExpense: Number(currExpense.toFixed(2)),
        netSavings: Number(currSavings.toFixed(2)),
        transactionCount: currTx.length,
        spendingByCategory,
      },
      gym: {
        workoutsCount: currWorkouts.length,
        strengthProgression,
      },
      productivity: {
        morningHours: Number((morningMinutes / 60).toFixed(1)),
        afternoonHours: Number((afternoonMinutes / 60).toFixed(1)),
        eveningHours: Number((eveningMinutes / 60).toFixed(1)),
        nightHours: Number((nightMinutes / 60).toFixed(1)),
        peakWindow,
      },
    },
  };
};

export default {
  createTimeEntry,
  updateTimeEntry,
  stopTimeEntry,
  getTimeEntries,
  deleteTimeEntry,
  getCrossDomainRetrospective,
  getLocalDateKey,
  getLocalStartOfDay,
};
