import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';
import { invalidateDashboardCache } from '../dashboard/dashboard.service';

export interface CreateCourseDTO {
  name: string;
  code?: string | null;
  semester?: string;
  instructor?: string | null;
  credits?: number;
  progress?: number;
  color?: string;
}

export interface UpdateCourseDTO {
  name?: string;
  code?: string | null;
  semester?: string;
  instructor?: string | null;
  credits?: number;
  progress?: number;
  color?: string;
}

export interface CreateAssignmentDTO {
  title: string;
  description?: string | null;
  dueDate: Date | string;
  type?: string;
  weight?: number;
  status?: string;
  grade?: number | null;
  maxGrade?: number;
}

export interface UpdateAssignmentDTO {
  title?: string;
  description?: string | null;
  dueDate?: Date | string;
  type?: string;
  weight?: number;
  status?: string;
  grade?: number | null;
  maxGrade?: number;
}

export interface CreateExamDTO {
  title: string;
  examDate: Date | string;
  startTime?: string | null;
  examType?: string;
  weight?: number | null;
  grade?: number | null;
  maxGrade?: number;
}

export interface UpdateExamDTO {
  title?: string;
  examDate?: Date | string;
  startTime?: string | null;
  examType?: string;
  weight?: number | null;
  grade?: number | null;
  maxGrade?: number;
}

export interface RecordAttendanceDTO {
  date?: Date | string;
  status: string;
  notes?: string | null;
}

export interface AddClassScheduleDTO {
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  room?: string | null;
}

// ==========================================
// GRADE & GPA ENGINE HELPERS
// ==========================================

export interface GradeScaleResult {
  letter: string;
  points: number;
}

export const getLetterGradeAndPoints = (percentage: number): GradeScaleResult => {
  if (percentage >= 93.0) return { letter: 'A', points: 4.0 };
  if (percentage >= 90.0) return { letter: 'A-', points: 3.7 };
  if (percentage >= 87.0) return { letter: 'B+', points: 3.3 };
  if (percentage >= 83.0) return { letter: 'B', points: 3.0 };
  if (percentage >= 80.0) return { letter: 'B-', points: 2.7 };
  if (percentage >= 77.0) return { letter: 'C+', points: 2.3 };
  if (percentage >= 73.0) return { letter: 'C', points: 2.0 };
  if (percentage >= 70.0) return { letter: 'C-', points: 1.7 };
  if (percentage >= 67.0) return { letter: 'D+', points: 1.3 };
  if (percentage >= 60.0) return { letter: 'D', points: 1.0 };
  return { letter: 'F', points: 0.0 };
};

export const calculateAttendanceRate = (attendances: Array<{ status: string }>): number => {
  const evaluable = attendances.filter((a) => a.status !== 'EXCUSED');
  if (evaluable.length === 0) return 100.0;
  const presentCount = evaluable.filter((a) => a.status === 'PRESENT').length;
  const lateCount = evaluable.filter((a) => a.status === 'LATE').length;
  const effectiveAttended = presentCount + lateCount * 0.5;
  return Number(((effectiveAttended / evaluable.length) * 100).toFixed(1));
};

export const computeCourseGrade = (
  assignments: Array<{ grade: number | null; maxGrade: number | null; weight?: number | null }>,
  exams: Array<{ grade: number | null; maxGrade: number | null; weight?: number | null }>
) => {
  let totalWeightedScore = 0;
  let totalEvaluatedWeight = 0;
  let totalPossibleWeight = 0;
  let gradedItemsCount = 0;

  assignments.forEach((a) => {
    const w = a.weight ?? 10.0;
    totalPossibleWeight += w;
    if (a.grade !== null && a.grade !== undefined && a.maxGrade && a.maxGrade > 0) {
      const pct = (a.grade / a.maxGrade) * 100;
      totalWeightedScore += pct * w;
      totalEvaluatedWeight += w;
      gradedItemsCount++;
    }
  });

  exams.forEach((e) => {
    const w = e.weight ?? 25.0;
    totalPossibleWeight += w;
    if (e.grade !== null && e.grade !== undefined && e.maxGrade && e.maxGrade > 0) {
      const pct = (e.grade / e.maxGrade) * 100;
      totalWeightedScore += pct * w;
      totalEvaluatedWeight += w;
      gradedItemsCount++;
    }
  });

  const runningPercentage =
    totalEvaluatedWeight > 0
      ? Number((totalWeightedScore / totalEvaluatedWeight).toFixed(1))
      : 0.0;

  const { letter, points } = getLetterGradeAndPoints(runningPercentage);

  return {
    runningPercentage,
    letter: gradedItemsCount > 0 ? letter : 'N/A',
    gradePoints: gradedItemsCount > 0 ? points : 0.0,
    totalEvaluatedWeight,
    totalPossibleWeight,
    gradedItemsCount,
    earnedWeightPoints: Number((totalWeightedScore / 100).toFixed(1)),
  };
};

/**
 * Deduplicate study intervals between StudySession (manual logs) and FocusSession (timer logs)
 * to prevent double-counting overlapping study time.
 */
export const calculateDeduplicatedStudyMinutes = (
  studySessions: Array<{ startTime: Date | string; durationMinutes: number; endTime?: Date | string | null }>,
  focusSessions: Array<{ startTime: Date | string; durationMinutes: number; endTime?: Date | string | null }>
): number => {
  type Interval = { start: number; end: number };
  const intervals: Interval[] = [];

  const addIntervals = (
    sessions: Array<{ startTime: Date | string; durationMinutes: number; endTime?: Date | string | null }>
  ) => {
    for (const s of sessions) {
      const start = new Date(s.startTime).getTime();
      const durationMs = (s.durationMinutes || 0) * 60 * 1000;
      if (durationMs <= 0 || isNaN(start)) continue;
      const end = s.endTime ? new Date(s.endTime).getTime() : start + durationMs;
      intervals.push({ start, end: Math.max(start, isNaN(end) ? start + durationMs : end) });
    }
  };

  addIntervals(studySessions);
  addIntervals(focusSessions);

  if (intervals.length === 0) return 0;

  intervals.sort((a, b) => a.start - b.start);

  let mergedMinutes = 0;
  let current = { ...intervals[0] };

  for (let i = 1; i < intervals.length; i++) {
    const next = intervals[i];
    if (next.start <= current.end) {
      current.end = Math.max(current.end, next.end);
    } else {
      mergedMinutes += Math.round((current.end - current.start) / 60000);
      current = { ...next };
    }
  }
  mergedMinutes += Math.round((current.end - current.start) / 60000);

  return mergedMinutes;
};

/**
 * Auto-recalculate course progress based on completed assignments & exams (UC-74)
 */
export const recalculateCourseProgress = async (courseId: string, client: any = prisma) => {
  const [totalAssignments, completedAssignments, totalExams, gradedExams] = await Promise.all([
    client.assignment.count({ where: { courseId } }),
    client.assignment.count({ where: { courseId, status: { in: ['SUBMITTED', 'GRADED'] } } }),
    client.exam.count({ where: { courseId } }),
    client.exam.count({ where: { courseId, grade: { not: null } } }),
  ]);

  const totalEvaluations = totalAssignments + totalExams;
  if (totalEvaluations === 0) return 0;

  const completedEvaluations = completedAssignments + gradedExams;
  const progress = Number(((completedEvaluations / totalEvaluations) * 100).toFixed(1));

  await client.course.update({
    where: { id: courseId },
    data: { progress },
  });

  return progress;
};

/**
 * Validate that combined assignment and exam weights do not exceed 100%
 */
export const checkTotalWeightWithinLimit = async (
  courseId: string,
  newWeight: number,
  excludeAssignmentId?: string,
  excludeExamId?: string,
  client: any = prisma
) => {
  const [assignments, exams] = await Promise.all([
    client.assignment.findMany({
      where: {
        courseId,
        ...(excludeAssignmentId ? { id: { not: excludeAssignmentId } } : {}),
      },
      select: { weight: true },
    }),
    client.exam.findMany({
      where: {
        courseId,
        ...(excludeExamId ? { id: { not: excludeExamId } } : {}),
      },
      select: { weight: true },
    }),
  ]);

  const currentTotal =
    assignments.reduce((sum: number, a: { weight: number | null }) => sum + (a.weight ?? 0), 0) +
    exams.reduce((sum: number, e: { weight: number | null }) => sum + (e.weight ?? 0), 0);

  if (currentTotal + newWeight > 100.0) {
    throw new ApiError(
      400,
      `Combined course deliverables weight cannot exceed 100%. Current total is ${currentTotal.toFixed(1)}%, adding ${newWeight}% would result in ${(currentTotal + newWeight).toFixed(1)}%.`
    );
  }
};

// ==========================================
// 1. COURSES (UC-70 to UC-74)
// ==========================================

export const createCourse = async (userId: string, data: CreateCourseDTO) => {
  const course = await prisma.course.create({
    data: {
      name: data.name,
      code: data.code,
      semester: data.semester || 'Fall 2026',
      instructor: data.instructor,
      credits: data.credits || 3,
      progress: data.progress || 0.0,
      color: data.color || '#8B5CF6',
      userId,
    },
  });

  invalidateDashboardCache(userId);
  return course;
};

export const getCourses = async (userId: string, semester?: string) => {
  const courses = await prisma.course.findMany({
    where: {
      userId,
      ...(semester && semester !== 'ALL' ? { semester } : {}),
    },
    orderBy: [{ progress: 'asc' }, { name: 'asc' }],
    include: {
      _count: {
        select: {
          assignments: true,
          exams: true,
          attendances: true,
          studySessions: true,
          tasks: true,
          classSchedules: true,
        },
      },
      assignments: {
        select: { grade: true, maxGrade: true, weight: true },
      },
      exams: {
        select: { grade: true, maxGrade: true, weight: true },
      },
      attendances: {
        select: { status: true },
      },
      classSchedules: {
        select: { dayOfWeek: true, startTime: true, endTime: true, room: true },
      },
    },
  });

  return courses.map((course) => {
    const gradeDetails = computeCourseGrade(course.assignments, course.exams);
    const attendanceRate = calculateAttendanceRate(course.attendances);

    return {
      id: course.id,
      name: course.name,
      code: course.code,
      semester: course.semester,
      instructor: course.instructor,
      credits: course.credits || 3,
      progress: course.progress,
      color: course.color,
      createdAt: course.createdAt,
      updatedAt: course.updatedAt,
      counts: course._count,
      gradeDetails,
      attendanceRate,
      classSchedules: course.classSchedules,
    };
  });
};

export const getCourseById = async (userId: string, courseId: string) => {
  const course = await prisma.course.findFirst({
    where: { id: courseId, userId },
    include: {
      assignments: { orderBy: { dueDate: 'asc' } },
      exams: { orderBy: { examDate: 'asc' } },
      attendances: { orderBy: { date: 'desc' }, take: 30 },
      studySessions: { orderBy: { startTime: 'desc' }, take: 20 },
      classSchedules: { orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }] },
      tasks: {
        where: { userId },
        orderBy: [{ isCompleted: 'asc' }, { dueDate: 'asc' }],
        select: {
          id: true,
          title: true,
          status: true,
          priority: true,
          dueDate: true,
          isCompleted: true,
        },
      },
      focusSessions: {
        where: { userId },
        orderBy: { startTime: 'desc' },
        take: 20,
        select: {
          id: true,
          durationMinutes: true,
          startTime: true,
          notes: true,
        },
      },
      vaultNotes: {
        where: { userId },
        orderBy: { updatedAt: 'desc' },
        select: {
          id: true,
          title: true,
          updatedAt: true,
          tags: true,
        },
      },
    },
  });

  if (!course) {
    throw new ApiError(404, 'Course not found');
  }

  // Attendance percentage across ALL records of this course
  const allCourseAttendances = await prisma.attendance.findMany({
    where: { courseId },
    select: { status: true },
  });
  const attendanceRate = calculateAttendanceRate(allCourseAttendances);

  // Grade details
  const gradeDetails = computeCourseGrade(course.assignments, course.exams);

  // Total study time across study and focus sessions for this course
  const [allStudySessions, allFocusSessions] = await Promise.all([
    prisma.studySession.findMany({
      where: { courseId, userId },
      select: { startTime: true, durationMinutes: true, endTime: true },
    }),
    prisma.focusSession.findMany({
      where: { courseId, userId, status: 'COMPLETED' },
      select: { startTime: true, durationMinutes: true, endTime: true },
    }),
  ]);

  const studySessionMinutes = allStudySessions.reduce(
    (acc: number, s: { durationMinutes: number }) => acc + (s.durationMinutes || 0),
    0
  );
  const focusSessionMinutes = allFocusSessions.reduce(
    (acc: number, f: { durationMinutes: number }) => acc + (f.durationMinutes || 0),
    0
  );

  // Time-interval union deduplication prevents double-counting overlapping study logs
  const totalStudyMinutes = calculateDeduplicatedStudyMinutes(allStudySessions, allFocusSessions);
  const totalStudyHours = Number((totalStudyMinutes / 60.0).toFixed(1));

  return {
    ...course,
    attendanceRate,
    gradeDetails,
    studySessionMinutes,
    focusSessionMinutes,
    totalStudyMinutes,
    totalStudyHours,
  };
};

export const updateCourse = async (userId: string, courseId: string, data: UpdateCourseDTO) => {
  const existingCourse = await prisma.course.findFirst({
    where: { id: courseId, userId },
  });

  if (!existingCourse) {
    throw new ApiError(404, 'Course not found');
  }

  const updatedCourse = await prisma.course.update({
    where: { id: courseId },
    data,
  });

  invalidateDashboardCache(userId);
  return updatedCourse;
};

export const deleteCourse = async (userId: string, courseId: string) => {
  const course = await prisma.course.findFirst({
    where: { id: courseId, userId },
  });

  if (!course) {
    throw new ApiError(404, 'Course not found');
  }

  await prisma.course.delete({ where: { id: courseId } });
  invalidateDashboardCache(userId);
  return { message: 'Course deleted successfully' };
};

// ==========================================
// 2. ASSIGNMENTS (UC-75 to UC-77)
// ==========================================

export const createAssignment = async (userId: string, courseId: string, data: CreateAssignmentDTO) => {
  const maxGrade = data.maxGrade !== undefined ? Number(data.maxGrade) : 100.0;
  if (data.grade !== null && data.grade !== undefined) {
    if (Number(data.grade) > maxGrade) {
      throw new ApiError(400, 'Grade cannot exceed maximum grade');
    }
  }

  const weight = data.weight !== undefined ? Number(data.weight) : 10.0;
  const status = data.status || (data.grade !== null && data.grade !== undefined ? 'GRADED' : 'NOT_STARTED');

  const assignment = await prisma.$transaction(async (tx) => {
    const course = await tx.course.findFirst({ where: { id: courseId, userId } });
    if (!course) throw new ApiError(404, 'Course not found');

    await checkTotalWeightWithinLimit(courseId, weight, undefined, undefined, tx);

    const created = await tx.assignment.create({
      data: {
        title: data.title,
        description: data.description,
        dueDate: new Date(data.dueDate),
        type: data.type || 'HOMEWORK',
        weight,
        status,
        grade: data.grade !== null && data.grade !== undefined ? Number(data.grade) : null,
        maxGrade,
        courseId,
      },
    });

    await recalculateCourseProgress(courseId, tx);
    return created;
  });

  invalidateDashboardCache(userId);
  return assignment;
};

export const updateAssignment = async (
  userId: string,
  courseId: string,
  assignmentId: string,
  data: UpdateAssignmentDTO
) => {
  const updateData: any = { ...data };
  if (data.dueDate) updateData.dueDate = new Date(data.dueDate);

  const updatedAssignment = await prisma.$transaction(async (tx) => {
    const course = await tx.course.findFirst({ where: { id: courseId, userId } });
    if (!course) throw new ApiError(404, 'Course not found');

    const assignment = await tx.assignment.findFirst({
      where: { id: assignmentId, courseId },
    });
    if (!assignment) throw new ApiError(404, 'Assignment not found');

    if (data.weight !== undefined) {
      updateData.weight = Number(data.weight);
      await checkTotalWeightWithinLimit(courseId, updateData.weight, assignmentId, undefined, tx);
    }
    const targetMaxGrade = (data.maxGrade !== undefined && data.maxGrade !== null ? Number(data.maxGrade) : assignment.maxGrade) || 100.0;
    if (data.grade !== undefined) {
      if (data.grade !== null) {
        const numericGrade = Number(data.grade);
        if (numericGrade > targetMaxGrade) {
          throw new ApiError(400, 'Grade cannot exceed maximum grade');
        }
        updateData.grade = numericGrade;
        if (!data.status) {
          updateData.status = 'GRADED';
        }
      } else {
        updateData.grade = null;
      }
    }
    if (data.maxGrade !== undefined) updateData.maxGrade = targetMaxGrade;

    const updated = await tx.assignment.update({
      where: { id: assignmentId },
      data: updateData,
    });

    if (data.status !== undefined || data.grade !== undefined) {
      await recalculateCourseProgress(courseId, tx);
    }
    return updated;
  });

  invalidateDashboardCache(userId);
  return updatedAssignment;
};

export const deleteAssignment = async (userId: string, courseId: string, assignmentId: string) => {
  await prisma.$transaction(async (tx) => {
    const course = await tx.course.findFirst({ where: { id: courseId, userId } });
    if (!course) throw new ApiError(404, 'Course not found');

    const assignment = await tx.assignment.findFirst({
      where: { id: assignmentId, courseId },
    });
    if (!assignment) throw new ApiError(404, 'Assignment not found');

    await tx.assignment.delete({ where: { id: assignmentId } });
    await recalculateCourseProgress(courseId, tx);
  });

  invalidateDashboardCache(userId);
  return { message: 'Assignment deleted successfully' };
};

// ==========================================
// 3. EXAMS (UC-78 to UC-80)
// ==========================================

export const createExam = async (userId: string, courseId: string, data: CreateExamDTO) => {
  const maxGrade = data.maxGrade !== undefined ? Number(data.maxGrade) : 100.0;
  if (data.grade !== null && data.grade !== undefined) {
    if (Number(data.grade) > maxGrade) {
      throw new ApiError(400, 'Grade cannot exceed maximum grade');
    }
  }

  const weight = data.weight !== undefined && data.weight !== null ? Number(data.weight) : 25.0;

  const exam = await prisma.$transaction(async (tx) => {
    const course = await tx.course.findFirst({ where: { id: courseId, userId } });
    if (!course) throw new ApiError(404, 'Course not found');

    await checkTotalWeightWithinLimit(courseId, weight, undefined, undefined, tx);

    const created = await tx.exam.create({
      data: {
        title: data.title,
        examDate: new Date(data.examDate),
        startTime: data.startTime,
        examType: data.examType || 'MIDTERM',
        weight,
        grade: data.grade !== null && data.grade !== undefined ? Number(data.grade) : null,
        maxGrade,
        courseId,
      },
    });

    await recalculateCourseProgress(courseId, tx);
    return created;
  });

  invalidateDashboardCache(userId);
  return exam;
};

export const updateExam = async (
  userId: string,
  courseId: string,
  examId: string,
  data: UpdateExamDTO
) => {
  const updateData: any = { ...data };
  if (data.examDate) updateData.examDate = new Date(data.examDate);

  const updatedExam = await prisma.$transaction(async (tx) => {
    const course = await tx.course.findFirst({ where: { id: courseId, userId } });
    if (!course) throw new ApiError(404, 'Course not found');

    const exam = await tx.exam.findFirst({
      where: { id: examId, courseId },
    });
    if (!exam) throw new ApiError(404, 'Exam not found');

    if (data.weight !== undefined && data.weight !== null) {
      updateData.weight = Number(data.weight);
      await checkTotalWeightWithinLimit(courseId, updateData.weight, undefined, examId, tx);
    }
    const targetMaxGrade = (data.maxGrade !== undefined && data.maxGrade !== null ? Number(data.maxGrade) : exam.maxGrade) || 100.0;
    if (data.grade !== undefined) {
      updateData.grade = data.grade !== null ? Number(data.grade) : null;
      if (updateData.grade !== null && updateData.grade > targetMaxGrade) {
        throw new ApiError(400, 'Grade cannot exceed maximum grade');
      }
    }
    if (data.maxGrade !== undefined) updateData.maxGrade = targetMaxGrade;

    const updated = await tx.exam.update({
      where: { id: examId },
      data: updateData,
    });

    if (data.grade !== undefined) {
      await recalculateCourseProgress(courseId, tx);
    }
    return updated;
  });

  invalidateDashboardCache(userId);
  return updatedExam;
};

export const deleteExam = async (userId: string, courseId: string, examId: string) => {
  await prisma.$transaction(async (tx) => {
    const course = await tx.course.findFirst({ where: { id: courseId, userId } });
    if (!course) throw new ApiError(404, 'Course not found');

    const exam = await tx.exam.findFirst({
      where: { id: examId, courseId },
    });
    if (!exam) throw new ApiError(404, 'Exam not found');

    await tx.exam.delete({ where: { id: examId } });
    await recalculateCourseProgress(courseId, tx);
  });

  invalidateDashboardCache(userId);
  return { message: 'Exam deleted successfully' };
};

// ==========================================
// 4. ATTENDANCE (UC-82 to UC-83)
// ==========================================

export const recordAttendance = async (userId: string, courseId: string, data: RecordAttendanceDTO) => {
  const course = await prisma.course.findFirst({ where: { id: courseId, userId } });
  if (!course) throw new ApiError(404, 'Course not found');

  const rawDate = data.date ? new Date(data.date) : new Date();
  const dateKey = typeof data.date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(data.date)
    ? data.date
    : rawDate.toISOString().slice(0, 10);
  const normalizedDate = new Date(`${dateKey}T00:00:00.000Z`);

  const attendance = await prisma.attendance.upsert({
    where: {
      courseId_date: {
        courseId,
        date: normalizedDate,
      },
    },
    update: {
      status: data.status,
      notes: data.notes,
    },
    create: {
      courseId,
      date: normalizedDate,
      status: data.status,
      notes: data.notes,
    },
  });

  invalidateDashboardCache(userId);
  return attendance;
};

// ==========================================
// 5. CLASS SCHEDULES (WEEKLY TIMETABLE)
// ==========================================

export const addClassSchedule = async (userId: string, courseId: string, data: AddClassScheduleDTO) => {
  if (data.startTime >= data.endTime) {
    throw new ApiError(400, 'End time must be after start time');
  }

  const schedule = await prisma.$transaction(async (tx) => {
    const course = await tx.course.findFirst({ where: { id: courseId, userId } });
    if (!course) throw new ApiError(404, 'Course not found');

    const existingSchedules = await tx.classSchedule.findMany({
      where: {
        course: { userId },
        dayOfWeek: data.dayOfWeek,
      },
    });

    const hasOverlap = existingSchedules.some((s) => {
      return data.startTime < s.endTime && data.endTime > s.startTime;
    });

    if (hasOverlap) {
      throw new ApiError(400, 'Schedule time overlaps with an existing class on this day');
    }

    return tx.classSchedule.create({
      data: {
        courseId,
        dayOfWeek: data.dayOfWeek,
        startTime: data.startTime,
        endTime: data.endTime,
        room: data.room || null,
      },
    });
  });

  invalidateDashboardCache(userId);
  return schedule;
};

export const deleteClassSchedule = async (userId: string, courseId: string, scheduleId: string) => {
  await prisma.$transaction(async (tx) => {
    const course = await tx.course.findFirst({ where: { id: courseId, userId } });
    if (!course) throw new ApiError(404, 'Course not found');

    const schedule = await tx.classSchedule.findFirst({
      where: { id: scheduleId, courseId },
    });
    if (!schedule) throw new ApiError(404, 'Class schedule not found');

    await tx.classSchedule.delete({ where: { id: scheduleId } });
  });

  invalidateDashboardCache(userId);
  return { message: 'Class schedule removed successfully' };
};

export const getClassSchedules = async (userId: string, courseId?: string) => {
  return prisma.classSchedule.findMany({
    where: {
      course: { userId },
      ...(courseId ? { courseId } : {}),
    },
    include: {
      course: { select: { id: true, name: true, code: true, color: true } },
    },
    orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }],
  });
};

// ==========================================
// 6. GPA & WHAT-IF CALCULATOR
// ==========================================

export const calculateGpaOverview = async (userId: string, semester?: string) => {
  const courses = await prisma.course.findMany({
    where: {
      userId,
      ...(semester ? { semester } : {}),
    },
    include: {
      assignments: { select: { grade: true, maxGrade: true, weight: true } },
      exams: { select: { grade: true, maxGrade: true, weight: true } },
    },
  });

  let totalCreditPoints = 0;
  let totalCredits = 0;
  const semesterMap: Record<string, { totalPoints: number; totalCredits: number; courses: any[] }> = {};

  const coursesWithGrades = courses.map((c) => {
    const credits = c.credits || 3;
    const grade = computeCourseGrade(c.assignments, c.exams);

    if (grade.gradedItemsCount > 0) {
      totalCreditPoints += grade.gradePoints * credits;
      totalCredits += credits;
    }

    const semKey = c.semester || 'Current';
    if (!semesterMap[semKey]) {
      semesterMap[semKey] = { totalPoints: 0, totalCredits: 0, courses: [] };
    }
    if (grade.gradedItemsCount > 0) {
      semesterMap[semKey].totalPoints += grade.gradePoints * credits;
      semesterMap[semKey].totalCredits += credits;
    }
    semesterMap[semKey].courses.push({
      id: c.id,
      name: c.name,
      code: c.code,
      credits,
      color: c.color,
      grade,
    });

    return {
      id: c.id,
      name: c.name,
      code: c.code,
      credits,
      semester: c.semester,
      grade,
    };
  });

  const cumulativeGpa = totalCredits > 0 ? Number((totalCreditPoints / totalCredits).toFixed(2)) : 0.0;
  const { letter: cumulativeLetter } = getLetterGradeAndPoints(
    totalCredits > 0 ? (cumulativeGpa / 4.0) * 100 : 0
  );

  const semesters = Object.entries(semesterMap).map(([sem, data]) => {
    const semGpa = data.totalCredits > 0 ? Number((data.totalPoints / data.totalCredits).toFixed(2)) : 0.0;
    return {
      semester: sem,
      semesterGpa: semGpa,
      creditsCount: data.totalCredits,
      coursesCount: data.courses.length,
      courses: data.courses,
    };
  });

  return {
    cumulativeGpa,
    cumulativeLetter,
    totalCreditsGraded: totalCredits,
    totalCoursesCount: courses.length,
    semesters,
    courses: coursesWithGrades,
  };
};

export const calculateWhatIfFinalGrade = async (
  userId: string,
  courseId: string,
  targetPercentage: number,
  finalExamWeight?: number
) => {
  const course = await prisma.course.findFirst({
    where: { id: courseId, userId },
    include: {
      assignments: { select: { grade: true, maxGrade: true, weight: true } },
      exams: { select: { grade: true, maxGrade: true, weight: true } },
    },
  });

  if (!course) throw new ApiError(404, 'Course not found');

  const grade = computeCourseGrade(course.assignments, course.exams);

  // Accounting for graded vs remaining work
  const completedWeightFraction = grade.totalEvaluatedWeight / 100.0;
  const earnedContributionTowardsFinal = Number(
    (grade.runningPercentage * completedWeightFraction).toFixed(2)
  );
  const remainingUngradedWeight = Number(
    Math.max(0, 100.0 - grade.totalEvaluatedWeight).toFixed(2)
  );
  const maxAchievableGrade = Number(
    Math.min(100.0, earnedContributionTowardsFinal + remainingUngradedWeight).toFixed(1)
  );

  let effectiveWeight: number;

  if (finalExamWeight !== undefined && finalExamWeight !== null) {
    if (finalExamWeight <= 0 || finalExamWeight > 100) {
      throw new ApiError(400, 'Final exam weight must be between 1 and 100');
    }
    if (remainingUngradedWeight <= 0) {
      throw new ApiError(400, 'Course is already 100% evaluated. No remaining ungraded weight.');
    }
    if (finalExamWeight > remainingUngradedWeight + 0.01) {
      throw new ApiError(
        400,
        `Requested final exam weight (${finalExamWeight}%) exceeds remaining ungraded course weight (${remainingUngradedWeight}%).`
      );
    }
    effectiveWeight = finalExamWeight;
  } else {
    effectiveWeight = remainingUngradedWeight;
  }

  let status: 'ACHIEVABLE' | 'ALREADY_SECURED' | 'MATHEMATICALLY_IMPOSSIBLE' = 'ACHIEVABLE';
  let requiredScorePercentage = 0;
  let maxPossibleGrade = maxAchievableGrade;
  let message = '';

  if (effectiveWeight <= 0) {
    maxPossibleGrade = earnedContributionTowardsFinal;
    if (targetPercentage <= earnedContributionTowardsFinal) {
      status = 'ALREADY_SECURED';
      message = `Congratulations! You have already secured at least ${targetPercentage}% in this course (final grade: ${earnedContributionTowardsFinal}%).`;
    } else {
      status = 'MATHEMATICALLY_IMPOSSIBLE';
      message = `Reaching ${targetPercentage}% is mathematically unattainable. All coursework is evaluated and the final grade is ${earnedContributionTowardsFinal}%.`;
    }
  } else {
    const neededFromFinal = targetPercentage - earnedContributionTowardsFinal;
    const weightFraction = effectiveWeight / 100.0;
    requiredScorePercentage = Number((neededFromFinal / weightFraction).toFixed(1));
    maxPossibleGrade = Number((earnedContributionTowardsFinal + effectiveWeight).toFixed(1));

    if (requiredScorePercentage <= 0) {
      status = 'ALREADY_SECURED';
      message = `Congratulations! You have already secured at least ${targetPercentage}% in this course.`;
    } else if (requiredScorePercentage > 100.0) {
      status = 'MATHEMATICALLY_IMPOSSIBLE';
      message = `Reaching ${targetPercentage}% is mathematically unattainable (requires ${requiredScorePercentage}%). The maximum possible grade is ${maxPossibleGrade}%.`;
    } else {
      status = 'ACHIEVABLE';
      message = `You need ${requiredScorePercentage}% on the final evaluation (${effectiveWeight}% of course) to achieve a ${targetPercentage}% overall grade.`;
    }
  }

  const { letter: targetLetter } = getLetterGradeAndPoints(targetPercentage);

  return {
    courseId,
    courseName: course.name,
    targetPercentage,
    targetLetter,
    finalExamWeight: effectiveWeight,
    currentAverageOnGradedWork: grade.runningPercentage,
    currentRunningPercentage: grade.runningPercentage,
    currentRunningLetter: grade.letter,
    earnedContributionTowardsFinal,
    currentEarnedTowardsFinal: earnedContributionTowardsFinal,
    totalEvaluatedWeight: grade.totalEvaluatedWeight,
    remainingUngradedWeight,
    maxAchievableGrade,
    maxPossibleGrade,
    requiredScorePercentage,
    status,
    message,
  };
};

// ==========================================
// 7. ACADEMIC OVERVIEW & COUNTDOWNS
// ==========================================

export const getAcademicSummary = async (userId: string, semester?: string) => {
  const now = new Date();
  const semesterFilter = semester && semester !== 'ALL' ? { semester } : {};

  const [
    courses,
    upcomingAssignments,
    upcomingAssignmentsTotal,
    upcomingExams,
    upcomingExamsTotal,
    schedules,
  ] = await Promise.all([
    prisma.course.findMany({
      where: {
        userId,
        ...semesterFilter,
      },
      include: {
        assignments: { select: { grade: true, maxGrade: true, weight: true } },
        exams: { select: { grade: true, maxGrade: true, weight: true } },
        attendances: true,
      },
    }),
    prisma.assignment.findMany({
      where: {
        course: { userId, ...semesterFilter },
        dueDate: { gte: now },
        status: { notIn: ['SUBMITTED', 'GRADED'] },
      },
      orderBy: { dueDate: 'asc' },
      take: 8,
      include: { course: { select: { id: true, name: true, code: true, color: true } } },
    }),
    prisma.assignment.count({
      where: {
        course: { userId, ...semesterFilter },
        dueDate: { gte: now },
        status: { notIn: ['SUBMITTED', 'GRADED'] },
      },
    }),
    prisma.exam.findMany({
      where: {
        course: { userId, ...semesterFilter },
        examDate: { gte: now },
      },
      orderBy: { examDate: 'asc' },
      take: 8,
      include: { course: { select: { id: true, name: true, code: true, color: true } } },
    }),
    prisma.exam.count({
      where: {
        course: { userId, ...semesterFilter },
        examDate: { gte: now },
      },
    }),
    prisma.classSchedule.findMany({
      where: { course: { userId, ...semesterFilter } },
      include: { course: { select: { id: true, name: true, code: true, color: true } } },
      orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }],
    }),
  ]);

  // Overall attendance rate across filtered courses
  const allAttendances = courses.flatMap((c) => c.attendances);
  const overallAttendanceRate = calculateAttendanceRate(allAttendances);

  // Calculate cumulative GPA across active courses
  let totalPoints = 0;
  let totalCredits = 0;
  courses.forEach((c) => {
    const creds = c.credits || 3;
    const g = computeCourseGrade(c.assignments, c.exams);
    if (g.gradedItemsCount > 0) {
      totalPoints += g.gradePoints * creds;
      totalCredits += creds;
    }
  });

  const cumulativeGpa = totalCredits > 0 ? Number((totalPoints / totalCredits).toFixed(2)) : 0.0;
  const { letter: cumulativeLetter } = getLetterGradeAndPoints(
    totalCredits > 0 ? (cumulativeGpa / 4.0) * 100 : 0
  );

  return {
    totalCourses: courses.length,
    overallAttendanceRate,
    cumulativeGpa,
    cumulativeLetter,
    upcomingAssignmentsCount: upcomingAssignmentsTotal,
    upcomingAssignmentsTotal,
    upcomingExamsCount: upcomingExamsTotal,
    upcomingExamsTotal,
    upcomingAssignments,
    upcomingExams,
    weeklyClassSchedules: schedules,
  };
};

// ==========================================
// 8. STUDY SESSIONS (UC-84 to UC-90)
// ==========================================

export const recordStudySession = async (
  userId: string,
  courseId: string,
  data: { durationMinutes: number; notes?: string | null; startTime?: Date | string }
) => {
  const course = await prisma.course.findFirst({ where: { id: courseId, userId } });
  if (!course) throw new ApiError(404, 'Course not found');

  if (data.durationMinutes <= 0) {
    throw new ApiError(400, 'Duration must be greater than 0 minutes');
  }

  const startTime = data.startTime ? new Date(data.startTime) : new Date();
  const endTime = new Date(startTime.getTime() + data.durationMinutes * 60 * 1000);

  const session = await prisma.studySession.create({
    data: {
      startTime,
      endTime,
      durationMinutes: data.durationMinutes,
      notes: data.notes,
      courseId,
      userId,
    },
  });

  invalidateDashboardCache(userId);
  return session;
};

export const getStudySessions = async (userId: string, courseId?: string) => {
  const sessions = await prisma.studySession.findMany({
    where: {
      userId,
      ...(courseId ? { courseId } : {}),
    },
    orderBy: { startTime: 'desc' },
    include: {
      course: { select: { id: true, name: true, color: true } },
    },
  });

  return sessions;
};

export default {
  createCourse,
  getCourses,
  getCourseById,
  updateCourse,
  deleteCourse,
  createAssignment,
  updateAssignment,
  deleteAssignment,
  createExam,
  updateExam,
  deleteExam,
  recordAttendance,
  addClassSchedule,
  deleteClassSchedule,
  getClassSchedules,
  calculateGpaOverview,
  calculateWhatIfFinalGrade,
  recordStudySession,
  getStudySessions,
  getAcademicSummary,
  recalculateCourseProgress,
};
