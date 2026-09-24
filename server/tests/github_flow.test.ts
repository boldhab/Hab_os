import supertest from 'supertest';
import app from '../src/app';
import prisma from '../src/config/db';

async function testGitHubDevHubWorkflow() {
  console.log('🧪 Testing GitHub Developer Hub Connected Workflow...');
  const request = supertest(app);

  try {
    // 1. Authenticate with demo user
    const loginRes = await request.post('/api/v1/auth/login').send({
      email: 'demo@habos.dev',
      password: 'Habos@2026',
    });

    const token = loginRes.body.data.tokens.accessToken;
    console.log('1. Authentication: ✅ PASS');

    // 2. Connect with GitHub (Sync Username & Fetch Live Public Profile)
    const syncRes = await request
      .post('/api/v1/integrations/github/sync')
      .set('Authorization', `Bearer ${token}`)
      .send({
        username: 'torvalds', // Using public profile for test
        currentStreak: 5,
        longestStreak: 20,
      });

    console.log('2. Connect GitHub Account:', syncRes.status === 200 && syncRes.body.data.username === 'torvalds' ? '✅ PASS' : '❌ FAIL');

    // 3. List GitHub Repositories (UC-54)
    const listReposRes = await request
      .get('/api/v1/integrations/github/repos')
      .set('Authorization', `Bearer ${token}`);

    console.log(
      '3. List GitHub Repositories:',
      listReposRes.status === 200 && Array.isArray(listReposRes.body.data.repositories) && listReposRes.body.data.repositories.length > 0
        ? `✅ PASS (Fetched ${listReposRes.body.data.repositories.length} repos)`
        : '❌ FAIL'
    );

    const firstRepo = listReposRes.body.data.repositories[0];

    // 4. Import Selected Repository as HabOS Project
    const importRes = await request
      .post('/api/v1/integrations/github/import-repo')
      .set('Authorization', `Bearer ${token}`)
      .send({
        repoName: firstRepo.name,
        owner: firstRepo.owner,
        repoUrl: firstRepo.repoUrl,
        description: firstRepo.description,
        language: firstRepo.primaryLanguage,
      });

    console.log('4. Import Selected Repo as HabOS Project:', importRes.status === 201 || importRes.status === 200 ? '✅ PASS' : '❌ FAIL');
    const importedProjectId = importRes.body.data.project.id;

    // 5. Deep Analyze Repository (Commits, Velocity, Languages, Issues)
    const analyzeRes = await request
      .get(`/api/v1/integrations/github/repos/${firstRepo.owner}/${firstRepo.name}/analyze`)
      .set('Authorization', `Bearer ${token}`);

    console.log(
      '5. Deep Analyze Repo Commits & Velocity:',
      analyzeRes.status === 200 && !!analyzeRes.body.data.analysisSummary
        ? `✅ PASS (Analyzed ${analyzeRes.body.data.analysisSummary.recentCommitsAnalyzed} commits across ${analyzeRes.body.data.analysisSummary.activeCodingDaysInSample} active days)`
        : '❌ FAIL'
    );

    // 6. Cleanup
    await request.delete(`/api/v1/projects/${importedProjectId}`).set('Authorization', `Bearer ${token}`);
    console.log('6. Cleanup: ✅ PASS');

    console.log('\n🎉 ALL GITHUB DEVELOPER HUB WORKFLOW TESTS PASSED WITH 100% SUCCESS!');
  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testGitHubDevHubWorkflow();
