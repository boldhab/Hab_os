import crypto from 'crypto';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { projectEventBus } from './projects.events';

export interface ProgressCalculationResult {
  progress: number;
  deliverablesCompleted: number;
  deliverablesTotal: number;
  completedTasks: number;
  totalTasks: number;
  completedFeatures: number;
  totalFeatures: number;
  openBugsCount: number;
  criticalBugsCount: number;
  majorBugsCount: number;
  bugPenalty: number;
  formula: string;
}

export interface HealthSignalResult {
  healthStatus: 'HEALTHY' | 'NEEDS_ATTENTION' | 'AT_RISK';
  isStale: boolean;
  daysInactive: number;
  isFirefighting: boolean;
  openBugs: number;
  openFeatures: number;
  openCriticalBugs: number;
  velocityTrend: 'UP' | 'DOWN' | 'STABLE';
  completedLast7Days: number;
  completedPrior7Days: number;
}

/**
 * The normalised in-memory projection that computeHealthFromData operates on.
 * Both computeProjectHealth (DB-sourced) and getProjects (already-fetched data)
 * map their respective Prisma shapes to this before calling the helper.
 */
export interface ProjectHealthInput {
  updatedAt: Date;
  tasks: Array<{
    updatedAt: Date;
    completedAt?: Date | null;
    focusSessions: Array<{ startTime: Date; updatedAt: Date }>;
  }>;
  features: Array<{ status: string; updatedAt: Date }>;
  bugs: Array<{ status: string; severity: string; updatedAt: Date }>;
}

export class ProjectsService {
  /**
   * Pure in-memory health computation. Accepts already-fetched data so
   * neither getProjects nor computeProjectHealth need an extra DB call.
   */
  private computeHealthFromData(input: ProjectHealthInput): HealthSignalResult {
    const now = new Date();
    const msPerDay = 1000 * 60 * 60 * 24;

    // Collect all activity timestamps
    const activityDates: Date[] = [input.updatedAt];
    input.tasks.forEach((t) => {
      activityDates.push(t.updatedAt);
      if (t.completedAt) activityDates.push(t.completedAt);
      t.focusSessions.forEach((fs) => {
        activityDates.push(fs.startTime);
        activityDates.push(fs.updatedAt);
      });
    });
    input.features.forEach((f) => activityDates.push(f.updatedAt));
    input.bugs.forEach((b) => activityDates.push(b.updatedAt));

    const latestActivity = new Date(Math.max(...activityDates.map((d) => d.getTime())));
    const daysInactive = Math.floor((now.getTime() - latestActivity.getTime()) / msPerDay);
    const isStale = daysInactive > 14;

    const openBugs = input.bugs.filter((b) => b.status === 'OPEN' || b.status === 'IN_PROGRESS');
    const openFeatures = input.features.filter((f) => f.status === 'TODO' || f.status === 'IN_PROGRESS');
    const openCriticalBugs = openBugs.filter((b) => b.severity === 'CRITICAL').length;
    const isFirefighting = openBugs.length > openFeatures.length || openCriticalBugs > 0;

    const sevenDaysAgo = new Date(now.getTime() - 7 * msPerDay);
    const fourteenDaysAgo = new Date(now.getTime() - 14 * msPerDay);

    const completedLast7Days =
      input.tasks.filter((t) => t.completedAt && t.completedAt >= sevenDaysAgo).length +
      input.features.filter((f) => f.status === 'COMPLETED' && f.updatedAt >= sevenDaysAgo).length;

    const completedPrior7Days =
      input.tasks.filter((t) => t.completedAt && t.completedAt >= fourteenDaysAgo && t.completedAt < sevenDaysAgo).length +
      input.features.filter((f) => f.status === 'COMPLETED' && f.updatedAt >= fourteenDaysAgo && f.updatedAt < sevenDaysAgo).length;

    let velocityTrend: 'UP' | 'DOWN' | 'STABLE' = 'STABLE';
    if (completedLast7Days > completedPrior7Days) velocityTrend = 'UP';
    else if (completedLast7Days < completedPrior7Days) velocityTrend = 'DOWN';

    let healthStatus: 'HEALTHY' | 'NEEDS_ATTENTION' | 'AT_RISK' = 'HEALTHY';
    if (openCriticalBugs > 0 || isStale || (isFirefighting && openBugs.length >= 3)) {
      healthStatus = 'AT_RISK';
    } else if (isFirefighting || velocityTrend === 'DOWN') {
      healthStatus = 'NEEDS_ATTENTION';
    }

    return {
      healthStatus,
      isStale,
      daysInactive,
      isFirefighting,
      openBugs: openBugs.length,
      openFeatures: openFeatures.length,
      openCriticalBugs,
      velocityTrend,
      completedLast7Days,
      completedPrior7Days,
    };
  }

  /**
   * Recalculates and persists auto progress for a project.
   * Accepts an optional Prisma transaction client to support atomic multi-table operations.
   */
  async computeAndSyncProjectProgress(
    projectId: string,
    dbClient: any = prisma
  ): Promise<ProgressCalculationResult> {
    const project = await dbClient.project.findUnique({
      where: { id: projectId },
      include: {
        tasks: { select: { id: true, status: true, isCompleted: true } },
        features: { select: { id: true, status: true } },
        bugs: { select: { id: true, status: true, severity: true } },
      },
    });

    if (!project) {
      throw ApiError.notFound('Project not found');
    }

    const completedTasks = project.tasks.filter(
      (t: any) => t.isCompleted || t.status === 'COMPLETED' || t.status === 'DONE'
    ).length;
    const totalTasks = project.tasks.length;

    const completedFeatures = project.features.filter(
      (f: any) => f.status === 'COMPLETED' || f.status === 'DONE'
    ).length;
    const totalFeatures = project.features.length;

    const openBugs = project.bugs.filter((b: any) => b.status === 'OPEN' || b.status === 'IN_PROGRESS');
    const openCriticalBugs = openBugs.filter((b: any) => b.severity === 'CRITICAL').length;
    const openMajorBugs = openBugs.filter((b: any) => b.severity === 'MAJOR').length;

    const deliverablesTotal = totalTasks + totalFeatures;
    const deliverablesCompleted = completedTasks + completedFeatures;

    let baseProgress = 0;
    if (deliverablesTotal > 0) {
      baseProgress = (deliverablesCompleted / deliverablesTotal) * 100;
    }

    // Bug penalty: 10% per open critical bug, 3% per major bug
    const bugPenalty = openCriticalBugs * 10 + openMajorBugs * 3;
    const calculatedProgress = deliverablesTotal === 0
      ? 0
      : Math.max(0, Math.min(100, Math.round(baseProgress - bugPenalty)));

    // If manual override is not enabled, update project.progress
    if (!project.manualProgress) {
      await dbClient.project.update({
        where: { id: projectId },
        data: { progress: calculatedProgress },
      });
    }

    return {
      progress: project.manualProgress ? project.progress : calculatedProgress,
      deliverablesCompleted,
      deliverablesTotal,
      completedTasks,
      totalTasks,
      completedFeatures,
      totalFeatures,
      openBugsCount: openBugs.length,
      criticalBugsCount: openCriticalBugs,
      majorBugsCount: openMajorBugs,
      bugPenalty,
      formula: deliverablesTotal > 0
        ? `((${deliverablesCompleted}/${deliverablesTotal}) * 100) - ${bugPenalty}% bug penalty`
        : '0/0 items',
    };
  }

  /**
   * Computes health metrics, risk signals, and velocity trend for a project.
   * Delegates all computation to the shared computeHealthFromData helper.
   */
  async computeProjectHealth(projectId: string): Promise<HealthSignalResult> {
    const project = await prisma.project.findUnique({
      where: { id: projectId },
      include: {
        tasks: {
          select: {
            id: true,
            status: true,
            isCompleted: true,
            updatedAt: true,
            completedAt: true,
            focusSessions: { select: { startTime: true, updatedAt: true } },
          },
        },
        features: { select: { id: true, status: true, updatedAt: true } },
        bugs: { select: { id: true, status: true, severity: true, updatedAt: true } },
      },
    });

    if (!project) throw ApiError.notFound('Project not found');

    return this.computeHealthFromData({
      updatedAt: project.updatedAt,
      tasks: project.tasks.map((t) => ({
        updatedAt: t.updatedAt,
        completedAt: t.completedAt,
        focusSessions: t.focusSessions,
      })),
      features: project.features.map((f) => ({ status: f.status, updatedAt: f.updatedAt })),
      bugs: project.bugs.map((b) => ({ status: b.status, severity: b.severity, updatedAt: b.updatedAt })),
    });
  }

  /**
   * List all projects for a user with computed stats, health badges, and focus hours.
   * Health is computed in-memory via the shared computeHealthFromData helper —
   * no extra DB calls per project.
   */
  async getProjects(userId: string, status?: string, page?: number, limit?: number) {
    const where: any = { userId };
    if (status) where.status = status;

    const projects = await prisma.project.findMany({
      where,
      include: {
        _count: {
          select: { tasks: true, features: true, bugs: true },
        },
        tasks: {
          select: {
            id: true,
            status: true,
            isCompleted: true,
            updatedAt: true,
            completedAt: true,
            focusSessions: { select: { durationMinutes: true, startTime: true, updatedAt: true } },
          },
        },
        features: { select: { id: true, status: true, updatedAt: true } },
        bugs: { select: { id: true, status: true, severity: true, updatedAt: true } },
      },
      orderBy: { updatedAt: 'desc' },
    });

    const results = [];
    for (const project of projects) {
      let totalFocusMinutes = 0;
      project.tasks.forEach((t) => {
        t.focusSessions.forEach((fs) => {
          totalFocusMinutes += fs.durationMinutes || 0;
        });
      });

      const openBugs = project.bugs.filter((b) => b.status === 'OPEN' || b.status === 'IN_PROGRESS');
      const openCriticalBugs = openBugs.filter((b) => b.severity === 'CRITICAL').length;
      const openMajorBugs = openBugs.filter((b) => b.severity === 'MAJOR').length;
      const completedTasks = project.tasks.filter((t) => t.isCompleted || t.status === 'COMPLETED').length;
      const completedFeatures = project.features.filter((f) => f.status === 'COMPLETED').length;

      const deliverablesTotal = project.tasks.length + project.features.length;
      const deliverablesCompleted = completedTasks + completedFeatures;

      let baseProgress = 0;
      if (deliverablesTotal > 0) {
        baseProgress = (deliverablesCompleted / deliverablesTotal) * 100;
      }
      const bugPenalty = openCriticalBugs * 10 + openMajorBugs * 3;
      const computedProgress = deliverablesTotal === 0
        ? 0
        : Math.max(0, Math.min(100, Math.round(baseProgress - bugPenalty)));

      const finalProgress = project.manualProgress ? project.progress : computedProgress;

      // Delegate health to the shared helper — same thresholds as computeProjectHealth
      const health = this.computeHealthFromData({
        updatedAt: project.updatedAt,
        tasks: project.tasks.map((t) => ({
          updatedAt: t.updatedAt,
          completedAt: t.completedAt,
          focusSessions: t.focusSessions.map((fs) => ({
            startTime: fs.startTime,
            updatedAt: fs.updatedAt,
          })),
        })),
        features: project.features.map((f) => ({ status: f.status, updatedAt: f.updatedAt })),
        bugs: project.bugs.map((b) => ({ status: b.status, severity: b.severity, updatedAt: b.updatedAt })),
      });

      results.push({
        id: project.id,
        title: project.title,
        description: project.description,
        status: project.status,
        progress: finalProgress,
        manualProgress: project.manualProgress,
        technologies: project.technologies,
        color: project.color,
        repoUrl: project.repoUrl,
        createdAt: project.createdAt,
        updatedAt: project.updatedAt,
        totalFocusMinutes,
        totalFocusHours: Number((totalFocusMinutes / 60).toFixed(1)),
        healthStatus: health.healthStatus,
        isStale: health.isStale,
        isFirefighting: health.isFirefighting,
        counts: {
          tasks: project.tasks.length,
          completedTasks,
          features: project.features.length,
          completedFeatures,
          bugs: project.bugs.length,
          openBugs: openBugs.length,
          openCriticalBugs,
        },
      });
    }

    if (page && limit && limit > 0) {
      const skip = (page - 1) * limit;
      const paginatedResults = results.slice(skip, skip + limit);
      return {
        data: paginatedResults,
        meta: {
          total: results.length,
          page,
          limit,
          totalPages: Math.ceil(results.length / limit),
        },
      };
    }

    return results;
  }

  /**
   * Get single project details including features, bugs, tasks, health, and focus rollups.
   * NOTE: webhookSecret is intentionally excluded from the response — it is write-only.
   */
  async getProjectById(userId: string, projectId: string) {
    const project = await prisma.project.findFirst({
      where: { id: projectId, userId },
      include: {
        features: { orderBy: { order: 'asc' } },
        bugs: { orderBy: { order: 'asc' } },
        tasks: {
          orderBy: { order: 'asc' },
          include: {
            focusSessions: {
              select: { id: true, durationMinutes: true, startTime: true, endTime: true, category: true },
            },
          },
        },
        githubLinks: true,
      },
    });

    if (!project) {
      throw ApiError.notFound('Project not found');
    }

    const progressStats = await this.computeAndSyncProjectProgress(projectId);
    const healthStats = await this.computeProjectHealth(projectId);

    let totalFocusMinutes = 0;
    project.tasks.forEach((t) => {
      t.focusSessions.forEach((fs) => {
        totalFocusMinutes += fs.durationMinutes || 0;
      });
    });

    // Explicit allowlist — never spread the raw Prisma row to avoid leaking webhookSecret
    return {
      id: project.id,
      userId: project.userId,
      title: project.title,
      description: project.description,
      status: project.status,
      repoUrl: project.repoUrl,
      technologies: project.technologies,
      color: project.color,
      manualProgress: project.manualProgress,
      progress: progressStats.progress,
      progressDetails: progressStats,
      health: healthStats,
      features: project.features,
      bugs: project.bugs,
      tasks: project.tasks,
      githubLinks: project.githubLinks,
      totalFocusMinutes,
      totalFocusHours: Number((totalFocusMinutes / 60).toFixed(1)),
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
    };
  }

  async createProject(userId: string, data: any) {
    const project = await prisma.project.create({
      data: {
        userId,
        title: data.title,
        description: data.description || null,
        status: data.status || 'PLANNING',
        repoUrl: data.repoUrl || null,
        technologies: data.technologies || [],
        color: data.color || '#10B981',
        manualProgress: !!data.manualProgress,
        progress: data.progress ? Number(data.progress) : 0,
        webhookSecret: data.webhookSecret || null,
      },
    });

    return project;
  }

  async updateProject(userId: string, projectId: string, data: any) {
    const existing = await prisma.project.findFirst({ where: { id: projectId, userId } });
    if (!existing) throw ApiError.notFound('Project not found');

    const updateData: any = {};
    if (data.title !== undefined) updateData.title = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.color !== undefined) updateData.color = data.color;
    if (data.repoUrl !== undefined) updateData.repoUrl = data.repoUrl;
    if (data.technologies !== undefined) updateData.technologies = data.technologies;
    if (data.manualProgress !== undefined) updateData.manualProgress = !!data.manualProgress;
    if (data.progress !== undefined) updateData.progress = Number(data.progress);
    if (data.webhookSecret !== undefined) updateData.webhookSecret = data.webhookSecret;

    const updated = await prisma.project.update({
      where: { id: projectId },
      data: updateData,
      include: {
        features: { orderBy: { order: 'asc' } },
        bugs: { orderBy: { order: 'asc' } },
        tasks: {
          orderBy: { order: 'asc' },
          include: {
            focusSessions: {
              select: { id: true, durationMinutes: true, startTime: true, endTime: true, category: true },
            },
          },
        },
        githubLinks: true,
      },
    });

    // Single progress computation — not re-triggered by getProjectById
    const progressStats = updated.manualProgress
      ? { progress: updated.progress, formula: 'Manual override', deliverablesCompleted: 0, deliverablesTotal: 0, completedTasks: 0, totalTasks: 0, completedFeatures: 0, totalFeatures: 0, openBugsCount: 0, criticalBugsCount: 0, majorBugsCount: 0, bugPenalty: 0 }
      : await this.computeAndSyncProjectProgress(projectId);

    const healthStats = await this.computeProjectHealth(projectId);

    let totalFocusMinutes = 0;
    updated.tasks.forEach((t) => {
      t.focusSessions.forEach((fs) => {
        totalFocusMinutes += fs.durationMinutes || 0;
      });
    });

    // Safe serialization — webhookSecret excluded (same allowlist as getProjectById)
    return {
      id: updated.id,
      userId: updated.userId,
      title: updated.title,
      description: updated.description,
      status: updated.status,
      repoUrl: updated.repoUrl,
      technologies: updated.technologies,
      color: updated.color,
      manualProgress: updated.manualProgress,
      progress: progressStats.progress,
      progressDetails: progressStats,
      health: healthStats,
      features: updated.features,
      bugs: updated.bugs,
      tasks: updated.tasks,
      githubLinks: updated.githubLinks,
      totalFocusMinutes,
      totalFocusHours: Number((totalFocusMinutes / 60).toFixed(1)),
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
    };
  }

  async deleteProject(userId: string, projectId: string) {
    const existing = await prisma.project.findFirst({ where: { id: projectId, userId } });
    if (!existing) throw ApiError.notFound('Project not found');

    return prisma.$transaction(async (tx) => {
      await tx.project.delete({ where: { id: projectId } });
      return true;
    });
  }

  // ==========================================
  // FEATURES CRUD
  // ==========================================

  async getFeatures(userId: string, projectId: string, query: any = {}) {
    const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
    if (!project) throw ApiError.notFound('Project not found');

    const where: any = { projectId };
    if (query.status) where.status = query.status;
    if (query.priority) where.priority = query.priority;

    const { page = 1, limit = 50 } = query;
    const parsedPage = Math.max(1, parseInt(page, 10) || 1);
    const parsedLimit = Math.min(200, Math.max(1, parseInt(limit, 10) || 50));
    const skip = (parsedPage - 1) * parsedLimit;

    const [items, total] = await Promise.all([
      prisma.feature.findMany({
        where,
        orderBy: { order: 'asc' },
        skip,
        take: parsedLimit,
        include: { assignedTask: { select: { id: true, title: true, status: true } } },
      }),
      prisma.feature.count({ where }),
    ]);

    return {
      data: items,
      meta: {
        total,
        page: parsedPage,
        limit: parsedLimit,
        totalPages: Math.ceil(total / parsedLimit),
      },
    };
  }

  async createFeature(userId: string, projectId: string, data: any) {
    const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
    if (!project) throw ApiError.notFound('Project not found');

    return prisma.$transaction(async (tx) => {
      const lastFeature = await tx.feature.findFirst({
        where: { projectId },
        orderBy: { order: 'desc' },
        select: { order: true },
      });
      const order = data.order !== undefined ? Number(data.order) : (lastFeature?.order ?? 0) + 1000;

      const feature = await tx.feature.create({
        data: {
          projectId,
          name: data.name || data.title,
          description: data.description || null,
          status: data.status || 'TODO',
          priority: data.priority || 'MEDIUM',
          order,
          githubIssueNumber: data.githubIssueNumber ? Number(data.githubIssueNumber) : null,
          githubUrl: data.githubUrl || null,
          assignedTaskId: data.assignedTaskId || null,
        },
      });

      await this.computeAndSyncProjectProgress(projectId, tx);
      return feature;
    });
  }

  async updateFeature(userId: string, projectId: string, featureId: string, data: any) {
    const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
    if (!project) throw ApiError.notFound('Project not found');

    const existing = await prisma.feature.findFirst({ where: { id: featureId, projectId } });
    if (!existing) throw ApiError.notFound('Feature not found');

    const updateData: any = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.title !== undefined) updateData.name = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.priority !== undefined) updateData.priority = data.priority;
    if (data.order !== undefined) updateData.order = Number(data.order);
    if (data.githubIssueNumber !== undefined) updateData.githubIssueNumber = data.githubIssueNumber ? Number(data.githubIssueNumber) : null;
    if (data.githubUrl !== undefined) updateData.githubUrl = data.githubUrl;
    if (data.assignedTaskId !== undefined) updateData.assignedTaskId = data.assignedTaskId;

    return prisma.$transaction(async (tx) => {
      const updated = await tx.feature.update({
        where: { id: featureId },
        data: updateData,
      });

      await this.computeAndSyncProjectProgress(projectId, tx);
      return updated;
    });
  }

  async deleteFeature(userId: string, projectId: string, featureId: string) {
    const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
    if (!project) throw ApiError.notFound('Project not found');

    const existing = await prisma.feature.findFirst({ where: { id: featureId, projectId } });
    if (!existing) throw ApiError.notFound('Feature not found');

    return prisma.$transaction(async (tx) => {
      await tx.feature.delete({ where: { id: featureId } });
      await this.computeAndSyncProjectProgress(projectId, tx);
      return true;
    });
  }

  // ==========================================
  // BUGS CRUD
  // ==========================================

  async getBugs(userId: string, projectId: string, query: any = {}) {
    const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
    if (!project) throw ApiError.notFound('Project not found');

    const where: any = { projectId };
    if (query.status) where.status = query.status;
    if (query.priority) where.priority = query.priority;
    if (query.severity) where.severity = query.severity;

    const { page = 1, limit = 50 } = query;
    const parsedPage = Math.max(1, parseInt(page, 10) || 1);
    const parsedLimit = Math.min(200, Math.max(1, parseInt(limit, 10) || 50));
    const skip = (parsedPage - 1) * parsedLimit;

    const [items, total] = await Promise.all([
      prisma.bug.findMany({
        where,
        orderBy: { order: 'asc' },
        skip,
        take: parsedLimit,
      }),
      prisma.bug.count({ where }),
    ]);

    return {
      data: items,
      meta: {
        total,
        page: parsedPage,
        limit: parsedLimit,
        totalPages: Math.ceil(total / parsedLimit),
      },
    };
  }

  async createBug(userId: string, projectId: string, data: any) {
    const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
    if (!project) throw ApiError.notFound('Project not found');

    return prisma.$transaction(async (tx) => {
      const lastBug = await tx.bug.findFirst({
        where: { projectId },
        orderBy: { order: 'desc' },
        select: { order: true },
      });
      const order = data.order !== undefined ? Number(data.order) : (lastBug?.order ?? 0) + 1000;

      const bug = await tx.bug.create({
        data: {
          projectId,
          title: data.title,
          description: data.description || '',
          stepsToReproduce: data.stepsToReproduce || null,
          severity: data.severity || 'MAJOR',
          priority: data.priority || 'MEDIUM',
          status: data.status || 'OPEN',
          order,
          githubIssueNumber: data.githubIssueNumber ? Number(data.githubIssueNumber) : null,
          githubUrl: data.githubUrl || null,
          resolutionNotes: data.resolutionNotes || null,
        },
      });

      await this.computeAndSyncProjectProgress(projectId, tx);
      return bug;
    });
  }

  async updateBug(userId: string, projectId: string, bugId: string, data: any) {
    const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
    if (!project) throw ApiError.notFound('Project not found');

    const existing = await prisma.bug.findFirst({ where: { id: bugId, projectId } });
    if (!existing) throw ApiError.notFound('Bug not found');

    const updateData: any = {};
    if (data.title !== undefined) updateData.title = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.stepsToReproduce !== undefined) updateData.stepsToReproduce = data.stepsToReproduce;
    if (data.severity !== undefined) updateData.severity = data.severity;
    if (data.priority !== undefined) updateData.priority = data.priority;
    if (data.status !== undefined) {
      updateData.status = data.status;
      if ((data.status === 'RESOLVED' || data.status === 'CLOSED') && !existing.resolvedAt) {
        updateData.resolvedAt = new Date();
      } else if (data.status === 'OPEN' || data.status === 'IN_PROGRESS') {
        updateData.resolvedAt = null;
      }
    }
    if (data.order !== undefined) updateData.order = Number(data.order);
    if (data.githubIssueNumber !== undefined) updateData.githubIssueNumber = data.githubIssueNumber ? Number(data.githubIssueNumber) : null;
    if (data.githubUrl !== undefined) updateData.githubUrl = data.githubUrl;
    if (data.resolutionNotes !== undefined) updateData.resolutionNotes = data.resolutionNotes;

    return prisma.$transaction(async (tx) => {
      const updated = await tx.bug.update({
        where: { id: bugId },
        data: updateData,
      });

      await this.computeAndSyncProjectProgress(projectId, tx);
      return updated;
    });
  }

  async deleteBug(userId: string, projectId: string, bugId: string) {
    const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
    if (!project) throw ApiError.notFound('Project not found');

    const existing = await prisma.bug.findFirst({ where: { id: bugId, projectId } });
    if (!existing) throw ApiError.notFound('Bug not found');

    return prisma.$transaction(async (tx) => {
      await tx.bug.delete({ where: { id: bugId } });
      await this.computeAndSyncProjectProgress(projectId, tx);
      return true;
    });
  }

  // ==========================================
  // KANBAN BOARD & FRACTIONAL REORDERING
  // ==========================================

  async getBoard(userId: string, projectId: string) {
    const project = await prisma.project.findFirst({
      where: { id: projectId, userId },
      include: {
        tasks: { orderBy: { order: 'asc' } },
        features: { orderBy: { order: 'asc' } },
        bugs: { orderBy: { order: 'asc' } },
      },
    });

    if (!project) throw ApiError.notFound('Project not found');

    const columns: Record<string, any[]> = {
      TODO: [],
      IN_PROGRESS: [],
      BLOCKED: [],
      COMPLETED: [],
    };

    project.tasks.forEach((t) => {
      let col = 'TODO';
      if (t.isCompleted || t.status === 'COMPLETED' || t.status === 'DONE') col = 'COMPLETED';
      else if (t.status === 'IN_PROGRESS') col = 'IN_PROGRESS';
      else if (t.status === 'BLOCKED') col = 'BLOCKED';

      columns[col].push({
        id: t.id,
        type: 'TASK',
        title: t.title,
        description: t.description,
        status: t.status,
        priority: t.priority,
        order: t.order,
        githubIssueNumber: t.githubIssueNumber,
        isCompleted: t.isCompleted,
        createdAt: t.createdAt,
      });
    });

    project.features.forEach((f) => {
      let col = 'TODO';
      if (f.status === 'COMPLETED' || f.status === 'DONE') col = 'COMPLETED';
      else if (f.status === 'IN_PROGRESS') col = 'IN_PROGRESS';
      else if (f.status === 'BLOCKED') col = 'BLOCKED';

      columns[col].push({
        id: f.id,
        type: 'FEATURE',
        title: f.name,
        description: f.description,
        status: f.status,
        priority: f.priority,
        order: f.order,
        githubIssueNumber: f.githubIssueNumber,
        createdAt: f.createdAt,
      });
    });

    project.bugs.forEach((b) => {
      let col = 'TODO';
      if (b.status === 'RESOLVED' || b.status === 'CLOSED') col = 'COMPLETED';
      else if (b.status === 'IN_PROGRESS') col = 'IN_PROGRESS';

      columns[col].push({
        id: b.id,
        type: 'BUG',
        title: b.title,
        description: b.description,
        status: b.status,
        priority: b.priority,
        severity: b.severity,
        order: b.order,
        githubIssueNumber: b.githubIssueNumber,
        createdAt: b.createdAt,
      });
    });

    Object.keys(columns).forEach((col) => {
      columns[col].sort((a, b) => a.order - b.order);
    });

    return {
      projectId,
      columns,
      totalItems:
        columns.TODO.length +
        columns.IN_PROGRESS.length +
        columns.BLOCKED.length +
        columns.COMPLETED.length,
    };
  }

  /**
   * Moves an item on the board with fractional ordering
   */
  async moveBoardItem(
    userId: string,
    projectId: string,
    payload: {
      entityType: 'TASK' | 'FEATURE' | 'BUG';
      entityId: string;
      targetStatus: 'TODO' | 'IN_PROGRESS' | 'BLOCKED' | 'COMPLETED';
      prevOrder?: number;
      nextOrder?: number;
    }
  ) {
    const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
    if (!project) throw ApiError.notFound('Project not found');

    const { entityType, entityId, targetStatus, prevOrder, nextOrder } = payload;

    return prisma.$transaction(async (tx) => {
      let calculatedOrder: number;
      if (prevOrder !== undefined && nextOrder !== undefined) {
        calculatedOrder = (prevOrder + nextOrder) / 2;
      } else if (nextOrder !== undefined) {
        calculatedOrder = nextOrder > 1000 ? nextOrder - 1000 : nextOrder / 2;
      } else if (prevOrder !== undefined) {
        calculatedOrder = prevOrder + 1000;
      } else {
        calculatedOrder = 1000;
      }

      // Safety: if the precision gap is too small, renormalize the source column
      const MIN_ORDER_GAP = 0.001;
      if (
        prevOrder !== undefined &&
        nextOrder !== undefined &&
        Math.abs(nextOrder - prevOrder) < MIN_ORDER_GAP
      ) {
        // Renormalize the target column after this update
        await this.normalizeColumnOrder(projectId, entityType, targetStatus, tx);
        // After renormalization use a simple append order; the column is clean now
        const last = await this.getLastOrderInColumn(projectId, entityType, targetStatus, tx);
        calculatedOrder = (last ?? 0) + 1000;
      }

      let entityStatus = targetStatus;
      let isCompleted = false;

      if (entityType === 'TASK') {
        if (targetStatus === 'COMPLETED') {
          entityStatus = 'COMPLETED';
          isCompleted = true;
        }
        await tx.task.update({
          where: { id: entityId },
          data: {
            status: entityStatus,
            isCompleted,
            completedAt: isCompleted ? new Date() : null,
            order: calculatedOrder,
          },
        });
      } else if (entityType === 'FEATURE') {
        await tx.feature.update({
          where: { id: entityId },
          data: {
            status: targetStatus,
            order: calculatedOrder,
          },
        });
      } else if (entityType === 'BUG') {
        let bugStatus = 'OPEN';
        let resolvedAt: Date | null = null;
        if (targetStatus === 'COMPLETED') {
          bugStatus = 'RESOLVED';
          resolvedAt = new Date();
        } else if (targetStatus === 'IN_PROGRESS') {
          bugStatus = 'IN_PROGRESS';
        }
        await tx.bug.update({
          where: { id: entityId },
          data: {
            status: bugStatus,
            resolvedAt,
            order: calculatedOrder,
          },
        });
      }

      const progress = await this.computeAndSyncProjectProgress(projectId, tx);

      return {
        success: true,
        entityType,
        entityId,
        newStatus: targetStatus,
        newOrder: calculatedOrder,
        projectProgress: progress.progress,
      };
    });
  }

  /**
   * Resets all order values in a column to clean multiples of 1000.
   * Called lazily when fractional precision degrades below MIN_ORDER_GAP.
   */
  private async normalizeColumnOrder(
    projectId: string,
    entityType: 'TASK' | 'FEATURE' | 'BUG',
    columnStatus: string,
    dbClient: any = prisma
  ): Promise<void> {
    if (entityType === 'TASK') {
      const items = await dbClient.task.findMany({
        where: { projectId, status: columnStatus },
        orderBy: { order: 'asc' },
        select: { id: true },
      });
      for (let i = 0; i < items.length; i++) {
        await dbClient.task.update({
          where: { id: items[i].id },
          data: { order: (i + 1) * 1000 },
        });
      }
    } else if (entityType === 'FEATURE') {
      const items = await dbClient.feature.findMany({
        where: { projectId, status: columnStatus },
        orderBy: { order: 'asc' },
        select: { id: true },
      });
      for (let i = 0; i < items.length; i++) {
        await dbClient.feature.update({
          where: { id: items[i].id },
          data: { order: (i + 1) * 1000 },
        });
      }
    } else if (entityType === 'BUG') {
      // Map board status → bug status values
      const bugStatusMap: Record<string, string[]> = {
        TODO: ['OPEN'],
        IN_PROGRESS: ['IN_PROGRESS'],
        COMPLETED: ['RESOLVED', 'CLOSED'],
        BLOCKED: [],
      };
      const statusFilter = bugStatusMap[columnStatus] ?? [];
      const items = await dbClient.bug.findMany({
        where: { projectId, status: { in: statusFilter } },
        orderBy: { order: 'asc' },
        select: { id: true },
      });
      for (let i = 0; i < items.length; i++) {
        await dbClient.bug.update({
          where: { id: items[i].id },
          data: { order: (i + 1) * 1000 },
        });
      }
    }
  }

  /**
   * Returns the highest order value in a column for appending.
   */
  private async getLastOrderInColumn(
    projectId: string,
    entityType: 'TASK' | 'FEATURE' | 'BUG',
    columnStatus: string,
    dbClient: any = prisma
  ): Promise<number | null> {
    if (entityType === 'TASK') {
      const item = await dbClient.task.findFirst({
        where: { projectId, status: columnStatus },
        orderBy: { order: 'desc' },
        select: { order: true },
      });
      return item?.order ?? null;
    } else if (entityType === 'FEATURE') {
      const item = await dbClient.feature.findFirst({
        where: { projectId, status: columnStatus },
        orderBy: { order: 'desc' },
        select: { order: true },
      });
      return item?.order ?? null;
    } else {
      const item = await dbClient.bug.findFirst({
        where: { projectId },
        orderBy: { order: 'desc' },
        select: { order: true },
      });
      return item?.order ?? null;
    }
  }

  // ==========================================
  // TIME TRACKING & VELOCITY ROLLUP
  // ==========================================

  async getProjectAnalytics(userId: string, projectId: string) {
    const project = await prisma.project.findFirst({
      where: { id: projectId, userId },
      include: {
        tasks: {
          include: {
            focusSessions: {
              where: { userId },
              orderBy: { startTime: 'asc' },
            },
          },
        },
        features: true,
        bugs: true,
      },
    });

    if (!project) throw ApiError.notFound('Project not found');

    let totalFocusMinutes = 0;
    const weeklyBuckets: Record<string, { weekStart: string; focusMinutes: number; tasksCompleted: number; featuresCompleted: number; bugsResolved: number }> = {};

    const now = new Date();
    for (let i = 7; i >= 0; i--) {
      const d = new Date(now.getTime() - i * 7 * 24 * 60 * 60 * 1000);
      const day = d.getDay();
      const diff = d.getDate() - day + (day === 0 ? -6 : 1);
      const monday = new Date(d.setDate(diff));
      const key = monday.toISOString().split('T')[0];
      if (!weeklyBuckets[key]) {
        weeklyBuckets[key] = {
          weekStart: key,
          focusMinutes: 0,
          tasksCompleted: 0,
          featuresCompleted: 0,
          bugsResolved: 0,
        };
      }
    }

    project.tasks.forEach((task) => {
      task.focusSessions.forEach((fs) => {
        totalFocusMinutes += fs.durationMinutes || 0;
        const fsDate = new Date(fs.startTime);
        const day = fsDate.getDay();
        const diff = fsDate.getDate() - day + (day === 0 ? -6 : 1);
        const monday = new Date(fsDate.setDate(diff)).toISOString().split('T')[0];
        if (weeklyBuckets[monday]) {
          weeklyBuckets[monday].focusMinutes += fs.durationMinutes || 0;
        }
      });

      if (task.completedAt) {
        const cDate = new Date(task.completedAt);
        const day = cDate.getDay();
        const diff = cDate.getDate() - day + (day === 0 ? -6 : 1);
        const monday = new Date(cDate.setDate(diff)).toISOString().split('T')[0];
        if (weeklyBuckets[monday]) {
          weeklyBuckets[monday].tasksCompleted += 1;
        }
      }
    });

    project.features.forEach((feature) => {
      if (feature.status === 'COMPLETED') {
        const uDate = new Date(feature.updatedAt);
        const day = uDate.getDay();
        const diff = uDate.getDate() - day + (day === 0 ? -6 : 1);
        const monday = new Date(uDate.setDate(diff)).toISOString().split('T')[0];
        if (weeklyBuckets[monday]) {
          weeklyBuckets[monday].featuresCompleted += 1;
        }
      }
    });

    project.bugs.forEach((bug) => {
      if (bug.resolvedAt) {
        const rDate = new Date(bug.resolvedAt);
        const day = rDate.getDay();
        const diff = rDate.getDate() - day + (day === 0 ? -6 : 1);
        const monday = new Date(rDate.setDate(diff)).toISOString().split('T')[0];
        if (weeklyBuckets[monday]) {
          weeklyBuckets[monday].bugsResolved += 1;
        }
      }
    });

    const weeklyVelocity = Object.values(weeklyBuckets).sort((a, b) => a.weekStart.localeCompare(b.weekStart));
    const health = await this.computeProjectHealth(projectId);
    const progress = await this.computeAndSyncProjectProgress(projectId);

    return {
      projectId,
      totalFocusMinutes,
      totalFocusHours: Number((totalFocusMinutes / 60).toFixed(1)),
      weeklyVelocity,
      health,
      progress,
      technologies: project.technologies,
    };
  }

  // ==========================================
  // TECH STACK INSIGHTS (CROSS-PROJECT)
  // ==========================================

  async getTechStackInsights(userId: string) {
    const projects = await prisma.project.findMany({
      where: { userId },
      include: {
        tasks: {
          include: {
            focusSessions: {
              where: { userId },
              select: { durationMinutes: true },
            },
          },
        },
        features: { select: { id: true, status: true } },
      },
    });

    const techMinutes: Record<string, number> = {};
    const techProjectCounts: Record<string, number> = {};
    let totalAllMinutes = 0;

    projects.forEach((proj) => {
      let projMinutes = 0;
      proj.tasks.forEach((t) => {
        t.focusSessions.forEach((fs) => {
          projMinutes += fs.durationMinutes || 0;
        });
      });
      totalAllMinutes += projMinutes;

      const techs = proj.technologies.length > 0 ? proj.technologies : ['General'];
      techs.forEach((tech) => {
        techMinutes[tech] = (techMinutes[tech] || 0) + projMinutes;
        techProjectCounts[tech] = (techProjectCounts[tech] || 0) + 1;
      });
    });

    const insights = Object.keys(techMinutes).map((tech) => {
      const minutes = techMinutes[tech];
      const percentage = totalAllMinutes > 0 ? Number(((minutes / totalAllMinutes) * 100).toFixed(1)) : 0;
      return {
        technology: tech,
        totalMinutes: minutes,
        totalHours: Number((minutes / 60).toFixed(1)),
        percentage,
        projectsCount: techProjectCounts[tech] || 0,
      };
    });

    insights.sort((a, b) => b.totalMinutes - a.totalMinutes);

    return {
      totalCodingMinutes: totalAllMinutes,
      totalCodingHours: Number((totalAllMinutes / 60).toFixed(1)),
      technologies: insights,
    };
  }

  // ==========================================
  // GITHUB COMMITS FETCHER (LIGHTWEIGHT REST)
  // ==========================================

  async getProjectCommits(userId: string, projectId: string) {
    const project = await prisma.project.findFirst({
      where: { id: projectId, userId },
    });

    if (!project) throw ApiError.notFound('Project not found');

    if (!project.repoUrl) {
      return {
        repoUrl: null,
        commits: [],
        errorCode: 'NO_REPO_URL' as const,
        message: 'No GitHub repository URL configured for this project',
      };
    }

    const match = project.repoUrl.match(/github\.com\/([^\/]+)\/([^\/]+)/);
    if (!match) {
      return {
        repoUrl: project.repoUrl,
        commits: [],
        errorCode: 'INVALID_REPO_URL' as const,
        message: 'Repository URL does not match expected GitHub format (https://github.com/owner/repo)',
      };
    }

    const owner = match[1];
    const repo = match[2].replace(/\.git$/, '');

    try {
      const githubToken = process.env.GITHUB_TOKEN;
      const headers: Record<string, string> = {
        'User-Agent': 'HabOS-Developer-Hub/1.0',
        Accept: 'application/vnd.github.v3+json',
      };
      if (githubToken) {
        headers['Authorization'] = `token ${githubToken}`;
      }

      const res = await fetch(`https://api.github.com/repos/${owner}/${repo}/commits?per_page=15`, {
        headers,
      });

      if (!res.ok) {
        // Surface rate-limit specifics to the client without fake data
        const errorCode = res.status === 403 || res.status === 429
          ? 'GITHUB_RATE_LIMITED'
          : 'GITHUB_API_ERROR';
        return {
          owner,
          repo,
          repoUrl: project.repoUrl,
          commits: [],
          errorCode: errorCode as 'GITHUB_RATE_LIMITED' | 'GITHUB_API_ERROR',
          message: `Unable to sync remote commits (GitHub API ${res.status})`,
        };
      }

      const data: any = await res.json();
      if (!Array.isArray(data)) {
        return {
          owner,
          repo,
          repoUrl: project.repoUrl,
          commits: [],
          errorCode: 'GITHUB_UNEXPECTED_RESPONSE' as const,
          message: 'Unable to sync remote commits (unexpected response format)',
        };
      }

      const commits = data.map((c: any) => ({
        sha: c.sha.substring(0, 7),
        fullSha: c.sha,
        message: c.commit.message,
        author: c.commit.author?.name || c.author?.login || 'Unknown',
        date: c.commit.author?.date || c.commit.committer?.date,
        url: c.html_url,
      }));

      return {
        owner,
        repo,
        repoUrl: project.repoUrl,
        commits,
      };
    } catch (err: any) {
      return {
        owner,
        repo,
        repoUrl: project.repoUrl,
        commits: [],
        errorCode: 'GITHUB_NETWORK_ERROR' as const,
        message: 'Unable to sync remote commits (network unreachable)',
      };
    }
  }

  // ==========================================
  // GITHUB WEBHOOKS & ISSUE AUTOMATION
  // ==========================================

  verifyWebhookSignature(
    payloadBuffer: Buffer | string,
    signatureHeader?: string,
    secret?: string
  ): boolean {
    if (!signatureHeader || !secret) {
      return false;
    }
    try {
      const hmac = crypto.createHmac('sha256', secret);
      const computed = 'sha256=' + hmac.update(payloadBuffer).digest('hex');
      const sigBuf = Buffer.from(signatureHeader);
      const compBuf = Buffer.from(computed);
      if (sigBuf.length !== compBuf.length) {
        return false;
      }
      return crypto.timingSafeEqual(sigBuf, compBuf);
    } catch {
      return false;
    }
  }

  async getProjectWebhookConfig(userId: string, projectId: string) {
    const project = await prisma.project.findFirst({
      where: { id: projectId, userId },
      select: { id: true, webhookSecret: true, repoUrl: true },
    });
    if (!project) throw ApiError.notFound('Project not found');

    const baseUrl = process.env.WEBHOOK_BASE_URL || process.env.BASE_URL || 'http://localhost:5000';
    const webhookUrl = `${baseUrl}/api/v1/projects/${projectId}/webhooks/github`;

    return {
      projectId,
      webhookUrl,
      hasSecret: !!project.webhookSecret,
      repoUrl: project.repoUrl,
    };
  }

  async generateProjectWebhookSecret(userId: string, projectId: string) {
    const project = await prisma.project.findFirst({
      where: { id: projectId, userId },
    });
    if (!project) throw ApiError.notFound('Project not found');

    const secret = crypto.randomBytes(24).toString('hex');
    await prisma.project.update({
      where: { id: projectId },
      data: { webhookSecret: secret },
    });

    const baseUrl = process.env.WEBHOOK_BASE_URL || process.env.BASE_URL || 'http://localhost:5000';
    const webhookUrl = `${baseUrl}/api/v1/projects/${projectId}/webhooks/github`;

    return {
      projectId,
      webhookSecret: secret,
      webhookUrl,
      message: 'Webhook secret generated. Configure this secret in your GitHub repository webhook settings.',
    };
  }

  async handleProjectGithubWebhook(
    projectId: string,
    event: string,
    payload: any,
    rawBody?: Buffer,
    signatureHeader?: string
  ) {
    const project = await prisma.project.findUnique({
      where: { id: projectId },
    });
    if (!project) throw ApiError.notFound('Project not found');

    const effectiveSecret = project.webhookSecret || process.env.GITHUB_WEBHOOK_SECRET;
    if (effectiveSecret) {
      const bodyToVerify = rawBody || Buffer.from(JSON.stringify(payload));
      const isValid = this.verifyWebhookSignature(bodyToVerify, signatureHeader, effectiveSecret);
      if (!isValid) {
        throw ApiError.unauthorized('Invalid GitHub webhook HMAC signature');
      }
    }

    const processedEvents: string[] = [];
    const repoFullName = payload.repository?.full_name || 'unknown';

    const result = await prisma.$transaction(async (tx) => {
      // 1. Push Event (scan commit messages for fixes/closes/resolves #num)
      if (event === 'push' && Array.isArray(payload.commits)) {
        for (const commit of payload.commits) {
          const message = commit.message || '';
          const issueMatches = [...message.matchAll(/(?:fixes|closes|resolves)\s+#(\d+)/gi)];
          for (const match of issueMatches) {
            const issueNum = parseInt(match[1], 10);

            // Complete task
            const tasks = await tx.task.findMany({
              where: { projectId: project.id, githubIssueNumber: issueNum, isCompleted: false },
            });
            for (const t of tasks) {
              await tx.task.update({
                where: { id: t.id },
                data: { status: 'COMPLETED', isCompleted: true, completedAt: new Date() },
              });
              processedEvents.push(`Task ${t.title} completed via commit ${commit.id.substring(0, 7)}`);
            }

            // Complete feature
            const features = await tx.feature.findMany({
              where: { projectId: project.id, githubIssueNumber: issueNum, status: { not: 'COMPLETED' } },
            });
            for (const f of features) {
              await tx.feature.update({
                where: { id: f.id },
                data: { status: 'COMPLETED' },
              });
              processedEvents.push(`Feature ${f.name} completed via commit ${commit.id.substring(0, 7)}`);
            }

            // Resolve bug
            const bugs = await tx.bug.findMany({
              where: {
                projectId: project.id,
                githubIssueNumber: issueNum,
                status: { notIn: ['RESOLVED', 'CLOSED'] },
              },
            });
            for (const b of bugs) {
              await tx.bug.update({
                where: { id: b.id },
                data: { status: 'RESOLVED', resolvedAt: new Date() },
              });
              processedEvents.push(`Bug ${b.title} resolved via commit ${commit.id.substring(0, 7)}`);
            }
          }
        }
      }

      // 2. Pull Request Event (merged PR closes linked items)
      if (event === 'pull_request') {
        const pr = payload.pull_request;
        const action = payload.action;

        if (action === 'closed' && pr?.merged) {
          const prNumber = pr.number;
          const links = await tx.githubLink.findMany({
            where: { projectId: project.id, issueOrPrNumber: prNumber },
          });

          for (const link of links) {
            if (link.entityType === 'TASK') {
              await tx.task.update({
                where: { id: link.entityId },
                data: { status: 'COMPLETED', isCompleted: true, completedAt: new Date() },
              });
            } else if (link.entityType === 'FEATURE') {
              await tx.feature.update({
                where: { id: link.entityId },
                data: { status: 'COMPLETED' },
              });
            } else if (link.entityType === 'BUG') {
              await tx.bug.update({
                where: { id: link.entityId },
                data: { status: 'RESOLVED', resolvedAt: new Date() },
              });
            }
            processedEvents.push(`PR #${prNumber} merged: closed ${link.entityType} ${link.entityId}`);
          }

          // Also check for issue closing references in PR body/title
          const prText = `${pr.title || ''} ${pr.body || ''}`;
          const matches = [...prText.matchAll(/(?:fixes|closes|resolves)\s+#(\d+)/gi)];
          for (const match of matches) {
            const issueNum = parseInt(match[1], 10);
            await tx.task.updateMany({
              where: { projectId: project.id, githubIssueNumber: issueNum },
              data: { status: 'COMPLETED', isCompleted: true, completedAt: new Date() },
            });
            await tx.feature.updateMany({
              where: { projectId: project.id, githubIssueNumber: issueNum },
              data: { status: 'COMPLETED' },
            });
            await tx.bug.updateMany({
              where: { projectId: project.id, githubIssueNumber: issueNum },
              data: { status: 'RESOLVED', resolvedAt: new Date() },
            });
            processedEvents.push(`PR #${prNumber} resolved linked issue #${issueNum}`);
          }
        }
      }

      // 3. Issues Event (auto-import and auto-status)
      if (event === 'issues') {
        const issue = payload.issue;
        const action = payload.action;

        if (action === 'opened' && issue) {
          const isBug = issue.labels?.some((l: any) =>
            l.name?.toLowerCase().includes('bug')
          );
          if (isBug) {
            const lastBug = await tx.bug.findFirst({
              where: { projectId: project.id },
              orderBy: { order: 'desc' },
              select: { order: true },
            });
            const bug = await tx.bug.create({
              data: {
                projectId: project.id,
                title: issue.title,
                description: issue.body || 'Issue imported via GitHub webhook',
                severity: 'MAJOR',
                priority: 'MEDIUM',
                status: 'OPEN',
                order: (lastBug?.order ?? 0) + 1000,
                githubIssueNumber: issue.number,
                githubUrl: issue.html_url,
              },
            });
            await tx.githubLink.upsert({
              where: {
                repoFullName_issueOrPrNumber_entityType_entityId: {
                  repoFullName,
                  issueOrPrNumber: issue.number,
                  entityType: 'BUG',
                  entityId: bug.id,
                },
              },
              update: {},
              create: {
                projectId: project.id,
                repoFullName,
                issueOrPrNumber: issue.number,
                entityType: 'BUG',
                entityId: bug.id,
              },
            });
            processedEvents.push(`Created bug for GitHub issue #${issue.number}`);
          } else {
            const lastFeature = await tx.feature.findFirst({
              where: { projectId: project.id },
              orderBy: { order: 'desc' },
              select: { order: true },
            });
            const feature = await tx.feature.create({
              data: {
                projectId: project.id,
                name: issue.title,
                description: issue.body || 'Feature imported via GitHub webhook',
                status: 'TODO',
                priority: 'MEDIUM',
                order: (lastFeature?.order ?? 0) + 1000,
                githubIssueNumber: issue.number,
                githubUrl: issue.html_url,
              },
            });
            await tx.githubLink.upsert({
              where: {
                repoFullName_issueOrPrNumber_entityType_entityId: {
                  repoFullName,
                  issueOrPrNumber: issue.number,
                  entityType: 'FEATURE',
                  entityId: feature.id,
                },
              },
              update: {},
              create: {
                projectId: project.id,
                repoFullName,
                issueOrPrNumber: issue.number,
                entityType: 'FEATURE',
                entityId: feature.id,
              },
            });
            processedEvents.push(`Created feature for GitHub issue #${issue.number}`);
          }
        } else if (action === 'closed' && issue) {
          await tx.bug.updateMany({
            where: { projectId: project.id, githubIssueNumber: issue.number },
            data: { status: 'RESOLVED', resolvedAt: new Date() },
          });
          await tx.feature.updateMany({
            where: { projectId: project.id, githubIssueNumber: issue.number },
            data: { status: 'COMPLETED' },
          });
          processedEvents.push(`Closed issue #${issue.number}`);
        } else if (action === 'reopened' && issue) {
          await tx.bug.updateMany({
            where: { projectId: project.id, githubIssueNumber: issue.number },
            data: { status: 'OPEN', resolvedAt: null },
          });
          await tx.feature.updateMany({
            where: { projectId: project.id, githubIssueNumber: issue.number },
            data: { status: 'TODO' },
          });
          processedEvents.push(`Reopened issue #${issue.number}`);
        }
      }

      // Recalculate auto progress within the same transaction
      const progress = await this.computeAndSyncProjectProgress(project.id, tx);

      return {
        handled: true,
        event,
        projectId: project.id,
        processedEvents,
        updatedProgress: progress.progress,
      };
    });

    // Broadcast real-time project:updated event to connected clients
    projectEventBus.emitProjectUpdate(projectId, {
      type: 'GITHUB_WEBHOOK',
      event,
      details: result,
    });

    return result;
  }

  // ==========================================
  // GITHUB ENTITY LINKS CRUD
  // ==========================================

  async getProjectGithubLinks(userId: string, projectId: string) {
    const project = await prisma.project.findFirst({
      where: { id: projectId, userId },
    });
    if (!project) throw ApiError.notFound('Project not found');

    return prisma.githubLink.findMany({
      where: { projectId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async linkGithubEntity(
    userId: string,
    projectId: string,
    data: {
      entityType: 'TASK' | 'FEATURE' | 'BUG';
      entityId: string;
      issueOrPrNumber: number;
      repoFullName: string;
    }
  ) {
    const project = await prisma.project.findFirst({
      where: { id: projectId, userId },
    });
    if (!project) throw ApiError.notFound('Project not found');

    const link = await prisma.githubLink.upsert({
      where: {
        repoFullName_issueOrPrNumber_entityType_entityId: {
          repoFullName: data.repoFullName,
          issueOrPrNumber: Number(data.issueOrPrNumber),
          entityType: data.entityType,
          entityId: data.entityId,
        },
      },
      update: {},
      create: {
        projectId,
        repoFullName: data.repoFullName,
        issueOrPrNumber: Number(data.issueOrPrNumber),
        entityType: data.entityType,
        entityId: data.entityId,
      },
    });

    // Also update githubIssueNumber on the entity itself
    if (data.entityType === 'TASK') {
      await prisma.task.update({
        where: { id: data.entityId },
        data: { githubIssueNumber: Number(data.issueOrPrNumber) },
      });
    } else if (data.entityType === 'FEATURE') {
      await prisma.feature.update({
        where: { id: data.entityId },
        data: { githubIssueNumber: Number(data.issueOrPrNumber) },
      });
    } else if (data.entityType === 'BUG') {
      await prisma.bug.update({
        where: { id: data.entityId },
        data: { githubIssueNumber: Number(data.issueOrPrNumber) },
      });
    }

    return link;
  }

  async unlinkGithubEntity(userId: string, projectId: string, linkId: string) {
    const project = await prisma.project.findFirst({
      where: { id: projectId, userId },
    });
    if (!project) throw ApiError.notFound('Project not found');

    const link = await prisma.githubLink.findFirst({
      where: { id: linkId, projectId },
    });
    if (!link) throw ApiError.notFound('GitHub link not found');

    await prisma.githubLink.delete({ where: { id: linkId } });
    return true;
  }
}

const projectsServiceInstance = new ProjectsService();

export const createProject = projectsServiceInstance.createProject.bind(projectsServiceInstance);
export const getProjects = projectsServiceInstance.getProjects.bind(projectsServiceInstance);
export const getProjectById = projectsServiceInstance.getProjectById.bind(projectsServiceInstance);
export const updateProject = projectsServiceInstance.updateProject.bind(projectsServiceInstance);
export const deleteProject = projectsServiceInstance.deleteProject.bind(projectsServiceInstance);
export const createFeature = projectsServiceInstance.createFeature.bind(projectsServiceInstance);
export const updateFeature = projectsServiceInstance.updateFeature.bind(projectsServiceInstance);
export const deleteFeature = projectsServiceInstance.deleteFeature.bind(projectsServiceInstance);
export const createBug = projectsServiceInstance.createBug.bind(projectsServiceInstance);
export const updateBug = projectsServiceInstance.updateBug.bind(projectsServiceInstance);
export const deleteBug = projectsServiceInstance.deleteBug.bind(projectsServiceInstance);
export const computeAndSyncProjectProgress = projectsServiceInstance.computeAndSyncProjectProgress.bind(projectsServiceInstance);
export const updateProjectProgressFromComponents = computeAndSyncProjectProgress;

export default projectsServiceInstance;
