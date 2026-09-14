import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';

export interface StartFocusDTO {
  category?: string;
  taskId?: string | null;
  notes?: string | null;
}

export interface EndFocusDTO {
  durationMinutes: number;
  notes?: string | null;
  taskId?: string | null;
}

export interface LogCompletedFocusDTO {
  startTime: Date | string;
  endTime: Date | string;
  durationMinutes: number;
  category?: string;
  taskId?: string | null;
  notes?: string | null;
}

export interface GetFocusQuery {
  category?: string;
  taskId?: string;
  startDate?: Date | string;
  endDate?: Date | string;
  page?: number;
  limit?: number;
}

/**
 * UC-31: Start Focus Session
 */
export const startSession = async (userId: string, data: StartFocusDTO) => {
  if (data.taskId) {
    const task = await prisma.task.findFirst({
      where: { id: data.taskId, userId },
    });
    if (!task) throw new ApiError(404, 'Associated task not found');
  }

  const session = await prisma.focusSession.create({
    data: {
      startTime: new Date(),
      category: data.category || 'CODING',
      notes: data.notes,
      taskId: data.taskId || null,
      userId,
    },
    include: {
      task: { select: { id: true, title: true, priority: true } },
    },
  });

  invalidateDashboardCache(userId);

  return session;
};

/**
 * UC-34: End Focus Session & Auto-record Task Time Entry
 */
export const endSession = async (userId: string, sessionId: string, data: EndFocusDTO) => {
  const session = await prisma.focusSession.findFirst({
    where: { id: sessionId, userId },
  });

  if (!session) {
    throw new ApiError(404, 'Focus session not found');
  }

  const endTime = new Date();
  const taskId = data.taskId !== undefined ? data.taskId : session.taskId;

  const updatedSession = await prisma.focusSession.update({
    where: { id: sessionId },
    data: {
      endTime,
      durationMinutes: data.durationMinutes,
      notes: data.notes !== undefined ? data.notes : session.notes,
      taskId,
    },
    include: {
      task: { select: { id: true, title: true, priority: true } },
    },
  });

  // If associated with a task, record a corresponding TimeEntry
  if (taskId) {
    await prisma.timeEntry.create({
      data: {
        startTime: session.startTime,
        endTime,
        duration: data.durationMinutes * 60, // in seconds
        taskId,
        userId,
      },
    });
  }

  invalidateDashboardCache(userId);

  return updatedSession;
};

/**
 * Log already completed focus session (e.g. Pomodoro timer completed on mobile)
 */
export const logCompletedSession = async (userId: string, data: LogCompletedFocusDTO) => {
  if (data.taskId) {
    const task = await prisma.task.findFirst({
      where: { id: data.taskId, userId },
    });
    if (!task) throw new ApiError(404, 'Associated task not found');
  }

  const startTime = new Date(data.startTime);
  const endTime = new Date(data.endTime);

  const session = await prisma.focusSession.create({
    data: {
      startTime,
      endTime,
      durationMinutes: data.durationMinutes,
      category: data.category || 'CODING',
      notes: data.notes,
      taskId: data.taskId || null,
      userId,
    },
    include: {
      task: { select: { id: true, title: true, priority: true } },
    },
  });

  if (data.taskId) {
    await prisma.timeEntry.create({
      data: {
        startTime,
        endTime,
        duration: data.durationMinutes * 60,
        taskId: data.taskId,
        userId,
      },
    });
  }

  invalidateDashboardCache(userId);

  return session;
};

/**
 * UC-36: Get Focus Session History
 */
export const getFocusSessions = async (userId: string, query: GetFocusQuery) => {
  const { category, taskId, startDate, endDate, page = 1, limit = 20 } = query;
  const skip = (page - 1) * limit;

  const where: Prisma.FocusSessionWhereInput = { userId };

  if (category) where.category = category;
  if (taskId) where.taskId = taskId;
  if (startDate || endDate) {
    where.startTime = {
      gte: startDate ? new Date(startDate) : undefined,
      lte: endDate ? new Date(endDate) : undefined,
    };
  }

  const [sessions, total] = await Promise.all([
    prisma.focusSession.findMany({
      where,
      skip,
      take: limit,
      orderBy: { startTime: 'desc' },
      include: {
        task: { select: { id: true, title: true, priority: true } },
      },
    }),
    prisma.focusSession.count({ where }),
  ]);

  return {
    sessions,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    },
  };
};

/**
 * UC-37: Calculate Focus Time Metrics (Today, This Week, This Month, Category Breakdown)
 */
export const getFocusStats = async (userId: string) => {
  const now = new Date();

  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

  const dayOfWeek = now.getDay();
  const diffToMonday = now.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1);
  const startOfWeek = new Date(now.setDate(diffToMonday));
  startOfWeek.setHours(0, 0, 0, 0);

  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);

  const [todaySessions, weekSessions, monthSessions] = await Promise.all([
    prisma.focusSession.findMany({
      where: {
        userId,
        startTime: { gte: startOfToday, lte: endOfToday },
      },
    }),
    prisma.focusSession.findMany({
      where: {
        userId,
        startTime: { gte: startOfWeek },
      },
    }),
    prisma.focusSession.findMany({
      where: {
        userId,
        startTime: { gte: startOfMonth },
      },
    }),
  ]);

  const todayMinutes = todaySessions.reduce((acc, s) => acc + s.durationMinutes, 0);
  const weekMinutes = weekSessions.reduce((acc, s) => acc + s.durationMinutes, 0);
  const monthMinutes = monthSessions.reduce((acc, s) => acc + s.durationMinutes, 0);

  // Category breakdown for this month
  const categoryBreakdown: Record<string, number> = {
    CODING: 0,
    STUDY: 0,
    PROJECT: 0,
    READING: 0,
    OTHER: 0,
  };

  monthSessions.forEach((s) => {
    categoryBreakdown[s.category] = (categoryBreakdown[s.category] || 0) + s.durationMinutes;
  });

  return {
    today: {
      minutes: todayMinutes,
      hours: Number((todayMinutes / 60).toFixed(1)),
      sessionsCount: todaySessions.length,
    },
    thisWeek: {
      minutes: weekMinutes,
      hours: Number((weekMinutes / 60).toFixed(1)),
      sessionsCount: weekSessions.length,
    },
    thisMonth: {
      minutes: monthMinutes,
      hours: Number((monthMinutes / 60).toFixed(1)),
      sessionsCount: monthSessions.length,
    },
    categoryBreakdown,
  };
};

/**
 * Delete a focus session
 */
export const deleteSession = async (userId: string, sessionId: string) => {
  const session = await prisma.focusSession.findFirst({
    where: { id: sessionId, userId },
  });

  if (!session) {
    throw new ApiError(404, 'Focus session not found');
  }

  await prisma.focusSession.delete({ where: { id: sessionId } });

  invalidateDashboardCache(userId);

  return { message: 'Focus session deleted successfully' };
};

export default {
  startSession,
  endSession,
  logCompletedSession,
  getFocusSessions,
  getFocusStats,
  deleteSession,
};
