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
  status?: string;
  grade?: number | null;
  maxGrade?: number;
}

export interface UpdateAssignmentDTO {
  title?: string;
  description?: string | null;
  dueDate?: Date | string;
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
        },
      },
    },
  });

  return courses;
};

export const getCourseById = async (userId: string, courseId: string) => {
  const course = await prisma.course.findFirst({
    where: { id: courseId, userId },
    include: {
      assignments: { orderBy: { dueDate: 'asc' } },
      exams: { orderBy: { examDate: 'asc' } },
      attendances: { orderBy: { date: 'desc' }, take: 20 },
      studySessions: { orderBy: { startTime: 'desc' }, take: 10 },
    },
  });

  if (!course) {
    throw new ApiError(404, 'Course not found');
  }

  // Compute attendance percentage
  const totalAttendances = course.attendances.length;
  const presentCount = course.attendances.filter((a) => a.status === 'PRESENT').length;
  const attendanceRate = totalAttendances > 0 ? Number(((presentCount / totalAttendances) * 100).toFixed(1)) : 100;

  return {
    ...course,
    attendanceRate,
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

  const updatedAssignment = await prisma.assignment.update({
    where: { id: assignmentId },
    data: {
      ...data,
      dueDate: data.dueDate ? new Date(data.dueDate) : undefined,
    },
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
      weight: data.weight,
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

  const updatedExam = await prisma.exam.update({
    where: { id: examId },
    data: {
      ...data,
      examDate: data.examDate ? new Date(data.examDate) : undefined,
    },
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
// 5. ACADEMIC OVERVIEW & COUNTDOWNS (UC-77, UC-79, UC-81)
// ==========================================

export const getAcademicSummary = async (userId: string) => {
  const now = new Date();

  const [courses, upcomingAssignments, upcomingExams] = await Promise.all([
    prisma.course.findMany({
      where: { userId },
      include: {
        assignments: true,
        exams: true,
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
      take: 5,
      include: { course: { select: { name: true, color: true } } },
    }),
    prisma.exam.findMany({
      where: {
        course: { userId },
        examDate: { gte: now },
      },
      orderBy: { examDate: 'asc' },
      take: 5,
      include: { course: { select: { name: true, color: true } } },
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
    totalAttendances > 0 ? Number(((presentAttendances / totalAttendances) * 100).toFixed(1)) : 100;

  return {
    totalCourses: courses.length,
    overallAttendanceRate,
    upcomingAssignmentsCount: upcomingAssignments.length,
    upcomingExamsCount: upcomingExams.length,
    upcomingAssignments,
    upcomingExams,
  };
};

// ==========================================
// 6. STUDY SESSIONS (UC-84 to UC-90)
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
  recordStudySession,
  getStudySessions,
  getAcademicSummary,
  recalculateCourseProgress,
};
