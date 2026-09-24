const http = require('http');

const BASE_URL = 'http://localhost:5000';

function makeRequest(endpoint, method = 'GET', body = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(endpoint, BASE_URL);
    const postData = body ? JSON.stringify(body) : '';

    const reqHeaders = {
      'Content-Type': 'application/json',
      ...headers,
    };

    if (body) {
      reqHeaders['Content-Length'] = Buffer.byteLength(postData).toString();
    }

    const req = http.request(
      {
        hostname: url.hostname,
        port: url.port,
        path: url.pathname + url.search,
        method,
        headers: reqHeaders,
      },
      (res) => {
        let rawData = '';
        res.on('data', (chunk) => {
          rawData += chunk;
        });
        res.on('end', () => {
          let parsed;
          try {
            parsed = JSON.parse(rawData);
          } catch {
            parsed = rawData;
          }
          resolve({
            statusCode: res.statusCode || 0,
            headers: res.headers,
            body: parsed,
          });
        });
      }
    );

    req.on('error', (err) => reject(err));

    if (body) {
      req.write(postData);
    }
    req.end();
  });
}

async function runArchitectureVerification() {
  console.log('🏛️  HABos Architecture & Performance Verification Suite\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, title, details) {
    if (condition) {
      console.log(`✅ PASS: ${title}`);
      passed++;
    } else {
      console.error(`❌ FAIL: ${title}${details ? ` -> ${details}` : ''}`);
      failed++;
    }
  }

  // 1. Authenticate user
  console.log('--- 1. Authenticating Test User ---');
  const testEmail = `arch_test_${Date.now()}@example.com`;
  const regRes = await makeRequest('/api/v1/auth/register', 'POST', {
    email: testEmail,
    password: 'Password123!',
    name: 'Arch Test User',
  });

  const token = regRes.body?.data?.tokens?.accessToken;
  assert(!!token, 'User authenticated successfully and token received', `Status: ${regRes.statusCode}`);
  const authHeaders = { Authorization: `Bearer ${token}` };

  // 2. Dashboard Parallel Fetch & Caching
  console.log('\n--- 2. Testing Dashboard Parallel Aggregation & In-Memory Cache ---');
  const t0 = Date.now();
  const dashMissRes = await makeRequest('/api/v1/dashboard', 'GET', null, authHeaders);
  const tMiss = Date.now() - t0;

  assert(
    dashMissRes.statusCode === 200 && dashMissRes.headers['x-cache'] === 'MISS',
    'First dashboard request compiles feed concurrently with Promise.all and reports X-Cache: MISS',
    `Status: ${dashMissRes.statusCode}, X-Cache: ${dashMissRes.headers['x-cache']}, Latency: ${tMiss}ms`
  );

  const t1 = Date.now();
  const dashHitRes = await makeRequest('/api/v1/dashboard', 'GET', null, authHeaders);
  const tHit = Date.now() - t1;

  assert(
    dashHitRes.statusCode === 200 && dashHitRes.headers['x-cache'] === 'HIT',
    'Subsequent dashboard request serves immediately from in-memory cache (X-Cache: HIT)',
    `Status: ${dashHitRes.statusCode}, X-Cache: ${dashHitRes.headers['x-cache']}, Latency: ${tHit}ms`
  );

  // 3. Service Layer & Cache Invalidation on Mutation
  console.log('\n--- 3. Testing Service Layer & Dashboard Cache Invalidation ---');
  const createTaskRes = await makeRequest(
    '/api/v1/tasks',
    'POST',
    {
      title: 'Architectural Hardening Task',
      priority: 'HIGH',
    },
    authHeaders
  );

  assert(
    createTaskRes.statusCode === 201 && createTaskRes.body.data?.id,
    'Task created via tasks.service.ts with status 201',
    `Status: ${createTaskRes.statusCode}`
  );

  const taskId = createTaskRes.body.data?.id;

  // After task mutation, dashboard cache MUST have been invalidated
  const dashPostTaskRes = await makeRequest('/api/v1/dashboard', 'GET', null, authHeaders);
  assert(
    dashPostTaskRes.headers['x-cache'] === 'MISS',
    'Dashboard cache is automatically invalidated upon task mutation (X-Cache: MISS)',
    `X-Cache: ${dashPostTaskRes.headers['x-cache']}`
  );

  // 4. Task State Machine & Auto-Timestamp Business Logic
  console.log('\n--- 4. Testing Task Service State Machine Transitions ---');
  const toggleCompleteRes = await makeRequest(
    `/api/v1/tasks/${taskId}/complete`,
    'PATCH',
    null,
    authHeaders
  );

  assert(
    toggleCompleteRes.statusCode === 200 &&
      toggleCompleteRes.body.data?.isCompleted === true &&
      toggleCompleteRes.body.data?.status === 'COMPLETED' &&
      !!toggleCompleteRes.body.data?.completedAt,
    'Toggle completion encapsulates state transition: isCompleted=true, status=COMPLETED, completedAt set',
    `isCompleted: ${toggleCompleteRes.body.data?.isCompleted}, status: ${toggleCompleteRes.body.data?.status}, completedAt: ${toggleCompleteRes.body.data?.completedAt}`
  );

  const toggleUncompleteRes = await makeRequest(
    `/api/v1/tasks/${taskId}/complete`,
    'PATCH',
    null,
    authHeaders
  );

  assert(
    toggleUncompleteRes.statusCode === 200 &&
      toggleUncompleteRes.body.data?.isCompleted === false &&
      toggleUncompleteRes.body.data?.status === 'TODO' &&
      toggleUncompleteRes.body.data?.completedAt === null,
    'Toggle completion again reverts state: isCompleted=false, status=TODO, completedAt cleared',
    `isCompleted: ${toggleUncompleteRes.body.data?.isCompleted}, status: ${toggleUncompleteRes.body.data?.status}, completedAt: ${toggleUncompleteRes.body.data?.completedAt}`
  );

  // 5. Standardized Pagination on /tasks, /focus, and /gym
  console.log('\n--- 5. Testing Standardized Pagination Layer ---');
  const taskPageRes = await makeRequest('/api/v1/tasks?page=1&limit=2', 'GET', null, authHeaders);
  const taskPag = taskPageRes.body?.data?.pagination;

  assert(
    taskPageRes.statusCode === 200 &&
      taskPag &&
      taskPag.page === 1 &&
      taskPag.limit === 2 &&
      typeof taskPag.total === 'number' &&
      typeof taskPag.hasMore === 'boolean',
    'GET /tasks returns structured pagination envelope with total, page, limit, hasMore',
    `Envelope: ${JSON.stringify(taskPag)}`
  );

  const focusPageRes = await makeRequest('/api/v1/focus?page=1&limit=5', 'GET', null, authHeaders);
  const focusPag = focusPageRes.body?.data?.pagination;

  assert(
    focusPageRes.statusCode === 200 &&
      focusPag &&
      focusPag.limit === 5 &&
      Array.isArray(focusPageRes.body?.data?.data),
    'GET /focus supports page and limit pagination',
    `Envelope: ${JSON.stringify(focusPag)}`
  );

  const gymPageRes = await makeRequest('/api/v1/gym?page=1&limit=5', 'GET', null, authHeaders);
  const gymPag = gymPageRes.body?.data?.pagination;

  assert(
    gymPageRes.statusCode === 200 &&
      gymPag &&
      gymPag.limit === 5 &&
      Array.isArray(gymPageRes.body?.data?.data),
    'GET /gym supports page and limit pagination',
    `Envelope: ${JSON.stringify(gymPag)}`
  );

  console.log(`\n========================================`);
  console.log(`Results: ${passed} Passed, ${failed} Failed`);
  console.log(`========================================\n`);

  process.exit(failed > 0 ? 1 : 0);
}

runArchitectureVerification().catch((err) => {
  console.error('Fatal error during architecture verification:', err);
  process.exit(1);
});
