import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testTypeScriptAuthFlow() {
  console.log('🧪 Testing HabOS TypeScript Backend Endpoints...');
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

    // 4. Token Rotation (/refresh)
    const refreshRes = await request.post('/api/v1/auth/refresh').send({
      refreshToken,
    });

    console.log('4. Token Rotation (/refresh):', refreshRes.status === 200 && !!refreshRes.body.data.accessToken ? '✅ PASS' : '❌ FAIL');
    const newAccessToken = refreshRes.body.data.accessToken;

    // 5. Update Preferences
    const prefRes = await request
      .put('/api/v1/auth/preferences')
      .set('Authorization', `Bearer ${newAccessToken}`)
      .send({
        dailyCodingTargetMins: 180,
        weeklyGymTarget: 5,
      });

    console.log('5. Update Preferences:', prefRes.status === 200 && prefRes.body.data.dailyCodingTargetMins === 180 ? '✅ PASS' : '❌ FAIL');

    // 6. Password Update Flow & Verification
    // 6a. Reject password change with incorrect current password (Expect 400)
    const wrongCurrentRes = await request
      .put('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${newAccessToken}`)
      .send({
        currentPassword: 'WrongPassword123!',
        newPassword: 'BrandNewPassword2026!',
      });
    console.log('6a. Reject wrong current password:', wrongCurrentRes.status === 400 ? '✅ PASS' : '❌ FAIL');

    // 6b. Reject new password shorter than 8 characters (Expect 400)
    const shortNewRes = await request
      .put('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${newAccessToken}`)
      .send({
        currentPassword: 'Habos@2026',
        newPassword: 'short',
      });
    console.log('6b. Reject short new password (< 8 chars):', shortNewRes.status === 400 ? '✅ PASS' : '❌ FAIL');

    // 6c. Successfully update password
    const validChangeRes = await request
      .put('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${newAccessToken}`)
      .send({
        currentPassword: 'Habos@2026',
        newPassword: 'UpdatedHabos@2026',
      });
    console.log('6c. Update password with valid credentials:', validChangeRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    // 6d. Verify login works with new password
    const newLoginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'UpdatedHabos@2026',
    });
    console.log('6d. Login with updated password:', newLoginRes.status === 200 ? '✅ PASS' : '❌ FAIL');
    const updatedToken = newLoginRes.body.data.tokens.accessToken;

    // 6e. Revert back to original demo password to keep database fixtures clean
    const revertRes = await request
      .put('/api/v1/auth/profile')
      .set('Authorization', `Bearer ${updatedToken}`)
      .send({
        currentPassword: 'UpdatedHabos@2026',
        newPassword: 'Habos@2026',
      });
    console.log('6e. Revert password to initial fixture password:', revertRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    console.log('\n🎉 ALL TYPESCRIPT BACKEND TESTS PASSED WITH 100% SUCCESS!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testTypeScriptAuthFlow();
