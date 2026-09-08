import prisma from '../../config/db';

export interface GlobalSearchQuery {
  q: string;
  domain?: 'ALL' | 'TASKS' | 'PROJECTS' | 'COURSES' | 'VAULT' | 'HABITS' | 'GOALS' | 'GYM' | 'FINANCE';
  limit?: number;
}

export interface SearchResultItem {
  id: string;
  type: 'TASK' | 'PROJECT' | 'COURSE' | 'ASSIGNMENT' | 'NOTE' | 'HABIT' | 'GOAL' | 'WORKOUT' | 'TRANSACTION';
  title: string;
  subtitle?: string | null;
  route: string;
  details?: Record<string, unknown>;
}

/**
 * UC-167, UC-168: Global Omni-Search across all 24 domains
 */
export const searchGlobal = async (userId: string, query: GlobalSearchQuery) => {
  const { q, domain = 'ALL', limit = 10 } = query;
  const search = q.trim();

  const searchTasks = domain === 'ALL' || domain === 'TASKS';
  const searchProjects = domain === 'ALL' || domain === 'PROJECTS';
  const searchCourses = domain === 'ALL' || domain === 'COURSES';
  const searchVault = domain === 'ALL' || domain === 'VAULT';
  const searchHabits = domain === 'ALL' || domain === 'HABITS';
  const searchGoals = domain === 'ALL' || domain === 'GOALS';
  const searchGym = domain === 'ALL' || domain === 'GYM';
  const searchFinance = domain === 'ALL' || domain === 'FINANCE';

  const [
    tasks,
    projects,
    courses,
    assignments,
    notes,
    habits,
    goals,
    workouts,
    transactions,
  ] = await Promise.all([
    searchTasks
      ? prisma.task.findMany({
          where: {
            userId,
            OR: [
              { title: { contains: search, mode: 'insensitive' } },
              { description: { contains: search, mode: 'insensitive' } },
            ],
          },
          take: limit,
          select: { id: true, title: true, priority: true, status: true, dueDate: true },
        })
      : [],
    searchProjects
      ? prisma.project.findMany({
          where: {
            userId,
            OR: [
              { title: { contains: search, mode: 'insensitive' } },
              { description: { contains: search, mode: 'insensitive' } },
            ],
          },
          take: limit,
          select: { id: true, title: true, status: true, progress: true },
        })
      : [],
    searchCourses
      ? prisma.course.findMany({
          where: {
            userId,
            OR: [
              { name: { contains: search, mode: 'insensitive' } },
              { code: { contains: search, mode: 'insensitive' } },
            ],
          },
          take: limit,
          select: { id: true, name: true, code: true, semester: true },
        })
      : [],
    searchCourses
      ? prisma.assignment.findMany({
          where: {
            course: { userId },
            OR: [
              { title: { contains: search, mode: 'insensitive' } },
              { description: { contains: search, mode: 'insensitive' } },
            ],
          },
          take: limit,
          include: { course: { select: { name: true } } },
        })
      : [],
    searchVault
      ? prisma.vaultNote.findMany({
          where: {
            userId,
            OR: [
              { title: { contains: search, mode: 'insensitive' } },
              { content: { contains: search, mode: 'insensitive' } },
            ],
          },
          take: limit,
          select: { id: true, title: true, tags: true },
        })
      : [],
    searchHabits
      ? prisma.habit.findMany({
          where: {
            userId,
            name: { contains: search, mode: 'insensitive' },
          },
          take: limit,
          select: { id: true, name: true, currentStreak: true },
        })
      : [],
    searchGoals
      ? prisma.goal.findMany({
          where: {
            userId,
            OR: [
              { title: { contains: search, mode: 'insensitive' } },
              { description: { contains: search, mode: 'insensitive' } },
            ],
          },
          take: limit,
          select: { id: true, title: true, progress: true, category: true },
        })
      : [],
    searchGym
      ? prisma.workout.findMany({
          where: {
            userId,
            name: { contains: search, mode: 'insensitive' },
          },
          take: limit,
          select: { id: true, name: true, date: true },
        })
      : [],
    searchFinance
      ? prisma.transaction.findMany({
          where: {
            userId,
            OR: [
              { description: { contains: search, mode: 'insensitive' } },
              { source: { contains: search, mode: 'insensitive' } },
            ],
          },
          take: limit,
          select: { id: true, description: true, amount: true, type: true },
        })
      : [],
  ]);

  const results: SearchResultItem[] = [];

  tasks.forEach((t) => {
    results.push({
      id: t.id,
      type: 'TASK',
      title: t.title,
      subtitle: `Status: ${t.status} • Priority: ${t.priority}`,
      route: `/tasks/${t.id}`,
      details: { dueDate: t.dueDate },
    });
  });

  projects.forEach((p) => {
    results.push({
      id: p.id,
      type: 'PROJECT',
      title: p.title,
      subtitle: `Progress: ${p.progress}% • Status: ${p.status}`,
      route: `/projects/${p.id}`,
    });
  });

  courses.forEach((c) => {
    results.push({
      id: c.id,
      type: 'COURSE',
      title: c.name,
      subtitle: `${c.code || ''} • ${c.semester}`,
      route: `/courses/${c.id}`,
    });
  });

  assignments.forEach((a) => {
    results.push({
      id: a.id,
      type: 'ASSIGNMENT',
      title: a.title,
      subtitle: `Course: ${a.course.name} • Due: ${new Date(a.dueDate).toLocaleDateString()}`,
      route: `/courses/${a.courseId}/assignments/${a.id}`,
    });
  });

  notes.forEach((n) => {
    results.push({
      id: n.id,
      type: 'NOTE',
      title: n.title,
      subtitle: n.tags.length > 0 ? `Tags: ${n.tags.join(', ')}` : 'Knowledge Note',
      route: `/vault/${n.id}`,
    });
  });

  habits.forEach((h) => {
    results.push({
      id: h.id,
      type: 'HABIT',
      title: h.name,
      subtitle: `Current Streak: ${h.currentStreak} days`,
      route: `/habits/${h.id}`,
    });
  });

  goals.forEach((g) => {
    results.push({
      id: g.id,
      type: 'GOAL',
      title: g.title,
      subtitle: `Progress: ${g.progress}% • Category: ${g.category}`,
      route: `/goals/${g.id}`,
    });
  });

  workouts.forEach((w) => {
    results.push({
      id: w.id,
      type: 'WORKOUT',
      title: w.name,
      subtitle: `Date: ${new Date(w.date).toLocaleDateString()}`,
      route: `/gym/${w.id}`,
    });
  });

  transactions.forEach((tx) => {
    results.push({
      id: tx.id,
      type: 'TRANSACTION',
      title: tx.description || 'Transaction',
      subtitle: `${tx.type === 'INCOME' ? '+' : '-'}\$${tx.amount.toFixed(2)} (${tx.type})`,
      route: `/finance/transactions/${tx.id}`,
    });
  });

  return {
    query: search,
    domain,
    totalResults: results.length,
    results,
  };
};

export default {
  searchGlobal,
};
