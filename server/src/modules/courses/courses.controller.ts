import { Request, Response } from 'express';
import coursesService from './courses.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

// --- COURSES ---

export const createCourse = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const course = await coursesService.createCourse(authReq.user!.id, req.body);
  return ApiResponse.success(res, course, 'Course created successfully', 201);
});

export const getCourses = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { semester } = req.query;
  const courses = await coursesService.getCourses(authReq.user!.id, semester as string);
  return ApiResponse.success(res, courses, 'Courses retrieved successfully');
});

export const getAcademicSummary = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const summary = await coursesService.getAcademicSummary(authReq.user!.id);
  return ApiResponse.success(res, summary, 'Academic summary retrieved successfully');
});

export const getCourseById = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const course = await coursesService.getCourseById(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, course, 'Course details retrieved successfully');
});

export const updateCourse = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const course = await coursesService.updateCourse(authReq.user!.id, req.params.id, req.body);
  return ApiResponse.success(res, course, 'Course updated successfully');
});

export const deleteCourse = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await coursesService.deleteCourse(authReq.user!.id, req.params.id);
  return ApiResponse.success(res, result, 'Course deleted successfully');
});

// --- ASSIGNMENTS ---

export const createAssignment = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const assignment = await coursesService.createAssignment(authReq.user!.id, req.params.courseId, req.body);
  return ApiResponse.success(res, assignment, 'Assignment created successfully', 201);
});

export const updateAssignment = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const assignment = await coursesService.updateAssignment(
    authReq.user!.id,
    req.params.courseId,
    req.params.assignmentId,
    req.body
  );
  return ApiResponse.success(res, assignment, 'Assignment updated successfully');
});

export const deleteAssignment = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await coursesService.deleteAssignment(
    authReq.user!.id,
    req.params.courseId,
    req.params.assignmentId
  );
  return ApiResponse.success(res, result, 'Assignment deleted successfully');
});

// --- EXAMS ---

export const createExam = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const exam = await coursesService.createExam(authReq.user!.id, req.params.courseId, req.body);
  return ApiResponse.success(res, exam, 'Exam created successfully', 201);
});

export const updateExam = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const exam = await coursesService.updateExam(
    authReq.user!.id,
    req.params.courseId,
    req.params.examId,
    req.body
  );
  return ApiResponse.success(res, exam, 'Exam updated successfully');
});

export const deleteExam = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const result = await coursesService.deleteExam(
    authReq.user!.id,
    req.params.courseId,
    req.params.examId
  );
  return ApiResponse.success(res, result, 'Exam deleted successfully');
});

// --- ATTENDANCE ---

export const recordAttendance = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const attendance = await coursesService.recordAttendance(authReq.user!.id, req.params.courseId, req.body);
  return ApiResponse.success(res, attendance, 'Attendance recorded successfully');
});

// --- STUDY SESSIONS ---

export const recordStudySession = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const session = await coursesService.recordStudySession(
    authReq.user!.id,
    req.params.courseId,
    req.body
  );
  return ApiResponse.success(res, session, 'Study session recorded successfully', 201);
});

export const getStudySessions = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const sessions = await coursesService.getStudySessions(authReq.user!.id, req.params.courseId);
  return ApiResponse.success(res, sessions, 'Study sessions retrieved successfully');
});

export default {
  createCourse,
  getCourses,
  getAcademicSummary,
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
};
