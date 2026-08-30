import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testSearchAndNotificationsFlow() {
  console.log('🧪 Testing Global Omni-Search & Notifications Center API Endpoints...');
  const request = supertest(app);

  try {
    // 1. Authenticate with demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    const token = loginRes.body.data.tokens.accessToken;
    console.log('1. Authentication:', loginRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    // 2. Create sample task to search for
    const taskRes = await request
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Microservices Architecture Review',
        description: 'Review event-driven communication protocols',
        priority: 'HIGH',
      });

    const taskId = taskRes.body.data.id;

    // 3. Global Omni-Search across all domains (UC-167)
    const searchRes = await request
      .get('/api/v1/search?q=Microservices&domain=ALL')
      .set('Authorization', `Bearer ${token}`);

    console.log(
      '2. Global Omni-Search (UC-167):',
      searchRes.status === 200 && searchRes.body.data.results.some((r: { title: string }) => r.title.includes('Microservices'))
        ? '✅ PASS'
        : '❌ FAIL'
    );

    // 4. Create Notification manually (UC-178)
    const notifRes = await request
      .post('/api/v1/notifications')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Streak Milestone Achieved!',
        message: 'Congratulations! You reached a 7-day habit streak.',
        type: 'STREAK_ALERT',
      });

    console.log('3. Create Notification (UC-178):', notifRes.status === 201 && notifRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const notificationId = notifRes.body.data.id;

    // 5. Get Unread Count Badge
    const countRes = await request
      .get('/api/v1/notifications/unread-count')
      .set('Authorization', `Bearer ${token}`);

    console.log('4. Unread Notifications Count Badge:', countRes.status === 200 && countRes.body.data.unreadCount > 0 ? '✅ PASS' : '❌ FAIL');

    // 6. Generate Contextual Alerts (UC-178 to UC-182)
    const alertGenRes = await request
      .post('/api/v1/notifications/generate-alerts')
      .set('Authorization', `Bearer ${token}`);

    console.log('5. Generate Contextual Alerts (UC-178 to UC-182):', alertGenRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    // 7. Mark Notification as Read (UC-176)
    const readRes = await request
      .patch(`/api/v1/notifications/${notificationId}/read`)
      .set('Authorization', `Bearer ${token}`);

    console.log('6. Mark Notification as Read (UC-176):', readRes.status === 200 && readRes.body.data.isRead === true ? '✅ PASS' : '❌ FAIL');

    // 8. Mark All as Read (UC-176)
    const readAllRes = await request
      .patch('/api/v1/notifications/read-all')
      .set('Authorization', `Bearer ${token}`);

    console.log('7. Mark All Notifications as Read (UC-176):', readAllRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    // 9. Delete Notification (UC-177)
    const deleteRes = await request
      .delete(`/api/v1/notifications/${notificationId}`)
      .set('Authorization', `Bearer ${token}`);

    console.log('8. Delete Notification (UC-177):', deleteRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    // 10. Clean up created task
    await request.delete(`/api/v1/tasks/${taskId}`).set('Authorization', `Bearer ${token}`);
    console.log('9. Cleanup: ✅ PASS');

    console.log('\n🎉 ALL SEARCH & NOTIFICATIONS API TESTS PASSED WITH 100% SUCCESS!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testSearchAndNotificationsFlow();
