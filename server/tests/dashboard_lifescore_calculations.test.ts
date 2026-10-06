function assert(condition: boolean, message: string) {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

async function runDashboardLifeScoreUnitTests() {
  console.log('🧪 Starting Dashboard & Life Score Pure Calculation Unit Suite...\n');

  let passed = 0;
  let total = 0;

  function test(name: string, fn: () => void) {
    total++;
    try {
      fn();
      console.log(`  ✅ ${name}`);
      passed++;
    } catch (err: any) {
      console.error(`  ❌ ${name}: ${err.message}`);
      throw err;
    }
  }

  // ============================================================
  // 1. LIFE SCORE WEIGHT NORMALIZATION & CUSTOM WEIGHTS
  // ============================================================
  console.log('--- 1. Life Score Weight Normalization & Custom Weights ---');

  const computeNormalizedLifeScore = (
    scores: { tasks: number; habits: number; coding: number; study: number; gym: number; finance: number },
    customWeights: Record<string, number> = {}
  ) => {
    const defaultWeights = {
      tasks: 0.20,
      habits: 0.20,
      coding: 0.15,
      study: 0.15,
      gym: 0.15,
      finance: 0.15,
    };

    // Backward compatibility: map legacy 'focus' to coding & study if coding/study are missing
    const legacyFocus = typeof customWeights.focus === 'number' ? customWeights.focus : undefined;
    const rawCoding = typeof customWeights.coding === 'number'
      ? customWeights.coding
      : (legacyFocus !== undefined ? legacyFocus / 2 : undefined);
    const rawStudy = typeof customWeights.study === 'number'
      ? customWeights.study
      : (legacyFocus !== undefined ? legacyFocus / 2 : undefined);

    // Check if customWeights are in percentage scale (> 1.0)
    const numericValues = [
      customWeights.tasks,
      customWeights.habits,
      rawCoding,
      rawStudy,
      customWeights.gym,
      customWeights.finance,
    ].filter((v): v is number => typeof v === 'number');

    const isPercentageScale = numericValues.some((v) => v > 1.0);
    const scaleMultiplier = isPercentageScale ? 100 : 1;

    const weights = {
      tasks: typeof customWeights.tasks === 'number' ? Math.max(0, customWeights.tasks) : defaultWeights.tasks * scaleMultiplier,
      habits: typeof customWeights.habits === 'number' ? Math.max(0, customWeights.habits) : defaultWeights.habits * scaleMultiplier,
      coding: typeof rawCoding === 'number' ? Math.max(0, rawCoding) : defaultWeights.coding * scaleMultiplier,
      study: typeof rawStudy === 'number' ? Math.max(0, rawStudy) : defaultWeights.study * scaleMultiplier,
      gym: typeof customWeights.gym === 'number' ? Math.max(0, customWeights.gym) : defaultWeights.gym * scaleMultiplier,
      finance: typeof customWeights.finance === 'number' ? Math.max(0, customWeights.finance) : defaultWeights.finance * scaleMultiplier,
    };

    const rawOverall =
      scores.tasks * weights.tasks +
      scores.habits * weights.habits +
      scores.coding * weights.coding +
      scores.study * weights.study +
      scores.gym * weights.gym +
      scores.finance * weights.finance;

    const totalWeight = Object.values(weights).reduce((sum, weight) => sum + weight, 0);
    return Number((totalWeight > 0 ? rawOverall / totalWeight : 0).toFixed(1));
  };

  test('Default weights sum to 1.0 and calculate accurate composite score', () => {
    const scores = { tasks: 80, habits: 90, coding: 100, study: 70, gym: 60, finance: 85 };
    // 80*0.2 + 90*0.2 + 100*0.15 + 70*0.15 + 60*0.15 + 85*0.15
    // = 16 + 18 + 15 + 10.5 + 9 + 12.75 = 81.25 -> 81.3
    const score = computeNormalizedLifeScore(scores);
    assert(score === 81.3, `Default score should be 81.3, got ${score}`);
  });

  test('Custom weights summing to > 1.0 are properly normalized by totalWeight', () => {
    const scores = { tasks: 100, habits: 100, coding: 50, study: 50, gym: 50, finance: 50 };
    // Set all weights to 2.0 (total weight = 12.0)
    const customWeights = { tasks: 2, habits: 2, coding: 2, study: 2, gym: 2, finance: 2 };
    // Average should be (100*4 + 50*8) / 12 = 800 / 12 = 66.7
    const score = computeNormalizedLifeScore(scores, customWeights);
    assert(score === 66.7, `Normalized score should be 66.7, got ${score}`);
  });

  test('Legacy focus weight splits evenly into coding and study when omitted', () => {
    const scores = { tasks: 100, habits: 100, coding: 60, study: 40, gym: 80, finance: 80 };
    // Legacy payload with focus: 20
    const legacyWeights = { tasks: 20, habits: 20, focus: 20, gym: 20, finance: 20 };
    // focus: 20 -> coding: 10, study: 10. All 6 domains sum to 100.
    // 100*20 + 100*20 + 60*10 + 40*10 + 80*20 + 80*20 = 2000 + 2000 + 600 + 400 + 1600 + 1600 = 8200 / 100 = 82.0
    const score = computeNormalizedLifeScore(scores, legacyWeights);
    assert(score === 82.0, `Score with legacy focus should be 82.0, got ${score}`);
  });

  test('Negative custom weights are clamped to 0 without corrupting sum', () => {
    const scores = { tasks: 100, habits: 80, coding: 80, study: 80, gym: 80, finance: 80 };
    // Negative weight on tasks: should be clamped to 0
    const customWeights = { tasks: -0.5, habits: 0.2, coding: 0.2, study: 0.2, gym: 0.2, finance: 0.2 };
    // Total weight = 1.0. Tasks (100) ignored. Overall = 80
    const score = computeNormalizedLifeScore(scores, customWeights);
    assert(score === 80.0, `Score should be 80.0 with clamped negative weight, got ${score}`);
  });

  test('All zero weights safely return 0 without NaN', () => {
    const scores = { tasks: 100, habits: 100, coding: 100, study: 100, gym: 100, finance: 100 };
    const customWeights = { tasks: 0, habits: 0, coding: 0, study: 0, gym: 0, finance: 0 };
    const score = computeNormalizedLifeScore(scores, customWeights);
    assert(score === 0.0, `Zero weights should return 0.0, got ${score}`);
    assert(!isNaN(score), 'Score must not be NaN');
  });

  // ============================================================
  // 2. UTC BOUNDARY & TIMELINE CALCULATIONS
  // ============================================================
  console.log('\n--- 2. UTC Date Boundary & Immutable Time Calculations ---');

  const getUtcBoundaries = (date: Date) => {
    const utcYear = date.getUTCFullYear();
    const utcMonth = date.getUTCMonth();
    const utcDate = date.getUTCDate();

    const startOfToday = new Date(Date.UTC(utcYear, utcMonth, utcDate, 0, 0, 0, 0));
    const endOfToday = new Date(Date.UTC(utcYear, utcMonth, utcDate, 23, 59, 59, 999));

    const dayOfWeek = date.getUTCDay();
    const daysFromMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    const startOfWeek = new Date(startOfToday);
    startOfWeek.setUTCDate(startOfWeek.getUTCDate() - daysFromMonday);

    const startOfMonth = new Date(Date.UTC(utcYear, utcMonth, 1, 0, 0, 0, 0));
    const startOfNextMonth = new Date(Date.UTC(utcYear, utcMonth + 1, 1, 0, 0, 0, 0));

    return { startOfToday, endOfToday, startOfWeek, startOfMonth, startOfNextMonth };
  };

  test('UTC boundaries normalize midnight and preserve reference date immutability', () => {
    const refDate = new Date('2026-10-03T15:30:45.123Z'); // Saturday
    const refTimestamp = refDate.getTime();

    const b = getUtcBoundaries(refDate);

    // Reference timestamp was NOT mutated
    assert(refDate.getTime() === refTimestamp, 'Reference Date must not be mutated by calculation');

    // Start of day is midnight UTC
    assert(b.startOfToday.toISOString() === '2026-10-03T00:00:00.000Z', 'Start of today is 00:00:00.000Z');
    assert(b.endOfToday.toISOString() === '2026-10-03T23:59:59.999Z', 'End of today is 23:59:59.999Z');

    // Monday of this week: Saturday is day 6, Monday was 2026-09-28
    assert(b.startOfWeek.toISOString() === '2026-09-28T00:00:00.000Z', `Start of week is 2026-09-28, got ${b.startOfWeek.toISOString()}`);

    // Start of month is 2026-10-01
    assert(b.startOfMonth.toISOString() === '2026-10-01T00:00:00.000Z', 'Start of month is 2026-10-01');
    assert(b.startOfNextMonth.toISOString() === '2026-11-01T00:00:00.000Z', 'Start of next month is 2026-11-01');
  });

  test('Sunday maps back to the Monday of that same week', () => {
    const sunday = new Date('2026-10-04T12:00:00.000Z'); // Sunday
    const b = getUtcBoundaries(sunday);
    assert(b.startOfWeek.toISOString() === '2026-09-28T00:00:00.000Z', 'Sunday start of week is Monday 2026-09-28');
  });

  // ============================================================
  // 3. WORKOUT AND BUDGET FILTERING
  // ============================================================
  console.log('\n--- 3. Workout & Budget Date Filtering Rules ---');

  test('Future workouts are excluded from weekly completed workouts', () => {
    const now = new Date('2026-10-03T12:00:00.000Z');
    const startOfWeek = new Date('2026-09-28T00:00:00.000Z');

    const workouts = [
      { id: '1', date: new Date('2026-09-29T10:00:00.000Z') }, // this week past -> INCLUDE
      { id: '2', date: new Date('2026-10-02T18:00:00.000Z') }, // this week past -> INCLUDE
      { id: '3', date: new Date('2026-09-20T10:00:00.000Z') }, // last week -> EXCLUDE
      { id: '4', date: new Date('2026-10-04T18:00:00.000Z') }, // future workout -> EXCLUDE
    ];

    const validWorkouts = workouts.filter((w) => w.date >= startOfWeek && w.date <= now);
    assert(validWorkouts.length === 2, `Expected 2 valid workouts, got ${validWorkouts.length}`);
    assert(validWorkouts.map((w) => w.id).sort().join(',') === '1,2', 'Only past workouts this week are included');
  });

  test('Monthly budget and expenses correctly filter to current month', () => {
    const startOfMonth = new Date('2026-10-01T00:00:00.000Z');
    const startOfNextMonth = new Date('2026-11-01T00:00:00.000Z');

    const expenses = [
      { id: '1', amount: 45.0, date: new Date('2026-10-02T10:00:00Z') }, // current month
      { id: '2', amount: 120.0, date: new Date('2026-10-15T10:00:00Z') }, // current month
      { id: '3', amount: 80.0, date: new Date('2026-09-30T23:59:59Z') }, // previous month -> EXCLUDE
      { id: '4', amount: 50.0, date: new Date('2026-11-01T00:00:01Z') }, // next month -> EXCLUDE
    ];

    const monthExpenses = expenses.filter((e) => e.date >= startOfMonth && e.date < startOfNextMonth);
    const totalSpent = monthExpenses.reduce((sum, e) => sum + e.amount, 0);

    assert(monthExpenses.length === 2, `Expected 2 expenses, got ${monthExpenses.length}`);
    assert(totalSpent === 165.0, `Expected $165.0 spent, got $${totalSpent}`);
  });

  // ============================================================
  // 4. DASHBOARD MODULE PREFERENCES
  // ============================================================
  console.log('\n--- 4. Dashboard Module Visibility Logic ---');

  test('Module visibility helper respects user preferences and provides defaults', () => {
    const defaultModules = [
      'LIFE_SCORE',
      'HABITS',
      'TASKS',
      'SCHEDULE',
      'ACADEMIC',
      'PROJECTS',
      'FITNESS',
      'FINANCE',
      'RECENT_ACTIVITY',
    ];

    const isModuleEnabled = (moduleName: string, userPref?: string[]) => {
      const active = (userPref && userPref.length > 0) ? userPref : defaultModules;
      return active.includes(moduleName);
    };

    // Default: all enabled
    assert(isModuleEnabled('LIFE_SCORE'), 'LIFE_SCORE enabled by default');
    assert(isModuleEnabled('FINANCE'), 'FINANCE enabled by default');

    // Custom: user only wants TASKS and HABITS
    const customUser = ['TASKS', 'HABITS'];
    assert(isModuleEnabled('TASKS', customUser), 'TASKS enabled in custom pref');
    assert(isModuleEnabled('HABITS', customUser), 'HABITS enabled in custom pref');
    assert(!isModuleEnabled('FINANCE', customUser), 'FINANCE disabled in custom pref');
    assert(!isModuleEnabled('FITNESS', customUser), 'FITNESS disabled in custom pref');
  });

  console.log(`\n🎉 All ${passed}/${total} Dashboard & Life Score Unit Tests Passed Successfully!\n`);
}

runDashboardLifeScoreUnitTests()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Unit tests failed:', err);
    process.exit(1);
  });
