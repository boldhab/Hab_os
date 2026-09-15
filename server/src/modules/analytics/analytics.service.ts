import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';

export interface CreateTimeEntryDTO {
  startTime: Date | string;
  endTime: Date | string;
  duration: number; // in seconds
  taskId?: string | null;
}

export interface TimeEntryQuery {
  taskId?: string;
  startDate?: Date | string;
  endDate?: Date | string;
  page?: number;
  limit?: number;
}

// ==========================================
// 1. TIME ENTRIES (UC-134 to UC-138)
// ==========================================

export const createTimeEntry = async (userId: string, data: CreateTimeEntryDTO) => {
  if (data.taskId) {
    const task = await prisma.task.findFirst({
      where: { id: data.taskId, userId },
    });
    if (!task) throw new ApiError(404, 'Associated task not found');
  }

  const timeEntry = await prisma.timeEntry.create({
    data: {
      startTime: new Date(data.startTime),
      endTime: new Date(data.endTime),
      duration: data.duration,
      taskId: data.taskId || null,
      userId,
    },
    include: {
      task: { select: { id: true, title: true, priority: true } },
    },
  });

  return timeEntry;
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
// 2. CROSS-DOMAIN ANALYTICS & RETROSPECTIVE (UC-139 to UC-146)
// ==========================================

export const getCrossDomainRetrospective = async (userId: string) => {
  const now = new Date();
  const startOfPast7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  const [focusSessions, completedTasks, workouts, habitLogs, timeEntries] = await Promise.all([
    prisma.focusSession.findMany({
      where: { userId, startTime: { gte: startOfPast7Days } },
    }),
    prisma.task.findMany({
      where: { userId, isCompleted: true, completedAt: { gte: startOfPast7Days } },
      select: { id: true, title: true, priority: true },
    }),
    prisma.workout.findMany({
      where: { userId, date: { gte: startOfPast7Days } },
    }),
    prisma.habitLog.findMany({
      where: {
        habit: { userId },
        isCompleted: true,
        date: { gte: startOfPast7Days },
      },
    }),
    prisma.timeEntry.findMany({
      where: { userId, startTime: { gte: startOfPast7Days } },
    }),
  ]);

  const totalFocusMinutes = focusSessions.reduce((acc, f) => acc + f.durationMinutes, 0);
  const totalTrackedSeconds = timeEntries.reduce((acc, t) => acc + (t.duration || 0), 0);

  // Daily distribution (last 7 days)
  const dailyFocusHours: Record<string, number> = {};
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
    const dateKey = d.toISOString().split('T')[0];
    dailyFocusHours[dateKey] = 0;
  }

  focusSessions.forEach((f) => {
    const key = new Date(f.startTime).toISOString().split('T')[0];
    if (dailyFocusHours[key] !== undefined) {
      dailyFocusHours[key] = Number((dailyFocusHours[key] + f.durationMinutes / 60).toFixed(1));
    }
  });

  return {
    period: 'LAST_7_DAYS',
    summary: {
      totalFocusHours: Number((totalFocusMinutes / 60).toFixed(1)),
      totalTrackedHours: Number((totalTrackedSeconds / 3600).toFixed(1)),
      completedTasksCount: completedTasks.length,
      workoutsCount: workouts.length,
      habitsCompletedCount: habitLogs.length,
    },
    dailyFocusHours,
    completedTasks,
  };
};

export default {
  createTimeEntry,
  getTimeEntries,
  deleteTimeEntry,
  getCrossDomainRetrospective,
};
