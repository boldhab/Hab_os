import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting HabOS database seed (TypeScript)...');

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
            'habits',
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
            finance: 0.15,
          },
        },
      },
    },
  });

  console.log(`👤 Demo user created/verified: ${user.email} (ID: ${user.id})`);

  // 2. Create Default Categories
  const defaultCategories = [
    { name: 'Frontend Engineering', color: '#3B82F6', icon: 'code', type: 'TASK' },
    { name: 'Backend & API', color: '#10B981', icon: 'server', type: 'TASK' },
    { name: 'University Study', color: '#8B5CF6', icon: 'book', type: 'TASK' },
    { name: 'Health & Fitness', color: '#EF4444', icon: 'heart', type: 'HABIT' },
    { name: 'Food & Dining', color: '#F59E0B', icon: 'utensils', type: 'FINANCE' },
    { name: 'Education & Books', color: '#6366F1', icon: 'graduation-cap', type: 'FINANCE' },
  ];

  for (const cat of defaultCategories) {
    await prisma.category.upsert({
      where: {
        userId_name_type: {
          userId: user.id,
          name: cat.name,
          type: cat.type,
        },
      },
      update: {},
      create: {
        ...cat,
        userId: user.id,
      },
    });
  }
  console.log('🏷️  Default categories seeded.');

  console.log('✨ TypeScript seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
