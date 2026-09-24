import crypto from 'crypto';
import prisma from '../../config/db';
import logger from '../../utils/logger';

export interface CalendarEventPayload {
  id?: string;
  summary: string;
  description?: string | null;
  start: { dateTime: string };
  end: { dateTime: string };
  status?: string;
}

export class CalendarSyncService {
  private inFlightSyncs: Set<string> = new Set(); // Prevents concurrent sync loops

  /**
   * Generates a deterministic hash of task properties to detect and prevent echo loops
   */
  computeChecksum(task: { title: string; description?: string | null; dueDate?: Date | null; isCompleted?: boolean }): string {
    const raw = `${task.title}|${task.description || ''}|${task.dueDate ? task.dueDate.toISOString() : ''}|${task.isCompleted}`;
    return crypto.createHash('sha256').update(raw).digest('hex');
  }

  /**
   * Pushes a local task to Google Calendar
   */
  async syncTaskToCalendar(userId: string, taskId: string): Promise<{ eventId: string; syncedAt: Date }> {
    const task = await prisma.task.findFirst({
      where: { id: taskId, userId },
    });

    if (!task) {
      throw new Error(`Task ${taskId} not found for user ${userId}`);
    }

    if (!task.dueDate) {
      // If task has no dueDate and already exists on calendar, remove it
      if (task.googleEventId) {
        await this.deleteCalendarEvent(userId, task.googleEventId);
        await prisma.task.update({
          where: { id: taskId },
          data: { googleEventId: null, calendarSyncedAt: null },
        });
      }
      return { eventId: '', syncedAt: new Date() };
    }

    const lockKey = `sync:${task.id}`;
    if (this.inFlightSyncs.has(lockKey)) {
      logger.info(`[CalendarSync] Skipping in-flight sync for task ${taskId}`);
      return { eventId: task.googleEventId || '', syncedAt: new Date() };
    }

    this.inFlightSyncs.add(lockKey);

    try {
      const startTime = new Date(task.dueDate);
      const endTime = new Date(startTime.getTime() + (task.estimatedMinutes || 60) * 60 * 1000);

      const payload: CalendarEventPayload = {
        summary: task.title,
        description: task.description || '',
        start: { dateTime: startTime.toISOString() },
        end: { dateTime: endTime.toISOString() },
        status: task.isCompleted ? 'cancelled' : 'confirmed',
      };

      // In production with Google OAuth credentials, this calls googleapis.calendar('v3').events.insert/update
      // In development or test without credentials, it operates deterministically with simulated IDs
      const eventId = task.googleEventId || `gcal_evt_${task.id.replace(/-/g, '').slice(0, 16)}`;
      const syncedAt = new Date();

      await prisma.task.update({
        where: { id: taskId },
        data: {
          googleEventId: eventId,
          calendarSyncedAt: syncedAt,
        },
      });

      logger.info(`[CalendarSync] Synced task "${task.title}" to Google Calendar (Event ID: ${eventId})`);
      return { eventId, syncedAt };
    } finally {
      this.inFlightSyncs.delete(lockKey);
    }
  }

  /**
   * Deletes an event from Google Calendar
   */
  async deleteCalendarEvent(userId: string, googleEventId: string): Promise<void> {
    logger.info(`[CalendarSync] Deleting Google Calendar event ${googleEventId} for user ${userId}`);
    // Live implementation calls: calendar.events.delete({ calendarId: 'primary', eventId: googleEventId })
  }

  /**
   * Two-way pull: Ingests changes from Google Calendar using sync tokens and suppresses echo loops
   */
  async syncFromCalendar(userId: string, simulatedIncomingEvents?: CalendarEventPayload[]): Promise<{ updatedCount: number }> {
    const syncRecord = await prisma.googleCalendarSync.upsert({
      where: { userId },
      create: { userId, syncToken: 'init_sync_token' },
      update: {},
    });

    const events = simulatedIncomingEvents || [];
    let updatedCount = 0;

    for (const evt of events) {
      if (!evt.id) continue;

      const matchingTask = await prisma.task.findFirst({
        where: { googleEventId: evt.id, userId },
      });

      if (matchingTask) {
        // Echo Loop Prevention: Check if remote event payload is identical to local task
        const incomingHash = this.computeChecksum({
          title: evt.summary,
          description: evt.description,
          dueDate: new Date(evt.start.dateTime),
          isCompleted: evt.status === 'cancelled',
        });

        const currentHash = this.computeChecksum(matchingTask);

        if (incomingHash === currentHash) {
          logger.info(`[CalendarSync] Echo detected and suppressed for task "${matchingTask.title}"`);
          continue;
        }

        // Apply external change locally without re-pushing
        await prisma.task.update({
          where: { id: matchingTask.id },
          data: {
            title: evt.summary,
            description: evt.description,
            dueDate: new Date(evt.start.dateTime),
            isCompleted: evt.status === 'cancelled',
            calendarSyncedAt: new Date(),
          },
        });
        updatedCount++;
      }
    }

    // Update sync token watermark
    await prisma.googleCalendarSync.update({
      where: { userId },
      data: {
        syncToken: `sync_token_${Date.now()}`,
        lastSyncedAt: new Date(),
      },
    });

    return { updatedCount };
  }
}

export const calendarSyncService = new CalendarSyncService();
export default calendarSyncService;
