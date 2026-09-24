import { Router } from 'express';
import * as coursesController from './courses.controller';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createCourseSchema,
  updateCourseSchema,
  createAssignmentSchema,
  updateAssignmentSchema,
  createExamSchema,
  updateExamSchema,
  recordAttendanceSchema,
  uuidParamSchema,
  courseAssignmentParamSchema,
  courseExamParamSchema,
} from './courses.validation';

const router = Router();

// All courses routes require authentication
router.use(authenticate);

// --- Academic Overview (UC-77, UC-79, UC-81) ---
router.get('/summary', coursesController.getAcademicSummary);

// --- Courses (UC-70 to UC-74) ---
router.post('/', validate(createCourseSchema), coursesController.createCourse);
router.get('/', coursesController.getCourses);
router.get('/:id', validate(uuidParamSchema, 'params'), coursesController.getCourseById);
router.put(
  '/:id',
  validate(uuidParamSchema, 'params'),
  validate(updateCourseSchema),
  coursesController.updateCourse
);
router.delete('/:id', validate(uuidParamSchema, 'params'), coursesController.deleteCourse);

// --- Assignments (UC-75 to UC-77) ---
router.post(
  '/:courseId/assignments',
  validate(createAssignmentSchema),
  coursesController.createAssignment
);
router.put(
  '/:courseId/assignments/:assignmentId',
  validate(courseAssignmentParamSchema, 'params'),
  validate(updateAssignmentSchema),
  coursesController.updateAssignment
);
router.delete(
  '/:courseId/assignments/:assignmentId',
  validate(courseAssignmentParamSchema, 'params'),
  coursesController.deleteAssignment
);

// --- Exams (UC-78 to UC-80) ---
router.post(
  '/:courseId/exams',
  validate(createExamSchema),
  coursesController.createExam
);
router.put(
  '/:courseId/exams/:examId',
  validate(courseExamParamSchema, 'params'),
  validate(updateExamSchema),
  coursesController.updateExam
);
router.delete(
  '/:courseId/exams/:examId',
  validate(courseExamParamSchema, 'params'),
  coursesController.deleteExam
);

// --- Attendance (UC-82 to UC-83) ---
router.post(
  '/:courseId/attendance',
  validate(recordAttendanceSchema),
  coursesController.recordAttendance
);

// --- Study Sessions (UC-84 to UC-90) ---
router.post('/:courseId/study', coursesController.recordStudySession);
router.get('/:courseId/study', coursesController.getStudySessions);

export default router;
