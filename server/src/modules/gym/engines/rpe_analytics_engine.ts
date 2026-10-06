/**
 * RPE / RIR Hypertrophy Analytics Engine
 * Filters non-stimulating warm-up sets to isolate genuine hypertrophic mechanical tension.
 *
 * Criterion:
 * A set is classified as an "Effective Working Set" if and only if:
 * - RPE >= 7.0 OR
 * - RIR <= 3
 */

export interface RpeSetEntry {
  weightKg: number;
  repetitions: number;
  rpe?: number | null;
  rir?: number | null;
  tag?: string | null; // W (Warmup), N (Normal), D (Drop Set), F (Failure)
}

export interface RpeWorkoutExercise {
  exercise: {
    id: string;
    name: string;
    category?: string | null;
    muscleGroup?: string | null;
  };
  sets: RpeSetEntry[];
}

export interface RpeWorkoutSession {
  id: string;
  date: Date | string;
  exercises: RpeWorkoutExercise[];
}

export interface MuscleHypertrophySummary {
  muscleGroup: string;
  stimulativeVolumeKg: number;
  totalStructuralVolumeKg: number;
  effectiveSetsCount: number;
  totalSetsCount: number;
  efficiencyPercentage: number;
}

export interface HypertrophyTelemetry {
  stimulativeWorkingVolumeKg: number;
  totalStructuralVolumeKg: number;
  warmupVolumeKg: number;
  stimulativeSetsCount: number;
  warmupSetsCount: number;
  totalSetsCount: number;
  hypertrophicEfficiencyPercentage: number;
  muscleBreakdown: MuscleHypertrophySummary[];
}

/**
 * Criterion for hyper-stimulating effective working set:
 * 1. If explicitly tagged 'W' (Warm-up), strictly isolate and omit from hypertrophy working volume.
 * 2. If explicitly tagged 'D' (Drop Set) or 'F' (Failure / AMRAP), automatically prioritize as stimulative working set.
 * 3. Otherwise evaluate based on RPE >= 7.0 or RIR <= 3 (or positive load default if RPE omitted).
 */
export const isEffectiveSet = (set: RpeSetEntry): boolean => {
  if (set.tag === 'W') {
    return false;
  }
  if (set.tag === 'D' || set.tag === 'F') {
    return true;
  }
  if (set.rpe !== null && set.rpe !== undefined) {
    return set.rpe >= 7.0;
  }
  if (set.rir !== null && set.rir !== undefined) {
    return set.rir <= 3;
  }
  // When RPE/RIR is omitted by user, treat sets with positive load and reps as working sets
  return set.weightKg > 0 && set.repetitions > 0;
};

/**
 * Compute the stimulative mechanical tension and hypertrophy telemetry across workout sessions.
 */
export const calculateHypertrophyTelemetry = (
  workouts: RpeWorkoutSession[]
): HypertrophyTelemetry => {
  let stimulativeVolume = 0;
  let totalVolume = 0;
  let effectiveSetsCount = 0;
  let totalSetsCount = 0;

  const muscleMap: Record<
    string,
    {
      stimulativeVolume: number;
      totalVolume: number;
      effectiveSets: number;
      totalSets: number;
    }
  > = {
    CHEST: { stimulativeVolume: 0, totalVolume: 0, effectiveSets: 0, totalSets: 0 },
    BACK: { stimulativeVolume: 0, totalVolume: 0, effectiveSets: 0, totalSets: 0 },
    LEGS: { stimulativeVolume: 0, totalVolume: 0, effectiveSets: 0, totalSets: 0 },
    SHOULDERS: { stimulativeVolume: 0, totalVolume: 0, effectiveSets: 0, totalSets: 0 },
    ARMS: { stimulativeVolume: 0, totalVolume: 0, effectiveSets: 0, totalSets: 0 },
    CORE: { stimulativeVolume: 0, totalVolume: 0, effectiveSets: 0, totalSets: 0 },
  };

  for (const w of workouts) {
    for (const we of w.exercises) {
      const rawGroup = (we.exercise.muscleGroup || we.exercise.category || 'CHEST').toUpperCase();
      const groupKey = muscleMap[rawGroup] ? rawGroup : 'CHEST';

      for (const s of we.sets) {
        if (s.weightKg <= 0 || s.repetitions <= 0) continue;

        const vol = s.weightKg * s.repetitions;
        totalVolume += vol;
        totalSetsCount += 1;
        muscleMap[groupKey].totalVolume += vol;
        muscleMap[groupKey].totalSets += 1;

        if (isEffectiveSet(s)) {
          stimulativeVolume += vol;
          effectiveSetsCount += 1;
          muscleMap[groupKey].stimulativeVolume += vol;
          muscleMap[groupKey].effectiveSets += 1;
        }
      }
    }
  }

  const warmupVolume = Math.max(0, totalVolume - stimulativeVolume);
  const warmupSetsCount = Math.max(0, totalSetsCount - effectiveSetsCount);
  const efficiencyPercentage =
    totalVolume > 0
      ? Number(((stimulativeVolume / totalVolume) * 100).toFixed(1))
      : 0;

  const muscleBreakdown: MuscleHypertrophySummary[] = Object.keys(muscleMap).map(
    (group) => {
      const data = muscleMap[group];
      const eff =
        data.totalVolume > 0
          ? Number(((data.stimulativeVolume / data.totalVolume) * 100).toFixed(1))
          : 0;
      return {
        muscleGroup: group,
        stimulativeVolumeKg: Number(data.stimulativeVolume.toFixed(1)),
        totalStructuralVolumeKg: Number(data.totalVolume.toFixed(1)),
        effectiveSetsCount: data.effectiveSets,
        totalSetsCount: data.totalSets,
        efficiencyPercentage: eff,
      };
    }
  );

  return {
    stimulativeWorkingVolumeKg: Number(stimulativeVolume.toFixed(1)),
    totalStructuralVolumeKg: Number(totalVolume.toFixed(1)),
    warmupVolumeKg: Number(warmupVolume.toFixed(1)),
    stimulativeSetsCount: effectiveSetsCount,
    warmupSetsCount,
    totalSetsCount,
    hypertrophicEfficiencyPercentage: efficiencyPercentage,
    muscleBreakdown,
  };
};
