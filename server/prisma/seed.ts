import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting comprehensive HabOS database seed for ALL tables...');

  // ==========================================
  // 1. CLEANUP (IN REVERSE DEPENDENCY ORDER)
  // ==========================================
  console.log('🧹 Cleaning existing test data...');
  await prisma.notification.deleteMany();
  await prisma.noteLink.deleteMany();
  await prisma.vaultNote.deleteMany();
  await prisma.goalCheckIn.deleteMany();
  await prisma.milestone.deleteMany();
  await prisma.taskDependency.deleteMany();
  await prisma.timeEntry.deleteMany();
  await prisma.focusSession.deleteMany();
  await prisma.task.deleteMany();
  await prisma.goal.deleteMany();
  await prisma.budget.deleteMany();
  await prisma.transaction.deleteMany();
  await prisma.bodyMetric.deleteMany();
  await prisma.workoutTemplateExercise.deleteMany();
  await prisma.workoutTemplate.deleteMany();
  await prisma.setEntry.deleteMany();
  await prisma.workoutExercise.deleteMany();
  await prisma.workout.deleteMany();
  await prisma.personalRecord.deleteMany();
  await prisma.exercise.deleteMany();
  await prisma.studySession.deleteMany();
  await prisma.attendance.deleteMany();
  await prisma.exam.deleteMany();
  await prisma.assignment.deleteMany();
  await prisma.classSchedule.deleteMany();
  await prisma.course.deleteMany();
  await prisma.techLearning.deleteMany();
  await prisma.leetCodeIntegration.deleteMany();
  await prisma.gitHubIntegration.deleteMany();
  await prisma.githubLink.deleteMany();
  await prisma.bug.deleteMany();
  await prisma.feature.deleteMany();
  await prisma.project.deleteMany();
  await prisma.habitCorrelation.deleteMany();
  await prisma.routineItem.deleteMany();
  await prisma.routine.deleteMany();
  await prisma.habitLog.deleteMany();
  await prisma.habit.deleteMany();
  await prisma.scheduleEvent.deleteMany();
  await prisma.googleCalendarSync.deleteMany();
  await prisma.lifeScoreLog.deleteMany();
  await prisma.category.deleteMany();
  await prisma.userPreference.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.user.deleteMany();

  // ==========================================
  // 2. USER PROFILE & PREFERENCES
  // ==========================================
  console.log('👤 Seeding User & UserPreferences...');
  const hashedPassword = await bcrypt.hash('Habos@2026', 10);
  const demoEmail = 'demo@habos.dev';

  const user = await prisma.user.create({
    data: {
      email: demoEmail,
      password: hashedPassword,
      name: 'HabOS Explorer',
      timezone: 'UTC',
      dateFormat: 'YYYY-MM-DD',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    },
  });

  await prisma.refreshToken.create({
    data: {
      token: 'seed_refresh_token_habos_2026_demo_valid',
      userId: user.id,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      revoked: false,
    },
  });

  await prisma.userPreference.create({
    data: {
      userId: user.id,
      dashboardModules: [
        'priorities',
        'life_score',
        'coding_stats',
        'study_timer',
        'gym_workout',
        'finance_summary',
        'habits',
      ],
      dailyCodingTargetMins: 120,
      dailyStudyTargetMins: 120,
      dailyReadingTargetMins: 30,
      weeklyGymTarget: 4,
      quietHoursStart: '22:30',
      quietHoursEnd: '06:30',
      lifeScoreWeights: {
        tasks: 0.15,
        coding: 0.2,
        study: 0.2,
        gym: 0.15,
        habits: 0.15,
        finance: 0.15,
      },
    },
  });

  // ==========================================
  // 3. CATEGORIES
  // ==========================================
  console.log('🏷️  Seeding Categories...');
  const categoriesData = [
    { name: 'Frontend Engineering', color: '#3B82F6', icon: 'code', type: 'TASK' },
    { name: 'Backend & Cloud API', color: '#10B981', icon: 'server', type: 'TASK' },
    { name: 'Distributed Systems', color: '#8B5CF6', icon: 'book', type: 'TASK' },
    { name: 'Daily Habits', color: '#06B6D4', icon: 'check-circle', type: 'HABIT' },
    { name: 'Health & Fitness', color: '#EF4444', icon: 'heart', type: 'HABIT' },
    { name: 'Mindfulness & Mental', color: '#F97316', icon: 'smile', type: 'HABIT' },
    { name: 'Income & Freelance', color: '#10B981', icon: 'dollar-sign', type: 'FINANCE' },
    { name: 'Food & Groceries', color: '#F59E0B', icon: 'coffee', type: 'FINANCE' },
    { name: 'Tech & Subscriptions', color: '#6366F1', icon: 'cpu', type: 'FINANCE' },
    { name: 'Gym & Sports Gear', color: '#EC4899', icon: 'shopping-bag', type: 'FINANCE' },
    { name: 'CS Architecture Vault', color: '#14B8A6', icon: 'folder', type: 'VAULT' },
    { name: 'Life Philosophy', color: '#A855F7', icon: 'bookmark', type: 'VAULT' },
  ];

  const categories: Record<string, any> = {};
  for (const cat of categoriesData) {
    const created = await prisma.category.create({
      data: { ...cat, userId: user.id },
    });
    categories[cat.name] = created;
  }

  // ==========================================
  // 4. LIFE SCORE LOGS (Past 7 Days)
  // ==========================================
  console.log('📈 Seeding LifeScoreLogs...');
  const lifeScoreLogs = [
    { daysAgo: 6, score: 74.0, task: 70, coding: 80, study: 65, gym: 75, habit: 80, finance: 75 },
    { daysAgo: 5, score: 78.5, task: 80, coding: 85, study: 70, gym: 80, habit: 80, finance: 76 },
    { daysAgo: 4, score: 81.0, task: 85, coding: 90, study: 75, gym: 80, habit: 85, finance: 72 },
    { daysAgo: 3, score: 79.0, task: 75, coding: 80, study: 80, gym: 85, habit: 80, finance: 75 },
    { daysAgo: 2, score: 84.5, task: 90, coding: 95, study: 80, gym: 75, habit: 90, finance: 80 },
    { daysAgo: 1, score: 88.0, task: 95, coding: 90, study: 85, gym: 90, habit: 90, finance: 80 },
    { daysAgo: 0, score: 86.5, task: 88, coding: 90, study: 85, gym: 85, habit: 88, finance: 82 },
  ];

  for (const item of lifeScoreLogs) {
    const d = new Date();
    d.setDate(d.getDate() - item.daysAgo);
    await prisma.lifeScoreLog.create({
      data: {
        date: d,
        overallScore: item.score,
        taskScore: item.task,
        codingScore: item.coding,
        studyScore: item.study,
        gymScore: item.gym,
        habitScore: item.habit,
        financeScore: item.finance,
        userId: user.id,
      },
    });
  }

  // ==========================================
  // 5. DEVELOPER HUB: Projects, Features, Bugs & Integrations
  // ==========================================
  console.log('💻 Seeding Projects, Features, Bugs & Tech Integrations...');
  const project1 = await prisma.project.create({
    data: {
      title: 'HabOS Core Life System',
      description: 'Unified cross-platform life operating dashboard built with Flutter & Node/Prisma',
      repoUrl: 'https://github.com/habos/habos-core',
      status: 'IN_PROGRESS',
      progress: 68.0,
      technologies: ['Flutter', 'TypeScript', 'Prisma', 'PostgreSQL', 'Riverpod', 'Docker'],
      color: '#3B82F6',
      webhookSecret: 'habos_webhook_secret_key_2026',
      userId: user.id,
      features: {
        create: [
          { name: 'Habit Routine Sequential Bundling', status: 'COMPLETED', priority: 'HIGH', order: 1.0 },
          { name: 'Live LifeScore Composite Engine', status: 'COMPLETED', priority: 'HIGH', order: 2.0 },
          { name: 'B-Tree Indexing in PostgreSQL Engine', status: 'IN_PROGRESS', priority: 'MEDIUM', order: 3.0 },
          { name: 'Cross-Device Notification Daemon', status: 'TODO', priority: 'MEDIUM', order: 4.0 },
        ],
      },
      bugs: {
        create: [
          {
            title: 'Fix token refresh race condition on parallel endpoints',
            description: 'Simultaneous API calls trigger multiple refresh token invalidations in interceptor',
            severity: 'CRITICAL',
            priority: 'HIGH',
            status: 'RESOLVED',
            order: 1.0,
            resolutionNotes: 'Implemented single-flight lock mutex in RefreshInterceptor',
          },
          {
            title: 'Audit streak freeze decrement boundary on timezones',
            description: 'Streaks reset if user travels across UTC boundaries late at night',
            severity: 'MAJOR',
            priority: 'MEDIUM',
            status: 'OPEN',
            order: 2.0,
          },
        ],
      },
    },
  });

  const project2 = await prisma.project.create({
    data: {
      title: 'AI Second Brain Neural Search',
      description: 'Semantic vector similarity and personal knowledge query engine',
      repoUrl: 'https://github.com/habos/ai-brain',
      status: 'PLANNING',
      progress: 25.0,
      technologies: ['Python', 'FastAPI', 'pgvector', 'LangChain', 'OpenAI'],
      color: '#10B981',
      userId: user.id,
      features: {
        create: [
          { name: 'Local Embedding Generation Pipeline', status: 'IN_PROGRESS', priority: 'HIGH', order: 1.0 },
          { name: 'Markdown Note Chunking & Tokenizer', status: 'TODO', priority: 'MEDIUM', order: 2.0 },
        ],
      },
    },
  });

  await prisma.githubLink.create({
    data: {
      projectId: project1.id,
      repoFullName: 'habos/habos-core',
      issueOrPrNumber: 104,
      entityType: 'FEATURE',
      entityId: project1.id,
    },
  });

  await prisma.gitHubIntegration.create({
    data: {
      userId: user.id,
      username: 'hab-dev',
      accessToken: 'ghp_mock_encrypted_token_value_xyz',
      lastSyncedAt: new Date(),
      totalCommits: 482,
      publicReposCount: 14,
      currentStreak: 19,
      longestStreak: 45,
      recentCommitsJson: [
        { repo: 'habos-core', message: 'feat: add habit correlation matrix', date: new Date().toISOString() },
        { repo: 'habos-core', message: 'fix: schema synchronization with postgres', date: new Date().toISOString() },
      ],
    },
  });

  await prisma.leetCodeIntegration.create({
    data: {
      userId: user.id,
      username: 'hab_coder',
      totalSolved: 312,
      easySolved: 120,
      mediumSolved: 154,
      hardSolved: 38,
      currentStreak: 12,
      longestStreak: 28,
      lastSyncedAt: new Date(),
    },
  });

  await prisma.techLearning.createMany({
    data: [
      {
        name: 'Rust & Systems Memory Safety',
        status: 'LEARNING',
        progressPercentage: 45.0,
        priority: 'HIGH',
        userId: user.id,
        resources: [
          { title: 'The Rust Programming Book', type: 'BOOK', url: 'https://doc.rust-lang.org/book/' },
          { title: 'Rustlings Exercises', type: 'EXERCISE', url: 'https://github.com/rust-lang/rustlings' },
        ],
      },
      {
        name: 'Distributed Systems & Paxos Consensus',
        status: 'PRACTICING',
        progressPercentage: 60.0,
        priority: 'HIGH',
        userId: user.id,
        resources: [
          { title: 'Designing Data-Intensive Applications', type: 'BOOK', url: 'https://dataintensive.net/' },
        ],
      },
      {
        name: 'Advanced Flutter Internals & RenderObjects',
        status: 'COMPLETED',
        progressPercentage: 100.0,
        priority: 'MEDIUM',
        userId: user.id,
      },
    ],
  });

  // ==========================================
  // 6. STUDENT HUB: Courses, Schedules, Assignments & Exams
  // ==========================================
  console.log('🎓 Seeding Courses, Assignments, Exams & Class Schedules...');
  const course1 = await prisma.course.create({
    data: {
      name: 'Distributed Systems & Cloud Computing',
      code: 'CS441',
      semester: 'Fall 2026',
      instructor: 'Dr. Sarah Connor',
      credits: 4,
      progress: 58.0,
      color: '#3B82F6',
      userId: user.id,
      classSchedules: {
        create: [
          { dayOfWeek: 1, startTime: '09:00', endTime: '10:30', room: 'Hall B-201' },
          { dayOfWeek: 3, startTime: '09:00', endTime: '10:30', room: 'Hall B-201' },
        ],
      },
      assignments: {
        create: [
          {
            title: 'Raft Consensus Protocol Implementation in Go',
            description: 'Build leader election, log replication, and persistence for a 5-node cluster',
            dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
            type: 'PROJECT',
            weight: 20.0,
            status: 'IN_PROGRESS',
            maxGrade: 100.0,
          },
          {
            title: 'RPC and Network Fault Tolerance Paper Review',
            description: 'Critique Leslie Lamports Logical Clocks paper',
            dueDate: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
            type: 'ESSAY',
            weight: 10.0,
            status: 'GRADED',
            grade: 96.0,
            maxGrade: 100.0,
          },
        ],
      },
      exams: {
        create: [
          {
            title: 'Distributed Systems Midterm Exam',
            examDate: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000),
            startTime: '10:00',
            examType: 'MIDTERM',
            weight: 30.0,
            maxGrade: 100.0,
          },
        ],
      },
      attendances: {
        create: [
          { date: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), status: 'PRESENT' },
          { date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), status: 'PRESENT' },
        ],
      },
      studySessions: {
        create: [
          {
            startTime: new Date(Date.now() - 24 * 60 * 60 * 1000),
            endTime: new Date(Date.now() - 22 * 60 * 60 * 1000),
            durationMinutes: 120,
            notes: 'Deep dive into Raft state machine safety proofs',
            userId: user.id,
          },
        ],
      },
    },
  });

  const course2 = await prisma.course.create({
    data: {
      name: 'Advanced Database Internals',
      code: 'CS452',
      semester: 'Fall 2026',
      instructor: 'Prof. Michael Stonebraker',
      credits: 3,
      progress: 42.0,
      color: '#8B5CF6',
      userId: user.id,
      classSchedules: {
        create: [
          { dayOfWeek: 2, startTime: '11:00', endTime: '12:30', room: 'SciTech Lab 4' },
          { dayOfWeek: 4, startTime: '11:00', endTime: '12:30', room: 'SciTech Lab 4' },
        ],
      },
      assignments: {
        create: [
          {
            title: 'B+ Tree Buffer Pool Manager in C++',
            description: 'Implement LRU-K cache eviction and concurrency latching',
            dueDate: new Date(Date.now() + 9 * 24 * 60 * 60 * 1000),
            type: 'PROJECT',
            weight: 25.0,
            status: 'IN_PROGRESS',
            maxGrade: 100.0,
          },
        ],
      },
      exams: {
        create: [
          {
            title: 'Database Architecture Final Exam',
            examDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
            startTime: '14:00',
            examType: 'FINAL',
            weight: 40.0,
            maxGrade: 100.0,
          },
        ],
      },
      attendances: {
        create: [
          { date: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000), status: 'PRESENT' },
        ],
      },
    },
  });

  // ==========================================
  // 7. GOALS & MILESTONES
  // ==========================================
  console.log('🎯 Seeding Goals, Milestones & CheckIns...');
  const goal1 = await prisma.goal.create({
    data: {
      title: 'Publish HabOS v1.0 Production Release',
      description: 'Deliver the full personal life operating system with web, desktop and mobile readiness',
      targetDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
      priority: 'CRITICAL',
      category: 'CAREER',
      status: 'IN_PROGRESS',
      progress: 65.0,
      userId: user.id,
      milestones: {
        create: [
          {
            title: 'Complete All 24 Backend API Modules with 100% Swagger Specs',
            status: 'COMPLETED',
            isCompleted: true,
            order: 1.0,
            weight: 1.0,
          },
          {
            title: 'Implement Full Habits & Routine Sequential Experience in Flutter',
            status: 'COMPLETED',
            isCompleted: true,
            order: 2.0,
            weight: 1.0,
          },
          {
            title: 'Deploy Production Cluster with Postgres & Redis Caching',
            status: 'IN_PROGRESS',
            isCompleted: false,
            order: 3.0,
            weight: 1.0,
            targetDate: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000),
          },
        ],
      },
      checkIns: {
        create: [
          {
            date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
            confidence: 'ON_TRACK',
            note: 'Architecture is solid; database connection upgraded to postgres owner.',
            userId: user.id,
          },
        ],
      },
    },
  });

  const goal2 = await prisma.goal.create({
    data: {
      title: 'Achieve 100kg Bench Press & 160kg Deadlift PR',
      description: 'Progressive overload training cycle with structured nutrition',
      targetDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
      priority: 'HIGH',
      category: 'HEALTH',
      status: 'IN_PROGRESS',
      progress: 85.0,
      targetAmount: 100.0,
      currentAmount: 95.0,
      userId: user.id,
      milestones: {
        create: [
          { title: 'Bench Press 90kg for 3 sets of 5', status: 'COMPLETED', isCompleted: true, order: 1.0 },
          { title: 'Bench Press 95kg for 2 clean paused reps', status: 'COMPLETED', isCompleted: true, order: 2.0 },
          { title: 'Hit 100kg 1RM milestone', status: 'IN_PROGRESS', isCompleted: false, order: 3.0 },
        ],
      },
    },
  });

  // ==========================================
  // 8. TASKS & DEPENDENCIES
  // ==========================================
  console.log('✅ Seeding Tasks & TaskDependencies...');
  const taskParent = await prisma.task.create({
    data: {
      title: 'Architect Real-Time Notification Pipeline',
      description: 'Setup background scheduler to dispatch exam reminders and streak preservation notifications',
      isCompleted: false,
      priority: 'HIGH',
      status: 'IN_PROGRESS',
      dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
      estimatedMinutes: 90,
      userId: user.id,
      projectId: project1.id,
      categoryId: categories['Backend & Cloud API'].id,
    },
  });

  const taskSub1 = await prisma.task.create({
    data: {
      title: 'Implement Cron Job for Daily Streak Decay & Freeze Protection',
      isCompleted: true,
      completedAt: new Date(),
      priority: 'HIGH',
      status: 'COMPLETED',
      parentTaskId: taskParent.id,
      userId: user.id,
      projectId: project1.id,
      categoryId: categories['Backend & Cloud API'].id,
    },
  });

  const taskSub2 = await prisma.task.create({
    data: {
      title: 'Add In-App Notification Dropdown with Unread Counter in Client',
      isCompleted: false,
      priority: 'MEDIUM',
      status: 'TODO',
      parentTaskId: taskParent.id,
      userId: user.id,
      projectId: project1.id,
      categoryId: categories['Frontend Engineering'].id,
    },
  });

  // Task Dependency: taskSub2 is blocked by taskSub1
  await prisma.taskDependency.create({
    data: {
      blockingTaskId: taskSub1.id,
      blockedTaskId: taskSub2.id,
    },
  });

  const taskStudy = await prisma.task.create({
    data: {
      title: 'Finish Raft Heartbeat Mechanism Lab',
      description: 'Implement election timer reset on valid AppendEntries RPC',
      isCompleted: false,
      priority: 'CRITICAL',
      status: 'IN_PROGRESS',
      dueDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
      estimatedMinutes: 60,
      userId: user.id,
      courseId: course1.id,
      categoryId: categories['Distributed Systems'].id,
    },
  });

  // Time entry and focus session linked to tasks
  await prisma.timeEntry.create({
    data: {
      startTime: new Date(Date.now() - 4000 * 1000),
      endTime: new Date(Date.now() - 1000 * 1000),
      duration: 3000,
      taskId: taskParent.id,
      userId: user.id,
    },
  });

  await prisma.focusSession.create({
    data: {
      startTime: new Date(Date.now() - 60 * 60 * 1000),
      endTime: new Date(),
      durationMinutes: 60,
      category: 'CODING',
      notes: 'Deep focus building HabOS routines engine',
      taskId: taskParent.id,
      userId: user.id,
    },
  });

  await prisma.focusSession.create({
    data: {
      startTime: new Date(Date.now() - 120 * 60 * 1000),
      endTime: new Date(Date.now() - 75 * 60 * 1000),
      durationMinutes: 45,
      category: 'STUDY',
      notes: 'Reviewing Paxos vs Raft consensus invariants',
      courseId: course1.id,
      userId: user.id,
    },
  });

  // ==========================================
  // 9. HABITS, LOGS, ROUTINES & CORRELATIONS
  // ==========================================
  console.log('🔥 Seeding Habits, 30-Day Logs, Routines & Correlations...');
  const habit1 = await prisma.habit.create({
    data: {
      name: 'Morning Hydration (750ml)',
      description: 'Drink a large glass of water with electrolytes right after waking up',
      frequency: 'DAILY',
      targetFrequencyCount: 1,
      targetFrequencyPeriod: 'DAY',
      targetType: 'CHECKBOX',
      targetValue: 1,
      reminderTime: '07:00',
      currentStreak: 14,
      longestStreak: 32,
      streakFreezes: 2,
      difficulty: 'TRIVIAL',
      weight: 0.5,
      isActive: true,
      categoryId: categories['Daily Habits'].id,
      userId: user.id,
    },
  });

  const habit2 = await prisma.habit.create({
    data: {
      name: 'Mindfulness Meditation',
      description: '10 minutes of non-judgmental breath focus and mental clarity',
      frequency: 'DAILY',
      targetFrequencyCount: 1,
      targetFrequencyPeriod: 'DAY',
      targetType: 'DURATION',
      targetValue: 10,
      reminderTime: '07:15',
      currentStreak: 9,
      longestStreak: 21,
      streakFreezes: 2,
      difficulty: 'EASY',
      weight: 0.8,
      isActive: true,
      categoryId: categories['Mindfulness & Mental'].id,
      userId: user.id,
    },
  });

  const habit3 = await prisma.habit.create({
    data: {
      name: 'Daily LeetCode Problem',
      description: 'Solve 1 Medium algorithm problem to keep problem-solving sharp',
      frequency: 'DAILY',
      targetFrequencyCount: 1,
      targetFrequencyPeriod: 'DAY',
      targetType: 'CHECKBOX',
      targetValue: 1,
      reminderTime: '08:00',
      currentStreak: 12,
      longestStreak: 28,
      streakFreezes: 1,
      difficulty: 'HARD',
      weight: 1.5,
      isActive: true,
      categoryId: categories['Daily Habits'].id,
      userId: user.id,
    },
  });

  const habit4 = await prisma.habit.create({
    data: {
      name: 'Technical Reading (30 mins)',
      description: 'Read system design papers or computer science literature',
      frequency: 'DAILY',
      targetFrequencyCount: 1,
      targetFrequencyPeriod: 'DAY',
      targetType: 'DURATION',
      targetValue: 30,
      reminderTime: '21:30',
      currentStreak: 7,
      longestStreak: 19,
      streakFreezes: 2,
      difficulty: 'MEDIUM',
      weight: 1.0,
      isActive: true,
      categoryId: categories['Daily Habits'].id,
      userId: user.id,
    },
  });

  const habit5 = await prisma.habit.create({
    data: {
      name: 'Strength Gym Workout',
      description: 'Heavy compound lifting session (Push, Pull, or Legs)',
      frequency: 'CUSTOM',
      targetFrequencyCount: 4,
      targetFrequencyPeriod: 'WEEK',
      targetType: 'CHECKBOX',
      targetValue: 1,
      currentStreak: 6,
      longestStreak: 14,
      streakFreezes: 2,
      difficulty: 'EPIC',
      weight: 2.0,
      isActive: true,
      categoryId: categories['Health & Fitness'].id,
      userId: user.id,
    },
  });

  // Seed 14 days of habit logs for realistic streak heatmaps
  const allHabits = [habit1, habit2, habit3, habit4, habit5];
  for (let i = 14; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dateOnly = new Date(d.getFullYear(), d.getMonth(), d.getDate());

    for (const h of allHabits) {
      // 85% completion rate
      const completed = (i + h.name.length) % 7 !== 0;
      await prisma.habitLog.create({
        data: {
          habitId: h.id,
          date: dateOnly,
          isCompleted: completed,
          value: h.targetValue,
          wasFrozen: false,
          notes: completed ? 'Completed on time' : null,
        },
      });
    }
  }

  // Create Routines bundling habits
  const routineMorning = await prisma.routine.create({
    data: {
      name: 'Morning Launchpad Ritual',
      description: 'Hydrate ➔ Meditate ➔ Solve LeetCode before starting work',
      icon: 'sunrise',
      color: '#F59E0B',
      targetTime: '07:00',
      userId: user.id,
      items: {
        create: [
          { habitId: habit1.id, order: 0 },
          { habitId: habit2.id, order: 1 },
          { habitId: habit3.id, order: 2 },
        ],
      },
    },
  });

  const routineEvening = await prisma.routine.create({
    data: {
      name: 'Evening Wind-Down & Read',
      description: 'Disconnect from screens, read technical literature, plan tomorrow',
      icon: 'moon',
      color: '#6366F1',
      targetTime: '21:30',
      userId: user.id,
      items: {
        create: [
          { habitId: habit4.id, order: 0 },
        ],
      },
    },
  });

  // Seed Habit Correlation Insights
  await prisma.habitCorrelation.create({
    data: {
      userId: user.id,
      habitAId: habit1.id,
      habitBId: habit2.id,
      correlationScore: 0.88,
      supportCount: 14,
      insightText: 'Drinking morning water increases your likelihood of completing meditation by 88%.',
    },
  });

  await prisma.habitCorrelation.create({
    data: {
      userId: user.id,
      habitAId: habit2.id,
      habitBId: habit3.id,
      correlationScore: 0.82,
      supportCount: 12,
      insightText: 'Meditation significantly improves focus, boosting LeetCode problem completion rate.',
    },
  });

  // ==========================================
  // 10. GYM & FITNESS: Exercises, Workouts, Sets, PRs, Templates & BodyMetrics
  // ==========================================
  console.log('🏋️  Seeding Gym Exercises, Workouts, Sets, PRs & BodyMetrics...');
  const exBench = await prisma.exercise.create({
    data: {
      name: 'Barbell Bench Press',
      category: 'CHEST',
      muscleGroup: 'CHEST',
      equipmentType: 'BARBELL',
      notes: 'Arch upper back, retract scapula, pause at chest level',
      userId: user.id,
    },
  });

  const exSquat = await prisma.exercise.create({
    data: {
      name: 'Barbell Back Squat',
      category: 'LEGS',
      muscleGroup: 'LEGS',
      equipmentType: 'BARBELL',
      notes: 'Hit parallel depth, drive through mid-foot',
      userId: user.id,
    },
  });

  const exDeadlift = await prisma.exercise.create({
    data: {
      name: 'Conventional Deadlift',
      category: 'BACK',
      muscleGroup: 'BACK',
      equipmentType: 'BARBELL',
      notes: 'Brace core with Valsalva maneuver, keep lats tight',
      userId: user.id,
    },
  });

  const exOverhead = await prisma.exercise.create({
    data: {
      name: 'Overhead Barbell Shoulder Press',
      category: 'SHOULDERS',
      muscleGroup: 'SHOULDERS',
      equipmentType: 'BARBELL',
      userId: user.id,
    },
  });

  await prisma.personalRecord.createMany({
    data: [
      { exerciseId: exBench.id, weightKg: 95.0, repetitions: 2, calculatedOneRepMax: 98.5, userId: user.id },
      { exerciseId: exSquat.id, weightKg: 130.0, repetitions: 3, calculatedOneRepMax: 138.0, userId: user.id },
      { exerciseId: exDeadlift.id, weightKg: 160.0, repetitions: 1, calculatedOneRepMax: 160.0, userId: user.id },
      { exerciseId: exOverhead.id, weightKg: 65.0, repetitions: 5, calculatedOneRepMax: 73.0, userId: user.id },
    ],
  });

  // Workout template
  const workoutTemplate = await prisma.workoutTemplate.create({
    data: {
      name: 'Push Hypertrophy & Power (Chest/Shoulders/Triceps)',
      description: 'Heavy bench press followed by incline dumbbell work and lateral delts',
      category: 'PPL',
      userId: user.id,
      exercises: {
        create: [
          { exerciseId: exBench.id, order: 1, targetSets: 4, targetReps: 6, targetRpe: 8.5 },
          { exerciseId: exOverhead.id, order: 2, targetSets: 3, targetReps: 8, targetRpe: 8.0 },
        ],
      },
    },
  });

  // Recent completed workout
  const workout = await prisma.workout.create({
    data: {
      name: 'Heavy Push Day - Chest & Delts',
      date: new Date(Date.now() - 24 * 60 * 60 * 1000),
      startTime: '18:00',
      durationMinutes: 65,
      notes: 'Strong bench sets! 92.5kg felt smooth and crisp.',
      isCompleted: true,
      userId: user.id,
      exercises: {
        create: [
          {
            exerciseId: exBench.id,
            order: 1,
            sets: {
              create: [
                { setNumber: 1, weightKg: 85.0, repetitions: 8, rpe: 7.5, rir: 2, isPR: false },
                { setNumber: 2, weightKg: 90.0, repetitions: 6, rpe: 8.5, rir: 1, isPR: false },
                { setNumber: 3, weightKg: 92.5, repetitions: 5, rpe: 9.0, rir: 0, isPR: true },
              ],
            },
          },
          {
            exerciseId: exOverhead.id,
            order: 2,
            sets: {
              create: [
                { setNumber: 1, weightKg: 55.0, repetitions: 8, rpe: 7.5, rir: 2 },
                { setNumber: 2, weightKg: 60.0, repetitions: 6, rpe: 8.5, rir: 1 },
              ],
            },
          },
        ],
      },
    },
  });

  // Body Metrics history
  const bodyMetricsData = [
    { daysAgo: 21, weight: 77.2, bodyFat: 14.5, chest: 104, waist: 82, arms: 38 },
    { daysAgo: 14, weight: 77.0, bodyFat: 14.2, chest: 104.5, waist: 81.5, arms: 38.2 },
    { daysAgo: 7, weight: 76.8, bodyFat: 14.0, chest: 105, waist: 81, arms: 38.5 },
    { daysAgo: 0, weight: 76.5, bodyFat: 13.8, chest: 105.2, waist: 80.5, arms: 38.8 },
  ];

  for (const bm of bodyMetricsData) {
    const d = new Date();
    d.setDate(d.getDate() - bm.daysAgo);
    await prisma.bodyMetric.create({
      data: {
        date: d,
        weightKg: bm.weight,
        bodyFatPercent: bm.bodyFat,
        chestCm: bm.chest,
        waistCm: bm.waist,
        armsCm: bm.arms,
        notes: 'Consistent lean bulk progression',
        userId: user.id,
      },
    });
  }

  // ==========================================
  // 11. PERSONAL FINANCE: Transactions & Budgets
  // ==========================================
  console.log('💰 Seeding Transactions & Budgets...');
  const now = new Date();
  const currentMonth = now.getMonth() + 1;
  const currentYear = now.getFullYear();

  await prisma.budget.createMany({
    data: [
      {
        monthlyLimit: 400.0,
        month: currentMonth,
        year: currentYear,
        categoryId: categories['Food & Groceries'].id,
        userId: user.id,
      },
      {
        monthlyLimit: 120.0,
        month: currentMonth,
        year: currentYear,
        categoryId: categories['Tech & Subscriptions'].id,
        userId: user.id,
      },
      {
        monthlyLimit: 150.0,
        month: currentMonth,
        year: currentYear,
        categoryId: categories['Gym & Sports Gear'].id,
        userId: user.id,
      },
    ],
  });

  const transactionsData = [
    { amount: 3500.0, type: 'INCOME', desc: 'Software Engineer Monthly Salary', source: 'SALARY', cat: categories['Income & Freelance'].id, daysAgo: 1 },
    { amount: 450.0, type: 'INCOME', desc: 'Full-Stack Consulting Project Milestone', source: 'FREELANCE', cat: categories['Income & Freelance'].id, daysAgo: 5 },
    { amount: 68.5, type: 'EXPENSE', desc: 'Weekly Organic Groceries & High-Protein Meal Prep', source: 'BANK', cat: categories['Food & Groceries'].id, daysAgo: 2 },
    { amount: 18.0, type: 'EXPENSE', desc: 'GitHub Copilot & DigitalOcean Cloud Server', source: 'BANK', cat: categories['Tech & Subscriptions'].id, daysAgo: 3 },
    { amount: 20.0, type: 'EXPENSE', desc: 'ChatGPT Plus Subscription', source: 'BANK', cat: categories['Tech & Subscriptions'].id, daysAgo: 4 },
    { amount: 55.0, type: 'EXPENSE', desc: 'Whey Isolate Protein Powder & Creatine Monohydrate', source: 'BANK', cat: categories['Gym & Sports Gear'].id, daysAgo: 6 },
  ];

  for (const tx of transactionsData) {
    const d = new Date();
    d.setDate(d.getDate() - tx.daysAgo);
    await prisma.transaction.create({
      data: {
        amount: tx.amount,
        type: tx.type,
        date: d,
        description: tx.desc,
        source: tx.source,
        categoryId: tx.cat,
        userId: user.id,
      },
    });
  }

  // ==========================================
  // 12. SCHEDULE & GOOGLE CALENDAR
  // ==========================================
  console.log('📅 Seeding ScheduleEvents & Calendar Sync...');
  await prisma.googleCalendarSync.create({
    data: {
      userId: user.id,
      calendarId: 'primary',
      syncToken: 'mock_google_calendar_sync_token_2026',
      lastSyncedAt: new Date(),
    },
  });

  const todayBase = new Date();
  await prisma.scheduleEvent.createMany({
    data: [
      {
        title: 'Daily Standup & Sprint Planning',
        description: 'Review PRs, blockers, and weekly sprint goals',
        location: 'Google Meet',
        color: '#3B82F6',
        startTime: new Date(todayBase.getFullYear(), todayBase.getMonth(), todayBase.getDate(), 10, 0),
        endTime: new Date(todayBase.getFullYear(), todayBase.getMonth(), todayBase.getDate(), 10, 30),
        isRecurring: true,
        recurrenceRule: 'DAILY',
        userId: user.id,
      },
      {
        title: 'CS441 Distributed Systems Lecture',
        description: 'Topic: Consensus, Byzantine Fault Tolerance, and Paxos',
        location: 'Hall B-201',
        color: '#8B5CF6',
        startTime: new Date(todayBase.getFullYear(), todayBase.getMonth(), todayBase.getDate(), 14, 0),
        endTime: new Date(todayBase.getFullYear(), todayBase.getMonth(), todayBase.getDate(), 15, 30),
        userId: user.id,
      },
      {
        title: 'Gym Session: Heavy Push Day',
        description: 'Barbell Bench Press, Incline Dumbbell Press, Lateral Raises',
        location: 'Metropolis Fitness Club',
        color: '#EF4444',
        startTime: new Date(todayBase.getFullYear(), todayBase.getMonth(), todayBase.getDate(), 18, 0),
        endTime: new Date(todayBase.getFullYear(), todayBase.getMonth(), todayBase.getDate(), 19, 15),
        userId: user.id,
      },
    ],
  });

  // ==========================================
  // 13. KNOWLEDGE VAULT: Notes & Bidirectional NoteLinks
  // ==========================================
  console.log('🧠 Seeding Knowledge Vault Notes & NoteLinks...');
  const note1 = await prisma.vaultNote.create({
    data: {
      title: 'CAP Theorem and Trade-Offs in Distributed Architectures',
      content: `# CAP Theorem\n\nIn any asynchronous network subjected to partitions:\n- **Consistency**: Every read receives the most recent write.\n- **Availability**: Every non-failing node returns a response.\n- **Partition Tolerance**: System functions despite network packet drops.\n\nIn modern cloud engineering, network partitions are inevitable (*P is non-negotiable*), forcing architects to choose between **CP** and **AP**.`,
      tags: ['system-design', 'distributed-systems', 'architecture'],
      isMistakeSolution: false,
      codeSnippets: [
        {
          language: 'python',
          description: 'Quorum consistency check calculation',
          code: 'def is_strictly_consistent(N, W, R):\n    return (W + R) > N',
        },
      ],
      categoryId: categories['CS Architecture Vault'].id,
      courseId: course1.id,
      userId: user.id,
    },
  });

  const note2 = await prisma.vaultNote.create({
    data: {
      title: 'Raft Consensus Algorithm Internals',
      content: `# Raft Consensus\n\nDesigned for understandability compared to Paxos.\n\nKey Subproblems:\n1. **Leader Election** (Heartbeat timeouts 150-300ms)\n2. **Log Replication** (Leader appends entries)\n3. **Safety** (Election restriction: candidates must have up-to-date logs)\n\nLinks with [[CAP Theorem and Trade-Offs in Distributed Architectures]].`,
      tags: ['consensus', 'distributed-systems', 'go'],
      isMistakeSolution: false,
      categoryId: categories['CS Architecture Vault'].id,
      courseId: course1.id,
      userId: user.id,
    },
  });

  const note3 = await prisma.vaultNote.create({
    data: {
      title: 'Common Mistake: Refresh Token Race Condition in Flutter Dio',
      content: `# Token Refresh Mutex Pattern\n\n### Problem\nWhen multiple concurrent HTTP requests receive 401 simultaneously, multiple parallel calls trigger refresh endpoints, causing rotation invalidation.\n\n### Solution\nUse a single-flight mutex / lock in Dio error interceptor to queue pending requests while token renewal executes once.`,
      tags: ['flutter', 'dio', 'security', 'bugfix'],
      isMistakeSolution: true,
      categoryId: categories['CS Architecture Vault'].id,
      userId: user.id,
    },
  });

  // Bidirectional NoteLink between note1 and note2
  await prisma.noteLink.create({
    data: {
      sourceNoteId: note1.id,
      targetNoteId: note2.id,
    },
  });

  // ==========================================
  // 14. NOTIFICATIONS
  // ==========================================
  console.log('🔔 Seeding Notifications...');
  await prisma.notification.createMany({
    data: [
      {
        title: '🔥 Impressive Consistency!',
        message: 'You have maintained your Morning Hydration streak for 14 straight days!',
        type: 'STREAK_ALERT',
        isRead: false,
        userId: user.id,
      },
      {
        title: '⏰ Exam Approaching',
        message: 'Distributed Systems Midterm Exam is scheduled in 18 days.',
        type: 'EXAM_REMINDER',
        isRead: false,
        scheduledFor: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000),
        userId: user.id,
      },
      {
        title: '🏋️ Workout Reminder',
        message: 'Time for Heavy Push Day at 18:00 today.',
        type: 'WORKOUT_REMINDER',
        isRead: true,
        sentAt: new Date(Date.now() - 3 * 60 * 60 * 1000),
        userId: user.id,
      },
      {
        title: '💰 Monthly Budget Update',
        message: 'Food & Groceries budget is at 17% utilization with 26 days remaining.',
        type: 'BUDGET_ALERT',
        isRead: true,
        userId: user.id,
      },
    ],
  });

  console.log('═══════════════════════════════════════════════════════════');
  console.log('🎉 ALL 45 TABLES SEEDED SUCCESSFULLY WITH RICH DEMO DATA!');
  console.log('👤 Login Credentials:');
  console.log('   Email:    demo@habos.dev');
  console.log('   Password: Habos@2026');
  console.log('═══════════════════════════════════════════════════════════');
}

main()
  .catch((e) => {
    console.error('❌ Error during comprehensive seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
