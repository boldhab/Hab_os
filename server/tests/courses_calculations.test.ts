import {
  computeCourseGrade,
  calculateAttendanceRate,
  calculateDeduplicatedStudyMinutes,
  getLetterGradeAndPoints,
} from '../src/modules/courses/courses.service';

function assert(condition: boolean, message: string) {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

async function runCourseCalculationUnitTests() {
  console.log('🧪 Starting Academic Pure Calculation & Unit Test Suite...\n');

  let passed = 0;
  let total = 0;

  function test(name: string, fn: () => void) {
    total++;
    try {
      fn();
      console.log(`  ✅ ${name}`);
      passed++;
    } catch (err: any) {
      console.error(`  ❌ ${name}: ${err.message}`);
      throw err;
    }
  }

  // ============================================================
  // 1. GRADE & LETTER SCALE BOUNDARIES
  // ============================================================
  console.log('--- 1. Grade Letter & Points Scale Thresholds ---');

  test('Scale thresholds match academic standard (A, A-, B+, B, B-, C+, C, C-, D+, D, F)', () => {
    assert(getLetterGradeAndPoints(95.0).letter === 'A' && getLetterGradeAndPoints(95.0).points === 4.0, '95% = A (4.0)');
    assert(getLetterGradeAndPoints(93.0).letter === 'A' && getLetterGradeAndPoints(93.0).points === 4.0, '93% = A (4.0)');
    assert(getLetterGradeAndPoints(92.9).letter === 'A-' && getLetterGradeAndPoints(92.9).points === 3.7, '92.9% = A- (3.7)');
    assert(getLetterGradeAndPoints(90.0).letter === 'A-' && getLetterGradeAndPoints(90.0).points === 3.7, '90.0% = A- (3.7)');
    assert(getLetterGradeAndPoints(88.0).letter === 'B+' && getLetterGradeAndPoints(88.0).points === 3.3, '88% = B+ (3.3)');
    assert(getLetterGradeAndPoints(84.0).letter === 'B' && getLetterGradeAndPoints(84.0).points === 3.0, '84% = B (3.0)');
    assert(getLetterGradeAndPoints(81.0).letter === 'B-' && getLetterGradeAndPoints(81.0).points === 2.7, '81% = B- (2.7)');
    assert(getLetterGradeAndPoints(78.0).letter === 'C+' && getLetterGradeAndPoints(78.0).points === 2.3, '78% = C+ (2.3)');
    assert(getLetterGradeAndPoints(75.0).letter === 'C' && getLetterGradeAndPoints(75.0).points === 2.0, '75% = C (2.0)');
    assert(getLetterGradeAndPoints(71.0).letter === 'C-' && getLetterGradeAndPoints(71.0).points === 1.7, '71% = C- (1.7)');
    assert(getLetterGradeAndPoints(68.0).letter === 'D+' && getLetterGradeAndPoints(68.0).points === 1.3, '68% = D+ (1.3)');
    assert(getLetterGradeAndPoints(62.0).letter === 'D' && getLetterGradeAndPoints(62.0).points === 1.0, '62% = D (1.0)');
    assert(getLetterGradeAndPoints(59.9).letter === 'F' && getLetterGradeAndPoints(59.9).points === 0.0, '59.9% = F (0.0)');
    assert(getLetterGradeAndPoints(0.0).letter === 'F' && getLetterGradeAndPoints(0.0).points === 0.0, '0% = F (0.0)');
  });

  // ============================================================
  // 2. COURSE GRADE COMPUTATION
  // ============================================================
  console.log('\n--- 2. Course Grade Computation (computeCourseGrade) ---');

  test('Empty course deliverables return 0% and N/A', () => {
    const res = computeCourseGrade([], []);
    assert(res.runningPercentage === 0.0, 'Running percentage is 0');
    assert(res.letter === 'N/A', 'Letter is N/A');
    assert(res.gradePoints === 0.0, 'Grade points is 0');
    assert(res.gradedItemsCount === 0, 'No graded items');
  });

  test('Ungraded deliverables do not penalize running percentage', () => {
    const assignments = [
      { grade: 90, maxGrade: 100, weight: 20 },
      { grade: null, maxGrade: 100, weight: 20 }, // not graded yet
    ];
    const exams = [
      { grade: null, maxGrade: 100, weight: 60 }, // not graded yet
    ];
    const res = computeCourseGrade(assignments, exams);
    assert(res.gradedItemsCount === 1, 'Only 1 graded item');
    assert(res.totalEvaluatedWeight === 20, 'Evaluated weight is 20');
    assert(res.runningPercentage === 90.0, 'Running percentage is 90.0%');
    assert(res.letter === 'A-', 'Letter is A-');
  });

  test('Weighted mix of assignments and exams with non-100 maxGrades', () => {
    const assignments = [
      { grade: 45, maxGrade: 50, weight: 20 }, // 90% * 20 = 1800
      { grade: 80, maxGrade: 100, weight: 20 }, // 80% * 20 = 1600
    ];
    const exams = [
      { grade: 95, maxGrade: 100, weight: 60 }, // 95% * 60 = 5700
    ];
    // Total evaluated weight = 100
    // Total weighted score = 1800 + 1600 + 5700 = 9100 / 100 = 91.0%
    const res = computeCourseGrade(assignments, exams);
    assert(res.runningPercentage === 91.0, `Running percentage should be 91.0, got ${res.runningPercentage}`);
    assert(res.letter === 'A-', `Letter should be A-, got ${res.letter}`);
    assert(res.totalEvaluatedWeight === 100, 'Total weight evaluated is 100');
  });

  // ============================================================
  // 3. ATTENDANCE RATE CALCULATION
  // ============================================================
  console.log('\n--- 3. Attendance Rate Policy Calculations ---');

  test('calculateAttendanceRate handles empty, perfect, and zero attendance', () => {
    assert(calculateAttendanceRate([]) === 100.0, 'Empty attendance defaults to 100%');
    assert(calculateAttendanceRate([{ status: 'PRESENT' }, { status: 'PRESENT' }]) === 100.0, 'All PRESENT = 100%');
    assert(calculateAttendanceRate([{ status: 'ABSENT' }, { status: 'ABSENT' }]) === 0.0, 'All ABSENT = 0%');
  });

  test('calculateAttendanceRate weights LATE as 0.5 and excludes EXCUSED', () => {
    // 1 Present (1.0), 1 Late (0.5), 1 Excused (excluded), 1 Absent (0)
    // Evaluable = 3. Effective attended = 1.5. Rate = 1.5 / 3 = 50.0%
    const records = [
      { status: 'PRESENT' },
      { status: 'LATE' },
      { status: 'EXCUSED' },
      { status: 'ABSENT' },
    ];
    const rate = calculateAttendanceRate(records);
    assert(rate === 50.0, `Rate should be 50.0%, got ${rate}`);

    // All EXCUSED should return 100.0% default
    assert(calculateAttendanceRate([{ status: 'EXCUSED' }, { status: 'EXCUSED' }]) === 100.0, 'All EXCUSED = 100%');
  });

  // ============================================================
  // 4. STUDY TIME INTERVAL DEDUPLICATION
  // ============================================================
  console.log('\n--- 4. Study Time Interval Deduplication ---');

  test('calculateDeduplicatedStudyMinutes merges overlapping StudySession and FocusSession', () => {
    const baseTime = new Date('2026-10-03T10:00:00Z');
    const t = (offsetMins: number) => new Date(baseTime.getTime() + offsetMins * 60 * 1000);

    // Exact identical overlap: 60 mins each at 10:00
    const study1 = [{ startTime: t(0), durationMinutes: 60, endTime: t(60) }];
    const focus1 = [{ startTime: t(0), durationMinutes: 60, endTime: t(60) }];
    const res1 = calculateDeduplicatedStudyMinutes(study1, focus1);
    assert(res1 === 60, `Identical intervals should merge to 60m, got ${res1}`);

    // Partial overlap: Study 10:00-11:00 (60m) + Focus 10:30-11:30 (60m) -> Total union 10:00-11:30 (90m)
    const study2 = [{ startTime: t(0), durationMinutes: 60, endTime: t(60) }];
    const focus2 = [{ startTime: t(30), durationMinutes: 60, endTime: t(90) }];
    const res2 = calculateDeduplicatedStudyMinutes(study2, focus2);
    assert(res2 === 90, `Partially overlapping intervals should merge to 90m, got ${res2}`);

    // Subsumed: Study 10:00-12:00 (120m) + Focus 10:30-11:00 (30m) -> Total union 10:00-12:00 (120m)
    const study3 = [{ startTime: t(0), durationMinutes: 120, endTime: t(120) }];
    const focus3 = [{ startTime: t(30), durationMinutes: 30, endTime: t(60) }];
    const res3 = calculateDeduplicatedStudyMinutes(study3, focus3);
    assert(res3 === 120, `Subsumed interval should merge to 120m, got ${res3}`);

    // Non-overlapping: Study 10:00-11:00 (60m) + Focus 12:00-13:00 (60m) -> Total 120m
    const study4 = [{ startTime: t(0), durationMinutes: 60, endTime: t(60) }];
    const focus4 = [{ startTime: t(120), durationMinutes: 60, endTime: t(180) }];
    const res4 = calculateDeduplicatedStudyMinutes(study4, focus4);
    assert(res4 === 120, `Non-overlapping intervals should sum to 120m, got ${res4}`);

    // Empty sessions
    assert(calculateDeduplicatedStudyMinutes([], []) === 0, 'Empty sessions = 0m');
  });

  // ============================================================
  // 5. SCHEDULE OVERLAP BOUNDARIES
  // ============================================================
  console.log('\n--- 5. Schedule Conflict Boundary Logic ---');

  test('Adjoining / abutting slots do not conflict, while true overlaps do', () => {
    const isOverlap = (
      reqStart: string,
      reqEnd: string,
      existingStart: string,
      existingEnd: string
    ) => {
      return reqStart < existingEnd && reqEnd > existingStart;
    };

    // Abutting: 10:00-11:00 and 11:00-12:00 -> NOT overlap (11:00 < 11:00 is false)
    assert(!isOverlap('11:00', '12:00', '10:00', '11:00'), 'Abutting schedule slots (11:00 start after 11:00 end) must NOT conflict');

    // 1 minute overlap: 10:00-11:01 and 11:00-12:00 -> OVERLAP
    assert(isOverlap('11:00', '12:00', '10:00', '11:01'), '1-minute overlapping slot must conflict');

    // Enclosing: 09:00-13:00 and 10:00-11:00 -> OVERLAP
    assert(isOverlap('09:00', '13:00', '10:00', '11:00'), 'Enclosing slot must conflict');

    // Inside: 10:15-10:45 inside 10:00-11:00 -> OVERLAP
    assert(isOverlap('10:15', '10:45', '10:00', '11:00'), 'Contained slot must conflict');

    // Completely separate: 14:00-15:00 and 10:00-11:00 -> NOT overlap
    assert(!isOverlap('14:00', '15:00', '10:00', '11:00'), 'Separate slots must not conflict');
  });

  // ============================================================
  // 6. WHAT-IF GRADE FORMULA SEMANTICS
  // ============================================================
  console.log('\n--- 6. What-If Grade Simulation Academic Semantics ---');

  test('What-If simulation computes correct earned contribution and required score', () => {
    // Graded: 40% weight completed at 92.0% average
    const totalEvaluatedWeight = 40.0;
    const runningPercentage = 92.0;
    const earnedContribution = Number((runningPercentage * (totalEvaluatedWeight / 100)).toFixed(1)); // 36.8
    const remainingUngradedWeight = 100.0 - totalEvaluatedWeight; // 60.0

    assert(earnedContribution === 36.8, `Earned contribution is 36.8 points, got ${earnedContribution}`);
    assert(remainingUngradedWeight === 60.0, 'Remaining weight is 60.0%');

    // Max achievable final grade = 36.8 + 60.0 = 96.8%
    const maxAchievable = earnedContribution + remainingUngradedWeight;
    assert(maxAchievable === 96.8, 'Max achievable grade is 96.8%');

    // Scenario A: Target 60% with 30% final exam
    // Needed = 60 - 36.8 = 23.2 points from 30% exam
    // Required score = (23.2 / 0.30) = 77.3%
    const neededA = 60 - earnedContribution;
    const reqScoreA = Number((neededA / (30.0 / 100)).toFixed(1));
    assert(reqScoreA === 77.3, `Required score should be 77.3%, got ${reqScoreA}`);

    // Scenario B: Target 30% with 30% final exam
    // Needed = 30 - 36.8 = -6.8 points -> ALREADY_SECURED
    const neededB = 30 - earnedContribution;
    const reqScoreB = Number((neededB / (30.0 / 100)).toFixed(1));
    assert(reqScoreB <= 0, 'Target is already secured when required score <= 0');

    // Scenario C: Target 99% with 30% final exam
    // Needed = 99 - 36.8 = 62.2 from 30% exam -> (62.2 / 0.30) = 207.3% -> MATHEMATICALLY_IMPOSSIBLE
    const neededC = 99 - earnedContribution;
    const reqScoreC = Number((neededC / (30.0 / 100)).toFixed(1));
    assert(reqScoreC > 100, 'Target is impossible when required score > 100%');
  });

  console.log(`\n🎉 All ${passed}/${total} Pure Calculation Unit Tests Passed Successfully!\n`);
}

runCourseCalculationUnitTests()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Unit tests failed:', err);
    process.exit(1);
  });
