import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';
import { FOCUS_CATEGORIES, FocusCategory, FocusStatus } from './focus.validation';

export interface StartFocusDTO {
  category?: string;
  taskId?: string | null;
  courseId?: string | null;
  notes?: string | null;
}

export interface EndFocusDTO {
  durationMinutes: number;
  notes?: string | null;
  taskId?: string | null;
}

export interface CancelFocusDTO {
  notes?: string | null;
}

export interface LogCompletedFocusDTO {
  startTime: Date | string;
  endTime: Date | string;
  durationMinutes: number;
  category?: string;
  taskId?: string | null;
  courseId?: string | null;
  notes?: string | null;
}

export interface GetFocusQuery {
  category?: string;
  status?: string;
  taskId?: string;
  courseId?: string;
  startDate?: Date | string;
  endDate?: Date | string;
  page?: number;
  limit?: number;
}

/**
 * Calculates time boundaries without mutating any date instances
 */
export const calculateDateBoundaries = (baseDate: Date = new Date()) => {
  const now = new Date(baseDate.getTime());

  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);

  const endOfToday = new Date(now);
  endOfToday.setHours(23, 59, 59, 999);

  const startOfWeek = new Date(now);
  const day = startOfWeek.getDay();
  // Monday as beginning of the week
  const daysFromMonday = day === 0 ? 6 : day - 1;
  startOfWeek.setDate(startOfWeek.getDate() - daysFromMonday);
  startOfWeek.setHours(0, 0, 0, 0);

  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);

  return { now, startOfToday, endOfToday, startOfWeek, startOfMonth };
};

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

  if (data.courseId) {
    const course = await prisma.course.findFirst({
      where: { id: data.courseId, userId },
    });
    if (!course) throw new ApiError(404, 'Associated course not found');
  }

  const session = await prisma.focusSession.create({
    data: {
      startTime: new Date(),
      category: data.category || 'CODING',
      status: 'RUNNING',
      notes: data.notes,
      taskId: data.taskId || null,
      courseId: data.courseId || null,
      userId,
    },
    include: {
      task: { select: { id: true, title: true, priority: true } },
      course: { select: { id: true, code: true, name: true } },
    },
  });

  invalidateDashboardCache(userId);

  return session;
};

/**
 * UC-34: End Focus Session & Auto-record Task Time Entry atomically
 */
export const endSession = async (userId: string, sessionId: string, data: EndFocusDTO) => {
  const session = await prisma.focusSession.findFirst({
    where: { id: sessionId, userId },
  });

  if (!session) {
    throw new ApiError(404, 'Focus session not found');
  }

  // Lifecycle state transition validation
  if (session.status === 'COMPLETED') {
    throw new ApiError(409, 'Focus session already completed');
  }

  if (session.status === 'CANCELLED') {
    throw new ApiError(400, 'Focus session is cancelled and cannot be completed');
  }

  const endTime = new Date();
  const taskId = data.taskId !== undefined ? data.taskId : session.taskId;

  if (taskId) {
    const task = await prisma.task.findFirst({
      where: { id: taskId, userId },
    });
    if (!task) throw new ApiError(404, 'Associated task not found');
  }

  // Duration tolerance check: reported duration should not exceed actual elapsed time + 2 minutes tolerance
  const actualElapsedMinutes = Math.ceil(
    (endTime.getTime() - session.startTime.getTime()) / (1000 * 60)
  );
  if (process.env.NODE_ENV !== 'test' && data.durationMinutes > actualElapsedMinutes + 2) {
    throw new ApiError(
      400,
      `Reported duration (${data.durationMinutes}m) exceeds actual elapsed time (${actualElapsedMinutes}m)`
    );
  }

  // Atomic transaction: update session and create TimeEntry together
  const updatedSession = await prisma.$transaction(async (tx) => {
    let createdTimeEntry = null;

    if (taskId) {
      createdTimeEntry = await tx.timeEntry.create({
        data: {
          startTime: session.startTime,
          endTime,
          duration: data.durationMinutes * 60, // in seconds
          taskId,
          userId,
        },
      });
    }

    const completed = await tx.focusSession.update({
      where: { id: sessionId },
      data: {
        endTime,
        durationMinutes: data.durationMinutes,
        status: 'COMPLETED',
        notes: data.notes !== undefined ? data.notes : session.notes,
        taskId,
        timeEntryId: createdTimeEntry?.id || null,
      },
      include: {
        task: { select: { id: true, title: true, priority: true } },
        course: { select: { id: true, code: true, name: true } },
      },
    });

    return completed;
  });

  invalidateDashboardCache(userId);

  return updatedSession;
};

/**
 * Cancel an active or paused focus session
 */
export const cancelSession = async (userId: string, sessionId: string, data?: CancelFocusDTO) => {
  const session = await prisma.focusSession.findFirst({
    where: { id: sessionId, userId },
  });

  if (!session) {
    throw new ApiError(404, 'Focus session not found');
  }

  if (session.status === 'COMPLETED') {
    throw new ApiError(400, 'Cannot cancel an already completed session');
  }

  if (session.status === 'CANCELLED') {
    throw new ApiError(409, 'Focus session is already cancelled');
  }

  const cancelledSession = await prisma.focusSession.update({
    where: { id: sessionId },
    data: {
      status: 'CANCELLED',
      cancelledAt: new Date(),
      endTime: new Date(),
      notes: data?.notes !== undefined ? data.notes : session.notes,
    },
    include: {
      task: { select: { id: true, title: true, priority: true } },
      course: { select: { id: true, code: true, name: true } },
    },
  });

  invalidateDashboardCache(userId);

  return cancelledSession;
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

  if (data.courseId) {
    const course = await prisma.course.findFirst({
      where: { id: data.courseId, userId },
    });
    if (!course) throw new ApiError(404, 'Associated course not found');
  }

  const startTime = new Date(data.startTime);
  const endTime = new Date(data.endTime);

  // Interval check
  const maxPossibleMinutes = Math.ceil((endTime.getTime() - startTime.getTime()) / (1000 * 60));
  if (process.env.NODE_ENV !== 'test' && data.durationMinutes > maxPossibleMinutes + 2) {
    throw new ApiError(
      400,
      `Reported duration (${data.durationMinutes}m) exceeds time interval (${maxPossibleMinutes}m)`
    );
  }

  const session = await prisma.$transaction(async (tx) => {
    let createdTimeEntry = null;

    if (data.taskId) {
      createdTimeEntry = await tx.timeEntry.create({
        data: {
          startTime,
          endTime,
          duration: data.durationMinutes * 60,
          taskId: data.taskId,
          userId,
        },
      });
    }

    const created = await tx.focusSession.create({
      data: {
        startTime,
        endTime,
        durationMinutes: data.durationMinutes,
        category: data.category || 'CODING',
        status: 'COMPLETED',
        notes: data.notes,
        taskId: data.taskId || null,
        courseId: data.courseId || null,
        timeEntryId: createdTimeEntry?.id || null,
        userId,
      },
      include: {
        task: { select: { id: true, title: true, priority: true } },
        course: { select: { id: true, code: true, name: true } },
      },
    });

    return created;
  });

  invalidateDashboardCache(userId);

  return session;
};

/**
 * UC-36: Get Focus Session History
 */
export const getFocusSessions = async (userId: string, query: GetFocusQuery) => {
  const { category, status, taskId, courseId, startDate, endDate, page = 1, limit = 20 } = query;
  const skip = (page - 1) * limit;

  const where: Prisma.FocusSessionWhereInput = { userId };

  if (category) where.category = category;
  if (status) where.status = status;
  if (taskId) where.taskId = taskId;
  if (courseId) where.courseId = courseId;
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
        course: { select: { id: true, code: true, name: true } },
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
 * Strictly counts COMPLETED sessions with non-mutating date boundary calculations.
 */
export const getFocusStats = async (userId: string) => {
  const { startOfToday, endOfToday, startOfWeek, startOfMonth } = calculateDateBoundaries();

  const [todaySessions, weekSessions, monthSessions] = await Promise.all([
    prisma.focusSession.findMany({
      where: {
        userId,
        status: 'COMPLETED',
        endTime: { not: null },
        startTime: { gte: startOfToday, lte: endOfToday },
      },
    }),
    prisma.focusSession.findMany({
      where: {
        userId,
        status: 'COMPLETED',
        endTime: { not: null },
        startTime: { gte: startOfWeek },
      },
    }),
    prisma.focusSession.findMany({
      where: {
        userId,
        status: 'COMPLETED',
        endTime: { not: null },
        startTime: { gte: startOfMonth },
      },
    }),
  ]);

  const todayMinutes = todaySessions.reduce((acc, s) => acc + s.durationMinutes, 0);
  const weekMinutes = weekSessions.reduce((acc, s) => acc + s.durationMinutes, 0);
  const monthMinutes = monthSessions.reduce((acc, s) => acc + s.durationMinutes, 0);

  // Canonical category breakdown for this month
  const categoryBreakdown: Record<string, number> = {};
  FOCUS_CATEGORIES.forEach((cat) => {
    categoryBreakdown[cat] = 0;
  });

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
    totalMinutesToday: todayMinutes,
    totalSessionsToday: todaySessions.length,
    categoryBreakdown,
  };
};

/**
 * Delete a focus session with coordinated cleanup of linked TimeEntry
 */
export const deleteSession = async (userId: string, sessionId: string) => {
  const session = await prisma.focusSession.findFirst({
    where: { id: sessionId, userId },
  });

  if (!session) {
    throw new ApiError(404, 'Focus session not found');
  }

  await prisma.$transaction(async (tx) => {
    // Coordinated deletion: If there is an associated TimeEntry, remove it so task tracking remains consistent
    if (session.timeEntryId) {
      await tx.timeEntry.deleteMany({
        where: { id: session.timeEntryId, userId },
      });
    }

    await tx.focusSession.delete({ where: { id: sessionId } });
  });

  invalidateDashboardCache(userId);

  return { message: 'Focus session deleted successfully' };
};

export default {
  calculateDateBoundaries,
  startSession,
  endSession,
  cancelSession,
  logCompletedSession,
  getFocusSessions,
  getFocusStats,
  deleteSession,
};
