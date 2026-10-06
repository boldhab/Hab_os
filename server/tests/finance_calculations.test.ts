import { Prisma } from '@prisma/client';
import { decimalToNumber } from '../src/modules/finance/finance.service';

function assert(condition: boolean, message: string) {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

async function runFinanceCalculationUnitTests() {
  console.log('🧪 Starting Finance Calculations & Precision Unit Test Suite...\n');

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
  // 1. DECIMAL PRECISION & MONEY SERIALIZATION
  // ============================================================
  console.log('--- 1. Decimal Precision & Normalization ---');

  test('0.10 + 0.20 sums precisely to 0.30 without floating-point drift', () => {
    const d1 = new Prisma.Decimal('0.10');
    const d2 = new Prisma.Decimal('0.20');
    const sum = d1.plus(d2);

    assert(sum.toString() === '0.3', 'Prisma Decimal sum is exact');
    assert(decimalToNumber(sum) === 0.3, 'Normalized number representation is 0.30');
  });

  test('Fractional cents are properly converted with 2-decimal rounding', () => {
    const d = new Prisma.Decimal('49.999');
    assert(decimalToNumber(d) === 50.0, 'Rounds to 2 decimal places');

    const d2 = new Prisma.Decimal('19.994');
    assert(decimalToNumber(d2) === 19.99, 'Truncates sub-cent beyond 2 decimals');
  });

  test('Null, undefined and numeric inputs are safely converted', () => {
    assert(decimalToNumber(null) === 0, 'null maps to 0');
    assert(decimalToNumber(undefined) === 0, 'undefined maps to 0');
    assert(decimalToNumber(125.5) === 125.5, 'number passes through');
  });

  // ============================================================
  // 2. BUDGET CALCULATION THRESHOLDS & BOUNDARIES
  // ============================================================
  console.log('\n--- 2. Budget Utilization Boundaries & State Logic ---');

  function calculateBudgetState(monthlyLimitVal: number, spentVal: number) {
    const spentDecimal = new Prisma.Decimal(spentVal);
    const monthlyLimitDecimal = new Prisma.Decimal(monthlyLimitVal);

    const spent = decimalToNumber(spentDecimal);
    const monthlyLimit = decimalToNumber(monthlyLimitDecimal);

    const percentageUsed = monthlyLimit > 0
      ? Number(spentDecimal.dividedBy(monthlyLimitDecimal).times(100).toFixed(1))
      : 0;

    const isExceeded = spentDecimal.greaterThan(monthlyLimitDecimal);
    const isWarning = percentageUsed >= 80 && !isExceeded;
    const remainingDecimal = spentDecimal.greaterThan(monthlyLimitDecimal)
      ? new Prisma.Decimal(0)
      : monthlyLimitDecimal.minus(spentDecimal);
    const remaining = decimalToNumber(remainingDecimal);

    return {
      monthlyLimit,
      spent,
      remaining,
      percentageUsed,
      isWarning,
      isExceeded,
    };
  }

  test('Budget at 79.9% usage is neither warning nor exceeded', () => {
    const res = calculateBudgetState(1000, 799);
    assert(res.percentageUsed === 79.9, 'Percentage used is 79.9%');
    assert(res.isWarning === false, 'isWarning must be false below 80%');
    assert(res.isExceeded === false, 'isExceeded must be false');
    assert(res.remaining === 201, 'Remaining is 201');
  });

  test('Budget at exactly 80.0% usage triggers isWarning = true', () => {
    const res = calculateBudgetState(1000, 800);
    assert(res.percentageUsed === 80.0, 'Percentage used is 80.0%');
    assert(res.isWarning === true, 'isWarning must be true at exactly 80%');
    assert(res.isExceeded === false, 'isExceeded must be false at 80%');
    assert(res.remaining === 200, 'Remaining is 200');
  });

  test('Budget at 99.9% usage retains isWarning = true', () => {
    const res = calculateBudgetState(1000, 999);
    assert(res.percentageUsed === 99.9, 'Percentage used is 99.9%');
    assert(res.isWarning === true, 'isWarning is true');
    assert(res.isExceeded === false, 'isExceeded is false');
    assert(res.remaining === 1, 'Remaining is 1');
  });

  test('Budget at exactly 100.0% usage (at limit) has isWarning = true and isExceeded = false', () => {
    const res = calculateBudgetState(1000, 1000);
    assert(res.percentageUsed === 100.0, 'Percentage used is 100%');
    assert(res.isWarning === true, 'isWarning is true');
    assert(res.isExceeded === false, 'isExceeded is false when exactly equal');
    assert(res.remaining === 0, 'Remaining is 0');
  });

  test('Budget at 100.1% usage (over limit) sets isExceeded = true and isWarning = false', () => {
    const res = calculateBudgetState(1000, 1001);
    assert(res.percentageUsed === 100.1, 'Percentage used is 100.1%');
    assert(res.isWarning === false, 'isWarning is false once exceeded');
    assert(res.isExceeded === true, 'isExceeded is true');
    assert(res.remaining === 0, 'Remaining clamped to 0');
  });

  // ============================================================
  // 3. SAVINGS RATE & FINANCIAL ANALYTICS
  // ============================================================
  console.log('\n--- 3. Financial Analytics & Savings Rate ---');

  function calculateAnalytics(incomeVal: number, expenseVal: number) {
    const totalIncomeDecimal = new Prisma.Decimal(incomeVal);
    const totalExpensesDecimal = new Prisma.Decimal(expenseVal);
    const netSavingsDecimal = totalIncomeDecimal.minus(totalExpensesDecimal);

    const totalIncome = decimalToNumber(totalIncomeDecimal);
    const totalExpenses = decimalToNumber(totalExpensesDecimal);
    const netSavings = decimalToNumber(netSavingsDecimal);

    const savingsRate = totalIncomeDecimal.greaterThan(0)
      ? Number(netSavingsDecimal.dividedBy(totalIncomeDecimal).times(100).toFixed(1))
      : 0;

    return { totalIncome, totalExpenses, netSavings, savingsRate };
  }

  test('Calculates positive savings rate correctly (5000 income, 2000 expense = 60.0% savings)', () => {
    const res = calculateAnalytics(5000, 2000);
    assert(res.totalIncome === 5000, 'Income is 5000');
    assert(res.totalExpenses === 2000, 'Expense is 2000');
    assert(res.netSavings === 3000, 'Net savings is 3000');
    assert(res.savingsRate === 60.0, 'Savings rate is 60.0%');
  });

  test('Calculates negative savings rate (deficit) when expenses exceed income', () => {
    const res = calculateAnalytics(2000, 3000);
    assert(res.netSavings === -1000, 'Net savings is -1000');
    assert(res.savingsRate === -50.0, 'Savings rate is -50.0%');
  });

  test('Zero income results in 0% savings rate without division by zero errors', () => {
    const res = calculateAnalytics(0, 500);
    assert(res.netSavings === -500, 'Net savings is -500');
    assert(res.savingsRate === 0, 'Savings rate is 0 when income is 0');
  });

  console.log(`\n========================================`);
  console.log(`Finance Calculation Tests: ${passed}/${total} passed`);
  console.log(`========================================\n`);
}

runFinanceCalculationUnitTests();
