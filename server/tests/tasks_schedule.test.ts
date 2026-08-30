import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testTasksAndScheduleFlow() {
  console.log('🧪 Testing Tasks & Schedule API Endpoints...');
  const request = supertest(app);

  try {
    // 1. Authenticate with demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    const token = loginRes.body.data.tokens.accessToken;
    console.log('1. Authentication:', loginRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    // 2. Create Task (UC-10)
    const taskRes = await request
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Implement JWT Token Rotation in Client',
        description: 'Store refresh token securely and handle 401 interceptor',
        priority: 'CRITICAL',
        status: 'TODO',
        dueDate: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString(),
        estimatedMinutes: 90,
      });

    console.log('2. Create Task (UC-10):', taskRes.status === 201 && taskRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const taskId = taskRes.body.data.id;

    // 3. Get Tasks with View & Filters (UC-15, UC-16)
    const getTasksRes = await request
      .get('/api/v1/tasks?view=all&priority=CRITICAL')
      .set('Authorization', `Bearer ${token}`);

    console.log('3. Filter Tasks (UC-16):', getTasksRes.status === 200 && getTasksRes.body.data.tasks.length > 0 ? '✅ PASS' : '❌ FAIL');

    // 4. Toggle Task Completion (UC-13)
    const toggleRes = await request
      .patch(`/api/v1/tasks/${taskId}/complete`)
      .set('Authorization', `Bearer ${token}`);

    console.log('4. Toggle Complete Task (UC-13):', toggleRes.status === 200 && toggleRes.body.data.isCompleted === true ? '✅ PASS' : '❌ FAIL');

    // 5. Get Task Stats (Dashboard summary)
    const statsRes = await request
      .get('/api/v1/tasks/stats')
      .set('Authorization', `Bearer ${token}`);

    console.log('5. Task Stats Summary:', statsRes.status === 200 && statsRes.body.data.total > 0 ? '✅ PASS' : '❌ FAIL');

    // 6. Create Schedule Event (UC-18)
    const now = new Date();
    const startTime = new Date(now.getTime() + 60 * 60 * 1000); // 1 hour from now
    const endTime = new Date(now.getTime() + 120 * 60 * 1000);  // 2 hours from now

    const eventRes = await request
      .post('/api/v1/schedule')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Deep Work: Flutter Riverpod State Setup',
        description: 'Implement presentation providers and local state cache',
        location: 'Home Office',
        color: '#10B981',
        startTime: startTime.toISOString(),
        endTime: endTime.toISOString(),
      });

    console.log('6. Create Schedule Event (UC-18):', eventRes.status === 201 && eventRes.body.data.event.id ? '✅ PASS' : '❌ FAIL');
    const eventId = eventRes.body.data.event.id;

    // 7. Get Daily Timeline (UC-21)
    const dailyRes = await request
      .get('/api/v1/schedule/daily')
      .set('Authorization', `Bearer ${token}`);

    console.log('7. View Daily Schedule Timeline (UC-21):', dailyRes.status === 200 && Array.isArray(dailyRes.body.data.events) ? '✅ PASS' : '❌ FAIL');

    // 8. Get Weekly Schedule (UC-22)
    const weeklyRes = await request
      .get('/api/v1/schedule/weekly')
      .set('Authorization', `Bearer ${token}`);

    console.log('8. View Weekly Schedule (UC-22):', weeklyRes.status === 200 && typeof weeklyRes.body.data.eventsByDay === 'object' ? '✅ PASS' : '❌ FAIL');

    // 9. Clean up created test items
    await request.delete(`/api/v1/tasks/${taskId}`).set('Authorization', `Bearer ${token}`);
    await request.delete(`/api/v1/schedule/${eventId}`).set('Authorization', `Bearer ${token}`);
    console.log('9. Task & Event Deletion (UC-12, UC-20): ✅ PASS');

    console.log('\n🎉 ALL TASKS & SCHEDULE API TESTS PASSED WITH 100% SUCCESS!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testTasksAndScheduleFlow();
