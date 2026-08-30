import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';

export interface CreateTaskDTO {
  title: string;
  description?: string | null;
  priority?: string;
  status?: string;
  dueDate?: Date | string | null;
  estimatedMinutes?: number | null;
  projectId?: string | null;
  goalId?: string | null;
  categoryId?: string | null;
}

export interface UpdateTaskDTO {
  title?: string;
  description?: string | null;
  priority?: string;
  status?: string;
  isCompleted?: boolean;
  dueDate?: Date | string | null;
  estimatedMinutes?: number | null;
  projectId?: string | null;
  goalId?: string | null;
  categoryId?: string | null;
}

export interface GetTasksQuery {
  view?: 'today' | 'upcoming' | 'overdue' | 'completed' | 'all';
  status?: string;
  priority?: string;
  projectId?: string;
  goalId?: string;
  categoryId?: string;
  search?: string;
  page?: number;
  limit?: number;
}

/**
 * Helper: Downstream recalculation of project progress (UC-42)
 */
const recalculateProjectProgress = async (projectId: string) => {
  const totalTasks = await prisma.task.count({ where: { projectId } });
  if (totalTasks === 0) return;

  const completedTasks = await prisma.task.count({
    where: { projectId, isCompleted: true },
  });

  const progress = Number(((completedTasks / totalTasks) * 100).toFixed(1));
  await prisma.project.update({
    where: { id: projectId },
    data: { progress },
  });
};

/**
 * Helper: Downstream recalculation of goal progress (UC-117)
 */
const recalculateGoalProgress = async (goalId: string) => {
  const totalMilestones = await prisma.milestone.count({ where: { goalId } });
  const totalTasks = await prisma.task.count({ where: { goalId } });

  const totalItems = totalMilestones + totalTasks;
  if (totalItems === 0) return;

  const completedMilestones = await prisma.milestone.count({
    where: { goalId, isCompleted: true },
  });
  const completedTasks = await prisma.task.count({
    where: { goalId, isCompleted: true },
  });

  const progress = Number((((completedMilestones + completedTasks) / totalItems) * 100).toFixed(1));
  await prisma.goal.update({
    where: { id: goalId },
    data: { progress },
  });
};

/**
 * UC-10: Create a new Task
 */
export const createTask = async (userId: string, data: CreateTaskDTO) => {
  // Validate relations ownership
  if (data.projectId) {
    const project = await prisma.project.findFirst({ where: { id: data.projectId, userId } });
    if (!project) throw new ApiError(404, 'Associated project not found');
  }
  if (data.goalId) {
    const goal = await prisma.goal.findFirst({ where: { id: data.goalId, userId } });
    if (!goal) throw new ApiError(404, 'Associated goal not found');
  }
  if (data.categoryId) {
    const category = await prisma.category.findFirst({ where: { id: data.categoryId, userId } });
    if (!category) throw new ApiError(404, 'Associated category not found');
  }

  const isCompleted = data.status === 'COMPLETED';
  const completedAt = isCompleted ? new Date() : null;

  const task = await prisma.task.create({
    data: {
      title: data.title,
      description: data.description,
      priority: data.priority || 'MEDIUM',
      status: data.status || 'TODO',
      isCompleted,
      completedAt,
      dueDate: data.dueDate ? new Date(data.dueDate) : null,
      estimatedMinutes: data.estimatedMinutes,
      userId,
      projectId: data.projectId || null,
      goalId: data.goalId || null,
      categoryId: data.categoryId || null,
    },
    include: {
      project: { select: { id: true, title: true, color: true } },
      goal: { select: { id: true, title: true } },
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  if (data.projectId) await recalculateProjectProgress(data.projectId);
  if (data.goalId) await recalculateGoalProgress(data.goalId);

  invalidateDashboardCache(userId);

  return task;
};

/**
 * UC-15 & UC-16: Get Tasks with Filtering & Views
 */
export const getTasks = async (userId: string, query: GetTasksQuery) => {
  const { view = 'all', status, priority, projectId, goalId, categoryId, search, page = 1, limit = 20 } = query;
  const skip = (page - 1) * limit;

  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

  const where: Prisma.TaskWhereInput = { userId };

  // Apply Views
  if (view === 'today') {
    where.OR = [
      { dueDate: { gte: startOfToday, lte: endOfToday } },
      { dueDate: { lt: startOfToday }, isCompleted: false }, // Overdue tasks appear in today's view
    ];
  } else if (view === 'upcoming') {
    where.dueDate = { gt: endOfToday };
    where.isCompleted = false;
  } else if (view === 'overdue') {
    where.dueDate = { lt: startOfToday };
    where.isCompleted = false;
  } else if (view === 'completed') {
    where.isCompleted = true;
  }

  // Apply Filters
  if (status) where.status = status;
  if (priority) where.priority = priority;
  if (projectId) where.projectId = projectId;
  if (goalId) where.goalId = goalId;
  if (categoryId) where.categoryId = categoryId;

  // Search keyword (UC-167)
  if (search && search.trim() !== '') {
    where.AND = [
      {
        OR: [
          { title: { contains: search, mode: 'insensitive' } },
          { description: { contains: search, mode: 'insensitive' } },
        ],
      },
    ];
  }

  const [tasks, total] = await Promise.all([
    prisma.task.findMany({
      where,
      skip,
      take: limit,
      orderBy: [
        { isCompleted: 'asc' },
        { priority: 'desc' },
        { dueDate: 'asc' },
        { createdAt: 'desc' },
      ],
      include: {
        project: { select: { id: true, title: true, color: true } },
        goal: { select: { id: true, title: true } },
        category: { select: { id: true, name: true, color: true, icon: true } },
      },
    }),
    prisma.task.count({ where }),
  ]);

  return {
    tasks,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    },
  };
};

/**
 * Get Task Details by ID
 */
export const getTaskById = async (userId: string, taskId: string) => {
  const task = await prisma.task.findFirst({
    where: { id: taskId, userId },
    include: {
      project: true,
      goal: true,
      category: true,
      timeEntries: { orderBy: { startTime: 'desc' } },
      focusSessions: { orderBy: { startTime: 'desc' } },
    },
  });

  if (!task) {
    throw new ApiError(404, 'Task not found');
  }

  return task;
};

/**
 * UC-11: Update Task
 */
export const updateTask = async (userId: string, taskId: string, data: UpdateTaskDTO) => {
  const existingTask = await prisma.task.findFirst({
    where: { id: taskId, userId },
  });

  if (!existingTask) {
    throw new ApiError(404, 'Task not found');
  }

  const updateData: Prisma.TaskUpdateInput = {};

  if (data.title !== undefined) updateData.title = data.title;
  if (data.description !== undefined) updateData.description = data.description;
  if (data.priority !== undefined) updateData.priority = data.priority;
  if (data.estimatedMinutes !== undefined) updateData.estimatedMinutes = data.estimatedMinutes;
  if (data.dueDate !== undefined) updateData.dueDate = data.dueDate ? new Date(data.dueDate) : null;

  // Handle completion status transition
  if (data.isCompleted !== undefined || data.status !== undefined) {
    const isCompleted = data.isCompleted !== undefined ? data.isCompleted : data.status === 'COMPLETED';
    updateData.isCompleted = isCompleted;
    updateData.status = data.status || (isCompleted ? 'COMPLETED' : 'TODO');
    updateData.completedAt = isCompleted ? (existingTask.completedAt || new Date()) : null;
  }

  if (data.projectId !== undefined) {
    updateData.project = data.projectId ? { connect: { id: data.projectId } } : { disconnect: true };
  }
  if (data.goalId !== undefined) {
    updateData.goal = data.goalId ? { connect: { id: data.goalId } } : { disconnect: true };
  }
  if (data.categoryId !== undefined) {
    updateData.category = data.categoryId ? { connect: { id: data.categoryId } } : { disconnect: true };
  }

  const updatedTask = await prisma.task.update({
    where: { id: taskId },
    data: updateData,
    include: {
      project: { select: { id: true, title: true, color: true } },
      goal: { select: { id: true, title: true } },
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  // Downstream Progress Updates
  const affectedProjects = [existingTask.projectId, data.projectId].filter(Boolean) as string[];
  for (const pid of new Set(affectedProjects)) {
    await recalculateProjectProgress(pid);
  }

  const affectedGoals = [existingTask.goalId, data.goalId].filter(Boolean) as string[];
  for (const gid of new Set(affectedGoals)) {
    await recalculateGoalProgress(gid);
  }

  invalidateDashboardCache(userId);

  return updatedTask;
};

/**
 * UC-13: Toggle Task Completion
 */
export const toggleTaskComplete = async (userId: string, taskId: string) => {
  const task = await prisma.task.findFirst({
    where: { id: taskId, userId },
  });

  if (!task) {
    throw new ApiError(404, 'Task not found');
  }

  const isCompleted = !task.isCompleted;
  const status = isCompleted ? 'COMPLETED' : 'TODO';
  const completedAt = isCompleted ? new Date() : null;

  const updatedTask = await prisma.task.update({
    where: { id: taskId },
    data: {
      isCompleted,
      status,
      completedAt,
    },
    include: {
      project: { select: { id: true, title: true, color: true } },
      goal: { select: { id: true, title: true } },
      category: { select: { id: true, name: true, color: true, icon: true } },
    },
  });

  if (task.projectId) await recalculateProjectProgress(task.projectId);
  if (task.goalId) await recalculateGoalProgress(task.goalId);

  invalidateDashboardCache(userId);

  return updatedTask;
};

/**
 * UC-12: Delete Task
 */
export const deleteTask = async (userId: string, taskId: string) => {
  const task = await prisma.task.findFirst({
    where: { id: taskId, userId },
  });

  if (!task) {
    throw new ApiError(404, 'Task not found');
  }

  await prisma.task.delete({ where: { id: taskId } });

  if (task.projectId) await recalculateProjectProgress(task.projectId);
  if (task.goalId) await recalculateGoalProgress(task.goalId);

  invalidateDashboardCache(userId);

  return { message: 'Task deleted successfully' };
};

/**
 * Task Statistics for Dashboard Summary (UC-06, UC-07)
 */
export const getTaskStats = async (userId: string) => {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

  const [total, completedTotal, dueTodayTotal, completedTodayTotal, overdueTotal] = await Promise.all([
    prisma.task.count({ where: { userId } }),
    prisma.task.count({ where: { userId, isCompleted: true } }),
    prisma.task.count({
      where: {
        userId,
        dueDate: { gte: startOfToday, lte: endOfToday },
      },
    }),
    prisma.task.count({
      where: {
        userId,
        completedAt: { gte: startOfToday, lte: endOfToday },
      },
    }),
    prisma.task.count({
      where: {
        userId,
        isCompleted: false,
        dueDate: { lt: startOfToday },
      },
    }),
  ]);

  const completionRate = total > 0 ? Number(((completedTotal / total) * 100).toFixed(1)) : 0;

  return {
    total,
    completedTotal,
    dueTodayTotal,
    completedTodayTotal,
    overdueTotal,
    completionRate,
  };
};

export default {
  createTask,
  getTasks,
  getTaskById,
  updateTask,
  toggleTaskComplete,
  deleteTask,
  getTaskStats,
};
