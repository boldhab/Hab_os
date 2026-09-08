import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';

export interface CreateProjectDTO {
  title: string;
  description?: string | null;
  repoUrl?: string | null;
  status?: string;
  progress?: number;
  technologies?: string[];
  color?: string;
}

export interface UpdateProjectDTO {
  title?: string;
  description?: string | null;
  repoUrl?: string | null;
  status?: string;
  progress?: number;
  technologies?: string[];
  color?: string;
}

export interface CreateFeatureDTO {
  name: string;
  description?: string | null;
  status?: string;
  priority?: string;
  assignedTaskId?: string | null;
}

export interface UpdateFeatureDTO {
  name?: string;
  description?: string | null;
  status?: string;
  priority?: string;
  assignedTaskId?: string | null;
}

export interface CreateBugDTO {
  title: string;
  description: string;
  stepsToReproduce?: string | null;
  priority?: string;
  status?: string;
}

export interface UpdateBugDTO {
  title?: string;
  description?: string;
  stepsToReproduce?: string | null;
  priority?: string;
  status?: string;
  resolutionNotes?: string | null;
}

/**
 * Auto-recalculate project progress from features & tasks (UC-42, UC-47)
 */
export const updateProjectProgressFromComponents = async (projectId: string) => {
  const [totalFeatures, completedFeatures, totalTasks, completedTasks] = await Promise.all([
    prisma.feature.count({ where: { projectId } }),
    prisma.feature.count({ where: { projectId, status: 'COMPLETED' } }),
    prisma.task.count({ where: { projectId } }),
    prisma.task.count({ where: { projectId, isCompleted: true } }),
  ]);

  const totalItems = totalFeatures + totalTasks;
  if (totalItems === 0) return 0;

  const completedItems = completedFeatures + completedTasks;
  const progress = Number(((completedItems / totalItems) * 100).toFixed(1));

  await prisma.project.update({
    where: { id: projectId },
    data: { progress },
  });

  return progress;
};

// ==========================================
// 1. PROJECTS (UC-38 to UC-42)
// ==========================================

export const createProject = async (userId: string, data: CreateProjectDTO) => {
  const project = await prisma.project.create({
    data: {
      title: data.title,
      description: data.description,
      repoUrl: data.repoUrl,
      status: data.status || 'PLANNING',
      progress: data.progress || 0.0,
      technologies: data.technologies || [],
      color: data.color || '#10B981',
      userId,
    },
  });

  invalidateDashboardCache(userId);

  return project;
};

export const getProjects = async (userId: string, status?: string, page?: number, limit?: number) => {
  const where = {
    userId,
    ...(status ? { status } : {}),
  };

  const total = await prisma.project.count({ where });

  let skip: number | undefined;
  let take: number | undefined;
  if (page && limit && limit > 0) {
    skip = (page - 1) * limit;
    take = limit;
  }

  const projects = await prisma.project.findMany({
    where,
    skip,
    take,
    orderBy: [{ progress: 'asc' }, { updatedAt: 'desc' }],
    include: {
      _count: {
        select: {
          features: true,
          bugs: true,
          tasks: true,
        },
      },
    },
  });

  return {
    data: projects,
    meta: {
      total,
      page: page || 1,
      limit: limit || total,
      totalPages: limit && limit > 0 ? Math.ceil(total / limit) : 1,
    },
  };
};

export const getProjectById = async (userId: string, projectId: string) => {
  const project = await prisma.project.findFirst({
    where: { id: projectId, userId },
    include: {
      features: { orderBy: [{ status: 'asc' }, { priority: 'desc' }] },
      bugs: { orderBy: [{ status: 'asc' }, { priority: 'desc' }] },
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

  if (!project) {
    throw new ApiError(404, 'Project not found');
  }

  return project;
};

export const updateProject = async (userId: string, projectId: string, data: UpdateProjectDTO) => {
  const existingProject = await prisma.project.findFirst({
    where: { id: projectId, userId },
  });

  if (!existingProject) {
    throw new ApiError(404, 'Project not found');
  }

  const updatedProject = await prisma.project.update({
    where: { id: projectId },
    data,
  });

  invalidateDashboardCache(userId);

  return updatedProject;
};

export const deleteProject = async (userId: string, projectId: string) => {
  const project = await prisma.project.findFirst({
    where: { id: projectId, userId },
  });

  if (!project) {
    throw new ApiError(404, 'Project not found');
  }

  await prisma.project.delete({ where: { id: projectId } });

  invalidateDashboardCache(userId);

  return { message: 'Project deleted successfully' };
};

// ==========================================
// 2. FEATURES (UC-43 to UC-47)
// ==========================================

export const createFeature = async (userId: string, projectId: string, data: CreateFeatureDTO) => {
  const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
  if (!project) throw new ApiError(404, 'Project not found');

  const feature = await prisma.feature.create({
    data: {
      name: data.name,
      description: data.description,
      status: data.status || 'TODO',
      priority: data.priority || 'MEDIUM',
      assignedTaskId: data.assignedTaskId,
      projectId,
    },
  });

  await updateProjectProgressFromComponents(projectId);
  return feature;
};

export const updateFeature = async (
  userId: string,
  projectId: string,
  featureId: string,
  data: UpdateFeatureDTO
) => {
  const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
  if (!project) throw new ApiError(404, 'Project not found');

  const feature = await prisma.feature.findFirst({
    where: { id: featureId, projectId },
  });
  if (!feature) throw new ApiError(404, 'Feature not found');

  const updatedFeature = await prisma.feature.update({
    where: { id: featureId },
    data,
  });

  if (data.status !== undefined) {
    await updateProjectProgressFromComponents(projectId);
  }

  return updatedFeature;
};

export const deleteFeature = async (userId: string, projectId: string, featureId: string) => {
  const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
  if (!project) throw new ApiError(404, 'Project not found');

  const feature = await prisma.feature.findFirst({
    where: { id: featureId, projectId },
  });
  if (!feature) throw new ApiError(404, 'Feature not found');

  await prisma.feature.delete({ where: { id: featureId } });
  await updateProjectProgressFromComponents(projectId);

  return { message: 'Feature deleted successfully' };
};

// ==========================================
// 3. BUGS (UC-48 to UC-52)
// ==========================================

export const createBug = async (userId: string, projectId: string, data: CreateBugDTO) => {
  const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
  if (!project) throw new ApiError(404, 'Project not found');

  const bug = await prisma.bug.create({
    data: {
      title: data.title,
      description: data.description,
      stepsToReproduce: data.stepsToReproduce,
      priority: data.priority || 'MEDIUM',
      status: data.status || 'OPEN',
      projectId,
    },
  });

  return bug;
};

export const updateBug = async (
  userId: string,
  projectId: string,
  bugId: string,
  data: UpdateBugDTO
) => {
  const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
  if (!project) throw new ApiError(404, 'Project not found');

  const bug = await prisma.bug.findFirst({
    where: { id: bugId, projectId },
  });
  if (!bug) throw new ApiError(404, 'Bug not found');

  const isResolved = data.status === 'RESOLVED' || data.status === 'CLOSED';
  const resolvedAt = isResolved ? (bug.resolvedAt || new Date()) : null;

  const updatedBug = await prisma.bug.update({
    where: { id: bugId },
    data: {
      ...data,
      resolvedAt,
    },
  });

  return updatedBug;
};

export const deleteBug = async (userId: string, projectId: string, bugId: string) => {
  const project = await prisma.project.findFirst({ where: { id: projectId, userId } });
  if (!project) throw new ApiError(404, 'Project not found');

  const bug = await prisma.bug.findFirst({
    where: { id: bugId, projectId },
  });
  if (!bug) throw new ApiError(404, 'Bug not found');

  await prisma.bug.delete({ where: { id: bugId } });
  return { message: 'Bug removed successfully' };
};

export default {
  createProject,
  getProjects,
  getProjectById,
  updateProject,
  deleteProject,
  createFeature,
  updateFeature,
  deleteFeature,
  createBug,
  updateBug,
  deleteBug,
  updateProjectProgressFromComponents,
};
