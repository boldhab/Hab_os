import {
  calculateACWR,
  calculatePushPullSymmetry,
  calculateFatigueAccumulationIndex,
  runSportsScienceDiagnostics,
  WorkoutHistoryItem,
} from '../../src/modules/gym/engines/sports_science_engine';
import {
  isEffectiveSet,
  calculateHypertrophyTelemetry,
  RpeWorkoutSession,
} from '../../src/modules/gym/engines/rpe_analytics_engine';

function assert(condition: boolean, message: string) {
  if (!condition) {
    console.error(`❌ FAILED: ${message}`);
    process.exit(1);
  }
  console.log(`  ✅ ${message}`);
}

console.log('🧪 Running Sports Science & Biomechanical Diagnostics Test Suite...\n');

// 1. Test ACWR Spikes
console.log('--- 1. Acute-to-Chronic Workload Ratio (ACWR) ---');
const baseDate = new Date('2026-10-04T12:00:00Z');
const dayMs = 24 * 60 * 60 * 1000;

// Scenario A: Steady chronic baseline of ~10,000 kg/week for 4 weeks (weeks 1-4 prior)
// followed by an acute week of 12,500 kg (25% increase -> should trigger VOLUME_SPIKE_WARNING)
const mockWorkoutsForACWR: WorkoutHistoryItem[] = [
  // Chronic week 4 (28-35 days ago)
  {
    id: 'w-c4',
    date: new Date(baseDate.getTime() - 30 * dayMs),
    name: 'Leg Day C4',
    exercises: [
      {
        exercise: { id: 'e1', name: 'Squat', category: 'LEGS', muscleGroup: 'LEGS' },
        sets: [{ weightKg: 100, repetitions: 100 }], // 10,000 kg
      },
    ],
  },
  // Chronic week 3 (21-28 days ago)
  {
    id: 'w-c3',
    date: new Date(baseDate.getTime() - 23 * dayMs),
    name: 'Leg Day C3',
    exercises: [
      {
        exercise: { id: 'e1', name: 'Squat', category: 'LEGS', muscleGroup: 'LEGS' },
        sets: [{ weightKg: 100, repetitions: 100 }], // 10,000 kg
      },
    ],
  },
  // Chronic week 2 (14-21 days ago)
  {
    id: 'w-c2',
    date: new Date(baseDate.getTime() - 16 * dayMs),
    name: 'Leg Day C2',
    exercises: [
      {
        exercise: { id: 'e1', name: 'Squat', category: 'LEGS', muscleGroup: 'LEGS' },
        sets: [{ weightKg: 100, repetitions: 100 }], // 10,000 kg
      },
    ],
  },
  // Chronic week 1 (7-14 days ago)
  {
    id: 'w-c1',
    date: new Date(baseDate.getTime() - 9 * dayMs),
    name: 'Leg Day C1',
    exercises: [
      {
        exercise: { id: 'e1', name: 'Squat', category: 'LEGS', muscleGroup: 'LEGS' },
        sets: [{ weightKg: 100, repetitions: 100 }], // 10,000 kg
      },
    ],
  },
  // Acute week (last 7 days) -> 12,500 kg (spike > 15%)
  {
    id: 'w-a1',
    date: new Date(baseDate.getTime() - 2 * dayMs),
    name: 'Spike Day',
    exercises: [
      {
        exercise: { id: 'e1', name: 'Squat', category: 'LEGS', muscleGroup: 'LEGS' },
        sets: [{ weightKg: 125, repetitions: 100 }], // 12,500 kg
      },
    ],
  },
];

const acwrResult = calculateACWR(mockWorkoutsForACWR, baseDate);
assert(acwrResult.isSpike === true, 'ACWR correctly detects workload spike > 15%');
assert(acwrResult.ratio >= 1.2, `ACWR ratio accurately computed (${acwrResult.ratio} >= 1.2)`);
assert(acwrResult.insight?.type === 'VOLUME_SPIKE_WARNING', 'Generates VOLUME_SPIKE_WARNING insight token');

// Scenario B: Normal progression (e.g. 5% increase)
const mockNormalACWR: WorkoutHistoryItem[] = [
  ...mockWorkoutsForACWR.slice(0, 4),
  {
    id: 'w-norm',
    date: new Date(baseDate.getTime() - 2 * dayMs),
    name: 'Normal Day',
    exercises: [
      {
        exercise: { id: 'e1', name: 'Squat', category: 'LEGS', muscleGroup: 'LEGS' },
        sets: [{ weightKg: 105, repetitions: 100 }], // 10,500 kg (+5%)
      },
    ],
  },
];
const normalAcwr = calculateACWR(mockNormalACWR, baseDate);
assert(normalAcwr.isSpike === false, 'Safe progression under 15% does not flag spike');
assert(normalAcwr.insight?.type === 'OPTIMAL_WORKLOAD', 'Flags OPTIMAL_WORKLOAD in safe adaptation zone');

// 2. Test Push/Pull Symmetry
console.log('\n--- 2. Push/Pull Biomechanical Symmetry ---');
// Scenario A: Chest/Shoulders 10,000 kg vs Back 5,000 kg (100% anterior dominance, > 30%)
const mockImbalancedPushPull: WorkoutHistoryItem[] = [
  {
    id: 'w-push',
    date: new Date(baseDate.getTime() - 3 * dayMs),
    name: 'Push Workout',
    exercises: [
      {
        exercise: { id: 'e-bench', name: 'Bench Press', category: 'CHEST', muscleGroup: 'CHEST' },
        sets: [{ weightKg: 100, repetitions: 70 }], // 7,000 kg
      },
      {
        exercise: { id: 'e-ohp', name: 'Overhead Press', category: 'SHOULDERS', muscleGroup: 'SHOULDERS' },
        sets: [{ weightKg: 50, repetitions: 60 }], // 3,000 kg (Total Push: 10,000 kg)
      },
    ],
  },
  {
    id: 'w-pull',
    date: new Date(baseDate.getTime() - 4 * dayMs),
    name: 'Pull Workout',
    exercises: [
      {
        exercise: { id: 'e-row', name: 'Barbell Row', category: 'BACK', muscleGroup: 'BACK' },
        sets: [{ weightKg: 100, repetitions: 50 }], // 5,000 kg (Total Pull: 5,000 kg)
      },
    ],
  },
];

const symResult = calculatePushPullSymmetry(mockImbalancedPushPull, baseDate);
assert(symResult.isImbalanced === true, 'Correctly flags push/pull imbalance when Anterior > Posterior * 1.30');
assert(symResult.insight?.type === 'PUSH_PULL_IMBALANCE_WARNING', 'Injects PUSH_PULL_IMBALANCE_WARNING');

// Scenario B: Balanced push and pull (e.g. 5,000 kg push vs 5,000 kg pull)
const mockBalancedPushPull: WorkoutHistoryItem[] = [
  {
    id: 'w-push-bal',
    date: new Date(baseDate.getTime() - 3 * dayMs),
    name: 'Push Balanced',
    exercises: [
      {
        exercise: { id: 'e-bench', name: 'Bench Press', category: 'CHEST', muscleGroup: 'CHEST' },
        sets: [{ weightKg: 100, repetitions: 50 }], // 5,000 kg
      },
    ],
  },
  {
    id: 'w-pull-bal',
    date: new Date(baseDate.getTime() - 4 * dayMs),
    name: 'Pull Balanced',
    exercises: [
      {
        exercise: { id: 'e-row', name: 'Barbell Row', category: 'BACK', muscleGroup: 'BACK' },
        sets: [{ weightKg: 100, repetitions: 50 }], // 5,000 kg
      },
    ],
  },
];
const symBalanced = calculatePushPullSymmetry(mockBalancedPushPull, baseDate);
assert(symBalanced.isImbalanced === false, 'Balanced push/pull does not trigger warning');
assert(symBalanced.insight?.type === 'STRUCTURAL_SYMMETRY', 'Flags STRUCTURAL_SYMMETRY');

// 3. Test Fatigue Accumulation & Deload
console.log('\n--- 3. Fatigue Accumulation Index & Deload Recommendation ---');
// Create 5 consecutive weeks with 3+ sessions and high tonnage
const mockHighFatigueWorkouts: WorkoutHistoryItem[] = [];
for (let week = 0; week < 5; week++) {
  for (let s = 1; s <= 3; s++) {
    mockHighFatigueWorkouts.push({
      id: `w-${week}-${s}`,
      date: new Date(baseDate.getTime() - (week * 7 + s) * dayMs),
      name: `Heavy Session W${week} S${s}`,
      exercises: [
        {
          exercise: { id: 'e-all', name: 'Compound', category: 'LEGS', muscleGroup: 'LEGS' },
          sets: [{ weightKg: 100, repetitions: 50 }], // 5,000 kg per session
        },
      ],
    });
  }
}

const fatigueResult = calculateFatigueAccumulationIndex(mockHighFatigueWorkouts, baseDate);
assert(fatigueResult.consecutiveHighVolumeWeeks >= 4, `Identifies ${fatigueResult.consecutiveHighVolumeWeeks} consecutive high-volume weeks`);
assert(fatigueResult.deloadRecommended === true, 'Recommends DELOAD after 4-6 continuous weeks');
assert(fatigueResult.insight?.type === 'DELOAD_RECOMMENDATION', 'Injects DELOAD_RECOMMENDATION notification');

// 4. Test RPE / RIR Hypertrophy Analytics Engine
console.log('\n--- 4. RPE / RIR Hypertrophy Working Volume vs Warm-up Filtering ---');
assert(isEffectiveSet({ weightKg: 100, repetitions: 8, rpe: 8.0 }) === true, 'RPE 8 is classified as effective working set (RPE >= 7)');
assert(isEffectiveSet({ weightKg: 100, repetitions: 8, rpe: 6.5 }) === false, 'RPE 6.5 is filtered out as warm-up / non-stimulating set');
assert(isEffectiveSet({ weightKg: 100, repetitions: 8, rir: 2 }) === true, 'RIR 2 is classified as effective working set (RIR <= 3)');
assert(isEffectiveSet({ weightKg: 100, repetitions: 8, rir: 4 }) === false, 'RIR 4 is filtered out as warm-up (RIR > 3)');

const mockRpeSessions: RpeWorkoutSession[] = [
  {
    id: 's1',
    date: baseDate,
    exercises: [
      {
        exercise: { id: 'e1', name: 'Barbell Bench Press', muscleGroup: 'CHEST' },
        sets: [
          { weightKg: 40, repetitions: 15, rpe: 5.0 }, // 600 kg Warmup
          { weightKg: 60, repetitions: 10, rpe: 6.0 }, // 600 kg Warmup
          { weightKg: 100, repetitions: 8, rpe: 8.5 }, // 800 kg Stimulative
          { weightKg: 100, repetitions: 7, rpe: 9.0 }, // 700 kg Stimulative
          { weightKg: 100, repetitions: 6, rir: 1 },   // 600 kg Stimulative
        ],
      },
    ],
  },
];

const telemetry = calculateHypertrophyTelemetry(mockRpeSessions);
assert(telemetry.totalStructuralVolumeKg === 3300, `Total Structural Volume is 3,300 kg (got ${telemetry.totalStructuralVolumeKg})`);
assert(telemetry.stimulativeWorkingVolumeKg === 2100, `Stimulative Working Volume is 2,100 kg (got ${telemetry.stimulativeWorkingVolumeKg})`);
assert(telemetry.warmupVolumeKg === 1200, `Warmup Volume is 1,200 kg (got ${telemetry.warmupVolumeKg})`);
assert(telemetry.stimulativeSetsCount === 3, 'Stimulative Sets Count is 3');
assert(telemetry.warmupSetsCount === 2, 'Warmup Sets Count is 2');
assert(telemetry.totalSetsCount === 5, 'Total Sets Count is 5');
assert(telemetry.hypertrophicEfficiencyPercentage === 63.6, `Hypertrophic efficiency ratio is 63.6% (got ${telemetry.hypertrophicEfficiencyPercentage}%)`);

// 5. Test Tagging Architecture (W, N, D, F)
console.log('\n--- 5. Tag-based Hypertrophy Classification ---');
assert(isEffectiveSet({ weightKg: 100, repetitions: 8, rpe: 9.0, tag: 'W' }) === false, 'Tag W unconditionally overrides RPE 9.0 to non-stimulating warm-up');
assert(isEffectiveSet({ weightKg: 100, repetitions: 8, rpe: 5.0, tag: 'D' }) === true, 'Tag D unconditionally qualifies as effective drop set regardless of lower RPE');
assert(isEffectiveSet({ weightKg: 100, repetitions: 8, rpe: 6.0, tag: 'F' }) === true, 'Tag F unconditionally qualifies as effective failure set');
assert(isEffectiveSet({ weightKg: 100, repetitions: 8, rpe: 8.0, tag: 'N' }) === true, 'Tag N evaluates via standard RPE/RIR thresholds');

// 6. Test Cross-Module Analytics (Focus & LifeScore synergy)
console.log('\n--- 6. Cross-Module Cognitive & Sleep Correlations ---');
const crossDiagnostics = runSportsScienceDiagnostics(
  [
    {
      id: 'w1',
      date: '2026-10-04T10:00:00Z',
      name: 'High Sleep Session',
      exercises: [
        {
          exercise: { id: 'e1', name: 'Bench', category: 'CHEST', muscleGroup: 'CHEST' },
          sets: [{ weightKg: 100, repetitions: 10, tag: 'N' }],
        },
      ],
    },
    {
      id: 'w2',
      date: '2026-10-01T10:00:00Z',
      name: 'Low Sleep Session',
      exercises: [
        {
          exercise: { id: 'e1', name: 'Bench', category: 'CHEST', muscleGroup: 'CHEST' },
          sets: [{ weightKg: 80, repetitions: 10, tag: 'N' }],
        },
      ],
    },
    {
      id: 'w3',
      date: '2026-09-28T10:00:00Z',
      name: 'Heavy Focus Session 1',
      exercises: [
        {
          exercise: { id: 'e1', name: 'Deadlift', category: 'BACK', muscleGroup: 'BACK' },
          sets: [{ weightKg: 140, repetitions: 5, rpe: 9.0, tag: 'N' }],
        },
      ],
    },
    {
      id: 'w4',
      date: '2026-09-25T10:00:00Z',
      name: 'Heavy Focus Session 2',
      exercises: [
        {
          exercise: { id: 'e1', name: 'Deadlift', category: 'BACK', muscleGroup: 'BACK' },
          sets: [{ weightKg: 140, repetitions: 5, rpe: 9.0, tag: 'N' }],
        },
      ],
    },
  ],
  baseDate,
  {
    focusSessions: [
      { durationMinutes: 250, category: 'CODING', status: 'COMPLETED', startTime: '2026-09-28T09:00:00Z' },
      { durationMinutes: 260, category: 'STUDY', status: 'COMPLETED', startTime: '2026-09-25T09:00:00Z' },
    ],
    lifeScoreLogs: [
      { date: '2026-10-04T00:00:00Z', overallScore: 85 },
      { date: '2026-10-01T00:00:00Z', overallScore: 50 },
    ],
  }
);

assert(
  crossDiagnostics.insights.some((i) => i.type === 'COGNITIVE_FATIGUE_CORRELATION'),
  'Flags COGNITIVE_FATIGUE_CORRELATION when sessions coincide with heavy focus days'
);
assert(
  crossDiagnostics.insights.some((i) => i.type === 'SLEEP_PERFORMANCE_CORRELATION'),
  'Flags SLEEP_PERFORMANCE_CORRELATION when high recovery scores produce greater tonnage'
);

console.log('\n🎉 ALL Sports Science & Hypertrophy Analytics Tests Passed Successfully!');
