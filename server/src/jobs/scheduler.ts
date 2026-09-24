import logger from '../utils/logger';
import { runHabitStreakDecay } from './scheduled/habitStreakDecay.job';
import { runNotificationProcessor } from './scheduled/notificationProcessor.job';
import { runDailyLifeScoreSnapshot } from './scheduled/dailyLifeScore.job';

interface ScheduledTask {
  name: string;
  intervalMs: number;
  handler: () => Promise<any>;
  timer: NodeJS.Timeout | null;
}

class BackgroundScheduler {
  private tasks: Map<string, ScheduledTask> = new Map();
  private isRunning: boolean = false;

  /**
   * Register a recurring job
   */
  register(name: string, intervalMs: number, handler: () => Promise<any>): void {
    this.tasks.set(name, {
      name,
      intervalMs,
      handler,
      timer: null,
    });
  }

  /**
   * Start all registered background jobs
   */
  start(): void {
    if (this.isRunning) return;
    this.isRunning = true;

    logger.info(`⏰ [Scheduler] Starting Background Job Engine (${this.tasks.size} jobs registered)`);

    for (const [name, task] of this.tasks.entries()) {
      task.timer = setInterval(async () => {
        try {
          await task.handler();
        } catch (error) {
          logger.error(`[Scheduler] Error in background job "${name}":`, error);
        }
      }, task.intervalMs);

      // Prevent scheduled jobs from blocking process exit in test/dev
      if (task.timer.unref) {
        task.timer.unref();
      }
    }
  }

  /**
   * Stop all running background jobs
   */
  stop(): void {
    for (const task of this.tasks.values()) {
      if (task.timer) {
        clearInterval(task.timer);
        task.timer = null;
      }
    }
    this.isRunning = false;
    logger.info('🛑 [Scheduler] Stopped Background Job Engine');
  }

  /**
   * Manually trigger a registered job immediately (useful for testing and admin APIs)
   */
  async runJobNow(name: string): Promise<any> {
    const task = this.tasks.get(name);
    if (!task) {
      throw new Error(`Background job "${name}" not found`);
    }
    logger.info(`[Scheduler] Manually executing job "${name}"...`);
    return await task.handler();
  }
}

export const scheduler = new BackgroundScheduler();

// Register Default Scheduled Jobs:
// 1. Notification processor: runs every 60 seconds
scheduler.register('notificationProcessor', 60 * 1000, runNotificationProcessor);

// 2. Habit streak decay: runs every 60 minutes
scheduler.register('habitStreakDecay', 60 * 60 * 1000, runHabitStreakDecay);

// 3. Daily Life Score snapshot: runs every 6 hours
scheduler.register('dailyLifeScore', 6 * 60 * 60 * 1000, runDailyLifeScoreSnapshot);

export const initScheduler = (): void => {
  scheduler.start();
};

export default scheduler;
