import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import ApiError from '../../common/apiError';
import env from '../../config/env';

const JWT_SECRET = env.JWT_SECRET;
const JWT_REFRESH_SECRET = env.JWT_REFRESH_SECRET;
const JWT_EXPIRES_IN = env.JWT_EXPIRES_IN || '15m';
const JWT_REFRESH_EXPIRES_IN = env.JWT_REFRESH_EXPIRES_IN || '30d';

// ──────────────────────────────────────────────
// In-memory stores (no database required)
// ──────────────────────────────────────────────

interface InMemoryUser {
  id: string;
  email: string;
  name: string | null;
  password: string; // bcrypt hash
  googleId?: string;
  authProvider?: string;
  avatarUrl: string | null;
  timezone: string;
  dateFormat: string;
  preferences: InMemoryPreferences | null;
  categories: InMemoryCategory[];
  createdAt: Date;
  updatedAt: Date;
}

interface InMemoryPreferences {
  dashboardModules: string[];
  dailyCodingTargetMins: number;
  dailyStudyTargetMins: number;
  dailyReadingTargetMins: number;
  weeklyGymTarget: number;
  quietHoursStart?: string;
  quietHoursEnd?: string;
  lifeScoreWeights: Record<string, number>;
}

interface InMemoryCategory {
  name: string;
  color: string;
  icon: string;
  type: string;
}

interface InMemoryRefreshToken {
  id: string;
  token: string;
  userId: string;
  revoked: boolean;
  expiresAt: Date;
}

// Map: email -> user
const usersStore = new Map<string, InMemoryUser>();
// Map: id -> user (index)
const usersById = new Map<string, InMemoryUser>();
// Map: token string -> refresh token record
const refreshTokensStore = new Map<string, InMemoryRefreshToken>();

function createDefaultPreferences(): InMemoryPreferences {
  return {
    dashboardModules: [
      'priorities',
      'life_score',
      'coding_stats',
      'study_timer',
      'gym_workout',
      'finance_summary',
      'habits',
    ],
    dailyCodingTargetMins: 120,
    dailyStudyTargetMins: 90,
    dailyReadingTargetMins: 30,
    weeklyGymTarget: 4,
    lifeScoreWeights: {
      tasks: 0.15,
      coding: 0.2,
      study: 0.2,
      gym: 0.15,
      habits: 0.15,
      finance: 0.15,
    },
  };
}

function createDefaultCategories(): InMemoryCategory[] {
  return [
    { name: 'Frontend Engineering', color: '#3B82F6', icon: 'code', type: 'TASK' },
    { name: 'Backend & API', color: '#10B981', icon: 'server', type: 'TASK' },
    { name: 'University Study', color: '#8B5CF6', icon: 'book', type: 'TASK' },
    { name: 'Health & Fitness', color: '#EF4444', icon: 'heart', type: 'HABIT' },
    { name: 'Food & Dining', color: '#F59E0B', icon: 'utensils', type: 'FINANCE' },
    { name: 'Education & Books', color: '#6366F1', icon: 'graduation-cap', type: 'FINANCE' },
  ];
}

// Pre-seed demo user so demo login works immediately without database
function seedDemoUser() {
  const demoId = 'demo-user-habos-2026';
  const demoEmail = 'demo@habos.dev';
  const hashedPassword = bcrypt.hashSync('Habos@2026', 10);
  const now = new Date();

  const demoUser: InMemoryUser = {
    id: demoId,
    email: demoEmail,
    name: 'HabOS Explorer',
    password: hashedPassword,
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    timezone: 'UTC',
    dateFormat: 'YYYY-MM-DD',
    preferences: createDefaultPreferences(),
    categories: createDefaultCategories(),
    createdAt: now,
    updatedAt: now,
  };

  usersStore.set(demoEmail, demoUser);
  usersById.set(demoId, demoUser);
}
seedDemoUser();

function safeUserPayload(user: InMemoryUser) {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    timezone: user.timezone,
    dateFormat: user.dateFormat,
    avatarUrl: user.avatarUrl,
    preferences: user.preferences,
    createdAt: user.createdAt,
  };
}

// ──────────────────────────────────────────────
// DTOs
// ──────────────────────────────────────────────

export interface RegisterDTO {
  name?: string | null;
  email: string;
  password: string;
  timezone?: string;
  dateFormat?: string;
}

export interface LoginDTO {
  email: string;
  password: string;
}

export interface GoogleAuthDTO {
  idToken?: string;
  email?: string;
  name?: string;
  avatarUrl?: string;
  googleId?: string;
}

export interface UpdateProfileDTO {
  name?: string;
  avatarUrl?: string;
  timezone?: string;
  dateFormat?: string;
  currentPassword?: string;
  newPassword?: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: string;
}

// ──────────────────────────────────────────────
// Token generation (in-memory refresh token store)
// ──────────────────────────────────────────────

export const generateAuthTokens = async (userId: string): Promise<AuthTokens> => {
  const accessToken = jwt.sign({ id: userId }, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN as jwt.SignOptions['expiresIn'],
  });

  const refreshToken = jwt.sign(
    { id: userId, jti: crypto.randomBytes(16).toString('hex') },
    JWT_REFRESH_SECRET,
    {
      expiresIn: JWT_REFRESH_EXPIRES_IN as jwt.SignOptions['expiresIn'],
    }
  );

  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 30);

  const tokenRecord: InMemoryRefreshToken = {
    id: crypto.randomUUID(),
    token: refreshToken,
    userId,
    revoked: false,
    expiresAt,
  };
  refreshTokensStore.set(refreshToken, tokenRecord);

  return {
    accessToken,
    refreshToken,
    expiresIn: JWT_EXPIRES_IN,
  };
};

// ──────────────────────────────────────────────
// UC-01: Register a new user (in-memory)
// ──────────────────────────────────────────────

export const register = async (data: RegisterDTO) => {
  const emailKey = data.email.toLowerCase();
  if (usersStore.has(emailKey)) {
    throw new ApiError(400, 'An account with this email address already exists');
  }

  const hashedPassword = await bcrypt.hash(data.password, 10);
  const id = crypto.randomUUID();
  const now = new Date();

  const user: InMemoryUser = {
    id,
    email: emailKey,
    name: data.name || null,
    password: hashedPassword,
    avatarUrl: null,
    timezone: data.timezone || 'UTC',
    dateFormat: data.dateFormat || 'YYYY-MM-DD',
    preferences: createDefaultPreferences(),
    categories: createDefaultCategories(),
    createdAt: now,
    updatedAt: now,
  };

  usersStore.set(emailKey, user);
  usersById.set(id, user);

  const tokens = await generateAuthTokens(user.id);
  return { user: safeUserPayload(user), tokens };
};

// ──────────────────────────────────────────────
// UC-02: Login with email and password (in-memory)
// ──────────────────────────────────────────────

export const login = async ({ email, password }: LoginDTO) => {
  const emailKey = email.toLowerCase();
  const user = usersStore.get(emailKey);

  if (!user) {
    throw new ApiError(401, 'Invalid email or password');
  }

  const isPasswordValid = await bcrypt.compare(password, user.password);
  if (!isPasswordValid) {
    throw new ApiError(401, 'Invalid email or password');
  }

  const tokens = await generateAuthTokens(user.id);
  return { user: safeUserPayload(user), tokens };
};

// ──────────────────────────────────────────────
// UC-GoogleAuth: Google auth (in-memory)
// ──────────────────────────────────────────────

export const googleAuth = async (data: GoogleAuthDTO) => {
  let email = data.email?.toLowerCase().trim();
  let name = data.name?.trim();
  let avatarUrl = data.avatarUrl;
  let googleId = data.googleId?.trim();

  // If idToken is provided, decode payload
  if (data.idToken) {
    try {
      const parts = data.idToken.split('.');
      if (parts.length === 3) {
        const payloadJson = Buffer.from(parts[1], 'base64url').toString('utf8');
        const payload = JSON.parse(payloadJson);
        if (payload.email) email = payload.email.toLowerCase().trim();
        if (payload.name) name = payload.name;
        if (payload.picture) avatarUrl = payload.picture;
        if (payload.sub) googleId = payload.sub;
      }
    } catch (_err) {
      // Ignore token parse error and fallback to direct fields
    }
  }

  if (!email) {
    throw new ApiError(400, 'A valid email address is required for Google authentication');
  }

  let user = usersStore.get(email);

  if (user) {
    // Update existing user with Google details if missing
    if (!user.googleId && googleId) user.googleId = googleId;
    if (!user.avatarUrl && avatarUrl) user.avatarUrl = avatarUrl;
    if (!user.name && name) user.name = name;
    user.updatedAt = new Date();
  } else {
    // Register new user via Google
    const placeholderPassword = await bcrypt.hash(Math.random().toString(36) + Date.now().toString(), 10);
    const id = crypto.randomUUID();
    const now = new Date();

    user = {
      id,
      email,
      name: name || email.split('@')[0],
      password: placeholderPassword,
      googleId: googleId || undefined,
      avatarUrl: avatarUrl || null,
      authProvider: 'google',
      timezone: 'UTC',
      dateFormat: 'YYYY-MM-DD',
      preferences: createDefaultPreferences(),
      categories: createDefaultCategories(),
      createdAt: now,
      updatedAt: now,
    };

    usersStore.set(email, user);
    usersById.set(id, user);
  }

  const tokens = await generateAuthTokens(user.id);
  return { user: safeUserPayload(user), tokens };
};

// ──────────────────────────────────────────────
// UC-OAuth-01: Generate Google OAuth 2.0 URL
// ──────────────────────────────────────────────

export const getGoogleAuthUrl = (returnUrl?: string): string => {
  if (!env.GOOGLE_CLIENT_ID) {
    throw new ApiError(
      400,
      'Google OAuth is not configured on the server. Please set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in server/.env.'
    );
  }

  // Create tamper-proof signed state token (valid for 15 minutes)
  const state = jwt.sign(
    {
      nonce: crypto.randomBytes(16).toString('hex'),
      returnUrl: returnUrl || env.FRONTEND_URL,
      issuedAt: Date.now(),
    },
    env.JWT_SECRET,
    { expiresIn: '15m' }
  );

  const queryParams = new URLSearchParams({
    client_id: env.GOOGLE_CLIENT_ID,
    redirect_uri: env.GOOGLE_CALLBACK_URL,
    response_type: 'code',
    scope: 'openid email profile',
    state,
    access_type: 'offline',
    prompt: 'select_account',
  });

  return `https://accounts.google.com/o/oauth2/v2/auth?${queryParams.toString()}`;
};

// ──────────────────────────────────────────────
// UC-OAuth-02: Handle Google OAuth callback
// ──────────────────────────────────────────────

export const handleGoogleOAuthCallback = async (code: string, state: string) => {
  if (!state) {
    throw new ApiError(400, 'Missing OAuth state parameter.');
  }

  let decodedState: { nonce: string; returnUrl?: string };
  try {
    decodedState = jwt.verify(state, env.JWT_SECRET) as { nonce: string; returnUrl?: string };
  } catch (_err) {
    throw new ApiError(400, 'Invalid or expired OAuth state parameter. Please try logging in again.');
  }

  if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET) {
    throw new ApiError(500, 'Google OAuth credentials are not configured on the server.');
  }

  // Exchange authorization code for tokens with Google
  let tokenData: any;
  try {
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        code,
        client_id: env.GOOGLE_CLIENT_ID,
        client_secret: env.GOOGLE_CLIENT_SECRET,
        redirect_uri: env.GOOGLE_CALLBACK_URL,
        grant_type: 'authorization_code',
      }),
    });

    tokenData = await tokenResponse.json();
    if (!tokenResponse.ok) {
      const errorMsg =
        tokenData.error_description || tokenData.error || 'Failed to exchange authorization code with Google';
      throw new ApiError(400, errorMsg);
    }
  } catch (err: any) {
    if (err instanceof ApiError) throw err;
    throw new ApiError(502, `Failed to communicate with Google OAuth service: ${err.message}`);
  }

  const googleAccessToken = tokenData.access_token;
  if (!googleAccessToken) {
    throw new ApiError(400, 'Google did not return a valid access token.');
  }

  // Fetch verified profile from Google
  let googleProfile: any;
  try {
    const profileResponse = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
      headers: {
        Authorization: `Bearer ${googleAccessToken}`,
      },
    });

    googleProfile = await profileResponse.json();
    if (!profileResponse.ok) {
      throw new ApiError(400, 'Failed to fetch verified user profile from Google.');
    }
  } catch (err: any) {
    if (err instanceof ApiError) throw err;
    throw new ApiError(502, `Failed to fetch Google user profile: ${err.message}`);
  }

  const googleId = googleProfile.sub;
  const email = googleProfile.email?.toLowerCase().trim();
  const emailVerified = googleProfile.email_verified;
  const name = googleProfile.name || email?.split('@')[0] || 'Google User';
  const avatarUrl = googleProfile.picture;

  if (!googleId) {
    throw new ApiError(400, 'Google OpenID Connect response did not contain a valid sub identifier.');
  }

  if (!email || !emailVerified) {
    throw new ApiError(400, 'Google account email is missing or unverified. Please verify your email with Google first.');
  }

  // Find or create user in memory
  let user = usersStore.get(email);

  // Also check by googleId across all users
  if (!user) {
    for (const u of usersStore.values()) {
      if (u.googleId === googleId) {
        user = u;
        break;
      }
    }
  }

  if (user) {
    if (!user.googleId) user.googleId = googleId;
    if (!user.avatarUrl && avatarUrl) user.avatarUrl = avatarUrl;
    user.updatedAt = new Date();
  } else {
    const placeholderPassword = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 10);
    const id = crypto.randomUUID();
    const now = new Date();

    user = {
      id,
      email,
      name,
      password: placeholderPassword,
      googleId,
      authProvider: 'google',
      avatarUrl: avatarUrl || null,
      timezone: 'UTC',
      dateFormat: 'YYYY-MM-DD',
      preferences: createDefaultPreferences(),
      categories: createDefaultCategories(),
      createdAt: now,
      updatedAt: now,
    };

    usersStore.set(email, user);
    usersById.set(id, user);
  }

  const tokens = await generateAuthTokens(user.id);

  return {
    user: safeUserPayload(user),
    tokens,
    returnUrl: decodedState.returnUrl || env.FRONTEND_URL,
  };
};

// ──────────────────────────────────────────────
// Token Rotation: Refresh tokens (in-memory)
// ──────────────────────────────────────────────

export const refreshTokens = async (refreshToken: string): Promise<AuthTokens> => {
  let decoded: { id: string };
  try {
    decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET) as { id: string };
  } catch (_error) {
    throw new ApiError(401, 'Invalid or expired refresh token');
  }

  const storedToken = refreshTokensStore.get(refreshToken);

  if (!storedToken || storedToken.revoked || storedToken.expiresAt < new Date()) {
    throw new ApiError(401, 'Refresh token has been revoked or expired');
  }

  // Revoke old refresh token (Token Rotation)
  storedToken.revoked = true;

  return generateAuthTokens(decoded.id);
};

// ──────────────────────────────────────────────
// UC-03: Logout (in-memory)
// ──────────────────────────────────────────────

export const logout = async (userId: string, refreshToken?: string) => {
  if (refreshToken) {
    const storedToken = refreshTokensStore.get(refreshToken);
    if (storedToken && storedToken.userId === userId) {
      storedToken.revoked = true;
    }
  }
  return { message: 'Logged out successfully' };
};

// ──────────────────────────────────────────────
// UC-04: Get profile (in-memory)
// ──────────────────────────────────────────────

export const getProfile = async (userId: string) => {
  const user = usersById.get(userId);

  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  return {
    id: user.id,
    email: user.email,
    name: user.name,
    avatarUrl: user.avatarUrl,
    timezone: user.timezone,
    dateFormat: user.dateFormat,
    createdAt: user.createdAt,
    preferences: user.preferences,
    categories: user.categories,
  };
};

// ──────────────────────────────────────────────
// UC-04: Update profile (in-memory)
// ──────────────────────────────────────────────

export const updateProfile = async (userId: string, data: UpdateProfileDTO) => {
  const user = usersById.get(userId);
  if (!user) throw new ApiError(404, 'User not found');

  const { name, avatarUrl, timezone, dateFormat, currentPassword, newPassword } = data;

  if (name !== undefined) user.name = name;
  if (avatarUrl !== undefined) user.avatarUrl = avatarUrl;
  if (timezone !== undefined) user.timezone = timezone;
  if (dateFormat !== undefined) user.dateFormat = dateFormat;

  if (newPassword) {
    if (!currentPassword) {
      throw new ApiError(400, 'Current password is required to set a new password');
    }
    const isCurrentValid = await bcrypt.compare(currentPassword, user.password);
    if (!isCurrentValid) {
      throw new ApiError(400, 'Current password verification failed');
    }
    user.password = await bcrypt.hash(newPassword, 10);
  }

  user.updatedAt = new Date();

  return {
    id: user.id,
    email: user.email,
    name: user.name,
    avatarUrl: user.avatarUrl,
    timezone: user.timezone,
    dateFormat: user.dateFormat,
    updatedAt: user.updatedAt,
  };
};

// ──────────────────────────────────────────────
// UC-05: Update preferences (in-memory)
// ──────────────────────────────────────────────

export const updatePreferences = async (userId: string, preferencesData: Record<string, any>) => {
  const user = usersById.get(userId);
  if (!user) throw new ApiError(404, 'User not found');

  if (!user.preferences) {
    user.preferences = createDefaultPreferences();
  }

  // Merge incoming preferences
  Object.assign(user.preferences, preferencesData);
  user.updatedAt = new Date();

  return user.preferences;
};

// ──────────────────────────────────────────────
// Helper: look up user by ID (used by auth middleware)
// ──────────────────────────────────────────────

export const getUserById = (userId: string) => {
  return usersById.get(userId) || null;
};

export default {
  register,
  login,
  googleAuth,
  getGoogleAuthUrl,
  handleGoogleOAuthCallback,
  refreshTokens,
  logout,
  getProfile,
  updateProfile,
  updatePreferences,
  getUserById,
};
