import prisma from '../../config/db';

export interface AskAiDTO {
  prompt: string;
  contextScope?: 'ALL' | 'TASKS' | 'HABITS' | 'STUDY' | 'DEV' | 'GYM' | 'FINANCE';
}

/**
 * Gather rich domain context across all life areas for personalized AI generation
 */
export const gatherLifeContext = async (userId: string) => {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);

  const [
    user,
    pendingTasks,
    habits,
    todayFocus,
    upcomingAssignments,
    upcomingExams,
    todayWorkouts,
    monthExpenses,
    monthIncome,
  ] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      include: { preferences: true },
    }),
    prisma.task.findMany({
      where: {
        userId,
        isCompleted: false,
        OR: [
          { dueDate: { lte: endOfToday } },
          { priority: { in: ['HIGH', 'CRITICAL'] } },
        ],
      },
      orderBy: [{ priority: 'desc' }, { dueDate: 'asc' }],
      take: 5,
    }),
    prisma.habit.findMany({
      where: { userId, isActive: true },
      include: {
        logs: {
          where: { date: { gte: startOfToday, lte: endOfToday } },
          take: 1,
        },
      },
    }),
    prisma.focusSession.findMany({
      where: { userId, startTime: { gte: startOfToday, lte: endOfToday } },
    }),
    prisma.assignment.findMany({
      where: {
        course: { userId },
        dueDate: { gte: now },
        status: { notIn: ['SUBMITTED', 'GRADED'] },
      },
      orderBy: { dueDate: 'asc' },
      take: 3,
      include: { course: { select: { name: true } } },
    }),
    prisma.exam.findMany({
      where: {
        course: { userId },
        examDate: { gte: now },
      },
      orderBy: { examDate: 'asc' },
      take: 2,
      include: { course: { select: { name: true } } },
    }),
    prisma.workout.findMany({
      where: { userId, date: { gte: startOfToday, lte: endOfToday } },
    }),
    prisma.transaction.aggregate({
      where: { userId, type: 'EXPENSE', date: { gte: startOfMonth } },
      _sum: { amount: true },
    }),
    prisma.transaction.aggregate({
      where: { userId, type: 'INCOME', date: { gte: startOfMonth } },
      _sum: { amount: true },
    }),
  ]);

  const completedHabitsCount = habits.filter((h) => h.logs.length > 0 && h.logs[0].isCompleted).length;
  const pendingHabits = habits.filter((h) => h.logs.length === 0 || !h.logs[0].isCompleted);
  const totalFocusMins = todayFocus.reduce((sum, f) => sum + f.durationMinutes, 0);

  return {
    user: {
      name: user?.name,
      dailyCodingTargetMins: user?.preferences?.dailyCodingTargetMins || 120,
      weeklyGymTarget: user?.preferences?.weeklyGymTarget || 4,
    },
    productivity: {
      pendingTasksCount: pendingTasks.length,
      urgentTasks: pendingTasks.map((t) => ({ id: t.id, title: t.title, priority: t.priority, dueDate: t.dueDate })),
      focusMinutesToday: totalFocusMins,
    },
    habits: {
      totalActive: habits.length,
      completedToday: completedHabitsCount,
      pendingHabits: pendingHabits.map((h) => ({ id: h.id, name: h.name, currentStreak: h.currentStreak })),
    },
    academics: {
      upcomingAssignments: upcomingAssignments.map((a) => ({
        title: a.title,
        course: a.course.name,
        dueDate: a.dueDate,
      })),
      upcomingExams: upcomingExams.map((e) => ({
        title: e.title,
        course: e.course.name,
        examDate: e.examDate,
      })),
    },
    fitness: {
      workedOutToday: todayWorkouts.length > 0,
    },
    finance: {
      spentThisMonth: monthExpenses._sum.amount || 0,
      incomeThisMonth: monthIncome._sum.amount || 0,
    },
  };
};

/**
 * UC-148: Generate Personalized Daily Briefing
 */
export const generateDailyBriefing = async (userId: string) => {
  const ctx = await gatherLifeContext(userId);
  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

  const highlights: string[] = [];

  // Urgent tasks highlight
  if (ctx.productivity.urgentTasks.length > 0) {
    highlights.push(
      `You have ${ctx.productivity.urgentTasks.length} high-priority tasks requiring attention, starting with "${ctx.productivity.urgentTasks[0].title}".`
    );
  } else {
    highlights.push('Your high-priority task queue is clean today!');
  }

  // Habits highlight
  if (ctx.habits.pendingHabits.length > 0) {
    const topStreakHabit = [...ctx.habits.pendingHabits].sort((a, b) => b.currentStreak - a.currentStreak)[0];
    if (topStreakHabit && topStreakHabit.currentStreak > 0) {
      highlights.push(
        `Protect your ${topStreakHabit.currentStreak}-day streak for "${topStreakHabit.name}" by completing it today.`
      );
    }
  }

  // Academic countdown
  if (ctx.academics.upcomingAssignments.length > 0) {
    const nextAssignment = ctx.academics.upcomingAssignments[0];
    highlights.push(`Upcoming deadline: "${nextAssignment.title}" for ${nextAssignment.course}.`);
  }

  // Fitness status
  if (!ctx.fitness.workedOutToday) {
    highlights.push(`Target reminder: Maintain your goal of ${ctx.user.weeklyGymTarget} gym workouts this week.`);
  }

  return {
    greeting: `${greeting}, ${ctx.user.name || 'Champion'}!`,
    summary: `Here is your HabOS operational briefing for ${new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' })}.`,
    highlights,
    context: ctx,
  };
};

/**
 * UC-150: Recommend Next Action (Intelligent priority weighting)
 */
export const recommendNextAction = async (userId: string) => {
  const ctx = await gatherLifeContext(userId);

  if (ctx.productivity.urgentTasks.length > 0) {
    const topTask = ctx.productivity.urgentTasks[0];
    return {
      recommendationType: 'TASK',
      title: `Focus on: ${topTask.title}`,
      reasoning: `This task is marked as ${topTask.priority} priority and directly unblocks your project/goal roadmap.`,
      targetId: topTask.id,
      suggestedDurationMins: 45,
    };
  }

  if (ctx.habits.pendingHabits.length > 0) {
    const topHabit = ctx.habits.pendingHabits[0];
    return {
      recommendationType: 'HABIT',
      title: `Complete Habit: ${topHabit.name}`,
      reasoning: `Complete this to maintain your ${topHabit.currentStreak}-day streak and boost your Life Score.`,
      targetId: topHabit.id,
      suggestedDurationMins: 15,
    };
  }

  return {
    recommendationType: 'FOCUS_SESSION',
    title: 'Deep Work Session: Coding / Learning',
    reasoning: `You have logged ${ctx.productivity.focusMinutesToday} of your ${ctx.user.dailyCodingTargetMins} daily target minutes.`,
    targetId: null,
    suggestedDurationMins: 25,
  };
};

/**
 * UC-147: Ask AI Assistant with context injection
 */
export const askAssistant = async (userId: string, data: AskAiDTO) => {
  const ctx = await gatherLifeContext(userId);

  // In production, this can invoke Google Gemini / OpenAI via SDK
  // Here we provide high-fidelity structured analysis grounded in live user data:
  const promptLower = data.prompt.toLowerCase();

  let reply = '';
  if (promptLower.includes('habit') || promptLower.includes('streak')) {
    reply = `You currently have ${ctx.habits.completedToday}/${ctx.habits.totalActive} habits completed today. ${
      ctx.habits.pendingHabits.length > 0
        ? `Pending habits: ${ctx.habits.pendingHabits.map((h) => `${h.name} (${h.currentStreak}d)`).join(', ')}.`
        : 'All active habits are completed for today!'
    }`;
  } else if (promptLower.includes('task') || promptLower.includes('todo')) {
    reply = `You have ${ctx.productivity.pendingTasksCount} urgent tasks remaining. Highest priority: "${
      ctx.productivity.urgentTasks[0]?.title || 'None'
    }".`;
  } else if (promptLower.includes('focus') || promptLower.includes('study') || promptLower.includes('code')) {
    reply = `Today you have recorded ${ctx.productivity.focusMinutesToday} minutes of focus time towards your daily target of ${ctx.user.dailyCodingTargetMins} mins.`;
  } else if (promptLower.includes('finance') || promptLower.includes('money') || promptLower.includes('budget')) {
    reply = `This month you have logged \$${ctx.finance.spentThisMonth.toFixed(2)} in expenses against \$${ctx.finance.incomeThisMonth.toFixed(2)} in total income.`;
  } else {
    reply = `Based on your live profile: You have ${ctx.productivity.pendingTasksCount} priority tasks and ${ctx.habits.pendingHabits.length} pending habits. Would you like to start a focus timer or review your roadmap?`;
  }

  return {
    prompt: data.prompt,
    response: reply,
    timestamp: new Date(),
    contextSummary: {
      tasksDue: ctx.productivity.pendingTasksCount,
      habitsPending: ctx.habits.pendingHabits.length,
      focusMinutes: ctx.productivity.focusMinutesToday,
    },
  };
};

export default {
  gatherLifeContext,
  generateDailyBriefing,
  recommendNextAction,
  askAssistant,
};
