import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import logger from '../../utils/logger';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';
import { recalculateGoalProgress, recalculateGoalProgressTx } from '../goals/goals.service';
import calendarSyncService from './calendarSync.service';

type DbClient = Prisma.TransactionClient | typeof prisma;

export interface CreateTaskDTO {
  title: string;
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

export interface ReorderTaskDTO {
  targetTaskId: string;
  prevOrder?: number;
  nextOrder?: number;
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
  cursor?: string;
}

/**
 * Helper: Validates multi-tenant ownership for related resources (IDOR prevention)
 */
const validateRelationOwnership = async (
  userId: string,
  relations: {
    projectId?: string | null;
    goalId?: string | null;
    milestoneId?: string | null;
    categoryId?: string | null;
    courseId?: string | null;
    parentTaskId?: string | null;
  },
  currentTaskId?: string,
  db: DbClient = prisma
) => {
  if (relations.projectId) {
    const project = await db.project.findFirst({
      where: { id: relations.projectId, userId },
      select: { id: true },
    });
    if (!project) throw new ApiError(404, 'Linked project not found or access denied');
  }

  if (relations.goalId) {
    const goal = await db.goal.findFirst({
      where: { id: relations.goalId, userId },
      select: { id: true },
    });
    if (!goal) throw new ApiError(404, 'Linked goal not found or access denied');
  }

  if (relations.milestoneId) {
    const milestone = await db.milestone.findFirst({
      where: { id: relations.milestoneId, goal: { userId } },
      select: { id: true },
    });
    if (!milestone) throw new ApiError(404, 'Linked milestone not found or access denied');
  }

  if (relations.categoryId) {
    const category = await db.category.findFirst({
      where: { id: relations.categoryId, userId },
      select: { id: true },
    });
    if (!category) throw new ApiError(404, 'Linked category not found or access denied');
  }

  if (relations.courseId) {
    const course = await db.course.findFirst({
      where: { id: relations.courseId, userId },
      select: { id: true },
    });
    if (!course) throw new ApiError(404, 'Linked course not found or access denied');
  }

  if (relations.parentTaskId) {
    const visited = new Set<string>();
    let ancestorId: string | null = relations.parentTaskId;

    while (ancestorId) {
      if (currentTaskId && ancestorId === currentTaskId) {
        throw new ApiError(400, 'A task cannot be assigned beneath one of its descendants');
      }
      if (visited.has(ancestorId)) {
        throw new ApiError(400, 'Task hierarchy contains a circular parent relationship');
      }
      visited.add(ancestorId);

      const parentTaskRecord: { id: string; parentTaskId: string | null } | null = await db.task.findFirst({
        where: { id: ancestorId, userId },
        select: { id: true, parentTaskId: true },
      });
      if (!parentTaskRecord) throw new ApiError(404, 'Parent task not found or access denied');
      ancestorId = parentTaskRecord.parentTaskId;
    }
  }
};

/**
 * Helper: Downstream recalculation of project progress (UC-42)
 */
const recalculateProjectProgress = async (projectId: string, db: DbClient = prisma) => {
  const totalTasks = await db.task.count({ where: { projectId } });
  if (totalTasks === 0) {
    await db.project.update({
      where: { id: projectId },
      data: { progress: 0 },
    });
    return;
  }

  const completedTasks = await db.task.count({
    where: { projectId, isCompleted: true },
  });

  const progress = Number(((completedTasks / totalTasks) * 100).toFixed(1));
  await db.project.update({
    where: { id: projectId },
    data: { progress },
  });
};

/**
 * Helper: Automatically synchronizes parent task status based on subtasks
 */
const evaluateParentCompletion = async (userId: string, parentTaskId: string, db: DbClient = prisma): Promise<void> => {
  const parent = await db.task.findFirst({
    where: { id: parentTaskId, userId },
    include: {
      subtasks: true,
      blockedBy: {
        include: { blockingTask: { select: { isCompleted: true } } },
      },
    },
  });

  if (!parent || parent.subtasks.length === 0) return;

  const allSubtasksDone = parent.subtasks.every((s) => s.isCompleted);

  if (allSubtasksDone && !parent.isCompleted) {
    const hasIncompleteBlockers = parent.blockedBy.some((b) => !b.blockingTask.isCompleted);
    if (!hasIncompleteBlockers) {
      await db.task.update({
        where: { id: parentTaskId },
        data: {
          isCompleted: true,
          status: 'COMPLETED',
          completedAt: new Date(),
        },
      });
      if (parent.projectId) await recalculateProjectProgress(parent.projectId, db);
      if (parent.goalId) await recalculateGoalProgressTx(parent.goalId, db);
    }
  } else if (!allSubtasksDone && parent.isCompleted) {
    await db.task.update({
      where: { id: parentTaskId },
      data: {
        isCompleted: false,
        status: 'IN_PROGRESS',
        completedAt: null,
      },
    });
    if (parent.projectId) await recalculateProjectProgress(parent.projectId, db);
    if (parent.goalId) await recalculateGoalProgressTx(parent.goalId, db);
  }
};

/**
 * Helper: Spawns next occurrence for a recurring task
 */
const generateNextRecurringInstance = async (userId: string, task: any, db: DbClient = prisma): Promise<void> => {
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

  await db.task.create({
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
      milestoneId: task.milestoneId || null,
      courseId: task.courseId || null,
      parentTaskId: task.parentTaskId,
      isRecurring: true,
      recurrenceRule: task.recurrenceRule,
    },
  });
};

/**
 * Cycle detection via BFS with batch-prefetched dependency graph.
 *
 * Loads all dependency edges for the user's task graph in a single query,
 * builds an in-memory adjacency map, then performs BFS from targetId to
 * check if sourceId is reachable — which would indicate a cycle.
 */
const detectCycle = async (sourceId: string, targetId: string, db: DbClient = prisma): Promise<boolean> => {
  // Batch-fetch the entire dependency graph in one query
  const allEdges = await db.taskDependency.findMany({
    where: {
      OR: [
        { blockedTaskId: sourceId },
        { blockedTaskId: targetId },
        { blockingTaskId: sourceId },
        { blockingTaskId: targetId },
      ],
    },
    select: { blockedTaskId: true, blockingTaskId: true },
  });

  // If the graph is small enough from the OR filter, expand to full subgraph
  // by collecting all reachable node IDs and re-fetching
  const nodeIds = new Set<string>();
  for (const e of allEdges) {
    nodeIds.add(e.blockedTaskId);
    nodeIds.add(e.blockingTaskId);
  }

  const fullEdges = nodeIds.size > 0
    ? await db.taskDependency.findMany({
        where: {
          OR: [
            { blockedTaskId: { in: [...nodeIds] } },
            { blockingTaskId: { in: [...nodeIds] } },
          ],
        },
        select: { blockedTaskId: true, blockingTaskId: true },
      })
    : allEdges;

  // Build adjacency map: blockedTaskId -> [blockingTaskIds]
  const adjacency = new Map<string, string[]>();
  for (const edge of fullEdges) {
    const list = adjacency.get(edge.blockedTaskId);
    if (list) {
      list.push(edge.blockingTaskId);
    } else {
      adjacency.set(edge.blockedTaskId, [edge.blockingTaskId]);
    }
  }

  // BFS from targetId; if we reach sourceId, adding sourceId->targetId would form a cycle
  const visited = new Set<string>();
  const queue = [targetId];

  while (queue.length > 0) {
    const current = queue.shift()!;
    if (current === sourceId) return true;
    if (visited.has(current)) continue;
    visited.add(current);

    const neighbors = adjacency.get(current);
    if (neighbors) {
      for (const next of neighbors) {
        if (!visited.has(next)) {
          queue.push(next);
        }
      }
    }
  }

  return false;
};

/**
 * UC-10: Create Task
 */
export const createTask = async (userId: string, data: CreateTaskDTO) => {
  await validateRelationOwnership(userId, data);

  const isCompleted = data.isCompleted === true || data.status === 'COMPLETED';
  const status = isCompleted ? 'COMPLETED' : (data.status || 'TODO');
  const completedAt = isCompleted ? new Date() : null;

  const task = await prisma.$transaction(async (tx) => {
    const created = await tx.task.create({
      data: {
        title: data.title,
        description: data.description,
        priority: data.priority || 'MEDIUM',
        status,
        isCompleted,
        completedAt,
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

    if (data.parentTaskId) {
      await evaluateParentCompletion(userId, data.parentTaskId, tx);
    }
    if (data.projectId) await recalculateProjectProgress(data.projectId, tx);
    if (data.goalId) await recalculateGoalProgressTx(data.goalId, tx);

    return created;
  });

  invalidateDashboardCache(userId);

  if (task.dueDate) {
    calendarSyncService.syncTaskToCalendar(userId, task.id).catch((err) => {
      logger.warn(`[CalendarSync] Background sync failed for task ${task.id}: ${err.message}`);
    });
  }

  return task;
};

/**
 * UC-15, UC-16: Get Tasks with Filtering, Views, Search, Pagination (Offset + Cursor)
 */
export const getTasks = async (userId: string, query: GetTasksQuery) => {
  const page = Math.max(1, Number(query.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
  const skip = (page - 1) * limit;
  const isCursorMode = Boolean(query.cursor);
  const cursor = query.cursor;

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

  const [fetchedTasks, total] = await Promise.all([
    prisma.task.findMany({
      where,
      take: isCursorMode ? limit + 1 : limit,
      ...(isCursorMode
        ? { cursor: { id: cursor }, skip: 1 }
        : { skip }),
      orderBy: [
        { isCompleted: 'asc' },
        { order: 'asc' },
        { priority: 'desc' },
        { dueDate: 'asc' },
        { createdAt: 'desc' },
        { id: 'asc' },
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

  let rawTasks = fetchedTasks;
  let hasMore = false;
  let nextCursor: string | null = null;

  if (isCursorMode && rawTasks.length > limit) {
    hasMore = true;
    rawTasks = rawTasks.slice(0, limit);
    nextCursor = rawTasks[rawTasks.length - 1].id;
  }

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
    page: isCursorMode ? null : page,
    limit,
    totalPages: Math.ceil(total / limit),
    nextCursor,
    hasMore: isCursorMode ? hasMore : page < Math.ceil(total / limit),
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
 * UC-11: Update Task (Wrapped in Atomic Prisma Transaction)
 */
export const updateTask = async (userId: string, taskId: string, data: UpdateTaskDTO) => {
  const updatedTask = await prisma.$transaction(async (tx) => {
    const existingTask = await tx.task.findFirst({
      where: { id: taskId, userId },
    });

    if (!existingTask) {
      throw new ApiError(404, 'Task not found');
    }

    await validateRelationOwnership(userId, data, taskId, tx);

    const updateData: Prisma.TaskUpdateInput = {};

    if (data.title !== undefined) updateData.title = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.priority !== undefined) updateData.priority = data.priority;
    if (data.estimatedMinutes !== undefined) updateData.estimatedMinutes = data.estimatedMinutes;
    if (data.dueDate !== undefined) updateData.dueDate = data.dueDate ? new Date(data.dueDate) : null;
    if (data.parentTaskId !== undefined) {
      if (data.parentTaskId) {
        updateData.parentTask = { connect: { id: data.parentTaskId } };
      } else if (existingTask.parentTaskId) {
        updateData.parentTask = { disconnect: true };
      }
    }
    if (data.isRecurring !== undefined) updateData.isRecurring = data.isRecurring;
    if (data.recurrenceRule !== undefined) updateData.recurrenceRule = data.recurrenceRule;

    if (data.isCompleted !== undefined || data.status !== undefined) {
      let willComplete = false;
      let targetStatus = existingTask.status;

      if (data.isCompleted !== undefined) {
        willComplete = data.isCompleted;
        targetStatus = willComplete ? 'COMPLETED' : (data.status && data.status !== 'COMPLETED' ? data.status : 'TODO');
      } else if (data.status !== undefined) {
        willComplete = data.status === 'COMPLETED';
        targetStatus = data.status;
      }

      if (willComplete && !existingTask.isCompleted) {
        const blockers = await tx.taskDependency.findMany({
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
      updateData.isCompleted = willComplete;
      updateData.status = targetStatus;
      updateData.completedAt = willComplete ? (existingTask.completedAt || new Date()) : null;
    }

    if (data.projectId !== undefined) {
      if (data.projectId) {
        updateData.project = { connect: { id: data.projectId } };
      } else if (existingTask.projectId) {
        updateData.project = { disconnect: true };
      }
    }
    if (data.goalId !== undefined) {
      if (data.goalId) {
        updateData.goal = { connect: { id: data.goalId } };
      } else if (existingTask.goalId) {
        updateData.goal = { disconnect: true };
      }
    }
    if (data.milestoneId !== undefined) {
      if (data.milestoneId) {
        updateData.milestone = { connect: { id: data.milestoneId } };
      } else if (existingTask.milestoneId) {
        updateData.milestone = { disconnect: true };
      }
    }
    if (data.categoryId !== undefined) {
      if (data.categoryId) {
        updateData.category = { connect: { id: data.categoryId } };
      } else if (existingTask.categoryId) {
        updateData.category = { disconnect: true };
      }
    }
    if (data.courseId !== undefined) {
      if (data.courseId) {
        updateData.course = { connect: { id: data.courseId } };
      } else if (existingTask.courseId) {
        updateData.course = { disconnect: true };
      }
    }

    const taskResult = await tx.task.update({
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
      await evaluateParentCompletion(userId, existingTask.parentTaskId, tx);
    }

    if (!existingTask.isCompleted && taskResult.isCompleted && taskResult.isRecurring) {
      await generateNextRecurringInstance(userId, taskResult, tx);
    }

    const affectedProjects = [existingTask.projectId, data.projectId].filter(Boolean) as string[];
    for (const pid of new Set(affectedProjects)) {
      await recalculateProjectProgress(pid, tx);
    }

    const affectedGoals = [existingTask.goalId, data.goalId].filter(Boolean) as string[];
    for (const gid of new Set(affectedGoals)) {
      await recalculateGoalProgressTx(gid, tx);
    }

    return taskResult;
  });

  invalidateDashboardCache(userId);

  if (updatedTask.dueDate || updatedTask.googleEventId) {
    calendarSyncService.syncTaskToCalendar(userId, updatedTask.id).catch((err) => {
      logger.warn(`[CalendarSync] Background sync failed for task ${updatedTask.id}: ${err.message}`);
    });
  }

  return updatedTask;
};

/**
 * UC-13: Toggle Task Completion (Wrapped in Atomic Prisma Transaction)
 */
export const toggleTaskComplete = async (userId: string, taskId: string) => {
  const updatedTask = await prisma.$transaction(async (tx) => {
    const task = await tx.task.findFirst({
      where: { id: taskId, userId },
    });

    if (!task) {
      throw new ApiError(404, 'Task not found');
    }

    const isCompleted = !task.isCompleted;
    const status = isCompleted ? 'COMPLETED' : 'TODO';
    const completedAt = isCompleted ? new Date() : null;

    if (isCompleted) {
      const blockers = await tx.taskDependency.findMany({
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

    const taskResult = await tx.task.update({
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
      await evaluateParentCompletion(userId, task.parentTaskId, tx);
    }

    if (!task.isCompleted && taskResult.isCompleted && taskResult.isRecurring) {
      await generateNextRecurringInstance(userId, taskResult, tx);
    }

    if (task.projectId) await recalculateProjectProgress(task.projectId, tx);
    if (task.goalId) await recalculateGoalProgressTx(task.goalId, tx);

    return taskResult;
  });

  invalidateDashboardCache(userId);

  if (updatedTask.dueDate || updatedTask.googleEventId) {
    calendarSyncService.syncTaskToCalendar(userId, updatedTask.id).catch((err) => {
      logger.warn(`[CalendarSync] Background sync failed for task ${updatedTask.id}: ${err.message}`);
    });
  }

  return updatedTask;
};

export const toggleComplete = toggleTaskComplete;

/**
 * Reorder task using fractional positioning coordinates
 */
export const reorderTask = async (userId: string, params: ReorderTaskDTO) => {
  const { targetTaskId, prevOrder, nextOrder } = params;

  const task = await prisma.task.findFirst({
    where: { id: targetTaskId, userId },
  });

  if (!task) {
    throw new ApiError(404, 'Task not found');
  }

  let calculatedOrder: number;
  if (prevOrder !== undefined && prevOrder !== null && nextOrder !== undefined && nextOrder !== null) {
    calculatedOrder = (Number(prevOrder) + Number(nextOrder)) / 2;
  } else if (prevOrder !== undefined && prevOrder !== null) {
    calculatedOrder = Number(prevOrder) + 1.0;
  } else if (nextOrder !== undefined && nextOrder !== null) {
    calculatedOrder = Number(nextOrder) / 2;
  } else {
    calculatedOrder = 1.0;
  }

  const updated = await prisma.task.update({
    where: { id: targetTaskId },
    data: { order: calculatedOrder },
    select: { id: true, order: true },
  });

  invalidateDashboardCache(userId);
  return updated;
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

  if (task.googleEventId) {
    calendarSyncService.deleteCalendarEvent(userId, task.googleEventId).catch((err) => {
      logger.warn(`[CalendarSync] Background event deletion failed for task ${taskId}: ${err.message}`);
    });
  }

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

  const subtask = await prisma.$transaction(async (tx) => {
    const created = await tx.task.create({
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
        milestoneId: parent.milestoneId,
        courseId: parent.courseId,
      },
    });

    if (parent.isCompleted) {
      await tx.task.update({
        where: { id: parentTaskId },
        data: {
          isCompleted: false,
          status: 'IN_PROGRESS',
          completedAt: null,
        },
      });
      if (parent.projectId) await recalculateProjectProgress(parent.projectId, tx);
      if (parent.goalId) await recalculateGoalProgressTx(parent.goalId, tx);
    }

    return created;
  });

  invalidateDashboardCache(userId);
  return subtask;
};

/**
 * Add task blocker dependency
 */
export const addDependency = async (userId: string, blockedTaskId: string, blockingTaskId: string) => {
  if (blockedTaskId === blockingTaskId) {
    throw new ApiError(400, 'A task cannot depend on itself');
  }

  return prisma.$transaction(async (tx) => {
    const [blocked, blocking] = await Promise.all([
      tx.task.findFirst({ where: { id: blockedTaskId, userId } }),
      tx.task.findFirst({ where: { id: blockingTaskId, userId } }),
    ]);

    if (!blocked || !blocking) {
      throw new ApiError(404, 'One or both tasks not found or access denied');
    }

    const hasCycle = await detectCycle(blockedTaskId, blockingTaskId, tx);
    if (hasCycle) {
      throw new ApiError(
        400,
        'Circular dependency detected: adding this relation would create an infinite dependency loop'
      );
    }

    try {
      return await tx.taskDependency.create({
        data: {
          blockedTaskId,
          blockingTaskId,
        },
        include: {
          blockingTask: { select: { id: true, title: true, isCompleted: true } },
          blockedTask: { select: { id: true, title: true } },
        },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new ApiError(409, 'This task dependency already exists');
      }
      throw error;
    }
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
  reorderTask,
};


