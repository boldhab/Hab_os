import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import cache from '../../utils/cache';
import { parsePagination, buildPaginatedResult, PaginatedResult } from '../../common/pagination';

export interface CreateTaskInput {
  title: string;
  description?: string | null;
  priority?: string;
  dueDate?: string | Date | null;
  projectId?: string | null;
  categoryId?: string | null;
  goalId?: string | null;
  estimatedMinutes?: number | null;
  parentTaskId?: string | null;
  isRecurring?: boolean;
  recurrenceRule?: string | null;
}

export interface UpdateTaskInput {
  title?: string;
  description?: string | null;
  priority?: string;
  status?: string;
  isCompleted?: boolean;
  dueDate?: string | Date | null;
  projectId?: string | null;
  categoryId?: string | null;
  goalId?: string | null;
  estimatedMinutes?: number | null;
  parentTaskId?: string | null;
  isRecurring?: boolean;
  recurrenceRule?: string | null;
}

export class TasksService {
  /**
   * Retrieves paginated tasks for a user with optional filtering
   * Includes subtask summaries and dependency blocker status
   */
  async getTasks(userId: string, query: Record<string, any>): Promise<PaginatedResult<any>> {
    const { status, priority, projectId, categoryId, search, parentTaskId } = query;
    const pagination = parsePagination(query);

    const where: any = { userId };
    if (status && typeof status === 'string') where.status = status;
    if (priority && typeof priority === 'string') where.priority = priority;
    if (projectId && typeof projectId === 'string') where.projectId = projectId;
    if (categoryId && typeof categoryId === 'string') where.categoryId = categoryId;

    // By default, list top-level tasks unless a specific parent is requested
    if (parentTaskId !== undefined) {
      where.parentTaskId = parentTaskId === 'null' || parentTaskId === '' ? null : parentTaskId;
    }

    if (search && typeof search === 'string') {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [total, tasks] = await Promise.all([
      prisma.task.count({ where }),
      prisma.task.findMany({
        where,
        include: {
          project: { select: { id: true, title: true } },
          category: true,
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
        orderBy: { createdAt: 'desc' },
        skip: pagination.skip,
        take: pagination.limit,
      }),
    ]);

    // Format subtask progress and blocker metadata
    const formatted = tasks.map((t) => {
      const subtaskCount = t.subtasks.length;
      const completedSubtaskCount = t.subtasks.filter((s) => s.isCompleted).length;
      const incompleteBlockers = t.blockedBy.filter((b) => !b.blockingTask.isCompleted);

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

    return buildPaginatedResult(formatted, total, {
      page: pagination.page,
      limit: pagination.limit,
    });
  }

  /**
   * Aggregates task metrics for dashboard and statistics view
   */
  async getTaskStats(userId: string) {
    const [total, completed, inProgress] = await Promise.all([
      prisma.task.count({ where: { userId } }),
      prisma.task.count({ where: { userId, isCompleted: true } }),
      prisma.task.count({ where: { userId, status: 'IN_PROGRESS' } }),
    ]);

    return {
      total,
      completed,
      inProgress,
      todo: total - completed - inProgress,
    };
  }

  /**
   * Creates a new task or subtask and invalidates user dashboard cache
   */
  async createTask(userId: string, input: CreateTaskInput) {
    // If parentTaskId is supplied, verify parent ownership
    if (input.parentTaskId) {
      const parent = await prisma.task.findFirst({
        where: { id: input.parentTaskId, userId },
      });
      if (!parent) {
        throw new ApiError(404, 'Parent task not found or access denied');
      }
    }

    const task = await prisma.task.create({
      data: {
        userId,
        title: input.title.trim(),
        description: input.description || null,
        priority: input.priority || 'MEDIUM',
        dueDate: input.dueDate ? new Date(input.dueDate) : null,
        projectId: input.projectId || null,
        categoryId: input.categoryId || null,
        goalId: input.goalId || null,
        estimatedMinutes: input.estimatedMinutes ? Number(input.estimatedMinutes) : null,
        parentTaskId: input.parentTaskId || null,
        isRecurring: input.isRecurring ?? false,
        recurrenceRule: input.recurrenceRule || null,
      },
      include: {
        project: { select: { id: true, title: true } },
        category: true,
        subtasks: true,
      },
    });

    cache.del(`dashboard:${userId}`);
    return task;
  }

  /**
   * Creates a dedicated subtask under a parent task
   */
  async createSubtask(userId: string, parentTaskId: string, input: CreateTaskInput) {
    return this.createTask(userId, {
      ...input,
      parentTaskId,
    });
  }

  /**
   * Updates an existing task ensuring strict user ownership (prevents IDOR).
   * - Enforces Dependency Blocker checks before allowing completion.
   * - Encapsulates parent auto-completion when all subtasks complete.
   * - Automatically spawns next occurrence if task is recurring.
   */
  async updateTask(userId: string, taskId: string, input: UpdateTaskInput) {
    const existing = await prisma.task.findFirst({
      where: { id: taskId, userId },
      include: {
        blockedBy: {
          include: {
            blockingTask: { select: { id: true, title: true, isCompleted: true } },
          },
        },
      },
    });

    if (!existing) {
      throw new ApiError(404, 'Task not found or access denied');
    }

    const updateData: any = {};
    const willBeCompleted = input.isCompleted === true || input.status === 'COMPLETED';

    // 1. DEPENDENCY CHECK: Prevent completion if any blocker is incomplete
    if (willBeCompleted && !existing.isCompleted) {
      const incompleteBlockers = existing.blockedBy.filter((b) => !b.blockingTask.isCompleted);
      if (incompleteBlockers.length > 0) {
        const blockerNames = incompleteBlockers.map((b) => `"${b.blockingTask.title}"`).join(', ');
        throw new ApiError(
          400,
          `Cannot complete task: blocked by incomplete prerequisite task(s): ${blockerNames}`
        );
      }
    }

    // 2. State Machine completion logic
    if (input.isCompleted !== undefined) {
      updateData.isCompleted = input.isCompleted;
      updateData.status = input.isCompleted ? 'COMPLETED' : 'TODO';
      updateData.completedAt = input.isCompleted ? new Date() : null;
    } else if (input.status !== undefined) {
      updateData.status = input.status;
      if (input.status === 'COMPLETED') {
        updateData.isCompleted = true;
        updateData.completedAt = existing.completedAt || new Date();
      } else {
        updateData.isCompleted = false;
        updateData.completedAt = null;
      }
    }

    if (input.title !== undefined) updateData.title = input.title.trim();
    if (input.description !== undefined) updateData.description = input.description;
    if (input.priority !== undefined) updateData.priority = input.priority;
    if (input.dueDate !== undefined) updateData.dueDate = input.dueDate ? new Date(input.dueDate) : null;
    if (input.projectId !== undefined) updateData.projectId = input.projectId;
    if (input.categoryId !== undefined) updateData.categoryId = input.categoryId;
    if (input.goalId !== undefined) updateData.goalId = input.goalId;
    if (input.isRecurring !== undefined) updateData.isRecurring = input.isRecurring;
    if (input.recurrenceRule !== undefined) updateData.recurrenceRule = input.recurrenceRule;
    if (input.estimatedMinutes !== undefined) {
      updateData.estimatedMinutes = input.estimatedMinutes ? Number(input.estimatedMinutes) : null;
    }

    const updatedTask = await prisma.task.update({
      where: { id: taskId },
      data: updateData,
      include: {
        project: { select: { id: true, title: true } },
        category: true,
        subtasks: true,
      },
    });

    // 3. SUBTASK AUTO-COMPLETION RULE
    // If this updated task is a subtask, evaluate parent auto-completion
    if (updatedTask.parentTaskId) {
      await this.evaluateParentCompletion(userId, updatedTask.parentTaskId);
    }

    // 4. RECURRING TASK GENERATION RULE
    // If completing a recurring task, generate next pending occurrence
    if (
      !existing.isCompleted &&
      updatedTask.isCompleted &&
      updatedTask.isRecurring &&
      updatedTask.recurrenceRule
    ) {
      await this.generateNextRecurringInstance(userId, updatedTask);
    }

    cache.del(`dashboard:${userId}`);
    return updatedTask;
  }

  /**
   * Helper: Automatically synchronizes parent task status based on subtasks
   */
  private async evaluateParentCompletion(userId: string, parentTaskId: string): Promise<void> {
    const parent = await prisma.task.findFirst({
      where: { id: parentTaskId, userId },
      include: { subtasks: true },
    });

    if (!parent || parent.subtasks.length === 0) return;

    const allSubtasksDone = parent.subtasks.every((s) => s.isCompleted);

    if (allSubtasksDone && !parent.isCompleted) {
      // Auto-complete parent task
      await prisma.task.update({
        where: { id: parentTaskId },
        data: {
          isCompleted: true,
          status: 'COMPLETED',
          completedAt: new Date(),
        },
      });
    } else if (!allSubtasksDone && parent.isCompleted) {
      // Revert parent task to in-progress if a subtask was reopened
      await prisma.task.update({
        where: { id: parentTaskId },
        data: {
          isCompleted: false,
          status: 'IN_PROGRESS',
          completedAt: null,
        },
      });
    }
  }

  /**
   * Helper: Spawns next occurrence for a recurring task
   */
  private async generateNextRecurringInstance(userId: string, task: any): Promise<void> {
    const baseDate = task.dueDate ? new Date(task.dueDate) : new Date();
    const nextDate = new Date(baseDate);
    const rule = (task.recurrenceRule || 'DAILY').toUpperCase();

    if (rule.includes('WEEKLY')) {
      nextDate.setDate(nextDate.getDate() + 7);
    } else if (rule.includes('MONTHLY')) {
      nextDate.setMonth(nextDate.getMonth() + 1);
    } else {
      // Default: DAILY
      nextDate.setDate(nextDate.getDate() + 1);
    }

    // If nextDate is still in the past, adjust relative to today
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
  }

  /**
   * Dedicated method to toggle task completion state
   */
  async toggleComplete(userId: string, taskId: string) {
    const existing = await prisma.task.findFirst({
      where: { id: taskId, userId },
    });

    if (!existing) {
      throw new ApiError(404, 'Task not found or access denied');
    }

    return this.updateTask(userId, taskId, {
      isCompleted: !existing.isCompleted,
    });
  }

  /**
   * Deletes a task ensuring user ownership
   */
  async deleteTask(userId: string, taskId: string) {
    const existing = await prisma.task.findFirst({
      where: { id: taskId, userId },
    });

    if (!existing) {
      throw new ApiError(404, 'Task not found or access denied');
    }

    await prisma.task.delete({
      where: { id: taskId },
    });

    cache.del(`dashboard:${userId}`);
  }

  /**
   * Adds a prerequisite dependency with Cycle Detection
   * blockedTaskId cannot be completed until blockingTaskId is completed.
   */
  async addDependency(userId: string, blockedTaskId: string, blockingTaskId: string) {
    if (blockedTaskId === blockingTaskId) {
      throw new ApiError(400, 'A task cannot depend on itself');
    }

    // Verify both tasks belong to the user
    const [blocked, blocking] = await Promise.all([
      prisma.task.findFirst({ where: { id: blockedTaskId, userId } }),
      prisma.task.findFirst({ where: { id: blockingTaskId, userId } }),
    ]);

    if (!blocked || !blocking) {
      throw new ApiError(404, 'One or both tasks not found or access denied');
    }

    // Cycle detection via DFS
    const hasCycle = await this.detectCycle(blockedTaskId, blockingTaskId);
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
  }

  /**
   * Removes a dependency link
   */
  async removeDependency(userId: string, blockedTaskId: string, blockingTaskId: string) {
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
  }

  /**
   * DFS Cycle Detection helper: tests if targetId can reach sourceId
   */
  private async detectCycle(sourceId: string, targetId: string): Promise<boolean> {
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
  }

  /**
   * Eisenhower Matrix: 2x2 Quadrant Categorization
   * Q1: Urgent & Important
   * Q2: Not Urgent & Important
   * Q3: Urgent & Not Important
   * Q4: Not Urgent & Not Important
   */
  async getEisenhowerMatrix(userId: string) {
    const tasks = await prisma.task.findMany({
      where: {
        userId,
        isCompleted: false, // Matrix focuses on active pending work
      },
      include: {
        project: { select: { id: true, title: true } },
        category: true,
        subtasks: { select: { id: true, isCompleted: true } },
      },
      orderBy: { dueDate: 'asc' },
    });

    const now = new Date();
    const urgentThreshold = new Date(now.getTime() + 48 * 60 * 60 * 1000); // 48 hours

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
  }
}

export const tasksService = new TasksService();
export default tasksService;
