/**
 * Report Generator Engine
 * Compiles cross-domain analytics retrospectives into printable CSV and PDF streams.
 */

export interface MetricComparison {
  metric: string;
  current: number;
  previous: number;
  unit: string;
  deltaPercentage: number;
}

export interface CategorySpending {
  name: string;
  color: string;
  amount: number;
  percentage: number;
}

export interface CourseStudyTime {
  courseName: string;
  code?: string | null;
  color: string;
  hours: number;
  sessionsCount: number;
}

export interface StrengthProgressionPoint {
  exerciseName: string;
  weightKg: number;
  repetitions: number;
  oneRepMax: number;
  date: string;
}

export interface ProductivityTimeDistribution {
  morningHours: number;
  afternoonHours: number;
  eveningHours: number;
  nightHours: number;
  peakWindow: string;
}

export interface MultiDomainMetrics {
  study: {
    totalHours: number;
    sessionCount: number;
    byCourse: CourseStudyTime[];
  };
  coding: {
    totalCommits: number;
    currentStreak: number;
    leetcodeTotal: number;
    leetcodeEasy: number;
    leetcodeMedium: number;
    leetcodeHard: number;
  };
  finance: {
    totalIncome: number;
    totalExpense: number;
    netSavings: number;
    transactionCount: number;
    spendingByCategory: CategorySpending[];
  };
  gym: {
    workoutsCount: number;
    strengthProgression: StrengthProgressionPoint[];
  };
  productivity: ProductivityTimeDistribution;
}

export interface RetrospectiveReportData {
  period: 'WEEKLY' | 'MONTHLY';
  summary: {
    totalFocusHours: number;
    totalTrackedHours: number;
    completedTasksCount: number;
    workoutsCount: number;
    habitsCompletedCount: number;
  };
  comparison: MetricComparison[];
  dailyFocusHours: Record<string, number>;
  completedTasks: Array<{ id: string; title: string; priority: string }>;
  multiDomain: MultiDomainMetrics;
}

/**
 * Compiles a sanitized RFC 4180 CSV spreadsheet buffer with UTF-8 BOM.
 */
export const generateAnalyticsCsv = (data: RetrospectiveReportData): string => {
  const lines: string[] = [];
  const escape = (val: any) => `"${String(val ?? '').replace(/"/g, '""')}"`;
  const BOM = '\uFEFF';

  lines.push('HABOS PRODUCTIVITY & CROSS-DOMAIN RETROSPECTIVE REPORT');
  lines.push(`Period,${escape(data.period)},Generated At,${escape(new Date().toISOString())}`);
  lines.push('');

  // 1. Executive Summary
  lines.push('--- EXECUTIVE SUMMARY ---');
  lines.push('Metric,Value,Unit');
  lines.push(`Total Focus Hours,${data.summary.totalFocusHours},hours`);
  lines.push(`Total Tracked Time,${data.summary.totalTrackedHours},hours`);
  lines.push(`Tasks Completed,${data.summary.completedTasksCount},tasks`);
  lines.push(`Workouts Completed,${data.summary.workoutsCount},sessions`);
  lines.push(`Habits Logged,${data.summary.habitsCompletedCount},check-ins`);
  lines.push(`Academic Study Time,${data.multiDomain.study.totalHours},hours`);
  lines.push(`Peak Productivity Window,${escape(data.multiDomain.productivity.peakWindow)},time`);
  lines.push(`GitHub Total Commits,${data.multiDomain.coding.totalCommits},commits`);
  lines.push(`LeetCode Total Solved,${data.multiDomain.coding.leetcodeTotal},problems`);
  lines.push(`Net Financial Savings,$${data.multiDomain.finance.netSavings},USD`);
  lines.push('');

  // 2. Period Comparison & Variances
  lines.push('--- PERIOD COMPARISON & VARIANCES ---');
  lines.push('Metric,Current Period,Previous Period,Delta Percentage');
  for (const cmp of data.comparison) {
    const sign = cmp.deltaPercentage > 0 ? '+' : '';
    lines.push(
      `${escape(cmp.metric)},${cmp.current} ${cmp.unit},${cmp.previous} ${cmp.unit},${sign}${cmp.deltaPercentage}%`
    );
  }
  lines.push('');

  // 3. Financial Spending By Category (UC-151)
  lines.push('--- FINANCIAL SPENDING BY CATEGORY ---');
  lines.push('Category,Amount (USD),Share (%)');
  for (const cat of data.multiDomain.finance.spendingByCategory) {
    lines.push(`${escape(cat.name)},$${cat.amount},${cat.percentage}%`);
  }
  lines.push('');

  // 4. Academic Study Distribution By Course (UC-149)
  lines.push('--- STUDY TIME DISTRIBUTION BY COURSE ---');
  lines.push('Course,Code,Hours,Sessions');
  for (const crs of data.multiDomain.study.byCourse) {
    lines.push(`${escape(crs.courseName)},${escape(crs.code ?? '')},${crs.hours},${crs.sessionsCount}`);
  }
  lines.push('');

  // 5. Gym Strength Progression & 1RM PRs (UC-150)
  lines.push('--- GYM STRENGTH PR PROGRESSION ---');
  lines.push('Exercise,Weight (kg),Reps,Estimated 1RM (kg),Date');
  for (const pr of data.multiDomain.gym.strengthProgression) {
    lines.push(`${escape(pr.exerciseName)},${pr.weightKg},${pr.repetitions},${pr.oneRepMax},${pr.date}`);
  }
  lines.push('');

  // 6. Productivity Hourly Distribution (UC-147)
  lines.push('--- PRODUCTIVITY DIURNAL DISTRIBUTION ---');
  lines.push('Time Window,Focus Hours');
  lines.push(`Morning (06:00 - 12:00),${data.multiDomain.productivity.morningHours}`);
  lines.push(`Afternoon (12:00 - 18:00),${data.multiDomain.productivity.afternoonHours}`);
  lines.push(`Evening (18:00 - 24:00),${data.multiDomain.productivity.eveningHours}`);
  lines.push(`Night (00:00 - 06:00),${data.multiDomain.productivity.nightHours}`);
  lines.push('');

  // 7. Daily Focus Distribution
  lines.push('--- DAILY FOCUS DISTRIBUTION ---');
  lines.push('Date,Focus Hours');
  for (const [dateKey, hours] of Object.entries(data.dailyFocusHours)) {
    lines.push(`${dateKey},${hours}`);
  }
  lines.push('');

  // 8. Completed Tasks
  lines.push('--- COMPLETED TASKS ARCHIVE ---');
  lines.push('Task ID,Title,Priority');
  for (const task of data.completedTasks) {
    lines.push(`${escape(task.id)},${escape(task.title)},${escape(task.priority)}`);
  }

  return BOM + lines.join('\r\n');
};

/**
 * Compiles a standards-compliant PDF 1.4 document stream directly.
 */
export const generateAnalyticsPdf = (data: RetrospectiveReportData): Buffer => {
  const sanitize = (text: string) => text.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');

  const pdfLines: string[] = [];
  pdfLines.push('HABOS PRODUCTIVITY & RETROSPECTIVE SUMMARY');
  pdfLines.push(`Report Period: ${data.period}  |  Generated: ${new Date().toISOString().split('T')[0]}`);
  pdfLines.push('================================================================');
  pdfLines.push('');
  pdfLines.push('[ EXECUTIVE SUMMARY ]');
  pdfLines.push(`  * Total Focus Time:       ${data.summary.totalFocusHours.toFixed(1)} hrs (Peak: ${data.multiDomain.productivity.peakWindow})`);
  pdfLines.push(`  * Tasks Completed:        ${data.summary.completedTasksCount}`);
  pdfLines.push(`  * Workouts Done:          ${data.summary.workoutsCount} sessions`);
  pdfLines.push(`  * Habits Maintained:      ${data.summary.habitsCompletedCount} check-ins`);
  pdfLines.push(`  * Academic Study Time:    ${data.multiDomain.study.totalHours.toFixed(1)} hrs`);
  pdfLines.push(`  * GitHub Commits:         ${data.multiDomain.coding.totalCommits}`);
  pdfLines.push(`  * LeetCode Problems:      ${data.multiDomain.coding.leetcodeTotal} solved`);
  pdfLines.push(`  * Financial Net Savings:  $${data.multiDomain.finance.netSavings.toFixed(2)}`);
  pdfLines.push('');
  pdfLines.push('[ PERIOD-OVER-PERIOD PERFORMANCE VARIANCES ]');
  for (const cmp of data.comparison) {
    const sign = cmp.deltaPercentage > 0 ? '+' : '';
    pdfLines.push(
      `  * ${cmp.metric.padEnd(20)}: ${String(cmp.current).padStart(6)} ${cmp.unit.padEnd(3)} (Prev: ${String(cmp.previous).padStart(6)} | Var: ${sign}${cmp.deltaPercentage}%)`
    );
  }
  pdfLines.push('');
  pdfLines.push('[ DOMAIN TREND DETAILS ]');
  pdfLines.push(`  * Top Category Spending:  ${data.multiDomain.finance.spendingByCategory.map((c) => `${c.name}: $${c.amount}`).slice(0, 3).join(', ') || 'None'}`);
  pdfLines.push(`  * Top Course Study:       ${data.multiDomain.study.byCourse.map((c) => `${c.courseName}: ${c.hours}h`).slice(0, 3).join(', ') || 'None'}`);
  pdfLines.push(`  * Peak Gym 1RM Lifts:     ${data.multiDomain.gym.strengthProgression.map((p) => `${p.exerciseName}: ${p.oneRepMax}kg`).slice(0, 3).join(', ') || 'No PRs'}`);
  pdfLines.push('');
  pdfLines.push('[ COMPLETED TASKS IN THIS PERIOD ]');
  if (data.completedTasks.length === 0) {
    pdfLines.push('  (No completed tasks logged for this cycle)');
  } else {
    for (const t of data.completedTasks.slice(0, 15)) {
      pdfLines.push(`  [x] [${t.priority.padEnd(6)}] ${t.title}`);
    }
  }

  let streamContent = 'BT\n/F1 10 Tf\n20 TL\n50 780 Td\n';
  for (let i = 0; i < pdfLines.length; i++) {
    const line = sanitize(pdfLines[i]);
    if (i === 0) {
      streamContent += `/F1 16 Tf (${line}) Tj\n/F1 10 Tf\nT*\n`;
    } else if (line.startsWith('[')) {
      streamContent += `/F1 11 Tf (${line}) Tj\n/F1 10 Tf\nT*\n`;
    } else {
      streamContent += `(${line}) Tj\nT*\n`;
    }
  }
  streamContent += 'ET\n';

  const streamBytes = Buffer.from(streamContent, 'utf-8');
  const objects: string[] = [];
  objects.push('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
  objects.push('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');
  objects.push(
    '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n'
  );
  objects.push(`4 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n${streamContent}endstream\nendobj\n`);
  objects.push('5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>\nendobj\n');

  let output = '%PDF-1.4\n';
  const offsets: number[] = [];
  for (const obj of objects) {
    offsets.push(Buffer.byteLength(output, 'utf-8'));
    output += obj;
  }
  const xrefOffset = Buffer.byteLength(output, 'utf-8');
  output += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  for (const offset of offsets) {
    output += `${String(offset).padStart(10, '0')} 00000 n \n`;
  }
  output += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefOffset}\n%%EOF\n`;

  return Buffer.from(output, 'utf-8');
};

export default {
  generateAnalyticsCsv,
  generateAnalyticsPdf,
};
