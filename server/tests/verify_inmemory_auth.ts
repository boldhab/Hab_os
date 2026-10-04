import supertest from 'supertest';
import app from '../src/app';

async function runTests() {
  const req = supertest(app);
  let passed = 0;
  let failed = 0;

  function assert(condition: boolean, testName: string, detail?: string) {
    if (condition) {
      console.log(`✅ PASS: ${testName}`);
      passed++;
    } else {
      console.error(`❌ FAIL: ${testName}${detail ? ` - ${detail}` : ''}`);
      failed++;
    }
  }

  console.log('\n--- 1. Testing Pre-seeded Demo User Login ---');
  const demoLoginRes = await req.post('/api/v1/auth/login').send({
    email: 'demo@habos.dev',
    password: 'Habos@2026',
  });
  assert(demoLoginRes.status === 200, 'Demo user login returns 200');
  assert(!!demoLoginRes.body.data?.tokens?.accessToken, 'Demo user login returns accessToken');
  assert(demoLoginRes.body.data?.user?.email === 'demo@habos.dev', 'Demo user email matches in payload');

  console.log('\n--- 2. Testing New User Registration ---');
  const uniqueEmail = `user_${Date.now()}@example.com`;
  const regRes = await req.post('/api/v1/auth/register').send({
    name: 'Jane Doe',
    email: uniqueEmail,
    password: 'SecurePassword123!',
  });
  assert(regRes.status === 201, 'Registration returns 201 Created');
  assert(regRes.body.data?.user?.email === uniqueEmail, 'Registered user email matches');
  assert(regRes.body.data?.user?.name === 'Jane Doe', 'Registered user name matches');
  assert(!!regRes.body.data?.tokens?.accessToken, 'Registration returns accessToken');
  assert(!!regRes.body.data?.tokens?.refreshToken, 'Registration returns refreshToken');

  console.log('\n--- 3. Testing Duplicate Registration Prevention ---');
  const dupRes = await req.post('/api/v1/auth/register').send({
    name: 'Jane Clone',
    email: uniqueEmail,
    password: 'AnotherPassword456!',
  });
  assert(dupRes.status === 400, 'Duplicate registration returns 400');

  console.log('\n--- 4. Testing Login With Newly Registered User ---');
  const loginRes = await req.post('/api/v1/auth/login').send({
    email: uniqueEmail,
    password: 'SecurePassword123!',
  });
  assert(loginRes.status === 200, 'Login returns 200 OK');
  const newAccessToken = loginRes.body.data?.tokens?.accessToken;
  const newRefreshToken = loginRes.body.data?.tokens?.refreshToken;
  assert(!!newAccessToken, 'Login returns valid access token');

  console.log('\n--- 5. Testing Wrong Password Rejection ---');
  const badLoginRes = await req.post('/api/v1/auth/login').send({
    email: uniqueEmail,
    password: 'WrongPassword!',
  });
  assert(badLoginRes.status === 401, 'Invalid password rejected with 401');

  console.log('\n--- 6. Testing Protected /me Route with Access Token ---');
  const meRes = await req.get('/api/v1/auth/me').set('Authorization', `Bearer ${newAccessToken}`);
  assert(meRes.status === 200, 'GET /me returns 200');
  assert(meRes.body.data?.email === uniqueEmail, 'GET /me returns correct user data');
  assert(meRes.body.data?.name === 'Jane Doe', 'GET /me returns correct profile name');

  console.log('\n--- 7. Testing Token Refresh (Rotation) ---');
  const refreshRes = await req.post('/api/v1/auth/refresh').send({
    refreshToken: newRefreshToken,
  });
  assert(refreshRes.status === 200, 'POST /refresh returns 200');
  assert(!!refreshRes.body.data?.accessToken, 'POST /refresh yields new accessToken');

  console.log('\n--- 8. Testing Protected Route Rejection without Token ---');
  const unauthorizedRes = await req.get('/api/v1/auth/me');
  assert(unauthorizedRes.status === 401, 'Request without token rejected with 401');

  console.log('\n--- 9. Testing Profile Update ---');
  const updateRes = await req
    .put('/api/v1/auth/profile')
    .set('Authorization', `Bearer ${newAccessToken}`)
    .send({ name: 'Jane Updated' });
  assert(updateRes.status === 200, 'PUT /profile returns 200');
  assert(updateRes.body.data?.name === 'Jane Updated', 'Profile name updated correctly');

  console.log(`\n========================================`);
  console.log(`Results: ${passed} passed, ${failed} failed`);
  console.log(`========================================\n`);

  process.exit(failed === 0 ? 0 : 1);
}

runTests().catch((err) => {
  console.error('Test execution error:', err);
  process.exit(1);
});
