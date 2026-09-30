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
  targetAmount?: number | null;
  currentAmount?: number | null;
  milestones?: {
    title: string;
    description?: string | null;
    targetDate?: Date | string | null;
    isCompleted?: boolean;
    weight?: number;
    order?: number;
  }[];
}

export interface UpdateGoalDTO {
  title?: string;
  description?: string | null;
  category?: string;
  priority?: string;
  status?: string;
  targetDate?: Date | string | null;
  progress?: number;
  targetAmount?: number | null;
  currentAmount?: number | null;
}

export interface CreateMilestoneDTO {
  title: string;
  description?: string | null;
  targetDate?: Date | string | null;
  isCompleted?: boolean;
  weight?: number;
  order?: number;
}

export interface UpdateMilestoneDTO {
  title?: string;
  description?: string | null;
  targetDate?: Date | string | null;
  status?: string;
  isCompleted?: boolean;
  weight?: number;
  order?: number;
}

export interface CreateCheckInDTO {
  confidence: 'ON_TRACK' | 'BEHIND' | 'AT_RISK';
  note?: string | null;
}

/**
 * Auto-recalculate goal progress from weighted milestones + tasks, or financial target (UC-117)
 */
export const recalculateGoalProgress = async (goalId: string): Promise<number> => {
  const goal = await prisma.goal.findUnique({
    where: { id: goalId },
    include: {
      milestones: {
        include: {
          tasks: { select: { id: true, isCompleted: true } },
        },
      },
      tasks: { select: { id: true, isCompleted: true, milestoneId: true } },
    },
  });

  if (!goal) return 0;

  let progress = 0;

  // 1. FINANCIAL goals: prioritize targetAmount if present
  if (goal.category === 'FINANCIAL' && goal.targetAmount && goal.targetAmount > 0) {
    const current = goal.currentAmount ?? 0;
    progress = Number(Math.min(100, Math.max(0, (current / goal.targetAmount) * 100)).toFixed(1));
  }
  // 2. Goals with Milestones: weighted average of milestone progress
  else if (goal.milestones.length > 0) {
    let totalWeight = 0;
    let weightedProgressSum = 0;

    for (const m of goal.milestones) {
      const weight = m.weight && m.weight > 0 ? m.weight : 1.0;
      totalWeight += weight;

      let milestoneProgressRatio = 0;

      if (m.tasks.length > 0) {
        // Task-derived milestone progress
        const doneTasks = m.tasks.filter((t) => t.isCompleted).length;
        milestoneProgressRatio = doneTasks / m.tasks.length;
        const allDone = doneTasks === m.tasks.length;

        // Auto-synchronize milestone status if changed
        if (m.isCompleted !== allDone) {
          await prisma.milestone.update({
            where: { id: m.id },
            data: {
              isCompleted: allDone,
              status: allDone ? 'COMPLETED' : doneTasks > 0 ? 'IN_PROGRESS' : 'NOT_STARTED',
            },
          });
        }
      } else {
        // Binary/subjective manual toggle
        milestoneProgressRatio = m.isCompleted ? 1.0 : 0.0;
      }

      weightedProgressSum += milestoneProgressRatio * weight;
    }

    progress = totalWeight > 0 ? Number(((weightedProgressSum / totalWeight) * 100).toFixed(1)) : 0;
  }
  // 3. Goals without milestones but with direct tasks
  else if (goal.tasks.length > 0) {
    const completedTasks = goal.tasks.filter((t) => t.isCompleted).length;
    progress = Number(((completedTasks / goal.tasks.length) * 100).toFixed(1));
  } else {
    // Preserve manual progress if no milestones or tasks exist
    progress = goal.progress;
  }

  const status = progress >= 100 ? 'COMPLETED' : progress > 0 ? 'IN_PROGRESS' : 'NOT_STARTED';

  await prisma.goal.update({
    where: { id: goalId },
    data: { progress, status },
  });

  return progress;
};

// ==========================================
// 1. GOALS
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
      targetAmount: data.targetAmount,
      currentAmount: data.currentAmount || 0.0,
      userId,
      milestones:
        data.milestones && data.milestones.length > 0
          ? {
              create: data.milestones.map((m, idx) => ({
                title: m.title,
                description: m.description,
                targetDate: m.targetDate ? new Date(m.targetDate) : null,
                isCompleted: m.isCompleted || false,
                status: m.isCompleted ? 'COMPLETED' : 'NOT_STARTED',
                weight: m.weight || 1.0,
                order: m.order ?? idx,
              })),
            }
          : undefined,
    },
    include: {
      milestones: { orderBy: [{ order: 'asc' }, { targetDate: 'asc' }] },
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
      milestones: {
        orderBy: [{ order: 'asc' }, { targetDate: 'asc' }],
        include: { _count: { select: { tasks: true } } },
      },
      checkIns: {
        orderBy: { date: 'desc' },
        take: 1,
      },
      _count: { select: { tasks: true, milestones: true, checkIns: true } },
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
      milestones: {
        orderBy: [{ order: 'asc' }, { targetDate: 'asc' }],
        include: {
          tasks: {
            orderBy: [{ isCompleted: 'asc' }, { dueDate: 'asc' }],
            select: {
              id: true,
              title: true,
              priority: true,
              status: true,
              isCompleted: true,
              dueDate: true,
              estimatedMinutes: true,
            },
          },
        },
      },
      tasks: {
        where: { milestoneId: null }, // Direct tasks without milestone
        orderBy: [{ isCompleted: 'asc' }, { dueDate: 'asc' }],
        select: {
          id: true,
          title: true,
          priority: true,
          status: true,
          isCompleted: true,
          dueDate: true,
          estimatedMinutes: true,
        },
      },
      checkIns: {
        orderBy: { date: 'desc' },
        take: 10,
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
      milestones: { orderBy: [{ order: 'asc' }, { targetDate: 'asc' }] },
    },
  });

  if (data.targetAmount !== undefined || data.currentAmount !== undefined) {
    await recalculateGoalProgress(goalId);
  }

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
// 2. MILESTONES
// ==========================================

export const getMilestones = async (userId: string, goalId: string) => {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new ApiError(404, 'Goal not found');

  return prisma.milestone.findMany({
    where: { goalId },
    orderBy: [{ order: 'asc' }, { targetDate: 'asc' }],
    include: {
      tasks: {
        select: { id: true, title: true, isCompleted: true, priority: true, dueDate: true },
      },
    },
  });
};

export const createMilestone = async (userId: string, goalId: string, data: CreateMilestoneDTO) => {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new ApiError(404, 'Goal not found');

  const count = await prisma.milestone.count({ where: { goalId } });

  const milestone = await prisma.milestone.create({
    data: {
      title: data.title,
      description: data.description,
      targetDate: data.targetDate ? new Date(data.targetDate) : null,
      isCompleted: data.isCompleted || false,
      status: data.isCompleted ? 'COMPLETED' : 'NOT_STARTED',
      weight: data.weight || 1.0,
      order: data.order ?? count,
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
  const status = isCompleted ? 'COMPLETED' : data.status || 'IN_PROGRESS';

  const updatedMilestone = await prisma.milestone.update({
    where: { id: milestoneId },
    data: {
      title: data.title !== undefined ? data.title : milestone.title,
      description: data.description !== undefined ? data.description : milestone.description,
      targetDate:
        data.targetDate !== undefined
          ? data.targetDate
            ? new Date(data.targetDate)
            : null
          : milestone.targetDate,
      weight: data.weight !== undefined ? data.weight : milestone.weight,
      order: data.order !== undefined ? data.order : milestone.order,
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
// 3. TREE / ROADMAP VISUALIZATION
// ==========================================

export const getGoalTree = async (userId: string, goalId: string) => {
  const goal = await prisma.goal.findFirst({
    where: { id: goalId, userId },
    include: {
      milestones: {
        orderBy: [{ order: 'asc' }, { targetDate: 'asc' }],
        include: {
          tasks: {
            orderBy: [{ isCompleted: 'asc' }, { dueDate: 'asc' }],
            select: {
              id: true,
              title: true,
              priority: true,
              status: true,
              isCompleted: true,
              dueDate: true,
              estimatedMinutes: true,
            },
          },
        },
      },
      tasks: {
        where: { milestoneId: null },
        orderBy: [{ isCompleted: 'asc' }, { dueDate: 'asc' }],
        select: {
          id: true,
          title: true,
          priority: true,
          status: true,
          isCompleted: true,
          dueDate: true,
          estimatedMinutes: true,
        },
      },
    },
  });

  if (!goal) throw new ApiError(404, 'Goal not found');

  // Compute branch breakdown
  const branches = goal.milestones.map((m) => {
    const totalTasks = m.tasks.length;
    const completedTasks = m.tasks.filter((t) => t.isCompleted).length;
    const branchProgress =
      totalTasks > 0
        ? Math.round((completedTasks / totalTasks) * 100)
        : m.isCompleted
        ? 100
        : 0;

    return {
      id: m.id,
      title: m.title,
      description: m.description,
      order: m.order,
      weight: m.weight,
      targetDate: m.targetDate,
      isCompleted: m.isCompleted,
      status: m.status,
      progress: branchProgress,
      totalTasks,
      completedTasks,
      tasks: m.tasks,
    };
  });

  return {
    id: goal.id,
    title: goal.title,
    category: goal.category,
    priority: goal.priority,
    targetDate: goal.targetDate,
    overallProgress: goal.progress,
    status: goal.status,
    targetAmount: goal.targetAmount,
    currentAmount: goal.currentAmount,
    milestoneCount: goal.milestones.length,
    directTasksCount: goal.tasks.length,
    branches,
    unassignedTasks: goal.tasks,
  };
};

export const getRoadmap = async (userId: string) => {
  const goals = await prisma.goal.findMany({
    where: { userId },
    orderBy: { targetDate: 'asc' },
    include: {
      milestones: { orderBy: [{ order: 'asc' }, { targetDate: 'asc' }] },
      checkIns: { orderBy: { date: 'desc' }, take: 1 },
      _count: { select: { tasks: true, milestones: true } },
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

// ==========================================
// 4. CHECK-INS & HEALTH ENGINE
// ==========================================

export const recordCheckIn = async (userId: string, goalId: string, data: CreateCheckInDTO) => {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new ApiError(404, 'Goal not found');

  return prisma.goalCheckIn.create({
    data: {
      goalId,
      userId,
      confidence: data.confidence,
      note: data.note,
    },
  });
};

export const getGoalCheckIns = async (userId: string, goalId: string) => {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new ApiError(404, 'Goal not found');

  return prisma.goalCheckIn.findMany({
    where: { goalId },
    orderBy: { date: 'desc' },
  });
};

export const getGoalsHealth = async (userId: string) => {
  const goals = await prisma.goal.findMany({
    where: {
      userId,
      status: { notIn: ['COMPLETED', 'ARCHIVED'] },
    },
    include: {
      milestones: { select: { id: true, isCompleted: true, updatedAt: true } },
      tasks: { select: { id: true, isCompleted: true, updatedAt: true } },
      checkIns: { orderBy: { date: 'desc' }, take: 1 },
    },
  });

  const now = new Date();
  const atRiskGoals: any[] = [];
  const behindGoals: any[] = [];
  const onTrackGoals: any[] = [];

  for (const g of goals) {
    let daysUntilTarget: number | null = null;
    if (g.targetDate) {
      const diffMs = new Date(g.targetDate).getTime() - now.getTime();
      daysUntilTarget = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
    }

    // Determine latest activity date
    const timestamps = [
      g.updatedAt.getTime(),
      ...g.milestones.map((m) => m.updatedAt.getTime()),
      ...g.tasks.map((t) => t.updatedAt.getTime()),
      ...(g.checkIns.length > 0 ? [new Date(g.checkIns[0].date).getTime()] : []),
    ];
    const latestActivityMs = Math.max(...timestamps);
    const daysSinceActivity = Math.floor((now.getTime() - latestActivityMs) / (1000 * 60 * 60 * 24));

    const latestConfidence = g.checkIns.length > 0 ? g.checkIns[0].confidence : null;

    let healthStatus: 'ON_TRACK' | 'BEHIND' | 'AT_RISK' = 'ON_TRACK';
    let riskReason: string | null = null;

    if (latestConfidence === 'AT_RISK') {
      healthStatus = 'AT_RISK';
      riskReason = 'User flagged check-in as at risk';
    } else if (daysUntilTarget !== null && daysUntilTarget <= 30 && g.progress < 30) {
      healthStatus = 'AT_RISK';
      riskReason = `Target date is in ${daysUntilTarget} days but progress is only ${g.progress}%`;
    } else if (daysSinceActivity >= 14 && daysUntilTarget !== null && daysUntilTarget <= 60) {
      healthStatus = 'AT_RISK';
      riskReason = `No activity recorded in ${daysSinceActivity} days`;
    } else if (latestConfidence === 'BEHIND') {
      healthStatus = 'BEHIND';
      riskReason = 'User flagged check-in as behind schedule';
    } else if (daysUntilTarget !== null && daysUntilTarget <= 14 && g.progress < 70) {
      healthStatus = 'BEHIND';
      riskReason = `Target date is in ${daysUntilTarget} days but progress is only ${g.progress}%`;
    }

    const payload = {
      id: g.id,
      title: g.title,
      category: g.category,
      priority: g.priority,
      targetDate: g.targetDate,
      progress: g.progress,
      daysUntilTarget,
      daysSinceActivity,
      latestConfidence,
      healthStatus,
      riskReason,
    };

    if (healthStatus === 'AT_RISK') {
      atRiskGoals.push(payload);
    } else if (healthStatus === 'BEHIND') {
      behindGoals.push(payload);
    } else {
      onTrackGoals.push(payload);
    }
  }

  return {
    summary: {
      totalActive: goals.length,
      atRiskCount: atRiskGoals.length,
      behindCount: behindGoals.length,
      onTrackCount: onTrackGoals.length,
    },
    atRisk: atRiskGoals,
    behind: behindGoals,
    onTrack: onTrackGoals,
  };
};

export const contributeFinancialGoal = async (userId: string, goalId: string, amount: number) => {
  const goal = await prisma.goal.findFirst({ where: { id: goalId, userId } });
  if (!goal) throw new ApiError(404, 'Goal not found');
  if (goal.category !== 'FINANCIAL') throw new ApiError(400, 'Goal is not categorized as FINANCIAL');

  const newCurrent = (goal.currentAmount || 0) + amount;
  const updated = await prisma.goal.update({
    where: { id: goalId },
    data: { currentAmount: newCurrent },
  });

  await recalculateGoalProgress(goalId);
  return updated;
};

export default {
  createGoal,
  getGoals,
  getGoalById,
  updateGoal,
  deleteGoal,
  getMilestones,
  createMilestone,
  updateMilestone,
  deleteMilestone,
  getGoalTree,
  getRoadmap,
  recordCheckIn,
  getGoalCheckIns,
  getGoalsHealth,
  contributeFinancialGoal,
  recalculateGoalProgress,
};
