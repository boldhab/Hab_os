import assert from 'assert';
import {
  FOCUS_CATEGORIES,
  FOCUS_STATUSES,
  startFocusSchema,
  endFocusSchema,
  logCompletedFocusSchema,
  cancelFocusSchema,
  getFocusQuerySchema,
  focusIdParamSchema,
} from '../../src/modules/focus/focus.validation';

console.log('🧪 Running Focus Validation Unit Tests...');

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

// ── 1. Canonical Categories ──────────────────────────────────────────────
runTest('All 6 canonical categories are defined', () => {
  assert.deepStrictEqual([...FOCUS_CATEGORIES], [
    'CODING',
    'STUDY',
    'PROJECT',
    'READING',
    'WELLNESS',
    'OTHER',
  ]);
});

runTest('All 4 lifecycle statuses are defined', () => {
  assert.deepStrictEqual([...FOCUS_STATUSES], [
    'RUNNING',
    'PAUSED',
    'COMPLETED',
    'CANCELLED',
  ]);
});

// ── 2. startFocusSchema ──────────────────────────────────────────────────
runTest('startFocusSchema accepts each canonical category', () => {
  for (const cat of FOCUS_CATEGORIES) {
    const { error, value } = startFocusSchema.validate({ category: cat });
    assert.strictEqual(error, undefined, `Failed on category ${cat}`);
    assert.strictEqual(value.category, cat);
  }
});

runTest('startFocusSchema defaults category to CODING when omitted', () => {
  const { error, value } = startFocusSchema.validate({});
  assert.strictEqual(error, undefined);
  assert.strictEqual(value.category, 'CODING');
});

runTest('startFocusSchema rejects unknown category (e.g. GAMING, SLACK)', () => {
  const { error: err1 } = startFocusSchema.validate({ category: 'GAMING' });
  assert.notStrictEqual(err1, undefined);

  const { error: err2 } = startFocusSchema.validate({ category: 'SLACK' });
  assert.notStrictEqual(err2, undefined);
});

runTest('startFocusSchema accepts valid taskId and courseId UUIDs', () => {
  const validUUID = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
  const { error } = startFocusSchema.validate({
    taskId: validUUID,
    courseId: validUUID,
    notes: 'Deep work sprint',
  });
  assert.strictEqual(error, undefined);
});

runTest('startFocusSchema rejects invalid taskId UUID', () => {
  const { error } = startFocusSchema.validate({ taskId: 'not-a-uuid' });
  assert.notStrictEqual(error, undefined);
});

// ── 3. endFocusSchema ────────────────────────────────────────────────────
runTest('endFocusSchema accepts valid duration and notes', () => {
  const { error } = endFocusSchema.validate({
    durationMinutes: 45,
    notes: 'Finished chapter 4',
  });
  assert.strictEqual(error, undefined);
});

runTest('endFocusSchema requires durationMinutes', () => {
  const { error } = endFocusSchema.validate({ notes: 'missing duration' });
  assert.notStrictEqual(error, undefined);
});

runTest('endFocusSchema rejects non-positive or excessive duration', () => {
  const { error: err0 } = endFocusSchema.validate({ durationMinutes: 0 });
  assert.notStrictEqual(err0, undefined);

  const { error: errNeg } = endFocusSchema.validate({ durationMinutes: -5 });
  assert.notStrictEqual(errNeg, undefined);

  const { error: errTooBig } = endFocusSchema.validate({ durationMinutes: 1500 });
  assert.notStrictEqual(errTooBig, undefined);
});

// ── 4. logCompletedFocusSchema ───────────────────────────────────────────
runTest('logCompletedFocusSchema accepts valid session interval with WELLNESS', () => {
  const start = new Date(Date.now() - 30 * 60 * 1000).toISOString();
  const end = new Date().toISOString();
  const { error } = logCompletedFocusSchema.validate({
    startTime: start,
    endTime: end,
    durationMinutes: 30,
    category: 'WELLNESS',
    notes: 'Morning breathwork and meditation',
  });
  assert.strictEqual(error, undefined);
});

runTest('logCompletedFocusSchema rejects endTime earlier than startTime', () => {
  const start = new Date(Date.now()).toISOString();
  const end = new Date(Date.now() - 30 * 60 * 1000).toISOString();
  const { error } = logCompletedFocusSchema.validate({
    startTime: start,
    endTime: end,
    durationMinutes: 30,
    category: 'STUDY',
  });
  assert.notStrictEqual(error, undefined);
  assert.ok(error?.details[0].message.includes('End time must be after start time') || error?.details[0].type === 'date.greater');
});

// ── 5. cancelFocusSchema ─────────────────────────────────────────────────
runTest('cancelFocusSchema accepts optional notes', () => {
  const { error: err1 } = cancelFocusSchema.validate({});
  assert.strictEqual(err1, undefined);

  const { error: err2 } = cancelFocusSchema.validate({ notes: 'Interrupted by urgent phone call' });
  assert.strictEqual(err2, undefined);
});

// ── 6. focusIdParamSchema ────────────────────────────────────────────────
runTest('focusIdParamSchema validates UUID format', () => {
  const validUUID = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
  const { error: ok } = focusIdParamSchema.validate({ id: validUUID });
  assert.strictEqual(ok, undefined);

  const { error: bad } = focusIdParamSchema.validate({ id: '12345' });
  assert.notStrictEqual(bad, undefined);
});

console.log(`\n🎉 All ${passed}/${total} Focus Validation unit tests passed successfully!\n`);
