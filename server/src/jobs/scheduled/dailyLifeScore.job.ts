import prisma from '../../config/db';
import logger from '../../utils/logger';
import lifeScoreService from '../../modules/lifescore/lifescore.service';

/**
 * Daily Life Score Snapshot Job
 * Computes a standardized daily productivity snapshot for active users
 * and stores it into the life_score_logs table.
 */
export async function runDailyLifeScoreSnapshot(): Promise<{ snapshotsCreated: number }> {
  const users = await prisma.user.findMany({
    select: { id: true },
    take: 50,
  });

  let createdCount = 0;

  for (const user of users) {
    const result = await lifeScoreService.snapshotDailyLifeScore(user.id);
    if (result.log) createdCount++;
  }

  logger.info(`[DailyLifeScoreSnapshot] Created ${createdCount} daily life score snapshots`);
  return { snapshotsCreated: createdCount };
}

export default runDailyLifeScoreSnapshot;
