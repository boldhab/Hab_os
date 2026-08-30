import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';

export interface CreateGoalDTO {
  title: string;
  description?: string | null;
  category?: string;
  priority?: string;
  targetDate?: Date | string | null;
  progress?: number;
  milestones?: { title: string; targetDate?: Date | string | null; isCompleted?: boolean }[];
}

export interface UpdateGoalDTO {
  title?: string;
  description?: string | null;
  category?: string;
  priority?: string;
  status?: string;
  targetDate?: Date | string | null;
  progress?: number;
}

export interface CreateMilestoneDTO {
  title: string;
  description?: string | null;
  targetDate?: Date | string | null;
  isCompleted?: boolean;
}

export interface UpdateMilestoneDTO {
  title?: string;
  description?: string | null;
  targetDate?: Date | string | null;
  status?: string;
  isCompleted?: boolean;
}

/**
 * Auto-recalculate goal progress from completed milestones + completed linked tasks (UC-117)
 */
export const recalculateGoalProgress = async (goalId: string) => {
  const [totalMilestones, completedMilestones, totalTasks, completedTasks] = await Promise.all([
    prisma.milestone.count({ where: { goalId } }),
    prisma.milestone.count({ where: { goalId, isCompleted: true } }),
    prisma.task.count({ where: { goalId } }),
    prisma.task.count({ where: { goalId, isCompleted: true } }),
  ]);

  const totalItems = totalMilestones + totalTasks;
  if (totalItems === 0) return 0;

  const completedItems = completedMilestones + completedTasks;
  const progress = Number(((completedItems / totalItems) * 100).toFixed(1));
  const status = progress >= 100 ? 'COMPLETED' : progress > 0 ? 'IN_PROGRESS' : 'NOT_STARTED';

  await prisma.goal.update({
    where: { id: goalId },
    data: { progress, status },
  });

  return progress;
};

// ==========================================
// 1. GOALS (UC-112 to UC-114, UC-119, UC-120)
// ==========================================

export const createGoal = async (userId: string, data: CreateGoalDTO) => {
  const goal = await prisma.goal.create({
    data: {
      title: data.title,
      description: data.description,
      category: data.category || 'PERSONAL',
      priority: data.priority || 'MEDIUM',
      targetDate: data.targetDate ? new Date(data.targetDate) : null,
      progress: data.progress || 0.0,
      userId,
      milestones: data.milestones && data.milestones.length > 0 ? {
        create: data.milestones.map((m) => ({
          title: m.title,
          targetDate: m.targetDate ? new Date(m.targetDate) : null,
          isCompleted: m.isCompleted || false,
          status: m.isCompleted ? 'COMPLETED' : 'NOT_STARTED',
        })),
      } : undefined,
    },
    include: {
      milestones: { orderBy: { targetDate: 'asc' } },
    },
  });

  if (data.milestones && data.milestones.length > 0) {
    await recalculateGoalProgress(goal.id);
  }

  invalidateDashboardCache(userId);

  return goal;
};

export const getGoals = async (userId: string, category?: string, page?: number, limit?: number) => {
  const where = {
    userId,
    ...(category ? { category } : {}),
  };

  const total = await prisma.goal.count({ where });

  let skip: number | undefined;
  let take: number | undefined;
  if (page && limit && limit > 0) {
    skip = (page - 1) * limit;
    take = limit;
  }

  const goals = await prisma.goal.findMany({
    where,
    skip,
    take,
    orderBy: [{ progress: 'asc' }, { targetDate: 'asc' }],
    include: {
      milestones: { orderBy: { targetDate: 'asc' } },
      _count: { select: { tasks: true, milestones: true } },
    },
  });

  return {
    data: goals,
    meta: {
      total,
      page: page || 1,
      limit: limit || total,
      totalPages: limit && limit > 0 ? Math.ceil(total / limit) : 1,
    },
  };
};

export const getGoalById = async (userId: string, goalId: string) => {
  const goal = await prisma.goal.findFirst({
    where: { id: goalId, userId },
    include: {
      milestones: { orderBy: { targetDate: 'asc' } },
      tasks: {
        orderBy: [{ isCompleted: 'asc' }, { dueDate: 'asc' }],
        select: {
          id: true,
          title: true,
          priority: true,
          status: true,
          isCompleted: true,
          dueDate: true,
        },
      },
    },
  });

  if (!goal) {
    throw new ApiError(404, 'Goal not found');
  }

  return goal;
};

export const updateGoal = async (userId: string, goalId: string, data: UpdateGoalDTO) => {
  const existingGoal = await prisma.goal.findFirst({
    where: { id: goalId, userId },
  });

  if (!existingGoal) {
    throw new ApiError(404, 'Goal not found');
  }

  const updatedGoal = await prisma.goal.update({
    where: { id: goalId },
    data: {
      ...data,
      targetDate: data.targetDate ? new Date(data.targetDate) : undefined,
    },
    include: {
      milestones: { orderBy: { targetDate: 'asc' } },
    },
  });

  invalidateDashboardCache(userId);

  return updatedGoal;
};

export const deleteGoal = async (userId: string, goalId: string) => {
  const existingGoal = await prisma.goal.findFirst({
    where: { id: goalId, userId },
  });

  if (!existingGoal) {
    throw new ApiError(404, 'Goal not found');
  }

  await prisma.goal.delete({ where: { id: goalId } });

  invalidateDashboardCache(userId);

  return { message: 'Goal deleted successfully' };
};

// ==========================================
// 2. MILESTONES (UC-115, UC-116)
// ==========================================

export const createMilestone = async (userId: string, goalId: string, data: CreateMilestoneDTO) => {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new ApiError(404, 'Goal not found');

  const milestone = await prisma.milestone.create({
    data: {
      title: data.title,
      description: data.description,
      targetDate: data.targetDate ? new Date(data.targetDate) : null,
      isCompleted: data.isCompleted || false,
      status: data.isCompleted ? 'COMPLETED' : 'NOT_STARTED',
      goalId,
    },
  });

  await recalculateGoalProgress(goalId);
  return milestone;
};

export const updateMilestone = async (
  userId: string,
  goalId: string,
  milestoneId: string,
  data: UpdateMilestoneDTO
) => {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new ApiError(404, 'Goal not found');

  const milestone = await prisma.milestone.findFirst({
    where: { id: milestoneId, goalId },
  });
  if (!milestone) throw new ApiError(404, 'Milestone not found');

  const isCompleted = data.isCompleted !== undefined ? data.isCompleted : milestone.isCompleted;
  const status = isCompleted ? 'COMPLETED' : (data.status || 'IN_PROGRESS');

  const updatedMilestone = await prisma.milestone.update({
    where: { id: milestoneId },
    data: {
      title: data.title !== undefined ? data.title : milestone.title,
      description: data.description !== undefined ? data.description : milestone.description,
      targetDate: data.targetDate !== undefined ? (data.targetDate ? new Date(data.targetDate) : null) : milestone.targetDate,
      isCompleted,
      status,
    },
  });

  await recalculateGoalProgress(goalId);
  return updatedMilestone;
};

export const deleteMilestone = async (userId: string, goalId: string, milestoneId: string) => {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new ApiError(404, 'Goal not found');

  const milestone = await prisma.milestone.findFirst({
    where: { id: milestoneId, goalId },
  });
  if (!milestone) throw new ApiError(404, 'Milestone not found');

  await prisma.milestone.delete({ where: { id: milestoneId } });
  await recalculateGoalProgress(goalId);

  return { message: 'Milestone deleted successfully' };
};

// ==========================================
// 3. ROADMAP VIEW (UC-119, UC-120)
// ==========================================

export const getRoadmap = async (userId: string) => {
  const goals = await prisma.goal.findMany({
    where: { userId },
    orderBy: { targetDate: 'asc' },
    include: {
      milestones: { orderBy: { targetDate: 'asc' } },
    },
  });

  const totalGoals = goals.length;
  const completedGoals = goals.filter((g) => g.progress >= 100).length;
  const inProgressGoals = goals.filter((g) => g.progress > 0 && g.progress < 100).length;
  const notStartedGoals = goals.filter((g) => g.progress === 0).length;

  return {
    summary: {
      totalGoals,
      completedGoals,
      inProgressGoals,
      notStartedGoals,
    },
    timeline: goals,
  };
};

export default {
  createGoal,
  getGoals,
  getGoalById,
  updateGoal,
  deleteGoal,
  createMilestone,
  updateMilestone,
  deleteMilestone,
  getRoadmap,
  recalculateGoalProgress,
};
