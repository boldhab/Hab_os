import { Request, Response } from 'express';
import authService from './auth.service';
import ApiResponse from '../../common/apiResponse';
import asyncHandler from '../../common/asyncHandler';
import { AuthRequest } from '../../middleware/auth';

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
  refreshTokens,
  logout,
  getProfile,
  updateProfile,
  updatePreferences,
};
