import prisma from '../../config/db';
import logger from '../../utils/logger';

/**
 * Daily Life Score Snapshot Job
 * Computes a standardized daily productivity snapshot for active users
 * and stores it into the life_score_logs table.
 */
export async function runDailyLifeScoreSnapshot(): Promise<{ snapshotsCreated: number }> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  // Find users who don't already have a LifeScore log for today
  const users = await prisma.user.findMany({
    select: { id: true },
    take: 50,
  });

  let createdCount = 0;

  for (const user of users) {
    const existingLog = await prisma.lifeScoreLog.findFirst({
      where: {
        userId: user.id,
        date: { gte: today, lt: tomorrow },
      },
    });

    if (existingLog) {
      continue;
    }

    // Aggregate today's performance metrics
    const [completedTasks, focusSessions, completedHabits] = await Promise.all([
      prisma.task.count({
        where: {
          userId: user.id,
          isCompleted: true,
          completedAt: { gte: today, lt: tomorrow },
        },
      }),
      prisma.focusSession.findMany({
        where: {
          userId: user.id,
          startTime: { gte: today, lt: tomorrow },
        },
      }),
      prisma.habitLog.count({
        where: {
          habit: { userId: user.id },
          isCompleted: true,
          date: { gte: today, lt: tomorrow },
        },
      }),
    ]);

    const totalFocusMinutes = focusSessions.reduce((acc, s) => acc + (s.durationMinutes || 0), 0);

    const taskScore = Math.min(100, 50 + completedTasks * 10);
    const codingScore = Math.min(100, Math.round((totalFocusMinutes / 120) * 100));
    const studyScore = 80;

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const [recentWorkoutsCount, recentPRsCount, userPrefs] = await Promise.all([
      prisma.workout.count({
        where: { userId: user.id, date: { gte: sevenDaysAgo } },
      }),
      prisma.personalRecord.count({
        where: { userId: user.id, achievedDate: { gte: sevenDaysAgo } },
      }),
      prisma.userPreference.findUnique({ where: { userId: user.id } }),
    ]);

    const weeklyGymTarget = userPrefs?.weeklyGymTarget || 4;
    const attendanceRatio = Math.min(1.0, recentWorkoutsCount / weeklyGymTarget);
    const prBonus = recentPRsCount > 0 ? 15 : 0;
    const gymScore = Math.min(100, Math.round(attendanceRatio * 85 + prBonus));
    const habitScore = Math.min(100, 50 + completedHabits * 15);

    const overallScore = Math.round(
      taskScore * 0.2 +
      codingScore * 0.2 +
      studyScore * 0.2 +
      gymScore * 0.2 +
      habitScore * 0.2
    );

    await prisma.lifeScoreLog.create({
      data: {
        userId: user.id,
        date: new Date(),
        overallScore,
        taskScore,
        codingScore,
        studyScore,
        gymScore,
        habitScore,
      },
    });

    createdCount++;
  }

  logger.info(`[DailyLifeScoreSnapshot] Created ${createdCount} daily life score snapshots`);
  return { snapshotsCreated: createdCount };
}

export default runDailyLifeScoreSnapshot;
