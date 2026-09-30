import Joi from 'joi';

export const createCourseSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Course name is required',
    'any.required': 'Course name is required',
  }),
  code: Joi.string().trim().allow('', null),
  semester: Joi.string().trim().default('Fall 2026'),
  instructor: Joi.string().trim().allow('', null),
  credits: Joi.number().integer().min(1).max(10).default(3),
  progress: Joi.number().min(0).max(100).default(0.0),
  color: Joi.string().trim().default('#8B5CF6'),
});

export const updateCourseSchema = Joi.object({
  name: Joi.string().trim().min(1).max(255),
  code: Joi.string().trim().allow('', null),
  semester: Joi.string().trim(),
  instructor: Joi.string().trim().allow('', null),
  credits: Joi.number().integer().min(1).max(10),
  progress: Joi.number().min(0).max(100),
  color: Joi.string().trim(),
});

export const createAssignmentSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Assignment title is required',
    'any.required': 'Assignment title is required',
  }),
  description: Joi.string().trim().allow('', null),
  dueDate: Joi.date().iso().required().messages({
    'any.required': 'Due date is required',
  }),
  type: Joi.string().valid('HOMEWORK', 'ESSAY', 'PROJECT', 'LAB', 'QUIZ').default('HOMEWORK'),
  weight: Joi.number().min(0).max(100).default(10.0),
  status: Joi.string().valid('NOT_STARTED', 'IN_PROGRESS', 'SUBMITTED', 'GRADED').default('NOT_STARTED'),
  grade: Joi.number().min(0).allow(null),
  maxGrade: Joi.number().min(1).default(100.0),
});

export const updateAssignmentSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  description: Joi.string().trim().allow('', null),
  dueDate: Joi.date().iso(),
  type: Joi.string().valid('HOMEWORK', 'ESSAY', 'PROJECT', 'LAB', 'QUIZ'),
  weight: Joi.number().min(0).max(100).allow(null),
  status: Joi.string().valid('NOT_STARTED', 'IN_PROGRESS', 'SUBMITTED', 'GRADED'),
  grade: Joi.number().min(0).allow(null),
  maxGrade: Joi.number().min(1),
});

export const createExamSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255).required().messages({
    'string.empty': 'Exam title is required',
    'any.required': 'Exam title is required',
  }),
  examDate: Joi.date().iso().required().messages({
    'any.required': 'Exam date is required',
  }),
  startTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  examType: Joi.string().valid('MIDTERM', 'FINAL', 'QUIZ', 'ORAL').default('MIDTERM'),
  weight: Joi.number().min(0).max(100).allow(null),
  grade: Joi.number().min(0).allow(null),
  maxGrade: Joi.number().min(1).default(100.0),
});

export const updateExamSchema = Joi.object({
  title: Joi.string().trim().min(1).max(255),
  examDate: Joi.date().iso(),
  startTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).allow('', null),
  examType: Joi.string().valid('MIDTERM', 'FINAL', 'QUIZ', 'ORAL'),
  weight: Joi.number().min(0).max(100).allow(null),
  grade: Joi.number().min(0).allow(null),
  maxGrade: Joi.number().min(1),
});

export const recordAttendanceSchema = Joi.object({
  date: Joi.date().iso().default(() => new Date().toISOString().split('T')[0]),
  status: Joi.string().valid('PRESENT', 'ABSENT', 'LATE', 'EXCUSED').default('PRESENT'),
  notes: Joi.string().trim().allow('', null),
});

export const addClassScheduleSchema = Joi.object({
  dayOfWeek: Joi.number().integer().min(1).max(7).required().messages({
    'any.required': 'Day of week (1=Mon..7=Sun) is required',
  }),
  startTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).required().messages({
    'string.pattern.base': 'Start time must be HH:MM format (24h)',
    'any.required': 'Start time is required',
  }),
  endTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).required().messages({
    'string.pattern.base': 'End time must be HH:MM format (24h)',
    'any.required': 'End time is required',
  }),
  room: Joi.string().trim().allow('', null),
});

export const whatIfFinalGradeSchema = Joi.object({
  targetPercentage: Joi.number().min(0).max(100).required().messages({
    'any.required': 'Target percentage is required',
  }),
  finalExamWeight: Joi.number().min(1).max(100).default(30.0),
});

export const uuidParamSchema = Joi.object({
  id: Joi.string().uuid().required(),
});

export const courseAssignmentParamSchema = Joi.object({
  courseId: Joi.string().uuid().required(),
  assignmentId: Joi.string().uuid().required(),
});

export const courseExamParamSchema = Joi.object({
  courseId: Joi.string().uuid().required(),
  examId: Joi.string().uuid().required(),
});

export const courseScheduleParamSchema = Joi.object({
  courseId: Joi.string().uuid().required(),
  scheduleId: Joi.string().uuid().required(),
});
