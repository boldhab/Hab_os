import prisma from '../../config/db';
import logger from '../../utils/logger';
import { evaluateHabitStreak } from '../../modules/habits/habits.service';

/**
 * Habit Streak Decay Job
 * Evaluates active habit streaks, safely consuming streak freezes when days are missed
 * or decaying broken streaks.
 * Runs periodically to ensure streaks accurately reflect daily consistency.
 */
export async function runHabitStreakDecay(): Promise<{ evaluated: number; reset: number }> {
  // Fetch all active habits with positive streaks
  const activeHabits = await prisma.habit.findMany({
    where: {
      isActive: true,
      currentStreak: { gt: 0 },
    },
  });

  let resetCount = 0;

  for (const habit of activeHabits) {
    const prevStreak = habit.currentStreak;
    try {
      const result = await evaluateHabitStreak(habit.id, habit, true);
      if (prevStreak > 0 && result.currentStreak === 0) {
        resetCount++;
        logger.info(`[HabitStreakDecay] Reset broken streak for habit "${habit.name}" (User: ${habit.userId})`);
      }
    } catch (err) {
      logger.error(`[HabitStreakDecay] Error evaluating streak for habit "${habit.id}":`, err);
    }
  }

  logger.info(`[HabitStreakDecay] Completed: evaluated ${activeHabits.length} habits, reset ${resetCount} broken streaks`);
  return { evaluated: activeHabits.length, reset: resetCount };
}

export default runHabitStreakDecay;

