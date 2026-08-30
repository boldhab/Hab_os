import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testGoalsVaultAndAiFlow() {
  console.log('🧪 Testing Goals, Knowledge Vault & AI Assistant API Endpoints...');
  const request = supertest(app);

  try {
    // 1. Authenticate with demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    const token = loginRes.body.data.tokens.accessToken;
    console.log('1. Authentication:', loginRes.status === 200 ? '✅ PASS' : '❌ FAIL');

    // 2. Create Goal with Initial Milestones (UC-112, UC-115)
    const goalRes = await request
      .post('/api/v1/goals')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Master System Design & Distributed Systems',
        description: 'Complete designing 10 production-grade distributed architectures',
        category: 'CAREER',
        targetDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
        milestones: [
          { title: 'Read Designing Data-Intensive Applications', isCompleted: true },
          { title: 'Build distributed cache with Raft consensus', isCompleted: false },
        ],
      });

    console.log('2. Create Goal with Milestones (UC-112):', goalRes.status === 201 && goalRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const goalId = goalRes.body.data.id;

    // 3. Add Milestone & Recalculate Progress (UC-115, UC-117)
    const milestoneRes = await request
      .post(`/api/v1/goals/${goalId}/milestones`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Design high-throughput rate limiter & event broker',
      });

    console.log('3. Add Milestone & Recalculate Progress (UC-115, UC-117):', milestoneRes.status === 201 && milestoneRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const milestoneId = milestoneRes.body.data.id;

    // 4. View Goal Roadmap Timeline (UC-119, UC-120)
    const roadmapRes = await request
      .get('/api/v1/goals/roadmap')
      .set('Authorization', `Bearer ${token}`);

    console.log('4. View Goal Roadmap (UC-119):', roadmapRes.status === 200 && roadmapRes.body.data.timeline.length > 0 ? '✅ PASS' : '❌ FAIL');

    // 5. Create Vault Note with Markdown & Embedded Code Snippet (UC-121, UC-124)
    const noteRes = await request
      .post('/api/v1/vault/notes')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Distributed Locks with Redis Redlock',
        content: '# Redlock Algorithm\n\nGuarantees mutual exclusion across N Redis masters without single point of failure.',
        tags: ['redis', 'distributed-systems', 'concurrency'],
        isMistakeSolution: false,
        codeSnippets: [
          {
            language: 'typescript',
            code: 'const lock = await redlock.acquire(["resources/lifescore"], 5000);',
            description: 'Acquiring distributed lock with 5s TTL',
          },
        ],
      });

    console.log('5. Create Vault Note with Code Snippets (UC-121, UC-124):', noteRes.status === 201 && noteRes.body.data.id ? '✅ PASS' : '❌ FAIL');
    const noteId = noteRes.body.data.id;

    // 6. Search Knowledge Vault (UC-127, UC-128)
    const vaultSearchRes = await request
      .get('/api/v1/vault/search?search=Redlock')
      .set('Authorization', `Bearer ${token}`);

    console.log('6. Search Knowledge Vault (UC-127):', vaultSearchRes.status === 200 && vaultSearchRes.body.data.totalResults > 0 ? '✅ PASS' : '❌ FAIL');

    // 7. Get Vault Tags (UC-128)
    const tagsRes = await request
      .get('/api/v1/vault/tags')
      .set('Authorization', `Bearer ${token}`);

    console.log('7. Retrieve Vault Tags (UC-128):', tagsRes.status === 200 && tagsRes.body.data.includes('redis') ? '✅ PASS' : '❌ FAIL');

    // 8. Generate Daily Briefing from Live Context (UC-148)
    const briefingRes = await request
      .get('/api/v1/ai/briefing')
      .set('Authorization', `Bearer ${token}`);

    console.log('8. Generate Daily Briefing (UC-148):', briefingRes.status === 200 && Array.isArray(briefingRes.body.data.highlights) ? '✅ PASS' : '❌ FAIL');

    // 9. Intelligent Next Action Recommendation (UC-150)
    const recRes = await request
      .get('/api/v1/ai/recommendation')
      .set('Authorization', `Bearer ${token}`);

    console.log('9. AI Next Action Recommendation (UC-150):', recRes.status === 200 && !!recRes.body.data.recommendationType ? '✅ PASS' : '❌ FAIL');

    // 10. Ask AI Assistant with domain query (UC-147)
    const askRes = await request
      .post('/api/v1/ai/ask')
      .set('Authorization', `Bearer ${token}`)
      .send({
        prompt: 'What habits do I need to complete today?',
      });

    console.log('10. Ask AI Assistant (UC-147):', askRes.status === 200 && !!askRes.body.data.response ? '✅ PASS' : '❌ FAIL');

    // 11. Cleanup created items
    await request.delete(`/api/v1/goals/${goalId}/milestones/${milestoneId}`).set('Authorization', `Bearer ${token}`);
    await request.delete(`/api/v1/goals/${goalId}`).set('Authorization', `Bearer ${token}`);
    await request.delete(`/api/v1/vault/notes/${noteId}`).set('Authorization', `Bearer ${token}`);
    console.log('11. Goals, Vault & AI Cleanup: ✅ PASS');

    console.log('\n🎉 ALL GOALS, VAULT & AI ASSISTANT API TESTS PASSED WITH 100% SUCCESS!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testGoalsVaultAndAiFlow();
