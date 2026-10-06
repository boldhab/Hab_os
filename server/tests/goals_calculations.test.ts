import assert from 'assert';
import {
  computeGoalProgressDetails,
  evaluateGoalHealthStatus,
} from '../src/modules/goals/goals.service';

/**
 * Pure Unit Tests for Goals Recalculation, Weighted Milestone Normalization,
 * Financial Targets, and Pace-Based Health Status Indicators.
 */

async function runGoalCalculationsSuite() {
  console.log('🧪 Starting Goal Calculations & Health Assessment Unit Test Suite...\n');

  // =========================================================================
  // 1. Financial Goal Calculation
  // =========================================================================
  console.log('--- 1. Financial Goal Progress Calculations ---');
  {
    const res = computeGoalProgressDetails({
      category: 'FINANCIAL',
      targetAmount: 5000,
      currentAmount: 2500,
      progress: 0,
      milestones: [],
      tasks: [],
    });
    assert.strictEqual(res.progress, 50.0, '5000 target with 2500 current should be 50.0%');
    assert.strictEqual(res.status, 'IN_PROGRESS');
    console.log('  ✅ Financial goal correctly calculates 50% progress');
  }

  {
    const resOver = computeGoalProgressDetails({
      category: 'FINANCIAL',
      targetAmount: 1000,
      currentAmount: 1500,
      progress: 0,
      milestones: [],
      tasks: [],
    });
    assert.strictEqual(resOver.progress, 100.0, 'Exceeding target amount caps at 100%');
    assert.strictEqual(resOver.status, 'COMPLETED');
    console.log('  ✅ Overachieved financial goal caps at 100% and marks COMPLETED');
  }

  // =========================================================================
  // 2. Weighted Milestone Normalization
  // =========================================================================
  console.log('\n--- 2. Weighted Milestone Progress & Auto-Normalization ---');
  {
    // Case A: Standard equal weights (1.0, 1.0), one completed
    const res = computeGoalProgressDetails({
      category: 'CAREER',
      progress: 0,
      milestones: [
        { id: 'm1', weight: 1.0, isCompleted: true, tasks: [] },
        { id: 'm2', weight: 1.0, isCompleted: false, tasks: [] },
      ],
      tasks: [],
    });
    assert.strictEqual(res.progress, 50.0, 'Equal 1.0 weights with 1/2 complete should be 50%');
    console.log('  ✅ Equal milestone weights calculate 50%');
  }

  {
    // Case B: Arbitrary un-normalized weights (e.g. 3.0 and 7.0 -> sum 10.0)
    // Milestone 1 (weight 3.0) complete = 3.0 / 10.0 = 30%
    const res = computeGoalProgressDetails({
      category: 'CAREER',
      progress: 0,
      milestones: [
        { id: 'm1', weight: 3.0, isCompleted: true, tasks: [] },
        { id: 'm2', weight: 7.0, isCompleted: false, tasks: [] },
      ],
      tasks: [],
    });
    assert.strictEqual(res.progress, 30.0, 'Normalized 3/(3+7) should be 30.0%');
    console.log('  ✅ Arbitrary weights (3 vs 7) automatically normalize without forcing sum=100');
  }

  {
    // Case C: Task-derived milestone progress with subtasks
    // Milestone 1 (weight 1.0, 2/2 tasks done -> 100%)
    // Milestone 2 (weight 1.0, 1/2 tasks done -> 50%)
    // Overall = (1.0*1.0 + 0.5*1.0) / 2.0 = 1.5 / 2.0 = 75%
    const res = computeGoalProgressDetails({
      category: 'EDUCATION',
      progress: 0,
      milestones: [
        {
          id: 'm1',
          weight: 1.0,
          isCompleted: false, // will auto-complete
          tasks: [
            { id: 't1', isCompleted: true },
            { id: 't2', isCompleted: true },
          ],
        },
        {
          id: 'm2',
          weight: 1.0,
          isCompleted: false,
          tasks: [
            { id: 't3', isCompleted: true },
            { id: 't4', isCompleted: false },
          ],
        },
      ],
      tasks: [],
    });
    assert.strictEqual(res.progress, 75.0, 'Task-backed milestones calculate 75.0% progress');
    assert.strictEqual(res.milestoneUpdates.length, 1);
    assert.strictEqual(res.milestoneUpdates[0].id, 'm1');
    assert.strictEqual(res.milestoneUpdates[0].isCompleted, true);
    assert.strictEqual(res.milestoneUpdates[0].status, 'COMPLETED');
    console.log('  ✅ Milestone status auto-synchronizes when all linked tasks complete');
  }

  // =========================================================================
  // 3. Fallback Task-Driven Goals
  // =========================================================================
  console.log('\n--- 3. Direct Task-Driven Goals (No Milestones) ---');
  {
    const res = computeGoalProgressDetails({
      category: 'PERSONAL',
      progress: 0,
      milestones: [],
      tasks: [
        { id: 't1', isCompleted: true },
        { id: 't2', isCompleted: true },
        { id: 't3', isCompleted: false },
      ],
    });
    assert.strictEqual(res.progress, 66.7, '2/3 completed tasks should be 66.7%');
    assert.strictEqual(res.status, 'IN_PROGRESS');
    console.log('  ✅ Direct task-driven goals compute correct percentage (66.7%)');
  }

  // =========================================================================
  // 4. Health Evaluation & Timeline Pacing
  // =========================================================================
  console.log('\n--- 4. Health Status & Dynamic Pace Tracking ---');
  {
    // Goal started 50 days ago, target in 50 days (total 100 days).
    // Elapsed time = 50%, expected progress = 50%.
    // Current progress = 48% -> On track!
    const now = new Date('2026-06-01T00:00:00Z');
    const createdAt = new Date('2026-04-12T00:00:00Z'); // 50 days prior
    const targetDate = new Date('2026-07-21T00:00:00Z'); // 50 days after

    const health = evaluateGoalHealthStatus({
      progress: 48,
      createdAt,
      targetDate,
      daysSinceActivity: 2,
      latestConfidence: null,
      now,
    });

    assert.strictEqual(health.healthStatus, 'ON_TRACK');
    console.log('  ✅ Goal pacing within expected margin evaluated as ON_TRACK');
  }

  {
    // Same timeline (expected progress = 50%), but current progress is only 15% (deficit = 35%)
    const now = new Date('2026-06-01T00:00:00Z');
    const createdAt = new Date('2026-04-12T00:00:00Z');
    const targetDate = new Date('2026-07-21T00:00:00Z');

    const health = evaluateGoalHealthStatus({
      progress: 15,
      createdAt,
      targetDate,
      daysSinceActivity: 3,
      latestConfidence: null,
      now,
    });

    assert.strictEqual(health.healthStatus, 'AT_RISK');
    assert(health.riskReason?.includes('Pacing alert'), 'Should include pacing alert reason');
    console.log('  ✅ Significant pace deficit (15% vs expected 50%) dynamically flags AT_RISK');
  }

  {
    // Overdue goal (target passed, progress < 100%)
    const now = new Date('2026-08-01T00:00:00Z');
    const createdAt = new Date('2026-04-12T00:00:00Z');
    const targetDate = new Date('2026-07-21T00:00:00Z');

    const health = evaluateGoalHealthStatus({
      progress: 80,
      createdAt,
      targetDate,
      daysSinceActivity: 1,
      latestConfidence: null,
      now,
    });

    assert.strictEqual(health.healthStatus, 'AT_RISK');
    assert(health.riskReason?.includes('Target date has passed'), 'Identifies overdue goal');
    console.log('  ✅ Overdue goal correctly flags AT_RISK with overdue days explanation');
  }

  console.log('\n🎉 All 7/7 Goal Pure Unit & Calculation Tests Passed Successfully!\n');
}

runGoalCalculationsSuite();
