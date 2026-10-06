import {
  createHabitSchema,
  updateHabitSchema,
  logHabitSchema,
} from '../../src/modules/habits/habits.validation';

interface TestCase {
  name: string;
  schema: any;
  payload: any;
  expectValid: boolean;
  expectedErrorSubstr?: string;
}

const testCases: TestCase[] = [
  // ── 1. Create Habit Frequency Matrix ──────────────────────────────────────────
  {
    name: 'Valid daily habit with default period',
    schema: createHabitSchema,
    payload: {
      name: 'Drink Water',
      frequency: 'DAILY',
    },
    expectValid: true,
  },
  {
    name: 'Valid daily habit with DAY period',
    schema: createHabitSchema,
    payload: {
      name: 'Morning Walk',
      frequency: 'DAILY',
      targetFrequencyPeriod: 'DAY',
      targetFrequencyCount: 1,
    },
    expectValid: true,
  },
  {
    name: 'Valid weekly habit with 4 days per week',
    schema: createHabitSchema,
    payload: {
      name: 'Gym Workout',
      frequency: 'WEEKLY',
      targetFrequencyPeriod: 'WEEK',
      targetFrequencyCount: 4,
    },
    expectValid: true,
  },
  {
    name: 'Valid custom monthly habit with 15 days per month',
    schema: createHabitSchema,
    payload: {
      name: 'Book Reading',
      frequency: 'CUSTOM',
      targetFrequencyPeriod: 'MONTH',
      targetFrequencyCount: 15,
    },
    expectValid: true,
  },
  {
    name: 'Invalid: DAILY frequency paired with MONTH period',
    schema: createHabitSchema,
    payload: {
      name: 'Invalid Daily Monthly',
      frequency: 'DAILY',
      targetFrequencyPeriod: 'MONTH',
    },
    expectValid: false,
    expectedErrorSubstr: 'Daily habits cannot have a monthly target period',
  },
  {
    name: 'Invalid: WEEKLY frequency paired with MONTH period',
    schema: createHabitSchema,
    payload: {
      name: 'Invalid Weekly Monthly',
      frequency: 'WEEKLY',
      targetFrequencyPeriod: 'MONTH',
    },
    expectValid: false,
    expectedErrorSubstr: 'Weekly habits cannot have a monthly target period',
  },
  {
    name: 'Invalid: WEEKLY frequency paired with DAY period',
    schema: createHabitSchema,
    payload: {
      name: 'Invalid Weekly Day',
      frequency: 'WEEKLY',
      targetFrequencyPeriod: 'DAY',
    },
    expectValid: false,
    expectedErrorSubstr: 'Weekly habits cannot have a daily target period',
  },
  {
    name: 'Invalid: WEEK period exceeding 7 days count',
    schema: createHabitSchema,
    payload: {
      name: 'Too Many Days',
      frequency: 'WEEKLY',
      targetFrequencyPeriod: 'WEEK',
      targetFrequencyCount: 8,
    },
    expectValid: false,
    expectedErrorSubstr: 'Weekly target count cannot exceed 7 days',
  },
  {
    name: 'Invalid: MONTH period exceeding 31 days count',
    schema: createHabitSchema,
    payload: {
      name: 'Too Many Months',
      frequency: 'CUSTOM',
      targetFrequencyPeriod: 'MONTH',
      targetFrequencyCount: 32,
    },
    expectValid: false,
    expectedErrorSubstr: 'Monthly target count cannot exceed 31 days',
  },
  {
    name: 'Invalid: DAY period with count > 1',
    schema: createHabitSchema,
    payload: {
      name: 'Too Many Daily Reps',
      frequency: 'DAILY',
      targetFrequencyPeriod: 'DAY',
      targetFrequencyCount: 3,
    },
    expectValid: false,
    expectedErrorSubstr: 'Daily period target count cannot exceed 1',
  },

  // ── 2. Update Habit Frequency Matrix ──────────────────────────────────────────
  {
    name: 'Valid update habit payload',
    schema: updateHabitSchema,
    payload: {
      name: 'Updated Water Target',
      frequency: 'DAILY',
      targetFrequencyPeriod: 'DAY',
    },
    expectValid: true,
  },
  {
    name: 'Invalid update: DAILY paired with MONTH',
    schema: updateHabitSchema,
    payload: {
      frequency: 'DAILY',
      targetFrequencyPeriod: 'MONTH',
    },
    expectValid: false,
    expectedErrorSubstr: 'Daily habits cannot have a monthly target period',
  },

  // ── 3. Log Habit Completion & Value Consistency ───────────────────────────────
  {
    name: 'Valid log: isCompleted true with value > 0',
    schema: logHabitSchema,
    payload: {
      isCompleted: true,
      value: 5,
    },
    expectValid: true,
  },
  {
    name: 'Valid log: isCompleted false with value 0',
    schema: logHabitSchema,
    payload: {
      isCompleted: false,
      value: 0,
    },
    expectValid: true,
  },
  {
    name: 'Valid log: partial progress (isCompleted false, value 15)',
    schema: logHabitSchema,
    payload: {
      isCompleted: false,
      value: 15,
    },
    expectValid: true,
  },
  {
    name: 'Invalid log: contradictory isCompleted true with value 0',
    schema: logHabitSchema,
    payload: {
      isCompleted: true,
      value: 0,
    },
    expectValid: false,
    expectedErrorSubstr: 'Cannot mark habit as completed with a value of 0',
  },
];

async function runValidationTests() {
  console.log('🧪 Running Habits Validation Matrix & Schema Unit Tests...\n');
  let passed = 0;
  let failed = 0;

  for (const tc of testCases) {
    const { error, value } = tc.schema.validate(tc.payload, { abortEarly: false });
    const isValid = !error;

    if (isValid === tc.expectValid) {
      if (!tc.expectValid && tc.expectedErrorSubstr) {
        const errorMsg = error?.details.map((d: any) => d.message).join('; ') || '';
        if (!errorMsg.includes(tc.expectedErrorSubstr)) {
          console.error(`❌ FAIL: ${tc.name}`);
          console.error(`   Expected error message to contain: "${tc.expectedErrorSubstr}"`);
          console.error(`   Actual error message: "${errorMsg}"`);
          failed++;
          continue;
        }
      }
      console.log(`✅ PASS: ${tc.name}`);
      passed++;
    } else {
      console.error(`❌ FAIL: ${tc.name}`);
      console.error(`   Expected valid: ${tc.expectValid}, Got valid: ${isValid}`);
      if (error) {
        console.error(`   Errors: ${error.details.map((d: any) => d.message).join('; ')}`);
      }
      failed++;
    }
  }

  console.log(`\n========================================`);
  console.log(`Validation Results: ${passed} passed, ${failed} failed, ${testCases.length} total`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runValidationTests();
