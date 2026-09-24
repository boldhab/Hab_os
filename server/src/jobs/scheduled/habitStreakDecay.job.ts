import prisma from '../../config/db';
import logger from '../../utils/logger';

/**
 * Habit Streak Decay Job
 * Automatically decays or resets current streaks for habits that were missed yesterday.
 * Runs periodically to ensure streaks accurately reflect daily consistency.
 */
export async function runHabitStreakDecay(): Promise<{ evaluated: number; reset: number }> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  // Fetch all active daily habits with their current streak > 0
  const activeHabits = await prisma.habit.findMany({
    where: {
      isActive: true,
      frequency: 'DAILY',
      currentStreak: { gt: 0 },
    },
    include: {
      logs: {
        where: {
          isCompleted: true,
          date: { gte: yesterday },
        },
      },
    },
  });

  let resetCount = 0;

  for (const habit of activeHabits) {
    // If there is NO completed log for yesterday or today, the streak is broken
    const hasLogYesterdayOrToday = habit.logs.length > 0;

    if (!hasLogYesterdayOrToday) {
      await prisma.habit.update({
        where: { id: habit.id },
        data: { currentStreak: 0 },
      });
      resetCount++;
      logger.info(`[HabitStreakDecay] Reset streak for habit "${habit.name}" (User: ${habit.userId})`);
    }
  }

  logger.info(`[HabitStreakDecay] Completed: evaluated ${activeHabits.length} habits, reset ${resetCount} broken streaks`);
  return { evaluated: activeHabits.length, reset: resetCount };
}

export default runHabitStreakDecay;
