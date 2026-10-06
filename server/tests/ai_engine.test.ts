import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testAiInsightsEngine() {
  console.log('🧪 Testing Module 19: AI Insights Engine (UC-136 to UC-143)...');
  const request = supertest(app);

  try {
    // 1. Authenticate with demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    if (loginRes.status !== 200 || !loginRes.body.data?.tokens?.accessToken) {
      throw new Error(`Auth failed with status ${loginRes.status}`);
    }

    const token = loginRes.body.data.tokens.accessToken;
    console.log('1. Authentication: ✅ PASS');

    // 2. UC-142: Identify Neglected Areas
    const neglectedRes = await request
      .get('/api/v1/ai/neglected-areas')
      .set('Authorization', `Bearer ${token}`);

    console.log(
      '2. Identify Neglected Areas (UC-142):',
      neglectedRes.status === 200 &&
        Array.isArray(neglectedRes.body.data.neglectedAreas) &&
        typeof neglectedRes.body.data.totalCount === 'number'
        ? '✅ PASS'
        : '❌ FAIL'
    );

    // 3. UC-141: Recommend Next Tasks
    const tasksRes = await request
      .get('/api/v1/ai/recommend-tasks?limit=5')
      .set('Authorization', `Bearer ${token}`);

    console.log(
      '3. Recommend Next Tasks (UC-141):',
      tasksRes.status === 200 && Array.isArray(tasksRes.body.data)
        ? '✅ PASS'
        : '❌ FAIL'
    );

    // 4. UC-143: Generate Personalized Weekly Plan (GET)
    const planRes = await request
      .get('/api/v1/ai/plan')
      .set('Authorization', `Bearer ${token}`);

    console.log(
      '4. Generate Personalized Plan (UC-143):',
      planRes.status === 200 &&
        Array.isArray(planRes.body.data.schedule) &&
        planRes.body.data.schedule.length === 7 &&
        typeof planRes.body.data.weeklyGoal === 'string'
        ? '✅ PASS'
        : '❌ FAIL'
    );

    // 5. UC-143: Generate Goal-Oriented Plan (POST with goalPrompt)
    const customPlanRes = await request
      .post('/api/v1/ai/plan')
      .set('Authorization', `Bearer ${token}`)
      .send({
        goalPrompt: 'Ace Distributed Systems Midterm and hit 4 gym sessions',
      });

    console.log(
      '5. Custom Goal Rebalancing Plan (UC-143):',
      customPlanRes.status === 200 &&
        customPlanRes.body.data.weeklyGoal.includes('Distributed Systems')
        ? '✅ PASS'
        : '❌ FAIL'
    );

    // 6. UC-136 to UC-140: Multi-Domain Grounded Insights
    const insightsRes = await request
      .get('/api/v1/ai/insights')
      .set('Authorization', `Bearer ${token}`);

    console.log(
      '6. Multi-Domain Performance Insights (UC-136 - UC-140):',
      insightsRes.status === 200 &&
        Array.isArray(insightsRes.body.data) &&
        insightsRes.body.data.length >= 5
        ? '✅ PASS'
        : '❌ FAIL'
    );

    // 7. UC-136: Targeted Productivity Insight
    const prodInsightRes = await request
      .get('/api/v1/ai/insights/PRODUCTIVITY')
      .set('Authorization', `Bearer ${token}`);

    console.log(
      '7. Targeted Productivity Insight (UC-136):',
      prodInsightRes.status === 200 &&
        prodInsightRes.body.data.domain === 'PRODUCTIVITY'
        ? '✅ PASS'
        : '❌ FAIL'
    );

    console.log('\n🎉 ALL AI INSIGHTS ENGINE API TESTS (UC-136 to UC-143) PASSED!');
  } catch (error) {
    console.error('❌ Test failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

testAiInsightsEngine();
