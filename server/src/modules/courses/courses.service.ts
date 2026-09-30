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
 * Auto-recalculate course progress based on completed assignments & exams (UC-74)
 */
export const recalculateCourseProgress = async (courseId: string) => {
  const [totalAssignments, completedAssignments, totalExams, gradedExams] = await Promise.all([
    prisma.assignment.count({ where: { courseId } }),
    prisma.assignment.count({ where: { courseId, status: { in: ['SUBMITTED', 'GRADED'] } } }),
    prisma.exam.count({ where: { courseId } }),
    prisma.exam.count({ where: { courseId, grade: { not: null } } }),
  ]);

  const totalEvaluations = totalAssignments + totalExams;
  if (totalEvaluations === 0) return 0;

  const completedEvaluations = completedAssignments + gradedExams;
  const progress = Number(((completedEvaluations / totalEvaluations) * 100).toFixed(1));

  await prisma.course.update({
    where: { id: courseId },
    data: { progress },
  });

  return progress;
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

  return course;
};

export const getCourses = async (userId: string, semester?: string) => {
  const courses = await prisma.course.findMany({
    where: {
      userId,
      ...(semester ? { semester } : {}),
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

    const totalAttendances = course.attendances.length;
    const presentCount = course.attendances.filter((a) => a.status === 'PRESENT').length;
    const attendanceRate =
      totalAttendances > 0
        ? Number(((presentCount / totalAttendances) * 100).toFixed(1))
        : 100.0;

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

  // Attendance percentage
  const totalAttendances = course.attendances.length;
  const presentCount = course.attendances.filter((a) => a.status === 'PRESENT').length;
  const attendanceRate =
    totalAttendances > 0 ? Number(((presentCount / totalAttendances) * 100).toFixed(1)) : 100.0;

  // Grade details
  const gradeDetails = computeCourseGrade(course.assignments, course.exams);

  // Total study time
  let totalStudyMinutes = 0;
  course.studySessions.forEach((s) => (totalStudyMinutes += s.durationMinutes || 0));
  course.focusSessions.forEach((f) => (totalStudyMinutes += f.durationMinutes || 0));

  return {
    ...course,
    attendanceRate,
    gradeDetails,
    totalStudyMinutes,
    totalStudyHours: Number((totalStudyMinutes / 60.0).toFixed(1)),
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
  return { message: 'Course deleted successfully' };
};

// ==========================================
// 2. ASSIGNMENTS (UC-75 to UC-77)
// ==========================================

export const createAssignment = async (userId: string, courseId: string, data: CreateAssignmentDTO) => {
  const course = await prisma.course.findFirst({ where: { id: courseId, userId } });
  if (!course) throw new ApiError(404, 'Course not found');

  const assignment = await prisma.assignment.create({
    data: {
      title: data.title,
      description: data.description,
      dueDate: new Date(data.dueDate),
      type: data.type || 'HOMEWORK',
      weight: data.weight !== undefined ? Number(data.weight) : 10.0,
      status: data.status || 'NOT_STARTED',
      grade: data.grade,
      maxGrade: data.maxGrade || 100.0,
      courseId,
    },
  });

  await recalculateCourseProgress(courseId);
  invalidateDashboardCache(userId);

  return assignment;
};

export const updateAssignment = async (
  userId: string,
  courseId: string,
  assignmentId: string,
  data: UpdateAssignmentDTO
) => {
  const course = await prisma.course.findFirst({ where: { id: courseId, userId } });
  if (!course) throw new ApiError(404, 'Course not found');

  const assignment = await prisma.assignment.findFirst({
    where: { id: assignmentId, courseId },
  });
  if (!assignment) throw new ApiError(404, 'Assignment not found');

  const updateData: any = { ...data };
  if (data.dueDate) updateData.dueDate = new Date(data.dueDate);
  if (data.weight !== undefined) updateData.weight = Number(data.weight);
  if (data.grade !== undefined) updateData.grade = data.grade !== null ? Number(data.grade) : null;
  if (data.maxGrade !== undefined) updateData.maxGrade = Number(data.maxGrade);

  const updatedAssignment = await prisma.assignment.update({
    where: { id: assignmentId },
    data: updateData,
  });

  if (data.status !== undefined || data.grade !== undefined) {
    await recalculateCourseProgress(courseId);
  }

  invalidateDashboardCache(userId);

  return updatedAssignment;
};

export const deleteAssignment = async (userId: string, courseId: string, assignmentId: string) => {
  const course = await prisma.course.findFirst({ where: { id: courseId, userId } });
  if (!course) throw new ApiError(404, 'Course not found');

  const assignment = await prisma.assignment.findFirst({
    where: { id: assignmentId, courseId },
  });
  if (!assignment) throw new ApiError(404, 'Assignment not found');

  await prisma.assignment.delete({ where: { id: assignmentId } });
  await recalculateCourseProgress(courseId);

  invalidateDashboardCache(userId);

  return { message: 'Assignment deleted successfully' };
};

// ==========================================
// 3. EXAMS (UC-78 to UC-80)
// ==========================================

export const createExam = async (userId: string, courseId: string, data: CreateExamDTO) => {
  const course = await prisma.course.findFirst({ where: { id: courseId, userId } });
  if (!course) throw new ApiError(404, 'Course not found');

  const exam = await prisma.exam.create({
    data: {
      title: data.title,
      examDate: new Date(data.examDate),
      startTime: data.startTime,
      examType: data.examType || 'MIDTERM',
      weight: data.weight !== undefined ? Number(data.weight) : 25.0,
      grade: data.grade,
      maxGrade: data.maxGrade || 100.0,
      courseId,
    },
  });

  await recalculateCourseProgress(courseId);
  return exam;
};

export const updateExam = async (
  userId: string,
  courseId: string,
  examId: string,
  data: UpdateExamDTO
) => {
  const course = await prisma.course.findFirst({ where: { id: courseId, userId } });
  if (!course) throw new ApiError(404, 'Course not found');

  const exam = await prisma.exam.findFirst({
    where: { id: examId, courseId },
  });
  if (!exam) throw new ApiError(404, 'Exam not found');

  const updateData: any = { ...data };
  if (data.examDate) updateData.examDate = new Date(data.examDate);
  if (data.weight !== undefined) updateData.weight = Number(data.weight);
  if (data.grade !== undefined) updateData.grade = data.grade !== null ? Number(data.grade) : null;
  if (data.maxGrade !== undefined) updateData.maxGrade = Number(data.maxGrade);

  const updatedExam = await prisma.exam.update({
    where: { id: examId },
    data: updateData,
  });

  if (data.grade !== undefined) {
    await recalculateCourseProgress(courseId);
  }

  return updatedExam;
};

export const deleteExam = async (userId: string, courseId: string, examId: string) => {
  const course = await prisma.course.findFirst({ where: { id: courseId, userId } });
  if (!course) throw new ApiError(404, 'Course not found');

  const exam = await prisma.exam.findFirst({
    where: { id: examId, courseId },
  });
  if (!exam) throw new ApiError(404, 'Exam not found');

  await prisma.exam.delete({ where: { id: examId } });
  await recalculateCourseProgress(courseId);

  return { message: 'Exam deleted successfully' };
};

// ==========================================
// 4. ATTENDANCE (UC-82 to UC-83)
// ==========================================

export const recordAttendance = async (userId: string, courseId: string, data: RecordAttendanceDTO) => {
  const course = await prisma.course.findFirst({ where: { id: courseId, userId } });
  if (!course) throw new ApiError(404, 'Course not found');

  const rawDate = data.date ? new Date(data.date) : new Date();
  const normalizedDate = new Date(rawDate.getFullYear(), rawDate.getMonth(), rawDate.getDate());

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

  return attendance;
};

// ==========================================
// 5. CLASS SCHEDULES (WEEKLY TIMETABLE)
// ==========================================

export const addClassSchedule = async (userId: string, courseId: string, data: AddClassScheduleDTO) => {
  const course = await prisma.course.findFirst({ where: { id: courseId, userId } });
  if (!course) throw new ApiError(404, 'Course not found');

  const schedule = await prisma.classSchedule.create({
    data: {
      courseId,
      dayOfWeek: data.dayOfWeek,
      startTime: data.startTime,
      endTime: data.endTime,
      room: data.room || null,
    },
  });

  return schedule;
};

export const deleteClassSchedule = async (userId: string, courseId: string, scheduleId: string) => {
  const course = await prisma.course.findFirst({ where: { id: courseId, userId } });
  if (!course) throw new ApiError(404, 'Course not found');

  const schedule = await prisma.classSchedule.findFirst({
    where: { id: scheduleId, courseId },
  });
  if (!schedule) throw new ApiError(404, 'Class schedule not found');

  await prisma.classSchedule.delete({ where: { id: scheduleId } });
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
  finalExamWeight: number = 30.0
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

  // Total weight currently accounted for
  const completedWeightFraction = grade.totalEvaluatedWeight / 100.0;
  // Weighted percentage earned toward 100% of course grade so far
  const currentEarnedTowardsFinal = (grade.runningPercentage * completedWeightFraction);

  // Target points remaining
  const neededFromFinal = targetPercentage - currentEarnedTowardsFinal;
  const weightFraction = finalExamWeight / 100.0;

  const requiredScorePercentage = Number((neededFromFinal / weightFraction).toFixed(1));
  const maxPossibleGrade = Number((currentEarnedTowardsFinal + finalExamWeight).toFixed(1));

  let status: 'ACHIEVABLE' | 'ALREADY_SECURED' | 'MATHEMATICALLY_IMPOSSIBLE' = 'ACHIEVABLE';
  let message = `You need ${requiredScorePercentage}% on the final exam (${finalExamWeight}% of course) to achieve a ${targetPercentage}% overall grade.`;

  if (requiredScorePercentage <= 0) {
    status = 'ALREADY_SECURED';
    message = `Congratulations! You have already secured at least ${targetPercentage}% in this course.`;
  } else if (requiredScorePercentage > 100.0) {
    status = 'MATHEMATICALLY_IMPOSSIBLE';
    message = `Reaching ${targetPercentage}% is mathematically unattainable (requires ${requiredScorePercentage}%). The maximum possible grade is ${maxPossibleGrade}%.`;
  }

  const { letter: targetLetter } = getLetterGradeAndPoints(targetPercentage);

  return {
    courseId,
    courseName: course.name,
    targetPercentage,
    targetLetter,
    finalExamWeight,
    currentRunningPercentage: grade.runningPercentage,
    currentRunningLetter: grade.letter,
    currentEarnedTowardsFinal: Number(currentEarnedTowardsFinal.toFixed(1)),
    requiredScorePercentage,
    maxPossibleGrade,
    status,
    message,
  };
};

// ==========================================
// 7. ACADEMIC OVERVIEW & COUNTDOWNS
// ==========================================

export const getAcademicSummary = async (userId: string) => {
  const now = new Date();

  const [courses, upcomingAssignments, upcomingExams, schedules] = await Promise.all([
    prisma.course.findMany({
      where: { userId },
      include: {
        assignments: { select: { grade: true, maxGrade: true, weight: true } },
        exams: { select: { grade: true, maxGrade: true, weight: true } },
        attendances: true,
      },
    }),
    prisma.assignment.findMany({
      where: {
        course: { userId },
        dueDate: { gte: now },
        status: { notIn: ['SUBMITTED', 'GRADED'] },
      },
      orderBy: { dueDate: 'asc' },
      take: 6,
      include: { course: { select: { id: true, name: true, code: true, color: true } } },
    }),
    prisma.exam.findMany({
      where: {
        course: { userId },
        examDate: { gte: now },
      },
      orderBy: { examDate: 'asc' },
      take: 6,
      include: { course: { select: { id: true, name: true, code: true, color: true } } },
    }),
    prisma.classSchedule.findMany({
      where: { course: { userId } },
      include: { course: { select: { id: true, name: true, code: true, color: true } } },
      orderBy: [{ dayOfWeek: 'asc' }, { startTime: 'asc' }],
    }),
  ]);

  // Overall attendance rate across all courses
  let totalAttendances = 0;
  let presentAttendances = 0;
  courses.forEach((c) => {
    totalAttendances += c.attendances.length;
    presentAttendances += c.attendances.filter((a) => a.status === 'PRESENT').length;
  });

  const overallAttendanceRate =
    totalAttendances > 0 ? Number(((presentAttendances / totalAttendances) * 100).toFixed(1)) : 100.0;

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
    upcomingAssignmentsCount: upcomingAssignments.length,
    upcomingExamsCount: upcomingExams.length,
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
