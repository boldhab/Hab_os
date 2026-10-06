import assert from 'assert';

/**
 * Pure Domain Logic Unit Tests for Habit Streaks, Periods & Numeric Progress
 */

// Helper to simulate ISO week calculation as in habits.service.ts
function getIsoWeek(d: Date): string {
  const date = new Date(d.getTime());
  date.setHours(0, 0, 0, 0);
  date.setDate(date.getDate() + 3 - ((date.getDay() + 6) % 7));
  const week1 = new Date(date.getFullYear(), 0, 4);
  const weekNum = 1 + Math.round(((date.getTime() - week1.getTime()) / 86400000 - 3 + ((week1.getDay() + 6) % 7)) / 7);
  return `${date.getFullYear()}-W${String(weekNum).padStart(2, '0')}`;
}

// Helper to simulate consecutive daily streak calculation
function computeDailyStreak(
  completedDatesIso: string[],
  todayIso: string,
  yesterdayIso: string,
  streakFreezes: number,
  consumeFreeze: boolean
): { currentStreak: number; freezesRemaining: number; freezeConsumed: boolean } {
  const dateSet = new Set(completedDatesIso);
  let freezes = streakFreezes;
  let freezeConsumed = false;

  if (!dateSet.has(todayIso) && !dateSet.has(yesterdayIso)) {
    if (freezes > 0) {
      if (consumeFreeze) {
        freezes--;
        freezeConsumed = true;
      }
      dateSet.add(yesterdayIso);
    }
  }

  const [tY, tM, tD] = todayIso.split('-').map(Number);
  const todayUtc = new Date(Date.UTC(tY, tM - 1, tD, 0, 0, 0, 0));
  const [yY, yM, yD] = yesterdayIso.split('-').map(Number);
  const yesterdayUtc = new Date(Date.UTC(yY, yM - 1, yD, 0, 0, 0, 0));

  let checkDate = dateSet.has(todayIso)
    ? new Date(todayUtc)
    : (dateSet.has(yesterdayIso) ? new Date(yesterdayUtc) : null);
  let streak = 0;

  if (checkDate) {
    while (true) {
      const dStr = checkDate.toISOString().split('T')[0];
      if (dateSet.has(dStr)) {
        streak++;
        checkDate.setUTCDate(checkDate.getUTCDate() - 1);
      } else {
        break;
      }
    }
  }

  return { currentStreak: streak, freezesRemaining: freezes, freezeConsumed };
}

// Helper to simulate weekly count-based streak calculation
function computeWeeklyStreak(
  logDates: Date[],
  targetCount: number,
  now: Date
): number {
  const weekCounts = new Map<string, number>();
  for (const d of logDates) {
    const wk = getIsoWeek(d);
    weekCounts.set(wk, (weekCounts.get(wk) || 0) + 1);
  }

  const currentWeek = getIsoWeek(now);
  const prevWeekDate = new Date(now);
  prevWeekDate.setDate(prevWeekDate.getDate() - 7);
  const prevWeek = getIsoWeek(prevWeekDate);

  let currentStreak = 0;
  let checkWeekDate = new Date(now);

  const currentWeekMet = (weekCounts.get(currentWeek) || 0) >= targetCount;
  const prevWeekMet = (weekCounts.get(prevWeek) || 0) >= targetCount;

  if (currentWeekMet) {
    while (true) {
      const wk = getIsoWeek(checkWeekDate);
      if ((weekCounts.get(wk) || 0) >= targetCount) {
        currentStreak++;
        checkWeekDate.setDate(checkWeekDate.getDate() - 7);
      } else {
        break;
      }
    }
  } else if (prevWeekMet) {
    checkWeekDate = new Date(prevWeekDate);
    while (true) {
      const wk = getIsoWeek(checkWeekDate);
      if ((weekCounts.get(wk) || 0) >= targetCount) {
        currentStreak++;
        checkWeekDate.setDate(checkWeekDate.getDate() - 7);
      } else {
        break;
      }
    }
  }

  return currentStreak;
}

// Helper to simulate monthly count streak calculation
function computeMonthlyStreak(
  logDates: Date[],
  targetCount: number,
  now: Date
): number {
  const monthCounts = new Map<string, number>();
  for (const d of logDates) {
    const key = `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
    monthCounts.set(key, (monthCounts.get(key) || 0) + 1);
  }

  const currentMonthKey = `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}`;
  const prevMonthDate = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1));
  const prevMonthKey = `${prevMonthDate.getUTCFullYear()}-${String(prevMonthDate.getUTCMonth() + 1).padStart(2, '0')}`;

  const currentMonthMet = (monthCounts.get(currentMonthKey) || 0) >= targetCount;
  const prevMonthMet = (monthCounts.get(prevMonthKey) || 0) >= targetCount;

  let currentStreak = 0;
  let checkDate = currentMonthMet
    ? new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1))
    : (prevMonthMet ? prevMonthDate : null);

  if (checkDate) {
    while (true) {
      const key = `${checkDate.getUTCFullYear()}-${String(checkDate.getUTCMonth() + 1).padStart(2, '0')}`;
      if ((monthCounts.get(key) || 0) >= targetCount) {
        currentStreak++;
        checkDate = new Date(Date.UTC(checkDate.getUTCFullYear(), checkDate.getUTCMonth() - 1, 1));
      } else {
        break;
      }
    }
  }

  return currentStreak;
}

// Helper for numeric completion derivation
function deriveCompletion(
  targetType: string,
  targetValue: number,
  data: { isCompleted?: boolean; value?: number }
): { isCompleted: boolean; loggedValue: number } {
  const targetVal = targetValue || 1;
  const isNumericHabit = targetType === 'COUNT' || targetType === 'DURATION';

  if (isNumericHabit) {
    const loggedValue = data.value !== undefined ? data.value : (data.isCompleted ? targetVal : 0);
    const isCompleted = loggedValue >= targetVal;
    return { isCompleted, loggedValue };
  } else {
    const isCompleted = data.isCompleted !== undefined ? data.isCompleted : ((data.value ?? 1) >= targetVal);
    const loggedValue = isCompleted ? targetVal : (data.value !== undefined ? data.value : 0);
    return { isCompleted, loggedValue };
  }
}

// ── Run Tests ─────────────────────────────────────────────────────────────

async function runDomainLogicTests() {
  console.log('🧪 Running Habits Domain Logic & Edge-Case Unit Tests...\n');
  let passed = 0;
  let failed = 0;

  function test(name: string, fn: () => void) {
    try {
      fn();
      console.log(`✅ PASS: ${name}`);
      passed++;
    } catch (err: any) {
      console.error(`❌ FAIL: ${name}`);
      console.error(`   ${err.message}`);
      failed++;
    }
  }

  // 1. Daily Consecutive Streak
  test('Daily: consecutive today, yesterday, and 2 days ago returns streak 3', () => {
    const res = computeDailyStreak(
      ['2026-10-03', '2026-10-02', '2026-10-01'],
      '2026-10-03',
      '2026-10-02',
      2,
      false
    );
    assert.strictEqual(res.currentStreak, 3);
    assert.strictEqual(res.freezesRemaining, 2);
  });

  test('Daily: completed yesterday but not today retains streak 1 without breaking', () => {
    const res = computeDailyStreak(
      ['2026-10-02'],
      '2026-10-03',
      '2026-10-02',
      2,
      false
    );
    assert.strictEqual(res.currentStreak, 1);
  });

  // 2. Read-Only GET vs Write Freeze Consumption
  test('Streak Freeze: GET read preserves streak without consuming freeze shield', () => {
    // Neither today nor yesterday logged, but 2 days ago was logged
    const res = computeDailyStreak(
      ['2026-10-01'],
      '2026-10-03',
      '2026-10-02',
      2,
      false // Read-only GET call
    );
    // Preserves streak as protected
    assert.strictEqual(res.currentStreak, 2);
    // Freeze shield was NOT decremented
    assert.strictEqual(res.freezesRemaining, 2);
    assert.strictEqual(res.freezeConsumed, false);
  });

  test('Streak Freeze: write path consumes shield when missed yesterday', () => {
    const res = computeDailyStreak(
      ['2026-10-01'],
      '2026-10-03',
      '2026-10-02',
      2,
      true // Explicit write evaluation
    );
    assert.strictEqual(res.currentStreak, 2);
    assert.strictEqual(res.freezesRemaining, 1);
    assert.strictEqual(res.freezeConsumed, true);
  });

  test('Streak Freeze: drops to 0 when no freezes remain and yesterday missed', () => {
    const res = computeDailyStreak(
      ['2026-10-01'],
      '2026-10-03',
      '2026-10-02',
      0, // Zero freezes
      true
    );
    assert.strictEqual(res.currentStreak, 0);
    assert.strictEqual(res.freezesRemaining, 0);
  });

  // 3. Weekly Count Streak (ISO weeks)
  test('Weekly: 3 days in current week meets target 3, returns streak 1', () => {
    const now = new Date(Date.UTC(2026, 9, 3)); // Oct 3, 2026
    const logs = [
      new Date(Date.UTC(2026, 9, 1)),
      new Date(Date.UTC(2026, 9, 2)),
      new Date(Date.UTC(2026, 9, 3)),
    ];
    const streak = computeWeeklyStreak(logs, 3, now);
    assert.strictEqual(streak, 1);
  });

  test('Weekly: 3 days in current week and 3 days in previous week returns streak 2', () => {
    const now = new Date(Date.UTC(2026, 9, 3)); // Saturday
    const logs = [
      // Current week
      new Date(Date.UTC(2026, 9, 1)),
      new Date(Date.UTC(2026, 9, 2)),
      new Date(Date.UTC(2026, 9, 3)),
      // Previous week
      new Date(Date.UTC(2026, 8, 24)),
      new Date(Date.UTC(2026, 8, 25)),
      new Date(Date.UTC(2026, 8, 26)),
    ];
    const streak = computeWeeklyStreak(logs, 3, now);
    assert.strictEqual(streak, 2);
  });

  test('Weekly: current week pending but previous week completed preserves streak 1', () => {
    const now = new Date(Date.UTC(2026, 9, 3));
    const logs = [
      // Previous week only
      new Date(Date.UTC(2026, 8, 24)),
      new Date(Date.UTC(2026, 8, 25)),
      new Date(Date.UTC(2026, 8, 26)),
    ];
    const streak = computeWeeklyStreak(logs, 3, now);
    assert.strictEqual(streak, 1);
  });

  // 4. Monthly Count Streak
  test('Monthly: meets monthly target across consecutive calendar months', () => {
    const now = new Date(Date.UTC(2026, 9, 5)); // October 2026
    const logs = [
      // October: 5 completions
      new Date(Date.UTC(2026, 9, 1)),
      new Date(Date.UTC(2026, 9, 2)),
      new Date(Date.UTC(2026, 9, 3)),
      new Date(Date.UTC(2026, 9, 4)),
      new Date(Date.UTC(2026, 9, 5)),
      // September: 5 completions
      new Date(Date.UTC(2026, 8, 10)),
      new Date(Date.UTC(2026, 8, 11)),
      new Date(Date.UTC(2026, 8, 12)),
      new Date(Date.UTC(2026, 8, 13)),
      new Date(Date.UTC(2026, 8, 14)),
      // August: 5 completions
      new Date(Date.UTC(2026, 7, 1)),
      new Date(Date.UTC(2026, 7, 2)),
      new Date(Date.UTC(2026, 7, 3)),
      new Date(Date.UTC(2026, 7, 4)),
      new Date(Date.UTC(2026, 7, 5)),
    ];
    const streak = computeMonthlyStreak(logs, 5, now);
    assert.strictEqual(streak, 3);
  });

  // 5. Server Authoritative Numeric/Duration Completion
  test('Numeric Derivation: value below target is NOT completed even if client says isCompleted: true', () => {
    const res = deriveCompletion('COUNT', 30, { isCompleted: true, value: 15 });
    assert.strictEqual(res.isCompleted, false);
    assert.strictEqual(res.loggedValue, 15);
  });

  test('Numeric Derivation: value reaching target is automatically isCompleted: true', () => {
    const res = deriveCompletion('COUNT', 30, { value: 30 });
    assert.strictEqual(res.isCompleted, true);
    assert.strictEqual(res.loggedValue, 30);
  });

  test('Duration Derivation: duration reaching target is automatically isCompleted: true', () => {
    const res = deriveCompletion('DURATION', 45, { value: 50 });
    assert.strictEqual(res.isCompleted, true);
    assert.strictEqual(res.loggedValue, 50);
  });

  test('Checkbox Derivation: client boolean toggle sets value to targetVal when true', () => {
    const res = deriveCompletion('CHECKBOX', 1, { isCompleted: true });
    assert.strictEqual(res.isCompleted, true);
    assert.strictEqual(res.loggedValue, 1);
  });

  // 6. LifeScore Partial Progress Credit Math
  test('LifeScore: proportional progress ratio for numeric habit is capped at 1.0', () => {
    const targetValue = 30;
    const value10 = 10;
    const value40 = 40;

    const ratio10 = Math.min(1.0, Math.max(0, value10 / targetValue));
    const ratio40 = Math.min(1.0, Math.max(0, value40 / targetValue));

    assert.strictEqual(Number(ratio10.toFixed(2)), 0.33);
    assert.strictEqual(ratio40, 1.0);
  });

  console.log(`\n========================================`);
  console.log(`Domain Logic Results: ${passed} passed, ${failed} failed, ${passed + failed} total`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runDomainLogicTests();
