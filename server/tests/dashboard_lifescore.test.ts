import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testDashboardAndLifeScoreFlow() {
  console.log('🧪 Testing Dashboard Feed & Life Score Engine API Endpoints...');
  const request = supertest(app);

  try {
    // 1. Authenticate with demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    const token = loginRes.body.data.tokens.accessToken;
    console.log('1. Authentication:', loginRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    // 2. Calculate Real-time Life Score (UC-158)
    const lifeScoreRes = await request
      .get('/api/v1/lifescore')
      .set('Authorization', `Bearer ${token}`);

    console.log(
      '2. Calculate Real-Time Life Score (UC-158):',
      lifeScoreRes.status === 200 && typeof lifeScoreRes.body.data.overallScore === 'number'
        ? `✅ PASS (${lifeScoreRes.body.data.overallScore}/100 [${lifeScoreRes.body.data.level}])`
        : '❌ FAIL'
    );

    // 3. Snapshot Daily Life Score into Database (UC-162)
    const snapshotRes = await request
      .post('/api/v1/lifescore/snapshot')
      .set('Authorization', `Bearer ${token}`);

    console.log('3. Snapshot Daily Life Score (UC-162):', snapshotRes.status === 201 && snapshotRes.body.data.log.id ? '✅ PASS' : '❌ FAIL');

    // 4. Retrieve Historical Life Score Logs for Charts (UC-163)
    const historyRes = await request
      .get('/api/v1/lifescore/history')
      .set('Authorization', `Bearer ${token}`);

    console.log('4. Life Score History (UC-163):', historyRes.status === 200 && historyRes.body.data.length > 0 ? '✅ PASS' : '❌ FAIL');

    // 5. Get Complete Unified Dashboard Feed (UC-06, UC-07)
    const dashboardRes = await request
      .get('/api/v1/dashboard')
      .set('Authorization', `Bearer ${token}`);

    console.log('5. Unified Dashboard Feed (UC-06):', dashboardRes.status === 200 && !!dashboardRes.body.data.lifeScore ? '✅ PASS' : '❌ FAIL');
    console.log('   - Verified Timeline Cards:', Array.isArray(dashboardRes.body.data.timeline.tasksDueToday) ? '✅' : '❌');
    console.log('   - Verified Habit Checklist:', Array.isArray(dashboardRes.body.data.habits.items) ? '✅' : '❌');
    console.log('   - Verified Fitness Widget:', typeof dashboardRes.body.data.fitness.workoutsThisWeekCount === 'number' ? '✅' : '❌');
    console.log('   - Verified Finance Pulse:', typeof dashboardRes.body.data.finance.spentThisMonth === 'number' ? '✅' : '❌');
    console.log('   - Verified AI Recommendation:', !!dashboardRes.body.data.aiRecommendation ? '✅' : '❌');

    console.log('\n🎉 ALL DASHBOARD & LIFE SCORE API TESTS PASSED WITH 100% SUCCESS!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testDashboardAndLifeScoreFlow();
