/**
 * Sports Science Engine - Biomechanical & Workload Analytics
 * Implements:
 * 1. Acute-to-Chronic Workload Ratio (ACWR) with Volume Spike Warning (>15% increase)
 * 2. Push/Pull Biomechanical Symmetry over rolling 14-day window (>30% anterior dominance flag)
 * 3. Fatigue Accumulation Index & Deload Recommendation (4-6 weeks continuous high volume)
 */

export interface SetMetric {
  weightKg: number;
  repetitions: number;
  rpe?: number | null;
  rir?: number | null;
  tag?: string | null; // W, N, D, F
  durationSeconds?: number | null;
  distanceMeters?: number | null;
  caloriesBurned?: number | null;
}

export interface WorkoutExerciseWithMeta {
  exercise: {
    id: string;
    name: string;
    category: string;
    muscleGroup: string;
    equipmentType?: string | null;
  };
  sets: SetMetric[];
}

export interface WorkoutHistoryItem {
  id: string;
  date: Date | string;
  name: string;
  exercises: WorkoutExerciseWithMeta[];
}

export interface CrossModuleContext {
  focusSessions?: Array<{
    durationMinutes: number;
    category: string;
    status: string;
    startTime: Date | string;
  }>;
  lifeScoreLogs?: Array<{
    date: Date | string;
    overallScore: number;
    gymScore?: number | null;
  }>;
  sleepHabitLogs?: Array<{
    date: Date | string;
    hoursSlept?: number;
    isCompleted: boolean;
  }>;
}

export interface BiomechanicalInsight {
  type:
    | 'VOLUME_SPIKE_WARNING'
    | 'OPTIMAL_WORKLOAD'
    | 'PUSH_PULL_IMBALANCE_WARNING'
    | 'STRUCTURAL_SYMMETRY'
    | 'DELOAD_RECOMMENDATION'
    | 'RECOVERY_OPTIMAL'
    | 'REST_DAY_CORRELATION'
    | 'SLEEP_PERFORMANCE_CORRELATION'
    | 'COGNITIVE_FATIGUE_CORRELATION';
  title: string;
  message: string;
  severity: 'POSITIVE' | 'INFO' | 'WARNING' | 'CRITICAL';
  metrics?: Record<string, number | string | boolean>;
}

export interface SportsScienceDiagnostics {
  insights: BiomechanicalInsight[];
  acwr: {
    acuteVolumeKg: number;
    chronicAverageVolumeKg: number;
    ratio: number;
    isSpike: boolean;
  };
  pushPullSymmetry: {
    anteriorVolumeKg: number;
    posteriorVolumeKg: number;
    imbalanceRatio: number;
    isImbalanced: boolean;
  };
  fatigueIndex: {
    consecutiveHighVolumeWeeks: number;
    deloadRecommended: boolean;
  };
}

/**
 * Normalizes Date to midnight UTC for consistent grouping
 */
const getMidnight = (d: Date): Date => {
  const date = new Date(d);
  date.setHours(0, 0, 0, 0);
  return date;
};

/**
 * Compute the total tonnage volume for a single workout
 */
export const calculateWorkoutVolume = (
  workout: WorkoutHistoryItem,
  userBodyweight: number = 70.0
): number => {
  let volume = 0;
  for (const we of workout.exercises) {
    const isBW = we.exercise.equipmentType?.toUpperCase() === 'BODYWEIGHT';
    for (const s of we.sets) {
      if (s.repetitions > 0) {
        const effectiveWeight = isBW
          ? (s.weightKg > 0 ? userBodyweight + s.weightKg : userBodyweight)
          : (s.weightKg > 0 ? s.weightKg : 0);
        volume += effectiveWeight * s.repetitions;
      }
    }
  }
  return Number(volume.toFixed(1));
};

/**
 * 1. ACWR (Acute-to-Chronic Workload Ratio)
 * Acute Workload: Current 7-day rolling window volume.
 * Chronic Workload: Average weekly volume across the preceding 4-week window (28 days).
 * If Acute > Chronic * 1.15 (>15% spike), trigger VOLUME_SPIKE_WARNING.
 */
export const calculateACWR = (
  workouts: WorkoutHistoryItem[],
  referenceDate: Date = new Date()
): {
  acuteVolumeKg: number;
  chronicAverageVolumeKg: number;
  ratio: number;
  isSpike: boolean;
  insight?: BiomechanicalInsight;
} => {
  const refTime = getMidnight(referenceDate).getTime();
  const dayMs = 24 * 60 * 60 * 1000;

  const acuteStart = refTime - 7 * dayMs;
  const chronicStart = refTime - 35 * dayMs; // 28 days preceding the acute window

  let acuteVolume = 0;
  const chronicWeekVolumes: number[] = [0, 0, 0, 0];

  for (const w of workouts) {
    const wTime = getMidnight(new Date(w.date)).getTime();
    const vol = calculateWorkoutVolume(w);

    if (wTime >= acuteStart && wTime <= refTime) {
      acuteVolume += vol;
    } else if (wTime >= chronicStart && wTime < acuteStart) {
      const daysAgo = Math.floor((acuteStart - wTime) / dayMs);
      const weekIndex = Math.min(3, Math.floor(daysAgo / 7));
      chronicWeekVolumes[weekIndex] += vol;
    }
  }

  // Active chronic weeks count to avoid division by 4 when user just started 1-2 weeks ago
  const nonZeroChronicWeeks = chronicWeekVolumes.filter((v) => v > 0).length;
  const chronicWeeksDivisor = Math.max(1, nonZeroChronicWeeks);
  const totalChronicVolume = chronicWeekVolumes.reduce((acc, curr) => acc + curr, 0);
  const chronicAverageVolume = Number((totalChronicVolume / chronicWeeksDivisor).toFixed(1));

  const ratio =
    chronicAverageVolume > 0
      ? Number((acuteVolume / chronicAverageVolume).toFixed(2))
      : acuteVolume > 0
      ? 1.0
      : 0.0;

  const isSpike = chronicAverageVolume > 0 && acuteVolume > chronicAverageVolume * 1.15;

  let insight: BiomechanicalInsight | undefined;

  if (isSpike) {
    const pctIncrease = Math.round(((acuteVolume - chronicAverageVolume) / chronicAverageVolume) * 100);
    const severity = ratio >= 1.35 ? 'CRITICAL' : 'WARNING';
    insight = {
      type: 'VOLUME_SPIKE_WARNING',
      title: 'Acute Workload Spike Detected',
      message: `Weekly training volume (${acuteVolume.toFixed(0)} kg) surged by ${pctIncrease}% over your 4-week rolling baseline (${chronicAverageVolume.toFixed(0)} kg). ACWR ratio of ${ratio} elevates soft-tissue strain risk.`,
      severity,
      metrics: {
        acuteVolumeKg: acuteVolume,
        chronicAverageVolumeKg: chronicAverageVolume,
        acwrRatio: ratio,
        percentageSurge: pctIncrease,
      },
    };
  } else if (chronicAverageVolume > 0 && acuteVolume > 0) {
    insight = {
      type: 'OPTIMAL_WORKLOAD',
      title: 'Progressive Overload in Safe Zone',
      message: `Workload ratio (ACWR: ${ratio}) is within the optimal stimulus adaptation band (0.85 - 1.15).`,
      severity: 'POSITIVE',
      metrics: {
        acuteVolumeKg: acuteVolume,
        chronicAverageVolumeKg: chronicAverageVolume,
        acwrRatio: ratio,
      },
    };
  }

  return {
    acuteVolumeKg: Number(acuteVolume.toFixed(1)),
    chronicAverageVolumeKg: chronicAverageVolume,
    ratio,
    isSpike,
    insight,
  };
};

/**
 * 2. Push/Pull Biomechanical Symmetry over rolling 14 days
 * Anterior Chain (Push): CHEST, SHOULDERS
 * Posterior Chain (Pull): BACK
 * If Anterior Volume > Posterior Volume * 1.30 (>30% dominance), trigger PUSH_PULL_IMBALANCE_WARNING.
 */
export const calculatePushPullSymmetry = (
  workouts: WorkoutHistoryItem[],
  referenceDate: Date = new Date()
): {
  anteriorVolumeKg: number;
  posteriorVolumeKg: number;
  imbalanceRatio: number;
  isImbalanced: boolean;
  insight?: BiomechanicalInsight;
} => {
  const refTime = getMidnight(referenceDate).getTime();
  const dayMs = 24 * 60 * 60 * 1000;
  const windowStart = refTime - 14 * dayMs;

  let anteriorVolume = 0;
  let posteriorVolume = 0;

  for (const w of workouts) {
    const wTime = getMidnight(new Date(w.date)).getTime();
    if (wTime < windowStart || wTime > refTime) continue;

    for (const we of w.exercises) {
      const group = (we.exercise.muscleGroup || we.exercise.category || '').toUpperCase();
      let exVolume = 0;
      for (const s of we.sets) {
        if (s.weightKg > 0 && s.repetitions > 0) {
          exVolume += s.weightKg * s.repetitions;
        }
      }

      if (group === 'CHEST' || group === 'SHOULDERS') {
        anteriorVolume += exVolume;
      } else if (group === 'BACK') {
        posteriorVolume += exVolume;
      }
    }
  }

  const isImbalanced =
    anteriorVolume > 0 &&
    (posteriorVolume === 0 || anteriorVolume > posteriorVolume * 1.3);

  const ratio =
    posteriorVolume > 0
      ? Number((anteriorVolume / posteriorVolume).toFixed(2))
      : anteriorVolume > 0
      ? 2.5
      : 1.0;

  let insight: BiomechanicalInsight | undefined;

  if (isImbalanced) {
    const pctDiff =
      posteriorVolume > 0
        ? Math.round(((anteriorVolume - posteriorVolume) / posteriorVolume) * 100)
        : 100;
    insight = {
      type: 'PUSH_PULL_IMBALANCE_WARNING',
      title: 'Push/Pull Structural Imbalance',
      message: `Anterior chain volume (${anteriorVolume.toFixed(0)} kg) exceeds posterior pulling volume (${posteriorVolume.toFixed(0)} kg) by ${pctDiff}%. Supplement horizontal rows and rear delt flies to maintain scapular balance.`,
      severity: 'WARNING',
      metrics: {
        anteriorVolumeKg: Number(anteriorVolume.toFixed(1)),
        posteriorVolumeKg: Number(posteriorVolume.toFixed(1)),
        imbalanceRatio: ratio,
      },
    };
  } else if (anteriorVolume > 0 && posteriorVolume > 0) {
    insight = {
      type: 'STRUCTURAL_SYMMETRY',
      title: 'Scapulohumeral Symmetry Balanced',
      message: `Anterior pushing and posterior pulling volumes are well aligned (${anteriorVolume.toFixed(0)} kg push vs ${posteriorVolume.toFixed(0)} kg pull).`,
      severity: 'POSITIVE',
      metrics: {
        anteriorVolumeKg: Number(anteriorVolume.toFixed(1)),
        posteriorVolumeKg: Number(posteriorVolume.toFixed(1)),
        imbalanceRatio: ratio,
      },
    };
  }

  return {
    anteriorVolumeKg: Number(anteriorVolume.toFixed(1)),
    posteriorVolumeKg: Number(posteriorVolume.toFixed(1)),
    imbalanceRatio: ratio,
    isImbalanced,
    insight,
  };
};

/**
 * 3. Fatigue Accumulation Index & Deload Recommendation
 * Examines consecutive calendar weekly completion cycles over past 6 weeks.
 * If 4 to 6 continuous weeks have been completed at high volume without a recovery drop,
 * recommend a DELOAD week to shed systemic neuromuscular fatigue.
 */
export const calculateFatigueAccumulationIndex = (
  workouts: WorkoutHistoryItem[],
  referenceDate: Date = new Date()
): {
  consecutiveHighVolumeWeeks: number;
  deloadRecommended: boolean;
  insight?: BiomechanicalInsight;
} => {
  const refTime = getMidnight(referenceDate).getTime();
  const dayMs = 24 * 60 * 60 * 1000;

  // Group workouts into 6 weekly buckets backwards
  const weeklyTonnages: number[] = [0, 0, 0, 0, 0, 0];
  const weeklySessions: number[] = [0, 0, 0, 0, 0, 0];

  for (const w of workouts) {
    const wTime = getMidnight(new Date(w.date)).getTime();
    const daysAgo = Math.floor((refTime - wTime) / dayMs);
    if (daysAgo >= 0 && daysAgo < 42) {
      const weekIdx = Math.floor(daysAgo / 7);
      if (weekIdx >= 0 && weekIdx < 6) {
        weeklyTonnages[weekIdx] += calculateWorkoutVolume(w);
        weeklySessions[weekIdx] += 1;
      }
    }
  }

  // Count consecutive weeks from current backwards where sessions >= 3 and volume > 0
  let consecutiveWeeks = 0;
  for (let i = 0; i < weeklySessions.length; i++) {
    if (weeklySessions[i] >= 3 && weeklyTonnages[i] > 1000) {
      consecutiveWeeks++;
    } else {
      break;
    }
  }

  const deloadRecommended = consecutiveWeeks >= 4;
  let insight: BiomechanicalInsight | undefined;

  if (deloadRecommended) {
    insight = {
      type: 'DELOAD_RECOMMENDATION',
      title: 'Systemic Deload Recommended',
      message: `You have completed ${consecutiveWeeks} consecutive high-volume training weeks without volume reduction. Scheduling a 1-week deload (40-50% volume drop) restores central nervous system readiness and resets muscle sensitivity.`,
      severity: consecutiveWeeks >= 6 ? 'CRITICAL' : 'WARNING',
      metrics: {
        consecutiveWeeks,
        currentWeekVolume: weeklyTonnages[0],
      },
    };
  } else {
    insight = {
      type: 'RECOVERY_OPTIMAL',
      title: 'Neuromuscular Recovery Resilient',
      message: `${consecutiveWeeks} continuous heavy weeks tracked. Fatigue accumulation is within sustainable recovery parameters.`,
      severity: 'INFO',
      metrics: {
        consecutiveWeeks,
      },
    };
  }

  return {
    consecutiveHighVolumeWeeks: consecutiveWeeks,
    deloadRecommended,
    insight,
  };
};

/**
 * Evaluates correlations between gym performance and cross-module metrics (Focus sessions & LifeScore/Sleep logs)
 */
export const analyzeCrossModuleCorrelations = (
  workouts: WorkoutHistoryItem[],
  context?: CrossModuleContext
): BiomechanicalInsight[] => {
  if (!context) return [];
  const insights: BiomechanicalInsight[] = [];

  // 1. Cognitive Fatigue Correlation:
  // Identify workouts that occurred on days with intense deep work / focus sessions (e.g. >= 240 minutes)
  if (context.focusSessions && context.focusSessions.length > 0) {
    const focusByDate: Record<string, number> = {};
    for (const fs of context.focusSessions) {
      if (fs.status === 'COMPLETED' || fs.status === 'completed') {
        const dStr = new Date(fs.startTime).toISOString().split('T')[0];
        focusByDate[dStr] = (focusByDate[dStr] || 0) + (fs.durationMinutes || 0);
      }
    }

    let heavyFocusWorkoutCount = 0;
    let highRpeOnHeavyFocusCount = 0;

    for (const w of workouts) {
      const wDateStr = new Date(w.date).toISOString().split('T')[0];
      const focusMins = focusByDate[wDateStr] || 0;
      if (focusMins >= 240) {
        heavyFocusWorkoutCount++;
        // Check if average RPE was high (>= 8.5) or perceived effort was elevated
        let totalRpe = 0;
        let rpeCount = 0;
        for (const ex of w.exercises) {
          for (const s of ex.sets) {
            if (s.rpe != null) {
              totalRpe += s.rpe;
              rpeCount++;
            }
          }
        }
        if (rpeCount > 0 && totalRpe / rpeCount >= 8.5) {
          highRpeOnHeavyFocusCount++;
        }
      }
    }

    if (heavyFocusWorkoutCount >= 2) {
      insights.push({
        type: 'COGNITIVE_FATIGUE_CORRELATION',
        title: 'Cognitive Load & Neural Drive Impact',
        message: `${heavyFocusWorkoutCount} workouts occurred on heavy deep work days (>4 hours focus). High mental exertion drains prefrontal dopamine and elevates perceived exertion (RPE) under the bar.`,
        severity: 'INFO',
        metrics: {
          heavyFocusWorkoutCount,
          highRpeOnHeavyFocusCount,
        },
      });
    }
  }

  // 2. Sleep & LifeScore Performance Correlation:
  // Correlate days with high overall LifeScore (>= 75) vs lower LifeScore (< 65) with workout volume
  if (context.lifeScoreLogs && context.lifeScoreLogs.length > 0) {
    const scoreByDate: Record<string, number> = {};
    for (const ls of context.lifeScoreLogs) {
      const dStr = new Date(ls.date).toISOString().split('T')[0];
      scoreByDate[dStr] = ls.overallScore;
    }

    let highLifeScoreVolume = 0;
    let highLifeScoreCount = 0;
    let lowLifeScoreVolume = 0;
    let lowLifeScoreCount = 0;

    for (const w of workouts) {
      const wDateStr = new Date(w.date).toISOString().split('T')[0];
      const score = scoreByDate[wDateStr];
      if (score != null) {
        let sessionVolume = 0;
        for (const ex of w.exercises) {
          for (const s of ex.sets) {
            if (s.tag !== 'W') {
              sessionVolume += s.weightKg * s.repetitions;
            }
          }
        }

        if (score >= 75) {
          highLifeScoreVolume += sessionVolume;
          highLifeScoreCount++;
        } else if (score < 65) {
          lowLifeScoreVolume += sessionVolume;
          lowLifeScoreCount++;
        }
      }
    }

    if (highLifeScoreCount > 0 && lowLifeScoreCount > 0) {
      const avgHigh = Math.round(highLifeScoreVolume / highLifeScoreCount);
      const avgLow = Math.round(lowLifeScoreVolume / lowLifeScoreCount);
      const diffPct = avgLow > 0 ? Math.round(((avgHigh - avgLow) / avgLow) * 100) : 0;

      if (diffPct > 5) {
        insights.push({
          type: 'SLEEP_PERFORMANCE_CORRELATION',
          title: 'Recovery Score & Output Synergy',
          message: `On days with optimal recovery and habit consistency (LifeScore >= 75), your average session tonnage is +${diffPct}% higher than on lower recovery days (${avgHigh}kg vs ${avgLow}kg).`,
          severity: 'POSITIVE',
          metrics: {
            avgHighVolumeKg: avgHigh,
            avgLowVolumeKg: avgLow,
            differencePercent: diffPct,
          },
        });
      }
    }
  }

  return insights;
};

/**
 * Master Sports Science Engine Orchestrator
 */
export const runSportsScienceDiagnostics = (
  workouts: WorkoutHistoryItem[],
  referenceDate: Date = new Date(),
  crossModuleContext?: CrossModuleContext
): SportsScienceDiagnostics => {
  const acwrResult = calculateACWR(workouts, referenceDate);
  const pushPullResult = calculatePushPullSymmetry(workouts, referenceDate);
  const fatigueResult = calculateFatigueAccumulationIndex(workouts, referenceDate);

  const insights: BiomechanicalInsight[] = [];

  if (acwrResult.insight) insights.push(acwrResult.insight);
  if (pushPullResult.insight) insights.push(pushPullResult.insight);
  if (fatigueResult.insight) insights.push(fatigueResult.insight);

  // Cross-module analytics (Focus sessions + Sleep/LifeScore logs)
  if (crossModuleContext) {
    const crossInsights = analyzeCrossModuleCorrelations(workouts, crossModuleContext);
    insights.push(...crossInsights);
  }

  // Always append Rest Day Supercompensation insight as baseline positive principle
  insights.push({
    type: 'REST_DAY_CORRELATION',
    title: 'Strength Supercompensation',
    message: 'Hypertrophic protein synthesis peaks between 24-48 hours post-session. Quality sleep accelerates progressive overload.',
    severity: 'POSITIVE',
  });

  return {
    insights,
    acwr: {
      acuteVolumeKg: acwrResult.acuteVolumeKg,
      chronicAverageVolumeKg: acwrResult.chronicAverageVolumeKg,
      ratio: acwrResult.ratio,
      isSpike: acwrResult.isSpike,
    },
    pushPullSymmetry: {
      anteriorVolumeKg: pushPullResult.anteriorVolumeKg,
      posteriorVolumeKg: pushPullResult.posteriorVolumeKg,
      imbalanceRatio: pushPullResult.imbalanceRatio,
      isImbalanced: pushPullResult.isImbalanced,
    },
    fatigueIndex: {
      consecutiveHighVolumeWeeks: fatigueResult.consecutiveHighVolumeWeeks,
      deloadRecommended: fatigueResult.deloadRecommended,
    },
  };
};
