import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';

export interface CreateHabitDTO {
  name: string;
  description?: string | null;
  frequency?: string;
  targetType?: string;
  targetValue?: number;
  reminderTime?: string | null;
  categoryId?: string | null;
}

export interface UpdateHabitDTO {
  name?: string;
  description?: string | null;
  frequency?: string;
  targetType?: string;
  targetValue?: number;
  reminderTime?: string | null;
  categoryId?: string | null;
  isActive?: boolean;
}

export interface LogHabitDTO {
  date?: Date | string;
  isCompleted?: boolean;
  value?: number;
  notes?: string | null;
}

/**
 * Recalculate streak metrics (currentStreak & longestStreak) for a habit (UC-28)
 */
const recalculateHabitStreak = async (habitId: string) => {
  // Fetch completed log dates sorted descending without artificial clipping
  const logs = await prisma.habitLog.findMany({
    where: { habitId, isCompleted: true },
    select: { date: true },
    orderBy: { date: 'desc' },
  });

  if (logs.length === 0) {
    await prisma.habit.update({
      where: { id: habitId },
      data: { currentStreak: 0 },
    });
    return { currentStreak: 0, longestStreak: 0 };
  }

  // Set of distinct dates in YYYY-MM-DD format
  const dateSet = new Set(
    logs.map((log) => new Date(log.date).toISOString().split('T')[0])
  );

  const today = new Date();
  const todayStr = today.toISOString().split('T')[0];

  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().split('T')[0];

  // Current streak calculation: check if completed today or yesterday
  let currentStreak = 0;
  let checkDate = dateSet.has(todayStr) ? new Date(today) : (dateSet.has(yesterdayStr) ? new Date(yesterday) : null);

  if (checkDate) {
    while (true) {
      const dateStr = checkDate.toISOString().split('T')[0];
      if (dateSet.has(dateStr)) {
        currentStreak++;
        checkDate.setDate(checkDate.getDate() - 1);
      } else {
        break;
      }
    }
  }

  // Longest streak calculation across history
  const sortedDates = Array.from(dateSet).sort();
  let longestStreak = 0;
  let tempStreak = 0;
  let prevDate: Date | null = null;

  for (const dStr of sortedDates) {
    const currDate = new Date(dStr);
    if (!prevDate) {
      tempStreak = 1;
    } else {
      const diffTime = currDate.getTime() - prevDate.getTime();
      const diffDays = Math.round(diffTime / (1000 * 3600 * 24));
      if (diffDays === 1) {
        tempStreak++;
      } else if (diffDays > 1) {
        tempStreak = 1;
      }
    }
    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }
    prevDate = currDate;
  }

  const habit = await prisma.habit.findUnique({ where: { id: habitId } });
  const maxLongest = Math.max(longestStreak, habit?.longestStreak || 0);

  await prisma.habit.update({
    where: { id: habitId },
    data: {
      currentStreak,
      longestStreak: maxLongest,
    },
  });

  return { currentStreak, longestStreak: maxLongest };
};

/**
 * UC-24: Create a new Habit
 */
export const createHabit = async (userId: string, data: CreateHabitDTO) => {
  if (data.categoryId) {
    const category = await prisma.category.findFirst({
      where: { id: data.categoryId, userId },
    });
    if (!category) throw new ApiError(404, 'Category not found');
  }

  const habit = await prisma.habit.create({
    data: {
      name: data.name,
      description: data.description,
      frequency: data.frequency || 'DAILY',
      targetType: data.targetType || 'CHECKBOX',
      targetValue: data.targetValue || 1,
      reminderTime: data.reminderTime,
      userId,
      categoryId: data.categoryId || null,
    },
    include: {
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  invalidateDashboardCache(userId);

  return habit;
};

/**
 * Get all habits with today's completion status (UC-06, UC-29) with optional pagination
 */
export const getHabits = async (userId: string, includeInactive = false, page?: number, limit?: number) => {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

  const where = {
    userId,
    ...(includeInactive ? {} : { isActive: true }),
  };

  const total = await prisma.habit.count({ where });

  let skip: number | undefined;
  let take: number | undefined;
  if (page && limit && limit > 0) {
    skip = (page - 1) * limit;
    take = limit;
  }

  const habits = await prisma.habit.findMany({
    where,
    skip,
    take,
    orderBy: [{ currentStreak: 'desc' }, { createdAt: 'asc' }],
    include: {
      category: { select: { id: true, name: true, color: true, icon: true } },
      logs: {
        where: {
          date: { gte: startOfToday, lte: endOfToday },
        },
        take: 1,
      },
    },
  });

  const habitList = habits.map((habit) => {
    const isCompletedToday = habit.logs.length > 0 && habit.logs[0].isCompleted;
    return {
      id: habit.id,
      name: habit.name,
      description: habit.description,
      frequency: habit.frequency,
      targetType: habit.targetType,
      targetValue: habit.targetValue,
      reminderTime: habit.reminderTime,
      currentStreak: habit.currentStreak,
      longestStreak: habit.longestStreak,
      isActive: habit.isActive,
      category: habit.category,
      isCompletedToday,
      todayLog: habit.logs[0] || null,
    };
  });

  return {
    data: habitList,
    meta: {
      total,
      page: page || 1,
      limit: limit || total,
      totalPages: limit && limit > 0 ? Math.ceil(total / limit) : 1,
    },
  };
};

/**
 * Get single habit details by ID with recent 30-day logs (UC-29)
 */
export const getHabitById = async (userId: string, habitId: string) => {
  const habit = await prisma.habit.findFirst({
    where: { id: habitId, userId },
    include: {
      category: true,
      logs: {
        orderBy: { date: 'desc' },
        take: 30,
      },
    },
  });

  if (!habit) {
    throw new ApiError(404, 'Habit not found');
  }

  return habit;
};

/**
 * UC-25: Update Habit
 */
export const updateHabit = async (userId: string, habitId: string, data: UpdateHabitDTO) => {
  const habit = await prisma.habit.findFirst({
    where: { id: habitId, userId },
  });

  if (!habit) {
    throw new ApiError(404, 'Habit not found');
  }

  const updatedHabit = await prisma.habit.update({
    where: { id: habitId },
    data: {
      ...data,
      categoryId: data.categoryId !== undefined ? data.categoryId : habit.categoryId,
    },
    include: {
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  invalidateDashboardCache(userId);

  return updatedHabit;
};

/**
 * UC-27: Mark Habit Completed / Log Habit for a specific date
 */
export const logHabitCompletion = async (userId: string, habitId: string, data: LogHabitDTO) => {
  const habit = await prisma.habit.findFirst({
    where: { id: habitId, userId },
  });

  if (!habit) {
    throw new ApiError(404, 'Habit not found');
  }

  const rawDate = data.date ? new Date(data.date) : new Date();
  const normalizedDate = new Date(rawDate.getFullYear(), rawDate.getMonth(), rawDate.getDate());

  const log = await prisma.habitLog.upsert({
    where: {
      habitId_date: {
        habitId,
        date: normalizedDate,
      },
    },
    update: {
      isCompleted: data.isCompleted !== undefined ? data.isCompleted : true,
      value: data.value !== undefined ? data.value : 1,
      notes: data.notes,
    },
    create: {
      habitId,
      date: normalizedDate,
      isCompleted: data.isCompleted !== undefined ? data.isCompleted : true,
      value: data.value !== undefined ? data.value : 1,
      notes: data.notes,
    },
  });

  // Recalculate streak
  const streaks = await recalculateHabitStreak(habitId);

  invalidateDashboardCache(userId);

  return {
    log,
    currentStreak: streaks.currentStreak,
    longestStreak: streaks.longestStreak,
  };
};

/**
 * UC-29: Get Habit History (Heatmap Calendar)
 */
export const getHabitHistory = async (
  userId: string,
  habitId: string,
  startDate?: Date | string,
  endDate?: Date | string
) => {
  const habit = await prisma.habit.findFirst({
    where: { id: habitId, userId },
  });

  if (!habit) {
    throw new ApiError(404, 'Habit not found');
  }

  const defaultStart = new Date();
  defaultStart.setDate(defaultStart.getDate() - 90); // 90 days of history by default

  const logs = await prisma.habitLog.findMany({
    where: {
      habitId,
      date: {
        gte: startDate ? new Date(startDate) : defaultStart,
        lte: endDate ? new Date(endDate) : new Date(),
      },
    },
    orderBy: { date: 'asc' },
  });

  const totalLogs = logs.length;
  const completedLogs = logs.filter((l) => l.isCompleted).length;
  const completionRate = totalLogs > 0 ? Number(((completedLogs / totalLogs) * 100).toFixed(1)) : 0;

  return {
    habitId: habit.id,
    habitName: habit.name,
    currentStreak: habit.currentStreak,
    longestStreak: habit.longestStreak,
    totalTrackedDays: totalLogs,
    completedDays: completedLogs,
    completionRate,
    logs,
  };
};

/**
 * UC-26: Delete Habit
 */
export const deleteHabit = async (userId: string, habitId: string) => {
  const habit = await prisma.habit.findFirst({
    where: { id: habitId, userId },
  });

  if (!habit) {
    throw new ApiError(404, 'Habit not found');
  }

  await prisma.habit.delete({ where: { id: habitId } });

  invalidateDashboardCache(userId);

  return { message: 'Habit deleted successfully' };
};

/**
 * Aggregate summary for Dashboard (UC-06, UC-07)
 */
export const getHabitsSummary = async (userId: string) => {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

  const activeHabits = await prisma.habit.findMany({
    where: { userId, isActive: true },
    select: { id: true, currentStreak: true },
  });

  const completedTodayCount = await prisma.habitLog.count({
    where: {
      habit: { userId, isActive: true },
      isCompleted: true,
      date: { gte: startOfToday, lte: endOfToday },
    },
  });

  const totalActive = activeHabits.length;
  const completionRateToday = totalActive > 0 ? Number(((completedTodayCount / totalActive) * 100).toFixed(1)) : 0;
  const bestActiveStreak = activeHabits.reduce((max, h) => Math.max(max, h.currentStreak), 0);

  return {
    totalActive,
    completedTodayCount,
    completionRateToday,
    bestActiveStreak,
  };
};

export default {
  createHabit,
  getHabits,
  getHabitById,
  updateHabit,
  logHabitCompletion,
  getHabitHistory,
  deleteHabit,
  getHabitsSummary,
};
