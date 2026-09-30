import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';
import { recalculateGoalProgress } from '../goals/goals.service';

export interface CreateTaskDTO {
  title: string;
  description?: string | null;
  priority?: string;
  status?: string;
  dueDate?: Date | string | null;
  estimatedMinutes?: number | null;
  projectId?: string | null;
  goalId?: string | null;
  milestoneId?: string | null;
  categoryId?: string | null;
  courseId?: string | null;
  parentTaskId?: string | null;
  isRecurring?: boolean;
  recurrenceRule?: string | null;
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
  milestoneId?: string | null;
  categoryId?: string | null;
  courseId?: string | null;
  parentTaskId?: string | null;
  isRecurring?: boolean;
  recurrenceRule?: string | null;
}

export interface GetTasksQuery {
  view?: 'today' | 'upcoming' | 'overdue' | 'completed' | 'all';
  status?: string;
  priority?: string;
  projectId?: string;
  goalId?: string;
  categoryId?: string;
  courseId?: string;
  search?: string;
  parentTaskId?: string;
  page?: number | string;
  limit?: number | string;
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
 * Helper: Automatically synchronizes parent task status based on subtasks
 */
const evaluateParentCompletion = async (userId: string, parentTaskId: string): Promise<void> => {
  const parent = await prisma.task.findFirst({
    where: { id: parentTaskId, userId },
    include: { subtasks: true },
  });

  if (!parent || parent.subtasks.length === 0) return;

  const allSubtasksDone = parent.subtasks.every((s) => s.isCompleted);

  if (allSubtasksDone && !parent.isCompleted) {
    await prisma.task.update({
      where: { id: parentTaskId },
      data: {
        isCompleted: true,
        status: 'COMPLETED',
        completedAt: new Date(),
      },
    });
  } else if (!allSubtasksDone && parent.isCompleted) {
    await prisma.task.update({
      where: { id: parentTaskId },
      data: {
        isCompleted: false,
        status: 'IN_PROGRESS',
        completedAt: null,
      },
    });
  }
};

/**
 * Helper: Spawns next occurrence for a recurring task
 */
const generateNextRecurringInstance = async (userId: string, task: any): Promise<void> => {
  const baseDate = task.dueDate ? new Date(task.dueDate) : new Date();
  const nextDate = new Date(baseDate);
  const rule = (task.recurrenceRule || 'DAILY').toUpperCase();

  if (rule.includes('WEEKLY')) {
    nextDate.setDate(nextDate.getDate() + 7);
  } else if (rule.includes('MONTHLY')) {
    nextDate.setMonth(nextDate.getMonth() + 1);
  } else {
    nextDate.setDate(nextDate.getDate() + 1);
  }

  const now = new Date();
  if (nextDate <= now) {
    nextDate.setDate(now.getDate() + 1);
  }

  await prisma.task.create({
    data: {
      userId,
      title: task.title,
      description: task.description,
      priority: task.priority,
      status: 'TODO',
      isCompleted: false,
      dueDate: nextDate,
      estimatedMinutes: task.estimatedMinutes,
      projectId: task.projectId,
      categoryId: task.categoryId,
      goalId: task.goalId,
      parentTaskId: task.parentTaskId,
      isRecurring: true,
      recurrenceRule: task.recurrenceRule,
    },
  });
};

/**
 * Cycle detection via DFS
 */
const detectCycle = async (sourceId: string, targetId: string): Promise<boolean> => {
  const visited = new Set<string>();
  const queue = [targetId];

  while (queue.length > 0) {
    const current = queue.shift()!;
    if (current === sourceId) {
      return true;
    }

    visited.add(current);

    const dependencies = await prisma.taskDependency.findMany({
      where: { blockedTaskId: current },
      select: { blockingTaskId: true },
    });

    for (const dep of dependencies) {
      if (!visited.has(dep.blockingTaskId)) {
        queue.push(dep.blockingTaskId);
      }
    }
  }

  return false;
};

/**
 * UC-10: Create Task
 */
export const createTask = async (userId: string, data: CreateTaskDTO) => {
  const task = await prisma.task.create({
    data: {
      title: data.title,
      description: data.description,
      priority: data.priority || 'MEDIUM',
      status: data.status || 'TODO',
      dueDate: data.dueDate ? new Date(data.dueDate) : null,
      estimatedMinutes: data.estimatedMinutes,
      parentTaskId: data.parentTaskId || null,
      isRecurring: data.isRecurring || false,
      recurrenceRule: data.recurrenceRule || null,
      userId,
      projectId: data.projectId,
      goalId: data.goalId,
      milestoneId: data.milestoneId || null,
      categoryId: data.categoryId,
      courseId: data.courseId,
    },
    include: {
      project: { select: { id: true, title: true, color: true } },
      goal: { select: { id: true, title: true } },
      category: { select: { id: true, name: true, color: true, icon: true } },
      course: { select: { id: true, name: true, color: true } },
    },
  });


  if (data.projectId) await recalculateProjectProgress(data.projectId);
  if (data.goalId) await recalculateGoalProgress(data.goalId);

  invalidateDashboardCache(userId);
  return task;
};

/**
 * UC-15, UC-16: Get Tasks with Filtering, Views, Search and Pagination
 */
export const getTasks = async (userId: string, query: GetTasksQuery) => {
  const page = Math.max(1, Number(query.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
  const skip = (page - 1) * limit;

  const { view, status, priority, projectId, goalId, categoryId, courseId, search, parentTaskId } = query;

  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

  const where: Prisma.TaskWhereInput = { userId };

  if (view === 'today') {
    where.OR = [
      { dueDate: { gte: startOfToday, lte: endOfToday } },
      { dueDate: { lt: startOfToday }, isCompleted: false },
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

  if (status) where.status = status;
  if (priority) where.priority = priority;
  if (projectId) where.projectId = projectId;
  if (goalId) where.goalId = goalId;
  if (categoryId) where.categoryId = categoryId;
  if (courseId) where.courseId = courseId;

  if (parentTaskId !== undefined) {
    if (parentTaskId === 'all') {
      // Do not filter by parentTaskId
    } else {
      where.parentTaskId = parentTaskId === 'null' || parentTaskId === '' ? null : parentTaskId;
    }
  } else {
    // Top-level task list excludes child subtasks by default
    where.parentTaskId = null;
  }


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

  const [rawTasks, total] = await Promise.all([
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
        course: { select: { id: true, name: true, color: true } },

        subtasks: {
          select: {
            id: true,
            title: true,
            isCompleted: true,
            status: true,
            priority: true,
          },
        },
        blockedBy: {
          include: {
            blockingTask: {
              select: { id: true, title: true, isCompleted: true },
            },
          },
        },
      },
    }),
    prisma.task.count({ where }),
  ]);

  const formatted = rawTasks.map((t) => {
    const subtaskCount = t.subtasks?.length || 0;
    const completedSubtaskCount = t.subtasks?.filter((s) => s.isCompleted).length || 0;
    const incompleteBlockers = t.blockedBy?.filter((b) => !b.blockingTask.isCompleted) || [];

    return {
      ...t,
      subtaskProgress: {
        total: subtaskCount,
        completed: completedSubtaskCount,
        fraction: `${completedSubtaskCount}/${subtaskCount}`,
        percent: subtaskCount > 0 ? Math.round((completedSubtaskCount / subtaskCount) * 100) : 0,
      },
      isBlocked: incompleteBlockers.length > 0,
      blockedByPrerequisites: incompleteBlockers.map((b) => ({
        id: b.blockingTask.id,
        title: b.blockingTask.title,
      })),
    };
  });

  const paginationMeta = {
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
  };

  return {
    tasks: formatted,
    data: formatted,
    pagination: paginationMeta,
    meta: paginationMeta,
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
      subtasks: {
        orderBy: [{ isCompleted: 'asc' }, { createdAt: 'asc' }],
      },
      blockedBy: {
        include: {
          blockingTask: {
            select: { id: true, title: true, isCompleted: true, priority: true, status: true },
          },
        },
      },
      blocking: {
        include: {
          blockedTask: {
            select: { id: true, title: true, isCompleted: true, priority: true, status: true },
          },
        },
      },
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
  if (data.parentTaskId !== undefined) {
    updateData.parentTask = data.parentTaskId ? { connect: { id: data.parentTaskId } } : { disconnect: true };
  }
  if (data.isRecurring !== undefined) updateData.isRecurring = data.isRecurring;
  if (data.recurrenceRule !== undefined) updateData.recurrenceRule = data.recurrenceRule;

  if (data.isCompleted !== undefined || data.status !== undefined) {
    const isCompleted = data.isCompleted !== undefined ? data.isCompleted : data.status === 'COMPLETED';
    if (isCompleted && !existingTask.isCompleted) {
      const blockers = await prisma.taskDependency.findMany({
        where: {
          blockedTaskId: taskId,
          blockingTask: { isCompleted: false },
        },
        include: {
          blockingTask: { select: { title: true } },
        },
      });

      if (blockers.length > 0) {
        const titles = blockers.map((b) => `"${b.blockingTask.title}"`).join(', ');
        throw new ApiError(400, `Cannot complete task: blocked by unfinished prerequisite(s): ${titles}`);
      }
    }
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
  if (data.milestoneId !== undefined) {
    updateData.milestone = data.milestoneId ? { connect: { id: data.milestoneId } } : { disconnect: true };
  }
  if (data.categoryId !== undefined) {
    updateData.category = data.categoryId ? { connect: { id: data.categoryId } } : { disconnect: true };
  }
  if (data.courseId !== undefined) {
    updateData.course = data.courseId ? { connect: { id: data.courseId } } : { disconnect: true };
  }

  const updatedTask = await prisma.task.update({
    where: { id: taskId },
    data: updateData,
    include: {
      project: { select: { id: true, title: true, color: true } },
      goal: { select: { id: true, title: true } },
      category: { select: { id: true, name: true, color: true, icon: true } },
      course: { select: { id: true, name: true, color: true } },
    },
  });


  if (existingTask.parentTaskId) {
    await evaluateParentCompletion(userId, existingTask.parentTaskId);
  }

  if (!existingTask.isCompleted && updatedTask.isCompleted && updatedTask.isRecurring) {
    await generateNextRecurringInstance(userId, updatedTask);
  }

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

  if (isCompleted) {
    const blockers = await prisma.taskDependency.findMany({
      where: {
        blockedTaskId: taskId,
        blockingTask: { isCompleted: false },
      },
      include: {
        blockingTask: { select: { title: true } },
      },
    });

    if (blockers.length > 0) {
      const titles = blockers.map((b) => `"${b.blockingTask.title}"`).join(', ');
      throw new ApiError(400, `Cannot complete task: blocked by unfinished prerequisite(s): ${titles}`);
    }
  }

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

  if (task.parentTaskId) {
    await evaluateParentCompletion(userId, task.parentTaskId);
  }

  if (!task.isCompleted && updatedTask.isCompleted && updatedTask.isRecurring) {
    await generateNextRecurringInstance(userId, updatedTask);
  }

  if (task.projectId) await recalculateProjectProgress(task.projectId);
  if (task.goalId) await recalculateGoalProgress(task.goalId);

  invalidateDashboardCache(userId);
  return updatedTask;
};

export const toggleComplete = toggleTaskComplete;

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

/**
 * Create subtask under parent task
 */
export const createSubtask = async (userId: string, parentTaskId: string, data: any) => {
  const parent = await prisma.task.findFirst({
    where: { id: parentTaskId, userId },
  });

  if (!parent) {
    throw new ApiError(404, 'Parent task not found or access denied');
  }

  const subtask = await prisma.task.create({
    data: {
      userId,
      parentTaskId,
      title: data.title,
      description: data.description || null,
      priority: data.priority || parent.priority,
      status: 'TODO',
      isCompleted: false,
      projectId: parent.projectId,
      goalId: parent.goalId,
      categoryId: parent.categoryId,
    },
  });

  return subtask;
};

/**
 * Add task blocker dependency
 */
export const addDependency = async (userId: string, blockedTaskId: string, blockingTaskId: string) => {
  if (blockedTaskId === blockingTaskId) {
    throw new ApiError(400, 'A task cannot depend on itself');
  }

  const [blocked, blocking] = await Promise.all([
    prisma.task.findFirst({ where: { id: blockedTaskId, userId } }),
    prisma.task.findFirst({ where: { id: blockingTaskId, userId } }),
  ]);

  if (!blocked || !blocking) {
    throw new ApiError(404, 'One or both tasks not found or access denied');
  }

  const hasCycle = await detectCycle(blockedTaskId, blockingTaskId);
  if (hasCycle) {
    throw new ApiError(
      400,
      'Circular dependency detected: adding this relation would create an infinite dependency loop'
    );
  }

  return await prisma.taskDependency.create({
    data: {
      blockedTaskId,
      blockingTaskId,
    },
    include: {
      blockingTask: { select: { id: true, title: true, isCompleted: true } },
      blockedTask: { select: { id: true, title: true } },
    },
  });
};

/**
 * Remove task dependency
 */
export const removeDependency = async (userId: string, blockedTaskId: string, blockingTaskId: string) => {
  const blocked = await prisma.task.findFirst({ where: { id: blockedTaskId, userId } });
  if (!blocked) {
    throw new ApiError(404, 'Task not found or access denied');
  }

  await prisma.taskDependency.deleteMany({
    where: {
      blockedTaskId,
      blockingTaskId,
    },
  });
};

/**
 * Eisenhower Matrix: 2x2 Quadrant Categorization
 */
export const getEisenhowerMatrix = async (userId: string) => {
  const tasks = await prisma.task.findMany({
    where: {
      userId,
      isCompleted: false,
    },
    include: {
      project: { select: { id: true, title: true } },
      category: true,
      subtasks: { select: { id: true, isCompleted: true } },
    },
    orderBy: { dueDate: 'asc' },
  });

  const now = new Date();
  const urgentThreshold = new Date(now.getTime() + 48 * 60 * 60 * 1000);

  const q1: any[] = [];
  const q2: any[] = [];
  const q3: any[] = [];
  const q4: any[] = [];

  for (const task of tasks) {
    const isImportant = task.priority === 'HIGH' || task.priority === 'CRITICAL';
    const isUrgent = task.dueDate !== null && new Date(task.dueDate) <= urgentThreshold;

    if (isImportant && isUrgent) {
      q1.push(task);
    } else if (isImportant && !isUrgent) {
      q2.push(task);
    } else if (!isImportant && isUrgent) {
      q3.push(task);
    } else {
      q4.push(task);
    }
  }

  return {
    quadrants: {
      q1_urgent_important: {
        label: 'Do First (Urgent & Important)',
        description: 'Pressing deadlines and critical issues',
        items: q1,
        count: q1.length,
      },
      q2_not_urgent_important: {
        label: 'Schedule (Important & Not Urgent)',
        description: 'Long-term strategies, deep work, and high-leverage goals',
        items: q2,
        count: q2.length,
      },
      q3_urgent_not_important: {
        label: 'Delegate / Expedite (Urgent & Not Important)',
        description: 'Time-sensitive requests that do not drive primary outcomes',
        items: q3,
        count: q3.length,
      },
      q4_not_urgent_not_important: {
        label: 'Eliminate / Backlog (Not Urgent & Not Important)',
        description: 'Low impact tasks and distractions',
        items: q4,
        count: q4.length,
      },
    },
    totalActiveTasks: tasks.length,
    generatedAt: new Date().toISOString(),
  };
};

/**
 * Daily Workload Capacity calculation
 */
export const getDailyWorkload = async (userId: string) => {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const endOf7Days = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 7, 23, 59, 59, 999);

  const tasks = await prisma.task.findMany({
    where: {
      userId,
      isCompleted: false,
      parentTaskId: null,
      dueDate: {
        lte: endOf7Days,
      },
    },
    select: {
      id: true,
      title: true,
      dueDate: true,
      estimatedMinutes: true,
      priority: true,
    },
  });

  const getCapacityStatus = (totalMinutes: number) => {
    if (totalMinutes > 300) return 'HEAVY';
    if (totalMinutes >= 120) return 'OPTIMAL';
    return 'LIGHT';
  };

  const formatDay = (d: Date) => {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  };

  const todayStr = formatDay(startOfToday);

  let todayMinutes = 0;
  let todayCount = 0;
  let overdueMinutes = 0;
  let overdueCount = 0;

  const dayBuckets: Record<string, { date: string; count: number; totalMinutes: number }> = {};
  for (let i = 0; i <= 7; i++) {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + i);
    const dateStr = formatDay(d);
    dayBuckets[dateStr] = { date: dateStr, count: 0, totalMinutes: 0 };
  }

  for (const t of tasks) {
    if (!t.dueDate) continue;
    const est = t.estimatedMinutes || 30;
    const d = new Date(t.dueDate);
    const dateStr = formatDay(d);

    if (d < startOfToday) {
      overdueMinutes += est;
      overdueCount += 1;
      todayMinutes += est;
      todayCount += 1;
    } else if (dateStr === todayStr) {
      todayMinutes += est;
      todayCount += 1;
    }

    if (dayBuckets[dateStr]) {
      dayBuckets[dateStr].count += 1;
      dayBuckets[dateStr].totalMinutes += est;
    }
  }

  const upcoming = Object.values(dayBuckets).map((b) => ({
    ...b,
    status: getCapacityStatus(b.totalMinutes),
  }));

  return {
    today: {
      count: todayCount,
      totalMinutes: todayMinutes,
      status: getCapacityStatus(todayMinutes),
      overdueCount,
      overdueMinutes,
    },
    upcoming,
  };
};

export default {
  createTask,
  getTasks,
  getTaskById,
  updateTask,
  toggleTaskComplete,
  toggleComplete,
  deleteTask,
  getTaskStats,
  createSubtask,
  addDependency,
  removeDependency,
  getEisenhowerMatrix,
  getDailyWorkload,
};

