import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';
import { runSportsScienceDiagnostics } from './engines/sports_science_engine';
import { calculateHypertrophyTelemetry } from './engines/rpe_analytics_engine';

export interface CreateWorkoutDTO {
  name: string;
  date?: Date | string;
  startTime?: string | null;
  durationMinutes?: number;
  notes?: string | null;
  isCompleted?: boolean;
  exercises?: any[];
}

export interface CreateExerciseDTO {
  name: string;
  category?: string;
  muscleGroup?: string;
  equipmentType?: string;
  notes?: string | null;
}

export interface SetEntryInput {
  setNumber: number;
  weightKg: number;
  repetitions: number;
  rpe?: number | null;
  notes?: string | null;
}

export interface AddExerciseToWorkoutDTO {
  exerciseId: string;
  order?: number;
  sets?: SetEntryInput[];
}

export interface RecordBodyMetricDTO {
  date?: Date | string;
  weightKg: number;
  bodyFatPercent?: number | null;
  chestCm?: number | null;
  waistCm?: number | null;
  armsCm?: number | null;
  legsCm?: number | null;
  photoUrl?: string | null;
  notes?: string | null;
}

const DEFAULT_EXERCISE_CATALOG = [
  // CHEST
  { name: 'Barbell Bench Press', category: 'CHEST', muscleGroup: 'CHEST', equipmentType: 'BARBELL' },
  { name: 'Incline Dumbbell Press', category: 'CHEST', muscleGroup: 'CHEST', equipmentType: 'DUMBBELL' },
  { name: 'Cable Chest Fly', category: 'CHEST', muscleGroup: 'CHEST', equipmentType: 'CABLE' },
  { name: 'Push-up', category: 'CHEST', muscleGroup: 'CHEST', equipmentType: 'BODYWEIGHT' },
  { name: 'Dips', category: 'CHEST', muscleGroup: 'CHEST', equipmentType: 'BODYWEIGHT' },

  // BACK
  { name: 'Barbell Deadlift', category: 'BACK', muscleGroup: 'BACK', equipmentType: 'BARBELL' },
  { name: 'Barbell Bent-Over Row', category: 'BACK', muscleGroup: 'BACK', equipmentType: 'BARBELL' },
  { name: 'Lat Pulldown', category: 'BACK', muscleGroup: 'BACK', equipmentType: 'CABLE' },
  { name: 'Seated Cable Row', category: 'BACK', muscleGroup: 'BACK', equipmentType: 'CABLE' },
  { name: 'Pull-up', category: 'BACK', muscleGroup: 'BACK', equipmentType: 'BODYWEIGHT' },

  // LEGS
  { name: 'Barbell Back Squat', category: 'LEGS', muscleGroup: 'LEGS', equipmentType: 'BARBELL' },
  { name: 'Romanian Deadlift', category: 'LEGS', muscleGroup: 'LEGS', equipmentType: 'BARBELL' },
  { name: 'Leg Press', category: 'LEGS', muscleGroup: 'LEGS', equipmentType: 'MACHINE' },
  { name: 'Leg Extension', category: 'LEGS', muscleGroup: 'LEGS', equipmentType: 'MACHINE' },
  { name: 'Lying Hamstring Curl', category: 'LEGS', muscleGroup: 'LEGS', equipmentType: 'MACHINE' },
  { name: 'Standing Calf Raise', category: 'LEGS', muscleGroup: 'LEGS', equipmentType: 'MACHINE' },

  // SHOULDERS
  { name: 'Overhead Barbell Press', category: 'SHOULDERS', muscleGroup: 'SHOULDERS', equipmentType: 'BARBELL' },
  { name: 'Dumbbell Shoulder Press', category: 'SHOULDERS', muscleGroup: 'SHOULDERS', equipmentType: 'DUMBBELL' },
  { name: 'Dumbbell Lateral Raise', category: 'SHOULDERS', muscleGroup: 'SHOULDERS', equipmentType: 'DUMBBELL' },
  { name: 'Cable Face Pull', category: 'SHOULDERS', muscleGroup: 'SHOULDERS', equipmentType: 'CABLE' },

  // ARMS
  { name: 'Barbell Bicep Curl', category: 'ARMS', muscleGroup: 'ARMS', equipmentType: 'BARBELL' },
  { name: 'Incline Dumbbell Curl', category: 'ARMS', muscleGroup: 'ARMS', equipmentType: 'DUMBBELL' },
  { name: 'Tricep Rope Pushdown', category: 'ARMS', muscleGroup: 'ARMS', equipmentType: 'CABLE' },
  { name: 'Skull Crusher', category: 'ARMS', muscleGroup: 'ARMS', equipmentType: 'BARBELL' },

  // CORE
  { name: 'Hanging Leg Raise', category: 'CORE', muscleGroup: 'CORE', equipmentType: 'BODYWEIGHT' },
  { name: 'Cable Crunch', category: 'CORE', muscleGroup: 'CORE', equipmentType: 'CABLE' },
  { name: 'Plank', category: 'CORE', muscleGroup: 'CORE', equipmentType: 'BODYWEIGHT' },
];

export const ensureDefaultExercises = async (userId: string) => {
  const existing = await prisma.exercise.findMany({
    where: { userId },
    select: { name: true },
  });
  const existingNames = new Set(existing.map((e) => e.name.toLowerCase()));

  const missing = DEFAULT_EXERCISE_CATALOG.filter(
    (e) => !existingNames.has(e.name.toLowerCase())
  );

  if (missing.length === 0) return;

  await prisma.exercise.createMany({
    data: missing.map((e) => ({
      userId,
      name: e.name,
      category: e.category,
      muscleGroup: e.muscleGroup,
      equipmentType: e.equipmentType,
      isCustom: false,
    })),
    skipDuplicates: true,
  });
};

export const ensureDefaultTemplates = async (userId: string) => {
  const count = await prisma.workoutTemplate.count({ where: { userId } });
  if (count > 0) return;

  await ensureDefaultExercises(userId);
  const exercises = await prisma.exercise.findMany({ where: { userId } });
  const exMap = new Map<string, string>(exercises.map((e) => [e.name, e.id]));

  // 1. Push Day Template
  const pushTemplate = await prisma.workoutTemplate.create({
    data: {
      userId,
      name: 'Push Day (Chest, Shoulders, Triceps)',
      category: 'PPL',
      description: 'Focus on horizontal and vertical pressing strength',
    },
  });

  const pushExercises = [
    { name: 'Barbell Bench Press', sets: 4, reps: 6, rpe: 8 },
    { name: 'Overhead Barbell Press', sets: 3, reps: 8, rpe: 8 },
    { name: 'Incline Dumbbell Press', sets: 3, reps: 10, rpe: 8.5 },
    { name: 'Tricep Rope Pushdown', sets: 3, reps: 12, rpe: 9 },
  ];

  let order = 1;
  for (const item of pushExercises) {
    const exId = exMap.get(item.name);
    if (exId) {
      await prisma.workoutTemplateExercise.create({
        data: {
          templateId: pushTemplate.id,
          exerciseId: exId,
          order: order++,
          targetSets: item.sets,
          targetReps: item.reps,
          targetRpe: item.rpe,
        },
      });
    }
  }

  // 2. Pull Day Template
  const pullTemplate = await prisma.workoutTemplate.create({
    data: {
      userId,
      name: 'Pull Day (Back, Biceps, Rear Delts)',
      category: 'PPL',
      description: 'Upper back thickness, lat width, and elbow flexor hypertrophy',
    },
  });

  const pullExercises = [
    { name: 'Barbell Deadlift', sets: 3, reps: 5, rpe: 8.5 },
    { name: 'Lat Pulldown', sets: 4, reps: 10, rpe: 8 },
    { name: 'Barbell Bent-Over Row', sets: 3, reps: 8, rpe: 8 },
    { name: 'Barbell Bicep Curl', sets: 3, reps: 10, rpe: 8.5 },
  ];

  order = 1;
  for (const item of pullExercises) {
    const exId = exMap.get(item.name);
    if (exId) {
      await prisma.workoutTemplateExercise.create({
        data: {
          templateId: pullTemplate.id,
          exerciseId: exId,
          order: order++,
          targetSets: item.sets,
          targetReps: item.reps,
          targetRpe: item.rpe,
        },
      });
    }
  }

  // 3. Leg Day Template
  const legTemplate = await prisma.workoutTemplate.create({
    data: {
      userId,
      name: 'Leg Day (Quads, Hamstrings, Calves)',
      category: 'PPL',
      description: 'Compound squat strength with quad and hamstring isolation',
    },
  });

  const legExercises = [
    { name: 'Barbell Back Squat', sets: 4, reps: 6, rpe: 8.5 },
    { name: 'Romanian Deadlift', sets: 3, reps: 8, rpe: 8 },
    { name: 'Leg Press', sets: 3, reps: 12, rpe: 8.5 },
    { name: 'Standing Calf Raise', sets: 4, reps: 15, rpe: 9 },
  ];

  order = 1;
  for (const item of legExercises) {
    const exId = exMap.get(item.name);
    if (exId) {
      await prisma.workoutTemplateExercise.create({
        data: {
          templateId: legTemplate.id,
          exerciseId: exId,
          order: order++,
          targetSets: item.sets,
          targetReps: item.reps,
          targetRpe: item.rpe,
        },
      });
    }
  }
};

/**
 * Sports-Science helper: Calculate effective load.
 * For bodyweight movements, factors in the athlete's current bodyweight (or baseline 70kg).
 */
export const getEffectiveLoad = (
  weightKg: number,
  equipmentType?: string | null,
  userBodyweight: number = 70.0
): number => {
  const isBW = equipmentType?.toUpperCase() === 'BODYWEIGHT';
  if (isBW) {
    return weightKg > 0 ? Number((userBodyweight + weightKg).toFixed(1)) : Number(userBodyweight.toFixed(1));
  }
  return weightKg > 0 ? Number(weightKg.toFixed(1)) : 0;
};

export const getUserCurrentBodyweight = async (userId: string): Promise<number> => {
  const latestMetric = await prisma.bodyMetric.findFirst({
    where: { userId },
    orderBy: { date: 'desc' },
  });
  return latestMetric?.weightKg || 70.0;
};

/**
 * Calculate One-Rep Max (1RM) using Epley Formula: 1RM = weight * (1 + repetitions / 30)
 */
export const calculateOneRepMax = (weightKg: number, reps: number): number => {
  if (reps <= 0 || weightKg <= 0) return 0;
  if (reps === 1) return Number(weightKg.toFixed(1));
  return Number((weightKg * (1 + reps / 30)).toFixed(1));
};

/**
 * Check if a set qualifies as a new Personal Record (PR) (UC-96)
 */
export const evaluatePersonalRecord = async (
  userId: string,
  exerciseId: string,
  weightKg: number,
  repetitions: number,
  workoutId?: string,
  setEntryId?: string,
  equipmentType?: string | null,
  userBodyweight?: number,
  txClient?: any
): Promise<{ isPR: boolean; calculated1RM: number }> => {
  const db = txClient || prisma;
  const effectiveWeight = getEffectiveLoad(weightKg, equipmentType, userBodyweight || 70.0);
  const calculated1RM = calculateOneRepMax(effectiveWeight, repetitions);
  if (calculated1RM <= 0) return { isPR: false, calculated1RM: 0 };

  const currentPR = await db.personalRecord.findFirst({
    where: { userId, exerciseId },
    orderBy: { calculatedOneRepMax: 'desc' },
  });

  const isPR = !currentPR || (currentPR.calculatedOneRepMax !== null && calculated1RM > currentPR.calculatedOneRepMax);

  if (isPR) {
    await db.personalRecord.create({
      data: {
        weightKg,
        repetitions,
        calculatedOneRepMax: calculated1RM,
        achievedDate: new Date(),
        exerciseId,
        userId,
        workoutId: workoutId || null,
        setEntryId: setEntryId || null,
      },
    });
  }

  return { isPR, calculated1RM };
};

// ==========================================
// 1. WORKOUTS (UC-91 to UC-97)
// ==========================================

export const createWorkout = async (userId: string, data: CreateWorkoutDTO) => {
  await ensureDefaultExercises(userId);

  const rawExercises: any[] = Array.isArray(data.exercises) ? data.exercises : [];
  const userBodyweight = await getUserCurrentBodyweight(userId);

  if (rawExercises.length > 0) {
    const workoutDate = data.date ? new Date(data.date) : new Date();
    const durationMinutes = data.durationMinutes ? Number(data.durationMinutes) : 60;

    return await prisma.$transaction(async (tx) => {
      const workout = await tx.workout.create({
        data: {
          userId,
          name: data.name,
          date: workoutDate,
          startTime: data.startTime || null,
          durationMinutes,
          notes: data.notes || null,
          isCompleted: data.isCompleted !== undefined ? data.isCompleted : true,
        },
      });

      let totalTonnage = 0;
      let totalSetsCount = 0;
      const detectedPRs: any[] = [];

      for (let i = 0; i < rawExercises.length; i++) {
        const exItem = rawExercises[i];
        const exerciseId = exItem.exerciseId;

        const exerciseRecord = await tx.exercise.findFirst({
          where: { id: exerciseId, userId },
        });

        if (!exerciseRecord) {
          throw new ApiError(404, `Exercise not found: ${exerciseId}`);
        }

        const we = await tx.workoutExercise.create({
          data: {
            workoutId: workout.id,
            exerciseId,
            order: exItem.order || i + 1,
          },
        });

          const rawSets: any[] = Array.isArray(exItem.sets) ? exItem.sets : [];
        for (let sIdx = 0; sIdx < rawSets.length; sIdx++) {
          const s = rawSets[sIdx];
          const weightKg = Number(s.weightKg || 0);
          const repetitions = Number(s.repetitions || 0);
          const tag = s.tag || 'N';
          const durationSeconds = s.durationSeconds !== undefined ? Number(s.durationSeconds) : null;
          const distanceMeters = s.distanceMeters !== undefined ? Number(s.distanceMeters) : null;
          const caloriesBurned = s.caloriesBurned !== undefined ? Number(s.caloriesBurned) : null;

          const effectiveLoad = getEffectiveLoad(weightKg, exerciseRecord?.equipmentType, userBodyweight);
          const calculated1RM = calculateOneRepMax(effectiveLoad, repetitions);
          if (tag !== 'W') {
            totalTonnage += effectiveLoad * repetitions;
          }
          totalSetsCount++;

          let isPR = false;
          // Omit warm-up sets ('W') from PR evaluations
          if (tag !== 'W' && calculated1RM > 0) {
            const existingPR = await tx.personalRecord.findFirst({
              where: { userId, exerciseId },
              orderBy: { calculatedOneRepMax: 'desc' },
            });
            isPR = !existingPR || (existingPR.calculatedOneRepMax !== null && calculated1RM > existingPR.calculatedOneRepMax);
          }

          const setEntry = await tx.setEntry.create({
            data: {
              workoutExerciseId: we.id,
              setNumber: s.setNumber || sIdx + 1,
              weightKg,
              repetitions,
              rpe: s.rpe !== undefined ? Number(s.rpe) : null,
              estimatedOneRepMax: calculated1RM,
              isPR,
              tag,
              durationSeconds,
              distanceMeters,
              caloriesBurned,
              notes: s.notes || null,
            },
          });

          if (isPR && calculated1RM > 0) {
            const newPR = await tx.personalRecord.create({
              data: {
                userId,
                exerciseId,
                weightKg,
                repetitions,
                calculatedOneRepMax: calculated1RM,
                achievedDate: workoutDate,
                workoutId: workout.id,
                setEntryId: setEntry.id,
              },
            });
            detectedPRs.push(newPR);
          }
        }
      }

      invalidateDashboardCache(userId);

      const fullWorkout = await tx.workout.findUnique({
        where: { id: workout.id },
        include: {
          exercises: {
            orderBy: { order: 'asc' },
            include: {
              exercise: true,
              sets: { orderBy: { setNumber: 'asc' } },
            },
          },
        },
      });

      return {
        ...fullWorkout,
        totalVolume: Number(totalTonnage.toFixed(1)),
        totalTonnage: Number(totalTonnage.toFixed(1)),
        totalSets: totalSetsCount,
        totalSetsCount,
        prCount: detectedPRs.length,
        detectedPRs,
      };
    });
  }

  const workout = await prisma.workout.create({
    data: {
      name: data.name,
      date: data.date ? new Date(data.date) : new Date(),
      startTime: data.startTime,
      durationMinutes: data.durationMinutes || 60,
      notes: data.notes,
      isCompleted: data.isCompleted !== undefined ? data.isCompleted : true,
      userId,
    },
  });

  invalidateDashboardCache(userId);
  return {
    ...workout,
    totalVolume: 0,
    totalTonnage: 0,
    totalSets: 0,
    totalSetsCount: 0,
    prCount: 0,
    detectedPRs: [],
  };
};

export const logWorkout = createWorkout;

export const getWorkouts = async (userId: string, limit: any = 20) => {
  const take = typeof limit === 'number' ? limit : 20;

  const [workouts, userBodyweight] = await Promise.all([
    prisma.workout.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      take,
      include: {
        exercises: {
          orderBy: { order: 'asc' },
          include: {
            exercise: true,
            sets: { orderBy: { setNumber: 'asc' } },
          },
        },
      },
    }),
    getUserCurrentBodyweight(userId),
  ]);

  return workouts.map((w) => {
    let totalVolume = 0;
    let totalSets = 0;
    let prCount = 0;

    for (const we of w.exercises) {
      for (const s of we.sets) {
        totalSets++;
        const effLoad = getEffectiveLoad(s.weightKg, we.exercise.equipmentType, userBodyweight);
        totalVolume += effLoad * s.repetitions;
        if (s.isPR) {
          prCount++;
        }
      }
    }

    return {
      ...w,
      totalVolume: Number(totalVolume.toFixed(1)),
      totalTonnage: Number(totalVolume.toFixed(1)),
      totalSets,
      totalSetsCount: totalSets,
      prCount,
    };
  });
};

export const getWorkoutById = async (userId: string, workoutId: string) => {
  const [workout, userBodyweight] = await Promise.all([
    prisma.workout.findFirst({
      where: { id: workoutId, userId },
      include: {
        exercises: {
          orderBy: { order: 'asc' },
          include: {
            exercise: true,
            sets: { orderBy: { setNumber: 'asc' } },
          },
        },
      },
    }),
    getUserCurrentBodyweight(userId),
  ]);

  if (!workout) {
    throw new ApiError(404, 'Workout not found');
  }

  let totalVolume = 0;
  let totalSets = 0;
  let prCount = 0;

  for (const we of workout.exercises) {
    for (const s of we.sets) {
      totalSets++;
      const effLoad = getEffectiveLoad(s.weightKg, we.exercise.equipmentType, userBodyweight);
      totalVolume += effLoad * s.repetitions;
      if (s.isPR) {
        prCount++;
      }
    }
  }

  return {
    ...workout,
    totalVolume: Number(totalVolume.toFixed(1)),
    totalTonnage: Number(totalVolume.toFixed(1)),
    totalSets,
    totalSetsCount: totalSets,
    prCount,
  };
};

export const updateWorkout = async (userId: string, workoutId: string, data: Partial<CreateWorkoutDTO>) => {
  const existing = await prisma.workout.findFirst({
    where: { id: workoutId, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Workout not found');
  }

  const { exercises, ...restData } = data;

  if (Array.isArray(exercises)) {
    const userBodyweight = await getUserCurrentBodyweight(userId);
    return await prisma.$transaction(async (tx) => {
      await tx.personalRecord.deleteMany({ where: { workoutId } });
      await tx.workoutExercise.deleteMany({ where: { workoutId } });

      await tx.workout.update({
        where: { id: workoutId },
        data: {
          ...restData,
          date: data.date ? new Date(data.date) : undefined,
        },
      });

      let totalTonnage = 0;
      let totalSetsCount = 0;
      let prCount = 0;

      for (let i = 0; i < exercises.length; i++) {
        const exItem = exercises[i];
        const exerciseId = exItem.exerciseId;
        const exerciseRecord = await tx.exercise.findFirst({
          where: { id: exerciseId, userId },
        });

        if (!exerciseRecord) {
          throw new ApiError(404, `Exercise not found: ${exerciseId}`);
        }

        const we = await tx.workoutExercise.create({
          data: {
            workoutId,
            exerciseId,
            order: exItem.order || i + 1,
          },
        });

        const rawSets: any[] = Array.isArray(exItem.sets) ? exItem.sets : [];
        for (let sIdx = 0; sIdx < rawSets.length; sIdx++) {
          const s = rawSets[sIdx];
          const weightKg = Number(s.weightKg || 0);
          const repetitions = Number(s.repetitions || 0);
          const tag = s.tag || 'N';
          const durationSeconds = s.durationSeconds !== undefined ? Number(s.durationSeconds) : null;
          const distanceMeters = s.distanceMeters !== undefined ? Number(s.distanceMeters) : null;
          const caloriesBurned = s.caloriesBurned !== undefined ? Number(s.caloriesBurned) : null;

          const effectiveLoad = getEffectiveLoad(weightKg, exerciseRecord?.equipmentType, userBodyweight);
          const calculated1RM = calculateOneRepMax(effectiveLoad, repetitions);
          if (tag !== 'W') {
            totalTonnage += effectiveLoad * repetitions;
          }
          totalSetsCount++;

          let isPR = false;
          // Omit warm-up sets ('W') from PR evaluations
          if (tag !== 'W' && calculated1RM > 0) {
            const existingPR = await tx.personalRecord.findFirst({
              where: { userId, exerciseId },
              orderBy: { calculatedOneRepMax: 'desc' },
            });
            isPR = !existingPR || (existingPR.calculatedOneRepMax !== null && calculated1RM > existingPR.calculatedOneRepMax);
          }
          if (isPR) prCount++;

          const setEntry = await tx.setEntry.create({
            data: {
              workoutExerciseId: we.id,
              setNumber: s.setNumber || sIdx + 1,
              weightKg,
              repetitions,
              rpe: s.rpe !== undefined ? Number(s.rpe) : null,
              estimatedOneRepMax: calculated1RM,
              isPR,
              tag,
              durationSeconds,
              distanceMeters,
              caloriesBurned,
              notes: s.notes || null,
            },
          });

          if (isPR && calculated1RM > 0) {
            await tx.personalRecord.create({
              data: {
                userId,
                exerciseId,
                weightKg,
                repetitions,
                calculatedOneRepMax: calculated1RM,
                achievedDate: data.date ? new Date(data.date) : existing.date,
                workoutId,
                setEntryId: setEntry.id,
              },
            });
          }
        }
      }

      invalidateDashboardCache(userId);

      const fullWorkout = await tx.workout.findUnique({
        where: { id: workoutId },
        include: {
          exercises: {
            orderBy: { order: 'asc' },
            include: {
              exercise: true,
              sets: { orderBy: { setNumber: 'asc' } },
            },
          },
        },
      });

      return {
        ...fullWorkout,
        totalVolume: Number(totalTonnage.toFixed(1)),
        totalTonnage: Number(totalTonnage.toFixed(1)),
        totalSets: totalSetsCount,
        totalSetsCount,
        prCount,
      };
    });
  }

  const updated = await prisma.workout.update({
    where: { id: workoutId },
    data: {
      ...restData,
      date: data.date ? new Date(data.date) : undefined,
    },
  });

  invalidateDashboardCache(userId);
  return getWorkoutById(userId, workoutId);
};

export const deleteWorkout = async (userId: string, workoutId: string) => {
  const existing = await prisma.workout.findFirst({
    where: { id: workoutId, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Workout not found');
  }

  await prisma.personalRecord.deleteMany({ where: { workoutId } });
  await prisma.workout.delete({ where: { id: workoutId } });
  invalidateDashboardCache(userId);
  return { message: 'Workout deleted successfully' };
};

// ==========================================
// 2. EXERCISES & SETS (UC-92 to UC-96)
// ==========================================

export const createExercise = async (userId: string, data: CreateExerciseDTO) => {
  const existing = await prisma.exercise.findFirst({
    where: { userId, name: data.name },
  });

  if (existing) {
    return existing;
  }

  const exercise = await prisma.exercise.create({
    data: {
      name: data.name,
      category: data.category || 'CHEST',
      muscleGroup: data.muscleGroup || data.category || 'CHEST',
      equipmentType: data.equipmentType || 'BARBELL',
      notes: data.notes,
      isCustom: true,
      userId,
    },
  });

  return exercise;
};

export const getExercises = async (userId: string, categoryOrQuery?: any) => {
  await ensureDefaultExercises(userId);

  const category = typeof categoryOrQuery === 'string' ? categoryOrQuery : categoryOrQuery?.category;
  const muscleGroup = typeof categoryOrQuery === 'object' ? categoryOrQuery?.muscleGroup : undefined;

  const exercises = await prisma.exercise.findMany({
    where: {
      userId,
      ...(category ? { category } : {}),
      ...(muscleGroup ? { muscleGroup } : {}),
    },
    orderBy: [{ isCustom: 'asc' }, { name: 'asc' }],
    include: {
      personalRecords: {
        orderBy: { calculatedOneRepMax: 'desc' },
        take: 1,
      },
    },
  });

  return exercises;
};

export const addExerciseToWorkout = async (
  userId: string,
  workoutId: string,
  data: AddExerciseToWorkoutDTO
) => {
  const workout = await prisma.workout.findFirst({ where: { id: workoutId, userId } });
  if (!workout) throw new ApiError(404, 'Workout not found');

  const exercise = await prisma.exercise.findFirst({ where: { id: data.exerciseId, userId } });
  if (!exercise) throw new ApiError(404, 'Exercise not found');

  const userBodyweight = await getUserCurrentBodyweight(userId);

  await prisma.$transaction(async (tx) => {
    const workoutExercise = await tx.workoutExercise.create({
      data: {
        workoutId,
        exerciseId: data.exerciseId,
        order: data.order || 1,
      },
    });

    if (data.sets && data.sets.length > 0) {
      for (const set of data.sets) {
        const tag = (set as any).tag || 'N';
        const durationSeconds = (set as any).durationSeconds !== undefined ? Number((set as any).durationSeconds) : null;
        const distanceMeters = (set as any).distanceMeters !== undefined ? Number((set as any).distanceMeters) : null;
        const caloriesBurned = (set as any).caloriesBurned !== undefined ? Number((set as any).caloriesBurned) : null;

        const setEntry = await tx.setEntry.create({
          data: {
            setNumber: set.setNumber,
            weightKg: set.weightKg,
            repetitions: set.repetitions,
            rpe: set.rpe !== undefined ? Number(set.rpe) : null,
            tag,
            durationSeconds,
            distanceMeters,
            caloriesBurned,
            isPR: false,
            notes: set.notes,
            workoutExerciseId: workoutExercise.id,
          },
        });

        if (tag !== 'W') {
          const { isPR, calculated1RM } = await evaluatePersonalRecord(
            userId,
            data.exerciseId,
            set.weightKg,
            set.repetitions,
            workoutId,
            setEntry.id,
            exercise.equipmentType,
            userBodyweight,
            tx
          );

          await tx.setEntry.update({
            where: { id: setEntry.id },
            data: { isPR, estimatedOneRepMax: calculated1RM },
          });
        }
      }
    }
  });

  return getWorkoutById(userId, workoutId);
};

export const recordSet = async (
  userId: string,
  workoutExerciseId: string,
  data: SetEntryInput
) => {
  const workoutExercise = await prisma.workoutExercise.findUnique({
    where: { id: workoutExerciseId },
    include: { workout: true, exercise: true },
  });

  if (!workoutExercise || workoutExercise.workout.userId !== userId) {
    throw new ApiError(404, 'Workout exercise not found');
  }

  const userBodyweight = await getUserCurrentBodyweight(userId);
  const tag = (data as any).tag || 'N';
  const durationSeconds = (data as any).durationSeconds !== undefined ? Number((data as any).durationSeconds) : null;
  const distanceMeters = (data as any).distanceMeters !== undefined ? Number((data as any).distanceMeters) : null;
  const caloriesBurned = (data as any).caloriesBurned !== undefined ? Number((data as any).caloriesBurned) : null;

  return await prisma.$transaction(async (tx) => {
    const setEntry = await tx.setEntry.create({
      data: {
        setNumber: data.setNumber,
        weightKg: data.weightKg,
        repetitions: data.repetitions,
        rpe: data.rpe !== undefined ? Number(data.rpe) : null,
        tag,
        durationSeconds,
        distanceMeters,
        caloriesBurned,
        isPR: false,
        notes: data.notes,
        workoutExerciseId,
      },
    });

    let finalSetEntry = setEntry;
    if (tag !== 'W') {
      const { isPR, calculated1RM } = await evaluatePersonalRecord(
        userId,
        workoutExercise.exerciseId,
        data.weightKg,
        data.repetitions,
        workoutExercise.workoutId,
        setEntry.id,
        workoutExercise.exercise.equipmentType,
        userBodyweight,
        tx
      );

      finalSetEntry = await tx.setEntry.update({
        where: { id: setEntry.id },
        data: { isPR, estimatedOneRepMax: calculated1RM },
      });
    }

    return finalSetEntry;
  });
};

export const getExerciseHistory = async (userId: string, exerciseId: string) => {
  const [exercise, userBodyweight] = await Promise.all([
    prisma.exercise.findFirst({
      where: { id: exerciseId, userId },
    }),
    getUserCurrentBodyweight(userId),
  ]);

  if (!exercise) throw new ApiError(404, 'Exercise not found');

  const workoutExercises = await prisma.workoutExercise.findMany({
    where: {
      exerciseId,
      workout: { userId },
    },
    include: {
      workout: { select: { id: true, name: true, date: true } },
      sets: { orderBy: { setNumber: 'asc' } },
    },
    orderBy: { workout: { date: 'desc' } },
  });

  const sessions = workoutExercises.map((we) => {
    let maxWeight = 0;
    let maxEst1RM = 0;
    let totalVolume = 0;

    we.sets.forEach((s) => {
      if (s.weightKg > maxWeight) maxWeight = s.weightKg;
      const effectiveLoad = getEffectiveLoad(s.weightKg, exercise.equipmentType, userBodyweight);
      const est1RM = s.estimatedOneRepMax || calculateOneRepMax(effectiveLoad, s.repetitions);
      if (est1RM > maxEst1RM) maxEst1RM = est1RM;
      if (s.tag !== 'W') {
        totalVolume += effectiveLoad * s.repetitions;
      }
    });

    return {
      workoutId: we.workout.id,
      workoutName: we.workout.name,
      date: we.workout.date,
      sets: we.sets,
      maxWeight,
      maxEst1RM: Number(maxEst1RM.toFixed(1)),
      totalVolume: Number(totalVolume.toFixed(1)),
    };
  });

  const currentPR = await prisma.personalRecord.findFirst({
    where: { userId, exerciseId },
    orderBy: { calculatedOneRepMax: 'desc' },
  });

  return {
    exercise,
    currentPR,
    lastPerformance: sessions.length > 0 ? sessions[0] : null,
    totalSessions: sessions.length,
    history: sessions,
  };
};

// ==========================================
// 3. BODY METRICS & ANALYTICS (UC-99 to UC-101)
// ==========================================

export const recordBodyMetric = async (userId: string, data: RecordBodyMetricDTO) => {
  const metric = await prisma.bodyMetric.create({
    data: {
      date: data.date ? new Date(data.date) : new Date(),
      weightKg: data.weightKg,
      bodyFatPercent: data.bodyFatPercent !== undefined ? Number(data.bodyFatPercent) : null,
      chestCm: data.chestCm,
      waistCm: data.waistCm,
      armsCm: data.armsCm,
      legsCm: data.legsCm,
      photoUrl: data.photoUrl || null,
      notes: data.notes,
      userId,
    },
  });

  return metric;
};

export const logBodyMetric = recordBodyMetric;

export const getBodyMetrics = async (userId: string, limit: any = 30) => {
  const take = typeof limit === 'number' ? limit : 30;

  const metrics = await prisma.bodyMetric.findMany({
    where: { userId },
    orderBy: { date: 'desc' },
    take,
  });

  if (metrics.length === 0) return [];

  const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
  const oldestDateInPage = new Date(metrics[metrics.length - 1].date);
  const bufferStartDate = new Date(oldestDateInPage.getTime() - sevenDaysMs);

  // Fetch metrics that fall within the 7-day window before the oldest page entry
  const bufferMetrics = await prisma.bodyMetric.findMany({
    where: {
      userId,
      date: {
        gte: bufferStartDate,
        lt: oldestDateInPage,
      },
    },
    orderBy: { date: 'desc' },
  });

  const allAvailableMetrics = [...metrics, ...bufferMetrics];

  const enriched = metrics.map((m) => {
    const mTime = new Date(m.date).getTime();
    const windowEntries = allAvailableMetrics.filter((other) => {
      const oTime = new Date(other.date).getTime();
      return oTime <= mTime && oTime >= mTime - sevenDaysMs;
    });

    const avg =
      windowEntries.reduce((acc, curr) => acc + curr.weightKg, 0) / (windowEntries.length || 1);

    return {
      ...m,
      sevenDayAverageKg: Number(avg.toFixed(1)),
    };
  });

  return enriched;
};

export const deleteBodyMetric = async (userId: string, id: string) => {
  const existing = await prisma.bodyMetric.findFirst({ where: { id, userId } });
  if (!existing) throw new ApiError(404, 'Body metric not found');

  await prisma.bodyMetric.delete({ where: { id } });
  return true;
};

export const getGymAnalytics = async (userId: string) => {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);

  const [totalWorkouts, monthWorkouts, totalPRs, latestWeight, topPRs] = await Promise.all([
    prisma.workout.count({ where: { userId } }),
    prisma.workout.count({ where: { userId, date: { gte: startOfMonth } } }),
    prisma.personalRecord.count({ where: { userId } }),
    prisma.bodyMetric.findFirst({
      where: { userId },
      orderBy: { date: 'desc' },
    }),
    getPersonalRecords(userId),
  ]);

  return {
    totalWorkouts,
    workoutsThisMonth: monthWorkouts,
    totalPersonalRecords: totalPRs,
    currentWeightKg: latestWeight?.weightKg || null,
    topPersonalRecords: topPRs.slice(0, 5),
  };
};

/**
 * Group all-time highest PR per unique exercise (Bug 6 Fix)
 */
export const getPersonalRecords = async (userId: string) => {
  const allPrs = await prisma.personalRecord.findMany({
    where: { userId },
    orderBy: { calculatedOneRepMax: 'desc' },
    include: { exercise: true },
  });

  const bestMap = new Map<string, typeof allPrs[0]>();
  for (const pr of allPrs) {
    if (!bestMap.has(pr.exerciseId)) {
      bestMap.set(pr.exerciseId, pr);
    }
  }

  return Array.from(bestMap.values()).sort(
    (a, b) => (b.calculatedOneRepMax || 0) - (a.calculatedOneRepMax || 0)
  );
};

const formatLocalDateKey = (date: Date): string => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

const getMondayOfDate = (d: Date): Date => {
  const date = new Date(d);
  const day = date.getDay();
  const diff = date.getDate() - day + (day === 0 ? -6 : 1);
  date.setDate(diff);
  date.setHours(0, 0, 0, 0);
  return date;
};

export const getGymStats = async (userId: string) => {
  const [workouts, userPref, userBodyweight] = await Promise.all([
    prisma.workout.findMany({
      where: { userId },
      include: {
        exercises: {
          include: {
            exercise: true,
            sets: true,
          },
        },
      },
    }),
    prisma.userPreference.findUnique({
      where: { userId },
    }),
    getUserCurrentBodyweight(userId),
  ]);

  const now = new Date();
  const currentWeekMonday = getMondayOfDate(now);

  const workoutsThisWeek = workouts.filter((w) => new Date(w.date) >= currentWeekMonday);
  const workedOutToday = workouts.some(
    (w) => formatLocalDateKey(new Date(w.date)) === formatLocalDateKey(now)
  );
  const weeklyTarget = userPref?.weeklyGymTarget ?? 4;

  let totalLifetimeTonnage = 0;
  let calisthenicsTotalReps = 0;
  let calisthenicsVolumeKg = 0;
  const muscleVolume: Record<string, number> = {
    CHEST: 0,
    BACK: 0,
    LEGS: 0,
    SHOULDERS: 0,
    ARMS: 0,
    CORE: 0,
  };

  const weeklyBuckets: Record<string, { weekStart: string; volumeKg: number; workoutsCount: number }> = {};
  for (let i = 7; i >= 0; i--) {
    const d = new Date(currentWeekMonday.getTime() - i * 7 * 24 * 60 * 60 * 1000);
    const key = formatLocalDateKey(d);
    weeklyBuckets[key] = { weekStart: key, volumeKg: 0, workoutsCount: 0 };
  }

  workouts.forEach((w) => {
    const wDate = new Date(w.date);
    const monday = formatLocalDateKey(getMondayOfDate(wDate));

    if (weeklyBuckets[monday]) {
      weeklyBuckets[monday].workoutsCount += 1;
    }

    w.exercises.forEach((we) => {
      const isCalisthenics = we.exercise.equipmentType === 'BODYWEIGHT';
      const mGroup = we.exercise.muscleGroup || we.exercise.category || 'CHEST';
      we.sets.forEach((s) => {
        const effLoad = getEffectiveLoad(s.weightKg, we.exercise.equipmentType, userBodyweight);
        const vol = effLoad * s.repetitions;
        totalLifetimeTonnage += vol;
        muscleVolume[mGroup] = (muscleVolume[mGroup] || 0) + vol;
        if (weeklyBuckets[monday]) {
          weeklyBuckets[monday].volumeKg += vol;
        }

        if (isCalisthenics) {
          calisthenicsTotalReps += s.repetitions;
          calisthenicsVolumeKg += vol;
        }
      });
    });
  });

  const muscleDistribution = Object.keys(muscleVolume).map((group) => {
    const vol = muscleVolume[group];
    const pct = totalLifetimeTonnage > 0 ? Number(((vol / totalLifetimeTonnage) * 100).toFixed(1)) : 0;
    return {
      muscleGroup: group,
      volumeKg: vol,
      percentage: pct,
    };
  });

  const [totalPRs, prs] = await Promise.all([
    prisma.personalRecord.count({ where: { userId } }),
    getPersonalRecords(userId),
  ]);

  const hypertrophyTelemetry = calculateHypertrophyTelemetry(workouts);

  return {
    workoutsThisWeek: workoutsThisWeek.length,
    weeklyTarget,
    workedOutToday,
    totalLifetimeTonnage: Number(totalLifetimeTonnage.toFixed(1)),
    calisthenicsTotalReps,
    calisthenicsVolumeKg: Number(calisthenicsVolumeKg.toFixed(1)),
    stimulativeWorkingVolumeKg: hypertrophyTelemetry.stimulativeWorkingVolumeKg,
    totalStructuralVolumeKg: hypertrophyTelemetry.totalStructuralVolumeKg,
    warmupVolumeKg: hypertrophyTelemetry.warmupVolumeKg,
    stimulativeSetsCount: hypertrophyTelemetry.stimulativeSetsCount,
    warmupSetsCount: hypertrophyTelemetry.warmupSetsCount,
    hypertrophicEfficiencyPercentage: hypertrophyTelemetry.hypertrophicEfficiencyPercentage,
    hypertrophyMuscleBreakdown: hypertrophyTelemetry.muscleBreakdown,
    weeklyVolumeTrend: Object.values(weeklyBuckets),
    muscleDistribution,
    topPRs: prs.slice(0, 5),
    totalPersonalRecords: totalPRs,
  };
};

export const getGymInsights = async (userId: string) => {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const [workouts, focusSessions, lifeScoreLogs] = await Promise.all([
    prisma.workout.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      include: {
        exercises: {
          include: {
            exercise: true,
            sets: true,
          },
        },
      },
    }),
    prisma.focusSession.findMany({
      where: {
        userId,
        startTime: { gte: thirtyDaysAgo },
      },
      select: {
        durationMinutes: true,
        category: true,
        status: true,
        startTime: true,
      },
    }),
    prisma.lifeScoreLog.findMany({
      where: {
        userId,
        date: { gte: thirtyDaysAgo },
      },
      select: {
        date: true,
        overallScore: true,
        gymScore: true,
      },
    }),
  ]);

  return runSportsScienceDiagnostics(workouts, new Date(), {
    focusSessions,
    lifeScoreLogs,
  });
};

// ==========================================
// 4. WORKOUT TEMPLATES & ROUTINES
// ==========================================

export const getTemplates = async (userId: string) => {
  await ensureDefaultTemplates(userId);

  const templates = await prisma.workoutTemplate.findMany({
    where: { userId },
    include: {
      exercises: {
        orderBy: { order: 'asc' },
        include: { exercise: true },
      },
    },
    orderBy: { createdAt: 'asc' },
  });

  const exerciseIds = Array.from(
    new Set(templates.flatMap((t) => t.exercises.map((e) => e.exerciseId)))
  );

  const recentWorkoutExercises =
    exerciseIds.length > 0
      ? await prisma.workoutExercise.findMany({
          where: {
            exerciseId: { in: exerciseIds },
            workout: { userId },
          },
          orderBy: { workout: { date: 'desc' } },
          include: {
            sets: { orderBy: { setNumber: 'asc' } },
          },
        })
      : [];

  const lastPerformanceMap = new Map<string, any[]>();
  for (const we of recentWorkoutExercises) {
    if (!lastPerformanceMap.has(we.exerciseId)) {
      lastPerformanceMap.set(we.exerciseId, we.sets);
    }
  }

  return templates.map((tmpl) => ({
    ...tmpl,
    exercises: tmpl.exercises.map((te) => ({
      ...te,
      lastPerformance: lastPerformanceMap.get(te.exerciseId) || [],
    })),
  }));
};

export const getTemplateById = async (userId: string, id: string) => {
  const template = await prisma.workoutTemplate.findFirst({
    where: { id, userId },
    include: {
      exercises: {
        orderBy: { order: 'asc' },
        include: { exercise: true },
      },
    },
  });

  if (!template) throw new ApiError(404, 'Workout template not found');

  const exerciseIds = template.exercises.map((e) => e.exerciseId);
  const recentWorkoutExercises =
    exerciseIds.length > 0
      ? await prisma.workoutExercise.findMany({
          where: {
            exerciseId: { in: exerciseIds },
            workout: { userId },
          },
          orderBy: { workout: { date: 'desc' } },
          include: {
            sets: { orderBy: { setNumber: 'asc' } },
          },
        })
      : [];

  const lastPerformanceMap = new Map<string, any[]>();
  for (const we of recentWorkoutExercises) {
    if (!lastPerformanceMap.has(we.exerciseId)) {
      lastPerformanceMap.set(we.exerciseId, we.sets);
    }
  }

  return {
    ...template,
    exercises: template.exercises.map((te) => ({
      ...te,
      lastPerformance: lastPerformanceMap.get(te.exerciseId) || [],
    })),
  };
};

export const createTemplate = async (userId: string, data: any) => {
  if (!data.name) throw new ApiError(400, 'Template name is required');

  const template = await prisma.workoutTemplate.create({
    data: {
      userId,
      name: data.name,
      category: data.category || 'PPL',
      description: data.description || null,
    },
  });

  if (Array.isArray(data.exercises)) {
    for (let i = 0; i < data.exercises.length; i++) {
      const item = data.exercises[i];
      await prisma.workoutTemplateExercise.create({
        data: {
          templateId: template.id,
          exerciseId: item.exerciseId,
          order: item.order || i + 1,
          targetSets: item.targetSets || 3,
          targetReps: item.targetReps || 10,
          targetRpe: item.targetRpe || null,
          notes: item.notes || null,
        },
      });
    }
  }

  return getTemplateById(userId, template.id);
};

export const deleteTemplate = async (userId: string, id: string) => {
  const existing = await prisma.workoutTemplate.findFirst({ where: { id, userId } });
  if (!existing) throw new ApiError(404, 'Workout template not found');

  await prisma.workoutTemplate.delete({ where: { id } });
  return true;
};

export default {
  calculateOneRepMax,
  evaluatePersonalRecord,
  ensureDefaultExercises,
  ensureDefaultTemplates,
  createWorkout,
  logWorkout,
  getWorkouts,
  getWorkoutById,
  updateWorkout,
  deleteWorkout,
  createExercise,
  getExercises,
  addExerciseToWorkout,
  recordSet,
  getExerciseHistory,
  recordBodyMetric,
  logBodyMetric,
  getBodyMetrics,
  deleteBodyMetric,
  getGymAnalytics,
  getPersonalRecords,
  getGymStats,
  getGymInsights,
  getTemplates,
  getTemplateById,
  createTemplate,
  deleteTemplate,
};
