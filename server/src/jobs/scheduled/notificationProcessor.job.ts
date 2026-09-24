import prisma from '../../config/db';
import logger from '../../utils/logger';

/**
 * Scheduled Notification Processor Job
 * Scans for notifications due for delivery and marks them sent.
 */
export async function runNotificationProcessor(): Promise<{ dispatched: number }> {
  const now = new Date();

  // Find unread, scheduled notifications whose time has arrived and haven't been marked sent
  const dueNotifications = await prisma.notification.findMany({
    where: {
      isRead: false,
      scheduledFor: { lte: now },
      sentAt: null,
    },
    take: 100,
  });

  if (dueNotifications.length === 0) {
    return { dispatched: 0 };
  }

  const ids = dueNotifications.map((n) => n.id);

  await prisma.notification.updateMany({
    where: { id: { in: ids } },
    data: { sentAt: now },
  });

  logger.info(`[NotificationProcessor] Dispatched ${dueNotifications.length} scheduled notifications`);
  return { dispatched: dueNotifications.length };
}

export default runNotificationProcessor;
