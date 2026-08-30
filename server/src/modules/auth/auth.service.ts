import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { Prisma } from '@prisma/client';
import prisma from '../../config/db';
import ApiError from '../../common/apiError';

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretjwtkey_habos_2026_secure';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'supersecretrefreshjwtkey_habos_2026_secure';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '15m';
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '30d';

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

/**
 * Generate Access and Refresh tokens
 */
export const generateAuthTokens = async (userId: string): Promise<AuthTokens> => {
  const accessToken = jwt.sign({ id: userId }, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN as jwt.SignOptions['expiresIn'],
  });

  const refreshToken = jwt.sign({ id: userId }, JWT_REFRESH_SECRET, {
    expiresIn: JWT_REFRESH_EXPIRES_IN as jwt.SignOptions['expiresIn'],
  });

  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 30);

  await prisma.refreshToken.create({
    data: {
      token: refreshToken,
      userId,
      expiresAt,
    },
  });

  return {
    accessToken,
    refreshToken,
    expiresIn: JWT_EXPIRES_IN,
  };
};

/**
 * UC-01: Register a new user
 */
export const register = async (data: RegisterDTO) => {
  const existingUser = await prisma.user.findUnique({
    where: { email: data.email.toLowerCase() },
  });

  if (existingUser) {
    throw new ApiError(400, 'An account with this email address already exists');
  }

  const hashedPassword = await bcrypt.hash(data.password, 10);

  const user = await prisma.user.create({
    data: {
      name: data.name,
      email: data.email.toLowerCase(),
      password: hashedPassword,
      timezone: data.timezone || 'UTC',
      dateFormat: data.dateFormat || 'YYYY-MM-DD',
      preferences: {
        create: {
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
        },
      },
      categories: {
        create: [
          { name: 'Frontend Engineering', color: '#3B82F6', icon: 'code', type: 'TASK' },
          { name: 'Backend & API', color: '#10B981', icon: 'server', type: 'TASK' },
          { name: 'University Study', color: '#8B5CF6', icon: 'book', type: 'TASK' },
          { name: 'Health & Fitness', color: '#EF4444', icon: 'heart', type: 'HABIT' },
          { name: 'Food & Dining', color: '#F59E0B', icon: 'utensils', type: 'FINANCE' },
          { name: 'Education & Books', color: '#6366F1', icon: 'graduation-cap', type: 'FINANCE' },
        ],
      },
    },
    select: {
      id: true,
      email: true,
      name: true,
      timezone: true,
      dateFormat: true,
      avatarUrl: true,
      createdAt: true,
    },
  });

  const tokens = await generateAuthTokens(user.id);
  return { user, tokens };
};

/**
 * UC-02: Login with email and password
 */
export const login = async ({ email, password }: LoginDTO) => {
  const user = await prisma.user.findUnique({
    where: { email: email.toLowerCase() },
  });

  if (!user) {
    throw new ApiError(401, 'Invalid email or password');
  }

  const isPasswordValid = await bcrypt.compare(password, user.password);
  if (!isPasswordValid) {
    throw new ApiError(401, 'Invalid email or password');
  }

  const tokens = await generateAuthTokens(user.id);

  const safeUser = {
    id: user.id,
    email: user.email,
    name: user.name,
    timezone: user.timezone,
    dateFormat: user.dateFormat,
    avatarUrl: user.avatarUrl,
    createdAt: user.createdAt,
  };

  return { user: safeUser, tokens };
};

/**
 * Token Rotation: Exchange valid Refresh Token for fresh Access & Refresh Tokens
 */
export const refreshTokens = async (refreshToken: string): Promise<AuthTokens> => {
  let decoded: { id: string };
  try {
    decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET) as { id: string };
  } catch (_error) {
    throw new ApiError(401, 'Invalid or expired refresh token');
  }

  const storedToken = await prisma.refreshToken.findUnique({
    where: { token: refreshToken },
  });

  if (!storedToken || storedToken.revoked || storedToken.expiresAt < new Date()) {
    throw new ApiError(401, 'Refresh token has been revoked or expired');
  }

  // Revoke old refresh token (Token Rotation)
  await prisma.refreshToken.update({
    where: { id: storedToken.id },
    data: { revoked: true },
  });

  return generateAuthTokens(decoded.id);
};

/**
 * UC-03: Logout & invalidate active refresh token
 */
export const logout = async (userId: string, refreshToken?: string) => {
  if (refreshToken) {
    await prisma.refreshToken.updateMany({
      where: {
        userId,
        token: refreshToken,
      },
      data: { revoked: true },
    });
  }
  return { message: 'Logged out successfully' };
};

/**
 * UC-04: Retrieve current user profile and preferences
 */
export const getProfile = async (userId: string) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      email: true,
      name: true,
      avatarUrl: true,
      timezone: true,
      dateFormat: true,
      createdAt: true,
      preferences: true,
      categories: true,
    },
  });

  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  return user;
};

/**
 * UC-04: Update user profile
 */
export const updateProfile = async (userId: string, data: UpdateProfileDTO) => {
  const { name, avatarUrl, timezone, dateFormat, currentPassword, newPassword } = data;

  const updateData: Prisma.UserUpdateInput = {};
  if (name !== undefined) updateData.name = name;
  if (avatarUrl !== undefined) updateData.avatarUrl = avatarUrl;
  if (timezone !== undefined) updateData.timezone = timezone;
  if (dateFormat !== undefined) updateData.dateFormat = dateFormat;

  if (newPassword) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new ApiError(404, 'User not found');
    
    if (!currentPassword) {
      throw new ApiError(400, 'Current password is required to set a new password');
    }
    const isCurrentValid = await bcrypt.compare(currentPassword, user.password);
    if (!isCurrentValid) {
      throw new ApiError(400, 'Current password verification failed');
    }
    updateData.password = await bcrypt.hash(newPassword, 10);
  }

  const updatedUser = await prisma.user.update({
    where: { id: userId },
    data: updateData,
    select: {
      id: true,
      email: true,
      name: true,
      avatarUrl: true,
      timezone: true,
      dateFormat: true,
      updatedAt: true,
    },
  });

  return updatedUser;
};

/**
 * UC-05, UC-174, UC-175, UC-177: Update user preferences
 */
export const updatePreferences = async (userId: string, preferencesData: Prisma.UserPreferenceUpdateInput) => {
  const preferences = await prisma.userPreference.upsert({
    where: { userId },
    update: preferencesData,
    create: {
      ...(preferencesData as Prisma.UserPreferenceCreateWithoutUserInput),
      user: { connect: { id: userId } },
    },
  });

  return preferences;
};

export default {
  register,
  login,
  refreshTokens,
  logout,
  getProfile,
  updateProfile,
  updatePreferences,
};
