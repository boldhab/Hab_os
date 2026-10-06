import path from 'path';
import fs from 'fs';
import { Request, Response } from 'express';
import authService from './auth.service';
import ApiResponse from '../../common/apiResponse';
import ApiError from '../../common/apiError';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';
import env from '../../config/env';

/**
 * @desc    Register a new user account
 * @route   POST /api/v1/auth/register
 * @access  Public
 */
export const register = asyncHandler(async (req: Request, res: Response) => {
  const result = await authService.register(req.body);
  return ApiResponse.success(res, result, 'User registered successfully', 201);
});

/**
 * @desc    Authenticate user & get tokens
 * @route   POST /api/v1/auth/login
 * @access  Public
 */
export const login = asyncHandler(async (req: Request, res: Response) => {
  const result = await authService.login(req.body);
  return ApiResponse.success(res, result, 'Login successful');
});

function renderGoogleSetupPage(returnUrl: string): string {
  const safeReturnUrl = encodeURIComponent(returnUrl);
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Connect Real Google Account - HABos</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Roboto', -apple-system, BlinkMacSystemFont, sans-serif;
      background-color: #0e0e11;
      color: #e4e4e7;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      padding: 20px;
    }
    .card {
      background: #18181b;
      border: 1px solid #27272a;
      border-radius: 24px;
      padding: 36px 32px;
      width: 100%;
      max-width: 520px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.5);
    }
    .header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 20px;
    }
    h1 {
      font-size: 22px;
      font-weight: 700;
      color: #fafafa;
    }
    .desc {
      font-size: 14px;
      line-height: 1.5;
      color: #a1a1aa;
      margin-bottom: 24px;
    }
    .notice-box {
      background: #27272a;
      border-left: 4px solid #ef4444;
      padding: 12px 16px;
      border-radius: 8px;
      margin-bottom: 24px;
      font-size: 13px;
      color: #d4d4d8;
    }
    .form-group {
      display: flex;
      flex-direction: column;
      gap: 6px;
      margin-bottom: 16px;
    }
    label {
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: #a1a1aa;
    }
    .input-field {
      padding: 12px 14px;
      background: #09090b;
      border: 1px solid #3f3f46;
      border-radius: 12px;
      color: #fafafa;
      font-size: 14px;
      outline: none;
      transition: border-color 0.15s;
    }
    .input-field:focus {
      border-color: #ef4444;
    }
    .btn-submit {
      width: 100%;
      background: #ef4444;
      color: white;
      border: none;
      border-radius: 12px;
      padding: 14px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      margin-top: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      transition: background 0.15s;
    }
    .btn-submit:hover {
      background: #dc2626;
    }
    .steps {
      margin-top: 24px;
      padding-top: 20px;
      border-top: 1px solid #27272a;
      font-size: 12px;
      color: #71717a;
      line-height: 1.6;
    }
    .steps a {
      color: #60a5fa;
      text-decoration: none;
    }
    .steps a:hover {
      text-decoration: underline;
    }
    .cancel-link {
      display: block;
      text-align: center;
      margin-top: 16px;
      font-size: 13px;
      color: #a1a1aa;
      text-decoration: none;
    }
    .cancel-link:hover {
      color: #fafafa;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <svg width="32" height="32" viewBox="0 0 48 48">
        <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
        <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
        <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
        <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
      </svg>
      <h1>Connect Real Google Account</h1>
    </div>

    <p class="desc">
      To authenticate with your real Google account on <strong>accounts.google.com</strong>, Google requires an OAuth 2.0 Client ID from the Google Cloud Console.
    </p>

    <div class="notice-box">
      Demo accounts have been disabled. Enter your Google Cloud OAuth credentials below to connect directly to Google:
    </div>

    <form action="/api/v1/auth/google/configure" method="POST">
      <input type="hidden" name="returnUrl" value="${returnUrl}">
      <div class="form-group">
        <label for="clientId">Google Client ID</label>
        <input type="text" id="clientId" name="clientId" class="input-field" placeholder="xxxx-xxxx.apps.googleusercontent.com" required>
      </div>

      <div class="form-group">
        <label for="clientSecret">Google Client Secret</label>
        <input type="password" id="clientSecret" name="clientSecret" class="input-field" placeholder="GOCSPX-xxxx" required>
      </div>

      <button type="submit" class="btn-submit">
        Save & Connect to Google
      </button>
    </form>

    <div class="steps">
      <strong>How to get these in 2 minutes:</strong><br>
      1. Open <a href="https://console.cloud.google.com/apis/credentials" target="_blank" rel="noreferrer">Google Cloud Console &rarr; Credentials</a>.<br>
      2. Click <strong>Create Credentials &rarr; OAuth client ID</strong> (Type: <em>Web application</em>).<br>
      3. Under <strong>Authorized redirect URIs</strong>, add: <code>http://localhost:5000/api/v1/auth/google/callback</code><br>
      4. Paste the Client ID and Secret above.
    </div>

    <a href="${returnUrl}/#/login" class="cancel-link">Return to HABos Login</a>
  </div>
</body>
</html>`;
}

/**
 * @desc    Initiate Real Google OAuth 2.0 flow
 * @route   GET /api/v1/auth/google
 * @access  Public
 */
export const initiateGoogleAuth = asyncHandler(async (req: Request, res: Response) => {
  const returnUrl = ((req.query.returnUrl as string) || req.headers.referer || env.FRONTEND_URL || 'http://localhost:3000').replace(/\/+$/, '');

  // If real Google OAuth credentials are not provided, show setup form
  if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET) {
    if (req.headers.accept?.includes('application/json') || req.query.format === 'json') {
      return ApiResponse.error(res, 'Google OAuth credentials not configured in server/.env', 400);
    }
    return res.type('html').send(renderGoogleSetupPage(returnUrl));
  }

  const authUrl = authService.getGoogleAuthUrl(returnUrl);

  if (req.headers.accept?.includes('application/json') || req.query.format === 'json') {
    return ApiResponse.success(res, { url: authUrl }, 'Google authorization URL generated');
  }

  return res.redirect(authUrl);
});

/**
 * @desc    Configure Google OAuth credentials directly and redirect to Google
 * @route   POST /api/v1/auth/google/configure
 * @access  Public
 */
export const configureGoogleOAuth = asyncHandler(async (req: Request, res: Response) => {
  const returnUrl = ((req.body.returnUrl || req.query.returnUrl) as string) || env.FRONTEND_URL || 'http://localhost:3000';
  const clientId = (req.body.clientId as string)?.trim();
  const clientSecret = (req.body.clientSecret as string)?.trim();

  if (!clientId || !clientSecret) {
    throw new ApiError(400, 'Both Google Client ID and Google Client Secret are required.');
  }

  // Update in-memory runtime environment variables
  env.GOOGLE_CLIENT_ID = clientId;
  env.GOOGLE_CLIENT_SECRET = clientSecret;

  // Persist to server/.env file
  try {
    const envPath = path.resolve(__dirname, '../../../.env');
    if (fs.existsSync(envPath)) {
      let envContent = fs.readFileSync(envPath, 'utf8');
      envContent = envContent.replace(/GOOGLE_CLIENT_ID=.*/g, `GOOGLE_CLIENT_ID=${clientId}`);
      envContent = envContent.replace(/GOOGLE_CLIENT_SECRET=.*/g, `GOOGLE_CLIENT_SECRET=${clientSecret}`);
      if (!envContent.includes('GOOGLE_CLIENT_ID=')) {
        envContent += `\nGOOGLE_CLIENT_ID=${clientId}`;
      }
      if (!envContent.includes('GOOGLE_CLIENT_SECRET=')) {
        envContent += `\nGOOGLE_CLIENT_SECRET=${clientSecret}`;
      }
      fs.writeFileSync(envPath, envContent, 'utf8');
    }
  } catch (_err) {
    // Non-fatal if env file write fails in restricted environments
  }

  // Generate real Google OAuth URL and redirect directly to Google accounts
  const authUrl = authService.getGoogleAuthUrl(returnUrl);
  return res.redirect(authUrl);
});

/**
 * @desc    Handle Google OAuth 2.0 redirect callback
 * @route   GET /api/v1/auth/google/callback
 * @access  Public
 */
export const handleGoogleCallback = asyncHandler(async (req: Request, res: Response) => {
  const returnUrl = (env.FRONTEND_URL || 'http://localhost:3000').replace(/\/+$/, '');

  if (req.query.error) {
    const errorDesc = (req.query.error_description || req.query.error) as string;
    return res.redirect(`${returnUrl}/#/login?error=${encodeURIComponent(errorDesc)}`);
  }

  const code = req.query.code as string;
  const state = req.query.state as string;

  if (!code || !state) {
    return res.redirect(
      `${returnUrl}/#/login?error=${encodeURIComponent(
        'Missing authorization code or state from Google callback'
      )}`
    );
  }

  try {
    const result = await authService.handleGoogleOAuthCallback(code, state);
    const baseReturn = (result.returnUrl || returnUrl).replace(/\/+$/, '');
    const redirectUrl = `${baseReturn}/#/auth/callback?token=${encodeURIComponent(
      result.tokens.accessToken
    )}&refreshToken=${encodeURIComponent(result.tokens.refreshToken)}&expiresIn=${encodeURIComponent(
      result.tokens.expiresIn
    )}`;

    return res.redirect(redirectUrl);
  } catch (err: any) {
    const message = err.message || 'Google authentication failed';
    return res.redirect(`${returnUrl}/#/login?error=${encodeURIComponent(message)}`);
  }
});

/**
 * @desc    Authenticate or register user with Google payload directly
 * @route   POST /api/v1/auth/google
 * @access  Public
 */
export const googleAuth = asyncHandler(async (req: Request, res: Response) => {
  const result = await authService.googleAuth(req.body);
  return ApiResponse.success(res, result, 'Google authentication successful');
});

/**
 * @desc    Refresh access token using refresh token
 * @route   POST /api/v1/auth/refresh
 * @access  Public
 */
export const refreshTokens = asyncHandler(async (req: Request, res: Response) => {
  const { refreshToken } = req.body;
  const tokens = await authService.refreshTokens(refreshToken);
  return ApiResponse.success(res, tokens, 'Tokens refreshed successfully');
});

/**
 * @desc    Logout user & invalidate tokens
 * @route   POST /api/v1/auth/logout
 * @access  Private
 */
export const logout = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const { refreshToken } = req.body;
  const result = await authService.logout(authReq.user!.id, refreshToken);
  return ApiResponse.success(res, result, 'Logged out successfully');
});

/**
 * @desc    Get current authenticated user profile
 * @route   GET /api/v1/auth/me
 * @access  Private
 */
export const getProfile = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const profile = await authService.getProfile(authReq.user!.id);
  return ApiResponse.success(res, profile, 'Profile retrieved successfully');
});

/**
 * @desc    Update user profile
 * @route   PUT /api/v1/auth/profile
 * @access  Private
 */
export const updateProfile = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const updatedUser = await authService.updateProfile(authReq.user!.id, req.body);
  return ApiResponse.success(res, updatedUser, 'Profile updated successfully');
});

/**
 * @desc    Update user preferences & targets
 * @route   PUT /api/v1/auth/preferences
 * @access  Private
 */
export const updatePreferences = asyncHandler(async (req: Request, res: Response) => {
  const authReq = req as AuthRequest;
  const updatedPreferences = await authService.updatePreferences(authReq.user!.id, req.body);
  return ApiResponse.success(res, updatedPreferences, 'Preferences updated successfully');
});

export default {
  register,
  login,
  googleAuth,
  initiateGoogleAuth,
  handleGoogleCallback,
  configureGoogleOAuth,
  refreshTokens,
  logout,
  getProfile,
  updateProfile,
  updatePreferences,
};
