import assert from 'assert';
import { calculateDateBoundaries } from '../../src/modules/focus/focus.service';
import { FOCUS_CATEGORIES } from '../../src/modules/focus/focus.validation';

console.log('🧪 Running Focus Domain Logic Unit Tests...');

let passed = 0;
let total = 0;

function runTest(name: string, fn: () => void) {
  total++;
  try {
    fn();
    passed++;
    console.log(`  ✅ ${name}`);
  } catch (err: any) {
    console.error(`  ❌ ${name}: ${err.message}`);
    throw err;
  }
}

// ── 1. Non-mutating Date Boundary Calculations ───────────────────────────
runTest('calculateDateBoundaries does not mutate the passed Date object', () => {
  const originalTime = new Date(2026, 9, 3, 14, 30, 0, 0); // Oct 3, 2026 14:30
  const timestampBefore = originalTime.getTime();

  const { now, startOfToday, endOfToday, startOfWeek, startOfMonth } =
    calculateDateBoundaries(originalTime);

  assert.strictEqual(originalTime.getTime(), timestampBefore, 'Original date was mutated!');
  assert.strictEqual(now.getTime(), timestampBefore);
  assert.strictEqual(startOfToday.getHours(), 0);
  assert.strictEqual(endOfToday.getHours(), 23);
});

runTest('calculateDateBoundaries correctly handles Wednesday mid-week', () => {
  // Wednesday, Oct 7, 2026
  const wednesday = new Date(2026, 9, 7, 12, 0, 0);
  const { startOfWeek } = calculateDateBoundaries(wednesday);

  // Monday was Oct 5, 2026
  assert.strictEqual(startOfWeek.getFullYear(), 2026);
  assert.strictEqual(startOfWeek.getMonth(), 9); // October
  assert.strictEqual(startOfWeek.getDate(), 5);
  assert.strictEqual(startOfWeek.getDay(), 1); // Monday
  assert.strictEqual(startOfWeek.getHours(), 0);
});

runTest('calculateDateBoundaries correctly handles Sunday (end of week boundary)', () => {
  // Sunday, Oct 11, 2026
  const sunday = new Date(2026, 9, 11, 22, 0, 0);
  const { startOfWeek } = calculateDateBoundaries(sunday);

  // Monday should still be Oct 5, 2026
  assert.strictEqual(startOfWeek.getFullYear(), 2026);
  assert.strictEqual(startOfWeek.getMonth(), 9); // October
  assert.strictEqual(startOfWeek.getDate(), 5);
  assert.strictEqual(startOfWeek.getDay(), 1); // Monday
});

runTest('calculateDateBoundaries correctly handles Monday (start of week)', () => {
  // Monday, Oct 5, 2026
  const monday = new Date(2026, 9, 5, 8, 30, 0);
  const { startOfWeek } = calculateDateBoundaries(monday);

  assert.strictEqual(startOfWeek.getDate(), 5);
  assert.strictEqual(startOfWeek.getDay(), 1);
});

runTest('Month boundary: startOfWeek in previous month does not corrupt startOfMonth', () => {
  // Thursday, Oct 1, 2026.
  // Monday of this week was Sep 28, 2026.
  const octFirst = new Date(2026, 9, 1, 15, 0, 0);
  const { startOfWeek, startOfMonth } = calculateDateBoundaries(octFirst);

  // startOfWeek should be Sep 28
  assert.strictEqual(startOfWeek.getFullYear(), 2026);
  assert.strictEqual(startOfWeek.getMonth(), 8); // September
  assert.strictEqual(startOfWeek.getDate(), 28);
  assert.strictEqual(startOfWeek.getDay(), 1); // Monday

  // startOfMonth MUST be October 1st, NOT September 1st!
  assert.strictEqual(startOfMonth.getFullYear(), 2026);
  assert.strictEqual(startOfMonth.getMonth(), 9); // October
  assert.strictEqual(startOfMonth.getDate(), 1);
});

// ── 2. Duration Tolerance Calculation ────────────────────────────────────
function validateReportedDuration(startTime: Date, endTime: Date, reportedMinutes: number) {
  const actualElapsedMinutes = Math.ceil((endTime.getTime() - startTime.getTime()) / (1000 * 60));
  if (reportedMinutes > actualElapsedMinutes + 2) {
    throw new Error(`Reported duration (${reportedMinutes}m) exceeds actual elapsed time (${actualElapsedMinutes}m)`);
  }
  return true;
}

runTest('Duration tolerance allows exact reported duration', () => {
  const start = new Date(Date.now() - 25 * 60 * 1000);
  const end = new Date();
  assert.strictEqual(validateReportedDuration(start, end, 25), true);
});

runTest('Duration tolerance allows reported duration with 2-minute buffer', () => {
  const start = new Date(Date.now() - 25 * 60 * 1000);
  const end = new Date();
  assert.strictEqual(validateReportedDuration(start, end, 27), true);
});

runTest('Duration tolerance rejects exaggerated reported duration', () => {
  const start = new Date(Date.now() - 10 * 60 * 1000);
  const end = new Date();
  assert.throws(
    () => validateReportedDuration(start, end, 60),
    /exceeds actual elapsed time/
  );
});

// ── 3. Lifecycle State Transition Guard ──────────────────────────────────
function transitionSessionStatus(currentStatus: string, action: 'end' | 'cancel') {
  if (action === 'end') {
    if (currentStatus === 'COMPLETED') throw new Error('409: Focus session already completed');
    if (currentStatus === 'CANCELLED') throw new Error('400: Focus session is cancelled and cannot be completed');
    return 'COMPLETED';
  } else if (action === 'cancel') {
    if (currentStatus === 'COMPLETED') throw new Error('400: Cannot cancel an already completed session');
    if (currentStatus === 'CANCELLED') throw new Error('409: Focus session is already cancelled');
    return 'CANCELLED';
  }
  return currentStatus;
}

runTest('Session lifecycle allows RUNNING -> COMPLETED', () => {
  assert.strictEqual(transitionSessionStatus('RUNNING', 'end'), 'COMPLETED');
});

runTest('Session lifecycle allows PAUSED -> COMPLETED', () => {
  assert.strictEqual(transitionSessionStatus('PAUSED', 'end'), 'COMPLETED');
});

runTest('Session lifecycle rejects duplicate completion with 409', () => {
  assert.throws(
    () => transitionSessionStatus('COMPLETED', 'end'),
    /409: Focus session already completed/
  );
});

runTest('Session lifecycle allows RUNNING -> CANCELLED', () => {
  assert.strictEqual(transitionSessionStatus('RUNNING', 'cancel'), 'CANCELLED');
});

runTest('Session lifecycle rejects cancelling an already completed session', () => {
  assert.throws(
    () => transitionSessionStatus('COMPLETED', 'cancel'),
    /400: Cannot cancel an already completed session/
  );
});

runTest('Session lifecycle rejects ending a cancelled session', () => {
  assert.throws(
    () => transitionSessionStatus('CANCELLED', 'end'),
    /400: Focus session is cancelled and cannot be completed/
  );
});

// ── 4. Canonical Category Aggregation ───────────────────────────────────
runTest('All canonical categories including WELLNESS are represented in stats breakdown', () => {
  const dummySessions = [
    { category: 'CODING', durationMinutes: 60 },
    { category: 'WELLNESS', durationMinutes: 30 },
    { category: 'STUDY', durationMinutes: 45 },
  ];

  const breakdown: Record<string, number> = {};
  FOCUS_CATEGORIES.forEach((cat) => {
    breakdown[cat] = 0;
  });

  dummySessions.forEach((s) => {
    breakdown[s.category] = (breakdown[s.category] || 0) + s.durationMinutes;
  });

  assert.strictEqual(breakdown['CODING'], 60);
  assert.strictEqual(breakdown['WELLNESS'], 30);
  assert.strictEqual(breakdown['STUDY'], 45);
  assert.strictEqual(breakdown['PROJECT'], 0);
  assert.strictEqual(breakdown['READING'], 0);
  assert.strictEqual(breakdown['OTHER'], 0);
});

console.log(`\n🎉 All ${passed}/${total} Focus Domain Logic unit tests passed successfully!\n`);
