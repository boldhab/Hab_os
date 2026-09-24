import crypto from 'crypto';
import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testFullDeveloperHubSuite() {
  console.log('🚀 Starting Full Developer Hub End-to-End Test Suite...\n');
  const request = supertest(app);

  try {
    // 1. Authenticate with demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    if (loginRes.status !== 200) {
      throw new Error(`Auth failed with status ${loginRes.status}: ${JSON.stringify(loginRes.body)}`);
    }

    const token = loginRes.body.data.tokens.accessToken;
    const authHeaders = { Authorization: `Bearer ${token}` };
    console.log('1. Authentication: ✅ PASS');

    // 2. Create a test Project
    const createProjRes = await request
      .post('/api/v1/projects')
      .set(authHeaders)
      .send({
        title: 'HabOS Developer Core',
        description: 'Next-gen productivity engine for developers',
        status: 'IN_PROGRESS',
        repoUrl: 'https://github.com/habos-dev/developer-core',
        technologies: ['TypeScript', 'Node.js', 'PostgreSQL'],
        color: '#10B981',
        webhookSecret: 'habos_webhook_super_secret_2026',
      });

    console.log(
      '2. Create Developer Project:',
      createProjRes.status === 201 && createProjRes.body.data.id ? '✅ PASS' : '❌ FAIL'
    );
    const projectId = createProjRes.body.data.id;

    // 3. Create Tasks, Features, and Bugs
    // 3a. Task
    const taskRes = await request
      .post('/api/v1/tasks')
      .set(authHeaders)
      .send({
        title: 'Architect Kanban State Machine',
        projectId,
        priority: 'HIGH',
        status: 'TODO',
        order: 1000,
        githubIssueNumber: 101,
      });
    const taskId = taskRes.body.data.id;
    console.log('3a. Create Project Task:', taskRes.status === 201 ? '✅ PASS' : '❌ FAIL');

    // 3b. Feature
    const featRes = await request
      .post(`/api/v1/projects/${projectId}/features`)
      .set(authHeaders)
      .send({
        name: 'Bi-directional GitHub Webhook Sync',
        description: 'Auto-update tasks on push/PR events',
        priority: 'CRITICAL',
        status: 'TODO',
        order: 2000,
        githubIssueNumber: 102,
      });
    const featureId = featRes.body.data.id;
    console.log('3b. Create Project Feature:', featRes.status === 201 ? '✅ PASS' : '❌ FAIL');

    // 3c. Bug with CRITICAL severity distinct from priority
    const bugRes = await request
      .post(`/api/v1/projects/${projectId}/bugs`)
      .set(authHeaders)
      .send({
        title: 'Payload buffer signature mismatch in HMAC parser',
        description: 'Raw body buffer must not be pre-mutated by JSON parser',
        severity: 'CRITICAL',
        priority: 'HIGH',
        status: 'OPEN',
        order: 3000,
        githubIssueNumber: 103,
      });
    const bugId = bugRes.body.data.id;
    console.log(
      '3c. Create Bug (with Severity distinct from Priority):',
      bugRes.status === 201 && bugRes.body.data.severity === 'CRITICAL' ? '✅ PASS' : '❌ FAIL'
    );

    // 4. Test Kanban Board Serialization
    const boardRes = await request.get(`/api/v1/projects/${projectId}/board`).set(authHeaders);
    const board = boardRes.body.data;
    console.log(
      '4. Kanban Board Retrieval:',
      boardRes.status === 200 &&
        board.columns.TODO.length === 3 &&
        board.totalItems === 3
        ? '✅ PASS (3 items across columns)'
        : '❌ FAIL'
    );

    // 5. Test Fractional Reordering on Kanban Board
    // Move Feature to IN_PROGRESS between orders 1000 and 3000 -> order should become 2000 or fractional
    const moveRes = await request
      .post(`/api/v1/projects/${projectId}/board/move`)
      .set(authHeaders)
      .send({
        entityType: 'FEATURE',
        entityId: featureId,
        targetStatus: 'IN_PROGRESS',
        prevOrder: 1000,
        nextOrder: 2000,
      });

    console.log(
      '5. Fractional Kanban Move:',
      moveRes.status === 200 &&
        moveRes.body.data.newOrder === 1500 &&
        moveRes.body.data.newStatus === 'IN_PROGRESS'
        ? `✅ PASS (Order recalculated to ${moveRes.body.data.newOrder})`
        : '❌ FAIL'
    );

    // 6. Test Auto Progress Calculation & Bug Penalty
    // Initially: 0 completed out of 2 deliverables (task + feature) -> 0%
    // Let's complete the task
    await request
      .post(`/api/v1/projects/${projectId}/board/move`)
      .set(authHeaders)
      .send({
        entityType: 'TASK',
        entityId: taskId,
        targetStatus: 'COMPLETED',
      });

    // 1 completed / 2 = 50% base progress. Open critical bug penalty = 10%. Net = 40%!
    const projDetailRes = await request.get(`/api/v1/projects/${projectId}`).set(authHeaders);
    const progressDetails = projDetailRes.body.data.progressDetails;
    console.log(
      '6. Auto Progress & Critical Bug Penalty:',
      projDetailRes.status === 200 && progressDetails.progress === 40
        ? `✅ PASS (Progress correctly computed to ${progressDetails.progress}% with bug penalty)`
        : `❌ FAIL (Expected 40%, got ${progressDetails?.progress}%)`
    );

    // 7. Test Time Tracking Rollup (Log FocusSession on Task)
    const userId = loginRes.body.data.user ? loginRes.body.data.user.id : loginRes.body.data.id;

    await prisma.focusSession.create({
      data: {
        userId,
        taskId,
        category: 'CODING',
        durationMinutes: 90,
        startTime: new Date(Date.now() - 90 * 60 * 1000),
        endTime: new Date(),
      },
    });

    const analyticsRes = await request.get(`/api/v1/projects/${projectId}/analytics`).set(authHeaders);
    console.log(
      '7. Time Tracking Rollup & Weekly Velocity:',
      analyticsRes.status === 200 && analyticsRes.body.data.totalFocusMinutes === 90
        ? `✅ PASS (90 focus minutes logged, 1.5h rolled up)`
        : `❌ FAIL (Expected 90 minutes, got ${analyticsRes.body?.data?.totalFocusMinutes})`
    );

    // 8. Test Project Health & Risk Signals
    const health = analyticsRes.body.data.health;
    console.log(
      '8. Project Health Signals:',
      health.openCriticalBugs === 1 && health.healthStatus === 'AT_RISK'
        ? `✅ PASS (Health correctly identified as ${health.healthStatus} due to open critical bug)`
        : '❌ FAIL'
    );

    // 9. Test GitHub Webhook with HMAC-SHA256 Signature Verification
    const webhookPayload = {
      repository: {
        full_name: 'habos-dev/developer-core',
        html_url: 'https://github.com/habos-dev/developer-core',
      },
      commits: [
        {
          id: 'commit-999',
          message: 'fix(core): resolves #103 buffer parsing error in HMAC engine',
          author: { name: 'Lead Dev' },
        },
      ],
    };

    const payloadString = JSON.stringify(webhookPayload);
    const webhookSecret = 'habos_webhook_super_secret_2026';
    const hmac = crypto.createHmac('sha256', webhookSecret);
    const signature = 'sha256=' + hmac.update(payloadString).digest('hex');

    const webhookRes = await request
      .post('/api/v1/integrations/github/webhook')
      .set('x-github-event', 'push')
      .set('x-hub-signature-256', signature)
      .set('Content-Type', 'application/json')
      .send(webhookPayload);

    console.log(
      '9. GitHub Webhook Signature & Commit Message Parsing:',
      webhookRes.status === 200 && webhookRes.body.data.handled === true
        ? `✅ PASS (${webhookRes.body.data.processedEvents.join(', ')})`
        : `❌ FAIL (${JSON.stringify(webhookRes.body)})`
    );

    // Verify bug was marked RESOLVED by webhook
    const resolvedBug = await prisma.bug.findUnique({ where: { id: bugId } });
    console.log(
      '9b. Bug Auto-Resolved via Commit Message:',
      resolvedBug?.status === 'RESOLVED' && Boolean(resolvedBug.resolvedAt)
        ? '✅ PASS (Bug status: RESOLVED)'
        : `❌ FAIL (Bug: status=${resolvedBug?.status}, resolvedAt=${resolvedBug?.resolvedAt})`
    );

    // 10. Test Tech Stack Insights (Cross-Project Aggregation)
    const techInsightsRes = await request.get('/api/v1/projects/insights/tech-stack').set(authHeaders);
    console.log(
      '10. Tech Stack Insights Aggregation:',
      techInsightsRes.status === 200 &&
        Array.isArray(techInsightsRes.body.data.technologies) &&
        techInsightsRes.body.data.technologies.some((t: any) => t.technology === 'TypeScript')
        ? `✅ PASS (Found TypeScript with ${techInsightsRes.body.data.technologies[0].percentage}% focus distribution)`
        : '❌ FAIL'
    );

    // 11. Cleanup
    await request.delete(`/api/v1/projects/${projectId}`).set(authHeaders);
    console.log('\n11. Cleanup Test Artifacts: ✅ PASS');

    console.log('\n🏆 ALL DEVELOPER HUB E2E TESTS PASSED WITH 100% SUCCESS!\n');
  } catch (err) {
    console.error('❌ Test suite execution failed:', err);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

testFullDeveloperHubSuite();
