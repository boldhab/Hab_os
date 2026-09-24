import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';

export interface ResourceInput {
  title: string;
  type?: string;
  url?: string;
  notes?: string;
}

export interface CreateTechLearningDTO {
  name: string;
  status?: string;
  priority?: string;
  progressPercentage?: number;
  resources?: ResourceInput[];
}

export interface UpdateTechLearningDTO {
  name?: string;
  status?: string;
  priority?: string;
  progressPercentage?: number;
  resources?: ResourceInput[];
}

/**
 * UC-65 to UC-69: Tech Learning Roadmap
 */
export const createTechLearning = async (userId: string, data: CreateTechLearningDTO) => {
  const learning = await prisma.techLearning.create({
    data: {
      name: data.name,
      status: data.status || 'NOT_STARTED',
      priority: data.priority || 'MEDIUM',
      progressPercentage: data.progressPercentage || 0.0,
      resources: data.resources ? (data.resources as unknown as Prisma.InputJsonValue) : Prisma.JsonNull,
      userId,
    },
  });

  return learning;
};

export const getTechLearnings = async (userId: string, status?: string, priority?: string, page?: number, limit?: number) => {
  const where = {
    userId,
    ...(status ? { status } : {}),
    ...(priority ? { priority } : {}),
  };

  const total = await prisma.techLearning.count({ where });

  let skip: number | undefined;
  let take: number | undefined;
  if (page && limit && limit > 0) {
    skip = (page - 1) * limit;
    take = limit;
  }

  const learnings = await prisma.techLearning.findMany({
    where,
    skip,
    take,
    orderBy: [{ progressPercentage: 'desc' }, { name: 'asc' }],
  });

  return {
    data: learnings,
    meta: {
      total,
      page: page || 1,
      limit: limit || total,
      totalPages: limit && limit > 0 ? Math.ceil(total / limit) : 1,
    },
  };
};

export const getTechLearningById = async (userId: string, id: string) => {
  const learning = await prisma.techLearning.findFirst({
    where: { id, userId },
  });

  if (!learning) {
    throw new ApiError(404, 'Technology learning entry not found');
  }

  return learning;
};

export const updateTechLearning = async (
  userId: string,
  id: string,
  data: UpdateTechLearningDTO
) => {
  const existing = await prisma.techLearning.findFirst({
    where: { id, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Technology learning entry not found');
  }

  const updated = await prisma.techLearning.update({
    where: { id },
    data: {
      name: data.name,
      status: data.status,
      priority: data.priority,
      progressPercentage: data.progressPercentage,
      resources: data.resources !== undefined ? (data.resources as unknown as Prisma.InputJsonValue) : undefined,
    },
  });

  return updated;
};

export const deleteTechLearning = async (userId: string, id: string) => {
  const existing = await prisma.techLearning.findFirst({
    where: { id, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Technology learning entry not found');
  }

  await prisma.techLearning.delete({ where: { id } });
  return { message: 'Technology learning entry deleted successfully' };
};

export const getTechSummary = async (userId: string) => {
  const all = await prisma.techLearning.findMany({ where: { userId } });
  const total = all.length;
  const completed = all.filter((t) => t.status === 'COMPLETED').length;
  const learning = all.filter((t) => t.status === 'LEARNING' || t.status === 'PRACTICING').length;
  const notStarted = all.filter((t) => t.status === 'NOT_STARTED').length;
  const avgProgress = total > 0 ? Number((all.reduce((s, t) => s + t.progressPercentage, 0) / total).toFixed(1)) : 0;

  return {
    total,
    completed,
    learning,
    notStarted,
    avgProgress,
  };
};

export default {
  createTechLearning,
  getTechLearnings,
  getTechLearningById,
  updateTechLearning,
  deleteTechLearning,
  getTechSummary,
};
