import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';

export interface CreateHabitDTO {
  name: string;
  description?: string | null;
  frequency?: string;
  targetFrequencyCount?: number;
  targetFrequencyPeriod?: string;
  targetType?: string;
  targetValue?: number;
  reminderTime?: string | null;
  categoryId?: string | null;
  difficulty?: string;
  weight?: number;
  streakFreezes?: number;
}

export interface UpdateHabitDTO {
  name?: string;
  description?: string | null;
  frequency?: string;
  targetFrequencyCount?: number;
  targetFrequencyPeriod?: string;
  targetType?: string;
  targetValue?: number;
  reminderTime?: string | null;
  categoryId?: string | null;
  difficulty?: string;
  weight?: number;
  streakFreezes?: number;
  isActive?: boolean;
}

export interface LogHabitDTO {
  date?: Date | string;
  isCompleted?: boolean;
  value?: number;
  notes?: string | null;
}

export interface CreateRoutineDTO {
  name: string;
  description?: string | null;
  icon?: string;
  color?: string;
  targetTime?: string | null;
  habitIds?: string[];
}

export interface UpdateRoutineDTO {
  name?: string;
  description?: string | null;
  icon?: string;
  color?: string;
  targetTime?: string | null;
  habitIds?: string[];
}

const getDifficultyWeight = (difficulty?: string): number => {
  switch (difficulty?.toUpperCase()) {
    case 'TRIVIAL':
      return 0.5;
    case 'EASY':
      return 0.8;
    case 'MEDIUM':
      return 1.0;
    case 'HARD':
      return 1.5;
    case 'EPIC':
      return 2.0;
    default:
      return 1.0;
  }
};

/**
 * Evaluates streaks for a habit, resetting expired streaks and consuming streak freezes when applicable.
 */
export const evaluateHabitStreak = async (habitId: string, habitRecord?: any) => {
  const habit = habitRecord || (await prisma.habit.findUnique({ where: { id: habitId } }));
  if (!habit) return { currentStreak: 0, longestStreak: 0, streakFreezes: 0 };

  const isWeeklyCount =
    habit.frequency === 'CUSTOM' ||
    habit.targetFrequencyPeriod === 'WEEK' ||
    (habit.targetFrequencyCount && habit.targetFrequencyCount > 1);

  if (isWeeklyCount) {
    return evaluateWeeklyCountStreak(habit);
  }

  // --- Daily Habit Streak Evaluation ---
  const logs = await prisma.habitLog.findMany({
    where: { habitId, isCompleted: true },
    select: { date: true, wasFrozen: true },
    orderBy: { date: 'desc' },
  });

  const dateSet = new Set(
    logs.map((log) => new Date(log.date).toISOString().split('T')[0])
  );

  const today = new Date();
  const todayStr = today.toISOString().split('T')[0];

  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().split('T')[0];

  let streakFreezes = habit.streakFreezes ?? 2;
  let currentStreak = habit.currentStreak || 0;
  let longestStreak = habit.longestStreak || 0;

  // Check if neither today nor yesterday has a completed log
  if (!dateSet.has(todayStr) && !dateSet.has(yesterdayStr)) {
    // If user built a streak and yesterday wasn't logged:
    if (currentStreak > 0) {
      if (streakFreezes > 0) {
        // Auto-consume 1 streak freeze for yesterday
        const yesterdayDate = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate());
        await prisma.habitLog.upsert({
          where: { habitId_date: { habitId, date: yesterdayDate } },
          update: { isCompleted: true, wasFrozen: true, notes: 'Protected by streak freeze' },
          create: { habitId, date: yesterdayDate, isCompleted: true, wasFrozen: true, notes: 'Protected by streak freeze' },
        });

        streakFreezes = Math.max(0, streakFreezes - 1);
        dateSet.add(yesterdayStr);
      } else {
        // Streak is broken
        longestStreak = Math.max(longestStreak, currentStreak);
        currentStreak = 0;
      }
    } else {
      currentStreak = 0;
    }
  }

  // Re-calculate consecutive unbroken streak backwards
  let checkDate = dateSet.has(todayStr) ? new Date(today) : (dateSet.has(yesterdayStr) ? new Date(yesterday) : null);
  let computedStreak = 0;

  if (checkDate) {
    while (true) {
      const dStr = checkDate.toISOString().split('T')[0];
      if (dateSet.has(dStr)) {
        computedStreak++;
        checkDate.setDate(checkDate.getDate() - 1);
      } else {
        break;
      }
    }
    currentStreak = computedStreak;
  }

  // Calculate historical longest streak
  const sortedDates = Array.from(dateSet).sort();
  let maxConsecutive = 0;
  let tempStreak = 0;
  let prevDate: Date | null = null;

  for (const dStr of sortedDates) {
    const currDate = new Date(dStr);
    if (!prevDate) {
      tempStreak = 1;
    } else {
      const diffDays = Math.round((currDate.getTime() - prevDate.getTime()) / (1000 * 3600 * 24));
      if (diffDays === 1) {
        tempStreak++;
      } else if (diffDays > 1) {
        tempStreak = 1;
      }
    }
    if (tempStreak > maxConsecutive) maxConsecutive = tempStreak;
    prevDate = currDate;
  }

  longestStreak = Math.max(longestStreak, maxConsecutive, currentStreak);

  await prisma.habit.update({
    where: { id: habitId },
    data: {
      currentStreak,
      longestStreak,
      streakFreezes,
      lastEvaluatedDate: new Date(),
    },
  });

  return { currentStreak, longestStreak, streakFreezes };
};

/**
 * Evaluates weekly count-based habits (e.g. 3x per week).
 * Streaks increment by 1 for each calendar week meeting the target.
 */
const evaluateWeeklyCountStreak = async (habit: any) => {
  const targetCount = habit.targetFrequencyCount || 1;

  const logs = await prisma.habitLog.findMany({
    where: { habitId: habit.id, isCompleted: true },
    select: { date: true },
    orderBy: { date: 'desc' },
  });

  // Group logs into ISO calendar week strings: "YYYY-Www"
  const getIsoWeek = (d: Date) => {
    const date = new Date(d.getTime());
    date.setHours(0, 0, 0, 0);
    date.setDate(date.getDate() + 3 - ((date.getDay() + 6) % 7));
    const week1 = new Date(date.getFullYear(), 0, 4);
    const weekNum = 1 + Math.round(((date.getTime() - week1.getTime()) / 86400000 - 3 + ((week1.getDay() + 6) % 7)) / 7);
    return `${date.getFullYear()}-W${String(weekNum).padStart(2, '0')}`;
  };

  const weekCounts = new Map<string, number>();
  for (const log of logs) {
    const wk = getIsoWeek(new Date(log.date));
    weekCounts.set(wk, (weekCounts.get(wk) || 0) + 1);
  }

  const now = new Date();
  const currentWeek = getIsoWeek(now);

  const prevWeekDate = new Date(now);
  prevWeekDate.setDate(prevWeekDate.getDate() - 7);
  const prevWeek = getIsoWeek(prevWeekDate);

  let currentStreak = 0;
  let checkWeekDate = new Date(now);

  // If current week already meets target, start from current week; else check if prev week met target
  const currentWeekMet = (weekCounts.get(currentWeek) || 0) >= targetCount;
  const prevWeekMet = (weekCounts.get(prevWeek) || 0) >= targetCount;

  if (currentWeekMet) {
    while (true) {
      const wk = getIsoWeek(checkWeekDate);
      if ((weekCounts.get(wk) || 0) >= targetCount) {
        currentStreak++;
        checkWeekDate.setDate(checkWeekDate.getDate() - 7);
      } else {
        break;
      }
    }
  } else if (prevWeekMet) {
    checkWeekDate = new Date(prevWeekDate);
    while (true) {
      const wk = getIsoWeek(checkWeekDate);
      if ((weekCounts.get(wk) || 0) >= targetCount) {
        currentStreak++;
        checkWeekDate.setDate(checkWeekDate.getDate() - 7);
      } else {
        break;
      }
    }
  }

  const longestStreak = Math.max(habit.longestStreak || 0, currentStreak);

  await prisma.habit.update({
    where: { id: habit.id },
    data: {
      currentStreak,
      longestStreak,
      lastEvaluatedDate: new Date(),
    },
  });

  return { currentStreak, longestStreak, streakFreezes: habit.streakFreezes ?? 2 };
};

export const recalculateHabitStreak = evaluateHabitStreak;

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

  const calculatedWeight = data.weight ?? getDifficultyWeight(data.difficulty);

  const habit = await prisma.habit.create({
    data: {
      name: data.name,
      description: data.description,
      frequency: data.frequency || 'DAILY',
      targetFrequencyCount: data.targetFrequencyCount ?? 1,
      targetFrequencyPeriod: data.targetFrequencyPeriod ?? 'WEEK',
      targetType: data.targetType || 'CHECKBOX',
      targetValue: data.targetValue || 1,
      reminderTime: data.reminderTime,
      difficulty: data.difficulty || 'MEDIUM',
      weight: calculatedWeight,
      streakFreezes: data.streakFreezes ?? 2,
      lastEvaluatedDate: new Date(),
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
 * Get all habits with evaluated streaks and today's completion status (UC-06, UC-29)
 */
export const getHabits = async (userId: string, includeInactive = false, page?: number, limit?: number) => {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

  // Monday of this week for weekly count evaluation
  const dayOfWeek = (now.getDay() + 6) % 7; // 0 = Monday
  const startOfWeek = new Date(startOfToday);
  startOfWeek.setDate(startOfWeek.getDate() - dayOfWeek);

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
          date: { gte: startOfWeek, lte: endOfToday },
        },
      },
    },
  });

  const habitList = await Promise.all(
    habits.map(async (habit) => {
      // Lazy evaluation check: if not evaluated today, re-evaluate
      const lastEvalStr = habit.lastEvaluatedDate ? habit.lastEvaluatedDate.toISOString().split('T')[0] : null;
      const todayStr = now.toISOString().split('T')[0];

      let currentStreak = habit.currentStreak;
      let longestStreak = habit.longestStreak;
      let streakFreezes = habit.streakFreezes;

      if (lastEvalStr !== todayStr) {
        const evalRes = await evaluateHabitStreak(habit.id, habit);
        currentStreak = evalRes.currentStreak;
        longestStreak = evalRes.longestStreak;
        streakFreezes = evalRes.streakFreezes;
      }

      const todayLog = habit.logs.find(
        (l) => new Date(l.date).toISOString().split('T')[0] === todayStr
      );
      const isCompletedToday = Boolean(todayLog?.isCompleted);

      const weeklyLogs = habit.logs.filter((l) => l.isCompleted);
      const weeklyCompletionsCount = weeklyLogs.length;

      return {
        id: habit.id,
        name: habit.name,
        description: habit.description,
        frequency: habit.frequency,
        targetFrequencyCount: habit.targetFrequencyCount,
        targetFrequencyPeriod: habit.targetFrequencyPeriod,
        targetType: habit.targetType,
        targetValue: habit.targetValue,
        reminderTime: habit.reminderTime,
        currentStreak,
        longestStreak,
        streakFreezes,
        difficulty: habit.difficulty,
        weight: habit.weight,
        isActive: habit.isActive,
        category: habit.category,
        isCompletedToday,
        todayLog: todayLog || null,
        weeklyCompletionsCount,
      };
    })
  );

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
 * Get single habit details by ID with evaluated streak & recent 30-day logs
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

  // Run streak evaluation
  const evaluated = await evaluateHabitStreak(habit.id, habit);

  return {
    ...habit,
    currentStreak: evaluated.currentStreak,
    longestStreak: evaluated.longestStreak,
    streakFreezes: evaluated.streakFreezes,
  };
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

  const weight = data.weight ?? (data.difficulty ? getDifficultyWeight(data.difficulty) : habit.weight);

  const updatedHabit = await prisma.habit.update({
    where: { id: habitId },
    data: {
      ...data,
      weight,
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

  // Re-evaluate streak
  const streaks = await evaluateHabitStreak(habitId);

  invalidateDashboardCache(userId);

  return {
    log,
    currentStreak: streaks.currentStreak,
    longestStreak: streaks.longestStreak,
    streakFreezes: streaks.streakFreezes,
  };
};

/**
 * UC-29: Get Habit History (Heatmap Calendar with freezes)
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
  defaultStart.setDate(defaultStart.getDate() - 365); // 365 days of history for heatmap

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
  const completedLogs = logs.filter((l) => l.isCompleted && !l.wasFrozen).length;
  const frozenLogs = logs.filter((l) => l.wasFrozen).length;
  const completionRate = totalLogs > 0 ? Number(((completedLogs / totalLogs) * 100).toFixed(1)) : 0;

  return {
    habitId: habit.id,
    habitName: habit.name,
    currentStreak: habit.currentStreak,
    longestStreak: habit.longestStreak,
    streakFreezes: habit.streakFreezes,
    totalTrackedDays: totalLogs,
    completedDays: completedLogs,
    frozenDays: frozenLogs,
    completionRate,
    logs,
  };
};

/**
 * Equip or refill a streak freeze
 */
export const refillStreakFreeze = async (userId: string, habitId: string, count = 1) => {
  const habit = await prisma.habit.findFirst({
    where: { id: habitId, userId },
  });

  if (!habit) throw new ApiError(404, 'Habit not found');

  const updated = await prisma.habit.update({
    where: { id: habitId },
    data: { streakFreezes: (habit.streakFreezes || 0) + count },
  });

  return { habitId: updated.id, streakFreezes: updated.streakFreezes };
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
    select: { id: true, currentStreak: true, weight: true },
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

// ==========================================
// ROUTINES & HABIT CHAINS
// ==========================================

export const createRoutine = async (userId: string, data: CreateRoutineDTO) => {
  const routine = await prisma.routine.create({
    data: {
      name: data.name,
      description: data.description,
      icon: data.icon || 'routine',
      color: data.color || '#3B82F6',
      targetTime: data.targetTime,
      userId,
      items: data.habitIds && data.habitIds.length > 0
        ? {
            create: data.habitIds.map((hId, idx) => ({
              habitId: hId,
              order: idx,
            })),
          }
        : undefined,
    },
    include: {
      items: {
        include: {
          habit: { select: { id: true, name: true, targetType: true, targetValue: true, currentStreak: true } },
        },
        orderBy: { order: 'asc' },
      },
    },
  });

  return routine;
};

export const getRoutines = async (userId: string) => {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

  const routines = await prisma.routine.findMany({
    where: { userId },
    orderBy: { createdAt: 'asc' },
    include: {
      items: {
        include: {
          habit: {
            include: {
              logs: {
                where: { date: { gte: startOfToday, lte: endOfToday } },
                take: 1,
              },
            },
          },
        },
        orderBy: { order: 'asc' },
      },
    },
  });

  return routines.map((r) => {
    const totalHabits = r.items.length;
    const completedCount = r.items.filter(
      (item) => item.habit.logs.length > 0 && item.habit.logs[0].isCompleted
    ).length;
    const isCompletedToday = totalHabits > 0 && completedCount === totalHabits;

    return {
      id: r.id,
      name: r.name,
      description: r.description,
      icon: r.icon,
      color: r.color,
      targetTime: r.targetTime,
      totalHabits,
      completedCount,
      isCompletedToday,
      items: r.items.map((it) => ({
        id: it.id,
        order: it.order,
        habitId: it.habitId,
        habitName: it.habit.name,
        targetType: it.habit.targetType,
        targetValue: it.habit.targetValue,
        currentStreak: it.habit.currentStreak,
        isCompletedToday: it.habit.logs.length > 0 && it.habit.logs[0].isCompleted,
      })),
    };
  });
};

export const getRoutineById = async (userId: string, routineId: string) => {
  const routine = await prisma.routine.findFirst({
    where: { id: routineId, userId },
    include: {
      items: {
        include: {
          habit: true,
        },
        orderBy: { order: 'asc' },
      },
    },
  });

  if (!routine) throw new ApiError(404, 'Routine not found');
  return routine;
};

export const updateRoutine = async (userId: string, routineId: string, data: UpdateRoutineDTO) => {
  const existing = await prisma.routine.findFirst({
    where: { id: routineId, userId },
  });

  if (!existing) throw new ApiError(404, 'Routine not found');

  // If habitIds provided, delete old items and recreate
  if (data.habitIds) {
    await prisma.routineItem.deleteMany({ where: { routineId } });
    await prisma.routineItem.createMany({
      data: data.habitIds.map((hId, idx) => ({
        routineId,
        habitId: hId,
        order: idx,
      })),
    });
  }

  const updated = await prisma.routine.update({
    where: { id: routineId },
    data: {
      name: data.name,
      description: data.description,
      icon: data.icon,
      color: data.color,
      targetTime: data.targetTime,
    },
    include: {
      items: {
        include: { habit: true },
        orderBy: { order: 'asc' },
      },
    },
  });

  return updated;
};

export const deleteRoutine = async (userId: string, routineId: string) => {
  const existing = await prisma.routine.findFirst({
    where: { id: routineId, userId },
  });

  if (!existing) throw new ApiError(404, 'Routine not found');

  await prisma.routine.delete({ where: { id: routineId } });
  return { message: 'Routine deleted successfully' };
};

/**
 * 1-Tap Complete Entire Routine
 */
export const completeRoutine = async (userId: string, routineId: string, dateStr?: string) => {
  const routine = await prisma.routine.findFirst({
    where: { id: routineId, userId },
    include: { items: true },
  });

  if (!routine) throw new ApiError(404, 'Routine not found');

  const rawDate = dateStr ? new Date(dateStr) : new Date();
  const normalizedDate = new Date(rawDate.getFullYear(), rawDate.getMonth(), rawDate.getDate());

  const results = await Promise.all(
    routine.items.map(async (item) => {
      await prisma.habitLog.upsert({
        where: {
          habitId_date: {
            habitId: item.habitId,
            date: normalizedDate,
          },
        },
        update: { isCompleted: true },
        create: {
          habitId: item.habitId,
          date: normalizedDate,
          isCompleted: true,
        },
      });

      return evaluateHabitStreak(item.habitId);
    })
  );

  invalidateDashboardCache(userId);

  return {
    routineId: routine.id,
    completedHabitsCount: routine.items.length,
    results,
  };
};

// ==========================================
// BEHAVIORAL CORRELATION INSIGHTS ENGINE
// ==========================================

export const getHabitCorrelations = async (userId: string) => {
  const activeHabits = await prisma.habit.findMany({
    where: { userId, isActive: true },
    select: { id: true, name: true },
  });

  if (activeHabits.length < 2) {
    return [];
  }

  const sixtyDaysAgo = new Date();
  sixtyDaysAgo.setDate(sixtyDaysAgo.getDate() - 60);

  const logs = await prisma.habitLog.findMany({
    where: {
      habit: { userId },
      isCompleted: true,
      date: { gte: sixtyDaysAgo },
    },
    select: { habitId: true, date: true },
  });

  // Map habitId -> Set of date strings (YYYY-MM-DD)
  const habitDates = new Map<string, Set<string>>();
  for (const h of activeHabits) {
    habitDates.set(h.id, new Set<string>());
  }

  for (const log of logs) {
    const dStr = new Date(log.date).toISOString().split('T')[0];
    if (habitDates.has(log.habitId)) {
      habitDates.get(log.habitId)!.add(dStr);
    }
  }

  // Total distinct days observed in logs
  const allDistinctDates = new Set<string>();
  for (const s of habitDates.values()) {
    for (const d of s) allDistinctDates.add(d);
  }
  const totalDaysObserved = Math.max(allDistinctDates.size, 14);

  const insights: Array<{
    habitAId: string;
    habitAName: string;
    habitBId: string;
    habitBName: string;
    probBGivenA: number;
    probBGivenNotA: number;
    liftPercent: number;
    insightText: string;
  }> = [];

  for (let i = 0; i < activeHabits.length; i++) {
    for (let j = 0; j < activeHabits.length; j++) {
      if (i === j) continue;
      const hA = activeHabits[i];
      const hB = activeHabits[j];

      const datesA = habitDates.get(hA.id)!;
      const datesB = habitDates.get(hB.id)!;

      const daysA = datesA.size;
      const daysNotA = totalDaysObserved - daysA;

      if (daysA < 5 || daysNotA < 5) continue;

      let bothCount = 0;
      for (const d of datesA) {
        if (datesB.has(d)) bothCount++;
      }

      let bWithoutACount = 0;
      for (const d of datesB) {
        if (!datesA.has(d)) bWithoutACount++;
      }

      const pBGivenA = bothCount / daysA;
      const pBGivenNotA = bWithoutACount / daysNotA;
      const lift = pBGivenA - pBGivenNotA;

      if (lift >= 0.20) {
        const percentHigher = Math.round(lift * 100);
        insights.push({
          habitAId: hA.id,
          habitAName: hA.name,
          habitBId: hB.id,
          habitBName: hB.name,
          probBGivenA: Number(pBGivenA.toFixed(2)),
          probBGivenNotA: Number(pBGivenNotA.toFixed(2)),
          liftPercent: percentHigher,
          insightText: `You complete "${hB.name}" ${percentHigher}% more often on days you also do "${hA.name}".`,
        });
      }
    }
  }

  // Sort by highest lift
  insights.sort((a, b) => b.liftPercent - a.liftPercent);

  return insights.slice(0, 5);
};

export default {
  createHabit,
  getHabits,
  getHabitById,
  updateHabit,
  logHabitCompletion,
  getHabitHistory,
  refillStreakFreeze,
  deleteHabit,
  getHabitsSummary,
  evaluateHabitStreak,
  recalculateHabitStreak,
  createRoutine,
  getRoutines,
  getRoutineById,
  updateRoutine,
  deleteRoutine,
  completeRoutine,
  getHabitCorrelations,
};
