import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';

export interface CreateWorkoutDTO {
  name: string;
  date?: Date | string;
  startTime?: string | null;
  durationMinutes?: number;
  notes?: string | null;
  isCompleted?: boolean;
}

export interface CreateExerciseDTO {
  name: string;
  category?: string;
  notes?: string | null;
}

export interface SetEntryInput {
  setNumber: number;
  weightKg: number;
  repetitions: number;
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
  chestCm?: number | null;
  waistCm?: number | null;
  armsCm?: number | null;
  legsCm?: number | null;
  notes?: string | null;
}

/**
 * Calculate One-Rep Max (1RM) using Epley Formula: 1RM = weight * (1 + repetitions / 30)
 */
export const calculateOneRepMax = (weightKg: number, reps: number): number => {
  if (reps === 1) return weightKg;
  if (reps === 0) return 0;
  return Number((weightKg * (1 + reps / 30)).toFixed(1));
};

/**
 * Check if a set qualifies as a new Personal Record (PR) (UC-96)
 */
export const evaluatePersonalRecord = async (
  userId: string,
  exerciseId: string,
  weightKg: number,
  repetitions: number
): Promise<{ isPR: boolean; calculated1RM: number }> => {
  const calculated1RM = calculateOneRepMax(weightKg, repetitions);
  if (calculated1RM <= 0) return { isPR: false, calculated1RM: 0 };

  const currentPR = await prisma.personalRecord.findFirst({
    where: { userId, exerciseId },
    orderBy: { calculatedOneRepMax: 'desc' },
  });

  const isPR = !currentPR || (currentPR.calculatedOneRepMax !== null && calculated1RM > currentPR.calculatedOneRepMax);

  if (isPR) {
    await prisma.personalRecord.create({
      data: {
        weightKg,
        repetitions,
        calculatedOneRepMax: calculated1RM,
        achievedDate: new Date(),
        exerciseId,
        userId,
      },
    });
  }

  return { isPR, calculated1RM };
};

// ==========================================
// 1. WORKOUTS (UC-91 to UC-97)
// ==========================================

export const createWorkout = async (userId: string, data: CreateWorkoutDTO) => {
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

  return workout;
};

export const getWorkouts = async (userId: string, limit = 20) => {
  const workouts = await prisma.workout.findMany({
    where: { userId },
    orderBy: { date: 'desc' },
    take: limit,
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

  return workouts;
};

export const getWorkoutById = async (userId: string, workoutId: string) => {
  const workout = await prisma.workout.findFirst({
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
  });

  if (!workout) {
    throw new ApiError(404, 'Workout not found');
  }

  return workout;
};

export const updateWorkout = async (userId: string, workoutId: string, data: Partial<CreateWorkoutDTO>) => {
  const existing = await prisma.workout.findFirst({
    where: { id: workoutId, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Workout not found');
  }

  const updated = await prisma.workout.update({
    where: { id: workoutId },
    data: {
      ...data,
      date: data.date ? new Date(data.date) : undefined,
    },
  });

  invalidateDashboardCache(userId);

  return updated;
};

export const deleteWorkout = async (userId: string, workoutId: string) => {
  const existing = await prisma.workout.findFirst({
    where: { id: workoutId, userId },
  });

  if (!existing) {
    throw new ApiError(404, 'Workout not found');
  }

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
      notes: data.notes,
      userId,
    },
  });

  return exercise;
};

export const getExercises = async (userId: string, category?: string) => {
  const exercises = await prisma.exercise.findMany({
    where: {
      userId,
      ...(category ? { category } : {}),
    },
    orderBy: { name: 'asc' },
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

  const workoutExercise = await prisma.workoutExercise.create({
    data: {
      workoutId,
      exerciseId: data.exerciseId,
      order: data.order || 1,
    },
  });

  // If sets provided, record them and evaluate PRs
  if (data.sets && data.sets.length > 0) {
    for (const set of data.sets) {
      const { isPR } = await evaluatePersonalRecord(userId, data.exerciseId, set.weightKg, set.repetitions);
      await prisma.setEntry.create({
        data: {
          setNumber: set.setNumber,
          weightKg: set.weightKg,
          repetitions: set.repetitions,
          isPR,
          notes: set.notes,
          workoutExerciseId: workoutExercise.id,
        },
      });
    }
  }

  return getWorkoutById(userId, workoutId);
};

export const recordSet = async (
  userId: string,
  workoutExerciseId: string,
  data: SetEntryInput
) => {
  const workoutExercise = await prisma.workoutExercise.findUnique({
    where: { id: workoutExerciseId },
    include: { workout: true },
  });

  if (!workoutExercise || workoutExercise.workout.userId !== userId) {
    throw new ApiError(404, 'Workout exercise not found');
  }

  const { isPR } = await evaluatePersonalRecord(
    userId,
    workoutExercise.exerciseId,
    data.weightKg,
    data.repetitions
  );

  const setEntry = await prisma.setEntry.create({
    data: {
      setNumber: data.setNumber,
      weightKg: data.weightKg,
      repetitions: data.repetitions,
      isPR,
      notes: data.notes,
      workoutExerciseId,
    },
  });

  return { setEntry, isPR };
};

// ==========================================
// 3. BODY METRICS & ANALYTICS (UC-99 to UC-101)
// ==========================================

export const recordBodyMetric = async (userId: string, data: RecordBodyMetricDTO) => {
  const metric = await prisma.bodyMetric.create({
    data: {
      date: data.date ? new Date(data.date) : new Date(),
      weightKg: data.weightKg,
      chestCm: data.chestCm,
      waistCm: data.waistCm,
      armsCm: data.armsCm,
      legsCm: data.legsCm,
      notes: data.notes,
      userId,
    },
  });

  return metric;
};

export const getBodyMetrics = async (userId: string, limit = 30) => {
  const metrics = await prisma.bodyMetric.findMany({
    where: { userId },
    orderBy: { date: 'desc' },
    take: limit,
  });

  return metrics;
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
    prisma.personalRecord.findMany({
      where: { userId },
      orderBy: { calculatedOneRepMax: 'desc' },
      take: 5,
      include: { exercise: { select: { name: true, category: true } } },
    }),
  ]);

  return {
    totalWorkouts,
    workoutsThisMonth: monthWorkouts,
    totalPersonalRecords: totalPRs,
    currentWeightKg: latestWeight?.weightKg || null,
    topPersonalRecords: topPRs,
  };
};

export default {
  createWorkout,
  getWorkouts,
  getWorkoutById,
  updateWorkout,
  deleteWorkout,
  createExercise,
  getExercises,
  addExerciseToWorkout,
  recordSet,
  recordBodyMetric,
  getBodyMetrics,
  getGymAnalytics,
  calculateOneRepMax,
  evaluatePersonalRecord,
};
