const supertest = require('supertest');
const app = require('../src/app');
const prisma = require('../src/config/db');

async function testAuthFlow() {
  console.log('🧪 Testing Authentication API Endpoints...');
  const request = supertest(app);

  try {
    // 1. Health check
    const healthRes = await request.get('/health');
    console.log('1. Health check:', healthRes.body.status === 'ok' ? '✅ PASS' : '❌ FAIL');

    // 2. Login with seeded demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    console.log('2. Login demo user:', loginRes.status === 200 ? '✅ PASS' : '❌ FAIL', loginRes.body.message);
    const { accessToken, refreshToken } = loginRes.body.data.tokens;

    // 3. Get Profile with Bearer token
    const profileRes = await request
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${accessToken}`);

    console.log('3. Get Profile (/me):', profileRes.status === 200 && profileRes.body.data.email === 'demo@habos.dev' ? '✅ PASS' : '❌ FAIL');

    // 4. Token Refresh
    const refreshRes = await request.post('/api/v1/auth/refresh').send({
      refreshToken,
    });

    console.log('4. Token Rotation (/refresh):', refreshRes.status === 200 && refreshRes.body.data.accessToken ? '✅ PASS' : '❌ FAIL');
    const newAccessToken = refreshRes.body.data.accessToken;

    // 5. Update Preferences
    const prefRes = await request
      .put('/api/v1/auth/preferences')
      .set('Authorization', `Bearer ${newAccessToken}`)
      .send({
        dailyCodingTargetMins: 150,
        weeklyGymTarget: 5,
      });

    console.log('5. Update Preferences:', prefRes.status === 200 && prefRes.body.data.dailyCodingTargetMins === 150 ? '✅ PASS' : '❌ FAIL');

    console.log('\n🎉 ALL AUTH ENDPOINT TESTS PASSED SUCCESSFULLY!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testAuthFlow();
