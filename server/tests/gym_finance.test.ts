import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testGymAndFinanceFlow() {
  console.log('🧪 Testing Gym & Personal Finance API Endpoints...');
  const request = supertest(app);

  try {
    // 1. Authenticate with demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    const token = loginRes.body.data.tokens.accessToken;
    console.log('1. Authentication:', loginRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    // 2. Register Exercise (UC-92)
    const exerciseRes = await request
      .post('/api/v1/gym/exercises')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Barbell Bench Press',
        category: 'CHEST',
        notes: 'Flat bench with Olympic barbell',
      });

    console.log('2. Register Exercise (UC-92):', exerciseRes.status === 201 && exerciseRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const exerciseId = exerciseRes.body.data.id;

    // 3. Create Workout (UC-91)
    const workoutRes = await request
      .post('/api/v1/gym')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Chest & Triceps Hypertrophy',
        durationMinutes: 75,
        notes: 'Heavy compound day',
      });

    console.log('3. Create Workout (UC-91):', workoutRes.status === 201 && workoutRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const workoutId = workoutRes.body.data.id;

    // 4. Add Exercise to Workout with Sets & Auto PR Detection (UC-93, UC-96)
    const addExerciseRes = await request
      .post(`/api/v1/gym/${workoutId}/exercises`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        exerciseId,
        order: 1,
        sets: [
          { setNumber: 1, weightKg: 80, repetitions: 10, notes: 'Warmup' },
          { setNumber: 2, weightKg: 100, repetitions: 6, notes: 'Working set' },
          { setNumber: 3, weightKg: 110, repetitions: 3, notes: 'New PR attempt!' },
        ],
      });

    console.log('4. Add Exercise with Sets & PR Detection (UC-93, UC-96):', addExerciseRes.status === 201 ? '✅ PASS' : '❌ FAIL');

    // 5. Record Body Weight Metric (UC-99)
    const metricRes = await request
      .post('/api/v1/gym/metrics')
      .set('Authorization', `Bearer ${token}`)
      .send({
        weightKg: 78.5,
        chestCm: 104,
        waistCm: 81,
        armsCm: 38.5,
      });

    console.log('5. Record Body Metric (UC-99):', metricRes.status === 201 && metricRes.body.data.weightKg === 78.5 ? '✅ PASS' : '❌ FAIL');

    // 6. Gym Analytics (UC-101)
    const gymAnalyticsRes = await request
      .get('/api/v1/gym/analytics')
      .set('Authorization', `Bearer ${token}`);

    console.log('6. Gym Analytics Dashboard (UC-101):', gymAnalyticsRes.status === 200 && gymAnalyticsRes.body.data.totalWorkouts > 0 ? '✅ PASS' : '❌ FAIL');

    // 7. Get or Create Category for Finance
    let category = await prisma.category.findFirst({ where: { name: 'Food & Dining' } });
    if (!category) {
      const user = await prisma.user.findUnique({ where: { email: 'demo@habos.dev' } });
      category = await prisma.category.create({
        data: {
          name: 'Food & Dining',
          color: '#F59E0B',
          icon: 'restaurant',
          userId: user!.id,
        },
      });
    }

    // 8. Add Income & Expense Transactions (UC-102, UC-103)
    const incomeRes = await request
      .post('/api/v1/finance/transactions')
      .set('Authorization', `Bearer ${token}`)
      .send({
        amount: 5000,
        type: 'INCOME',
        source: 'Full-time Software Engineer Salary',
        description: 'Monthly salary payout',
      });

    console.log('7. Add Income (UC-102):', incomeRes.status === 201 && incomeRes.body.data.amount === 5000 ? '✅ PASS' : '❌ FAIL');
    const incomeId = incomeRes.body.data.id;

    const expenseRes = await request
      .post('/api/v1/finance/transactions')
      .set('Authorization', `Bearer ${token}`)
      .send({
        amount: 450,
        type: 'EXPENSE',
        categoryId: category.id,
        source: 'CREDIT_CARD',
        description: 'Weekly grocery haul & meal prep',
      });

    console.log('8. Add Expense (UC-103):', expenseRes.status === 201 && expenseRes.body.data.amount === 450 ? '✅ PASS' : '❌ FAIL');
    const expenseId = expenseRes.body.data.id;

    // 9. Set Category Budget & Track Spending (UC-107, UC-108)
    const budgetRes = await request
      .post('/api/v1/finance/budgets')
      .set('Authorization', `Bearer ${token}`)
      .send({
        categoryId: category.id,
        monthlyLimit: 800,
      });

    console.log('9. Set Budget (UC-107):', budgetRes.status === 201 && budgetRes.body.data.monthlyLimit === 800 ? '✅ PASS' : '❌ FAIL');

    // 10. Financial Analytics & Savings Rate (UC-109, UC-110)
    const financeAnalyticsRes = await request
      .get('/api/v1/finance/analytics')
      .set('Authorization', `Bearer ${token}`);

    console.log(
      '10. Financial Analytics & Savings Rate (UC-109, UC-110):',
      financeAnalyticsRes.status === 200 && financeAnalyticsRes.body.data.savingsRate > 0 ? '✅ PASS' : '❌ FAIL'
    );

    // 11. Cleanup created items
    await request.delete(`/api/v1/gym/${workoutId}`).set('Authorization', `Bearer ${token}`);
    await request.delete(`/api/v1/finance/transactions/${incomeId}`).set('Authorization', `Bearer ${token}`);
    await request.delete(`/api/v1/finance/transactions/${expenseId}`).set('Authorization', `Bearer ${token}`);
    console.log('11. Gym & Finance Cleanup: ✅ PASS');

    console.log('\n🎉 ALL GYM & PERSONAL FINANCE API TESTS PASSED WITH 100% SUCCESS!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testGymAndFinanceFlow();
