import prisma from '../../config/db';
import ApiError from '../../common/apiError';

export interface CreateNotificationDTO {
  title: string;
  message: string;
  type?: string;
  scheduledFor?: Date | string | null;
  metadata?: Record<string, unknown> | null;
}

/**
 * Get user notifications with optional unread filter (UC-175)
 */
export const getNotifications = async (userId: string, unreadOnly = false, limit = 50) => {
  const notifications = await prisma.notification.findMany({
    where: {
      userId,
      ...(unreadOnly ? { isRead: false } : {}),
    },
    orderBy: { createdAt: 'desc' },
    take: limit,
  });

  return notifications;
};

/**
 * Get unread notification count badge
 */
export const getUnreadCount = async (userId: string) => {
  const count = await prisma.notification.count({
    where: { userId, isRead: false },
  });

  return { unreadCount: count };
};

/**
 * Create a new notification (UC-178 to UC-182)
 */
export const createNotification = async (userId: string, data: CreateNotificationDTO) => {
  const notification = await prisma.notification.create({
    data: {
      title: data.title,
      message: data.message,
      type: data.type || 'GENERAL',
      scheduledFor: data.scheduledFor ? new Date(data.scheduledFor) : null,
      sentAt: new Date(),
      metadata: data.metadata ? JSON.parse(JSON.stringify(data.metadata)) : undefined,
      userId,
    },
  });

  return notification;
};

/**
 * Mark notification as read (UC-176)
 */
export const markAsRead = async (userId: string, notificationId: string) => {
  const existing = await prisma.notification.findFirst({
    where: { id: notificationId, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Notification not found');
  }

  const updated = await prisma.notification.update({
    where: { id: notificationId },
    data: { isRead: true },
  });

  return updated;
};

/**
 * Mark all notifications as read (UC-176)
 */
export const markAllAsRead = async (userId: string) => {
  await prisma.notification.updateMany({
    where: { userId, isRead: false },
    data: { isRead: true },
  });

  return { message: 'All notifications marked as read' };
};

/**
 * Delete a notification (UC-177)
 */
export const deleteNotification = async (userId: string, notificationId: string) => {
  const existing = await prisma.notification.findFirst({
    where: { id: notificationId, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Notification not found');
  }

  await prisma.notification.delete({ where: { id: notificationId } });
  return { message: 'Notification deleted successfully' };
};

/**
 * Clear all notifications (UC-177)
 */
export const clearAllNotifications = async (userId: string) => {
  await prisma.notification.deleteMany({ where: { userId } });
  return { message: 'All notifications cleared' };
};

/**
 * Scan database and generate smart alerts for upcoming deadlines, habits, and budgets with 12h deduplication (UC-178 to UC-182)
 */
export const generateContextualAlerts = async (userId: string) => {
  const now = new Date();
  const next24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const next7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
  const twelveHoursAgo = new Date(now.getTime() - 12 * 60 * 60 * 1000);

  const [urgentTasks, upcomingExams, pendingStreakHabits] = await Promise.all([
    prisma.task.findMany({
      where: {
        userId,
        isCompleted: false,
        dueDate: { gte: now, lte: next24Hours },
      },
      take: 3,
    }),
    prisma.exam.findMany({
      where: {
        course: { userId },
        examDate: { gte: now, lte: next7Days },
      },
      take: 2,
      include: { course: { select: { name: true } } },
    }),
    prisma.habit.findMany({
      where: {
        userId,
        isActive: true,
        currentStreak: { gte: 3 },
      },
      include: {
        logs: { where: { date: { gte: startOfToday } } },
      },
    }),
  ]);

  const createdAlerts = [];

  const createAlertIfUnique = async (data: CreateNotificationDTO) => {
    const existing = await prisma.notification.findFirst({
      where: {
        userId,
        type: data.type || 'GENERAL',
        title: data.title,
        createdAt: { gte: twelveHoursAgo },
      },
    });

    if (existing) return null;
    return createNotification(userId, data);
  };

  // Task Due Reminders (UC-178)
  for (const task of urgentTasks) {
    const alert = await createAlertIfUnique({
      title: `Task Due Soon: ${task.title}`,
      message: `Priority ${task.priority} task is due within 24 hours.`,
      type: 'TASK_REMINDER',
      metadata: { taskId: task.id },
    });
    if (alert) createdAlerts.push(alert);
  }

  // Exam Countdown Alerts (UC-180)
  for (const exam of upcomingExams) {
    const alert = await createAlertIfUnique({
      title: `Upcoming Exam: ${exam.title} (${exam.course.name})`,
      message: `Exam scheduled on ${new Date(exam.examDate).toLocaleDateString()}.`,
      type: 'EXAM_REMINDER',
      metadata: { examId: exam.id },
    });
    if (alert) createdAlerts.push(alert);
  }

  // Streak Protection Alerts (UC-182)
  for (const habit of pendingStreakHabits) {
    if (habit.logs.length === 0 || !habit.logs[0].isCompleted) {
      const alert = await createAlertIfUnique({
        title: `Protect Your ${habit.currentStreak}-Day Streak!`,
        message: `Don't break the chain for "${habit.name}". Log it before midnight.`,
        type: 'STREAK_ALERT',
        metadata: { habitId: habit.id },
      });
      if (alert) createdAlerts.push(alert);
    }
  }

  return {
    generatedCount: createdAlerts.length,
    alerts: createdAlerts,
  };
};

/**
 * Background Scheduler: Periodically scan active users and generate contextual alerts (UC-178)
 */
export const initNotificationScheduler = () => {
  const SCHEDULER_INTERVAL_MS = 60 * 60 * 1000; // Run every hour

  const runSchedulerJob = async () => {
    try {
      const users = await prisma.user.findMany({ select: { id: true } });
      for (const u of users) {
        await generateContextualAlerts(u.id);
      }
    } catch (err) {
      console.warn('Background notification scheduler encountered an error:', err);
    }
  };

  setTimeout(runSchedulerJob, 5000);
  setInterval(runSchedulerJob, SCHEDULER_INTERVAL_MS);
};

export default {
  getNotifications,
  getUnreadCount,
  createNotification,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearAllNotifications,
  generateContextualAlerts,
  initNotificationScheduler,
};
