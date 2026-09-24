import prisma from '../../config/db';
import ApiError from '../../common/apiError';

export interface DefaultExerciseDef {
  name: string;
  category: string;
  muscleGroup: string;
  equipmentType: string;
  notes?: string;
}

const DEFAULT_EXERCISE_CATALOG: DefaultExerciseDef[] = [
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

export class GymService {
  /**
   * Calculates estimated 1-Rep Max using the Epley formula
   */
  calculateOneRepMax(weightKg: number, repetitions: number): number {
    if (repetitions <= 0 || weightKg <= 0) return 0;
    if (repetitions === 1) return weightKg;
    // Epley: weight * (1 + reps/30)
    const epley = weightKg * (1 + repetitions / 30.0);
    return Math.round(epley * 10) / 10;
  }

  /**
   * Lazily seeds default exercise catalog for a user if they have 0 exercises
   */
  async ensureDefaultExercises(userId: string) {
    const count = await prisma.exercise.count({ where: { userId } });
    if (count > 0) return;

    await prisma.exercise.createMany({
      data: DEFAULT_EXERCISE_CATALOG.map((e) => ({
        userId,
        name: e.name,
        category: e.category,
        muscleGroup: e.muscleGroup,
        equipmentType: e.equipmentType,
        isCustom: false,
      })),
      skipDuplicates: true,
    });
  }

  /**
   * Lazily seeds standard workout templates for a user if they have 0 templates
   */
  async ensureDefaultTemplates(userId: string) {
    const count = await prisma.workoutTemplate.count({ where: { userId } });
    if (count > 0) return;

    await this.ensureDefaultExercises(userId);
    const exercises = await prisma.exercise.findMany({ where: { userId } });
    const exMap = new Map<string, string>(exercises.map((e) => [e.name, e.id]));

    // 1. Push Day Template
    const pushTemplate = await prisma.workoutTemplate.create({
      data: {
        userId,
        name: 'Push Day (Chest, Shoulders, Triceps)',
        category: 'PPL',
        description: 'Hypertrophy focus on horizontal & vertical press plus triceps',
      },
    });

    const pushExercises = [
      { name: 'Barbell Bench Press', sets: 4, reps: 8, rpe: 8 },
      { name: 'Incline Dumbbell Press', sets: 3, reps: 10, rpe: 8.5 },
      { name: 'Dumbbell Lateral Raise', sets: 4, reps: 12, rpe: 9 },
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
  }

  // ==========================================
  // EXERCISES CATALOG & HISTORY
  // ==========================================

  async getExercises(userId: string, query: any = {}) {
    await this.ensureDefaultExercises(userId);

    const where: any = { userId };
    if (query.category) where.category = query.category;
    if (query.muscleGroup) where.muscleGroup = query.muscleGroup;
    if (query.equipmentType) where.equipmentType = query.equipmentType;

    return prisma.exercise.findMany({
      where,
      orderBy: [{ isCustom: 'asc' }, { name: 'asc' }],
    });
  }

  async createExercise(userId: string, data: any) {
    if (!data.name) throw ApiError.badRequest('Exercise name is required');

    const existing = await prisma.exercise.findUnique({
      where: { userId_name: { userId, name: data.name } },
    });
    if (existing) throw ApiError.badRequest('An exercise with this name already exists');

    return prisma.exercise.create({
      data: {
        userId,
        name: data.name,
        category: data.category || 'CHEST',
        muscleGroup: data.muscleGroup || data.category || 'CHEST',
        equipmentType: data.equipmentType || 'BARBELL',
        notes: data.notes || null,
        isCustom: true,
      },
    });
  }

  async getExerciseHistory(userId: string, exerciseId: string) {
    const exercise = await prisma.exercise.findFirst({
      where: { id: exerciseId, userId },
    });
    if (!exercise) throw ApiError.notFound('Exercise not found');

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
        const est1RM = s.estimatedOneRepMax || this.calculateOneRepMax(s.weightKg, s.repetitions);
        if (est1RM > maxEst1RM) maxEst1RM = est1RM;
        totalVolume += s.weightKg * s.repetitions;
      });

      return {
        workoutId: we.workout.id,
        workoutName: we.workout.name,
        date: we.workout.date,
        sets: we.sets,
        maxWeight,
        maxEst1RM,
        totalVolume,
      };
    });

    const currentPR = await prisma.personalRecord.findFirst({
      where: { userId, exerciseId },
      orderBy: { calculatedOneRepMax: 'desc' },
    });

    const lastPerformance = sessions.length > 0 ? sessions[0] : null;

    return {
      exercise,
      currentPR,
      lastPerformance,
      totalSessions: sessions.length,
      history: sessions,
    };
  }

  // ==========================================
  // TRANSACTIONAL WORKOUT LOGGING & PRs
  // ==========================================

  async logWorkout(userId: string, data: any) {
    if (!data.name) throw ApiError.badRequest('Workout name is required');
    await this.ensureDefaultExercises(userId);

    const workoutDate = data.date ? new Date(data.date) : new Date();
    const durationMinutes = data.durationMinutes ? Number(data.durationMinutes) : 60;
    const rawExercises: any[] = Array.isArray(data.exercises) ? data.exercises : [];

    return await prisma.$transaction(async (tx) => {
      // 1. Create Workout
      const workout = await tx.workout.create({
        data: {
          userId,
          name: data.name,
          date: workoutDate,
          startTime: data.startTime || null,
          durationMinutes,
          notes: data.notes || null,
          isCompleted: true,
        },
      });

      const detectedPRs: any[] = [];
      let totalTonnage = 0;
      let totalSetsCount = 0;

      // 2. Insert WorkoutExercises and SetEntries
      for (let i = 0; i < rawExercises.length; i++) {
        const exItem = rawExercises[i];
        const exerciseId = exItem.exerciseId;

        const we = await tx.workoutExercise.create({
          data: {
            workoutId: workout.id,
            exerciseId,
            order: exItem.order || i + 1,
          },
        });

        // Query historical PR for this exercise
        const existingPR = await tx.personalRecord.findFirst({
          where: { userId, exerciseId },
          orderBy: { calculatedOneRepMax: 'desc' },
        });

        const rawSets: any[] = Array.isArray(exItem.sets) ? exItem.sets : [];
        for (let sIdx = 0; sIdx < rawSets.length; sIdx++) {
          const s = rawSets[sIdx];
          const weightKg = Number(s.weightKg || 0);
          const repetitions = Number(s.repetitions || 0);
          const rpe = s.rpe !== undefined ? Number(s.rpe) : null;
          const rir = s.rir !== undefined ? Number(s.rir) : null;
          const estimated1RM = this.calculateOneRepMax(weightKg, repetitions);
          totalTonnage += weightKg * repetitions;
          totalSetsCount++;

          // Check if this set is a PR
          let isPR = false;
          if (weightKg > 0 && repetitions > 0) {
            if (!existingPR || estimated1RM > (existingPR.calculatedOneRepMax || 0)) {
              isPR = true;
              // Record or update PR in database
              await tx.personalRecord.create({
                data: {
                  userId,
                  exerciseId,
                  weightKg,
                  repetitions,
                  calculatedOneRepMax: estimated1RM,
                  achievedDate: workoutDate,
                },
              });

              // Fetch exercise name for response
              const exInfo = await tx.exercise.findUnique({ where: { id: exerciseId } });
              detectedPRs.push({
                exerciseName: exInfo?.name || 'Exercise',
                weightKg,
                repetitions,
                estimatedOneRepMax: estimated1RM,
                previous1RM: existingPR?.calculatedOneRepMax || 0,
              });
            }
          }

          await tx.setEntry.create({
            data: {
              workoutExerciseId: we.id,
              setNumber: s.setNumber || sIdx + 1,
              weightKg,
              repetitions,
              rpe,
              rir,
              estimatedOneRepMax: estimated1RM,
              isPR,
              notes: s.notes || null,
            },
          });
        }
      }

      // Fetch full workout with exercises & sets
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
        totalTonnage,
        totalSetsCount,
        detectedPRs,
      };
    });
  }

  async getWorkouts(userId: string, query: any = {}) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const [total, workouts] = await Promise.all([
      prisma.workout.count({ where: { userId } }),
      prisma.workout.findMany({
        where: { userId },
        include: {
          exercises: {
            orderBy: { order: 'asc' },
            include: {
              exercise: true,
              sets: { orderBy: { setNumber: 'asc' } },
            },
          },
        },
        orderBy: { date: 'desc' },
        skip,
        take: limit,
      }),
    ]);

    const formatted = workouts.map((w) => {
      let totalVolume = 0;
      let prCount = 0;
      let totalSets = 0;

      w.exercises.forEach((we) => {
        we.sets.forEach((s) => {
          totalVolume += s.weightKg * s.repetitions;
          totalSets++;
          if (s.isPR) prCount++;
        });
      });

      return {
        id: w.id,
        name: w.name,
        date: w.date,
        durationMinutes: w.durationMinutes,
        notes: w.notes,
        isCompleted: w.isCompleted,
        exercisesCount: w.exercises.length,
        totalSets,
        totalVolume,
        prCount,
        exercises: w.exercises,
      };
    });

    return {
      data: formatted,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getWorkoutById(userId: string, id: string) {
    const workout = await prisma.workout.findFirst({
      where: { id, userId },
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

    if (!workout) throw ApiError.notFound('Workout not found');

    let totalVolume = 0;
    let prCount = 0;
    workout.exercises.forEach((we) => {
      we.sets.forEach((s) => {
        totalVolume += s.weightKg * s.repetitions;
        if (s.isPR) prCount++;
      });
    });

    return {
      ...workout,
      totalVolume,
      prCount,
    };
  }

  async deleteWorkout(userId: string, id: string) {
    const existing = await prisma.workout.findFirst({ where: { id, userId } });
    if (!existing) throw ApiError.notFound('Workout not found');

    await prisma.workout.delete({ where: { id } });
    return true;
  }

  // ==========================================
  // PERSONAL RECORDS & PROGRESSIVE OVERLOAD
  // ==========================================

  async getPersonalRecords(userId: string) {
    const prs = await prisma.personalRecord.findMany({
      where: { userId },
      include: { exercise: true },
      orderBy: { achievedDate: 'desc' },
    });

    // Group by exercise (best PR per exercise)
    const bestByExercise = new Map<string, any>();
    prs.forEach((pr) => {
      const existing = bestByExercise.get(pr.exerciseId);
      if (!existing || (pr.calculatedOneRepMax || 0) > (existing.calculatedOneRepMax || 0)) {
        bestByExercise.set(pr.exerciseId, pr);
      }
    });

    return {
      totalPRsAchieved: prs.length,
      personalRecords: Array.from(bestByExercise.values()),
      recentPRs: prs.slice(0, 10),
    };
  }

  // ==========================================
  // VOLUME ANALYTICS & MUSCLE GROUP BALANCE
  // ==========================================

  async getGymStats(userId: string) {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // Monday of current week
    const currentDay = startOfToday.getDay();
    const diffToMonday = startOfToday.getDate() - currentDay + (currentDay === 0 ? -6 : 1);
    const currentWeekMonday = new Date(startOfToday.setDate(diffToMonday));

    // User preference for weekly target
    const prefs = await prisma.userPreference.findUnique({ where: { userId } });
    const weeklyTarget = prefs?.weeklyGymTarget ?? 4;

    const workouts = await prisma.workout.findMany({
      where: { userId },
      include: {
        exercises: {
          include: {
            exercise: true,
            sets: true,
          },
        },
      },
      orderBy: { date: 'desc' },
    });

    const workoutsThisWeek = workouts.filter((w) => new Date(w.date) >= currentWeekMonday);
    const workedOutToday = workouts.some(
      (w) => new Date(w.date).toDateString() === new Date().toDateString()
    );

    let totalLifetimeTonnage = 0;
    const muscleVolume: Record<string, number> = {
      CHEST: 0,
      BACK: 0,
      LEGS: 0,
      SHOULDERS: 0,
      ARMS: 0,
      CORE: 0,
    };

    // Calculate weekly buckets for past 8 weeks
    const weeklyBuckets: Record<string, { weekStart: string; volumeKg: number; workoutsCount: number }> = {};
    for (let i = 7; i >= 0; i--) {
      const d = new Date(currentWeekMonday.getTime() - i * 7 * 24 * 60 * 60 * 1000);
      const key = d.toISOString().split('T')[0];
      weeklyBuckets[key] = { weekStart: key, volumeKg: 0, workoutsCount: 0 };
    }

    workouts.forEach((w) => {
      const wDate = new Date(w.date);
      const day = wDate.getDay();
      const diff = wDate.getDate() - day + (day === 0 ? -6 : 1);
      const monday = new Date(new Date(wDate).setDate(diff)).toISOString().split('T')[0];

      if (weeklyBuckets[monday]) {
        weeklyBuckets[monday].workoutsCount += 1;
      }

      w.exercises.forEach((we) => {
        const mGroup = we.exercise.muscleGroup || we.exercise.category || 'CHEST';
        we.sets.forEach((s) => {
          const vol = s.weightKg * s.repetitions;
          totalLifetimeTonnage += vol;
          muscleVolume[mGroup] = (muscleVolume[mGroup] || 0) + vol;
          if (weeklyBuckets[monday]) {
            weeklyBuckets[monday].volumeKg += vol;
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

    return {
      workoutsThisWeek: workoutsThisWeek.length,
      weeklyTarget,
      workedOutToday,
      totalLifetimeTonnage,
      weeklyVolumeTrend: Object.values(weeklyBuckets),
      muscleDistribution,
    };
  }

  // ==========================================
  // CROSS-MODULE TRAINING INSIGHTS
  // ==========================================

  async getGymInsights(userId: string) {
    const workouts = await prisma.workout.findMany({
      where: { userId },
      include: {
        exercises: {
          include: {
            exercise: true,
            sets: true,
          },
        },
      },
      orderBy: { date: 'asc' },
    });

    if (workouts.length < 2) {
      return {
        insights: [
          {
            type: 'STARTER',
            title: 'Begin Progressive Overload',
            message: 'Log at least 3 workouts to unlock rest-day correlation and muscle balance intelligence.',
            severity: 'INFO',
          },
        ],
      };
    }

    const insights: any[] = [];

    // 1. Rest Day vs PR correlation
    let prsAfterRestDay = 0;
    let totalPRSessions = 0;

    for (let i = 1; i < workouts.length; i++) {
      const current = workouts[i];
      const prev = workouts[i - 1];
      const hasPR = current.exercises.some((e) => e.sets.some((s) => s.isPR));

      if (hasPR) {
        totalPRSessions++;
        const daysBetween = Math.floor(
          (new Date(current.date).getTime() - new Date(prev.date).getTime()) / (1000 * 60 * 60 * 24)
        );
        if (daysBetween >= 2) {
          prsAfterRestDay++;
        }
      }
    }

    if (totalPRSessions > 0) {
      const restDayPRRatio = Math.round((prsAfterRestDay / totalPRSessions) * 100);
      insights.push({
        type: 'REST_DAY_CORRELATION',
        title: 'Rest Day Strength Supercompensation',
        message: `${restDayPRRatio}% of your all-time PRs were achieved immediately following a rest day. Quality recovery directly accelerates progressive overload.`,
        severity: 'POSITIVE',
      });
    }

    // 2. Volume Balance Warning (Check last 14 days)
    const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);
    const recentWorkouts = workouts.filter((w) => new Date(w.date) >= fourteenDaysAgo);

    const recentMuscleVolume: Record<string, number> = { CHEST: 0, BACK: 0, LEGS: 0 };
    recentWorkouts.forEach((w) => {
      w.exercises.forEach((we) => {
        const mg = we.exercise.muscleGroup || we.exercise.category;
        if (recentMuscleVolume[mg] !== undefined) {
          we.sets.forEach((s) => {
            recentMuscleVolume[mg] += s.weightKg * s.repetitions;
          });
        }
      });
    });

    if (recentMuscleVolume.LEGS === 0 && (recentMuscleVolume.CHEST > 0 || recentMuscleVolume.BACK > 0)) {
      insights.push({
        type: 'VOLUME_BALANCE',
        title: 'Muscle Balance Alert: Legs Under-trained',
        message: 'You have logged 0 leg volume over the last 14 days. Incorporating squats or leg presses helps prevent structural imbalances.',
        severity: 'WARNING',
      });
    }

    return { insights };
  }

  // ==========================================
  // WORKOUT TEMPLATES & ROUTINES
  // ==========================================

  async getTemplates(userId: string) {
    await this.ensureDefaultTemplates(userId);

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

    // Augment with last performance for each exercise
    const augmented = await Promise.all(
      templates.map(async (tmpl) => {
        const exercisesWithHistory = await Promise.all(
          tmpl.exercises.map(async (te) => {
            const lastWe = await prisma.workoutExercise.findFirst({
              where: { exerciseId: te.exerciseId, workout: { userId } },
              include: { sets: { orderBy: { setNumber: 'asc' } } },
              orderBy: { workout: { date: 'desc' } },
            });

            return {
              ...te,
              lastPerformance: lastWe ? lastWe.sets : [],
            };
          })
        );

        return {
          ...tmpl,
          exercises: exercisesWithHistory,
        };
      })
    );

    return augmented;
  }

  async getTemplateById(userId: string, id: string) {
    const template = await prisma.workoutTemplate.findFirst({
      where: { id, userId },
      include: {
        exercises: {
          orderBy: { order: 'asc' },
          include: { exercise: true },
        },
      },
    });

    if (!template) throw ApiError.notFound('Workout template not found');
    return template;
  }

  async createTemplate(userId: string, data: any) {
    if (!data.name) throw ApiError.badRequest('Template name is required');

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

    return this.getTemplateById(userId, template.id);
  }

  async deleteTemplate(userId: string, id: string) {
    const existing = await prisma.workoutTemplate.findFirst({ where: { id, userId } });
    if (!existing) throw ApiError.notFound('Workout template not found');

    await prisma.workoutTemplate.delete({ where: { id } });
    return true;
  }

  // ==========================================
  // BODY METRICS & 7-DAY MOVING AVERAGE
  // ==========================================

  async getBodyMetrics(userId: string) {
    const metrics = await prisma.bodyMetric.findMany({
      where: { userId },
      orderBy: { date: 'asc' },
    });

    // Compute 7-day moving average
    const enriched = metrics.map((m, idx) => {
      const mTime = new Date(m.date).getTime();
      const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;

      // Find all entries in [mTime - 7 days, mTime]
      const windowEntries = metrics.filter((other) => {
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

    return enriched.reverse(); // Latest first
  }

  async logBodyMetric(userId: string, data: any) {
    if (data.weightKg === undefined) throw ApiError.badRequest('Weight is required');

    return prisma.bodyMetric.create({
      data: {
        userId,
        date: data.date ? new Date(data.date) : new Date(),
        weightKg: Number(data.weightKg),
        bodyFatPercent: data.bodyFatPercent !== undefined ? Number(data.bodyFatPercent) : null,
        chestCm: data.chestCm !== undefined ? Number(data.chestCm) : null,
        waistCm: data.waistCm !== undefined ? Number(data.waistCm) : null,
        armsCm: data.armsCm !== undefined ? Number(data.armsCm) : null,
        legsCm: data.legsCm !== undefined ? Number(data.legsCm) : null,
        photoUrl: data.photoUrl || null,
        notes: data.notes || null,
      },
    });
  }

  async deleteBodyMetric(userId: string, id: string) {
    const existing = await prisma.bodyMetric.findFirst({ where: { id, userId } });
    if (!existing) throw ApiError.notFound('Body metric not found');

    await prisma.bodyMetric.delete({ where: { id } });
    return true;
  }
}

export default new GymService();
