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
  addClassScheduleSchema,
  whatIfFinalGradeSchema,
  uuidParamSchema,
  courseIdParamSchema,
  courseAssignmentParamSchema,
  courseExamParamSchema,
  courseScheduleParamSchema,
  recordStudySessionSchema,
  academicSummaryQuerySchema,
} from './courses.validation';

const router = Router();

// All courses routes require authentication
router.use(authenticate);

// --- Academic Overview & GPA Engine ---
router.get('/summary', validate(academicSummaryQuerySchema, 'query'), coursesController.getAcademicSummary);
router.get('/gpa', validate(academicSummaryQuerySchema, 'query'), coursesController.getGpaOverview);
router.get('/schedules', coursesController.getClassSchedules);

// --- Courses CRUD ---
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

// --- Assignments ---
router.post(
  '/:courseId/assignments',
  validate(courseIdParamSchema, 'params'),
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

// --- Exams ---
router.post(
  '/:courseId/exams',
  validate(courseIdParamSchema, 'params'),
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

// --- Attendance ---
router.post(
  '/:courseId/attendance',
  validate(courseIdParamSchema, 'params'),
  validate(recordAttendanceSchema),
  coursesController.recordAttendance
);

// --- Class Schedules (Weekly Timetable) ---
router.get('/:courseId/schedules', validate(courseIdParamSchema, 'params'), coursesController.getClassSchedules);
router.post(
  '/:courseId/schedules',
  validate(courseIdParamSchema, 'params'),
  validate(addClassScheduleSchema),
  coursesController.addClassSchedule
);
router.delete(
  '/:courseId/schedules/:scheduleId',
  validate(courseScheduleParamSchema, 'params'),
  coursesController.deleteClassSchedule
);

// --- What-If Final Exam Calculator ---
router.post(
  '/:courseId/what-if',
  validate(courseIdParamSchema, 'params'),
  validate(whatIfFinalGradeSchema),
  coursesController.calculateWhatIfFinalGrade
);

// --- Study Sessions ---
router.post(
  '/:courseId/study',
  validate(courseIdParamSchema, 'params'),
  validate(recordStudySessionSchema),
  coursesController.recordStudySession
);
router.get('/:courseId/study', validate(courseIdParamSchema, 'params'), coursesController.getStudySessions);

export default router;
