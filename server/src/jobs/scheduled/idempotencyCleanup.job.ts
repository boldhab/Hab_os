import prisma from '../../config/db';
import logger from '../../utils/logger';

/**
 * Cleanup Expired Idempotency Keys Job
 * Periodically removes expired keys from idempotency_keys table
 * to prevent database bloat over time.
 */
export async function runIdempotencyCleanup(): Promise<{ deletedCount: number }> {
  try {
    if (!prisma?.idempotencyKey?.deleteMany) {
      return { deletedCount: 0 };
    }

    const result = await prisma.idempotencyKey.deleteMany({
      where: {
        expiresAt: {
          lt: new Date(),
        },
      },
    });

    if (result.count > 0) {
      logger.info(`[IdempotencyCleanup] Cleaned up ${result.count} expired idempotency keys`);
    }

    return { deletedCount: result.count };
  } catch (error) {
    logger.error('[IdempotencyCleanup] Failed to clean up expired idempotency keys', error);
    return { deletedCount: 0 };
  }
}

export default runIdempotencyCleanup;
