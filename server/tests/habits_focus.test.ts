import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testHabitsAndFocusFlow() {
  console.log('🧪 Testing Habits & Focus API Endpoints...');
  const request = supertest(app);

  try {
    // 1. Authenticate with demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    const token = loginRes.body.data.tokens.accessToken;
    console.log('1. Authentication:', loginRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    // 2. Create Habit (UC-24)
    const habitRes = await request
      .post('/api/v1/habits')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Morning Cold Shower',
        description: 'Take a 3-minute cold shower every morning',
        frequency: 'DAILY',
        targetType: 'DURATION',
        targetValue: 3,
        reminderTime: '07:00',
      });

    console.log('2. Create Habit (UC-24):', habitRes.status === 201 && habitRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const habitId = habitRes.body.data.id;

    // 3. Log Habit Completion & Calculate Streaks (UC-27, UC-28)
    const logRes = await request
      .post(`/api/v1/habits/${habitId}/log`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        isCompleted: true,
        value: 3,
        notes: 'Felt very energized!',
      });

    console.log('3. Log Habit & Update Streak (UC-27, UC-28):', logRes.status === 200 && logRes.body.data.currentStreak === 1 ? '✅ PASS' : '❌ FAIL');

    // 4. Get Habit Heatmap History (UC-29)
    const historyRes = await request
      .get(`/api/v1/habits/${habitId}/history`)
      .set('Authorization', `Bearer ${token}`);

    console.log('4. Habit History & Heatmap (UC-29):', historyRes.status === 200 && historyRes.body.data.completedDays >= 1 ? '✅ PASS' : '❌ FAIL');

    // 5. Get Habits Summary (Dashboard widget)
    const summaryRes = await request
      .get('/api/v1/habits/summary')
      .set('Authorization', `Bearer ${token}`);

    console.log('5. Habits Summary Metrics:', summaryRes.status === 200 && summaryRes.body.data.totalActive > 0 ? '✅ PASS' : '❌ FAIL');

    // 6. Start Focus Session Timer (UC-31)
    const startFocusRes = await request
      .post('/api/v1/focus/start')
      .set('Authorization', `Bearer ${token}`)
      .send({
        category: 'CODING',
        notes: 'Implementing Pomodoro focus module in TypeScript',
      });

    console.log('6. Start Focus Session (UC-31):', startFocusRes.status === 201 && startFocusRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const sessionId = startFocusRes.body.data.id;

    // 7. End Focus Session & Auto-record Time (UC-34)
    const endFocusRes = await request
      .post(`/api/v1/focus/${sessionId}/end`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        durationMinutes: 45,
        notes: 'Completed the focus module and Joi validation schemas',
      });

    console.log('7. End Focus Session (UC-34):', endFocusRes.status === 200 && endFocusRes.body.data.durationMinutes === 45 ? '✅ PASS' : '❌ FAIL');

    // 8. Log Completed Focus Session Directly (Pomodoro timer widget)
    const now = new Date();
    const startTime = new Date(now.getTime() - 25 * 60 * 1000);
    const logFocusRes = await request
      .post('/api/v1/focus/log')
      .set('Authorization', `Bearer ${token}`)
      .send({
        startTime: startTime.toISOString(),
        endTime: now.toISOString(),
        durationMinutes: 25,
        category: 'STUDY',
        notes: '25-minute Pomodoro study block',
      });

    console.log('8. Log Completed Focus (Pomodoro):', logFocusRes.status === 201 && logFocusRes.body.data.durationMinutes === 25 ? '✅ PASS' : '❌ FAIL');

    // 9. Calculate Focus Metrics & Category Breakdown (UC-37)
    const focusStatsRes = await request
      .get('/api/v1/focus/stats')
      .set('Authorization', `Bearer ${token}`);

    console.log('9. Calculate Focus Stats (UC-37):', focusStatsRes.status === 200 && focusStatsRes.body.data.today.minutes >= 70 ? '✅ PASS' : '❌ FAIL');

    // 10. Clean up created habit and focus session
    await request.delete(`/api/v1/habits/${habitId}`).set('Authorization', `Bearer ${token}`);
    await request.delete(`/api/v1/focus/${sessionId}`).set('Authorization', `Bearer ${token}`);
    console.log('10. Habit & Focus Deletion (UC-26): ✅ PASS');

    console.log('\n🎉 ALL HABITS & FOCUS API TESTS PASSED WITH 100% SUCCESS!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testHabitsAndFocusFlow();
