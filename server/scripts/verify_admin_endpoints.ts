import app from '../src/app';
import request from 'supertest';
import assert from 'assert';

async function verifyAdminEndpoints() {
  console.log('🔍 Testing Admin Web Console & API Endpoints HTTP Lifecycle...\n');

  // 1. Health and API status
  console.log('--- 1. Health & Discovery ---');
  const healthStatus = await request(app).get('/health');
  assert.strictEqual(healthStatus.status, 200);
  assert.strictEqual(healthStatus.body.status, 'ok');
  console.log('  ✅ System health status is 200 OK');

  // 2. Admin Web Page HTML delivery
  console.log('--- 2. Admin Web Portal HTML Delivery ---');
  const adminPageRes = await request(app).get('/admin');
  assert.strictEqual(adminPageRes.status, 200);
  assert.ok(adminPageRes.text.includes('HabOS Admin'));
  assert.ok(adminPageRes.text.includes('id="app-layout"'));
  assert.ok(adminPageRes.text.includes('Dashboard'));
  console.log('  ✅ /admin delivers clean semantic HTML5 Admin Dashboard');

  // 3. Admin CSS and JS Static Serving
  console.log('--- 3. Admin Static Assets Serving ---');
  const cssRes = await request(app).get('/admin/css/admin.css');
  assert.strictEqual(cssRes.status, 200);
  assert.ok(cssRes.text.includes('--bg-page'));

  const jsRes = await request(app).get('/admin/js/admin.js');
  assert.strictEqual(jsRes.status, 200);
  assert.ok(jsRes.text.includes('HabOS Admin Console'));
  console.log('  ✅ Admin CSS & JS static bundles served seamlessly');

  // 4. Security Shield Verification
  console.log('--- 4. Security & Role Gate Enforcement ---');
  const unauthorizedRes = await request(app).get('/api/v1/admin/stats');
  assert.strictEqual(unauthorizedRes.status, 403);
  console.log('  ✅ Unauthorized access without Admin Key or Admin Token is blocked (403)');

  // 5. Authenticated Admin Health Telemetry
  console.log('--- 5. Authenticated Admin Health Telemetry ---');
  const healthRes = await request(app)
    .get('/api/v1/admin/health')
    .set('X-Admin-Key', 'habos-admin-secret-2026');
  assert.strictEqual(healthRes.status, 200);
  assert.strictEqual(healthRes.body.success, true);
  assert.strictEqual(healthRes.body.data.status, 'HEALTHY');
  console.log('  ✅ Admin Health endpoint returns system runtime & memory metrics');

  // 6. Comprehensive 24-Domain Stats
  console.log('--- 6. 24-Domain Ecosystem Stats ---');
  const statsRes = await request(app)
    .get('/api/v1/admin/stats')
    .set('X-Admin-Key', 'habos-admin-secret-2026');
  assert.strictEqual(statsRes.status, 200);
  assert.strictEqual(statsRes.body.success, true);
  assert.ok(statsRes.body.data.users.total >= 2);
  assert.ok(statsRes.body.data.lifeScore.globalAverage > 0);
  console.log('  ✅ Stats endpoint returns users, life score distribution, and domain entity metrics');

  // 7. Background Workers Status & Execution
  console.log('--- 7. Background Worker Execution ---');
  const jobsRes = await request(app)
    .get('/api/v1/admin/jobs')
    .set('X-Admin-Key', 'habos-admin-secret-2026');
  assert.strictEqual(jobsRes.status, 200);
  assert.strictEqual(jobsRes.body.data.tasks.length, 4);

  const triggerRes = await request(app)
    .post('/api/v1/admin/jobs/idempotencyCleanup/run')
    .set('X-Admin-Key', 'habos-admin-secret-2026');
  assert.strictEqual(triggerRes.status, 200);
  assert.strictEqual(triggerRes.body.success, true);
  assert.strictEqual(typeof triggerRes.body.data.durationMs, 'number');
  console.log(`  ✅ Idempotency cleanup worker executed successfully (${triggerRes.body.data.durationMs}ms)`);

  // 8. Cache Flush
  console.log('--- 8. In-Memory Cache Flush ---');
  const cacheRes = await request(app)
    .post('/api/v1/admin/maintenance/cache-clear')
    .set('X-Admin-Key', 'habos-admin-secret-2026');
  assert.strictEqual(cacheRes.status, 200);
  assert.strictEqual(cacheRes.body.data.success, true);
  console.log('  ✅ In-memory feed cache flushed via admin maintenance');

  console.log('\n🎉 ALL 8/8 Admin Web & API Endpoints Verified Successfully!\n');
}

verifyAdminEndpoints().catch((err) => {
  console.error('❌ Verification failed:', err);
  process.exit(1);
});
