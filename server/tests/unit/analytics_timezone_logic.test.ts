import { getLocalDateKey, getLocalStartOfDay } from '../../src/modules/analytics/analytics.service';

function runAnalyticsTimezoneTests() {
  console.log('🧪 Running Analytics Service Timezone Logic Unit Tests...');
  let passed = 0;
  let total = 0;

  function assert(condition: boolean, testName: string) {
    total++;
    if (condition) {
      console.log(`  ✅ PASS: ${testName}`);
      passed++;
    } else {
      console.error(`  ❌ FAIL: ${testName}`);
      throw new Error(`Test failed: ${testName}`);
    }
  }

  // Test 1: getLocalDateKey converts UTC time to UTC+3 (Cairo/Kuwait)
  const lateNightUtc = new Date('2026-10-03T22:30:00.000Z');
  const utcKey = getLocalDateKey(lateNightUtc, 'UTC');
  const cairoKey = getLocalDateKey(lateNightUtc, 'Africa/Cairo'); // 22:30 UTC = 01:30 next day in Cairo (+3)
  assert(utcKey === '2026-10-03', 'Late night UTC resolves to 2026-10-03 in UTC');
  assert(cairoKey === '2026-10-04', 'Late night UTC resolves to 2026-10-04 in Cairo (UTC+3)');

  // Test 2: getLocalDateKey converts early morning UTC to UTC-4 (New York)
  const earlyMorningUtc = new Date('2026-10-04T02:00:00.000Z');
  const nyKey = getLocalDateKey(earlyMorningUtc, 'America/New_York'); // 02:00 UTC Oct 4 = 22:00 Oct 3 in NY
  assert(nyKey === '2026-10-03', 'Early morning UTC resolves to 2026-10-03 in America/New_York');

  // Test 3: getLocalStartOfDay computes true local midnight (00:00:00.000 local)
  const refDate = new Date('2026-10-04T15:00:00.000Z');
  const midnightNy = getLocalStartOfDay(refDate, 0, 'America/New_York');
  // Oct 4 midnight in NY (UTC-4) is 04:00:00 UTC
  assert(midnightNy.toISOString() === '2026-10-04T04:00:00.000Z', 'Midnight in America/New_York is 04:00:00 UTC');

  // Test 4: getLocalStartOfDay for 6 days ago (lower query boundary)
  const start6DaysAgoNy = getLocalStartOfDay(refDate, 6, 'America/New_York');
  assert(start6DaysAgoNy.toISOString() === '2026-09-28T04:00:00.000Z', '6 days ago midnight in NY is 2026-09-28 04:00:00 UTC');
  assert(getLocalDateKey(start6DaysAgoNy, 'America/New_York') === '2026-09-28', 'Local date key matches 2026-09-28');

  // Test 5: Graceful fallback on invalid timezone
  const fallbackKey = getLocalDateKey(refDate, 'Invalid/Timezone_Name');
  assert(fallbackKey === '2026-10-04', 'Invalid timezone falls back to UTC safely without crashing');

  console.log(`\n🎉 Analytics Timezone Logic Tests Completed: ${passed}/${total} passed.\n`);
}

runAnalyticsTimezoneTests();
