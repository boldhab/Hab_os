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

async function runAdvancedTasksVerification() {
  console.log('⚡ HABos Advanced Tasks Verification Suite\n');

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

  // 1. Authenticate test user
  console.log('--- 1. Authenticating Test User ---');
  const testEmail = `tasks_adv_${Date.now()}@example.com`;
  const regRes = await makeRequest('/api/v1/auth/register', 'POST', {
    email: testEmail,
    password: 'Password123!',
    name: 'Advanced Tasks User',
  });

  const token = regRes.body?.data?.tokens?.accessToken;
  assert(!!token, 'Test user registered and token acquired', `Status: ${regRes.statusCode}`);
  const authHeaders = { Authorization: `Bearer ${token}` };

  // 2. Subtasks & Auto-Completion Rule
  console.log('\n--- 2. Testing Subtasks & Parent Auto-Completion Logic ---');
  const parentRes = await makeRequest(
    '/api/v1/tasks',
    'POST',
    { title: 'Parent Feature Task' },
    authHeaders
  );
  const parentId = parentRes.body.data.id;

  const sub1Res = await makeRequest(
    `/api/v1/tasks/${parentId}/subtasks`,
    'POST',
    { title: 'Subtask 1: Unit Tests' },
    authHeaders
  );
  const sub1Id = sub1Res.body.data.id;

  const sub2Res = await makeRequest(
    `/api/v1/tasks/${parentId}/subtasks`,
    'POST',
    { title: 'Subtask 2: Documentation' },
    authHeaders
  );
  const sub2Id = sub2Res.body.data.id;

  assert(
    sub1Res.statusCode === 201 && sub2Res.statusCode === 201,
    'Subtasks created under parent task',
    `Sub1: ${sub1Id}, Sub2: ${sub2Id}`
  );

  // Complete subtask 1: parent should stay incomplete (1/2 done)
  await makeRequest(`/api/v1/tasks/${sub1Id}/complete`, 'PATCH', null, authHeaders);
  const check1Res = await makeRequest('/api/v1/tasks', 'GET', null, authHeaders);
  const parentCheck1 = check1Res.body.data.data.find((t) => t.id === parentId);

  assert(
    parentCheck1 && parentCheck1.isCompleted === false && parentCheck1.subtaskProgress.fraction === '1/2',
    'Completing 1 of 2 subtasks leaves parent task uncompleted (fraction 1/2)',
    `Fraction: ${parentCheck1?.subtaskProgress?.fraction}`
  );

  // Complete subtask 2: parent MUST auto-complete!
  await makeRequest(`/api/v1/tasks/${sub2Id}/complete`, 'PATCH', null, authHeaders);
  const check2Res = await makeRequest('/api/v1/tasks', 'GET', null, authHeaders);
  const parentCheck2 = check2Res.body.data.data.find((t) => t.id === parentId);

  assert(
    parentCheck2 && parentCheck2.isCompleted === true && parentCheck2.status === 'COMPLETED' && !!parentCheck2.completedAt,
    'Completing all subtasks auto-completes parent task (status: COMPLETED, completedAt set)',
    `isCompleted: ${parentCheck2?.isCompleted}, status: ${parentCheck2?.status}`
  );

  // Reopen subtask 1: parent MUST automatically revert to IN_PROGRESS!
  await makeRequest(`/api/v1/tasks/${sub1Id}/complete`, 'PATCH', null, authHeaders);
  const check3Res = await makeRequest('/api/v1/tasks', 'GET', null, authHeaders);
  const parentCheck3 = check3Res.body.data.data.find((t) => t.id === parentId);

  assert(
    parentCheck3 && parentCheck3.isCompleted === false && parentCheck3.status === 'IN_PROGRESS',
    'Reopening a subtask reverts parent task back to IN_PROGRESS',
    `status: ${parentCheck3?.status}`
  );

  // 3. Recurring Tasks & Next Instance Generation
  console.log('\n--- 3. Testing Recurring Tasks & Next Occurrence Generation ---');
  const recurRes = await makeRequest(
    '/api/v1/tasks',
    'POST',
    {
      title: 'Daily Standup Sync',
      isRecurring: true,
      recurrenceRule: 'DAILY',
      dueDate: new Date().toISOString(),
    },
    authHeaders
  );
  const recurId = recurRes.body.data.id;

  // Complete recurring task: triggers automatic generation of next instance
  await makeRequest(`/api/v1/tasks/${recurId}/complete`, 'PATCH', null, authHeaders);

  const recurListRes = await makeRequest('/api/v1/tasks', 'GET', null, authHeaders);
  const tasks = recurListRes.body.data.data;
  const originalCompleted = tasks.find((t) => t.id === recurId);
  const nextOccurrence = tasks.find((t) => t.id !== recurId && t.title === 'Daily Standup Sync');

  assert(
    originalCompleted && originalCompleted.isCompleted === true,
    'Completed recurring task instance is preserved in history (isCompleted: true)',
    `Status: ${originalCompleted?.status}`
  );

  assert(
    !!nextOccurrence && nextOccurrence.isCompleted === false && nextOccurrence.isRecurring === true,
    'Completing recurring task automatically creates next scheduled occurrence',
    `Next ID: ${nextOccurrence?.id}, Due: ${nextOccurrence?.dueDate}`
  );

  // 4. Task Dependencies & Blocker Enforcement
  console.log('\n--- 4. Testing Task Dependencies & Blocker Enforcement ---');
  const taskARes = await makeRequest('/api/v1/tasks', 'POST', { title: 'Task A: Database Setup' }, authHeaders);
  const taskBRes = await makeRequest('/api/v1/tasks', 'POST', { title: 'Task B: API Integration' }, authHeaders);
  const taskAId = taskARes.body.data.id;
  const taskBId = taskBRes.body.data.id;

  // Add dependency: Task B is blocked by Task A
  const depRes = await makeRequest(
    `/api/v1/tasks/${taskBId}/dependencies`,
    'POST',
    { blockingTaskId: taskAId },
    authHeaders
  );

  assert(
    depRes.statusCode === 201,
    'Dependency linked: Task B blocked by Task A',
    `Status: ${depRes.statusCode}`
  );

  // Attempt to complete Task B while Task A is uncompleted -> MUST be rejected with HTTP 400!
  const prematureCompleteRes = await makeRequest(
    `/api/v1/tasks/${taskBId}/complete`,
    'PATCH',
    null,
    authHeaders
  );

  assert(
    prematureCompleteRes.statusCode === 400 &&
      typeof prematureCompleteRes.body.message === 'string' &&
      prematureCompleteRes.body.message.includes('prerequisite'),
    'Completing a blocked task is rejected with 400 when prerequisite is incomplete',
    `Status: ${prematureCompleteRes.statusCode}, Error: ${prematureCompleteRes.body.message}`
  );

  // Circular dependency detection: Attempting to make Task A blocked by Task B
  const circularRes = await makeRequest(
    `/api/v1/tasks/${taskAId}/dependencies`,
    'POST',
    { blockingTaskId: taskBId },
    authHeaders
  );

  assert(
    circularRes.statusCode === 400 &&
      typeof circularRes.body.message === 'string' &&
      circularRes.body.message.includes('Circular dependency'),
    'Circular dependency attempt is detected and blocked with HTTP 400',
    `Status: ${circularRes.statusCode}, Message: ${circularRes.body.message}`
  );

  // Complete prerequisite Task A, then complete Task B -> MUST now succeed!
  await makeRequest(`/api/v1/tasks/${taskAId}/complete`, 'PATCH', null, authHeaders);
  const unblockedCompleteRes = await makeRequest(
    `/api/v1/tasks/${taskBId}/complete`,
    'PATCH',
    null,
    authHeaders
  );

  assert(
    unblockedCompleteRes.statusCode === 200 && unblockedCompleteRes.body.data.isCompleted === true,
    'Once prerequisite is completed, blocked task completion succeeds',
    `Status: ${unblockedCompleteRes.statusCode}`
  );

  // 5. Eisenhower Matrix
  console.log('\n--- 5. Testing Eisenhower Matrix Endpoint ---');
  // Create an urgent high-priority task for Q1
  await makeRequest(
    '/api/v1/tasks',
    'POST',
    {
      title: 'Emergency Server Fix',
      priority: 'CRITICAL',
      dueDate: new Date().toISOString(),
    },
    authHeaders
  );

  // Create an important non-urgent task for Q2
  const nextMonth = new Date();
  nextMonth.setDate(nextMonth.getDate() + 30);
  await makeRequest(
    '/api/v1/tasks',
    'POST',
    {
      title: 'Annual Strategic Architecture',
      priority: 'HIGH',
      dueDate: nextMonth.toISOString(),
    },
    authHeaders
  );

  const matrixRes = await makeRequest('/api/v1/tasks/matrix', 'GET', null, authHeaders);
  const matrix = matrixRes.body?.data?.quadrants;

  assert(
    matrixRes.statusCode === 200 &&
      matrix &&
      matrix.q1_urgent_important &&
      matrix.q2_not_urgent_important &&
      matrix.q3_urgent_not_important &&
      matrix.q4_not_urgent_not_important,
    'GET /api/v1/tasks/matrix returns all 4 quadrants (Do First, Schedule, Delegate, Eliminate)',
    `Q1: ${matrix?.q1_urgent_important?.count}, Q2: ${matrix?.q2_not_urgent_important?.count}`
  );

  assert(
    matrix.q1_urgent_important.items.some((t) => t.title === 'Emergency Server Fix') &&
      matrix.q2_not_urgent_important.items.some((t) => t.title === 'Annual Strategic Architecture'),
    'Tasks accurately mapped into Eisenhower quadrants based on priority and due date urgency',
    `Mapped successfully`
  );

  console.log(`\n========================================`);
  console.log(`Results: ${passed} Passed, ${failed} Failed`);
  console.log(`========================================\n`);

  process.exit(failed > 0 ? 1 : 0);
}

runAdvancedTasksVerification().catch((err) => {
  console.error('Fatal error during advanced tasks verification:', err);
  process.exit(1);
});
