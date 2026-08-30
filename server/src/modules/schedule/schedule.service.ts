import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';

export interface CreateEventDTO {
  title: string;
  description?: string | null;
  location?: string | null;
  color?: string;
  startTime: Date | string;
  endTime: Date | string;
  isRecurring?: boolean;
  recurrenceRule?: string | null;
}

export interface UpdateEventDTO {
  title?: string;
  description?: string | null;
  location?: string | null;
  color?: string;
  startTime?: Date | string;
  endTime?: Date | string;
  isRecurring?: boolean;
  recurrenceRule?: string | null;
}

/**
 * Check for overlapping schedule conflicts (UC-18, UC-19)
 */
export const checkTimeConflict = async (
  userId: string,
  startTime: Date,
  endTime: Date,
  excludeEventId?: string
) => {
  const conflictingEvents = await prisma.scheduleEvent.findMany({
    where: {
      userId,
      id: excludeEventId ? { not: excludeEventId } : undefined,
      OR: [
        {
          startTime: { lt: endTime },
          endTime: { gt: startTime },
        },
      ],
    },
  });

  return conflictingEvents;
};

/**
 * UC-18: Create Schedule Event
 */
export const createEvent = async (userId: string, data: CreateEventDTO) => {
  const startTime = new Date(data.startTime);
  const endTime = new Date(data.endTime);

  if (startTime >= endTime) {
    throw new ApiError(400, 'Start time must be strictly before end time');
  }

  // Check for conflicts (warn or attach info)
  const conflicts = await checkTimeConflict(userId, startTime, endTime);

  const event = await prisma.scheduleEvent.create({
    data: {
      title: data.title,
      description: data.description,
      location: data.location,
      color: data.color || '#6366F1',
      startTime,
      endTime,
      isRecurring: data.isRecurring || false,
      recurrenceRule: data.recurrenceRule,
      userId,
    },
  });

  return {
    event,
    hasConflict: conflicts.length > 0,
    conflicts: conflicts.map((c) => ({ id: c.id, title: c.title, startTime: c.startTime, endTime: c.endTime })),
  };
};

/**
 * UC-21: View Daily Schedule Timeline
 */
export const getDailySchedule = async (userId: string, targetDate?: Date | string) => {
  const baseDate = targetDate ? new Date(targetDate) : new Date();
  const startOfDay = new Date(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate(), 0, 0, 0);
  const endOfDay = new Date(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate(), 23, 59, 59, 999);

  const events = await prisma.scheduleEvent.findMany({
    where: {
      userId,
      startTime: { lte: endOfDay },
      endTime: { gte: startOfDay },
    },
    orderBy: { startTime: 'asc' },
  });

  // Also include tasks due today to form a complete unified timeline
  const tasksDueToday = await prisma.task.findMany({
    where: {
      userId,
      dueDate: { gte: startOfDay, lte: endOfDay },
    },
    select: {
      id: true,
      title: true,
      priority: true,
      status: true,
      isCompleted: true,
      dueDate: true,
      estimatedMinutes: true,
    },
  });

  return {
    date: startOfDay.toISOString().split('T')[0],
    events,
    tasksDueToday,
    totalEvents: events.length,
  };
};

/**
 * UC-22: View Weekly Schedule
 */
export const getWeeklySchedule = async (userId: string, startDateQuery?: Date | string) => {
  const baseDate = startDateQuery ? new Date(startDateQuery) : new Date();
  // Get start of week (Sunday or Monday)
  const day = baseDate.getDay();
  const diff = baseDate.getDate() - day + (day === 0 ? -6 : 1); // Monday as start of week
  const startOfWeek = new Date(baseDate.setDate(diff));
  startOfWeek.setHours(0, 0, 0, 0);

  const endOfWeek = new Date(startOfWeek);
  endOfWeek.setDate(endOfWeek.getDate() + 6);
  endOfWeek.setHours(23, 59, 59, 999);

  const events = await prisma.scheduleEvent.findMany({
    where: {
      userId,
      startTime: { lte: endOfWeek },
      endTime: { gte: startOfWeek },
    },
    orderBy: { startTime: 'asc' },
  });

  // Group events by day (0 to 6)
  const days: Record<string, typeof events> = {};
  for (let i = 0; i < 7; i++) {
    const currentDay = new Date(startOfWeek);
    currentDay.setDate(currentDay.getDate() + i);
    const dateKey = currentDay.toISOString().split('T')[0];
    days[dateKey] = [];
  }

  events.forEach((event) => {
    const eventDateKey = new Date(event.startTime).toISOString().split('T')[0];
    if (days[eventDateKey]) {
      days[eventDateKey].push(event);
    }
  });

  return {
    startOfWeek: startOfWeek.toISOString().split('T')[0],
    endOfWeek: endOfWeek.toISOString().split('T')[0],
    eventsByDay: days,
    totalEvents: events.length,
  };
};

/**
 * Get Event Details by ID
 */
export const getEventById = async (userId: string, eventId: string) => {
  const event = await prisma.scheduleEvent.findFirst({
    where: { id: eventId, userId },
  });

  if (!event) {
    throw new ApiError(404, 'Schedule event not found');
  }

  return event;
};

/**
 * UC-19: Update Schedule Event
 */
export const updateEvent = async (userId: string, eventId: string, data: UpdateEventDTO) => {
  const existingEvent = await prisma.scheduleEvent.findFirst({
    where: { id: eventId, userId },
  });

  if (!existingEvent) {
    throw new ApiError(404, 'Schedule event not found');
  }

  const startTime = data.startTime ? new Date(data.startTime) : existingEvent.startTime;
  const endTime = data.endTime ? new Date(data.endTime) : existingEvent.endTime;

  if (startTime >= endTime) {
    throw new ApiError(400, 'Start time must be strictly before end time');
  }

  const conflicts = await checkTimeConflict(userId, startTime, endTime, eventId);

  const updatedEvent = await prisma.scheduleEvent.update({
    where: { id: eventId },
    data: {
      ...data,
      startTime,
      endTime,
    },
  });

  return {
    event: updatedEvent,
    hasConflict: conflicts.length > 0,
    conflicts: conflicts.map((c) => ({ id: c.id, title: c.title, startTime: c.startTime, endTime: c.endTime })),
  };
};

/**
 * UC-20: Delete Schedule Event
 */
export const deleteEvent = async (userId: string, eventId: string) => {
  const event = await prisma.scheduleEvent.findFirst({
    where: { id: eventId, userId },
  });

  if (!event) {
    throw new ApiError(404, 'Schedule event not found');
  }

  await prisma.scheduleEvent.delete({ where: { id: eventId } });
  return { message: 'Event removed from schedule successfully' };
};

export default {
  createEvent,
  getDailySchedule,
  getWeeklySchedule,
  getEventById,
  updateEvent,
  deleteEvent,
  checkTimeConflict,
};
