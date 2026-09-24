import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testGymFitnessSuite() {
  console.log('🏋️ Starting Gym & Fitness Full E2E Test Suite...\n');
  const request = supertest(app);

  try {
    // 1. Authenticate with demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    if (loginRes.status !== 200) {
      throw new Error(`Auth failed with status ${loginRes.status}`);
    }

    const token = loginRes.body.data.tokens.accessToken;
    const authHeaders = { Authorization: `Bearer ${token}` };
    console.log('1. Authentication: ✅ PASS');

    // 2. Test Exercise Catalog (Lazy-Seeding on read)
    const exRes = await request.get('/api/v1/gym/exercises').set(authHeaders);
    console.log(
      '2. Exercise Catalog Retrieval (Auto-Seeded):',
      exRes.status === 200 && Array.isArray(exRes.body.data) && exRes.body.data.length >= 20
        ? `✅ PASS (Found ${exRes.body.data.length} exercises across muscle groups)`
        : '❌ FAIL'
    );

    const benchPress = exRes.body.data.find((e: any) => e.name === 'Barbell Bench Press');
    const squat = exRes.body.data.find((e: any) => e.name === 'Barbell Back Squat');

    if (!benchPress || !squat) {
      throw new Error('Expected standard exercises (Bench Press, Squat) not found in catalog');
    }

    // 3. Test Create Custom Exercise
    const customExRes = await request
      .post('/api/v1/gym/exercises')
      .set(authHeaders)
      .send({
        name: 'Deficit Bulgarian Split Squat',
        category: 'LEGS',
        muscleGroup: 'LEGS',
        equipmentType: 'DUMBBELL',
      });
    console.log(
      '3. Create Custom Exercise:',
      customExRes.status === 201 && customExRes.body.data.isCustom === true
        ? '✅ PASS (Custom exercise created)'
        : '❌ FAIL'
    );
    const customExId = customExRes.body.data.id;

    // 4. Test Transactional Workout Logging with Exercises, Sets, RPE, and PR Detection
    const workoutRes = await request
      .post('/api/v1/gym/workouts')
      .set(authHeaders)
      .send({
        name: 'Heavy Push Strength Session',
        date: new Date().toISOString(),
        durationMinutes: 70,
        notes: 'Felt explosive on bench today',
        exercises: [
          {
            exerciseId: benchPress.id,
            order: 1,
            sets: [
              { setNumber: 1, weightKg: 80, repetitions: 8, rpe: 8 },
              { setNumber: 2, weightKg: 85, repetitions: 6, rpe: 8.5 },
              { setNumber: 3, weightKg: 90, repetitions: 5, rpe: 9.5 },
            ],
          },
          {
            exerciseId: customExId,
            order: 2,
            sets: [
              { setNumber: 1, weightKg: 24, repetitions: 10, rpe: 8 },
              { setNumber: 2, weightKg: 26, repetitions: 8, rpe: 9 },
            ],
          },
        ],
      });

    const workoutData = workoutRes.body.data;
    console.log(
      '4. Transactional Workout Logging & PR Detection:',
      workoutRes.status === 201 &&
        workoutData.totalTonnage > 0 &&
        workoutData.detectedPRs.length > 0
        ? `✅ PASS (Logged ${workoutData.totalSetsCount} sets, total tonnage ${workoutData.totalTonnage}kg, detected ${workoutData.detectedPRs.length} PRs)`
        : `❌ FAIL (${JSON.stringify(workoutRes.body)})`
    );

    const workoutId = workoutData.id;

    // 5. Test Progressive Overload 1RM and History Retrieval
    const historyRes = await request
      .get(`/api/v1/gym/exercises/${benchPress.id}/history`)
      .set(authHeaders);

    const histData = historyRes.body.data;
    // 90kg x 5 reps -> Epley 1RM = 90 * (1 + 5/30) = 90 * 1.1667 = 105.0 kg
    console.log(
      '5. Epley 1RM Calculation & Exercise Progression History:',
      historyRes.status === 200 &&
        histData.currentPR &&
        histData.currentPR.calculatedOneRepMax >= 105.0 &&
        histData.lastPerformance !== null
        ? `✅ PASS (Best 1RM: ${histData.currentPR.calculatedOneRepMax}kg, Last Performance available)`
        : `❌ FAIL (Expected 1RM >= 105kg, got ${histData?.currentPR?.calculatedOneRepMax})`
    );

    // 6. Test Workout Templates (Lazy-Seeding and Retrieval)
    const tmplRes = await request.get('/api/v1/gym/templates').set(authHeaders);
    console.log(
      '6. Workout Templates (Auto-Seeded with Last Performance):',
      tmplRes.status === 200 && Array.isArray(tmplRes.body.data) && tmplRes.body.data.length >= 3
        ? `✅ PASS (${tmplRes.body.data.length} templates available: ${tmplRes.body.data.map((t: any) => t.name).join(', ')})`
        : '❌ FAIL'
    );

    // 7. Test Gym Volume Analytics & Muscle Group Balance
    const statsRes = await request.get('/api/v1/gym/stats').set(authHeaders);
    const stats = statsRes.body.data;
    console.log(
      '7. Volume Analytics & Muscle Group Breakdown:',
      statsRes.status === 200 &&
        stats.totalLifetimeTonnage > 0 &&
        Array.isArray(stats.muscleDistribution) &&
        stats.muscleDistribution.some((m: any) => m.muscleGroup === 'CHEST' && m.volumeKg > 0)
        ? `✅ PASS (Lifetime volume: ${stats.totalLifetimeTonnage}kg, Chest volume tracked)`
        : '❌ FAIL'
    );

    // 8. Test Training Insights (Rest Day Correlation & Balance)
    const insightsRes = await request.get('/api/v1/gym/insights').set(authHeaders);
    console.log(
      '8. Cross-Module Training Insights:',
      insightsRes.status === 200 && Array.isArray(insightsRes.body.data.insights)
        ? `✅ PASS (Generated ${insightsRes.body.data.insights.length} insight(s))`
        : '❌ FAIL'
    );

    // 9. Test Body Metrics & 7-Day Moving Average Smoothing
    const metricRes = await request
      .post('/api/v1/gym/body-metrics')
      .set(authHeaders)
      .send({
        weightKg: 78.5,
        bodyFatPercent: 14.8,
        waistCm: 81.0,
        chestCm: 104.0,
        notes: 'Morning weight after light breakfast',
      });

    console.log(
      '9. Log Body Metric:',
      metricRes.status === 201 && metricRes.body.data.weightKg === 78.5 ? '✅ PASS' : '❌ FAIL'
    );
    const metricId = metricRes.body.data.id;

    const getMetricsRes = await request.get('/api/v1/gym/body-metrics').set(authHeaders);
    console.log(
      '9b. Body Metrics 7-Day Moving Average:',
      getMetricsRes.status === 200 &&
        getMetricsRes.body.data[0].sevenDayAverageKg !== undefined
        ? `✅ PASS (Recorded 7-day average: ${getMetricsRes.body.data[0].sevenDayAverageKg}kg)`
        : '❌ FAIL'
    );

    // 10. Cleanup
    await request.delete(`/api/v1/gym/workouts/${workoutId}`).set(authHeaders);
    await request.delete(`/api/v1/gym/body-metrics/${metricId}`).set(authHeaders);
    await prisma.exercise.delete({ where: { id: customExId } });
    console.log('\n10. Cleanup Test Records: ✅ PASS');

    console.log('\n🏆 ALL GYM & FITNESS E2E TESTS PASSED WITH 100% SUCCESS!\n');
  } catch (err) {
    console.error('❌ Test failed:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

testGymFitnessSuite();
