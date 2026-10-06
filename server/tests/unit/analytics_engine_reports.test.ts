import { generateAnalyticsCsv, generateAnalyticsPdf, RetrospectiveReportData } from '../../src/modules/analytics/engines/report_generator';

function runReportGeneratorTests() {
  console.log('🧪 Testing Analytics Report Generator (CSV & PDF binary compilation with Domain Trends)...');

  const mockReport: RetrospectiveReportData = {
    period: 'WEEKLY',
    summary: {
      totalFocusHours: 18.5,
      totalTrackedHours: 20.0,
      completedTasksCount: 14,
      workoutsCount: 4,
      habitsCompletedCount: 28,
    },
    comparison: [
      { metric: 'Focus Time', current: 18.5, previous: 14.0, unit: 'hrs', deltaPercentage: 32.1 },
      { metric: 'Workouts', current: 4, previous: 3, unit: 'sessions', deltaPercentage: 33.3 },
      { metric: 'Net Savings', current: 450.0, previous: 300.0, unit: '$', deltaPercentage: 50.0 },
    ],
    dailyFocusHours: {
      '2026-09-28': 2.5,
      '2026-09-29': 3.0,
      '2026-09-30': 4.0,
      '2026-10-01': 1.5,
      '2026-10-02': 2.5,
      '2026-10-03': 3.0,
      '2026-10-04': 2.0,
    },
    completedTasks: [
      { id: 't1', title: 'Implement PDF/CSV Compiler', priority: 'HIGH' },
      { id: 't2', title: 'Complete Time Tracker UI', priority: 'URGENT' },
    ],
    multiDomain: {
      study: {
        totalHours: 12.0,
        sessionCount: 5,
        byCourse: [
          { courseName: 'Operating Systems', code: 'CS-601', color: '#8B5CF6', hours: 7.5, sessionsCount: 3 },
          { courseName: 'Distributed Systems', code: 'CS-602', color: '#3B82F6', hours: 4.5, sessionsCount: 2 },
        ],
      },
      coding: {
        totalCommits: 45,
        currentStreak: 12,
        leetcodeTotal: 150,
        leetcodeEasy: 50,
        leetcodeMedium: 80,
        leetcodeHard: 20,
      },
      finance: {
        totalIncome: 3500.0,
        totalExpense: 1200.0,
        netSavings: 2300.0,
        transactionCount: 8,
        spendingByCategory: [
          { name: 'Housing', color: '#EF4444', amount: 800.0, percentage: 66.7 },
          { name: 'Food', color: '#F59E0B', amount: 300.0, percentage: 25.0 },
          { name: 'Gym', color: '#10B981', amount: 100.0, percentage: 8.3 },
        ],
      },
      gym: {
        workoutsCount: 4,
        strengthProgression: [
          { exerciseName: 'Barbell Bench Press', weightKg: 100, repetitions: 5, oneRepMax: 112.5, date: '2026-09-30' },
          { exerciseName: 'Barbell Squat', weightKg: 140, repetitions: 3, oneRepMax: 150.0, date: '2026-10-02' },
        ],
      },
      productivity: {
        morningHours: 8.0,
        afternoonHours: 6.5,
        eveningHours: 3.5,
        nightHours: 0.5,
        peakWindow: 'Morning (6 AM - 12 PM)',
      },
    },
  };

  // 1. Test CSV Output
  const csv = generateAnalyticsCsv(mockReport);
  if (!csv.startsWith('\uFEFF')) throw new Error('CSV missing UTF-8 BOM');
  if (!csv.includes('FINANCIAL SPENDING BY CATEGORY')) throw new Error('CSV missing Category Spending section');
  if (!csv.includes('STUDY TIME DISTRIBUTION BY COURSE')) throw new Error('CSV missing Course Study section');
  if (!csv.includes('GYM STRENGTH PR PROGRESSION')) throw new Error('CSV missing Gym PR section');
  console.log('  ✅ PASS: CSV generated with UTF-8 BOM and deep multi-domain trend sections.');

  // 2. Test PDF Binary Output
  const pdfBuffer = generateAnalyticsPdf(mockReport);
  if (!Buffer.isBuffer(pdfBuffer)) throw new Error('PDF output is not a Buffer');
  const pdfHeader = pdfBuffer.slice(0, 8).toString('utf-8');
  if (!pdfHeader.startsWith('%PDF-1.4')) throw new Error(`Invalid PDF header: ${pdfHeader}`);
  console.log(`  ✅ PASS: PDF binary synthesized successfully (${pdfBuffer.length} bytes, valid PDF-1.4).`);

  console.log('\n🎉 ALL REPORT GENERATOR UNIT TESTS PASSED!');
}

runReportGeneratorTests();
