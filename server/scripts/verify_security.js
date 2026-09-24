const http = require('http');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:5000';

function makeRequest(endpoint, method = 'GET', body = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(endpoint, BASE_URL);
    const postData = body ? JSON.stringify(body) : '';

    const reqHeaders = {
      'Content-Type': 'application/json',
      ...headers,
    };

    if (body) {
      reqHeaders['Content-Length'] = Buffer.byteLength(postData).toString();
    }

    const req = http.request(
      {
        hostname: url.hostname,
        port: url.port,
        path: url.pathname,
        method,
        headers: reqHeaders,
      },
      (res) => {
        let rawData = '';
        res.on('data', (chunk) => {
          rawData += chunk;
        });
        res.on('end', () => {
          let parsed;
          try {
            parsed = JSON.parse(rawData);
          } catch {
            parsed = rawData;
          }
          resolve({
            statusCode: res.statusCode || 0,
            headers: res.headers,
            body: parsed,
          });
        });
      }
    );

    req.on('error', (err) => reject(err));

    if (body) {
      req.write(postData);
    }
    req.end();
  });
}

async function runSecurityVerification() {
  console.log('🛡️  HABos Security Hardening Verification Suite\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, title, details) {
    if (condition) {
      console.log(`✅ PASS: ${title}`);
      passed++;
    } else {
      console.error(`❌ FAIL: ${title}${details ? ` -> ${details}` : ''}`);
      failed++;
    }
  }

  // 1. Test Input Validation (Bad email, short password)
  console.log('--- 1. Testing Input Validation ---');
  const invalidRes = await makeRequest('/api/v1/auth/login', 'POST', {
    email: 'not-a-valid-email',
    password: '123',
  });
  assert(
    invalidRes.statusCode === 400 && invalidRes.body.success === false,
    'Rejects malformed email and password (<6 chars) with HTTP 400',
    `Status: ${invalidRes.statusCode}, body: ${JSON.stringify(invalidRes.body)}`
  );

  // 2. Test Rate Limiting Headers
  console.log('\n--- 2. Testing Rate Limiting Headers ---');
  const rateLimitHeader =
    invalidRes.headers['ratelimit-limit'] ||
    invalidRes.headers['x-ratelimit-limit'] ||
    invalidRes.headers['ratelimit'];
  const rateLimitRemaining =
    invalidRes.headers['ratelimit-remaining'] ||
    invalidRes.headers['x-ratelimit-remaining'];
  assert(
    rateLimitHeader !== undefined,
    'Rate limit headers are present on auth endpoints',
    `Headers: ${JSON.stringify(invalidRes.headers)}`
  );

  // 3. Test Registration & Token Generation
  console.log('\n--- 3. Testing Registration & Token Generation ---');
  const testEmail = `sec_test_${Date.now()}@example.com`;
  const registerRes = await makeRequest('/api/v1/auth/register', 'POST', {
    email: testEmail,
    password: 'Password123!',
    name: 'Security Test User',
  });
  assert(
    registerRes.statusCode === 201 && !!registerRes.body.data.tokens.refreshToken,
    'User registration succeeds and returns accessToken + refreshToken',
    `Status: ${registerRes.statusCode}`
  );

  const initialRefreshToken = registerRes.body.data?.tokens?.refreshToken;

  // 4. Test Single-Use Refresh Token Rotation
  console.log('\n--- 4. Testing Refresh Token Rotation ---');
  const refreshRes = await makeRequest('/api/v1/auth/refresh', 'POST', {
    refreshToken: initialRefreshToken,
  });
  assert(
    refreshRes.statusCode === 200 &&
      !!refreshRes.body.data?.accessToken &&
      !!refreshRes.body.data?.refreshToken &&
      refreshRes.body.data?.refreshToken !== initialRefreshToken,
    'Token rotation issues a brand NEW refresh token on every /refresh call',
    `Status: ${refreshRes.statusCode}, rotated: ${refreshRes.body.data?.refreshToken !== initialRefreshToken}`
  );

  const rotatedRefreshToken = refreshRes.body.data?.refreshToken;

  // 5. Test Token Replay / Theft Breach Detection
  console.log('\n--- 5. Testing Token Reuse / Theft Detection ---');
  const replayRes = await makeRequest('/api/v1/auth/refresh', 'POST', {
    refreshToken: initialRefreshToken, // Re-using old, already rotated/revoked token!
  });
  assert(
    replayRes.statusCode === 403 &&
      typeof replayRes.body.message === 'string' &&
      replayRes.body.message.includes('token reuse detected'),
    'Replay of revoked token is detected as theft, yielding HTTP 403 and invalidating family',
    `Status: ${replayRes.statusCode}, Message: ${replayRes.body.message}`
  );

  // Attempting to refresh with the rotated token should now also fail because family was revoked
  const familyRevokedRes = await makeRequest('/api/v1/auth/refresh', 'POST', {
    refreshToken: rotatedRefreshToken,
  });
  assert(
    familyRevokedRes.statusCode === 403,
    'Entire session family was revoked upon replay detection (rotated token also terminated)',
    `Status: ${familyRevokedRes.statusCode}`
  );

  // 6. Test Login Failure Auditing
  console.log('\n--- 6. Testing Login Failure Auditing ---');
  const loginFailRes = await makeRequest('/api/v1/auth/login', 'POST', {
    email: testEmail,
    password: 'WrongPassword123!',
  });
  assert(
    loginFailRes.statusCode === 401,
    'Invalid credentials returns 401',
    `Status: ${loginFailRes.statusCode}`
  );

  // 7. Verify Audit Logging in audit.log
  console.log('\n--- 7. Testing Audit Logging Persistence ---');
  const auditLogPath = path.resolve(__dirname, '..', 'logs', 'audit.log');
  const auditExists = fs.existsSync(auditLogPath);
  let hasBreachLog = false;
  let hasLoginFailLog = false;
  let hasRegisterLog = false;

  if (auditExists) {
    const fileContent = fs.readFileSync(auditLogPath, 'utf8');
    hasBreachLog = fileContent.includes('AUTH_TOKEN_REUSE_DETECTED');
    hasLoginFailLog = fileContent.includes('AUTH_LOGIN_FAILURE');
    hasRegisterLog = fileContent.includes('AUTH_REGISTER_SUCCESS');
  }
  assert(
    auditExists && hasBreachLog && hasLoginFailLog && hasRegisterLog,
    'Audit log file exists and recorded login failure, register, and token reuse breach events',
    `Path: ${auditLogPath} (Found: breach=${hasBreachLog}, loginFail=${hasLoginFailLog}, register=${hasRegisterLog})`
  );

  console.log(`\n========================================`);
  console.log(`Results: ${passed} Passed, ${failed} Failed`);
  console.log(`========================================\n`);

  process.exit(failed > 0 ? 1 : 0);
}

runSecurityVerification().catch((err) => {
  console.error('Fatal error during security verification:', err);
  process.exit(1);
});
