const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting HabOS database seed...');

  // 1. Create or upsert a demo user
  const hashedPassword = await bcrypt.hash('Habos@2026', 10);
  const demoEmail = 'demo@habos.dev';

  const user = await prisma.user.upsert({
    where: { email: demoEmail },
    update: {},
    create: {
      email: demoEmail,
      password: hashedPassword,
      name: 'HabOS Explorer',
      timezone: 'UTC',
      dateFormat: 'YYYY-MM-DD',
      preferences: {
        create: {
          dashboardModules: [
            'priorities',
            'life_score',
            'coding_stats',
            'study_timer',
            'gym_workout',
            'finance_summary',
            'habits'
          ],
          dailyCodingTargetMins: 120,
          dailyStudyTargetMins: 90,
          dailyReadingTargetMins: 30,
          weeklyGymTarget: 4,
          lifeScoreWeights: {
            tasks: 0.15,
            coding: 0.20,
            study: 0.20,
            gym: 0.15,
            habits: 0.15,
            finance: 0.15
          }
        }
      }
    }
  });

  console.log(`👤 Demo user created/verified: ${user.email} (ID: ${user.id})`);

  // 2. Create Default Categories
  const defaultCategories = [
    { name: 'Frontend Engineering', color: '#3B82F6', icon: 'code', type: 'TASK' },
    { name: 'Backend & API', color: '#10B981', icon: 'server', type: 'TASK' },
    { name: 'University Study', color: '#8B5CF6', icon: 'book', type: 'TASK' },
    { name: 'Health & Fitness', color: '#EF4444', icon: 'heart', type: 'HABIT' },
    { name: 'Food & Dining', color: '#F59E0B', icon: 'utensils', type: 'FINANCE' },
    { name: 'Education & Books', color: '#6366F1', icon: 'graduation-cap', type: 'FINANCE' }
  ];

  for (const cat of defaultCategories) {
    await prisma.category.upsert({
      where: {
        userId_name_type: {
          userId: user.id,
          name: cat.name,
          type: cat.type
        }
      },
      update: {},
      create: {
        ...cat,
        userId: user.id
      }
    });
  }
  console.log('🏷️  Default categories seeded.');

  // 3. Create Sample Project & Features
  const sampleProject = await prisma.project.create({
    data: {
      title: 'HabOS Core Platform',
      description: 'Modular personal life operating system with Flutter & Node/Prisma',
      repoUrl: 'https://github.com/habos/habos-core',
      status: 'IN_PROGRESS',
      progress: 45.0,
      technologies: ['Flutter', 'Express', 'Prisma', 'PostgreSQL', 'Riverpod'],
      color: '#3B82F6',
      userId: user.id,
      features: {
        create: [
          { name: 'Authentication & JWT Token Rotation', status: 'COMPLETED', priority: 'HIGH' },
          { name: 'Dashboard Life Score Engine', status: 'IN_PROGRESS', priority: 'HIGH' },
          { name: 'GitHub Sync Webhook', status: 'TODO', priority: 'MEDIUM' }
        ]
      },
      bugs: {
        create: [
          {
            title: 'Fix token refresh race condition',
            description: 'Simultaneous API calls trigger multiple refresh token invalidations',
            priority: 'HIGH',
            status: 'OPEN'
          }
        ]
      }
    }
  });
  console.log(`💻 Sample project created: ${sampleProject.title}`);

  // 4. Create Sample Tasks
  await prisma.task.createMany({
    data: [
      {
        title: 'Review Advanced Database exam materials',
        description: 'Read chapters 4 & 5 on B-Trees and Distributed Transactions',
        priority: 'HIGH',
        status: 'TODO',
        dueDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
        estimatedMinutes: 60,
        userId: user.id,
        projectId: sampleProject.id
      },
      {
        title: 'Complete push workout (Chest & Triceps)',
        description: 'Bench press 4x8, Incline dumbbell press 3x10, Tricep pushdowns 3x12',
        priority: 'MEDIUM',
        status: 'TODO',
        dueDate: new Date(),
        estimatedMinutes: 45,
        userId: user.id
      }
    ]
  });
  console.log('✅ Sample tasks seeded.');

  // 5. Create Sample Habits
  const habit1 = await prisma.habit.create({
    data: {
      name: 'Read Technical Book',
      description: 'Read at least 15 pages of system design or CS theory',
      frequency: 'DAILY',
      targetType: 'DURATION',
      targetValue: 30,
      currentStreak: 12,
      longestStreak: 21,
      userId: user.id
    }
  });

  const habit2 = await prisma.habit.create({
    data: {
      name: 'Daily LeetCode Problem',
      description: 'Solve 1 medium algorithm problem every morning',
      frequency: 'DAILY',
      targetType: 'CHECKBOX',
      targetValue: 1,
      currentStreak: 5,
      longestStreak: 18,
      userId: user.id
    }
  });
  console.log('🔥 Sample habits and streaks seeded.');

  // 6. Create Initial Life Score
  await prisma.lifeScoreLog.create({
    data: {
      overallScore: 82.5,
      taskScore: 85.0,
      codingScore: 90.0,
      studyScore: 75.0,
      gymScore: 80.0,
      habitScore: 88.0,
      financeScore: 78.0,
      userId: user.id
    }
  });
  console.log('📊 Initial Life Score log created.');

  console.log('✨ Seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
