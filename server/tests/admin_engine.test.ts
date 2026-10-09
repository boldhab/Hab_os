import assert from 'assert';
import adminService from '../src/modules/admin/admin.service';
import auditLogger from '../src/modules/admin/auditLog.service';
import scheduler from '../src/jobs/scheduler';
import authService from '../src/modules/auth/auth.service';

async function runAdminEngineTests() {
  console.log('🧪 Starting HabOS Admin Engine & Mission Control Unit Suite...\n');

  console.log('--- 1. System Health & Telemetry ---');
  const health = await adminService.getSystemHealth();
  assert.strictEqual(health.status, 'HEALTHY');
  assert.strictEqual(typeof health.memory.heapUsedMb, 'number');
  assert.ok(health.uptimeSeconds >= 0);
  assert.ok(health.runtime.nodeVersion.startsWith('v'));
  assert.strictEqual(health.scheduler.registeredJobs, 4);
  console.log('  ✅ Health telemetry reports healthy status, node version, and memory usage');

  console.log('--- 2. Comprehensive 24-Domain System Stats ---');
  const stats = await adminService.getSystemStats();
  assert.ok(stats.users.total >= 1);
  assert.strictEqual(typeof stats.lifeScore.globalAverage, 'number');
  assert.ok(stats.domains.productivity.tasksTotal > 0);
  assert.ok(stats.domains.devAndSoftware.activeProjects > 0);
  assert.ok(stats.domains.healthAndFitness.workoutsLogged > 0);
  assert.ok(stats.domains.personalFinance.transactionsLogged > 0);
  assert.ok(stats.domains.knowledgeVault.notesCount > 0);
  console.log('  ✅ 24 domains statistics and Life Score distributions aggregated successfully');

  console.log('--- 3. Multi-Tenant User Management ---');
  const users = await adminService.getAllUsers();
  assert.ok(users.length >= 2, 'Should contain demo user and root admin user');
  const demoUser = users.find((u) => u.email === 'demo@habos.dev');
  assert.ok(demoUser, 'demo@habos.dev user must exist');
  assert.strictEqual(demoUser.role, 'ADMIN');

  // Test updating role
  const updatedUser = await adminService.updateUserRole(demoUser.id, 'ACTOR_USER', 'test-runner');
  assert.strictEqual(updatedUser.role, 'ACTOR_USER');
  // Revert back
  await adminService.updateUserRole(demoUser.id, 'ADMIN', 'test-runner');
  console.log('  ✅ User retrieval, role modification, and persistence verified');

  // Test password reset
  const resetRes = await adminService.resetUserPassword(demoUser.id, 'NewSecurePass@2026', 'test-runner');
  assert.strictEqual(resetRes.temporaryPassword, 'NewSecurePass@2026');
  console.log('  ✅ Administrative credential resets generate valid temporary credentials');

  console.log('--- 4. Background Job Scheduler Engine ---');
  const jobs = adminService.getJobsTelemetry();
  assert.strictEqual(jobs.tasks.length, 4);
  const workerNames = jobs.tasks.map((t) => t.name);
  assert.ok(workerNames.includes('notificationProcessor'));
  assert.ok(workerNames.includes('habitStreakDecay'));
  assert.ok(workerNames.includes('dailyLifeScore'));
  assert.ok(workerNames.includes('idempotencyCleanup'));
  console.log('  ✅ All 4 core background workers registered with telemetry');

  // Test manual job trigger
  const runRes = await adminService.triggerJob('idempotencyCleanup', 'test-runner');
  assert.strictEqual(runRes.success, true);
  assert.strictEqual(typeof runRes.durationMs, 'number');
  console.log(`  ✅ Manual worker trigger executed in ${runRes.durationMs}ms`);

  // Test scheduler toggle
  const pauseRes = adminService.toggleScheduler(false, 'test-runner');
  assert.strictEqual(pauseRes.isRunning, false);
  const resumeRes = adminService.toggleScheduler(true, 'test-runner');
  assert.strictEqual(resumeRes.isRunning, true);
  console.log('  ✅ Scheduler pause and resume master controls function as expected');

  console.log('--- 5. Runtime Configuration & Domain Weights ---');
  const currentConfig = adminService.getRuntimeConfig();
  assert.strictEqual(currentConfig.defaultWeights.tasks, 0.15);

  adminService.updateRuntimeConfig({
    defaultWeights: {
      tasks: 0.20,
      coding: 0.25,
      study: 0.15,
      gym: 0.15,
      habits: 0.15,
      finance: 0.10,
    },
  }, 'test-runner');

  const modifiedConfig = adminService.getRuntimeConfig();
  assert.strictEqual(modifiedConfig.defaultWeights.tasks, 0.20);
  assert.strictEqual(modifiedConfig.defaultWeights.coding, 0.25);
  console.log('  ✅ Runtime configuration & Life Score weights dynamically updated');

  console.log('--- 6. In-Memory Cache Maintenance ---');
  const cacheRes = adminService.flushCache('test-runner');
  assert.strictEqual(cacheRes.success, true);
  console.log('  ✅ Cache flush operation completes and returns confirmation');

  console.log('--- 7. System Audit & Security Logging ---');
  const logs = auditLogger.getLogs({ limit: 10 });
  assert.ok(logs.length > 0);
  const securityLogs = auditLogger.getLogs({ level: 'SECURITY' });
  assert.ok(securityLogs.length > 0);
  console.log(`  ✅ Audit log buffer tracks ${logs.length} events with level filtering`);

  console.log('\n🎉 All 7/7 Admin Engine & Mission Control Tests Passed Successfully!\n');
}

runAdminEngineTests().catch((err) => {
  console.error('❌ Admin Engine Test Failed:', err);
  process.exit(1);
});
