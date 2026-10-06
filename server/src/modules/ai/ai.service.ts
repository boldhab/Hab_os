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
      spentThisMonth: monthExpenses._sum.amount ? Number(monthExpenses._sum.amount) : 0,
      incomeThisMonth: monthIncome._sum.amount ? Number(monthIncome._sum.amount) : 0,
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
  // Grounded structured analysis across all live user dimensions:
  const promptLower = data.prompt.toLowerCase();
  const scope = data.contextScope || 'ALL';

  let reply = '';

  if (promptLower.includes('what should i do next') || promptLower.includes('recommend') || promptLower.includes('priority')) {
    if (ctx.productivity.urgentTasks.length > 0) {
      const topTask = ctx.productivity.urgentTasks[0];
      reply = `I recommend focusing on "${topTask.title}" (${topTask.priority} priority). It is your highest priority uncompleted item. Would you like to start a 45-minute focus session for it?`;
    } else if (ctx.habits.pendingHabits.length > 0) {
      reply = `Your priority task queue is clean! Protect your habit streaks by completing "${ctx.habits.pendingHabits[0].name}" (${ctx.habits.pendingHabits[0].currentStreak}d streak).`;
    } else {
      reply = `You are caught up on priority tasks! Log a deep work coding session or review your weekly goals roadmap.`;
    }
  } else if (scope === 'GYM' || promptLower.includes('gym') || promptLower.includes('workout') || promptLower.includes('fitness')) {
    reply = ctx.fitness.workedOutToday
      ? `Great job! You have already completed a workout session today. Your weekly target is ${ctx.user.weeklyGymTarget} sessions. Prioritize hydration and recovery.`
      : `You haven't logged a gym session today. Your weekly target is ${ctx.user.weeklyGymTarget} workouts. Would you like to log a session or follow your routine template?`;
  } else if (scope === 'STUDY' || promptLower.includes('exam') || promptLower.includes('assignment') || promptLower.includes('study') || promptLower.includes('ready')) {
    if (ctx.academics.upcomingExams.length > 0 || ctx.academics.upcomingAssignments.length > 0) {
      const examStr = ctx.academics.upcomingExams.map((e) => `"${e.title}" for ${e.course}`).join(', ');
      const assignStr = ctx.academics.upcomingAssignments.map((a) => `"${a.title}" for ${a.course}`).join(', ');
      reply = `Academic Deadlines Status:\n${ctx.academics.upcomingExams.length > 0 ? `• Upcoming Exams: ${examStr}\n` : ''}${ctx.academics.upcomingAssignments.length > 0 ? `• Upcoming Assignments: ${assignStr}` : ''}\nSchedule a 50-minute Pomodoro block to begin revision.`;
    } else {
      reply = `You have no exams or assignments due within the next 14 days. Ideal time for self-directed technical reading or project architecture!`;
    }
  } else if (scope === 'FINANCE' || promptLower.includes('finance') || promptLower.includes('money') || promptLower.includes('budget') || promptLower.includes('spending')) {
    const net = ctx.finance.incomeThisMonth - ctx.finance.spentThisMonth;
    reply = `Financial Summary for this month:\n• Total Expenses: \$${ctx.finance.spentThisMonth.toFixed(2)}\n• Total Income: \$${ctx.finance.incomeThisMonth.toFixed(2)}\n• Net Cashflow: ${net >= 0 ? `+\$${net.toFixed(2)} (Savings)` : `-\$${Math.abs(net).toFixed(2)} (Deficit)`}.`;
  } else if (scope === 'DEV' || promptLower.includes('code') || promptLower.includes('dev') || promptLower.includes('project')) {
    reply = `Developer Hub Status:\nYou have logged ${ctx.productivity.focusMinutesToday} minutes of focus today towards your daily coding target of ${ctx.user.dailyCodingTargetMins} mins. Push an atomic commit today to maintain momentum!`;
  } else if (scope === 'HABITS' || promptLower.includes('habit') || promptLower.includes('streak')) {
    reply = `You currently have ${ctx.habits.completedToday}/${ctx.habits.totalActive} habits completed today. ${
      ctx.habits.pendingHabits.length > 0
        ? `Pending habits: ${ctx.habits.pendingHabits.map((h) => `${h.name} (${h.currentStreak}d)`).join(', ')}.`
        : 'All active habits are completed for today!'
    }`;
  } else if (scope === 'TASKS' || promptLower.includes('task') || promptLower.includes('todo')) {
    reply = `You have ${ctx.productivity.pendingTasksCount} urgent tasks in your queue. Highest priority: "${
      ctx.productivity.urgentTasks[0]?.title || 'None'
    }".`;
  } else {
    reply = `Based on your live profile: You have ${ctx.productivity.pendingTasksCount} priority tasks, ${ctx.habits.pendingHabits.length} pending habits, and ${ctx.productivity.focusMinutesToday} focus mins recorded today. How can I help you optimize your schedule?`;
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

export interface NeglectedArea {
  domain: 'FITNESS' | 'HABITS' | 'STUDY' | 'FINANCE' | 'DEV' | 'PRODUCTIVITY';
  title: string;
  description: string;
  severity: 'HIGH' | 'MEDIUM' | 'LOW';
  daysInactive?: number;
  metricLabel: string;
  metricValue: string;
  recommendedAction: string;
}

export interface RecommendedTask {
  id: string;
  title: string;
  priority: string;
  domain: string;
  score: number;
  dueDate: Date | null;
  estimatedMinutes?: number | null;
  projectName?: string | null;
  courseName?: string | null;
  reason: string;
}

export interface PersonalizedPlanDay {
  dayName: string;
  focusDomain: string;
  targetMins: number;
  suggestedActions: string[];
}

export interface PersonalizedPlan {
  weeklyGoal: string;
  totalSuggestedFocusMins: number;
  priorityDomains: string[];
  schedule: PersonalizedPlanDay[];
  aiAdvice: string;
}

export interface DomainMetric {
  label: string;
  value: string;
  trend?: string;
}

export interface DomainInsight {
  domain: 'PRODUCTIVITY' | 'FINANCE' | 'DEV' | 'STUDY' | 'FITNESS';
  title: string;
  summary: string;
  healthScore: number;
  metrics: DomainMetric[];
  recommendations: string[];
}

/**
 * UC-142: Identify Neglected Areas across all life domains
 */
export const identifyNeglectedAreas = async (userId: string, periodDays: number = 7) => {
  const now = new Date();
  const pastThreshold = new Date(now.getTime() - periodDays * 24 * 60 * 60 * 1000);
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);

  const [
    user,
    lastWorkout,
    recentWorkoutsCount,
    activeHabits,
    studySessions,
    courses,
    upcomingExams,
    upcomingAssignments,
    monthExpenses,
    monthIncome,
    activeProjects,
    recentFocusSessions,
    overdueTasksCount,
  ] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      include: { preferences: true },
    }),
    prisma.workout.findFirst({
      where: { userId },
      orderBy: { date: 'desc' },
      select: { date: true },
    }),
    prisma.workout.count({
      where: { userId, date: { gte: pastThreshold } },
    }),
    prisma.habit.findMany({
      where: { userId, isActive: true },
      include: {
        logs: {
          where: { date: { gte: pastThreshold } },
        },
      },
    }),
    prisma.studySession.findMany({
      where: { userId, startTime: { gte: pastThreshold } },
      select: { durationMinutes: true },
    }),
    prisma.course.findMany({
      where: { userId },
      select: { id: true, name: true },
    }),
    prisma.exam.findMany({
      where: {
        course: { userId },
        examDate: { gte: now, lte: new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000) },
      },
      select: { id: true, title: true, examDate: true },
    }),
    prisma.assignment.findMany({
      where: {
        course: { userId },
        dueDate: { gte: now, lte: new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000) },
        status: { notIn: ['SUBMITTED', 'GRADED'] },
      },
      select: { id: true, title: true, dueDate: true },
    }),
    prisma.transaction.aggregate({
      where: { userId, type: 'EXPENSE', date: { gte: startOfMonth } },
      _sum: { amount: true },
    }),
    prisma.transaction.aggregate({
      where: { userId, type: 'INCOME', date: { gte: startOfMonth } },
      _sum: { amount: true },
    }),
    prisma.project.count({
      where: { userId, status: 'IN_PROGRESS' },
    }),
    prisma.focusSession.findMany({
      where: { userId, startTime: { gte: pastThreshold } },
      select: { durationMinutes: true },
    }),
    prisma.task.count({
      where: { userId, isCompleted: false, dueDate: { lt: startOfToday } },
    }),
  ]);

  const neglected: NeglectedArea[] = [];
  const weeklyGymTarget = user?.preferences?.weeklyGymTarget || 4;

  // 1. Fitness Domain Assessment
  if (!lastWorkout) {
    neglected.push({
      domain: 'FITNESS',
      title: 'No Workouts Logged',
      description: 'You have not recorded any gym sessions yet. Regular physical activity drives focus and vitality.',
      severity: 'HIGH',
      daysInactive: 30,
      metricLabel: 'Weekly Target',
      metricValue: `0 / ${weeklyGymTarget} sessions`,
      recommendedAction: 'Schedule a 30-minute introductory workout or recovery session.',
    });
  } else {
    const daysSinceWorkout = Math.floor((now.getTime() - new Date(lastWorkout.date).getTime()) / (1000 * 3600 * 24));
    if (daysSinceWorkout >= 5) {
      neglected.push({
        domain: 'FITNESS',
        title: 'Fitness Inactivity Lag',
        description: `It has been ${daysSinceWorkout} days since your last gym workout. Consistency prevents deconditioning.`,
        severity: 'HIGH',
        daysInactive: daysSinceWorkout,
        metricLabel: 'Weekly Achieved',
        metricValue: `${recentWorkoutsCount} / ${weeklyGymTarget} sessions`,
        recommendedAction: 'Log your next resistance or cardio session today.',
      });
    } else if (daysSinceWorkout >= 3 && recentWorkoutsCount < Math.ceil(weeklyGymTarget / 2)) {
      neglected.push({
        domain: 'FITNESS',
        title: 'Workout Target Slipping',
        description: `${daysSinceWorkout} days since your last session with only ${recentWorkoutsCount} logged this week.`,
        severity: 'MEDIUM',
        daysInactive: daysSinceWorkout,
        metricLabel: 'Weekly Achieved',
        metricValue: `${recentWorkoutsCount} / ${weeklyGymTarget} sessions`,
        recommendedAction: 'Book a workout slot to stay on track for your weekly target.',
      });
    }
  }

  // 2. Habits Domain Assessment
  if (activeHabits.length > 0) {
    const totalExpectedLogs = activeHabits.length * periodDays;
    const completedLogs = activeHabits.reduce(
      (sum, h) => sum + h.logs.filter((l) => l.isCompleted).length,
      0
    );
    const completionRate = totalExpectedLogs > 0 ? (completedLogs / totalExpectedLogs) * 100 : 0;

    if (completionRate < 45) {
      neglected.push({
        domain: 'HABITS',
        title: 'Habit Adherence Below 45%',
        description: `Your 7-day habit completion rate dropped to ${Math.round(completionRate)}%. Routine consistency builds compounding momentum.`,
        severity: 'HIGH',
        metricLabel: '7-Day Completion',
        metricValue: `${Math.round(completionRate)}%`,
        recommendedAction: 'Focus on locking in your top micro-habit before noon today.',
      });
    } else if (completionRate < 65) {
      neglected.push({
        domain: 'HABITS',
        title: 'Habit Routine Slipping',
        description: `Habit adherence is at ${Math.round(completionRate)}%. Several daily check-ins have been skipped.`,
        severity: 'MEDIUM',
        metricLabel: '7-Day Completion',
        metricValue: `${Math.round(completionRate)}%`,
        recommendedAction: 'Stack your next habit onto an established daily routine.',
      });
    }
  }

  // 3. Academic / Study Assessment
  const totalStudyMinutes = studySessions.reduce((acc, s) => acc + s.durationMinutes, 0);
  const totalStudyHours = totalStudyMinutes / 60;
  const hasAcademicDeadlines = upcomingExams.length > 0 || upcomingAssignments.length > 0;

  if (courses.length > 0 && hasAcademicDeadlines && totalStudyHours < 1.0) {
    neglected.push({
      domain: 'STUDY',
      title: 'Zero Academic Study Logged',
      description: `You have ${upcomingExams.length} exams and ${upcomingAssignments.length} assignments within 14 days, but under 1 hour studied this week.`,
      severity: 'HIGH',
      metricLabel: 'Study Time (7d)',
      metricValue: `${totalStudyHours.toFixed(1)} hrs`,
      recommendedAction: 'Initiate a 45-minute focused Pomodoro study block for your earliest exam/assignment.',
    });
  } else if (courses.length > 0 && totalStudyHours < 2.5) {
    neglected.push({
      domain: 'STUDY',
      title: 'Study Velocity Low',
      description: `Only ${totalStudyHours.toFixed(1)} hrs studied in the last 7 days across ${courses.length} enrolled courses.`,
      severity: 'MEDIUM',
      metricLabel: 'Study Time (7d)',
      metricValue: `${totalStudyHours.toFixed(1)} hrs`,
      recommendedAction: 'Schedule a revision block to maintain course retention.',
    });
  }

  // 4. Finance / Cashflow Assessment
  const expenses = monthExpenses._sum.amount ? Number(monthExpenses._sum.amount) : 0;
  const income = monthIncome._sum.amount ? Number(monthIncome._sum.amount) : 0;

  if (expenses > income && expenses > 0) {
    neglected.push({
      domain: 'FINANCE',
      title: 'Negative Monthly Cashflow',
      description: `Month-to-date spending ($${expenses.toFixed(0)}) exceeds total recorded income ($${income.toFixed(0)}).`,
      severity: 'HIGH',
      metricLabel: 'Net Deficit',
      metricValue: `-$${(expenses - income).toFixed(0)}`,
      recommendedAction: 'Audit recent discretionary expenses and pause non-essential purchases.',
    });
  } else if (income > 0 && expenses / income > 0.85) {
    neglected.push({
      domain: 'FINANCE',
      title: 'High Burn Rate Warning',
      description: `Current expenses represent ${Math.round((expenses / income) * 100)}% of monthly income.`,
      severity: 'MEDIUM',
      metricLabel: 'Burn Ratio',
      metricValue: `${Math.round((expenses / income) * 100)}%`,
      recommendedAction: 'Review category spending to preserve savings.',
    });
  }

  // 5. Developer / Projects Assessment
  const totalDevMinutes = recentFocusSessions.reduce((acc, f) => acc + f.durationMinutes, 0);
  if (activeProjects > 0 && totalDevMinutes < 60) {
    neglected.push({
      domain: 'DEV',
      title: 'Project Momentum Stalled',
      description: `You have ${activeProjects} active development projects, but under 1 hour of focus logged this week.`,
      severity: 'MEDIUM',
      metricLabel: 'Focus Logged (7d)',
      metricValue: `${(totalDevMinutes / 60).toFixed(1)} hrs`,
      recommendedAction: 'Complete a focused coding session or merge 1 open bug fix.',
    });
  }

  // 6. Productivity / Task Backlog Assessment
  if (overdueTasksCount >= 3) {
    neglected.push({
      domain: 'PRODUCTIVITY',
      title: 'Overdue Task Accumulation',
      description: `${overdueTasksCount} tasks have passed their due dates without completion, clogging your operational queue.`,
      severity: 'HIGH',
      metricLabel: 'Overdue Count',
      metricValue: `${overdueTasksCount} tasks`,
      recommendedAction: 'Conduct a 15-minute backlog triage: reschedule, complete, or dismiss aging tasks.',
    });
  }

  // Sort by severity (HIGH -> MEDIUM -> LOW)
  const severityWeights: Record<string, number> = { HIGH: 3, MEDIUM: 2, LOW: 1 };
  neglected.sort((a, b) => severityWeights[b.severity] - severityWeights[a.severity]);

  return {
    neglectedAreas: neglected,
    totalCount: neglected.length,
    highestSeverity: neglected.length > 0 ? neglected[0].severity : 'NONE',
  };
};

/**
 * UC-141: Recommend Next Tasks based on priorities, deadlines, and neglected domains
 */
export const recommendNextTasks = async (userId: string, limit: number = 5) => {
  const now = new Date();
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);

  // 1. Fetch neglected areas to boost lagging domains
  const neglectedResult = await identifyNeglectedAreas(userId, 7);
  const neglectedDomains = new Set(neglectedResult.neglectedAreas.map((a) => a.domain));

  // 2. Fetch pending tasks with dependencies, project, and course relations
  const tasks = await prisma.task.findMany({
    where: {
      userId,
      isCompleted: false,
    },
    include: {
      blockedBy: {
        include: {
          blockingTask: {
            select: { id: true, title: true, isCompleted: true },
          },
        },
      },
      project: { select: { id: true, title: true } },
      course: { select: { id: true, name: true } },
    },
    take: 50,
  });

  const scoredTasks: RecommendedTask[] = [];

  for (const task of tasks) {
    // Check if task is blocked by any unfinished dependency
    const hasUnfinishedBlocker = task.blockedBy.some((b) => !b.blockingTask.isCompleted);
    if (hasUnfinishedBlocker) {
      continue; // Skip blocked tasks from immediate recommendations
    }

    let score = 0;
    const reasons: string[] = [];

    // Base Priority Score
    switch (task.priority) {
      case 'CRITICAL':
        score += 100;
        reasons.push('Critical priority item');
        break;
      case 'HIGH':
        score += 75;
        reasons.push('High priority item');
        break;
      case 'MEDIUM':
        score += 45;
        break;
      case 'LOW':
      default:
        score += 20;
        break;
    }

    // Deadline Urgency Score
    if (task.dueDate) {
      const dueTime = new Date(task.dueDate).getTime();
      const diffMs = dueTime - now.getTime();

      if (dueTime < startOfToday.getTime()) {
        score += 65;
        reasons.push('Past due date');
      } else if (diffMs <= 24 * 60 * 60 * 1000) {
        score += 50;
        reasons.push('Due today');
      } else if (diffMs <= 3 * 24 * 60 * 60 * 1000) {
        score += 30;
        reasons.push('Approaching deadline');
      } else if (diffMs <= 7 * 24 * 60 * 60 * 1000) {
        score += 15;
      }
    }

    // Domain Boost & Classification
    let domain = 'PRODUCTIVITY';

    if (task.courseId) {
      domain = 'STUDY';
      if (neglectedDomains.has('STUDY')) {
        score += 35;
        reasons.push(`Bolsters lagging academic progress in ${task.course?.name || 'course'}`);
      }
    } else if (task.projectId) {
      domain = 'DEV';
      if (neglectedDomains.has('DEV')) {
        score += 30;
        reasons.push(`Advances active project "${task.project?.title || 'project'}"`);
      }
    } else {
      const titleLower = task.title.toLowerCase();
      if (/gym|workout|lift|cardio|leg|chest|fitness/.test(titleLower)) {
        domain = 'FITNESS';
        if (neglectedDomains.has('FITNESS')) {
          score += 30;
          reasons.push('Helps restore lagging gym consistency');
        }
      } else if (/budget|finance|tax|invoice|bank|expense|bill/.test(titleLower)) {
        domain = 'FINANCE';
        if (neglectedDomains.has('FINANCE')) {
          score += 30;
          reasons.push('Addresses neglected financial health');
        }
      }
    }

    // Time fit / Quick win boost
    if (task.estimatedMinutes && task.estimatedMinutes <= 30) {
      score += 10;
      reasons.push(`Quick win (${task.estimatedMinutes} mins)`);
    }

    const humanizedReason = reasons.length > 0 ? reasons.join(' • ') : 'Standard queue recommendation';

    scoredTasks.push({
      id: task.id,
      title: task.title,
      priority: task.priority,
      domain,
      score,
      dueDate: task.dueDate,
      estimatedMinutes: task.estimatedMinutes,
      projectName: task.project?.title || null,
      courseName: task.course?.name || null,
      reason: humanizedReason,
    });
  }

  // Sort descending by score
  scoredTasks.sort((a, b) => b.score - a.score);

  return scoredTasks.slice(0, limit);
};

/**
 * UC-143: Generate Personalized Plan balancing neglected domains and upcoming goals
 */
export const generatePersonalizedPlan = async (userId: string, goalPrompt?: string) => {
  const [user, neglectedResult, recommendedTasks] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      include: { preferences: true },
    }),
    identifyNeglectedAreas(userId, 7),
    recommendNextTasks(userId, 3),
  ]);

  const codingTarget = user?.preferences?.dailyCodingTargetMins || 120;
  const studyTarget = user?.preferences?.dailyStudyTargetMins || 90;
  const gymTarget = user?.preferences?.weeklyGymTarget || 4;

  const neglectedList = neglectedResult.neglectedAreas;
  const priorityDomains = Array.from(new Set(neglectedList.map((a) => a.domain)));
  if (priorityDomains.length === 0) {
    priorityDomains.push('PRODUCTIVITY', 'DEV', 'FITNESS');
  }

  // Days schedule template
  const schedule: PersonalizedPlanDay[] = [
    {
      dayName: 'Monday',
      focusDomain: 'PRODUCTIVITY',
      targetMins: 90,
      suggestedActions: [
        recommendedTasks[0]?.title ? `Tackle top task: "${recommendedTasks[0].title}"` : 'Clear backlog inbox',
        'Review active priorities and establish weekly milestones',
      ],
    },
    {
      dayName: 'Tuesday',
      focusDomain: 'FITNESS',
      targetMins: 60,
      suggestedActions: [
        'Complete resistance training workout session',
        'Log workout exercises and personal records',
      ],
    },
    {
      dayName: 'Wednesday',
      focusDomain: 'DEV',
      targetMins: codingTarget,
      suggestedActions: [
        'Implement feature sprint for active project',
        'Commit codebase changes and review pending PRs',
      ],
    },
    {
      dayName: 'Thursday',
      focusDomain: 'STUDY',
      targetMins: studyTarget,
      suggestedActions: [
        'Deep study session for upcoming exam / course',
        'Work on pending academic assignments',
      ],
    },
    {
      dayName: 'Friday',
      focusDomain: 'FINANCE',
      targetMins: 45,
      suggestedActions: [
        'Reconcile weekly transactions and review category budgets',
        'Log income and verify savings rate',
      ],
    },
    {
      dayName: 'Saturday',
      focusDomain: 'FITNESS',
      targetMins: 60,
      suggestedActions: [
        'Endurance or secondary workout session',
        'Active mobility and recovery routine',
      ],
    },
    {
      dayName: 'Sunday',
      focusDomain: 'PRODUCTIVITY',
      targetMins: 45,
      suggestedActions: [
        'Conduct weekly retrospective and review life score',
        'Calibrate priorities and set focus blocks for next week',
      ],
    },
  ];

  // Rebalance schedule based on top neglected domain
  if (neglectedList.length > 0) {
    const topNeglected = neglectedList[0];
    if (topNeglected.domain === 'STUDY') {
      schedule[0].focusDomain = 'STUDY';
      schedule[0].targetMins = studyTarget;
      schedule[0].suggestedActions.unshift(topNeglected.recommendedAction);
    } else if (topNeglected.domain === 'FITNESS') {
      schedule[0].focusDomain = 'FITNESS';
      schedule[0].targetMins = 60;
      schedule[0].suggestedActions.unshift(topNeglected.recommendedAction);
    }
  }

  const totalSuggestedFocusMins = schedule.reduce((sum, d) => sum + d.targetMins, 0);

  const weeklyGoal = goalPrompt?.trim()
    ? `Objective: ${goalPrompt.trim()}`
    : neglectedList.length > 0
    ? `System Rebalance: Address ${neglectedList[0].title} while executing high-priority project tasks.`
    : 'Execution Sprint: Maintain optimal cadence across all life domains.';

  const aiAdvice =
    neglectedList.length > 0
      ? `Highest priority alert: ${neglectedList[0].title}. Dedicate early morning focus blocks to ${neglectedList[0].domain.toLowerCase()} to restore balance.`
      : 'All primary life domains are currently balanced. Keep steady momentum across your daily habit routines.';

  return {
    weeklyGoal,
    totalSuggestedFocusMins,
    priorityDomains,
    schedule,
    aiAdvice,
  };
};

/**
 * UC-136 to UC-140: Multi-domain grounded performance insights
 */
export const analyzeDomainInsights = async (userId: string, requestedDomain?: string) => {
  const [ctx, neglectedRes] = await Promise.all([
    gatherLifeContext(userId),
    identifyNeglectedAreas(userId, 7),
  ]);

  const insights: DomainInsight[] = [
    // UC-136: Productivity
    {
      domain: 'PRODUCTIVITY',
      title: 'Productivity & Focus Trends',
      summary: `You have completed ${ctx.productivity.focusMinutesToday} focus minutes today with ${ctx.productivity.pendingTasksCount} urgent tasks remaining.`,
      healthScore: ctx.productivity.pendingTasksCount > 5 ? 65 : 90,
      metrics: [
        { label: 'Today Focus', value: `${ctx.productivity.focusMinutesToday} mins` },
        { label: 'Urgent Tasks', value: `${ctx.productivity.pendingTasksCount}` },
      ],
      recommendations: [
        'Utilize 50-minute Pomodoro intervals for deep work blocks.',
        'Clear highest priority tasks during peak morning energy.',
      ],
    },
    // UC-137: Finance
    {
      domain: 'FINANCE',
      title: 'Spending & Cash Flow Analysis',
      summary: `Total month-to-date spending is $${ctx.finance.spentThisMonth.toFixed(2)} against $${ctx.finance.incomeThisMonth.toFixed(2)} in total income.`,
      healthScore: ctx.finance.spentThisMonth > ctx.finance.incomeThisMonth && ctx.finance.incomeThisMonth > 0 ? 55 : 88,
      metrics: [
        { label: 'Month Expenses', value: `$${ctx.finance.spentThisMonth.toFixed(2)}` },
        { label: 'Month Income', value: `$${ctx.finance.incomeThisMonth.toFixed(2)}` },
      ],
      recommendations: [
        'Monitor recurring subscription outflows.',
        'Target a 20%+ monthly savings rate.',
      ],
    },
    // UC-138: Developer
    {
      domain: 'DEV',
      title: 'Developer Momentum & Commit Velocity',
      summary: `Daily coding target: ${ctx.user.dailyCodingTargetMins} mins. Consistency in code commits accelerates project milestone delivery.`,
      healthScore: 82,
      metrics: [
        { label: 'Daily Target', value: `${ctx.user.dailyCodingTargetMins} mins` },
      ],
      recommendations: [
        'Push at least one atomic commit per day to maintain momentum.',
        'Review open bugs before starting new feature development.',
      ],
    },
    // UC-139: Study
    {
      domain: 'STUDY',
      title: 'Academic & Course Progress',
      summary: `Upcoming deadlines: ${ctx.academics.upcomingAssignments.length} assignments and ${ctx.academics.upcomingExams.length} exams.`,
      healthScore: ctx.academics.upcomingAssignments.length > 2 ? 70 : 85,
      metrics: [
        { label: 'Upcoming Assignments', value: `${ctx.academics.upcomingAssignments.length}` },
        { label: 'Upcoming Exams', value: `${ctx.academics.upcomingExams.length}` },
      ],
      recommendations: [
        'Begin assignment outlines at least 5 days prior to deadline.',
        'Use spaced repetition review blocks for exam prep.',
      ],
    },
    // UC-140: Fitness
    {
      domain: 'FITNESS',
      title: 'Gym & Strength Conditioning',
      summary: `Weekly gym target: ${ctx.user.weeklyGymTarget} workouts. Worked out today: ${ctx.fitness.workedOutToday ? 'Yes' : 'No'}.`,
      healthScore: ctx.fitness.workedOutToday ? 95 : 75,
      metrics: [
        { label: 'Weekly Target', value: `${ctx.user.weeklyGymTarget} sessions` },
        { label: 'Trained Today', value: ctx.fitness.workedOutToday ? 'Yes' : 'No' },
      ],
      recommendations: [
        'Prioritize progressive overload on primary compound lifts.',
        'Ensure 48 hours recovery between intense muscle group training.',
      ],
    },
  ];

  if (requestedDomain) {
    const single = insights.find((i) => i.domain.toUpperCase() === requestedDomain.toUpperCase());
    return single || insights[0];
  }

  return insights;
};

export default {
  gatherLifeContext,
  generateDailyBriefing,
  recommendNextAction,
  askAssistant,
  identifyNeglectedAreas,
  recommendNextTasks,
  generatePersonalizedPlan,
  analyzeDomainInsights,
};
