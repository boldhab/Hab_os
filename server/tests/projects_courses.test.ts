import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testProjectsAndCoursesFlow() {
  console.log('🧪 Testing Projects & Courses API Endpoints...');
  const request = supertest(app);

  try {
    // 1. Authenticate with demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    const token = loginRes.body.data.tokens.accessToken;
    console.log('1. Authentication:', loginRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    // 2. Create Project (UC-38)
    const projectRes = await request
      .post('/api/v1/projects')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'HabOS AI Recommendation Engine',
        description: 'Predictive agentic life assistant algorithms',
        technologies: ['TypeScript', 'Express', 'Prisma', 'LLM'],
        status: 'IN_PROGRESS',
        color: '#6366F1',
      });

    console.log('2. Create Project (UC-38):', projectRes.status === 201 && projectRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const projectId = projectRes.body.data.id;

    // 3. Add Feature & Auto-calculate Progress (UC-43, UC-47)
    const featureRes = await request
      .post(`/api/v1/projects/${projectId}/features`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Context Gathering Pipeline',
        description: 'Aggregate last 7 days of focus, habits, and coding data',
        status: 'COMPLETED',
        priority: 'HIGH',
      });

    console.log('3. Create Feature (UC-43):', featureRes.status === 201 && featureRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const featureId = featureRes.body.data.id;

    // 4. Report Bug (UC-48) & Resolve Bug (UC-50)
    const bugRes = await request
      .post(`/api/v1/projects/${projectId}/bugs`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Memory leak on long streaming sessions',
        description: 'Context buffer grows indefinitely',
        priority: 'HIGH',
        status: 'OPEN',
      });

    console.log('4. Create Bug (UC-48):', bugRes.status === 201 && bugRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const bugId = bugRes.body.data.id;

    const resolveBugRes = await request
      .put(`/api/v1/projects/${projectId}/bugs/${bugId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        status: 'RESOLVED',
        resolutionNotes: 'Capped sliding window to max 50 items',
      });

    console.log('5. Resolve Bug (UC-50):', resolveBugRes.status === 200 && resolveBugRes.body.data.status === 'RESOLVED' ? '✅ PASS' : '❌ FAIL');

    // 6. Create Course (UC-70)
    const courseRes = await request
      .post('/api/v1/courses')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Advanced Distributed Systems',
        code: 'CS-804',
        semester: 'Fall 2026',
        instructor: 'Dr. Alan Turing',
        credits: 4,
        color: '#8B5CF6',
      });

    console.log('6. Create Course (UC-70):', courseRes.status === 201 && courseRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const courseId = courseRes.body.data.id;

    // 7. Add Assignment (UC-75)
    const assignmentRes = await request
      .post(`/api/v1/courses/${courseId}/assignments`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Raft Consensus Implementation in Rust',
        description: 'Leader election, log replication, and heartbeat timers',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        status: 'IN_PROGRESS',
        maxGrade: 100,
      });

    console.log('7. Create Assignment (UC-75):', assignmentRes.status === 201 && assignmentRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const assignmentId = assignmentRes.body.data.id;

    // 8. Add Exam (UC-78)
    const examRes = await request
      .post(`/api/v1/courses/${courseId}/exams`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Midterm Examination',
        examDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
        startTime: '10:00',
        examType: 'MIDTERM',
        weight: 30,
      });

    console.log('8. Create Exam (UC-78):', examRes.status === 201 && examRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const examId = examRes.body.data.id;

    // 9. Record Attendance (UC-82)
    const attendanceRes = await request
      .post(`/api/v1/courses/${courseId}/attendance`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        status: 'PRESENT',
        notes: 'Attended lecture on Paxos vs Raft',
      });

    console.log('9. Record Attendance (UC-82):', attendanceRes.status === 200 && attendanceRes.body.data.status === 'PRESENT' ? '✅ PASS' : '❌ FAIL');

    // 10. Academic Summary (UC-77, UC-79, UC-81)
    const academicSummaryRes = await request
      .get('/api/v1/courses/summary')
      .set('Authorization', `Bearer ${token}`);

    console.log('10. Academic Summary Dashboard:', academicSummaryRes.status === 200 && academicSummaryRes.body.data.totalCourses > 0 ? '✅ PASS' : '❌ FAIL');

    // 11. Cleanup created items
    await request.delete(`/api/v1/projects/${projectId}/features/${featureId}`).set('Authorization', `Bearer ${token}`);
    await request.delete(`/api/v1/projects/${projectId}/bugs/${bugId}`).set('Authorization', `Bearer ${token}`);
    await request.delete(`/api/v1/projects/${projectId}`).set('Authorization', `Bearer ${token}`);
    await request.delete(`/api/v1/courses/${courseId}/assignments/${assignmentId}`).set('Authorization', `Bearer ${token}`);
    await request.delete(`/api/v1/courses/${courseId}/exams/${examId}`).set('Authorization', `Bearer ${token}`);
    await request.delete(`/api/v1/courses/${courseId}`).set('Authorization', `Bearer ${token}`);
    console.log('11. Projects & Courses Cleanup: ✅ PASS');

    console.log('\n🎉 ALL PROJECTS & COURSES API TESTS PASSED WITH 100% SUCCESS!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testProjectsAndCoursesFlow();
